/*
    Procedura che si occupa andare ad automatizzare la programmazione degli appelli di una determinata edizione di uno specifico insegnamento
    dell'anno accademico corrente.
    Per fare ciò, si determinano delle date di appello d'esame tali per cui non vi è un altro appello d'esame di un'altra edizione insegnamento
    dello stesso anno di corso e dello stesso corso di laurea nella stessa data scelta. 
    Si evitano anche i giorni considerati festivi dal punto di vista accaddemico: 'Sabato' e 'Domenica'. 
    Una possibile estensione è quella di andare a evitare anche i giorni considerati festivi dal locale calendario regionale e/o nazionale.  
*/

CREATE OR REPLACE PROCEDURE procedura_programmazione_appelli (
    codice_insegnamento_input IN appello.codice_insegnamento % TYPE,
    max_studenti_input IN appello.max_studenti % TYPE,
    tipo_input IN appello.tipo % TYPE,
    codice_corso_input IN corso_laurea.codice_corso % TYPE
    ) IS

    anno_accademico_input appello.anno_accademico % TYPE;
    giornoAttualeNumerico NUMBER(2, 0);
    giornoAttualeStringa CHAR(10);
    giornoFineMese NUMBER(2, 0);
    meseAttuale CHAR(15);
    monthCounter NUMBER(2, 0) := 0;
    annoAttuale CHAR(4);
    tempDate DATE;

    annoCorso edizione_insegnamento.anno_corso % TYPE;
    nAppelli NUMBER(5, 0);
    systemDate DATE;
    firstIteration NUMBER(1, 0) := 0;
    
