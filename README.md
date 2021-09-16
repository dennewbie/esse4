# esse4
![projectLogo](https://github.com/dennewbie/esse4/blob/main/documentazione/img.png)
## Progetto di Basi di Dati e Laboratorio di Basi di Dati - Università "Parthenope"

### Team: 
- [Max](https://github.com/gomax21)
- [Alfredo](https://github.com/AlfredoTerabait)
- [Denny](https://github.com/dennewbie)

### Descrizione 
Categoria: Portale Studenti
Si vuole realizzare la gestione di un portale studenti. A partire da profonde analisi, discussioni e conversazioni, sono scaturiti i requisiti seguenti. Il database deve riprodurre (per quanto possibile) il funzionamento di un noto portale studenti che permette di fornire i cosiddetti “Servizi Informatici” per Studenti e Docenti. In particolare, occorre tenere traccia dei seguenti aspetti:
- Studenti
	- pagamento delle tasse
	- partecipazione seminari
	- prenotazione ricevimenti
	- esami superati
	- edizioni degli insegnamenti frequentati
	- compilazione questionari edizioni insegnamenti
	- prenotazione appelli
	- prenotazione e conseguimento borse di studio
	- prenotazione e conseguimento progetti Erasmus
	- partecipazione seminari
	- prenotazione appelli seduta di laurea, lauree conseguite o conseguimento tirocini formativi
- Docenti
	- organizzazione seminari
	- tutoraggio tirocini
	- relatori studenti
	- pianificazione ricevimenti studenti
	- pianificazione appelli
	- pianificazione appelli seduta di laurea
	- edizioni dell’insegnamento in cui è coinvolto e per i quali vien valutato
- Corsi di Laurea
	- insegnamenti proposti e edizioni degli insegnamenti attualmente attive o studenti iscritti e laureati


Gli studenti devono essere in grado di connettersi al database, visualizzare i dettagli delle tasse, effettuare il loro pagamento, visualizzare eventuali more dovute a ritardi nei pagamenti, nonché la conferma di avvenuto pagamento.Uno studente collegato al portale studenti ha la possibilità di:

- partecipare a un seminario tenuto da un docente (prenderemo in esame successivamente il ruolo di un docente generico). Ciò è possibile solo se non è stata raggiunta la capienza massima di studenti prevista per quel seminario. Ogni seminario ha un nome, una data e un’ora di inizio. Uno studente in seguito alla partecipazione ad un seminario riceve un certo numero di CFU (Crediti Formativi Universitari). Un seminario non può esistere se non esiste il docente organizzatore
- effettuare una prenotazione per un ricevimento con un determinato docente. All’atto della prenotazione, viene stabilito il turno dello studente sotto forma di numero e la data
in cui è avvenuta la prenotazione. Ogni ricevimento di un docente ha una data e un’ora di inizio prefissata, nonché una durata prevista approssimativa. Un ricevimento dipende strettamente dal docente che riceve
- compilare il questionario relativamente a un docente per una determinata edizione dell’insegnamento che l’ha visto come insegnante di un certo tipo (per esempio di teoria e/o di laboratorio). Il questionario riguarda diversi aspetti di valutazione come il rispetto dell’orario delle lezioni da parte del docente, la sua disponibilità, il gradimento generale dell’edizione dell’insegnamento insegnata dal docente e la qualità del materiale didattico fornito dal docente per quella specifica edizione di un insegnamento. Prima di poter sostenere un esame, uno studente deve compilare il questionario. Inoltre, studenti fuoricorso non possono compilare nuovamente il questionario se frequentano di nuovo il corso
- prenotarsi per più appelli di una determinata edizione di insegnamento. Ogni appello è contraddistinto dal codice dell’insegnamento, dall’anno accademico e dalla data dell’appello. Inoltre, presenta alcune informazioni come la data di inizio iscrizione, la data di fine iscrizione, il numero degli studenti consentiti per quell’appello e il tipo di appello (prova scritta, orale, etc.). Uno studente che effettua una prenotazione per un appello riceve un numero di prenotazione e viene memorizzata la data di avvenuta prenotazione. Non si gestiscono appelli riservati per particolari categorie di studenti (es. appelli riservati solo ai fuoricorso)
- frequentare più edizioni insegnamento. Un’edizione insegnamento è identificata univocamente grazie ad un codice di insegnamento e ad un anno accademico di riferimento. Inoltre, presenta diverse informazioni di cui si vuole tenere traccia come i CFU, le modalità di svolgimento di quella determinata edizione dell’insegnamento, l’orario delle lezioni, il semestre e l’anno di corso lungo il quale viene erogato. Un insegnamento generico invece è semplicemente identificato dal suo codice e inoltre fornisce informazione sul nome di quell’insegnamento. La differenza tra insegnamento e edizione insegnamento sta nel fatto che l’edizione insegnamento fa riferimento a quello specifico anno accademico e non all’insegnamento in quanto corso caratterizzante di uno specifico corso di laurea. Si è fatto questo tipo di scelta per modellare la possibilità del docente di insegnare delle edizioni di un insegnamento e non l’insegnamento in sé. Inoltre, i questionari e gli appelli, così come i docenti hanno tra loro una correlazione semantica molto più stretta con edizione insegnamento, piuttosto che con l’insegnamento generico
- può superare o meno un esame, in seguito alla partecipazione ad un appello. In tal caso si vuole memorizzare il numero di verbale, il voto e l’eventuale lode associata all’esame superato dallo studente. Uno studente è iscritto a un solo corso di laurea per volta con una determinata matricola identificante. Infatti, si presuppone che anche al variare della matricola per un passaggio di corso triennale a uno magistrale, la matricola cambi e lo studente venga memorizzato come un nuovo studente, con una nuova matricola che di conseguenza è associata ad un solo corso di laurea, con l’eventuale convalida più o meno corposa degli esami svolti nella sua precedente carriera universitaria. Invece, è chiaro che è ad un corso di laurea possono essere iscritti più studenti. Di un corso di laurea ci interessa memorizzare il nome, la capienza in termini di numero di studenti ammessi, il tipo di laurea cioè se triennale o magistrale e il codice identificativo del corso di laurea. Un corso di laurea offre un certo numero di insegnamenti che possono essere insegnamenti principali come un insegnamento di “Basi di Dati e Laboratorio di Basi di Dati” per il Corso di Studi di “Informatica” oppure “affini/integrativi” come un insegnamento di “Economia e Organizzazione Aziendale” per lo stesso Corso di Studi
- effettuare più tirocini come attività obbligatoria prevista per il suo piano carriera al fine di raggiungere una determinata quota di CFU previsti per il suo Corso di Studi. Un tirocinio è identificato dal numero di tirocinio ed è necessario tenere traccia del numero di CFU erogati con quel tirocinio, della data di inizio e fine del tirocinio stesso. Un tirocinio può essere svolto con l’Università o con un’azienda presente nell’insieme di aziende previste dall’Università presso le quali è possibile svolgere il tirocinio. Un tirocinio ha un tutor aziendale e un tutor in quanto docente. Nel primo caso si tratta di una figura presente nel contesto aziendale di cui è necessario conoscere il numero tesserino, l’anagrafica e lo stipendio. Inoltre, un tutor aziendale fa capo a un’azienda presso la quale è stato assunto in una determinata data e per un certo periodo. Dell’azienda alla quale fa capo il tutor aziendale, è necessario memorizzare la Partita IVA, il nome e l’indirizzo.
- fare domanda per più bandi Erasmus, ma non è detto che ne vinca uno. Quando partecipa a uno di essi, viene memorizzata la data di domanda, mentre quando ne viene assegnato uno a tale studente, si vuole conoscere la data di assegnazione, la data di partenza, di rientro, l’università di destinazione e la località. Infine, di un bando Erasmus, si vuole conoscere il codice identificativo del bando, la data di emissione, la scadenza, il numero di CFU che vengono conseguiti vincendo quel bando e il numero di posti disponibili. Analogamente, uno studente può fare richiesta di più borse di studio, ma non è detto che gli venga assegnata. Quando questi partecipa a un bando di borsa di studio, viene memorizzata la data di domanda, mentre quando ne viene assegnata una a tale studente, si memorizza la data di assegnazione. Infine, di un bando di borsa di studio, si vuole tenere traccia del codice identificativo del bando, il tipo di borsa di studio per il quale si concorre, la causale, il valore netto in termini di denaro, la data di emissione del bando, la scadenza e il numero di borse di studio disponibili.
- può prenotarsi ad un appello di seduta di laurea, al termine della sua carriera universitaria. All’atto della prenotazione, lo studente riceve un numero di prenotazione e si memorizza la data di avvenuta prenotazione. Uno studente può prenotarsi a più appelli di seduta di laurea, senza però presentarsi alla seduta di laurea stessa. Per ogni appello di seduta di laurea è essenziale conoscere la data e il codice del corso di laurea di riferimento che permettono di identificare univocamente un appello di seduta di laurea, la data di inizio e fine iscrizione, il tipo e il numero di studenti consentiti. Mentre per una seduta di laurea, sostenuta da uno studente, è necessario conoscere il verbale della seduta di laurea, il voto assegnato, l’eventuale lode e il tipo. In un appello di seduta di laurea possono esservi più sedute di laurea, ognuna relativa ad uno studente.



Al fine della seduta di laurea, uno studente può avere più relatori ed è necessario conoscere la data di inizio e di fine che identifica il periodo lungo il quale un relatore svolge tale ruolo, il tipo e il titolo della tesi. Un relatore non è altro che un docente.
Di un docente si vuole tenere traccia del suo numero di tesserino che permette di identificarlo univocamente e dell’anagrafica.
Un docente ha la possibilità di:
- insegnare più insegnamenti e più edizioni di tali insegnamenti, che fanno riferimento ad anno accademico differenti
- organizzare seminari, senza eventuali vincoli sul numero o sull’argomento trattato
- pianificare ricevimenti oppure appelli. Per quest’ultimi viene adottata una particolare politica che consente di evitare accavallamenti tra appelli relativi ad edizioni di insegnamento e quindi ad insegnamenti relativi a Corsi di Studi per i quali tale docente insegna. I docenti sostengono
più ricevimenti in un giorno, magari di diversi insegnamenti e di diversi corsi di laurea.
- essere presidente presso gli appelli che presiede oppure presso gli appelli di seduta di laurea di
cui fa parte
- essere assegnato ad un tirocinio interno. In particolare, la politica adottata consiste
nell’assegnare il docente che è stato assegnato a meno tirocini
- visionare gli studenti che in un dato momento, sono prenotati per quel ricevimento in un
determinato giorno.
- ricoprire il ruolo di relatore per gli studenti interessati, al termine della loro carriera
universitaria.


Inoltre, un docente è valutato a partire dai questionari relativi ad una determinata edizione di insegnamento che insegna svolgendo un certo ruolo.
Nel caso una prenotazione di un appello, appello di laurea, ricevimento sia cancellata, lo slot diventa nuovamente disponibile. I dati delle prenotazioni sono conservati per un determinato periodo di tempo, dopodiché vengono cancellati. Le politiche accennate sono implementate mediante procedure, le quali vengono discusse nel dettaglio nella sezione “Procedure” del capitolo “Progettazione”.

#### [clicca qui per continuare la lettura della documentazione](https://github.com/dennewbie/esse4/blob/main/documentazione/relazione_progetto_esse4.pdf)

### Credenziali ripristino DUMP:
nome
password
In caso di malfunzionamento del file dump, usare l'approccio "manuale".

c##db_esse4
dbes
