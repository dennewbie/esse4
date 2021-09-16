/*
    :P

    if (userOpeningThisFile.name == "Alfredo" && userOpeningThisFile.surname == "Mungari") {
      closeThisFile();
    }
*/

drop table corso_laurea cascade constraints;
drop table studente cascade constraints;
drop table docente cascade constraints;
drop table insegnamento cascade constraints;
drop table edizione_insegnamento cascade constraints;
drop table offerta_insegnamento cascade constraints;
drop table insegna_edizione cascade constraints;
drop table frequenta_edizione_insegnamento cascade constraints;
drop table appello_laurea cascade constraints;
drop table prenotazione_appello_seduta cascade constraints;
drop table partecipa_seduta cascade constraints;
drop table seduta_laurea cascade constraints;
drop table relatore cascade constraints;
drop table azienda cascade constraints;
drop table tutor_aziendale cascade constraints;
drop table tirocinio cascade constraints;
drop table questionario cascade constraints;
drop table appello cascade constraints;
drop table orario_lezioni cascade constraints;
drop table seminario cascade constraints;
drop table presiede_appello cascade constraints;
drop table ricevimento cascade constraints;
drop table esame_superato cascade constraints;
drop table prenotazione_ricevimento cascade constraints;
drop table prenotazione_appello cascade constraints;
drop table tassa cascade constraints;
drop table partecipa_seminario cascade constraints;
drop table bando_borsa cascade constraints;
drop table bando_erasmus cascade constraints;
drop table partecipazione_bando_borsa cascade constraints;
drop table partecipazione_bando_erasmus cascade constraints;
drop table assegnazione_erasmus cascade constraints;
drop table assegnazione_borse cascade constraints;
drop table telefono_studente cascade constraints;
drop table telefono_docente cascade constraints;
drop table telefono_tutor_aziendale cascade constraints;
drop table email_studente cascade constraints;
drop table email_docente cascade constraints;
drop table email_tutor_aziendale cascade constraints;

create table corso_laurea (
  codice_corso char(15) primary key, 
  tipo varchar2(15) not null, 
  capienza number not null, 
  nome varchar2(60) not null, 
  constraint check_tipo1 check (
    tipo in (
      'MAGISTRALE', 'TRIENNALE', 'magistrale', 
      'triennale', 'Magistrale', 'Triennale'
    )
  ), 
  constraint check_capienza1 check (capienza > 0)
);


-- totalità rispetto a Corso di Laurea espressa con una NOT NULL sulla relativa FK
create table studente (
  matricola_studente char(15) primary key, 
  nome varchar2(30) not null, 
  cognome varchar2(30) not null, 
  data_nascita date not null, 
  sesso char(1) default 'U', 
  via varchar2(50), 
  numero_civico varchar2(10), 
  CAP char(5), 
  citta varchar2(30), 
  codice_corso char(15) not null, 
  data_iscrizione date not null, 
  constraint check_sesso1 check (
    sesso in ('M', 'F', 'U', 'm', 'f', 'u')
  ), 
  constraint fk_codice_corso1 foreign key (codice_corso) references corso_laurea(codice_corso) on delete cascade, 
  constraint check_date13 check (data_nascita < data_iscrizione)
);

create table docente (
  numero_tesserino char(15) primary key, 
  nome varchar2(30) not null, 
  cognome varchar2(30) not null, 
  data_nascita date not null, 
  sesso char(1) default 'U', 
  via varchar2(50), 
  numero_civico varchar(10), 
  CAP char(5), 
  citta varchar2(30), 
  constraint check_sesso2 check (
    sesso in ('M', 'F', 'U', 'm', 'f', 'u')
  )
);

create table insegnamento (
  codice_insegnamento char(15) primary key, 
  nome varchar2(60) not null
);


