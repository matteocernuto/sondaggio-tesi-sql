-- PROCEDURA: T3MFDPRM.sp_REA_Operazioni_ATECO_Sensibili_Paesi_Rischiosi
-- LOGICA ESTRATTA PER 4 REGOLE:
-- ID: 786 | ATECO sensibili bonifici esteri (L1)
-- ID: 787 | ATECO sensibili bonifici esteri (L1)
-- ID: 788 | ATECO sensibili bonifici esteri (L1)
-- ID: 854 | ATECO sensibili bonifici esteri (L1)

--------------------------------------------------

SELECT ATECO_ID
INTO #ATECO
FROM T3MFDPRM.RSM07A_Rischio_ATECO
WHERE CodiceRischio = 'AtecoConRestrizioni';

SELECT ID
INTO #PERSGIU
FROM T3MFDPRM.DIZ08_Personalita_Giuridica
WHERE Codice in ( SELECT parvalue FROM T3MFDEXC.REA_DYNAMIC_PARMS WHERE Parname = 'PersonalitàGiuridica' );

SELECT CONVERT(INT,parvalue)  Livello
INTO #LIVELLO
FROM T3MFDEXC.REA_DYNAMIC_PARMS
WHERE Parname = 'Livello';

SELECT ID
INTO #TIPOP_AV
FROM T3MFDPRM.DIZ04_TipoOperazioni
WHERE Codice IN (
    SELECT parvalue
    FROM T3MFDEXC.REA_DYNAMIC_PARMS
    WHERE Parname = 'CodiceTipoOperazioneAvere'
);

SELECT ID
INTO #TIPOP_DA
FROM T3MFDPRM.DIZ04_TipoOperazioni
WHERE Codice IN (
    SELECT parvalue
    FROM T3MFDEXC.REA_DYNAMIC_PARMS
    WHERE Parname = 'CodiceTipoOperazioneDare'
);

SELECT DISTINCT Nazione_ID
INTO #NAZ
FROM T3MFDPRM.RSM06A_Rischio_Nazione
WHERE (CodiceRischio = 'Terrorismo'  AND Valore = 1) OR  (CodiceRischio = 'GAFI'  AND Valore = 1);

SELECT
    RD.IDRDD RelazioneDinamicaDettaglio_ID
    ,RD.Cluster_ID
    ,RD.Cluster_Version
    ,RD.ImportoOperazione
    ,RD.Segno
    ,RD.SoggettoAttivo_ID Soggetto_ID
    ,RD.SoggettoAttivo_Version Soggetto_versione
INTO #REA_OPLIST
FROM T3MFDEXC.RD
    INNER JOIN #LIVELLO LV
        ON LV.Livello = RD.LivRel
    INNER JOIN #TIPOP_DA TP
        ON RD.TipoOperazione_ID = TP.ID
    INNER JOIN #NAZ NZ
        ON NZ.Nazione_ID = RD.Paesefiscale_ID
    INNER JOIN T3MFDCLS.CLU09_Cluster_Soggetto SOGG
        ON RD.SoggettoAttivo_ID = SOGG.ID
        AND RD.SoggettoAttivo_Version = SOGG.Versione
    INNER JOIN #PERSGIU PG
        ON PG.ID = SOGG.PersonalitaGiuridica_ID
    INNER JOIN #ATECO ATC
        ON ATC.ATECO_ID = SOGG.ATECO_ID
WHERE
 RD._FD_Month between @fd_start_month and @fd_current_month
 AND Segno = 'D';

INSERT INTO #REA_OPLIST
SELECT
    RD.IDRDD RelazioneDinamicaDettaglio_ID
    ,RD.Cluster_ID
    ,RD.Cluster_Version
    ,RD.ImportoOperazione
    ,RD.Segno
    ,RD.SoggettoPassivo_ID Soggetto_ID
    ,RD.SoggettoPassivo_ID Soggetto_versione
FROM T3MFDEXC.RD
    INNER JOIN #LIVELLO LV
        ON LV.Livello = RD.LivRel
    INNER JOIN #TIPOP_AV TP
        ON RD.TipoOperazione_ID = TP.ID
    INNER JOIN #NAZ NZ
        ON NZ.Nazione_ID = RD.Paesefiscale_ID
    INNER JOIN T3MFDCLS.CLU09_Cluster_Soggetto SOGG
        ON RD.SoggettoPassivo_ID = SOGG.ID
        AND RD.SoggettoPassivo_Version = SOGG.Versione
    INNER JOIN #ATECO ATC
        ON ATC.ATECO_ID = SOGG.ATECO_ID
    INNER JOIN #PERSGIU PG
        ON PG.ID = SOGG.PersonalitaGiuridica_ID
WHERE
 RD._FD_Month between @fd_start_month and @fd_current_month
AND
 Segno = 'A';

SELECT
        Cluster_ID
        ,Cluster_Version
        ,Soggetto_ID
        ,Soggetto_versione
INTO #REA_SOGGLIST_A
FROM #REA_OPLIST
WHERE SEGNO = 'A'
GROUP BY
        Cluster_ID
        ,Cluster_Version
        ,Soggetto_ID
        ,Soggetto_versione
HAVING SUM(ImportoOperazione) >= @SogliaImporto;

SELECT
        Cluster_ID
        ,Cluster_Version
        ,Soggetto_ID
        ,Soggetto_versione
INTO #REA_SOGGLIST_D
FROM #REA_OPLIST
WHERE SEGNO = 'D'
GROUP BY
        Cluster_ID
        ,Cluster_Version
        ,Soggetto_ID
        ,Soggetto_versione
HAVING SUM(ImportoOperazione) >= @SogliaImporto;

INSERT INTO T3MFDEXC.REA_OPLIST
SELECT        RelazioneDinamicaDettaglio_ID
            ,opl.Cluster_ID
            ,opl.Cluster_Version
FROM #REA_OPLIST opl
    INNER JOIN #REA_SOGGLIST_A sogA
        on        sogA.Soggetto_ID = opl.Soggetto_ID
        and sogA.Soggetto_versione = opl.Soggetto_versione
        and opl.Cluster_ID = sogA.Cluster_ID
        and opl.Cluster_Version = sogA.Cluster_Version
WHERE SEGNO = 'A';

INSERT INTO T3MFDEXC.REA_OPLIST
SELECT        RelazioneDinamicaDettaglio_ID
            ,opl.Cluster_ID
            ,opl.Cluster_Version
FROM #REA_OPLIST opl
    INNER JOIN #REA_SOGGLIST_D sogA
        on        sogA.Soggetto_ID = opl.Soggetto_ID
        and sogA.Soggetto_versione = opl.Soggetto_versione
        and opl.Cluster_ID = sogA.Cluster_ID
        and opl.Cluster_Version = sogA.Cluster_Version
WHERE SEGNO = 'D';

INSERT INTO T3MFDEXC.REA_TMP
SELECT RD.Cluster_ID
        ,RD.Cluster_Version
        ,SUM(RD.ImportoOperazione)
        ,(
            SELECT ParId
            FROM T3MFDEXC.REA_DYNAMIC_PARMS
            WHERE ParName = 'SogliaImporto'
        )
        ,NULL
        ,NULL
FROM T3MFDEXC.REA_OPLIST OPL
INNER JOIN T3MFDEXC.RD
    ON RD.IDRDD = OPL.IDRDD
GROUP BY RD.Cluster_ID
        ,RD.Cluster_Version;