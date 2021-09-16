-- Vista dei Corsi di Laurea con posti disponibili

CREATE OR REPLACE VIEW vista_corsi_di_laurea_posti_disponibili AS
  SELECT corso_laurea.codice_corso, corso_laurea.tipo, corso_laurea.capienza, corso_laurea.nome, COUNT(*) AS studenti_iscritti
  FROM studente JOIN corso_laurea ON studente.codice_corso = corso_laurea.codice_corso
  GROUP BY corso_laurea.codice_corso, corso_laurea.tipo, corso_laurea.capienza, corso_laurea.nome;