/*
    Uno studente che richiede di effettuare un tirocnio esterno ha bisogno di un docente come tutor interno ed un tutor aziendale esterno. Si suppone che
    venga assegnato allo studente un docente come tutor di tirocinio interno, che fra tutti i doenti è quello che ha fatto meno volte il tutor di tirocini 
    interni, lo stesso schema viene adottato anche per l'assegnazione del tutor aziendale.
*/

CREATE OR REPLACE PROCEDURE procedura_assegnazione_tutor_tirocinio (
    matricola_studente_input IN studente.matricola_studente % TYPE,
    partitaIva_input IN tutor_aziendale.partita_iva % TYPE
)
IS
    tesserinoTutor_selezionato docente.numero_tesserino % TYPE;
    numeroTirocinio tirocinio.numero_tirocinio % TYPE;
BEGIN

    -- prelievo tutor aziendale che ha meno tirocini associati dell'azienda richiesta
        SELECT numeroTesserino INTO tesserinoTutor_selezionato
        FROM (
                SELECT tutor_aziendale.partita_iva, tutor_aziendale.numero_tesserino AS numeroTesserino, COUNT(*) AS conteggioTirocini
                FROM tutor_aziendale JOIN tirocinio ON tutor_aziendale.numero_tesserino = tirocinio.tesserino_tutor_azienda
                WHERE tutor_aziendale.partita_iva = partitaIva_input
                GROUP BY tutor_aziendale.numero_tesserino, tutor_aziendale.partita_iva
                ORDER BY COUNT(tutor_aziendale.numero_tesserino) 
            )
        WHERE ROWNUM = 1; 

    --richiamo la procedura per l'assegnazione del tutor interno
        procedura_assegnazione_tutor_docente_tirocinio_interno(matricola_studente_input);

    --aggiorno la tupla appena creata nel tirocinio aggiungendo il tutor aziendale precedentemente trovato
    --Si assume che la durata media sia 3 mesi
        SELECT numero_tirocinio INTO numeroTirocinio
        FROM tirocinio
        WHERE matricola_studente = matricola_studente_input;

        UPDATE tirocinio
        SET tesserino_tutor_azienda = tesserinoTutor_selezionato
        WHERE numero_tirocinio = numeroTirocinio;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        raise_application_error(-20140, 'Non è stato possibile determinare il tutor aziendale da assegnare come tutor del tirocinio a questo studente.');
        ROLLBACK;
END;
