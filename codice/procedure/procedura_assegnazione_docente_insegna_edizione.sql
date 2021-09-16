/*
    La procedura consente di assegnare il docente per una specifica edizione di un insegnamento.
    Se non esistono questionari coompilati di tale edizione insegnamento (in tal caso si presuppone che tale insegnamento sia nuovo),
    allora viene scelto un docente qualsiasi tra i docenti degli altri insegnamenti relativi allo stesso corso di laurea dell'insegnamento fornito in input,
    Se esistono dei questionari coompilati di tale insegnamento, si assegna il docente che ha la migliore valutazione di GRADIMENTO tra tutti
    i questionari relativi a tale insegnamento, cioè il docente che tra tutti i docenti delle edizioni di insegnamento ha avuto la valutazione migliore.
    Si presuppone che l'anno accademico venga espresso nello stesso formato che si usa nel DML, cioè TO_DATE('YYYY').
    Inoltre, non è detto che il docente migliore venga assegnato. Infatti è possibile che insegni già troppe edizioni insegnamento e quindi ne va scelto un altro.
*/
CREATE OR REPLACE PROCEDURE procedura_assegnazione_docente_insegna_edizione (
        codice_insegnamento_input IN questionario.codice_insegnamento % TYPE,

        tipo_docente_input IN insegna_edizione.tipo_docente % TYPE,
        anno_accademico_input IN insegna_edizione.anno_accademico % TYPE,

        semestre_input IN edizione_insegnamento.semestre % TYPE,
        anno_corso_input IN edizione_insegnamento.anno_corso % TYPE, 
        CFU_input IN edizione_insegnamento.CFU % TYPE,
        svolgimento_input IN edizione_insegnamento.svolgimento % TYPE
    ) IS

    tesserino_docente_output            questionario.tesserino_docente % TYPE;
    annoAccademico                      date;
    checkValue                          questionario.tesserino_docente % TYPE;
    numeroQuestionariTrovati            NUMBER(5, 0);
    nDocentiEdizione                    NUMBER(5, 0);
    nDocentiCdL                         NUMBER(5, 0);
    docenteTrovato                      CHAR(1) := 'F';
    i                                   NUMBER(5, 0) := 1;
    insegnamentiInsegnati               NUMBER(5, 0) := 0;
    docenteNonDisponibile               EXCEPTION;
