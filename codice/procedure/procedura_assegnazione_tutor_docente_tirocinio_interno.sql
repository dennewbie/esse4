/*
    Uno studente che richiede di effettuare un tirocnio interno ha bisogno di un docente come tutor. Si suppone che
    venga assegnato allo studente un docente come tutor di tirocinio interno, che fra tutti i docenti è quello che ha 
    fatto meno volte il tutor di tirocini interni.
*/

CREATE OR REPLACE PROCEDURE procedura_assegnazione_tutor_docente_tirocinio_interno (matricola_studente_input IN studente.matricola_studente % TYPE) IS
    CFUconseguiti NUMBER(3, 0);
    tipoLaurea corso_laurea.tipo % TYPE;
    tesserino_docente_selezionato docente.numero_tesserino % TYPE;
BEGIN
    
    -- verifica relativa ai CFU da conseguire
        -- calcolo la somma dei CFU ottenuti dallo studente e nel caso in cui sia inferiore a 120 per uno studente della triennale
        -- o inferiore a 80 per uno studente della magistrale, allora annullo l'inserimento

        -- calcolo dei conseguiti CFU
            SELECT NVL(sommaCFU, 0) INTO CFUconseguiti
            FROM (  
                    -- recupero i CFU delle edizioni insegnamento che tale studente ha conseguito superando tale esame
                    SELECT studente.matricola_studente, NVL(SUM(edizione_insegnamento.CFU), 0) AS sommaCFU
                    FROM esame_superato JOIN edizione_insegnamento
                    ON  edizione_insegnamento.anno_accademico = esame_superato.anno_accademico 
                        AND edizione_insegnamento.codice_insegnamento = esame_superato.codice_insegnamento
                    JOIN insegnamento
                    ON esame_superato.codice_insegnamento = insegnamento.codice_insegnamento
                    RIGHT JOIN studente
                    ON studente.matricola_studente = esame_superato.matricola_studente
                    WHERE studente.matricola_studente = matricola_studente_input
                    GROUP BY studente.matricola_studente
            );

        -- controllo dei CFU
            -- verifico se lo studente è iscritto a un CdL triennale o magistrale e se ha abbastanza CFU
            SELECT corso_laurea.tipo INTO tipoLaurea 
            FROM corso_laurea JOIN studente 
            ON corso_laurea.codice_corso = studente.codice_corso
            WHERE studente.matricola_studente = matricola_studente_input;

            -- verifica in base alla tipo di laurea dello studente
            IF (LOWER(tipoLaurea) = TO_CHAR('triennale')) THEN
                IF (CFUconseguiti < 120) THEN
                    ROLLBACK;
                END IF; 
            ELSE
                IF (CFUconseguiti < 80) THEN
                    ROLLBACK;
                END IF; 
            END IF;
    -- assegnazione del docente
        -- prelievo docente che ha meno tirocini associati
        SELECT tesserino_docente INTO tesserino_docente_selezionato
        FROM (  SELECT docente.numero_tesserino AS tesserino_docente, COUNT(*) as conteggioTirocini
                FROM docente JOIN tirocinio
                ON docente.numero_tesserino = tirocinio.tesserino_docente
                GROUP BY docente.numero_tesserino
                ORDER BY conteggioTirocini
            )   WHERE ROWNUM = 1; 
    
    -- inserimento 
        -- si inserisce una tupla in tirocinio. Si assume che la durata media è di 3 mesi.
        INSERT INTO TIROCINIO(NUMERO_TIROCINIO, CFU, DATA_INIZIO, DATA_FINE, TESSERINO_DOCENTE, TESSERINO_TUTOR_AZIENDA, MATRICOLA_STUDENTE) VALUES  
        (matricola_studente_input, 12, TO_DATE(NEXT_DAY(SYSDATE, 'MONDAY'), 'DD/MM/YYYY'), TO_DATE(SYSDATE + 90,'DD/MM/YYYY'), TO_CHAR(tesserino_docente_selezionato),  NULL, TO_CHAR(matricola_studente_input));

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        raise_application_error(-20160, 'Non è stato possibile determinare il docente da assegnare come tutor del tirocinio a questo studente.');
        ROLLBACK;
END;
