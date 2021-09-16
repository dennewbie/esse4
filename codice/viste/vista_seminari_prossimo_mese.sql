-- Vista dei Seminari che avranno luogo nel prossimo mese

CREATE OR REPLACE VIEW vista_seminari_prossimo_mese AS
  SELECT data_seminario, nome, CFU, max_persone
  FROM seminario
  WHERE TRUNC(data_seminario) >= TRUNC(SYSDATE) AND TRUNC(data_seminario) < TRUNC(SYSDATE) + 30;