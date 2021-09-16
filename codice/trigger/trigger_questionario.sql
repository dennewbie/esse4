/*
      trigger_questionario
      Per compilare il questionario, lo studente deve aver frequentato l'edizione dell'insegnamento relativo. Inoltre, deve accadere
      che l'edizione insegnamento e l'insegnamento siano relativi al corso di studi dello studente, 
      che il docente per il quale si compila il questionario abbia effettivamente insegnato quell'edizione, 
      che la data di compilazione sia successiva alla data di inizio frequentazione del corso in questione, 
      che lo studente non abbia già compilato il questionario.
*/

CREATE OR REPLACE TRIGGER trigger_questionario
BEFORE INSERT OR UPDATE ON questionario
FOR EACH ROW
DECLARE
      studentID                           questionario.matricola_studente % TYPE;
      studentCdL                          studente.codice_corso % TYPE;
      cod_ins                             offerta_insegnamento.codice_insegnamento % TYPE;
      tupla_FEI                           frequenta_edizione_insegnamento % ROWTYPE;
      tess_docente                        insegna_edizione.tesserino_docente % TYPE;
      data_inizio                         date;
      conteggioQuestionario               number(2,0);

      invalidCdL                          EXCEPTION;
      invalid_FEI                         EXCEPTION;
      invalidProfessor                    EXCEPTION;
      invalidCompilationDate              EXCEPTION;
      alreadyCompiled                     EXCEPTION;
BEGIN
      -- controllare che l'edizione insegnamento/insegnamento sia relativo al corso di studi dello studente
            -- prelevo il CdL di tale studente
            SELECT codice_corso INTO studentCdL
            FROM studente 
            WHERE matricola_studente = :NEW.matricola_studente;
                  
            -- verifico che tale insegnamento appartenga a tale CdL
            SELECT codice_insegnamento INTO cod_ins
            FROM offerta_insegnamento
            WHERE codice_corso = studentCdL AND 
                  codice_insegnamento = :NEW.codice_insegnamento;

            IF (cod_ins IS NULL) THEN
                  RAISE invalidCdL;
            END IF;

      --controllare che abbia frequentato l'edizione per lo stesso anno accademico
            SELECT matricola_Studente INTO studentID
            FROM frequenta_edizione_insegnamento
            WHERE codice_insegnamento = :NEW.codice_insegnamento AND
                  anno_accademico = :NEW.anno_accademico AND
                  matricola_studente = :NEW.matricola_studente;

            IF (studentID IS NULL) THEN
                  RAISE invalid_FEI;
            END IF;

      -- controllare che il docente abbia insegnato quell'edizione
            SELECT tesserino_docente INTO tess_docente
            FROM insegna_edizione
            WHERE tesserino_docente = :NEW.tesserino_docente AND  
                  anno_accademico = :NEW.anno_accademico AND
                  codice_insegnamento = :NEW.codice_insegnamento;

            IF (tess_docente IS NULL) THEN
                  RAISE invalidProfessor;
            END IF;

      -- controllare che la data di compilazione sia successiva alla data di inizio frequentazione
            -- prelevo la data di inizio frequentazione di tale edizione insegnamento di tale studente
            SELECT data_ins INTO data_inizio
            FROM frequenta_edizione_insegnamento
            WHERE codice_insegnamento = :NEW.codice_insegnamento AND
                  anno_accademico = :NEW.anno_accademico AND
                  matricola_studente = :NEW.matricola_studente;

            IF :NEW.data_compilazione < data_inizio THEN
                  RAISE invalidCompilationDate;
            END IF;

      -- controllare che non esista un questionario già compilato per tale edizione di insegnamento e  per tale docente di tale studente
            SELECT cont INTO conteggioQuestionario
            FROM ((
                  SELECT count(*) as cont
                  FROM QUESTIONARIO
                  WHERE tesserino_docente = :NEW.tesserino_docente AND  
                        anno_accademico = :NEW.anno_accademico AND
                        codice_insegnamento = :NEW.codice_insegnamento AND
                        matricola_studente = :NEW.matricola_studente
                  GROUP BY numero_questionario
                  ) UNION ALL SELECT 0 FROM DUAL
            )
            WHERE ROWNUM = 1;
            

            IF (conteggioQuestionario > 0) THEN
                RAISE alreadyCompiled;
            END IF;

EXCEPTION
      WHEN invalidCdL THEN
            RAISE_APPLICATION_ERROR(-20050, 'Insegnamento immesso non valido: non appartiene al CdL dello studente!');
      WHEN invalid_FEI THEN
            RAISE_APPLICATION_ERROR(-20051, 'Ed_Insegnamento immessa non valida: lo studente non ha ancora frequentato tale edizione!');
      WHEN invalidProfessor THEN
            RAISE_APPLICATION_ERROR(-20052, 'Docente immesso non valido: non ha insegnato tale edizione dell''insegnamento');
      WHEN invalidCompilationDate THEN
            RAISE_APPLICATION_ERROR(-20053, 'Data compilazione non valida: deve prima aver frequentato l''edizione dell''insegnamento');
      WHEN alreadyCompiled THEN
            RAISE_APPLICATION_ERROR(-20054, 'Hai già compilato il questionario!');
      WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20055, 'Non puoi compilare il questionario!');
END;
