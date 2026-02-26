-- Pulizia tabelle temporanee globali -- Creazione tabelle temporanee
CREATE TABLE ##TempSintesi ( Cluster_ID INT, Cluster_Version INT, SommaConteggio DECIMAL(15,2),
Soggetto_ID INT NULL, Soggetto_Version INT NULL );

CREATE TABLE ##TempDettaglio ( Cluster_ID INT, Cluster_Version INT, IDRDD BIGINT );
 -- Popolamento sintesi
INSERT INTO ##TempSintesi
SELECT CLU01.ID AS Cluster_ID, CLU01.Versione AS Cluster_Version, SUM(CLU19.ImportoOperazione) AS SommaConteggio, CLU01.SoggettoVertice_ID AS Soggetto_ID, CLU01.SoggettoVertice_Version AS Soggetto_Version
FROM T3MFDCLS.CLU01_Cluster CLU01
JOIN T3MFDCLS.CLU09_Cluster_Soggetto CLU09_SoggettoVertice ON CLU01.SoggettoVertice_ID = CLU09_SoggettoVertice.ID
AND CLU01.SoggettoVertice_Version = CLU09_SoggettoVertice.Versione
JOIN T3MFDCLS.CLU07_Cluster_Relazione_Dinamica CLU07 ON CLU01.ID = CLU07.Cluster_ID
AND CLU01.Versione = CLU07.Cluster_Version
JOIN T3MFDCLS.CLU08_Cluster_Relazione_Dinamica_Dettagli CLU08 ON CLU07.ID = CLU08.RelazioneDinamica_ID
JOIN T3MFDCLS.CLU19_Cluster_Operazione CLU19 ON CLU08.Operazione_ID = CLU19.ID
JOIN T3MFDPRM.DIZ04_TipoOperazioni DIZ04 ON CLU19.TipoOperazione_ID = DIZ04.ID
JOIN T3MFDCLS.CLU09_Cluster_Soggetto CLU09_SoggettoRelazione ON CLU08.SoggettoEsecutore_ID = CLU09_SoggettoRelazione.ID
AND CLU08.SoggettoEsecutore_Versione = CLU09_SoggettoRelazione.Versione
JOIN T3MFDPRM.DIZ11_ATECO DIZ11 ON CLU09_SoggettoRelazione.ATECO_ID = DIZ11.ID
JOIN T3MFDPRM.RSM06_Rischio_Nazione RSM06 ON CLU09_SoggettoRelazione.Nazione_ID = RSM06.Nazione_ID --errore di selezione della tabela, il modello ha selezionato la non trasposta ma inserendo condizioni come se lo fosse
WHERE CLU01.LogProcesso_ID = 2703
AND CLU01.SottoAmbito_ID = 21
AND RSM06.CodiceRischio = 'Banca'
AND CLU09_SoggettoRelazione.PersonalitaGiuridica_ID = (SELECT ID
FROM T3MFDPRM.DIZ08_Personalita_Giuridica
WHERE Codice = 'G')
AND CLU07.LivRel = 1
AND CLU19.DataOperazione >= DATEADD(MONTH, -12, GETDATE()) --i vincoli sul tempo sono stati tolti per ottenere più risultati possibile sui dati di test, qua c'è un refuso che ha inserito comunque
AND ( (DIZ04.Codice IN ('102','105','103')
AND CLU19.Segno = 'D')
OR (DIZ04.Codice IN ('101','100','104')
AND CLU19.Segno = 'A') ) -- filtraggio per parametri non in modo efficiente
GROUP BY CLU01.ID, CLU01.Versione, CLU09_SoggettoVertice.NDG, CLU09_SoggettoVertice.NomeRagSociale, DIZ11.Codice, DIZ11.Descrizione, CLU01.SoggettoVertice_ID, CLU01.SoggettoVertice_Version
HAVING SUM(CLU19.ImportoOperazione) >= 30000;
 -- Popolamento dettaglio
INSERT INTO ##TempDettaglio
SELECT s.Cluster_ID, s.Cluster_Version, CLU08.ID AS IDRDD
FROM ##TempSintesi s
JOIN T3MFDCLS.CLU07_Cluster_Relazione_Dinamica CLU07 ON s.Cluster_ID = CLU07.Cluster_ID
AND s.Cluster_Version = CLU07.Cluster_Version
JOIN T3MFDCLS.CLU08_Cluster_Relazione_Dinamica_Dettagli CLU08 ON CLU07.ID = CLU08.RelazioneDinamica_ID
JOIN T3MFDCLS.CLU19_Cluster_Operazione CLU19 ON CLU08.Operazione_ID = CLU19.ID
JOIN T3MFDPRM.DIZ04_TipoOperazioni DIZ04 ON CLU19.TipoOperazione_ID = DIZ04.ID
WHERE CLU07.LivRel = 1
AND CLU19.DataOperazione >= DATEADD(MONTH, -12, GETDATE())
AND ( (DIZ04.Codice IN ('102','105','103')
AND CLU19.Segno = 'D')
OR (DIZ04.Codice IN ('101','100','104')
AND CLU19.Segno = 'A') );