-- totalità espressa implicitamente dalla PK rispetto ad insegnamento
create table edizione_insegnamento (
  codice_insegnamento char(15), 
  anno_accademico date, 
  semestre varchar2(15) not null, 
  anno_corso number(1, 0) not null, 
  CFU number(2, 0) not null, 
  svolgimento varchar2(15) not null, 
  constraint pk_edizione_insegnamento primary key (
    codice_insegnamento, anno_accademico
  ), 
  constraint check_semestre1 check (
    semestre in (
      'PRIMO', 'SECONDO', 'ANNUALE', 'Primo', 
      'Secondo', 'Annuale', 'primo', 'secondo', 
      'annuale'
    )
  ), 
  constraint check_anno_corso1 check (
    anno_corso in (1, 2, 3, 4, 5)
  ), 
  constraint check_svolgimento check (
    svolgimento in (
      'Presenza', 'Telematica', 'presenza', 
      'telematica', 'PRESENZA', 'TELEMATICA'
    )
  ), 
  constraint check_CFU3 check(CFU > 0), 
  constraint check_CFU4 check(CFU < 13), 
  constraint fk_codice_insegnamento2 foreign key (codice_insegnamento) references insegnamento(codice_insegnamento) on delete cascade
);



-- totalità espressa implicitamente dalla PK ambo i lati
create table offerta_insegnamento (
  codice_insegnamento char(15), 
  codice_corso char(15), 
  corso_principale char(1) not null, 
  constraint pk_offerta_insegnamento primary key (
    codice_insegnamento, codice_corso
  ), 
  constraint check_corso_principale1 check(
    corso_principale in ('Y', 'y', 'N', 'n')
  ), 
  constraint fk_codice_insegnamento1 foreign key (codice_insegnamento) references insegnamento(codice_insegnamento) on delete cascade, 
  constraint fk_codice_corso2 foreign key (codice_corso) references corso_laurea(codice_corso) on delete cascade
);


-- totalità espressa implicitamente dalla PK ambo i lati sebbene non presente
create table insegna_edizione (
  codice_insegnamento char(15), 
  anno_accademico date, 
  tesserino_docente char(15), 
  tipo_docente varchar2(30) not null, 
  constraint pk_insegna_edizione primary key (
    codice_insegnamento, anno_accademico, 
    tesserino_docente
  ), 
  constraint check_tipo_docente1 check (
    tipo_docente in (
      'TEORIA', 'Teoria', 'teoria', 'LABORATORIO', 
      'Laboratorio', 'laboratorio', 'TEORIA E LABORATORIO', 
      'Teoria e Laboratorio', 'teoria e laboratorio'
    )
  ), 
  constraint fk_tesserino_docente1 foreign key (tesserino_docente) references docente(numero_tesserino) on delete cascade, 
  constraint fk_codice_insegnamento_anno_accademico1 foreign key (
    codice_insegnamento, anno_accademico
  ) references edizione_insegnamento(
    codice_insegnamento, anno_accademico
  ) on delete cascade
);


-- totalità espressa implicitamente dalla PK ambo i lati sebbene non presente
create table frequenta_edizione_insegnamento (
  anno_accademico date, 
  codice_insegnamento char(15), 
  matricola_studente char(15), 
  data_ins date not null, 
  constraint pk_frequenta_edizione_insegnamento primary key (
    anno_accademico, codice_insegnamento, 
    matricola_studente
  ), 
  constraint fk_matricola_studente7 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade, 
  constraint fk_codice_insegnamento_anno_accademico2 foreign key (
    codice_insegnamento, anno_accademico
  ) references edizione_insegnamento(
    codice_insegnamento, anno_accademico
  ) on delete cascade
);

-- totalità rispetto a corso di laurea espressa con la NOT NULL sulla relativa FK
create table appello_laurea (
  data_appello date, 
  codice_corso char(15) not null, 
  inizio_iscrizioni date not null, 
  fine_iscrizioni date not null, 
  tipo varchar2(15) default 'Non previsto', 
  max_iscrizioni number(2, 0) not null, 
  constraint pk_appello_laurea primary key (data_appello, codice_corso), 
  constraint check_max_iscrizioni1 check (max_iscrizioni > 0), 
  constraint check_max_iscrizioni2 check (max_iscrizioni <= 20), 
  constraint check_date2 check (
    inizio_iscrizioni < fine_iscrizioni
  ), 

  constraint check_tipo2 check (
    tipo in (
      'Presenza', 'Telematica', 'PRESENZA', 'TELEMATICA', 
      'presenza', 'telematica', 'Non previsto', 
      'NON PREVISTO', 'non previsto'
    )
  ),
  constraint check_date3 check (data_appello > fine_iscrizioni), 
  constraint check_date4 check (inizio_iscrizioni < data_appello), 
  constraint check_date12 check (inizio_iscrizioni < fine_iscrizioni),
  constraint fk_codice_corso3 foreign key (codice_corso) references corso_laurea(codice_corso) on delete cascade
);


