-- Vista dei Bandi Erasmus attivi

CREATE OR REPLACE VIEW vista_bando_erasmus AS
  SELECT * 
  FROM bando_erasmus
  WHERE TRUNC(data_emissione) < TRUNC(SYSDATE) AND TRUNC(scadenza) > TRUNC(SYSDATE);