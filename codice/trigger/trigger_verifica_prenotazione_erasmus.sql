/*
    Uno studente non può effetuare la domanda di partecipazione a un bando erasmus prima
    della data di emissione del bando o dopo la sua scadenza.
*/
CREATE OR REPLACE TRIGGER VERIFICA_PRENOTAZIONE_ERASMUS
BEFORE INSERT OR UPDATE ON partecipazione_bando_erasmus FOR EACH ROW
DECLARE
    dataDomanda partecipazione_bando_erasmus.data_domanda % TYPE := :NEW.data_domanda;
    tuplaBandoErasmus bando_erasmus % ROWTYPE;
BEGIN
    -- recupero la tupla di tale bando per cui lo studente intende partecipare
        SELECT * INTO tuplaBandoErasmus
        FROM bando_erasmus 
        WHERE bando_erasmus.numero_bando_erasmus = :NEW.numero_bando_erasmus;

        IF (tuplaBandoErasmus.data_emissione > dataDomanda OR tuplaBandoErasmus.scadenza < dataDomanda) THEN
            RAISE NO_DATA_FOUND;
        END IF;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN
        raise_application_error(-20030, 'Data prenotazione non valida');
END;