-- totalità espressa implicitamente dalla PK ambo i lati sebbene non presente
create table prenotazione_appello_seduta (
  matricola_studente char(15), 
  codice_corso char(15), 
  data_appello date not null, 
  data_prenotazione date not null, 
  numero char(15) not null unique, 
  constraint pk_prenotazione_appello_seduta primary key (
    matricola_studente, data_appello, 
    codice_corso
  ), 
  constraint check_date5 check (data_prenotazione < data_appello), 
  constraint fk_matricola_studente9 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade, 
  constraint fk_codice_corso_data_appello_laurea1 foreign key (codice_corso, data_appello) references appello_laurea (codice_corso, data_appello) on delete cascade
);


-- totalità espressa implicitamente dalla PK ambo i lati sebbene non presente
create table partecipa_seduta (
  tesserino_docente char(15), 
  data_appello date, 
  codice_corso char(15), 
  presidente char(1) not null, 
  constraint pk_partecipa_seduta primary key (
    tesserino_docente, data_appello, 
    codice_corso
  ), 
  constraint check_presidente2 check (
    presidente in ('y', 'n', 'Y', 'N')
  ), 
  constraint fk_tesserino_docente6 foreign key (tesserino_docente) references docente(numero_tesserino) on delete cascade, 
  constraint fk_codice_corso_data_appello_laurea2 foreign key (codice_corso, data_appello) references appello_laurea (codice_corso, data_appello) on delete cascade
);

-- totalità non espressa rispetto ad appello seduta di laurea
-- totalità espressa rispetto a studente espressa con NOT NULL sulla relativa FK
create table seduta_laurea (
  numero_verbale char(15) primary key, 
  codice_corso char(15), 
  data_seduta date, 
  matricola_studente char(15) unique not null, 
  voto number(3, 0) not null, 
  lode char(1) default 'N', 
  constraint check_voto1 check (voto > 65), 
  constraint check_voto2 check (voto <= 110), 
  constraint check_lode1 check (
    (lode in ('N', 'n') OR (lode in ('Y', 'y') AND (voto = 110)))
  ), 
  constraint fk_codice_corso_data_appello_laurea3 foreign key (codice_corso, data_seduta) references appello_laurea (codice_corso, data_appello) on delete set null, 
  constraint fk_matricola_studente4 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade
);


-- totalità espressa implicitamente dalla PK ambo i lati sebbene non presente
create table relatore (
  matricola_studente char(15), 
  tesserino_docente char(15), 
  data_inizio date not null, 
  data_fine date not null, 
  titolo_tesi varchar2(100), 
  tipo_tesi varchar2(15), 
  constraint pk_relatore primary key (
    matricola_studente, tesserino_docente
  ), 

  constraint check_tipo_tesi1 check (
    tipo_tesi in (
      'Compilativa', 'COMPILATIVA', 'compilativa',
      'Sperimentale', 'SPERIMENTALE', 'sperimentale'
    )
  ), 
  constraint fk_matricola_studente2 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade, 
  constraint fk_tesserino_docente2 foreign key (tesserino_docente) references docente(numero_tesserino) on delete set null, 
  constraint check_date1 check (data_inizio < data_fine)
);

create table azienda (
  partita_iva char(15) primary key, 
  nome varchar2(30) not null, 
  via varchar2(20), 
  numero_civico varchar2(10),
  CAP char(5), 
  citta varchar2(30) not null
);


-- totalità rispetto ad azienda espressa con la NOT NULL sulla relativa FK
create table tutor_aziendale (
  numero_tesserino char(15) primary key, 
  nome varchar2(30) not null, 
  cognome varchar2(30) not null, 
  data_nascita date not null, 
  sesso char(1) default 'U', 
  via varchar2(50), 
  numero_civico varchar2(10),
  CAP char(5), 
  citta varchar2(30), 
  partita_iva char(15) not null, 
  constraint check_sesso3 check (
    sesso in ('M', 'F', 'U', 'm', 'f', 'u')
  ), 
  constraint fk_partita_iva1 foreign key (partita_iva) references azienda(partita_iva) on delete cascade
);


