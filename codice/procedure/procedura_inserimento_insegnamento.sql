/*
    Procedura che si occupa di creare un insegnamento e una sua edizione insegnamento in termini di tuple all'interno delle rispettive tabelle. 
    Inoltre permette di associare tale insegnamento a un particolare corso di laurea esistente con la possibilità di specificare se è 
    caratterizzante o meno per tale CdL.
*/

CREATE OR REPLACE PROCEDURE procedura_inserimento_insegnamento (
    codice_insegnamento_input IN insegnamento.codice_insegnamento % TYPE, nome_insegnamento_input IN insegnamento.nome % TYPE,

    anno_accademico_input IN edizione_insegnamento.anno_accademico % TYPE, semestre_input IN edizione_insegnamento.semestre % TYPE,
    anno_corso_input IN edizione_insegnamento.anno_corso % TYPE, CFU_input IN edizione_insegnamento.CFU % TYPE,
    svolgimento_input IN edizione_insegnamento.svolgimento % TYPE, 

    codice_corso_input IN corso_laurea.codice_corso % TYPE, corso_principale_input IN offerta_insegnamento.corso_principale % TYPE
    ) IS

BEGIN
    INSERT INTO INSEGNAMENTO(CODICE_INSEGNAMENTO, NOME) VALUES  (codice_insegnamento_input, nome_insegnamento_input);

    INSERT INTO EDIZIONE_INSEGNAMENTO(CODICE_INSEGNAMENTO, ANNO_ACCADEMICO, SEMESTRE, ANNO_CORSO, CFU, SVOLGIMENTO) VALUES  
    (codice_insegnamento_input, anno_accademico_input, semestre_input, anno_corso_input, CFU_input, svolgimento_input);    

    INSERT INTO OFFERTA_INSEGNAMENTO(CODICE_INSEGNAMENTO, CODICE_CORSO, CORSO_PRINCIPALE) VALUES  
    (codice_insegnamento_input, codice_corso_input, corso_principale_input);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        raise_application_error(-20120, 'Non è stato possibile inserire l''insegnamento, l''edizione insegnamento specificata o l''associazione con il CdL specificato.');
        ROLLBACK;
END;