BEGIN
    --inserimento edizione insegnamento nell'anno accademico di input
        annoAccademico := TO_DATE(anno_accademico_input, 'DD/MM/YYYY');
        INSERT INTO EDIZIONE_INSEGNAMENTO(CODICE_INSEGNAMENTO, ANNO_ACCADEMICO, SEMESTRE, ANNO_CORSO, CFU, SVOLGIMENTO) VALUES 
        (codice_insegnamento_input, TO_DATE(annoAccademico, 'DD/MM/YYYY'), semestre_input, anno_corso_input, CFU_input, svolgimento_input);
    -- conteggio questionari
        SELECT conteggio INTO numeroQuestionariTrovati
        FROM ((     
                -- conto il numero di questionari per tale insegnamento    
                    SELECT COUNT(*) AS conteggio
                    FROM questionario
                    WHERE questionario.codice_insegnamento = codice_insegnamento_input
                    GROUP BY questionario.codice_insegnamento
            ) UNION ALL SELECT 0 FROM DUAL
        ) WHERE ROWNUM = 1;

    -- conteggio docenti edizione
        -- conto il numero di docenti per i quali sono stati compilati dei questionari in tale insegnamento
        SELECT conteggio INTO nDocentiEdizione FROM
            (SELECT COUNT(*) AS conteggio FROM 
                ((  
                    -- recupero i docenti per i quali sono stati compilati dei questionari in tale insegnamento
                    SELECT questionario.tesserino_docente
                    FROM questionario 
                    WHERE codice_insegnamento = codice_insegnamento_input
                    GROUP BY questionario.tesserino_docente
                )) UNION ALL SELECT 0 FROM DUAL)
        WHERE ROWNUM = 1;     

    -- conteggio docenti CdL possibili
        -- conto i docenti, che rispettano le condizioni, di tale CdL
        SELECT conteggio INTO nDocentiCdL FROM
            (SELECT COUNT(*) AS conteggio FROM 
                ((  
                    -- recupero i docenti di uno dei CdL a cui tale insegnamento appartiene che insegnano materie principali in tale CdL      
                    SELECT questionario.tesserino_docente
                    FROM offerta_insegnamento JOIN questionario
                            ON offerta_insegnamento.codice_insegnamento = questionario.codice_insegnamento
                            WHERE offerta_insegnamento.codice_corso = (
                                SELECT offerta_insegnamento.codice_corso
                                FROM offerta_insegnamento
                                WHERE offerta_insegnamento.codice_insegnamento = codice_insegnamento_input AND ROWNUM = 1)
                            AND offerta_insegnamento.corso_principale = 'Y'
                    GROUP BY questionario.tesserino_docente
                )) UNION ALL SELECT 0 FROM DUAL)
        WHERE ROWNUM = 1;  


    -- presenza questionari
        -- se ci sono questionari per tale insegnamento
        IF (numeroQuestionariTrovati > 0) THEN
            -- non è un nuovo insegnamento: si ricerca nelle edizioni insegnamento passate il miglior docente
            -- per tale motivo viene stabilito un indice di valutazione complessivo del docente, 
            -- tale indice è la media delle medie delle valutazioni ottenute in tale insegnamento attraverso i questionari
            WHILE (docenteTrovato = 'F') 
            LOOP

                -- recupero la lista dei docenti migliori secondo tale indice
                    -- parto dal primo docente e verifico se può effettivamente insegnare una nuova edizione di insegnamento
                    SELECT tesserinoDocenteSelezionato INTO tesserino_docente_output FROM 
                        (SELECT tesserinoDocenteSelezionato, ROWNUM AS RN FROM (
                            SELECT questionario.tesserino_docente AS tesserinoDocenteSelezionato, (((SUM(questionario.gradimento) / COUNT(questionario.gradimento)) +
                                (SUM(questionario.disponibilita_docente) / COUNT(questionario.disponibilita_docente)) +
                                (SUM(questionario.precisione_orario) / COUNT(questionario.precisione_orario)) +
                                (SUM(questionario.materiale_didattico) / COUNT(questionario.materiale_didattico))) / 4) AS Media
                    
                                FROM questionario 
                                WHERE codice_insegnamento = codice_insegnamento_input
                                GROUP BY questionario.tesserino_docente
                                ORDER BY Media DESC
                    )) WHERE RN = i;

                -- conto quante cattedre ha già tale docente nell'anno accademico
                    SELECT conteggioInsegnamentiDocente INTO insegnamentiInsegnati
                    FROM
                        ((  SELECT COUNT(*) AS conteggioInsegnamentiDocente
                            FROM docente JOIN insegna_edizione
                            ON docente.numero_tesserino = insegna_edizione.tesserino_docente
                            JOIN edizione_insegnamento
                            ON edizione_insegnamento.anno_accademico = insegna_edizione.anno_accademico 
                            AND edizione_insegnamento.codice_insegnamento = insegna_edizione.codice_insegnamento
                            WHERE edizione_insegnamento.anno_accademico = anno_accademico_input
                            AND docente.numero_tesserino = tesserino_docente_output
                            GROUP BY insegna_edizione.tesserino_docente) UNION ALL SELECT 0 FROM DUAL)
                    WHERE ROWNUM = 1;

                -- se tale docente non ha raggiunto il numero massimo di cattedre (5)
                    --allora è possibile assegnare un docente
                --altrimenti non assegna tale docente e passa al prossimo docente valido per tale insegnamento
                    IF (insegnamentiInsegnati > 4 AND (nDocentiEdizione - i) < 1) THEN 
                        RAISE docenteNonDisponibile;
                    ELSIF (insegnamentiInsegnati <= 4) THEN
                        docenteTrovato := 'T';
                        INSERT INTO INSEGNA_EDIZIONE(CODICE_INSEGNAMENTO, ANNO_ACCADEMICO, TESSERINO_DOCENTE, TIPO_DOCENTE) VALUES 
                        (codice_insegnamento_input, TO_DATE(annoAccademico, 'DD/MM/YYYY'), tesserino_docente_output, tipo_docente_input);
                    ELSIF ((nDocentiEdizione - i) < 1) THEN
                        RAISE docenteNonDisponibile;
                    ELSE
                        i := i + 1;
                    END IF;
            END LOOP;
        ELSE 
    --assenza questionari
        -- se non ci sono questionari per tale insegnamento
            -- è un nuovo insegnamento. Il docente NON va ricercato nelle vecchie edizioni insegnamento
            -- per tale motivo viene stabilito un indice di valutazione complessivo del docente, 
            -- tale indice è la media delle medie delle valutazioni ottenute attraverso i questionari in un insegnamento principale 
            -- di uno dei CdL a cui appartiene tale insegnamento 
            WHILE (docenteTrovato = 'F') 
            LOOP

                -- recupero la lista dei docenti migliori secondo tale indice
                    -- parto dal primo docente e verifico se può effettivamente insegnare una nuova edizione di insegnamento
                    SELECT tesserinoDocenteSelezionato INTO tesserino_docente_output FROM 
                        (SELECT tesserinoDocenteSelezionato, ROWNUM AS RN FROM (
                            SELECT questionario.tesserino_docente AS tesserinoDocenteSelezionato, (((SUM(questionario.gradimento) / COUNT(questionario.gradimento)) +
                                (SUM(questionario.disponibilita_docente) / COUNT(questionario.disponibilita_docente)) +
                                (SUM(questionario.precisione_orario) / COUNT(questionario.precisione_orario)) +
                                (SUM(questionario.materiale_didattico) / COUNT(questionario.materiale_didattico))) / 4) AS Media
                    
                                FROM offerta_insegnamento JOIN questionario
                                ON offerta_insegnamento.codice_insegnamento = questionario.codice_insegnamento
                                WHERE offerta_insegnamento.codice_corso = (
                                    SELECT offerta_insegnamento.codice_corso
                                    FROM offerta_insegnamento
                                    WHERE offerta_insegnamento.codice_insegnamento = codice_insegnamento_input AND ROWNUM = 1)
                                AND offerta_insegnamento.corso_principale = 'Y'
                                GROUP BY questionario.tesserino_docente
                                ORDER BY Media DESC
                    )) WHERE RN = i;
                -- conto quante cattedre ha già tale docente nell'anno accademico
                    SELECT conteggioInsegnamentiDocente INTO insegnamentiInsegnati
                    FROM
                        ((  SELECT COUNT(*) AS conteggioInsegnamentiDocente
                            FROM docente JOIN insegna_edizione
                            ON docente.numero_tesserino = insegna_edizione.tesserino_docente
                            JOIN edizione_insegnamento
                            ON edizione_insegnamento.anno_accademico = insegna_edizione.anno_accademico 
                            AND edizione_insegnamento.codice_insegnamento = insegna_edizione.codice_insegnamento
                            WHERE edizione_insegnamento.anno_accademico = anno_accademico_input
                            AND docente.numero_tesserino = tesserino_docente_output
                            GROUP BY insegna_edizione.tesserino_docente) UNION ALL SELECT 0 FROM DUAL)
                    WHERE ROWNUM = 1;
                -- se tale docente non ha raggiunto il numero massimo di cattedre (5)
                    --allora è possibile assegnare un docente
                --altrimenti non assegna tale docente e passa al prossimo docente valido tra i possibili docenti del CdL estratti precedentemente
                        IF (insegnamentiInsegnati > 4 AND (nDocentiCdL - i) < 1) THEN 
                            RAISE docenteNonDisponibile;
                        ELSIF (insegnamentiInsegnati <= 4) THEN
                            docenteTrovato := 'T';
                            INSERT INTO INSEGNA_EDIZIONE(CODICE_INSEGNAMENTO, ANNO_ACCADEMICO, TESSERINO_DOCENTE, TIPO_DOCENTE) VALUES 
                            (codice_insegnamento_input, TO_DATE(annoAccademico, 'DD/MM/YYYY'), tesserino_docente_output, tipo_docente_input);
                        ELSIF ((nDocentiCdL - i) < 1) THEN
                            RAISE docenteNonDisponibile;
                        ELSE
                            i := i + 1;
                        END IF;
            END LOOP;
        END IF;
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        raise_application_error(-20180, 'NO DATA FOUND');
        ROLLBACK;
    WHEN docenteNonDisponibile THEN
        raise_application_error(-20181, 'Non esiste un docente che ha insegnato le precedenti edizioni insegnamento oppure un docente del CdL che può insegnare questa edizione di insegnamento!');
        ROLLBACK;
    WHEN OTHERS THEN 
        raise_application_error(-20182, 'Non è stato possibile assegnare un docente a tale edizione di tale insegnamento.');
        ROLLBACK;
END; 

