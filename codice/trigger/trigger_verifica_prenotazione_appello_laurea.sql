/*
    Uno studente può effettuare una prenotazione per un appello di seduta di laurea se e solo se
    l'appello di seduta di laurea per il quale ha eseguito la prenotazione afferisce al suo CdL,
    se la somma dei CFU ottenuti con i seminari (al più 3), dei CFU ottenuti con il tirocinio (12),
    dei CFU ottenuti con i bandi erasmus (al più 12) e quelli ottenuti con gli esami del CdL è maggiore
    i 180 se si tratta di una triennale o 120 se si tratta di una magistrale. Inoltre, 
    uno studente può effettuare una prenotazione per un appello di seduta di laurea se e solo se ha
    pagato tutte le tasse previste, la data di prenotazione è avvenuta nel range di date corretto, e ci sono
    abbastanza posti rimanenti, se ha effettuato il tirocinio.
*/

CREATE OR REPLACE TRIGGER VERIFICA_PRENOTAZIONE_APPELLO_LAUREA 
BEFORE INSERT OR UPDATE ON prenotazione_appello_seduta FOR EACH ROW
DECLARE
    studentID prenotazione_appello_seduta.matricola_studente % TYPE := :NEW.matricola_studente;
    insertedCourseID studente.codice_corso % TYPE := :NEW.codice_corso;
    studentCourseID studente.codice_corso % TYPE;
    studentID_payment prenotazione_appello_seduta.matricola_studente % TYPE;
    studentID_temp prenotazione_appello_seduta.matricola_studente % TYPE;

    CFU_seminari seminario.CFU % TYPE := 0;
    CFU_tirocini tirocinio.CFU % TYPE := 0;
    CFU_esamiSuperati Number(3, 0) := 0;
    CFU_bandiErasmus bando_erasmus.CFU % TYPE := 0;

    nPostiPrenotati appello_laurea.max_iscrizioni % TYPE := 0;
    tuplaAppello appello_laurea % ROWTYPE;
    dataPrenotazione prenotazione_appello_seduta.data_prenotazione % TYPE := :NEW.data_prenotazione;

    tipoLaurea corso_laurea.tipo % TYPE := 0;
    notEnough_CFU EXCEPTION;
    invalidCourseID EXCEPTION;
    unpaidTaxes EXCEPTION;
    invalidBookingDate EXCEPTION;
    postiMancanti EXCEPTION;
