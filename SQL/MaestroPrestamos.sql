CREATE OR REPLACE PROCEDURE "NELSON.FERRUCHO".SP_MS_PRESTAMOS_CDTS_PRESTAMOS(W_OFICINA IN VARCHAR2)
IS
    TRT_ROW MS_PRESTAMOS_CDTS%ROWTYPE;
    I NUMERIC := 0;
    ESPACIO VARCHAR2(1) := ' ';
    MAX5_3 VARCHAR2(6) := '00.000';
    MAX9_6 VARCHAR2(10) := '000.000000';
    MAX15_2 VARCHAR2(16) := '0000000000000.00';
    MAX15_4 VARCHAR2(16) := '00000000000.0000';
    MAX17_2 VARCHAR2(18) := '000000000000000.00';
    MAX9_2 VARCHAR2(10) := '0000000.00';
    MAX11_6 VARCHAR2(12) := '00000.000000';
    MAX13_2 VARCHAR2(14) := '00000000000.00';
    MAX6_3 VARCHAR2(7) := '000.000';
    MAX21_8 VARCHAR2(22) := '0000000000000.00000000';
    FECHA_CORTE DATE := FB_FECHA_CORTE();
    CURSOR CUR_NRO_CREDITO IS
        SELECT DISTINCT NRO_CREDITO, C.CODIGO_SUCURSAL
        FROM   DCNCRE01 C
        INNER JOIN (SELECT CODIGO_SUCURSAL
                    FROM OFICINAS 
                    WHERE CODIGO_SUCURSAL IN(SELECT REGEXP_SUBSTR(W_OFICINA,'[^,]+', 1, LEVEL ) 
                                             FROM   DUAL
                                             CONNECT BY REGEXP_SUBSTR(W_OFICINA,'[^,]+', 1, LEVEL) IS NOT NULL)
                    AND CODIGO_EJECUTIVO = 1)DF ON DF.CODIGO_SUCURSAL = C.CODIGO_SUCURSAL  
        WHERE  ESTADO < 2;

TYPE TIPOARRAYREGISTROS
IS
    TABLE OF CUR_NRO_CREDITO%ROWTYPE;
    ARRAYREGISTROS TIPOARRAYREGISTROS;
    INDICE PLS_INTEGER;
