-- PROCEDURA: T3MFDPRM.sp_REA_PrelieviCarteEstero_DueSoglie
-- LOGICA ESTRATTA PER 2 REGOLE:
-- ID: 813 | Prelievi all estero
-- ID: 863 | Prelievi all estero

--------------------------------------------------

WITH CLS  ( Cluster_ID, Cluster_Version, SottoAmbito_ID , SottoAmbito_Version) AS
(
	  SELECT	CLS.ID, CLS.Versione, CLS.SottoAmbito_ID, CLS.SottoAmbito_Version 
	  FROM		T3MFDCLS.CLU01_Cluster CLS
	  WHERE 
				CLS.LogProcesso_ID = @IDEsecuzione and
				CLS.SottoAmbito_ID = @IDSottoambito
), 
TIPOP AS
(
	select ID FROM T3MFDPRM.DIZ04_TipoOperazioni where Codice in  ( '310' , '410', '510')
),
OpeRagruppati AS
(
SELECT _FD_Month, CLS.Cluster_ID,CLS.Cluster_Version, SUM(ImportoOperazione) totaleimporto
FROM	CLS    
INNER JOIN  T3MFDCLS.CLU07_Cluster_Relazione_Dinamica RD ON 
    	  RD.Cluster_ID = CLS.Cluster_ID
	  AND RD.Cluster_Version = CLS.Cluster_Version
INNER JOIN  T3MFDCLS.CLU08_Cluster_Relazione_Dinamica_Dettagli RDD 
    ON	  RDD.RelazioneDinamica_ID = RD.ID
INNER JOIN  T3MFDCLS.CLU19_Cluster_Operazione OPE
    ON	  RDD.Operazione_ID = OPE.ID
INNER JOIN TIPOP 
   ON  OPE.TipoOperazione_ID = TIPOP.ID
WHERE OPE.PaeseOperazione_ID NOT IN (81, 1 )
group by OPE._FD_Month,CLS.Cluster_ID,CLS.Cluster_Version
HAVING SUM(ImportoOperazione) >  @ValoreSogliaMensile
)
 INSERT INTO T3MFDEXC.REA_OPLIST
            (
			Cluster_ID
			,Cluster_Version
			,IDRDD
			)
		SELECT RD.Cluster_ID
			,RD.Cluster_Version
			,RDD.ID
 FROM	CLS    
INNER JOIN  T3MFDCLS.CLU07_Cluster_Relazione_Dinamica RD ON 
    	  RD.Cluster_ID = CLS.Cluster_ID
	  AND RD.Cluster_Version = CLS.Cluster_Version
INNER JOIN  T3MFDCLS.CLU08_Cluster_Relazione_Dinamica_Dettagli RDD 
    ON	  RDD.RelazioneDinamica_ID = RD.ID
INNER JOIN  T3MFDCLS.CLU19_Cluster_Operazione OPE
    ON	  RDD.Operazione_ID = OPE.ID
INNER JOIN TIPOP 
   ON   OPE.TipoOperazione_ID = TIPOP.ID
INNER JOIN OpeRagruppati
   ON     OpeRagruppati._FD_Month = OPE._FD_Month
   AND CLS.Cluster_ID = OpeRagruppati.Cluster_ID
   AND CLS.Cluster_Version = OpeRagruppati.Cluster_Version
WHERE OPE.PaeseOperazione_ID NOT IN (81, 1 )
AND OPE.ImportoOperazione >  @ValoreSoglia;

INSERT INTO T3MFDEXC.REA_TMP
	SELECT DISTINCT Cluster_ID
		,Cluster_Version
		,SUM(OPE.ImportoOperazione)
		,(
			SELECT ParId
			FROM T3MFDEXC.REA_DYNAMIC_PARMS
			WHERE ParName = 'Soglia Mensile'
			)
		,NULL
		,NULL
	FROM T3MFDEXC.REA_OPLIST OPLi
	INNER JOIN  T3MFDCLS.CLU08_Cluster_Relazione_Dinamica_Dettagli RDD 
    ON	  RDD.ID = OPLi.IDRDD
    INNER JOIN  T3MFDCLS.CLU19_Cluster_Operazione OPE
    ON	  RDD.Operazione_ID = OPE.ID
	GROUP BY Cluster_ID
		,Cluster_Version;