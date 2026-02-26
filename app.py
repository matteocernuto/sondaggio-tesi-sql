import streamlit as st
import pandas as pd
from datetime import datetime
import os

st.set_page_config(page_title="Valutazione AI SQL - Sondaggio Tesi", layout="centered")

# ==========================================
# INIEZIONE CSS CUSTOM (Per rimpicciolire il font)
# ==========================================
st.markdown("""
<style>
/* Rimpicciolisce il carattere all'interno dei blocchi di codice */
.stCodeBlock code {
    font-size: 13px !important;
    line-height: 1.4 !important;
}
</style>
""", unsafe_allow_html=True)

def save_response(data):
    filename = "risposte_sondaggio.csv"
    df_new = pd.DataFrame([data])
    if not os.path.exists(filename):
        df_new.to_csv(filename, index=False, sep=';')
    else:
        df_new.to_csv(filename, mode='a', header=False, index=False, sep=';')

def load_sql_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as file:
            return file.read()
    except FileNotFoundError:
        return f"-- Errore: Impossibile trovare il file '{filepath}'. Assicurati che sia nella cartella dello script."

# ==========================================
# CARICAMENTO DELLE QUERY
# ==========================================
sql_2w_ai = load_sql_file("2W_Commenti_Errori.sql")
sql_2w_gold = load_sql_file("CLEAN_sp_REA_PrelieviCarteEstero_DueSoglie.sql")

sql_0b_ai = load_sql_file("0B_Commenti_Errori.sql")
sql_0b_gold = load_sql_file("CLEAN_sp_REA_Operazioni_ATECO_Sensibili_Paesi_Rischiosi.sql")

# ==========================================
# 1. INTRODUZIONE E PIPELINE
# ==========================================
st.title("Valutazione Generazione SQL tramite AI")

st.markdown("""
Benvenuto e grazie per il tuo tempo. Questo sondaggio ha lo scopo di valutare l'output di un'architettura AI (LLM) progettata per tradurre configurazioni di business (regole Anti-Money Laundering) direttamente in Stored Procedure SQL Server.

L'obiettivo è generare solo la parte di logica di estrazione della procedura di calcolo per estrarre cluster, soggetti e operazioni che fanno scattare la regola.
""")

try:
    st.image("diagramma.png", caption="Rappresentazione sintetica dell'interazione tra gli agenti LLM", use_container_width=True)
except FileNotFoundError:
    st.write("[Immagine del diagramma non trovata. Caricare il file corrispondente nella directory.]")

st.markdown("""
Questo diagramma rappresenta la pipeline in modo molto sintetico di come interagiscono i vari agenti LLM per generare la logica.

Di seguito verranno mostrati due casi tipici di errori che bloccano l'esecuzione in SQL e anche errori di interpretazione delle configurazioni della CFG 11 e 12. 
Il primo caso comprende gli errori più semplici da sistemare che riguardano principalmente le condizioni di filtro (clausola WHERE), mentre il secondo caso mostra un errore dove la logica da implementare è più complessa e la generazione sbaglia di molto.

Da tenere in considerazione che, anche se venissero risolti questi problemi sintattici, ci sarebbe comunque da controllare la corretta implementazione delle logiche per ottenere la query definitiva.
""")

st.divider()

# ==========================================
# SEZIONE 1: CASO 2W
# ==========================================
st.header("Caso Studio 1: Errori di Parametri (Regola 2W)")
st.markdown("""
In questo scenario, il modello riceve in input una regola per i prelievi all'estero.
La sintassi prodotta è corretta, ma il modello ha inventato alcuni codici filtro non presenti nei parametri, causando un'estrazione nulla.

**Righe estratte dalla configurazione (CFG 11/12):**
* SottoAmbito_ID: 21
* Descrizione: Prelievi all'estero con carte
* Soglia: Importo > 1000
""")

st.info("⚠️ **Nota bene:** Nelle schede 'Query Originale' mostrate di seguito, è stata estratta solo la parte di logica di interesse per il confronto, omettendo l'inizializzazione dei parametri e le variabili di contorno.")

tab1_2w, tab2_2w = st.tabs(["Query Generata dall'AI", "Query Originale (Gold Standard)"])

# AGGIUNTO IL PARAMETRO wrap_lines=True PER IL WORD WRAP
with tab1_2w:
    st.code(sql_2w_ai, language="sql", wrap_lines=True)
with tab2_2w:
    st.code(sql_2w_gold, language="sql", wrap_lines=True)

st.markdown("**Domanda 1: Facilità di correzione**")
q1 = st.radio(
    "Quanto ritieni sia semplice per uno sviluppatore SQL (conoscendo le logiche aziendali) individuare e correggere questa tipologia di errore sui parametri?",
    options=[
        "[ 1 ] Molto difficile (L'errore è subdolo e difficile da debuggare)",
        "[ 2 ] Difficile",
        "[ 3 ] Neutro",
        "[ 4 ] Facile",
        "[ 5 ] Molto facile (Basta aggiornare i valori nella clausola IN)"
    ]
)