BEGIN  
    -- calcolo mese e anno accademico attuale
        -- da cui partire per la programmazione degli appelli
        systemDate := SYSDATE;
        SELECT TO_CHAR(systemDate, 'Month') INTO meseAttuale FROM dual;
        SELECT (SELECT TO_DATE(to_char(systemDate, 'YYYY'), 'YYYY') FROM DUAL) INTO anno_accademico_input FROM DUAL;

    
    -- prelievo anno corso dell'edizione insegnamento per cui si vuole avviare la procedura di programmazione
        SELECT edizione_insegnamento.anno_corso INTO annoCorso
        FROM edizione_insegnamento JOIN offerta_insegnamento
        ON edizione_insegnamento.codice_insegnamento = offerta_insegnamento.codice_insegnamento

        WHERE edizione_insegnamento.anno_accademico = anno_accademico_input
        AND edizione_insegnamento.codice_insegnamento = codice_insegnamento_input
        AND offerta_insegnamento.codice_corso = codice_corso_input;
        
    -- ciclo esterno che itera sui mesi
        WHILE (meseAttuale != 'August') 
        LOOP

            -- calcolo l'ultimo giorno di tale mese
            SELECT TO_NUMBER(TO_CHAR(LAST_DAY(TO_DATE(ADD_MONTHS(systemDate, monthCounter), 'DD/MM/YY')), 'DD')) INTO giornoFineMese FROM DUAL;
            
            -- alla prima iterazione, fissiamo la prima data utile per l'iterazione su tale mese come sysdate per evitare che
            -- vengano ipotizzate date di appello in giorni passati siccome l'iterazione parte dal primo giorno del mese
            IF (firstIteration = 1) THEN
                SELECT TO_NUMBER(TO_CHAR(TO_DATE(TRUNC(ADD_MONTHS(systemDate, monthCounter), 'mm'), 'DD/MM/YY'), 'DD')) INTO giornoAttualeNumerico FROM DUAL;
            ELSE
                SELECT TO_NUMBER(TO_CHAR(systemDate, 'DD')) INTO giornoAttualeNumerico FROM DUAL;
                IF (giornoAttualeNumerico + 1 > giornoFineMese) THEN
                    giornoAttualeNumerico := giornoFineMese + 1;
                ELSE 
                    giornoAttualeNumerico := giornoAttualeNumerico + 1;
                END IF;
                firstIteration := 1;
            END IF;
    -- ciclo interno che itera sui giorni del mese
            WHILE (giornoAttualeNumerico != giornoFineMese + 1)
            LOOP
                -- controllo che tale giorno non sia sabato o domenica
                    SELECT TO_CHAR(TO_DATE(TRUNC(ADD_MONTHS(systemDate, monthCounter), 'mm') + giornoAttualeNumerico, 'DD/MM/YY'), 'Day') INTO giornoAttualeStringa FROM DUAL;
                    IF (giornoAttualeStringa = 'Saturday' OR giornoAttualeStringa = 'Sunday') THEN
                        giornoAttualeNumerico := giornoAttualeNumerico + 1;
                        CONTINUE;
                    END IF;

                -- recupero dell'anno
                    SELECT TO_CHAR(EXTRACT (YEAR FROM TO_DATE(ADD_MONTHS(systemDate + giornoAttualeNumerico, monthCounter), 'DD/MM/YY'))) INTO annoAttuale FROM dual;
                -- costruizione della data ipotetica
                    tempDate := TO_DATE(TO_CHAR(giornoAttualeNumerico || meseAttuale || annoAttuale), 'DD/MM/YYYY');

                -- automatizzazione appelli
                    SELECT conteggioAppelli INTO nAppelli FROM (    
                                                                    -- conto il numero di appelli già fissati nella data ipotetica
                                                                    -- per edizioni di insegnamento del medesimo corso di laurea ed anno di corso
                                                                    SELECT conteggioAppelli FROM (   SELECT COUNT(*) as conteggioAppelli
                                                                    FROM appello JOIN edizione_insegnamento 
                                                                    ON appello.anno_accademico = edizione_insegnamento.anno_accademico
                                                                    AND appello.codice_insegnamento = edizione_insegnamento.codice_insegnamento
                                                                    JOIN offerta_insegnamento 
                                                                    ON offerta_insegnamento.codice_insegnamento = edizione_insegnamento.codice_insegnamento

                                                                    WHERE appello.anno_accademico = anno_accademico_input
                                                                    AND appello.data_appello = tempDate
                                                                    AND offerta_insegnamento.codice_corso = codice_corso_input
                                                                    AND edizione_insegnamento.anno_corso = annoCorso
                                                                    GROUP BY appello.data_appello) 
                        UNION ALL SELECT 0 FROM DUAL)
                    WHERE ROWNUM = 1;
                    -- se esistono già appelli con suddette caratteristiche, si passa al giorno successivo 
                    -- e vengono ripetuti i controlli su tale giorno, altrimenti è possibile fissare tale appello in tale giorno
                    IF (nAppelli > 0) THEN
                        giornoAttualeNumerico := giornoAttualeNumerico + 1;
                        CONTINUE;
                    END IF;

                -- inserimento    
                    INSERT INTO APPELLO(ANNO_ACCADEMICO, DATA_APPELLO, CODICE_INSEGNAMENTO, DATA_INIZIO, DATA_FINE, MAX_STUDENTI, TIPO) VALUES 
                    (anno_accademico_input, tempDate, codice_insegnamento_input, tempDate - 30, tempDate - 5, max_studenti_input, tipo_input);
                    EXIT;
            END LOOP;
            -- incremento del mese
                -- sia nel caso in cui non sia possibile fissare l'appello in tale mese poichè non vi sono date disponibili oppure
                -- sia nel caso in cui sia stata fissata la data correttamente
                
                --riposizionamento al primo giorno del mese
                giornoAttualeNumerico := 1;
                monthCounter := monthCounter + 1;
                SELECT TO_CHAR(TO_DATE(ADD_MONTHS(systemDate, monthCounter), 'DD/MM/YY'), 'Month') INTO meseAttuale FROM dual;
        END LOOP;
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        raise_application_error(-20110, 'Non esiste l''edizione insegnamento o l''insegnamento.');
        ROLLBACK;
    WHEN OTHERS THEN
        raise_application_error(-20111, 'Non è stato possibile stabilire tutte le date di appello per l''anno accademico.');
        ROLLBACK;
END;

