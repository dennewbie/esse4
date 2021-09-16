/*
    Uno studente non può pagare la stessa tassa due volte
*/

CREATE OR REPLACE TRIGGER VERIFICA_PAGAMENTO_TASSA
BEFORE UPDATE ON tassa FOR EACH ROW
DECLARE
    tuplaTassa tassa % ROWTYPE;
    taxAlreadyPaid EXCEPTION;
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    -- recupero la tupla della tassa da pagare
        SELECT * INTO tuplaTassa
        FROM tassa
        WHERE :OLD.numero_fattura = tassa.numero_fattura;

        --verifico che la tassa non sia già stata pagata
        IF ((tuplaTassa.IUV IS NOT NULL) AND (tuplaTassa.data_pagamento IS NOT NULL)) THEN
            RAISE taxAlreadyPaid;
        END IF;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN
        raise_application_error(-20040, 'NO DATA FOUND');
    WHEN taxAlreadyPaid THEN
        raise_application_error(-20041, 'La tassa risulta essere pagata. Non devi ripagarla!');
END;