BEGIN
    -- verifica correttezza CdL
        --prelevo il CdL effettivo dello studente caricato nel db
        SELECT studente.codice_corso INTO studentCourseID
        FROM studente
        WHERE studente.matricola_studente = studentID;

        --verifico che corrisponda col CdL inserito
        IF studentCourseID != insertedCourseID THEN
            RAISE invalidCourseID;
        END IF;


    -- conteggio CFU seminari
        -- somma dei cfu dei seminari a cui ha partecipato tale studente
        SELECT studente.matricola_studente, SUM(seminario.CFU) INTO studentID_temp, CFU_seminari
        FROM (
            -- recupero gli studenti che hanno partecipato a seminari e per tale seminari recupero il numero di CFU corrispondente
            (STUDENTE LEFT JOIN partecipa_seminario ON STUDENTE.matricola_studente = partecipa_seminario.matricola_studente) 
            LEFT JOIN seminario ON partecipa_seminario.data_seminario = seminario.data_seminario 
                AND partecipa_seminario.tesserino_docente = seminario.tesserino_docente
        )
        WHERE studente.matricola_studente = studentID
        GROUP BY studente.matricola_studente;

        -- se non ha partecipato ad alcun seminario, assegno 0 a tale conteggio
        IF (CFU_seminari IS NULL) THEN  
            CFU_seminari := 0;
        END IF;

        -- limito il numero di CFU per i seminari a 3 se eventualmente ha assistito a più seminari ottenendo più CFU dei massimi consentiti
        IF (CFU_seminari > 3) THEN
            CFU_seminari := 3;
        END IF;

    
    -- conteggio CFU tirocini
        -- prelevo il numero dei cfu del tirocinio a cui ha partecipato tale studente, se vi ha partecipato. 
        SELECT tirocinio.matricola_studente, tirocinio.CFU INTO studentID_temp, CFU_tirocini
        FROM tirocinio 
        WHERE tirocinio.matricola_studente = studentID;

        -- si suppone che il massimo numero di CFU ottenibili da tirocini sia 12 (vedi traccia trigger)
        IF CFU_tirocini > 12 THEN
            CFU_tirocini := 12;
        END IF;


    -- conteggio CFU Erasmus
         -- somma dei CFU conseguiti dalle esperienze Erasmus a cui ha partecipato tale studente
        SELECT studente.matricola_studente, SUM(bando_erasmus.CFU) INTO studentID_temp, CFU_bandiErasmus
        FROM (
            -- recupero gli studenti che hanno partecipato ad erasmus e per tale erasmus recupero il numero di CFU corrispondente
            studente LEFT JOIN assegnazione_erasmus ON STUDENTE.matricola_studente = assegnazione_erasmus.matricola_studente)
            LEFT JOIN bando_erasmus ON assegnazione_erasmus.numero_bando_erasmus = bando_erasmus.numero_bando_erasmus
        WHERE studente.matricola_studente = studentID
        GROUP BY studente.matricola_studente;

        -- se non ha partecipato ad alcun erasmus, assegno 0 a tale conteggio
        IF (CFU_bandiErasmus IS NULL) THEN
            CFU_bandiErasmus := 0;
        END IF;

        -- si suppone max 12 cfu per erasmus in totale
        IF CFU_bandiErasmus > 12 THEN
            CFU_bandiErasmus := 12;
        END IF;

    -- conteggio CFU esami superati
        -- somma dei CFU conseguiti al superamento di esami
        SELECT studente.matricola_studente, SUM(edizione_insegnamento.CFU) INTO studentID_temp, CFU_esamiSuperati
        FROM ((
                -- recupero gli esami superati, i relativi appelli e le relative edizioni dell'insegnamento per prelevare il numero di CFU corrispondente
                (studente LEFT JOIN esame_superato ON studente.matricola_studente = esame_superato.matricola_studente)

                LEFT JOIN appello ON esame_superato.data_esame = appello.data_appello 
                    AND esame_superato.anno_accademico = appello.anno_accademico 
                    AND esame_superato.codice_insegnamento = appello.codice_insegnamento) 
                
                LEFT JOIN

                edizione_insegnamento ON edizione_insegnamento.anno_accademico = appello.anno_accademico 
                    AND edizione_insegnamento.codice_insegnamento = appello.codice_insegnamento
        )
        WHERE studente.matricola_studente = studentID
        GROUP BY studente.matricola_studente;

        -- se non ha superato alcun esame, assegno 0 a tale conteggio
        IF (CFU_esamiSuperati IS NULL) THEN
            CFU_esamiSuperati := 0;
        END IF;

    -- verifica tipo seduta laurea
        -- prelevo il tipo di laurea di tale studente 
        SELECT corso_laurea.tipo INTO tipoLaurea 
        FROM studente JOIN corso_laurea ON studente.codice_corso = corso_laurea.codice_corso
        WHERE studente.matricola_studente = studentID;

        -- verifica il tipo del corso di laurea al quale è iscritto lo studente e se può prenotarsi per un appello
        -- di seduta di laurea del proprio corso
            -- se la laurea di tale studente è triennale, la somma deve essere pari a 180 
        IF LOWER(tipoLaurea) = 'triennale' THEN
            IF (CFU_esamiSuperati + CFU_tirocini + CFU_seminari +  CFU_bandiErasmus) < 180 THEN
                RAISE notEnough_CFU;
            END IF;
            -- se la laurea di tale studente è magistrale, la somma deve essere pari a 120 
        ELSIF LOWER(tipoLaurea) = 'magistrale' THEN
            IF (CFU_esamiSuperati + CFU_tirocini + CFU_seminari +  CFU_bandiErasmus) < 120 THEN
                RAISE notEnough_CFU;
            END IF;
        END IF; 

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

    -- prelievo appello a cui tale studente vuole prenotarsi
        SELECT appello_laurea.data_appello, appello_laurea.codice_corso, appello_laurea.inizio_iscrizioni, appello_laurea.fine_iscrizioni, appello_laurea.tipo, appello_laurea.max_iscrizioni INTO tuplaAppello
        FROM appello_laurea 
        WHERE appello_laurea.codice_corso = :NEW.codice_corso
            AND appello_laurea.data_appello =:NEW.data_appello;

        -- verifico se la data di prenotazione è compresa tra l'inizio e la fine del periodo di iscrizione dell'appello
        IF (tuplaAppello.inizio_iscrizioni > dataPrenotazione OR tuplaAppello.fine_iscrizioni < dataPrenotazione) THEN
            RAISE invalidBookingDate;
        END IF;

    -- verifica posti
        -- conto il numero di persone già prenotate a tale appello
        SELECT NVL(cont, 0) 
        INTO nPostiPrenotati 
        FROM
                ((SELECT cont 
                FROM 
                    (   
                        -- recupero il numero di prenotazioni per tale appello
                        SELECT appello_laurea.data_appello, appello_laurea.codice_corso, COUNT(*) as cont
                        FROM appello_laurea JOIN prenotazione_appello_seduta 
                        ON appello_laurea.codice_corso = prenotazione_appello_seduta.codice_corso
                        AND appello_laurea.data_appello = prenotazione_appello_seduta.data_appello
                        GROUP BY appello_laurea.data_appello, appello_laurea.codice_corso
                        HAVING appello_laurea.data_appello = tuplaAppello.data_appello 
                        AND appello_laurea.codice_corso = tuplaAppello.codice_corso 
                    ))
                UNION ALL SELECT 0 FROM DUAL
                )
        WHERE ROWNUM = 1;

        -- verifico che ci siano posti disponibili per tale appello
        IF (nPostiPrenotati >= tuplaAppello.max_iscrizioni) THEN
            RAISE postiMancanti;
        END IF;

EXCEPTION 
    WHEN notEnough_CFU THEN
        raise_application_error(-20010, 'Non e'' possibile effettuare la prenotazione. Non hai raggiunto abbastanza CFU!');
    WHEN NO_DATA_FOUND THEN
        raise_application_error(-20011, 'Non e'' stato possibile completare l''operazione di prenotazione.');
    WHEN invalidCourseID THEN
        raise_application_error(-20012, 'Codice di Corso di Laurea non valido');
    WHEN unpaidTaxes THEN
        raise_application_error(-20013, 'Sono presenti delle tasse non pagate. Non puoi laurearti!');
    WHEN invalidBookingDate THEN
        raise_application_error(-20014, 'Data prenotazione non valida!');
    WHEN postiMancanti THEN
        raise_application_error(-20015, 'Posti Mancanti!');
END;
