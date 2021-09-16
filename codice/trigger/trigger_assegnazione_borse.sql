/*
    trigger_assegnazione_borse
    Le borse di studio sono assegnate agli studenti che hanno fatto richiesta per quel bando. Inoltre,
    non deve essere assegnata ad uno studente che ha già vinto la borsa di studio in quell'anno accademico e
    il numero di borse assegnate non supera il numero di borse disponibili.

    N.B. Precisazione relativa all'anno accademico
        Siccome in fase di inserimento per l'anno accademico, specie nel popolamento, si predilige un espressione del tipo 
            TO_DATE('2019', 'YYYY')
        che effettua un taglio al 01-JUN-2019, consideriamo che l'anno accademico abbia inizio il 1 Giugno e
        abbia fine il 31 Maggio prossimo.
*/

CREATE OR REPLACE TRIGGER trigger_assegnazione_borse   
BEFORE INSERT OR UPDATE ON assegnazione_borse   
FOR EACH ROW   
DECLARE   
    studentID               partecipazione_bando_borsa.matricola_studente % TYPE;
    annoAccademico          date;
    fineAnnoAccademico      date;
    data_scadenza           date;
    nBorse                  bando_borsa.numero_borse % TYPE;
    borsa_assegnata         assegnazione_borse.numero_bando_borsa % TYPE;
    nBorseAssegnate         bando_borsa.numero_borse % TYPE := 0;

    invalidStudent          EXCEPTION;
    invalidDate             EXCEPTION;
    alreadyAssigned         EXCEPTION;
    exceed_nBorse           EXCEPTION;                          
BEGIN 
    --recupero l'anno accademico 
        --in base alla data di assegnazione della bds
        IF (EXTRACT(MONTH FROM TO_DATE(:NEW.data_assegnazione, 'DD/MM/YYYY')) > 5) THEN
            SELECT TO_DATE(('01/06/' || SUBSTR(TO_CHAR(:NEW.data_assegnazione, 'DD/MM/YYYY'), -4, 4)), 'DD/MM/YYYY') INTO annoAccademico FROM DUAL;
            SELECT ADD_MONTHS(TO_DATE(annoAccademico, 'DD/MM/YYYY'), 12) INTO fineAnnoAccademico FROM DUAL;
        ELSE
            SELECT TO_DATE(('01/06/' || SUBSTR(TO_CHAR(:NEW.data_assegnazione, 'DD/MM/YYYY'), -4, 4)), 'DD/MM/YYYY') INTO fineAnnoAccademico FROM DUAL;
            SELECT ADD_MONTHS(TO_DATE(fineAnnoAccademico, 'DD/MM/YYYY'), -12) INTO annoAccademico FROM DUAL;
        END IF;

    --controllo che lo studente abbia fatto richiesta
        SELECT matricola_studente INTO studentID   
        FROM partecipazione_bando_borsa   
        WHERE numero_bando_borsa = :NEW.numero_bando_borsa AND matricola_studente = :NEW.matricola_studente;   
    
    
        IF (studentID IS NULL) THEN
            RAISE invalidStudent;
        END IF;

    --verifico che la data di assegnazione sia successiva alla scadenza
        -- prelevo la data di scadenza delle prenotazioni e il numero di borse assegnabili per tale bando
        SELECT bando_borsa.scadenza, bando_borsa.numero_borse INTO data_scadenza, nBorse
        FROM bando_borsa
        WHERE numero_bando_borsa = :NEW.numero_bando_borsa;

        -- la data di assegnazione deve essere successiva alla data di scadenza delle prenotazioni di tale bando
        IF data_scadenza >= :NEW.data_assegnazione THEN
            RAISE invalidDate;
        END IF;

    --controllo che lo studente non abbia ricevuto già una bds nell'anno accademico
        SELECT numero_bando_borsa INTO borsa_assegnata
        FROM assegnazione_borse
        WHERE (NOT EXISTS ( 
                            -- recupero eventuali bds ricevute nell'anno accademico
                            SELECT * 
                            FROM assegnazione_borse 
                            WHERE matricola_studente = :NEW.matricola_studente AND 
                                    TO_DATE(data_assegnazione, 'DD/MM/YYYY') >= TO_DATE(annoAccademico, 'DD/MM/YYYY') AND 
                                    TO_DATE(data_assegnazione, 'DD/MM/YYYY') < TO_DATE(fineAnnoAccademico, 'DD/MM/YYYY')
                        )) AND ROWNUM = 1;


        IF (borsa_assegnata IS NULL) THEN
            RAISE alreadyAssigned;
        END IF;

    --verifico posti
        --conto il numero di borse già assegnate
        SELECT COUNT(*) INTO nBorseAssegnate
        FROM assegnazione_borse
        WHERE numero_bando_borsa = :NEW.numero_bando_borsa;

        --verifico che ci siano ancora borse assegnabili
        IF (nBorseAssegnate >= nBorse) THEN
            RAISE exceed_nBorse;
        END IF;

EXCEPTION  
    WHEN invalidStudent THEN
        RAISE_APPLICATION_ERROR(-20070, 'Lo studente immesso non ha fatto richiesta per tale bando!');
    WHEN invalidDate THEN
        RAISE_APPLICATION_ERROR(-20071, 'La data immessa non è valida per tale bando!');
    WHEN alreadyAssigned THEN
        RAISE_APPLICATION_ERROR(-20072, 'Per tale studente è già stata assegnata una borsa di studio nell''anno accademico corrente!');
    WHEN exceed_nBorse THEN
        RAISE_APPLICATION_ERROR(-20073, 'Numero massimo di borse assegnate per bando_borsa raggiunto!');
    WHEN NO_DATA_FOUND THEN   
        RAISE_APPLICATION_ERROR(-20074, 'Non puoi assegnare il bando!');   
END;

