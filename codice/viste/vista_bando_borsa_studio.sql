-- Vista dei Bandi di Borsa di Studio attivi

CREATE OR REPLACE VIEW vista_bando_borsa_studio AS
  SELECT * 
  FROM bando_borsa
  WHERE TRUNC(data_emissione) < TRUNC(SYSDATE) AND TRUNC(scadenza) > TRUNC(SYSDATE);
