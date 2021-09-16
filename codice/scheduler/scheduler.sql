/*
    Job che ogni primo del mese cancella tutti i ricevimenti eseguiti nel mese scorso,
    tutte le prenotazioni ad essi associati, tutte le prenotazioni ad appelli di edizioni 
    insegnamento avvenute nel mese scorso e tutte le prenotazioni ad appelli di laurea
    avvenute nel mese scorso.
*/

BEGIN DBMS_SCHEDULER.CREATE_JOB (
    job_name => 'Rollout',
    job_type => 'PLSQL_BLOCK',
    job_action =>  '    
                        BEGIN
                            DELETE FROM ricevimento
                            WHERE data_ricevimento < SYSDATE - 30; 

                            DELETE FROM prenotazione_appello
                            WHERE data_appello < SYSDATE - 30;

                            DELETE FROM prenotazione_appello_seduta
                            WHERE data_appello < SYSDATE - 30;
                        END;
                    ',
    start_date => TO_DATE('01-SET-2017','DD-MM-YYYY'), 
    repeat_interval => 'FREQ = MONTHLY',
    enabled => TRUE,
    comments => 'Cancellazione di tuple di ricevimenti e prenotazioni relative al mese appena passato.'); 
END;

-- Cancellazione Job di ROLLOUT
BEGIN
    DBMS_SCHEDULER.DROP_JOB ('Rollout');
END;