st.markdown("**Domanda 2: Risparmio di tempo netto**")
q2 = st.radio(
    "Considerando l'impalcatura generale già scritta dall'AI (struttura INSERT, sintassi, aliasing e le 6 JOIN principali azzeccate), quanto tempo pensi di risparmiare partendo da questa bozza rispetto a scrivere l'intera query da zero?",
    options=[
        "Nessun risparmio (Ci metto meno a riscriverla da zero)",
        "Risparmio marginale (Meno del 25% del tempo)",
        "Risparmio discreto (Circa il 50% del tempo)",
        "Alto risparmio (Tra il 50% e il 75% del tempo)",
        "Altissimo risparmio (Più del 75% del tempo risparmiato)"
    ]
)

st.divider()

# ==========================================
# SEZIONE 2: CASO 0B
# ==========================================
st.header("Caso Studio 2: Errori di Logica e Struttura (Regola 0B)")
st.markdown("""
Qui la logica richiesta è più articolata. Il codice compila, ma presenta un errore di JOIN strutturale (viene usata una tabella base al posto della vista corretta) e un filtro OR subottimale a livello prestazionale.

**Righe estratte dalla configurazione (CFG 11/12):**
* SottoAmbito_ID: 21
* Descrizione: Monitoraggio ATECO a rischio in transazioni internazionali
* Soglia: Importo >= 30000
""")

tab1_0b, tab2_0b = st.tabs(["Query Generata dall'AI", "Query Originale (Gold Standard)"])

# AGGIUNTO IL PARAMETRO wrap_lines=True PER IL WORD WRAP
with tab1_0b:
    st.code(sql_0b_ai, language="sql", wrap_lines=True)
with tab2_0b:
    st.code(sql_0b_gold, language="sql", wrap_lines=True)

st.markdown("**Domanda 3: Effort di Refactoring vs. Riscrittura**")
q3 = st.radio(
    "Di fronte a una query complessa che presenta errori architetturali e di schema linking come questa, quale approccio operativo riterresti più efficiente per arrivare alla versione corretta per la produzione?",
    options=[
        "Riscrivere da zero: Gli errori logici 'sporcano' troppo il codice, preferirei usare la bozza solo come spunto visivo e scrivere la mia query.",
        "Correggere la bozza dell'AI: Riscrivere i filtri errati e correggere le JOIN richiede comunque meno sforzo cognitivo e manuale rispetto a digitare tutto il blocco DML da zero."
    ]
)

st.markdown("**Domanda 4: Valutazione dell'impalcatura (Base di partenza)**")
q4 = st.radio(
    "Al netto degli errori specifici sui filtri, valuta la bontà della 'struttura scheletro' proposta dall'AI (creazione delle temporanee ##TempSintesi/##TempDettaglio, estrazione delle chiavi, raggruppamento). Quanto la ritieni una base solida su cui lavorare?",
    options=[
        "[ 1 ] Per nulla solida (Struttura inusabile)",
        "[ 2 ] Poco solida",
        "[ 3 ] Accettabile (Richiede pesanti rimaneggiamenti ma ha un senso)",
        "[ 4 ] Solida (Buona impostazione procedurale)",
        "[ 5 ] Molto solida (Impostazione eccellente, basta solo fixare la logica interna)"
    ]
)

st.divider()

# ==========================================
# SEZIONE 3: GENERALE
# ==========================================
st.header("Valutazione Generale: Impatto sulla Produttività")

st.markdown("**Domanda 5: Impatto complessivo sulla produttività aziendale**")
q5 = st.radio(
    "Immagina di avere questo strumento integrato nel tuo ambiente di lavoro: un assistente che prende in pasto un file di configurazione grezzo (CSV) e ti genera in automatico queste bozze pre-formattate per ogni regola. Quale pensi sarebbe l'impatto complessivo sui tuoi tempi di sviluppo quotidiani?",
    options=[
        "[ 1 ] Impatto Negativo: Fare QA sul codice generato mi farebbe perdere più tempo che scriverlo da solo.",
        "[ 2 ] Impatto Nullo: Non cambierebbe significativamente le mie tempistiche.",
        "[ 3 ] Impatto Moderato: Rimuoverebbe il lavoro ripetitivo (es. scrivere le JOIN standard), facendomi risparmiare un po' di tempo.",
        "[ 4 ] Impatto Elevato: Velocizzerebbe notevolmente la prima stesura, lasciandomi solo l'onere del fine-tuning logico.",
        "[ 5 ] Impatto Trasformativo: Cambierebbe radicalmente la velocità di rilascio, abbattendo drasticamente i tempi di sviluppo delle estrazioni."
    ]
)

commenti = st.text_area("Hai ulteriori commenti o suggerimenti tecnici sull'impalcatura prodotta? (Opzionale)")

# ==========================================
# INVIO DATI
# ==========================================
st.write("")
if st.button("Invia Risposte", type="primary"):
    response_data = {
        "Timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "D1_Facilita_Correzione": q1.split("]")[0].replace("[", "").strip(),
        "D2_Risparmio_Tempo": q2.split("(")[0].strip(),
        "D3_Refactoring_vs_Riscrittura": q3.split(":")[0].strip(),
        "D4_Valutazione_Impalcatura": q4.split("]")[0].replace("[", "").strip(),
        "D5_Impatto_Produttivita": q5.split("]")[0].replace("[", "").strip(),
        "Commenti_Aggiuntivi": commenti
    }
    save_response(response_data)
    st.success("La tua risposta è stata registrata con successo. Grazie per la collaborazione.")