-- totalità rispetto a studente e docente espressa, ma non rispetto a tutor aziendale
-- per come sono impostate le totalità la politica di reazione più appropriata è la ON DELETE CASCADE su studente e sulle altre ON DELETE SET NULL
create table tirocinio (
  numero_tirocinio char(15) primary key, 
  CFU number(2, 0) not null, 
  data_inizio date not null, 
  data_fine date not null, 
  tesserino_docente char(15) not null, 
  tesserino_tutor_azienda char(15), 
  matricola_studente char(15) not null unique, 
  constraint fk_tesserino_docente4 foreign key (tesserino_docente) references docente(numero_tesserino) on delete set null, 
  constraint fk_matricola_studente5 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade, 
  constraint fk_tesserino_tutor_aziendale1 foreign key (tesserino_tutor_azienda) references tutor_aziendale(numero_tesserino) on delete set null, 
  constraint check_date7 check (data_inizio < data_fine), 
  constraint check_CFU1 check (CFU > 0), 
  constraint check_CFU2 check (CFU < 13)
);

-- totalità rispetto a edizione insegnamento espressa implicitamente dalla PK
-- totalità rispetto a docente e a studente espressa con NOT NULL
create table questionario (
  numero_questionario char(15), 
  codice_insegnamento char(15), 
  anno_accademico date, 
  materiale_didattico number(1, 0) not null, 
  gradimento number(1, 0) not null, 
  disponibilita_docente number(1, 0) not null, 
  precisione_orario number(1, 0) not null, 
  tesserino_docente char(15) not null, 
  matricola_studente char(15) not null, 
  data_compilazione date not null, 
  constraint pk_questionario primary key (
    numero_questionario, codice_insegnamento, 
    anno_accademico
  ), 
  constraint check_materiale_didattico1 check (materiale_didattico > 0), 
  constraint check_materiale_didattico2 check (materiale_didattico <= 5), 
  constraint check_gradimento1 check (gradimento > 0), 
  constraint check_gradimento2 check (gradimento <= 5), 
  constraint check_disponibilita_docente1 check (disponibilita_docente > 0), 
  constraint check_disponibilita_docente2 check (disponibilita_docente <= 5), 
  constraint check_precisione_orario1 check (precisione_orario > 0), 
  constraint check_precisione_orario2 check (precisione_orario <= 5), 
  constraint fk_codice_insegnamento_anno_accademico3 foreign key (
    codice_insegnamento, anno_accademico
  ) references edizione_insegnamento(
    codice_insegnamento, anno_accademico
  ) on delete cascade, 
  constraint fk_matricola_studente18 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade, 
  constraint fk_tesserino_docente10 foreign key (tesserino_docente) references docente(numero_tesserino) on delete cascade
);


-- totalità espressa implicitamente dalla PK rispetto a edizione insegnamento
create table appello (
  anno_accademico date, 
  data_appello date, 
  codice_insegnamento char(15), 
  data_inizio date not null, 
  data_fine date not null, 
  max_studenti number(3, 0) not null, 
  tipo varchar2(15) default 'Non previsto', 
  constraint pk_appello primary key (
    anno_accademico, data_appello, codice_insegnamento
  ), 
  constraint check_max_studenti1 check (max_studenti > 0), 
  constraint check_tipo3 check (
    tipo in (
      'Orale', 'ORALE', 'orale', 'scritto', 
      'Scritto', 'SCRITTO', 'Non previsto', 
      'NON PREVISTO', 'non previsto'
    )
  ), 
  constraint check_date6 check (data_inizio < data_fine), 
  constraint check_date10 check (data_inizio < data_appello), 
  constraint check_date11 check (data_fine < data_appello), 
  constraint fk_codice_insegnamento_anno_accademico4 foreign key (
    codice_insegnamento, anno_accademico
  ) references edizione_insegnamento(
    codice_insegnamento, anno_accademico
  ) on delete cascade
);


