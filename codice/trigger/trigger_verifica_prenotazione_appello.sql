/*
    Uno studente può prenotarsi solo ad appelli di esami riguardanti il suo corso di laurea. 
    Inoltre, può prenotarsi a un appello di un esame se e solo se ha pagato tutte le tasse, non ci sono 
    più prenotazioni per lo stesso appello, non è stato già superato il numero di iscritti consentiti,
    se non ha già superato quell'esame, se la prenotazione è avvenuta in data coerente con quelle di inizio e fine 
    prenotazione dell'appello stesso.
*/

CREATE OR REPLACE TRIGGER VERIFICA_PRENOTAZIONE_APPELLO 
BEFORE INSERT OR UPDATE ON prenotazione_appello FOR EACH ROW
DECLARE
    studentID prenotazione_appello.matricola_studente % TYPE := :NEW.matricola_studente;
    studentCourseID studente.codice_corso % TYPE;

    dataPrenotazione prenotazione_appello.data_prenotazione % TYPE := :NEW.data_prenotazione;
    codiceInsegnamentoAppello prenotazione_appello.codice_insegnamento % TYPE := :NEW.codice_insegnamento;
    
    tuplaAppello appello % ROWTYPE;
    tuplaStudente studente % ROWTYPE;
    
    tempMatricolaStudente studente.matricola_studente % TYPE;
    nPostiPrenotati appello.max_studenti % TYPE := 0;
    studentID_payment prenotazione_appello_seduta.matricola_studente % TYPE;

    invalidBookingDate EXCEPTION;
    postiMancanti EXCEPTION;
    unpaidTaxes EXCEPTION;
BEGIN
    -- verifica correttezza CdL
        -- prelevo il CdL di tale studente
        SELECT studente.codice_corso INTO studentCourseID
        FROM studente 
        WHERE studente.matricola_studente = studentID;

    -- verifica correttezza appello    
        -- recupero l'appello a cui tale studente vuole prenotarsi
        SELECT appello.anno_accademico, appello.data_appello, appello.codice_insegnamento, appello.data_inizio, appello.data_fine, appello.max_studenti, appello.tipo INTO tuplaAppello
        FROM   appello 
        WHERE appello.codice_insegnamento = :NEW.codice_insegnamento
            AND appello.anno_accademico = :NEW.anno_accademico
            AND appello.data_appello =:NEW.data_appello;

    -- verifico date
        -- verifico che la data di prenotazione per tale appello sia all'interno del periodo in cui è possibile prenotarsi
        IF (tuplaAppello.data_inizio > dataPrenotazione OR tuplaAppello.data_fine < dataPrenotazione) THEN
            RAISE invalidBookingDate;
        END IF;

    -- verifico posti
        -- conto il numero di persone già prenotate a tale appello
        SELECT NVL(cont, 0) 
        INTO nPostiPrenotati 
        FROM
                ((SELECT cont 
                FROM 
                    (   
                        -- recupero il numero di prenotazioni per tale appello
                        SELECT appello.data_appello, appello.codice_insegnamento, appello.anno_accademico, COUNT(*) as cont
                        FROM appello JOIN prenotazione_appello 
                        ON appello.anno_accademico = prenotazione_appello.anno_accademico
                        AND appello.codice_insegnamento = prenotazione_appello.codice_insegnamento
                        AND appello.data_appello = prenotazione_appello.data_appello
                        GROUP BY appello.data_appello, appello.codice_insegnamento, appello.anno_accademico
                        HAVING appello.data_appello = tuplaAppello.data_appello 
                        AND appello.codice_insegnamento = tuplaAppello.codice_insegnamento 
                        AND appello.anno_accademico = tuplaAppello.anno_accademico))
                UNION ALL SELECT 0 FROM DUAL
                )
        WHERE ROWNUM = 1;

        -- verifico che ci siano posti disponibili per tale appello
        IF (nPostiPrenotati >= tuplaAppello.max_studenti) THEN
            RAISE postiMancanti;
        END IF;

    -- verifico CdL studente e CdL coinvolti in appello
        SELECT * INTO tuplaStudente
        FROM studente
        WHERE studente.matricola_studente = studentID 
            AND EXISTS (    SELECT corso_laurea.codice_corso
                            FROM ((  appello JOIN offerta_insegnamento
                                        ON appello.codice_insegnamento = offerta_insegnamento.codice_insegnamento
                            ) 

                            JOIN
                            corso_laurea ON corso_laurea.codice_corso = offerta_insegnamento.codice_corso)
                            WHERE corso_laurea.codice_corso = studentCourseID
                                AND appello.anno_accademico = tuplaAppello.anno_accademico
                                AND appello.data_appello = tuplaAppello.data_appello
                                AND appello.codice_insegnamento = tuplaAppello.codice_insegnamento
            );

    -- non può prenotarsi per esami già superati
        -- non esiste un esame superato la cui matricola studente è la stessa presente sulla prenotazione che si sta cercando di inserire
        SELECT studente.matricola_studente INTO tempMatricolaStudente
        FROM studente
        WHERE studente.matricola_studente = studentID AND
             NOT EXISTS (
                        --recupero eventuali esami già superati per tale insegnamento
                        SELECT *
                        FROM esame_superato
                        WHERE esame_superato.matricola_studente = studentID 
                            AND esame_superato.codice_insegnamento = codiceInsegnamentoAppello);


    -- verifica pagamento di tutte le tasse: 
        -- non esistono tasse non pagate dallo studente
        SELECT studente.matricola_studente INTO studentID_payment
        FROM studente LEFT JOIN tassa ON studente.matricola_studente = tassa.matricola_studente
        WHERE ( NOT EXISTS (    
                                -- recupero le tasse non pagate
                                SELECT * 
                                FROM tassa
                                WHERE tassa.matricola_studente = studentID AND
                                tassa.data_pagamento IS NULL
                            )
            ) AND studente.matricola_studente = studentID
        GROUP BY studente.matricola_studente;

        -- se vi sono tasse non pagate, tale studente non può prenotarsi
        IF (studentID_payment IS NULL) THEN
            RAISE unpaidTaxes;
        END IF;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN
        raise_application_error(-20000, 'Non puoi prenotarti per questo esame!');
    WHEN invalidBookingDate THEN
        raise_application_error(-20001, 'Data prenotazione non valida!');
    WHEN postiMancanti THEN
        raise_application_error(-20002, 'Posti Mancanti!');
    WHEN unpaidTaxes THEN
        raise_application_error(-20003, 'Sono presenti delle tasse non pagate. Non puoi iscriverti all''appello!');
END;

