CREATE TABLE ##TempSintesi (
    Cluster_ID INT
    ,Cluster_Version INT
    ,SommaConteggio DECIMAL(15, 2)
    ,Soggetto_ID INT
    ,Soggetto_Version INT
);

CREATE TABLE ##TempDettaglio (
    Cluster_ID INT
    ,Cluster_Version INT
    ,IDRDD BIGINT
);

INSERT INTO ##TempSintesi (
    Cluster_ID
    ,Cluster_Version
    ,SommaConteggio
)
SELECT CLU01.ID AS Cluster_ID
    ,CLU01.Versione AS Cluster_Version
    ,SUM(CLU19.ImportoOperazione) AS SommaConteggio
FROM T3MFDCLS.CLU01_Cluster CLU01
JOIN T3MFDCLS.CLU09_Cluster_Soggetto CLU09 ON CLU01.SoggettoVertice_ID = CLU09.ID
    AND CLU01.SoggettoVertice_Version = CLU09.Versione
JOIN T3MFDCLS.CLU07_Cluster_Relazione_Dinamica CLU07 ON CLU07.SoggettoPassivo_ID = CLU09.ID
    AND CLU07.SoggettoPassivo_Version = CLU09.Versione
JOIN T3MFDCLS.CLU08_Cluster_Relazione_Dinamica_Dettagli CLU08 ON CLU08.RelazioneDinamica_ID = CLU07.ID
JOIN T3MFDCLS.CLU19_Cluster_Operazione CLU19 ON CLU19.ID = CLU08.Operazione_ID
JOIN T3MFDPRM.DIZ16_Paese DIZ16 ON DIZ16.ID = CLU19.PaeseOperazione_ID
JOIN T3MFDPRM.DIZ10_Tipo_Operazione DIZ10 ON DIZ10.ID = CLU19.TipoOperazione_ID 
    -- ERRORE DI SCHEMA LINKING: Il modello ha agganciato la tabella DIZ10 confondendola con il dizionario corretto previsto dalla logica (DIZ04_TipoOperazioni).
WHERE CLU01.LogProcesso_ID = 2703
    AND CLU01.SottoAmbito_ID = 21
    AND CLU19.ImportoOperazione > 1000
    AND DIZ16.CodicePaeseISO <> 'IT' 
    -- ERRORE DI FORMATTAZIONE DATI: Inizialmente il modello ha generato ' IT ' con spazi interni. Questo typo impedisce il match esatto a livello di database causando un "silent failure" (risultato vuoto).
    AND DIZ10.Codice IN (
        'PREL'
        ,'PREL_CONT'
    ) 
    -- ALLUCINAZIONE PARAMETRI: Non trovando questi codici esplicitati nella configurazione testuale passata in input (poiché hardcodati nella SP originale), il modello ha inventato dei valori di business plausibili ma errati.
    AND CLU19.Segno = 'D' 
    -- VINCOLO RIDONDANTE: Filtro superfluo aggiunto a causa di un'interpretazione imprecisa o overly-restrictive della configurazione originale.
GROUP BY CLU01.ID
    ,CLU01.Versione
HAVING SUM(CLU19.ImportoOperazione) > 3000;


INSERT INTO ##TempDettaglio (
    Cluster_ID
    ,Cluster_Version
    ,IDRDD
)
SELECT S.Cluster_ID
    ,S.Cluster_Version
    ,CLU08.ID
FROM ##TempSintesi S
JOIN T3MFDCLS.CLU01_Cluster CLU01 ON S.Cluster_ID = CLU01.ID
    AND S.Cluster_Version = CLU01.Versione
JOIN T3MFDCLS.CLU09_Cluster_Soggetto CLU09 ON CLU01.SoggettoVertice_ID = CLU09.ID
    AND CLU01.SoggettoVertice_Version = CLU09.Versione
JOIN T3MFDCLS.CLU07_Cluster_Relazione_Dinamica CLU07 ON CLU07.SoggettoPassivo_ID = CLU09.ID
    AND CLU07.SoggettoPassivo_Version = CLU09.Versione
JOIN T3MFDCLS.CLU08_Cluster_Relazione_Dinamica_Dettagli CLU08 ON CLU08.RelazioneDinamica_ID = CLU07.ID
JOIN T3MFDCLS.CLU19_Cluster_Operazione CLU19 ON CLU19.ID = CLU08.Operazione_ID
JOIN T3MFDPRM.DIZ16_Paese DIZ16 ON DIZ16.ID = CLU19.PaeseOperazione_ID
JOIN T3MFDPRM.DIZ10_Tipo_Operazione DIZ10 ON DIZ10.ID = CLU19.TipoOperazione_ID
WHERE CLU01.LogProcesso_ID = 2703
    AND CLU01.SottoAmbito_ID = 21
    AND CLU19.ImportoOperazione > 1000
    AND DIZ16.CodicePaeseISO <> 'IT'   
    -- PROPAGAZIONE DELL'ERRORE: I difetti di formattazione (' IT ') vengono logicamente replicati nella fase di estrazione del dettaglio.
    AND DIZ10.Codice IN (
        'PREL'
        ,'PREL_CONT'
    ) 
    -- PROPAGAZIONE ALLUCINAZIONE: Valori inventati reiterati.
    AND CLU19.Segno = 'D'; 
    -- Vincolo Superfluo
