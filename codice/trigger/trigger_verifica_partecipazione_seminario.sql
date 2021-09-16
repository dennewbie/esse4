/* 
    trigger verifica partecipazione seminario
    Uno studente non può partecipare a più semminari conteporaneamente
*/

CREATE OR REPLACE TRIGGER VERIFICA_PARTECIPAZIONE_SEMINARIO
BEFORE INSERT OR UPDATE ON partecipa_seminario FOR EACH ROW
DECLARE 
    numeroSeminariContemporanei number(4, 0);
    invalidParticipation EXCEPTION;
BEGIN
    -- VERIFICA CHE LO STUDENTE PARTECIPI GIA' AD UN ALTRO SEMINARIO NELLA STESSA DATA
        --conto il numero dei seminari a cui già partecipa nella stessa data
        SELECT COUNT(*) INTO numeroSeminariContemporanei
        FROM partecipa_seminario
        WHERE partecipa_seminario.matricola_studente = :NEW.matricola_studente 
        AND partecipa_seminario.data_seminario = :NEW.data_seminario;

        -- non deve partecipare a più seminari contemporaneamnte
        IF numeroSeminariContemporanei <> 0 THEN
            RAISE invalidParticipation;
        END IF;

EXCEPTION 
     WHEN invalidParticipation THEN
        raise_application_error(-20080, 'Lo studente sta gia'' partecipando ad un seminario');
END;