-- totalità espressa implicitamente dalla PK
create table orario_lezioni (
  giorno_e_ora date, 
  anno_accademico date, 
  codice_insegnamento char(15), 
  constraint pk_orario_lezioni primary key (
    giorno_e_ora, anno_accademico, codice_insegnamento
  ), 
  constraint fk_codice_insegnamento_anno_accademico5 foreign key (
    codice_insegnamento, anno_accademico
  ) references edizione_insegnamento(
    codice_insegnamento, anno_accademico
  ) on delete cascade
);

-- totalità espressa implicitamente dalla PK
create table seminario (
  data_seminario date, 
  tesserino_docente char(15), 
  nome varchar2(30), 
  CFU number(2, 0) not null, 
  max_persone number(3, 0) not null, 
  constraint pk_seminario primary key (
    data_seminario, tesserino_docente
  ), 
  constraint check_max_persone1 check (max_persone > 0), 
  constraint fk_tesserino_docente5 foreign key (tesserino_docente) references docente(numero_tesserino) on delete set null, 
  constraint check_CFU6 check (CFU >= 0)
);


-- totalità espressa implicitamente dalla PK ambo i lati sebbene non presente
create table presiede_appello (
  anno_accademico date, 
  data_appello date, 
  codice_insegnamento char(15), 
  tesserino_docente char(15), 
  presidente char(1) not null, 
  constraint pk_presiede_appello primary key (
    anno_accademico, data_appello, codice_insegnamento, 
    tesserino_docente
  ), 
  constraint check_presidente1 check (
    presidente in ('y', 'n', 'Y', 'N')
  ), 
  constraint fk_tesserino_docente13 foreign key (tesserino_docente) references docente(numero_tesserino) on delete cascade, 
  constraint fk_codice_insegnamento_anno_accademico_data_appello1 foreign key (
    codice_insegnamento, anno_accademico, 
    data_appello
  ) references appello(
    codice_insegnamento, anno_accademico, 
    data_appello
  ) on delete cascade
);


-- totalità espressa implicitamente dalla PK
create table ricevimento (
  data_ricevimento date, 
  tesserino_docente char(15), 
  durata number(3, 0) default 0, 
  constraint pk_ricevimento primary key (
    data_ricevimento, tesserino_docente
  ), 
  constraint fk_tesserino_docente15 foreign key (tesserino_docente) references docente(numero_tesserino) on delete cascade
);


-- totalità rispetto a studente espressa con la NOT NULL
-- totalità rispetto ad appello non può essere espressa
create table esame_superato (
  numero_verbale char(15) primary key, 
  voto number(2) not null, 
  lode char(1) not null, 
  data_esame date, 
  anno_accademico date, 
  codice_insegnamento char(15), 
  matricola_studente char(15) not null, 
  constraint check_voto3 check (voto > 17), 
  constraint check_voto4 check (voto <= 30), 
  constraint check_lode2 check (
    (lode in ('N', 'n') OR (lode in ('Y', 'y') AND (voto = 30)))
  ),
  constraint check_univocita_studente unique(matricola_studente, codice_insegnamento), 
  constraint fk_codice_insegnamento_anno_accademico_data_appello2 foreign key (
    codice_insegnamento, anno_accademico, 
    data_esame
  ) references appello(
    codice_insegnamento, anno_accademico, 
    data_appello
  ) on delete set null, 
  constraint fk_matricola_studente13 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade
);


-- totalità espressa implicitamente dalla PK ambo i lati sebbene non presente
create table prenotazione_ricevimento (
  numero_prenotazione char(15) not null unique, 
  data_ricevimento date, 
  tesserino_docente char(15), 
  matricola_studente char(15), 
  data_prenotazione date not null, 
  constraint pk_prenotazione_ricevimento primary key (
    data_ricevimento, tesserino_docente, 
    matricola_studente
  ), 
  constraint fk_data_ricevimento_docente1 foreign key (
    data_ricevimento, tesserino_docente
  ) references ricevimento(
    data_ricevimento, tesserino_docente
  ) on delete cascade, 
  constraint fk_matricola_studente19 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade, 
  constraint check_date8 check (
    data_prenotazione < data_ricevimento
  )
);


