/*
    Uno studente non può effetuare la domanda di partecipazione a un bando borsa di studio prima
    della data di emissione del bando o dopo la sua scadenza.
*/
CREATE OR REPLACE TRIGGER VERIFICA_PRENOTAZIONE_BORSA_STUDIO
BEFORE INSERT OR UPDATE ON partecipazione_bando_borsa FOR EACH ROW
DECLARE
    dataDomanda partecipazione_bando_borsa.data_domanda % TYPE := :NEW.data_domanda;
    tuplaBandoBorsa bando_borsa % ROWTYPE;
BEGIN
    --recupero la tupla di tale bando per cui lo studente intende partecipare
        SELECT * INTO tuplaBandoBorsa
        FROM bando_borsa 
        WHERE bando_borsa.numero_bando_borsa = :NEW.numero_bando_borsa;
        
        IF (tuplaBandoBorsa.data_emissione > dataDomanda OR tuplaBandoBorsa.scadenza < dataDomanda) THEN
            RAISE NO_DATA_FOUND;
        END IF;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN
        raise_application_error(-20020, 'Data prenotazione non valida');
END;
