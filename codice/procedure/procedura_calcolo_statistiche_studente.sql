-- Procedura che calcola le statistiche degli esami e della laurea per uno studente la cui matricola viene passata in input
CREATE OR REPLACE PROCEDURE procedura_calcola_statistiche_esami_e_laurea (matricola_studente_input IN studente.matricola_studente % TYPE, 
                                                                mediaAritmeticaEsami OUT NUMBER, mediaPonderataEsami OUT NUMBER, 
                                                                mediaAritmeticaLaurea OUT NUMBER, mediaPonderataLaurea OUT NUMBER, progressioneCFU OUT NUMBER)
                                                                IS
    esamiRegistrati NUMBER(2, 0);
    CFUconseguiti NUMBER(3, 0);
    sommaVotiEsami NUMBER(4, 0);
    combinazioneLineareVotiPesi NUMBER(5, 0);
    tipoLaurea corso_laurea.tipo % TYPE;
    divisoreProgressioneCFU NUMBER(3, 0);
BEGIN

    -- memorizzazione informazioni relative alla carriera di tale studente
        -- memorizzo le informazioni recuperate
        SELECT sommaCFU, conteggioEsami, sommaVoti, combLineare INTO CFUconseguiti, esamiRegistrati, sommaVotiEsami, combinazioneLineareVotiPesi
        FROM (  
                -- recupero, a partire dagli esami superati dagli studenti, le informazioni relative a tali esami e alle edizioni di insegnamento associate e
                -- prelevo tali informazioni per lo studente specifico, ovvero la matricola di input

                --recupero
                    -- il numero di CFU conseguiti relativi agli insegnamenti del CdL a cui è iscritto tale studente 
                    -- il numero di esami registrati con successo
                    -- la somma dei voti ottenuti a tali esami
                    -- la combinazione lineare dei voti ottenuti e i CFU conseguiti per tali esami
                SELECT studente.matricola_studente, SUM(edizione_insegnamento.CFU) AS sommaCFU, COUNT(*) AS conteggioEsami, SUM(esame_superato.voto) AS sommaVoti,
                    SUM(esame_superato.voto * edizione_insegnamento.CFU) AS combLineare
                FROM esame_superato JOIN edizione_insegnamento
                ON  edizione_insegnamento.anno_accademico = esame_superato.anno_accademico 
                    AND edizione_insegnamento.codice_insegnamento = esame_superato.codice_insegnamento
                JOIN insegnamento
                ON esame_superato.codice_insegnamento = insegnamento.codice_insegnamento
                JOIN studente
                ON studente.matricola_studente = esame_superato.matricola_studente
                WHERE esame_superato.matricola_studente = matricola_studente_input
                GROUP BY studente.matricola_studente
        );
    -- prelievo del tipo di corso di laurea
        -- verifico se lo studente è iscritto a un CdL triennale o magistrale
        SELECT corso_laurea.tipo INTO tipoLaurea 
        FROM corso_laurea JOIN studente 
        ON corso_laurea.codice_corso = studente.codice_corso
        WHERE studente.matricola_studente = matricola_studente_input;

        IF (LOWER(tipoLaurea) = 'triennale') THEN
            divisoreProgressioneCFU := 180;
        ELSE
            divisoreProgressioneCFU := 120;
        END IF;

    -- calcolo statistiche della carriera di tale studente
        -- attraverso le informazioni ottenute in precedenza
        mediaAritmeticaEsami := ROUND(sommaVotiEsami / esamiRegistrati);
        mediaPonderataEsami := ROUND(combinazioneLineareVotiPesi / CFUconseguiti);
        mediaAritmeticaLaurea := ROUND((mediaAritmeticaEsami * 110) / 30);
        mediaPonderataLaurea := ROUND((mediaPonderataEsami * 110) / 30);
        progressioneCFU := TRUNC(((100 * CFUconseguiti) / divisoreProgressioneCFU), 2);

    -- visualizzazione statistiche
        DBMS_OUTPUT.PUT_LINE('Esami Registrati: ' || esamiRegistrati);
        DBMS_OUTPUT.PUT_LINE('CFU Conseguiti: ' || CFUconseguiti);
        DBMS_OUTPUT.PUT_LINE('Media Aritmetica Esami: ' || mediaAritmeticaEsami);
        DBMS_OUTPUT.PUT_LINE('Media Ponderata Esami: ' || mediaPonderataEsami);
        DBMS_OUTPUT.PUT_LINE('Media Aritmetica Laurea: ' || mediaAritmeticaLaurea);
        DBMS_OUTPUT.PUT_LINE('Media Ponderata Laurea: ' || mediaPonderataLaurea);
        DBMS_OUTPUT.PUT_LINE('Progressione CFU: ' || progressioneCFU || '%');    
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        raise_application_error(-20130, 'Non è possibile visualizzare le statistiche dei tuoi esami e relative alla tua futura laurea');
        ROLLBACK;
END;