-- totalità espressa implicitamente dalla PK ambo i lati sebbene non presente
create table prenotazione_appello (
  anno_accademico date, 
  data_appello date, 
  codice_insegnamento char(15), 
  matricola_studente char(15), 
  numero_prenotazione char(15) not null, 
  data_prenotazione date not null, 
  constraint pk_prenotazione_appello primary key (
    anno_accademico, data_appello, codice_insegnamento, 
    matricola_studente
  ), 
  constraint fk_matricola_studente12 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade, 
  constraint fk_codice_insegnamento_anno_accademico_data_appello3 foreign key (
    codice_insegnamento, anno_accademico, 
    data_appello
  ) references appello(
    codice_insegnamento, anno_accademico, 
    data_appello
  ) on delete cascade, 
  constraint check_date9 check (data_prenotazione < data_appello)
);


-- totalità rispetto a studente espressa a differenza di quanto riportato nel relazionale
create table tassa (
  numero_fattura char(15) primary key, 
  scadenza date not null, 
  importo number(3, 0) not null, 
  matricola_studente char(15) not null, 
  data_pagamento date, 
  mora number(3, 0) default 0, 
  IUV char(25), 
  tipo varchar2(15), 
  constraint check_importo1 check (importo > 0), 
  constraint fk_matricola_studente15 foreign key (matricola_studente) references studente(matricola_studente) on delete set null
);


-- totalità espressa implicitamente dalla PK ambo i lati sebbene non presente
-- In questo caso la politica di reazione più appropriata è on delete cascade se viene cancellato uno studente e on delete se null se viene cancellato il seminario
create table partecipa_seminario (
  data_seminario date, 
  tesserino_docente char(15), 
  matricola_studente char(15), 
  constraint pk_partecipa_seminario primary key (
    data_seminario, tesserino_docente, 
    matricola_studente
  ), 
  constraint fk_matricola_studente20 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade, 
  constraint fk_data_seminario_tesserino_docente1 foreign key (
    data_seminario, tesserino_docente
  ) references seminario(
    data_seminario, tesserino_docente
  ) on delete set null
);

create table bando_borsa (
  numero_bando_borsa char(15) primary key, 
  scadenza date not null, 
  data_emissione date not null, 
  valore number(4, 0) not null, 
  causale varchar2(25), 
  tipo varchar2(25), 
  numero_borse number(4, 0) not null, 
  constraint check_numero_borse1 check (numero_borse > 0), 
  constraint check_valore1 check (valore > 0), 
  constraint check_date14 check (data_emissione < scadenza)
);

create table bando_erasmus (
  numero_bando_erasmus char(15) primary key, 
  scadenza date not null, 
  data_emissione date not null, 
  CFU number(2, 0) not null, 
  numero_posti number(3, 0) not null, 
  constraint check_numero_posti1 check (numero_posti > 0), 
  constraint check_CFU5 check (CFU > 0), 
  constraint check_date15 check (data_emissione < scadenza)
);


-- totalità espressa implicitamente dalla PK ambo i lati sebbene non presente
create table partecipazione_bando_borsa (
  numero_bando_borsa char(15), 
  matricola_studente char(15), 
  data_domanda date not null, 
  constraint pk_partecipazione_bando_borsa primary key (
    numero_bando_borsa, matricola_studente
  ), 
  constraint fk_matricola_studente8 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade, 
  constraint fk_numero_bando_borsa1 foreign key (numero_bando_borsa) references bando_borsa(numero_bando_borsa) on delete cascade
);


-- totalità espressa implicitamente dalla PK ambo i lati sebbene non presente
create table partecipazione_bando_erasmus (
  numero_bando_erasmus char(15), 
  matricola_studente char(15), 
  data_domanda date not null, 
  constraint pk_partecipazione_bando_erasmus primary key (
    numero_bando_erasmus, matricola_studente
  ), 
  constraint fk_matricola_studente10 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade, 
  constraint fk_numero_bando_erasmus1 foreign key (numero_bando_erasmus) references bando_erasmus(numero_bando_erasmus) on delete set null
);