BEGIN


        OPEN CUR_NRO_CREDITO;
        LOOP
            FETCH CUR_NRO_CREDITO BULK COLLECT
            INTO  ARRAYREGISTROS LIMIT 5000;

            INDICE := ARRAYREGISTROS.FIRST;
            WHILE ( INDICE IS NOT NULL )
            LOOP
                FOR CUR IN ( SELECT  D.CODIGO_SUCURSAL AS WDEABRN ,
                          D.NRO_CREDITO AS WDEAACC ,
                          CT.WDEAPBR,
                          D.FECHA_INICIO_CRE AS WDEASDM ,
                          FV.WDEAMAM ,
                          D.DIAS_CUOTA_LIN * D.NRO_CUOTAS_CRE AS WDEATRM,
                          D.VAL_GIRO AS WDEAOAM,
                         -- D.FECHA_INICIO_CRE AS WDEAODM,
                          H.WDEAIAL ,
                          H.WDEAIAY ,
                          CASE D.NRO_CUOTAS_CRE WHEN 1 THEN 'MAT' ELSE 'SCH' END AS WDEAIPD,
                          CASE D.NRO_CUOTAS_CRE WHEN 1 THEN 'MAT' ELSE 'SCH' END AS WDEAPPD,
                          D.COD_ASESOR AS WDEAOFI,
                          FB_HOMOLOGA('2F','DGPPRO25',D.LINEA_CREDITO)  AS WDEATYP, 
                          D.VALOR_CUOTA AS WDEAROA,
                          CASE WHEN D.ESTADO <= 0 THEN ' ' WHEN D.ESTADO =2 THEN 'C' END AS WDEASTS ,
                          D.NUI AS WDEACUN ,
                          CP.WDEAIPY ,
                          P.WDEALIM ,
                          UPR.WDEALPM ,
                          TP.WDEACOT ,
                          FB_HOMOLOGA('CD','TIPO',D.TIPO_INTERES_LIN) AS WDEAFTB,  --Homologacion Jessica 01/03/2018
                          CASE WHEN D.SW_360_LIQ_INTERESES_CRE IN (1,360) THEN 360 ELSE 365 END AS WDEABAS,
                          D.NRO_PRORROGAS AS WDEARON,
                          D.NRO_CREDITO_PASIVO AS WDEAPAC,
                          CASE WHEN D.NRO_CUPO IS NOT NULL THEN D.NUI ELSE 0 END AS WDEACMC,
                          CASE WHEN D.SW_360_LIQ_INTERESES_CRE IN (1,360) THEN 'M' ELSE 'S' END AS WDEAICT,
                          DR.WDEAMLA ,
                          CP.WDEALOB ,
                          CS.WDEAICD ,
                          CASE D.SW_TIPO_CRED_LIN WHEN 'P' THEN 'N' ELSE 'Y' END AS WDEAIIP ,
                          CPF.WDEAPTM ,
                          P.WDEAITM ,
                          LT.WDEACPL ,
                          DP.WDEADEL ,
                          IV.WDEAIVL ,
                          IM.WDEAPIP ,
                          FB_HOMOLOGA('04','DGPNPR23',D.TIPO_LINEA_LIN)  AS WDEACLF, 
                          TD.WDEADED,
                          MG.WDEAPDU,
                          CASE WHEN TIPO_CREDITO = 3 THEN 'E' ELSE 'N' END AS WDEARET,
                          CASE WHEN TIPO_CREDITO = 3 THEN DEAREA ELSE 0 END AS WDEAREA,
                          NVL(D.PORCENTAJE_FNG,0) + NVL(D.PORCENTAJE_DCA,0) + NVL(D.PORCENTAJE_FAG,0) + NVL(D.PORCENTAJE_FGA,0) AS WDEACPE,
                          
                          /*
                          CASE WHEN D.PORCENTAJE_FNG <> 0 THEN D.PORCENTAJE_FNG
                          WHEN D.PORCENTAJE_DCA <> 0 THEN D.PORCENTAJE_DCA
                          WHEN D.PORCENTAJE_FAG <> 0 THEN D.PORCENTAJE_FAG
                          ELSE D.PORCENTAJE_FGA END AS DEACPE,
                          */
                          --D.TIPO_LINEA_LIN AS WDEAUC6, -- Homologacion Jessica 06/03/2018
                          FB_HOMOLOGA('04', 'DGPNPR23',D.TIPO_LINEA_LIN) AS WDEAUC6,
                          D.FECHA_VCTO_CRE AS WDEAOMM,
                          D.NRO_CUOTAS_CRE AS WDEANCU,
                          D.NRO_CUOTAS_CRE AS WDEAPCU,
                          CASE WHEN D.YA_CONTIGENTE = 1 THEN 'S' ELSE NULL END AS WDEASUS,
                          CASE WHEN D.CALIFICACION = '6' THEN '3' WHEN D.FECHA_ACELERA IS NOT NULL THEN '5' WHEN D.CALIFICACION <> '1' THEN '2' ELSE '1' END AS WDEADLC,
                          D.NRO_PAGARE AS WDEAFRA,
                          D.DIAS_CUOTA_LIN AS WDEAPRR,
                          D.SW_IMPRESO AS WDEAPRM,
                          --D.TIPO_LINEA_LIN AS WDEAPSU, -- Homologacion Jessica 06/03/2018
                          FB_HOMOLOGA('04', 'DGPNPR23',D.TIPO_LINEA_LIN) AS WDEAPSU,
                          D.DIAS_CUOTA_LIN AS WDEASTC,
                          E.WDEAEDM ,
                          D.NRO_CREDITO AS WDEAACC1 ,
                          MG.WDEAHAM ,
                          HY.WDEAPEI ,
                          TS.WDEAHEM ,
                          TF.WDEAFRT ,
                          CASE WHEN NVL(H1.TIPO_GARANTIA,0) >0 THEN 1 ELSE 0 END AS WDEAHTM,                          CASE WHEN NVL(TIPO_INTERES_LIN,0) <> 0 THEN TS.TASA_EFECTIVA ELSE NULL END AS WDEANER,
                          CASE WHEN NVL(TIPO_INTERES_LIN,0) <> 0 THEN TS.TASA_INTERES ELSE NULL END AS WDEANRM,
                          CASE WHEN NVL(TIPO_INTERES_LIN,0) <> 0 THEN UCT.CAMBIO_TASA ELSE NULL END AS WDEALRM,
                          CASE WHEN NVL(TIPO_INTERES_LIN,0) <> 0 THEN UCT.TASA_FLOTANTE ELSE 0 END AS WDEAPFR ,
                          MG.WDEAMEM ,
                          TS.WDEARTE ,
                          MG.WDEAPRI ,
                          MG.WDEALRT ,
                          TS.WDEAIDY ,
                          ABS (IV.SALDO) AS WDEAIDU,
                          TS.WDEARCM ,
                          TS.WDEAINM ,
                          TER.WDEASPR ,
                          MG.WDEAPIA ,
                          FB_HOMOLOGA('RS','DCNFUE45',D.FUENTE) AS WDEASOU
                FROM      DCNCRE01 D
                LEFT JOIN ( SELECT TASA_NOMINAL AS WDEAPBR,
                                  COD_EMP ,
                                  NRO_CREDITO
                          FROM    DCNCUT01
                          WHERE   NRO_CUOTA = 1 ) CT ON CT.COD_EMP = D.COD_EMP AND CT.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT  MAX(FECHA_FINAL) AS WDEAMAM,
                                   COD_EMP ,
                                   NRO_CREDITO
                          FROM     DCNCUT01
                          WHERE    TOTAL_CUOTAS = NRO_CUOTA
                          GROUP BY COD_EMP, NRO_CREDITO ) FV ON FV.COD_EMP = D.COD_EMP AND FV.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT CT.TASA_NOMINAL_REAL AS WDEARTE,
                                  CT.FECHA_FINAL AS WDEAIDY,
                                  CT.FECHA_INICIAL AS WDEARCM,
                                  CT.CAUSACION_HOY AS WDEAINM,
                                  CT.FECHA_FINAL AS WDEAHEM,
                                  CT.TASA_EFECTIVA_REAL AS TASA_EFECTIVA,
                                  CT.FECHA_FINAL AS TASA_INTERES,
                                  COD_EMPRESA,
                                  CT.NRO_CREDITO
                          FROM    DCNCUT01 CT,
                                  DCNINFAUDITORIA H
                          WHERE   H.FECHA = FECHA_CORTE
                                  AND CT.COD_EMP = H.COD_EMPRESA
                                  AND CT.NRO_CREDITO = H.NRO_CREDITO
                                  AND CT.NRO_CUOTA = H.NRO_CUOTA_ACTUAL ) TS ON  TS.COD_EMPRESA = D.COD_EMP AND TS.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT  SUM(CAUSACION_HOY) AS WDEAIAL,
                                   SUM(CAUSACION_HOY) AS WDEAIAY,
                                   COD_EMP ,
                                   NRO_CREDITO
                          FROM     DCNCUT01
                          GROUP BY COD_EMP, NRO_CREDITO ) H ON H.COD_EMP = D.COD_EMP AND H.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT H.GARANTIA_HIP + H.GARANTIA_NO_HIP + H.GARANTIA_FNG + H.NI_GARANTIA_HIP + H.NI_GARANTIA_NO_HIP + H.GARANTIA_DCA AS WDEAHAM,
                                  H.CAPITAL_1_30 + H.CAPITAL_31_90 + H.CAPITAL_91_180 + H.CAPITAL_181_360 + H.CAPITAL_360 AS WDEAPDU,
                                  H.INT_MORA_IDONEOS + INT_MORA_NO_IDONEOS + INT_CONTING_MORA AS WDEAPIA,
                                  H.CAPITAL_1_30 + H.CAPITAL_31_90 + H.CAPITAL_91_180 + H.CAPITAL_181_360 + H.CAPITAL_360 AS WDEAMEM,
                                  H.SALDO_CAPITAL AS WDEAPRI,
                                  H.TASA_EFEC_REAL AS WDEALRT,
                                  COD_EMPRESA ,
                                  NRO_CREDITO
                          FROM    DCNINFAUDITORIA H
                          WHERE   H.FECHA = FECHA_CORTE ) MG ON MG.COD_EMPRESA = D.COD_EMP AND MG.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT  SUM(DC.CAUSACION_HOY - DC.VLR_ABONO_INTERES) AS SALDO,
                                   NRO_CREDITO
                          FROM     DCNCUT01 DC
                          WHERE    DC.FECHA_FINAL <= FECHA_CORTE
                          GROUP BY NRO_CREDITO ) IV ON IV.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT  SUM(VALOR_CONCEPTO) AS WDEAIPY,
                                   COD_EMP ,
                                   NRO_CREDITO
                          FROM     DCNCTOPAG
                          WHERE    CONCEPTO_PAGO IN (2,7)
                          GROUP BY COD_EMP, NRO_CREDITO ) CP ON CP.COD_EMP = D.COD_EMP AND CP.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT  MAX(FECHA) AS WDEALIM,
                                   MAX(FECHA) AS WDEAITM,
                                   NRO_CREDITO
                          FROM     DCNCTOPAG
                          WHERE    CONCEPTO_PAGO IN (2,7)
                          GROUP BY NRO_CREDITO ) P ON P.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT  (MAX(FECHA)) AS WDEALPM,
                                   NRO_CREDITO
                          FROM     DCNCTOPAG
                          WHERE    CONCEPTO_PAGO IN (1,100)
                          GROUP BY NRO_CREDITO ) UPR ON UPR.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT DISTINCT TIPO_GTIA AS WDEACOT,
                                  NRO_CREDITO
                          FROM    DCNHIP33 H3,
                                  DFFGBIEN DG
                          WHERE   DG.IDENTIF_ACTIVO = H3.IDENTIF_ACTIVO ) TP ON TP.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT CF.TASA_CIFRA AS WDEAPEI,
                                  CODI_TIPO
                          FROM    CIFRA CF
                          WHERE   CF.CODI_TIPO = 534
                                  AND FECHA_CORTE BETWEEN CF.FECH_TIPO AND CF.FECH_FINAL ) HY ON HY.CODI_TIPO = D.TIPO_INTERES_LIN
                LEFT JOIN ( SELECT  COUNT(TIPO_GARANTIA) AS TIPO_GARANTIA,
                                   NRO_CREDITO
                          FROM     DCNHIP33 H
                          GROUP BY NRO_CREDITO ) H1 ON H1.NRO_CREDITO = D.NRO_CREDITO AND  D.PORCENTAJE_FNG + D.PORCENTAJE_DCA + D.PORCENTAJE_FAG + D.PORCENTAJE_FGA > 0
                LEFT JOIN ( SELECT DIRECCION_PERSONA AS WDEAMLA,
                                  NUI
                          FROM    DFCPSN02 ) DR ON DR.NUI = D.NUI
                LEFT JOIN ( SELECT C.CODIGO_CIIU AS WDEALOB,
                                  P.CODIGO_ACT ,
                                  P.NUI
                          FROM    DCPCAR01 C,
                                  DFCPSN02 P
                          WHERE   C.CODIGO_ACT = P.CODIGO_ACT ) CP ON CP.NUI = D.NUI
                LEFT JOIN ( SELECT CODIGO_ACT AS WDEAICD,
                                  NUI
                          FROM    DFCPSN02 ) CS ON CS.NUI = D.NUI                          
                LEFT JOIN ( SELECT CF.TASA_CIFRA AS WDEAFRT,
                                  CODI_TIPO
                          FROM    CIFRA CF
                          WHERE   FECHA_CORTE BETWEEN CF.FECH_TIPO AND CF.FECH_FINAL ) TF ON TF.CODI_TIPO = D.TIPO_INTERES_LIN
                LEFT JOIN ( SELECT DISTINCT CT.FECHA_FINAL AS CAMBIO_TASA,
                                  CT.TASA_EFECTIVA_REAL AS TASA_FLOTANTE,
                                  COD_EMPRESA ,
                                  CT.NRO_CREDITO
                          FROM    DCNCUT01 CT,
                                  DCNINFAUDITORIA H
                          WHERE   H.FECHA = FECHA_CORTE
                                  AND CT.COD_EMP = H.COD_EMPRESA
                                  AND CT.NRO_CREDITO = H.NRO_CREDITO
                                  AND CT.NRO_CUOTA = (H.NRO_CUOTA_ACTUAL-1) ) UCT ON UCT.COD_EMPRESA = D.COD_EMP AND UCT.NRO_CREDITO = D.NRO_CREDITO
                                        
                LEFT JOIN ( SELECT  (MAX(FECHA)) AS WDEAPTM,
                                   COD_EMP ,
                                   NRO_CREDITO
                          FROM     DCNCTOPAG
                          WHERE    CONCEPTO_PAGO IN (1,100)
                          GROUP BY COD_EMP, NRO_CREDITO ) CPF ON CPF.COD_EMP = D.COD_EMP AND CPF.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT  SUM(VALOR_CONCEPTO) AS WDEACPL,
                                   COD_EMP ,
                                   NRO_CREDITO
                          FROM     DCNCTOPAG
                          WHERE    CONCEPTO_PAGO IN (300,312,315,423,425,439,442)
                          GROUP BY COD_EMP, NRO_CREDITO ) LT ON LT.COD_EMP = D.COD_EMP AND LT.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT  SUM(VALOR_CONCEPTO) AS WDEADEL ,
                                   COD_EMP ,
                                   NRO_CREDITO
                          FROM     DCNCTOPAG
                          WHERE    CONCEPTO_PAGO IN (220,226,227,302,305,306,311,316,318,319,320,321,322,330,350,352,354,400,416,417,418,419,420,421,422,427,431,432,433,434,435,436,437,438,440,441)
                          GROUP BY COD_EMP, NRO_CREDITO ) DP ON DP.COD_EMP = D.COD_EMP AND DP.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT  SUM(VALOR_CONCEPTO) AS WDEAIVL,
                                   COD_EMP ,
                                   NRO_CREDITO
                          FROM     DCNCTOPAG
                          WHERE    CONCEPTO_PAGO IN (225,301,303,307,313,314,317,323,324,325,326,327,328,351,353,401,424,426,443)
                          GROUP BY COD_EMP, NRO_CREDITO ) IV ON IV.COD_EMP = D.COD_EMP AND IV.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT  SUM(VALOR_CONCEPTO) AS WDEAPIP,
                                   COD_EMP ,
                                   NRO_CREDITO
                          FROM     DCNCTOPAG
                          WHERE    CONCEPTO_PAGO IN (4,8)
                          GROUP BY COD_EMP, NRO_CREDITO ) IM ON IM.COD_EMP = D.COD_EMP AND IM.NRO_CREDITO = D.NRO_CREDITO

                         /*LEFT JOIN (SELECT FECHA AS WDEAEXM,
                                                      NRO_CREDITO
                                               FROM DCNGIR05
                                               WHERE TIPO_CREDITO = 3)G
                                          ON G.NRO_CREDITO = D.NRO_CREDITO
                                           --- El campo TIPO_CREDITO no existe en la tabla DCNGIR05, Por definir

                        */
                LEFT JOIN ( SELECT  SUM(VALOR) AS WDEADED,
                                   NRO_CREDITO
                          FROM     DCNDES01
                          WHERE    NRO_CUOTA >= 1
                          GROUP BY NRO_CREDITO ) TD ON TD.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT NRO_OBLIGACION AS DEAREA,
                                  NRO_CREDITO
                          FROM    DCNGIR05
                          WHERE   CONCEPTO = 16 ) NR ON NR.NRO_CREDITO = D.NRO_CREDITO    
                LEFT JOIN ( SELECT  (MAX(FECHA_EXTRACTO)) AS WDEAEDM,
                                   NRO_CREDITO
                          FROM     DCNEXTCAB02
                          GROUP BY NRO_CREDITO ) E ON E.NRO_CREDITO = D.NRO_CREDITO
                LEFT JOIN ( SELECT TASA_EFEC_REAL AS WDEASPR,
                                  COD_EMPRESA ,
                                  NRO_CREDITO
                          FROM    DCNINFAUDITORIA
                          WHERE   FECHA = FECHA_CORTE ) TER ON TER.COD_EMPRESA = D.COD_EMP AND TER.NRO_CREDITO = D.NRO_CREDITO
                WHERE     D.NRO_CREDITO = ARRAYREGISTROS(INDICE).NRO_CREDITO 
                          AND D.CODIGO_SUCURSAL= ARRAYREGISTROS(INDICE).CODIGO_SUCURSAL)
                LOOP 
                    BEGIN
                        TRT_ROW.DEABNK := FB_REP_CAD('01', 2);
                        TRT_ROW.DEABRN := FB_REP_NUM(CUR.WDEABRN,4);
                        TRT_ROW.DEACCY := FB_REP_CAD('COP',3);
                        TRT_ROW.DEAGLN := FB_REP_NUM (0,16); --Pendiente por homologar 
                        TRT_ROW.DEAACC := FB_REP_NUM (ARRAYREGISTROS(INDICE).NRO_CREDITO ,12);
                        TRT_ROW.DEATRF := FB_REP_CAD (ESPACIO,1);
                        TRT_ROW.DEAPBR := FB_REP_DEC (CUR.WDEAPBR/100000,MAX9_6);
                        TRT_ROW.DEASDM := FB_CAL_MES(CUR.WDEASDM);
                        TRT_ROW.DEASDD := FB_CAL_DIA(CUR.WDEASDM);
                        TRT_ROW.DEASDY := FB_CAL_ANYO(CUR.WDEASDM);
                        TRT_ROW.DEAMAM := FB_CAL_MES(CUR.WDEAMAM);
                        TRT_ROW.DEAMAD := FB_CAL_DIA(CUR.WDEAMAM);
                        TRT_ROW.DEAMAY := FB_CAL_ANYO(CUR.WDEAMAM);
                        TRT_ROW.DEARTE := FB_REP_DEC(CUR.WDEARTE,MAX9_6);
                        --TRT_ROW.DEARTE := FB_REP_DEC(0,MAX9_6);
                        TRT_ROW.DEATRM := FB_REP_NUM(CUR.WDEATRM,5);
                        TRT_ROW.DEATRC := FB_REP_CAD('D',1);
                        TRT_ROW.DEAPRI := FB_REP_DEC(CUR.WDEAPRI,MAX15_2);
                        TRT_ROW.DEAOAM := FB_REP_DEC(CUR.WDEAOAM,MAX15_2);
                        TRT_ROW.DEALCM := FB_CAL_MES(FECHA_CORTE);
                        TRT_ROW.DEALCD := FB_CAL_DIA(FECHA_CORTE);
                        TRT_ROW.DEALCY := FB_CAL_ANYO(FECHA_CORTE);
                        TRT_ROW.DEARRC := FB_REP_CAD('DC',2); --Pendiente Definir
                        TRT_ROW.DEAODM := FB_CAL_MES(CUR.WDEASDM);
                        TRT_ROW.DEAODD := FB_CAL_DIA(CUR.WDEASDM);
                        TRT_ROW.DEAODY := FB_CAL_ANYO(CUR.WDEASDM);
                        TRT_ROW.DEAIAL := FB_REP_DEC(CUR.WDEAIAL,MAX15_2);
                        TRT_ROW.DEAIAY := FB_REP_DEC(CUR.WDEAIAY,MAX15_4);
                        TRT_ROW.DEAHAM := FB_REP_DEC(CUR.WDEAHAM,MAX15_2);
                        TRT_ROW.DEARDM := FB_REP_NUM(0,2);
                        TRT_ROW.DEARDD := FB_REP_NUM(0,2);
                        TRT_ROW.DEARDY := FB_REP_NUM(0,4);
                        TRT_ROW.DEAROR := FB_REP_DEC(0,MAX9_6);
                        TRT_ROW.DEAROC := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAROY := FB_REP_NUM(0,3);
                        TRT_ROW.DEAIPD := FB_REP_CAD(CUR.WDEAIPD,3);
                        TRT_ROW.DEAPPD := FB_REP_CAD(CUR.WDEAPPD,3);
                        TRT_ROW.DEAOFI := FB_REP_CAD(CUR.WDEAOFI,4);
                        TRT_ROW.DEATYP := FB_REP_CAD(CUR.WDEATYP,4); 
                        TRT_ROW.DEAROA := FB_REP_DEC(CUR.WDEAROA,MAX15_2);
                        TRT_ROW.DEAGRC := FB_REP_CAD('CO',4);
                        TRT_ROW.DEALPR := FB_REP_DEC(CUR.WDEAPRI,MAX15_2);
                        TRT_ROW.DEALRT := FB_REP_DEC(CUR.WDEALRT,MAX9_6);
                        TRT_ROW.DEASTS := FB_REP_CAD(CUR.WDEASTS,1);
                        TRT_ROW.DEAGCD := FB_REP_CAD('CO',4);
                        TRT_ROW.DEACUN := FB_REP_NUM(CUR.WDEACUN,9); --Adicionado
                        TRT_ROW.DEADLI := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEARTB := FB_REP_CAD(ESPACIO,2);
                        TRT_ROW.DEAIDY := FB_CAL_DIA(CUR.WDEAIDY);
                        TRT_ROW.DEAPDY := FB_CAL_DIA(CUR.WDEAIDY);
                        TRT_ROW.DEACDY := FB_CAL_DIA(CUR.WDEAIDY);
                        TRT_ROW.DEARPT := FB_REP_CAD(ESPACIO,2);
                        TRT_ROW.DEAREB := FB_REP_CAD(ESPACIO,2);
                        TRT_ROW.DEARPR := FB_REP_NUM(0,4);
                        TRT_ROW.DEARPC := FB_REP_CAD(ESPACIO,3);
                        TRT_ROW.DEARGL := FB_REP_NUM(0,16);
                        TRT_ROW.DEARAC := FB_REP_NUM(0,12);
                        TRT_ROW.DEAIFL := FB_REP_CAD('1',1);
                        TRT_ROW.DEAIDU := FB_REP_DEC(CUR.WDEAIDU,MAX15_2);
                        TRT_ROW.DEALDY := FB_REP_NUM(0,5);
                        TRT_ROW.DEALBS := FB_REP_NUM(0,3);
                        TRT_ROW.DEAIPY := FB_REP_DEC(CUR.WDEAIPY,MAX15_2);
                        TRT_ROW.DEAIPL := FB_REP_DEC(CUR.WDEAIPY,MAX15_2);
                        TRT_ROW.DEAPDU := FB_REP_DEC(CUR.WDEAPDU,MAX15_2);
                        TRT_ROW.DEALIM := FB_CAL_MES(CUR.WDEALIM);
                        TRT_ROW.DEALID := FB_CAL_DIA(CUR.WDEALIM);
                        TRT_ROW.DEALIY := FB_CAL_ANYO(CUR.WDEALIM);
                        TRT_ROW.DEALPM := FB_CAL_MES(CUR.WDEALPM);
                        TRT_ROW.DEALPD := FB_CAL_DIA(CUR.WDEALPM);
                        TRT_ROW.DEALPY := FB_CAL_ANYO(CUR.WDEALPM);
                        TRT_ROW.DEACOT := FB_REP_CAD(CUR.WDEACOT,4);
                        TRT_ROW.DEAPEI := FB_REP_DEC(CUR.WDEAPEI,MAX9_2);
                        TRT_ROW.DEAFTB := FB_REP_CAD(CUR.WDEAFTB,2); 
                        TRT_ROW.DEAFTY := FB_REP_CAD('FP',2);
                        TRT_ROW.DEABAS := FB_REP_NUM(CUR.WDEABAS,2);
                        TRT_ROW.DEAODA := FB_REP_CAD('N',1);
                        TRT_ROW.DEARON := FB_REP_NUM(CUR.WDEARON,3); --Pendiente Preguntar
                        TRT_ROW.DEAROP := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEARCR := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAREC := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEACCN := FB_REP_NUM(0,8); --Pendiente Definir
                        TRT_ROW.DEAEXR := FB_REP_DEC(0,MAX11_6);
                        TRT_ROW.DEAUC3 := FB_REP_CAD(ESPACIO,4);
                        TRT_ROW.DEAPAC := FB_REP_NUM(CUR.WDEAPAC,12);
                        TRT_ROW.DEARCM := FB_CAL_MES(CUR.WDEARCM);
                        TRT_ROW.DEARCO := FB_CAL_DIA(CUR.WDEARCM);
                        TRT_ROW.DEAREY := FB_CAL_ANYO(CUR.WDEARCM);
                        TRT_ROW.DEACMC := FB_REP_NUM(CUR.WDEACMC,9);
                        --TRT_ROW.DEACMN      :=  FB_REP_NUM(CUR.WDEACMN,4); Pendiente de Definir
                        TRT_ROW.DEACMN := FB_REP_NUM(0,4);
                        TRT_ROW.DEAICT := FB_REP_CAD(CUR.WDEAICT,1);
                        TRT_ROW.DEADLP := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEARRP := FB_REP_CAD(ESPACIO,3);
                        TRT_ROW.DEARRM := FB_REP_NUM(0,2);
                        TRT_ROW.DEARRD := FB_REP_NUM(0,2);
                        TRT_ROW.DEARRY := FB_REP_NUM(0,4);
                        TRT_ROW.DEAHFQ := FB_REP_NUM('3',1); --Pendiente Definir
                        TRT_ROW.DEAHTM := FB_REP_NUM(CUR.WDEAHTM,1);
                        TRT_ROW.DEAIRT := FB_REP_DEC(0,MAX9_6);
                        TRT_ROW.DEAOF2 := FB_REP_CAD(ESPACIO,4);
                        --TRT_ROW.DEAMLA := FB_REP_CAD(CUR.WDEAMLA,2); Pendiente de definir que sucede.
                        TRT_ROW.DEAMLA := FB_REP_NUM(0,2);
                        TRT_ROW.DEALOB := FB_REP_CAD(CUR.WDEALOB,4);
                        TRT_ROW.DEAICD := FB_REP_CAD(CUR.WDEAICD,4);
                        TRT_ROW.DEAIJY := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAIJL := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAINM := FB_REP_DEC((CUR.WDEAINM),MAX15_2);
                        TRT_ROW.DEAHEM := FB_CAL_MES(CUR.WDEAHEM);
                        TRT_ROW.DEAHED := FB_CAL_DIA(CUR.WDEAHEM);
                        TRT_ROW.DEAHEY := FB_CAL_ANYO(CUR.WDEAHEM);
                        TRT_ROW.DEAOFB := FB_REP_CAD(ESPACIO,2);
                        TRT_ROW.DEAOCR := FB_REP_NUM(0,4);
                        TRT_ROW.DEAOCY := FB_REP_CAD(ESPACIO,3);
                        TRT_ROW.DEAOGL := FB_REP_NUM(0,16);
                        TRT_ROW.DEAOAC := FB_REP_NUM(0,12);
                        TRT_ROW.DEAPRF := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAOBL := FB_REP_CAD(ESPACIO,2);
                        TRT_ROW.DEAPAR := FB_REP_CAD('N',1);
                        TRT_ROW.DEAFRT := FB_REP_DEC(CUR.WDEAFRT/10000,MAX9_6);
                        TRT_ROW.DEANER := FB_REP_DEC(CUR.WDEANER,MAX9_6);
                        TRT_ROW.DEANRM := FB_CAL_MES(CUR.WDEANRM);
                        TRT_ROW.DEANRD := FB_CAL_DIA(CUR.WDEANRM);
                        TRT_ROW.DEANRY := FB_CAL_ANYO(CUR.WDEANRM);
                        TRT_ROW.DEALRM := FB_CAL_MES(CUR.WDEALRM);
                        TRT_ROW.DEALRD := FB_CAL_DIA(CUR.WDEALRM);
                        TRT_ROW.DEALRY := FB_CAL_ANYO(CUR.WDEALRM);
                        TRT_ROW.DEAPFR := FB_REP_DEC(CUR.WDEAPFR,MAX9_6);
                        TRT_ROW.DEAWHF := FB_REP_CAD('R',1); --Pendiente Preguntar
                        TRT_ROW.DEATX1 := FB_REP_CAD(0,1);
                        TRT_ROW.DEATX2 := FB_REP_CAD(0,1);
                        TRT_ROW.DEATX3 := FB_REP_CAD(0,1);
                        TRT_ROW.DEATX4 := FB_REP_CAD(0,1);
                        TRT_ROW.DEATX5 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEATX6 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEATX7 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEATX8 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEATX9 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAWQT := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAWYT := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAFEE := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEASPR := FB_REP_DEC(CUR.WDEASPR,MAX9_6);
                        TRT_ROW.DEACFF := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAMXR := FB_REP_DEC(0,MAX9_6); --Pendiente Definir
                        TRT_ROW.DEAMIR := FB_REP_DEC(0,MAX9_6); --Pendiente Definir
                        TRT_ROW.DEAIIP := FB_REP_CAD(CUR.WDEAIIP,1);
                        TRT_ROW.DEABAP := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEABAM := FB_REP_NUM(0,2);
                        TRT_ROW.DEABAD := FB_REP_NUM(0,2);
                        TRT_ROW.DEABAY := FB_REP_NUM(0,4);
                        TRT_ROW.DEAPTM := FB_CAL_MES(CUR.WDEAPTM);
                        TRT_ROW.DEAPTD := FB_CAL_DIA(CUR.WDEAPTM);
                        TRT_ROW.DEAPTY := FB_CAL_ANYO(CUR.WDEAPTM);
                        TRT_ROW.DEAITM := FB_CAL_MES(CUR.WDEAITM);
                        TRT_ROW.DEAITD := FB_CAL_DIA(CUR.WDEAITM);
                        TRT_ROW.DEAITY := FB_CAL_ANYO(CUR.WDEAITM);
                        TRT_ROW.DEASTM := FB_REP_NUM(0,2);
                        TRT_ROW.DEASTD := FB_REP_NUM(0,2);
                        TRT_ROW.DEASTY := FB_REP_NUM(0,4);
                        TRT_ROW.DEAAVP := FB_REP_DEC(0,MAX17_2);
                        TRT_ROW.DEAMEP := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAMEI := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAPVI := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAPV2 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEALNC := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAUBT := FB_REP_NUM(0,5);
                        TRT_ROW.DEAASD := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAREF := FB_REP_CAD(ESPACIO,20);
                        TRT_ROW.DEATPL := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEATPY := FB_REP_DEC(0,MAX15_2); --Pendiente Preguntar
                        TRT_ROW.DEACPL := FB_REP_DEC(CUR.WDEACPL,MAX15_2);
                        TRT_ROW.DEACPY := FB_REP_DEC(CUR.WDEACPL,MAX15_2);
                        TRT_ROW.DEADEL := FB_REP_DEC(CUR.WDEADEL,MAX15_2);
                        TRT_ROW.DEADEY := FB_REP_DEC(CUR.WDEADEL,MAX15_2);
                        TRT_ROW.DEAIVL := FB_REP_DEC(CUR.WDEAIVL,MAX15_2);
                        TRT_ROW.DEAIVY := FB_REP_DEC(CUR.WDEAIVL,MAX15_2);
                        TRT_ROW.DEAI2L := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAI2Y := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAPIF := FB_REP_CAD('X',1);
                        TRT_ROW.DEABRK := FB_REP_CAD(ESPACIO,4);
                        TRT_ROW.DEABCP := FB_REP_DEC(0,MAX6_3);
                        TRT_ROW.DEABCL := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEABCY := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEACCF := FB_REP_DEC(0,MAX6_3);
                        TRT_ROW.DEAPRO := FB_REP_CAD('DEAPRO',4); --Pendiente Definir
                        TRT_ROW.DEAPIA := FB_REP_DEC(CUR.WDEAPIA,MAX15_4);
                        TRT_ROW.DEAPIP := FB_REP_DEC(CUR.WDEAPIP,MAX15_2);
                        TRT_ROW.DEAUC4 := FB_REP_CAD(ESPACIO,6);
                        TRT_ROW.DEAUC5 := FB_REP_CAD(ESPACIO,4);
                        TRT_ROW.DEASOF := FB_REP_CAD(ESPACIO,4);
                        TRT_ROW.DEACLF := FB_REP_CAD(CUR.WDEACLF,1);
                        TRT_ROW.DEAGLC := FB_REP_NUM(0,2); --Pendiente Definir
                        TRT_ROW.DEALGM := FB_REP_NUM(0,2); --Pendiente Definir
                        TRT_ROW.DEALGD := FB_REP_NUM(0,2); --Pendiente Definir
                        TRT_ROW.DEALGY := FB_REP_NUM(0,4); --Pendiente Definir
                        TRT_ROW.DEALNR := FB_REP_NUM(0,9);
                        TRT_ROW.DEAGPD := FB_REP_NUM(0,2);
                        --TRT_ROW.DEAEXM    :=  FB_CAL_MES(CUR.WDEAEXM); --Por definir
                        TRT_ROW.DEAEXM := FB_REP_NUM(0,2); --Por definir
                        TRT_ROW.DEAEXD := FB_REP_NUM(0,2);
                        TRT_ROW.DEAEXD := FB_REP_NUM(0,2); --Por definir
                        --TRT_ROW.DEAEXM    :=  FB_CAL_DIA(CUR.WDEAEXM); --Por definir
                        --TRT_ROW.DEAEXY    :=  FB_REP_NUM(FB_CAL_ANY(CUR.WDEAEXM); Pendientes de validacion
                        TRT_ROW.DEAEXY := FB_REP_NUM(0,4); --Pendientes de validacion
                       -- TRT_ROW.DEADED := FB_REP_DEC(CUR.WDEADED,MAX15_2);
                        TRT_ROW.DEADED := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAPCO := FB_REP_DEC(0,MAX5_3); --Pendiente Definir ESTA PENDIENTE EN AS400
                        TRT_ROW.DEAXRC := FB_REP_CAD(0,3);
                        TRT_ROW.DEAXRM := FB_REP_CAD(0,2);
                        TRT_ROW.DEAXRD := FB_REP_CAD(0,2);
                        TRT_ROW.DEAXRY := FB_REP_CAD(0,4);
                        TRT_ROW.DEAPCM := FB_REP_CAD(0,2);
                        TRT_ROW.DEAPCD := FB_REP_CAD(0,2);
                        TRT_ROW.DEAPCY := FB_REP_CAD(0,4);
                        TRT_ROW.DEAXRA := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAXRL := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAXRP := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEARET := FB_REP_CAD(CUR.WDEARET,1);
                        TRT_ROW.DEAREA := FB_REP_NUM(CUR.WDEAREA,12);
                        TRT_ROW.DEARCL := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAPCL := FB_REP_CAD('1',1);
                        TRT_ROW.DEATLN := FB_REP_CAD(ESPACIO,2);
                        TRT_ROW.DEAUC6 := FB_REP_CAD(CUR.WDEAUC6,4);
                        TRT_ROW.DEAUC7 := FB_REP_CAD(ESPACIO,4);
                        TRT_ROW.DEAOMM := FB_CAL_MES(CUR.WDEAOMM);
                        TRT_ROW.DEAOMD := FB_CAL_DIA(CUR.WDEAOMM);
                        TRT_ROW.DEAOMY := FB_CAL_ANYO(CUR.WDEAOMM);
                        TRT_ROW.DEAPSN := FB_REP_NUM(0,12);
                        TRT_ROW.DEAPSB := FB_REP_NUM(0,15);
                        TRT_ROW.DEAPSM := FB_REP_NUM(0,2);
                        TRT_ROW.DEAPSD := FB_REP_NUM(0,2);
                        TRT_ROW.DEAPSY := FB_REP_NUM(0,4);
                        TRT_ROW.DEALSM := FB_REP_NUM(0,2);
                        TRT_ROW.DEALSD := FB_REP_NUM(0,2);
                        TRT_ROW.DEALSY := FB_REP_NUM(0,4);
                        TRT_ROW.DEALSP := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEALSI := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEALSR := FB_REP_DEC(0,MAX9_6);
                        TRT_ROW.DEALSX := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEALSO := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAMEM := FB_REP_DEC(CUR.WDEAMEM,MAX15_2);
                        TRT_ROW.DEARRT := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAMVL := FB_REP_DEC(0,MAX21_8);
                        TRT_ROW.DEA2SP := FB_REP_NUM(0,2);
                        TRT_ROW.DEA2TR := FB_REP_NUM(0,3);
                        TRT_ROW.DEA2TC := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAREV := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAPSA := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEALSN := FB_REP_NUM(0,5);
                        TRT_ROW.DEANCU := FB_REP_NUM(CUR.WDEANCU,5);
                        TRT_ROW.DEAPCU := FB_REP_NUM(CUR.WDEAPCU,3);
                        TRT_ROW.DEACLS := FB_REP_NUM('01',2);
                        TRT_ROW.DEAACD := FB_REP_CAD('10',2);
                        TRT_ROW.DEAACS := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAORG := FB_REP_CAD(ESPACIO,4);
                        TRT_ROW.DEADST := FB_REP_CAD(ESPACIO,4);
                        TRT_ROW.DEACPE :=FB_REP_DEC(CUR.WDEACPE,MAX6_3); --SE CREO UNA SUMA, PUES LOS DATOS NO SON EXCLUYENTES COMO LO INDICA EL REQUERIMIENTO
                        TRT_ROW.DEACPE := FB_REP_DEC(0,MAX6_3); --Por Definir
                        TRT_ROW.DEAPAP := FB_REP_DEC(0,MAX6_3);
                        TRT_ROW.DEAMCY := FB_REP_NUM(0,2);
                        TRT_ROW.DEASUS := FB_REP_CAD(CUR.WDEASUS,1);
                        TRT_ROW.DEADLC := FB_REP_CAD(CUR.WDEADLC,1);
                        TRT_ROW.DEAFRA := FB_REP_CAD(CUR.WDEAFRA,1);
                        TRT_ROW.DEAPP1 := FB_REP_CAD('7',1);
                        TRT_ROW.DEAPP2 := FB_REP_CAD('6',1);
                        TRT_ROW.DEAPP3 := FB_REP_CAD('5',1);
                        TRT_ROW.DEAPP4 := FB_REP_CAD('4',1);
                        TRT_ROW.DEAPP5 := FB_REP_CAD('2',1);
                        TRT_ROW.DEAPP6 := FB_REP_CAD('3',1);
                        TRT_ROW.DEAPP7 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAPP8 := FB_REP_CAD('1',1);
                        TRT_ROW.DEAPP9 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEACRR := FB_REP_NUM(0,3);
                        TRT_ROW.DEAPRR := FB_REP_NUM(CUR.WDEAPRR,3);
                        TRT_ROW.DEAPYI := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEADCI := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAFLC := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAPRT := FB_REP_CAD(ESPACIO,2);
                        TRT_ROW.DEAPRP := FB_REP_DEC(0,MAX6_3);
                        TRT_ROW.DEAPIY := FB_REP_DEC(0,MAX15_2);--INCLUIDO
                        TRT_ROW.DEAIPY := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAPPY := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAINV := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAF01 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAF02 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAF03 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DESSCH := FB_REP_CAD(ESPACIO,4);
                        TRT_ROW.DEASST := FB_REP_CAD(ESPACIO,4);
                        TRT_ROW.DEAOFN := FB_REP_NUM(0,12);
                        TRT_ROW.DEAOPI := FB_REP_DEC(0,MAX13_2);
                        TRT_ROW.DEAAVI := FB_REP_DEC(0,MAX13_2);
                        TRT_ROW.DEAIDT := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAANT := FB_REP_NUM(0,3);
                        TRT_ROW.DEAOPT := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEATDA := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEATDM := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEANDB := FB_REP_NUM(0,5);
                        TRT_ROW.DEANDM := FB_REP_NUM(0,5);
                        TRT_ROW.DEAMPA := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAA01 := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAPCT := FB_REP_DEC(0,MAX6_3);
                        TRT_ROW.DEASOU := FB_REP_CAD(CUR.WDEASOU,4); 
                        TRT_ROW.DESDIB := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEACRP := FB_REP_DEC(0,MAX6_3);
                        TRT_ROW.DEAIDG := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAF04 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAF05 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAF06 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAF07 := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEACVI := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEACUI := FB_REP_CAD(ESPACIO,20);
                        TRT_ROW.DEASCA := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEACFA := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAPRM := FB_REP_CAD(CUR.WDEAPRM,1);
                        TRT_ROW.DEAECU := FB_REP_CAD('2',1);
                        TRT_ROW.DEAPSU := FB_REP_CAD(CUR.WDEAPSU,1); 
                        TRT_ROW.DEATSF := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEACFL := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEADTY := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAPAF := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAADT := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAIVC := FB_REP_CAD(ESPACIO,20);
                        TRT_ROW.DEASUT := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEASUC := FB_REP_CAD(ESPACIO,4);
                        TRT_ROW.DEAOFT := FB_REP_CAD(ESPACIO,2);
                        TRT_ROW.DEARTO := FB_REP_CAD(ESPACIO,2);
                        TRT_ROW.DEACDT := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEANPR := FB_REP_NUM(0,1);
                        TRT_ROW.DEACRC := FB_REP_CAD(ESPACIO,20);
                        TRT_ROW.DEACNL := FB_REP_CAD(ESPACIO,2);
                        TRT_ROW.DEACNV := FB_REP_CAD(ESPACIO,4);
                        TRT_ROW.DEAUNR := FB_REP_CAD(ESPACIO,35);
                        TRT_ROW.DEASTC := FB_REP_NUM(CUR.WDEASTC,3);
                        TRT_ROW.DEAEDM := FB_CAL_MES(CUR.WDEAEDM);
                        TRT_ROW.DEAEDD := FB_CAL_DIA(CUR.WDEAEDM);
                        TRT_ROW.DEAEDY := FB_CAL_ANYO(CUR.WDEAEDM);
                        TRT_ROW.DEAEDA := FB_CAL_DIA(CUR.WDEAEDM); 
                        TRT_ROW.DEAXRF := FB_REP_CAD('P',1);
                        TRT_ROW.DEACRT := FB_REP_DEC(0,MAX9_6);
                        TRT_ROW.DEAXDM := FB_REP_NUM(0,2);
                        TRT_ROW.DEAXDD := FB_REP_NUM(0,2);
                        TRT_ROW.DEAXDY := FB_REP_NUM(0,4);
                        TRT_ROW.DEAFLX := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEAFLY := FB_REP_CAD(ESPACIO,1);
                        TRT_ROW.DEARTX := FB_REP_DEC(0,MAX9_6);
                        TRT_ROW.DEARTZ := FB_REP_DEC(0,MAX9_6);
                        TRT_ROW.DEAMTZ := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEAMTY := FB_REP_DEC(0,MAX15_2);
                        TRT_ROW.DEALMM := FB_REP_NUM(0,2);
                        TRT_ROW.DEALMD := FB_REP_NUM(0,2);
                        TRT_ROW.DEALMY := FB_REP_NUM(0,4);
                        TRT_ROW.DEALMT := FB_REP_CAD(ESPACIO,26);
                        TRT_ROW.DEAACC1 := FB_REP_NUM(CUR.WDEAACC1,15);
                    EXCEPTION
                    WHEN VALUE_ERROR THEN
                        INSERT INTO MS_PRESTAMOS_CDTS VALUES TRT_ROW LOG ERRORS
                        INTO   LOG_MS_PRESTAMOS_CDTS ('INSERT' ) REJECT LIMIT UNLIMITED;

                        GOTO SIGUIENTE;
                    WHEN INVALID_NUMBER THEN
                        INSERT INTO MS_PRESTAMOS_CDTS VALUES TRT_ROW LOG ERRORS
                        INTO   LOG_MS_PRESTAMOS_CDTS ('INSERT' ) REJECT LIMIT UNLIMITED;

                        GOTO SIGUIENTE;
                    WHEN ACCESS_INTO_NULL THEN
                        INSERT INTO MS_PRESTAMOS_CDTS VALUES TRT_ROW LOG ERRORS
                        INTO   LOG_MS_PRESTAMOS_CDTS ('INSERT' ) REJECT LIMIT UNLIMITED;

                        GOTO SIGUIENTE;
                    END;
                    INSERT INTO MS_PRESTAMOS_CDTS VALUES TRT_ROW;

                    <<SIGUIENTE>> I := I+1;
                    IF MOD(I,1000)=0 THEN
                        COMMIT;
                    END IF;
                END LOOP;
                COMMIT;
                INDICE := ARRAYREGISTROS.NEXT(INDICE);
            END LOOP;
            EXIT WHEN CUR_NRO_CREDITO%NOTFOUND;
        END LOOP;
        CLOSE CUR_NRO_CREDITO;

END SP_MS_PRESTAMOS_CDTS_PRESTAMOS;