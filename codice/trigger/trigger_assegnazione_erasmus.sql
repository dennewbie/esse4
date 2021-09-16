/*
    Trigger_assegnazione_erasmus
    Gli Erasmus sono assegnati agli studenti che hanno fatto richiesta per quel bando. Inoltre,
    non deve essere assegnato ad uno studente che ha già vinto l'Erasmus in quell'anno accademico e
    il numero di bandi Erasmus assegnati non supera il numero di borse Erasmus disponibili (assegnabili)
    
    N.B. Precisazione relativa all'anno accademico
        Siccome in fase di inserimento per l'anno accademico, specie nel popolamento, si predilige un espressione del tipo 
            TO_DATE('2019', 'YYYY')
        che effettua un taglio al 01-JUN-2019, consideriamo che l'anno accademico abbia inizio il 1 Giugno e
        abbia fine il 31 Maggio prossimo.
*/

CREATE OR REPLACE TRIGGER trigger_assegnazione_erasmus   
BEFORE INSERT OR UPDATE ON assegnazione_erasmus 
FOR EACH ROW   
DECLARE   
    studentID               partecipazione_bando_erasmus.matricola_studente % TYPE;
    annoAccademico          date;
    fineAnnoAccademico      date;
    data_scadenza           date;
    nPosti                  bando_erasmus.numero_posti % TYPE;
    bando_assegnato         assegnazione_erasmus.numero_bando_erasmus % TYPE;
    nPostiAssegnati         bando_erasmus.numero_posti % TYPE := 0;

    invalidStudent          EXCEPTION;
    invalidDate             EXCEPTION;
    alreadyAssigned         EXCEPTION;
    exceed_nPosti           EXCEPTION;  
BEGIN   
   --recupero l'anno accademico in base alla data di assegnazione dell'erasmus
        IF (EXTRACT(MONTH FROM TO_DATE(:NEW.data_assegnazione, 'DD/MM/YYYY')) > 5) THEN
            SELECT TO_DATE(('01/06/' || SUBSTR(TO_CHAR(:NEW.data_assegnazione, 'DD/MM/YYYY'), -4, 4)), 'DD/MM/YYYY') INTO annoAccademico FROM DUAL;
            SELECT ADD_MONTHS(TO_DATE(annoAccademico, 'DD/MM/YYYY'), 12) INTO fineAnnoAccademico FROM DUAL;
        ELSE
            SELECT TO_DATE(('01/06/' || SUBSTR(TO_CHAR(:NEW.data_assegnazione, 'DD/MM/YYYY'), -4, 4)), 'DD/MM/YYYY') INTO fineAnnoAccademico FROM DUAL;
            SELECT ADD_MONTHS(TO_DATE(fineAnnoAccademico, 'DD/MM/YYYY'), -12) INTO annoAccademico FROM DUAL;
        END IF;
    
    --controllo che lo studente abbia fatto richiesta
        SELECT matricola_studente INTO studentID   
        FROM partecipazione_bando_erasmus   
        WHERE numero_bando_erasmus = :NEW.numero_bando_erasmus AND matricola_studente = :NEW.matricola_studente;   
        
        
        IF (studentID IS NULL) THEN
            RAISE invalidStudent;
        END IF;

    --verifico che la data di assegnazione sia successiva alla scadenza
        -- prelevo la data di scadenza delle prenotazioni e il numero di posti per tale bando
        SELECT bando_erasmus.scadenza, bando_erasmus.numero_posti INTO data_scadenza, nPosti
        FROM bando_erasmus
        WHERE numero_bando_erasmus = :NEW.numero_bando_erasmus;


        IF data_scadenza >= :NEW.data_assegnazione THEN
            RAISE invalidDate;
        END IF;

    --controllo che lo studente non abbia ricevuto già un bando erasmus nell'anno accademico
        SELECT numero_bando_erasmus INTO bando_assegnato
        FROM assegnazione_erasmus
        WHERE (NOT EXISTS (
                            -- recupero eventuali eramus ricevuti nell'anno accademico
                            SELECT * 
                            FROM assegnazione_erasmus 
                            WHERE matricola_studente = :NEW.matricola_studente AND 
                                    TO_DATE(data_assegnazione, 'DD/MM/YYYY') >= TO_DATE(annoAccademico, 'DD/MM/YYYY') AND 
                                    TO_DATE(data_assegnazione, 'DD/MM/YYYY') < TO_DATE(fineAnnoAccademico, 'DD/MM/YYYY')
                        )) AND ROWNUM = 1;

        IF (bando_assegnato IS NULL) THEN
            RAISE alreadyAssigned;
        END IF;

    --verifico posti
        --conto il numero di erasmus già assegnati
        SELECT COUNT(*) INTO nPostiAssegnati
        FROM assegnazione_erasmus
        WHERE numero_bando_erasmus = :NEW.numero_bando_erasmus;

        --verifico che ci siano ancora posti disponibili
        IF (nPostiAssegnati >= nPosti) THEN
            RAISE exceed_nPosti;
        END IF;

EXCEPTION  
    WHEN invalidStudent THEN
        RAISE_APPLICATION_ERROR(-20060, 'Lo studente immesso non ha fatto richiesta per tale bando!');
    WHEN invalidDate THEN
        RAISE_APPLICATION_ERROR(-20061, 'La data immessa non è valida per tale bando!');
    WHEN alreadyAssigned THEN
        RAISE_APPLICATION_ERROR(-20062, 'Per tale studente è già stata assegnato un bando_erasmus nell''anno accademico corrente!');
    WHEN exceed_nPosti THEN
        RAISE_APPLICATION_ERROR(-20063, 'Numero massimo di posti assegnati per bando_erasmus raggiunto!');
    WHEN NO_DATA_FOUND THEN   
        RAISE_APPLICATION_ERROR(-20064, 'Non puoi assegnare il bando!');   
END;