-- totalità espressa implicitamente dalla PK ambo i lati sebbene non presente
create table assegnazione_erasmus (
  numero_bando_erasmus char(15), 
  matricola_studente char(15), 
  data_assegnazione date not null, 
  localita varchar2(30), 
  nome_universita varchar2(25), 
  data_partenza date not null, 
  data_rientro date not null, 
  constraint pk_assegnazione_bando_erasmus primary key (
    numero_bando_erasmus, matricola_studente
  ), 
  constraint fk_numero_bando_erasmus2 foreign key (numero_bando_erasmus) references bando_erasmus(numero_bando_erasmus) on delete set null, 
  constraint fk_matricola_studente17 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade, 
  constraint check_date16 check (data_partenza < data_rientro), 
  constraint check_date17 check (
    data_assegnazione < data_partenza
  ), 
  constraint check_date18 check (data_assegnazione < data_rientro)
);


-- totalità espressa implicitamente dalla PK ambo i lati sebbene non presente
create table assegnazione_borse (
  numero_bando_borsa char(15), 
  matricola_studente char(15), 
  data_assegnazione date not null, 
  constraint pk_assegnazione_bando_borsa primary key (
    numero_bando_borsa, matricola_studente
  ), 
  constraint fk_numero_bando_borsa2 foreign key (numero_bando_borsa) references bando_borsa(numero_bando_borsa) on delete cascade, 
  constraint fk_matricola_studente16 foreign key (matricola_studente) references studente(matricola_studente) on delete set null
);


-- totalità espressa implicitamente dalla PK
create table telefono_studente (
  numero_telefono_studente char(10), 
  matricola_studente char(15), 
  constraint pk_telefono_studente primary key (
    numero_telefono_studente, matricola_studente
  ), 
  constraint fk_matricola_studente21 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade
);


-- totalità espressa implicitamente dalla PK
create table telefono_docente (
  numero_telefono_docente char(10), 
  tesserino_docente char(15), 
  constraint pk_telefono_docente primary key (
    numero_telefono_docente, tesserino_docente
  ), 
  constraint fk_tesserino_docente12 foreign key (tesserino_docente) references docente(numero_tesserino) on delete cascade
);


-- totalità espressa implicitamente dalla PK
create table telefono_tutor_aziendale (
  numero_telefono_tutor_aziendale char(10), 
  tesserino_tutor_azienda char(15), 
  constraint pk_telefono_tutor_aziendale primary key (
    numero_telefono_tutor_aziendale, 
    tesserino_tutor_azienda
  ), 
  constraint fk_tesserino_tutor_aziendale2 foreign key (tesserino_tutor_azienda) references tutor_aziendale(numero_tesserino) on delete cascade
);


-- totalità espressa implicitamente dalla PK
create table email_studente (
  mail_studente varchar2(50), 
  matricola_studente char(15), 
  constraint pk_email_studente primary key (
    mail_studente, matricola_studente
  ), 
  constraint fk_matricola_studente22 foreign key (matricola_studente) references studente(matricola_studente) on delete cascade,
  constraint email_studente check (REGEXP_LIKE(mail_studente, '^[A-Za-z]+\.[A-Za-z]+[0-9]+@studenti.uniparthenope.it$'))
);


-- totalità espressa implicitamente dalla PK 
create table email_docente (
  mail_docente varchar2(50), 
  tesserino_docente char(15), 
  constraint pk_email_docente primary key (mail_docente, tesserino_docente), 
  constraint fk_tesserino_docente14 foreign key (tesserino_docente) references docente(numero_tesserino) on delete cascade,
  constraint email_docente check (REGEXP_LIKE(mail_docente, '^[A-Za-z]+\.[A-Za-z]+@uniparthenope.it$'))
);


-- totalità espressa implicitamente dalla PK
create table email_tutor_aziendale (
  mail_tutor_aziendale varchar2(50), 
  tesserino_tutor_azienda char(15), 
  constraint pk_email_tutor_aziendale primary key (
    mail_tutor_aziendale, tesserino_tutor_azienda
  ), 
  constraint fk_tesserino_tutor_aziendale3 foreign key (tesserino_tutor_azienda) references tutor_aziendale(numero_tesserino) on delete cascade,
  constraint email_tutor_aziendale check (REGEXP_LIKE(mail_tutor_aziendale, '^[A-Za-z]+\.[A-Za-z]+@uniparthenope.it$'))
);
