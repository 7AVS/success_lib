#!/usr/bin/env python3
"""
Generate success_queries.xlsx - one tab per campaign mnemonic.
Each tab follows the source_to_target_mapping template:
  1. Source-to-target mapping table
  2. ORGANIC: Sample (10 rows) + Summary (by year-month)
  3. CAMPAIGN: Sample (10 rows) + Summary (by year-month)

All queries use EDW (Teradata) SQL syntax with PROC SQL / CONNECTION TO TERADATA pattern.
"""

import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from pathlib import Path

# ---------------------------------------------------------------------------
# Style constants
# ---------------------------------------------------------------------------
HEADER_FONT      = Font(name="Calibri", bold=True, size=12)
SQL_FONT         = Font(name="Consolas", size=10)
LABEL_FONT       = Font(name="Calibri", bold=True, size=11)
MAP_HDR_FONT     = Font(name="Calibri", bold=True, size=11)
MAP_DATA_FONT    = Font(name="Calibri", size=11)

MAP_HDR_FILL     = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")
GREEN_FILL       = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")
BLUE_FILL        = PatternFill(start_color="BDD7EE", end_color="BDD7EE", fill_type="solid")
YELLOW_FILL      = PatternFill(start_color="FFF2CC", end_color="FFF2CC", fill_type="solid")

WRAP_ALIGN       = Alignment(wrap_text=False, vertical="top")
THIN_BORDER      = Border(
    left=Side(style="thin"), right=Side(style="thin"),
    top=Side(style="thin"), bottom=Side(style="thin"),
)

COL_A_WIDTH      = 30
COL_B_WIDTH      = 45
COL_C_WIDTH      = 50

# ---------------------------------------------------------------------------
# Snap-date subquery
# ---------------------------------------------------------------------------
SNAP_SUBQUERY = (
    "(SELECT MAX(SNAP_DT) FROM DDWV01.VISA_DR_CRD_DLY "
    "WHERE SNAP_DT >= CURRENT_DATE - 7)"
)

# ---------------------------------------------------------------------------
# Source-to-target mapping rows per metric type
# ---------------------------------------------------------------------------

def _card_acq_mapping(mne):
    return [
        ("clnt_no",            "DDWV01.VISA_DR_CRD_DLY",  "CLNT_NO"),
        ("acct_no",            "DDWV01.VISA_DR_CRD_DLY",  ""),
        ("amount",             "",                          ""),
        ("event_mnemonic_cd",  "",                          mne),
        ("event_type_cd",      "",                          ""),
        ("event_attributes",   "DDWV01.VISA_DR_CRD_DLY",  "JSON(STS_CD, SRVC_ID)"),
        ("event_dt",           "DDWV01.VISA_DR_CRD_DLY",  "ISS_DT"),
        ("snap_dt",            "",                          "<GENERATED>"),
        ("job_id",             "",                          "<GENERATED>"),
    ]

def _card_actv_mapping(mne):
    return [
        ("clnt_no",            "DDWV01.VISA_DR_CRD_DLY",  "CLNT_NO"),
        ("acct_no",            "DDWV01.VISA_DR_CRD_DLY",  ""),
        ("amount",             "",                          ""),
        ("event_mnemonic_cd",  "",                          mne),
        ("event_type_cd",      "",                          ""),
        ("event_attributes",   "DDWV01.VISA_DR_CRD_DLY",  "JSON(STS_CD, SRVC_ID)"),
        ("event_dt",           "DDWV01.VISA_DR_CRD_DLY",  "ACTV_DT"),
        ("snap_dt",            "",                          "<GENERATED>"),
        ("job_id",             "",                          "<GENERATED>"),
    ]

def _card_usage_mapping(mne):
    return [
        ("clnt_no",            "DDWV01.VISA_DR_CRD_DLY",  "CLNT_NO"),
        ("acct_no",            "DDWV01.VISA_DR_CRD_DLY",  ""),
        ("amount",             "",                          ""),
        ("event_mnemonic_cd",  "",                          mne),
        ("event_type_cd",      "",                          ""),
        ("event_attributes",   "DDWV01.VISA_DR_CRD_DLY",  "JSON(STS_CD, SRVC_ID)"),
        ("event_dt",           "DDWV01.VISA_DR_CRD_DLY",  "ACTV_DT"),
        ("snap_dt",            "",                          "<GENERATED>"),
        ("job_id",             "",                          "<GENERATED>"),
    ]

def _wallet_mapping(mne):
    return [
        ("clnt_no",            "DDWV05.CLNT_CRD_POS_LOG",  "CAST(SUBSTR(CLNT_CRD_NO, 7, 9) AS INTEGER)"),
        ("acct_no",            "DDWV05.CLNT_CRD_POS_LOG",  "CLNT_CRD_NO"),
        ("amount",             "",                           ""),
        ("event_mnemonic_cd",  "",                           mne),
        ("event_type_cd",      "",                           ""),
        ("event_attributes",   "DDWV05.CLNT_CRD_POS_LOG + DL_DECMAN.TOKEN_LIST",
                                                             "JSON(TOKN_REQSTR_ID, TOKEN_WALLET_IND)"),
        ("event_dt",           "DDWV05.CLNT_CRD_POS_LOG",  "TXN_DT"),
        ("snap_dt",            "",                           "<GENERATED>"),
        ("job_id",             "",                           "<GENERATED>"),
    ]

def _imt_mapping(mne):
    return [
        ("clnt_no",            "DDWV01.EXT_CDS_CHNL_EVNT",  "CLNT_NO"),
        ("acct_no",            "DDWV01.EXT_CDS_CHNL_EVNT",  "AR_ID"),
        ("amount",             "DDWV01.EXT_CDS_CHNL_EVNT",  "EVNT_AMT_CAD"),
        ("event_mnemonic_cd",  "",                            mne),
        ("event_type_cd",      "",                            ""),
        ("event_attributes",   "DDWV01.EXT_CDS_CHNL_EVNT",  "JSON(CHNL_TYP_CD, EVNT_CRNCY_CD, ACTVY_TYP_CD)"),
        ("event_dt",           "DDWV01.EXT_CDS_CHNL_EVNT",  "CAPTR_DT"),
        ("snap_dt",            "",                            "<GENERATED>"),
        ("job_id",             "",                            "<GENERATED>"),
    ]


# ===========================================================================
# Query builder functions
# Each returns (sample_sql, summary_sql) for organic and campaign
# ===========================================================================

# --- CARD ACQUISITION (VCN, VDA) -------------------------------------------

def card_acq_organic():
    sample = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT TOP 10
        CLNT_NO,
        ISS_DT        AS SUCCESS_DT,
        STS_CD,
        SRVC_ID
    FROM DDWV01.VISA_DR_CRD_DLY
    WHERE STS_CD IN ('06','08')
      AND SRVC_ID = 36
      AND ISS_DT IS NOT NULL
      AND SNAP_DT = {SNAP_SUBQUERY}
    ORDER BY ISS_DT DESC

);
DISCONNECT FROM EDW;
QUIT;"""

    summary = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT
        EXTRACT(YEAR FROM ISS_DT)  AS yr,
        EXTRACT(MONTH FROM ISS_DT) AS mo,
        COUNT(DISTINCT CLNT_NO)    AS unique_clients,
        COUNT(*)                   AS total_events
    FROM DDWV01.VISA_DR_CRD_DLY
    WHERE STS_CD IN ('06','08')
      AND SRVC_ID = 36
      AND ISS_DT IS NOT NULL
      AND SNAP_DT = {SNAP_SUBQUERY}
    GROUP BY 1, 2
    ORDER BY 1, 2

);
DISCONNECT FROM EDW;
QUIT;"""
    return sample, summary


def card_acq_campaign(mne):
    sample = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT TOP 10
        A.CLNT_NO,
        A.ISS_DT            AS SUCCESS_DT,
        A.STS_CD,
        B.TACTIC_ID,
        B.TREATMT_STRT_DT,
        B.TREATMT_END_DT
    FROM DDWV01.VISA_DR_CRD_DLY        AS A
    INNER JOIN DG6V01.TACTIC_EVNT_IP_AR_HIST AS B
        ON A.CLNT_NO = B.CLNT_NO
    WHERE A.STS_CD IN ('06','08')
      AND A.SRVC_ID = 36
      AND A.ISS_DT IS NOT NULL
      AND A.SNAP_DT = {SNAP_SUBQUERY}
      AND SUBSTR(B.TACTIC_ID, 8, 3) = '{mne}'
      AND A.ISS_DT BETWEEN B.TREATMT_STRT_DT AND B.TREATMT_END_DT
    ORDER BY A.ISS_DT DESC

);
DISCONNECT FROM EDW;
QUIT;"""

    summary = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT
        EXTRACT(YEAR FROM A.ISS_DT)  AS yr,
        EXTRACT(MONTH FROM A.ISS_DT) AS mo,
        COUNT(DISTINCT A.CLNT_NO)    AS unique_clients,
        COUNT(*)                     AS total_events
    FROM DDWV01.VISA_DR_CRD_DLY        AS A
    INNER JOIN DG6V01.TACTIC_EVNT_IP_AR_HIST AS B
        ON A.CLNT_NO = B.CLNT_NO
    WHERE A.STS_CD IN ('06','08')
      AND A.SRVC_ID = 36
      AND A.ISS_DT IS NOT NULL
      AND A.SNAP_DT = {SNAP_SUBQUERY}
      AND SUBSTR(B.TACTIC_ID, 8, 3) = '{mne}'
      AND A.ISS_DT BETWEEN B.TREATMT_STRT_DT AND B.TREATMT_END_DT
    GROUP BY 1, 2
    ORDER BY 1, 2

);
DISCONNECT FROM EDW;
QUIT;"""
    return sample, summary


# --- CARD ACTIVATION (VDT) -------------------------------------------------

def card_actv_organic():
    sample = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT TOP 10
        CLNT_NO,
        ACTV_DT       AS SUCCESS_DT,
        STS_CD,
        SRVC_ID
    FROM DDWV01.VISA_DR_CRD_DLY
    WHERE STS_CD IN ('06','08')
      AND SRVC_ID = 36
      AND ISS_DT IS NOT NULL
      AND ACTV_DT IS NOT NULL
      AND SNAP_DT = {SNAP_SUBQUERY}
    ORDER BY ACTV_DT DESC

);
DISCONNECT FROM EDW;
QUIT;"""

    summary = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT
        EXTRACT(YEAR FROM ACTV_DT)  AS yr,
        EXTRACT(MONTH FROM ACTV_DT) AS mo,
        COUNT(DISTINCT CLNT_NO)     AS unique_clients,
        COUNT(*)                    AS total_events
    FROM DDWV01.VISA_DR_CRD_DLY
    WHERE STS_CD IN ('06','08')
      AND SRVC_ID = 36
      AND ISS_DT IS NOT NULL
      AND ACTV_DT IS NOT NULL
      AND SNAP_DT = {SNAP_SUBQUERY}
    GROUP BY 1, 2
    ORDER BY 1, 2

);
DISCONNECT FROM EDW;
QUIT;"""
    return sample, summary


def card_actv_campaign(mne):
    sample = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT TOP 10
        A.CLNT_NO,
        A.ACTV_DT           AS SUCCESS_DT,
        A.STS_CD,
        B.TACTIC_ID,
        B.TREATMT_STRT_DT,
        B.TREATMT_END_DT
    FROM DDWV01.VISA_DR_CRD_DLY        AS A
    INNER JOIN DG6V01.TACTIC_EVNT_IP_AR_HIST AS B
        ON A.CLNT_NO = B.CLNT_NO
    WHERE A.STS_CD IN ('06','08')
      AND A.SRVC_ID = 36
      AND A.ISS_DT IS NOT NULL
      AND A.ACTV_DT IS NOT NULL
      AND A.SNAP_DT = {SNAP_SUBQUERY}
      AND SUBSTR(B.TACTIC_ID, 8, 3) = '{mne}'
      AND A.ACTV_DT BETWEEN B.TREATMT_STRT_DT AND B.TREATMT_END_DT
    ORDER BY A.ACTV_DT DESC

);
DISCONNECT FROM EDW;
QUIT;"""

    summary = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT
        EXTRACT(YEAR FROM A.ACTV_DT)  AS yr,
        EXTRACT(MONTH FROM A.ACTV_DT) AS mo,
        COUNT(DISTINCT A.CLNT_NO)     AS unique_clients,
        COUNT(*)                      AS total_events
    FROM DDWV01.VISA_DR_CRD_DLY        AS A
    INNER JOIN DG6V01.TACTIC_EVNT_IP_AR_HIST AS B
        ON A.CLNT_NO = B.CLNT_NO
    WHERE A.STS_CD IN ('06','08')
      AND A.SRVC_ID = 36
      AND A.ISS_DT IS NOT NULL
      AND A.ACTV_DT IS NOT NULL
      AND A.SNAP_DT = {SNAP_SUBQUERY}
      AND SUBSTR(B.TACTIC_ID, 8, 3) = '{mne}'
      AND A.ACTV_DT BETWEEN B.TREATMT_STRT_DT AND B.TREATMT_END_DT
    GROUP BY 1, 2
    ORDER BY 1, 2

);
DISCONNECT FROM EDW;
QUIT;"""
    return sample, summary


# --- CARD USAGE (VUI) ------------------------------------------------------

def card_usage_organic():
    sample = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT TOP 10
        CLNT_NO,
        ACTV_DT       AS SUCCESS_DT,
        STS_CD,
        SRVC_ID
    FROM DDWV01.VISA_DR_CRD_DLY
    WHERE STS_CD IN ('06','08')
      AND SRVC_ID = 36
      AND ISS_DT IS NOT NULL
      AND SNAP_DT = {SNAP_SUBQUERY}
    ORDER BY ACTV_DT DESC

);
DISCONNECT FROM EDW;
QUIT;"""

    summary = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT
        EXTRACT(YEAR FROM ACTV_DT)  AS yr,
        EXTRACT(MONTH FROM ACTV_DT) AS mo,
        COUNT(DISTINCT CLNT_NO)     AS unique_clients,
        COUNT(*)                    AS total_events
    FROM DDWV01.VISA_DR_CRD_DLY
    WHERE STS_CD IN ('06','08')
      AND SRVC_ID = 36
      AND ISS_DT IS NOT NULL
      AND SNAP_DT = {SNAP_SUBQUERY}
    GROUP BY 1, 2
    ORDER BY 1, 2

);
DISCONNECT FROM EDW;
QUIT;"""
    return sample, summary


def card_usage_campaign(mne):
    sample = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT TOP 10
        A.CLNT_NO,
        A.ACTV_DT           AS SUCCESS_DT,
        A.STS_CD,
        B.TACTIC_ID,
        B.TREATMT_STRT_DT,
        B.TREATMT_END_DT
    FROM DDWV01.VISA_DR_CRD_DLY        AS A
    INNER JOIN DG6V01.TACTIC_EVNT_IP_AR_HIST AS B
        ON A.CLNT_NO = B.CLNT_NO
    WHERE A.STS_CD IN ('06','08')
      AND A.SRVC_ID = 36
      AND A.ISS_DT IS NOT NULL
      AND A.SNAP_DT = {SNAP_SUBQUERY}
      AND SUBSTR(B.TACTIC_ID, 8, 3) = '{mne}'
      AND A.ACTV_DT BETWEEN B.TREATMT_STRT_DT AND B.TREATMT_END_DT
    ORDER BY A.ACTV_DT DESC

);
DISCONNECT FROM EDW;
QUIT;"""

    summary = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT
        EXTRACT(YEAR FROM A.ACTV_DT)  AS yr,
        EXTRACT(MONTH FROM A.ACTV_DT) AS mo,
        COUNT(DISTINCT A.CLNT_NO)     AS unique_clients,
        COUNT(*)                      AS total_events
    FROM DDWV01.VISA_DR_CRD_DLY        AS A
    INNER JOIN DG6V01.TACTIC_EVNT_IP_AR_HIST AS B
        ON A.CLNT_NO = B.CLNT_NO
    WHERE A.STS_CD IN ('06','08')
      AND A.SRVC_ID = 36
      AND A.ISS_DT IS NOT NULL
      AND A.SNAP_DT = {SNAP_SUBQUERY}
      AND SUBSTR(B.TACTIC_ID, 8, 3) = '{mne}'
      AND A.ACTV_DT BETWEEN B.TREATMT_STRT_DT AND B.TREATMT_END_DT
    GROUP BY 1, 2
    ORDER BY 1, 2

);
DISCONNECT FROM EDW;
QUIT;"""
    return sample, summary


# --- WALLET PROVISIONING (VUT, VAW) ----------------------------------------

def wallet_organic():
    sample = """\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT TOP 10
        CAST(SUBSTR(B.CLNT_CRD_NO, 7, 9) AS INTEGER)  AS CLNT_NO,
        B.TXN_DT                                        AS SUCCESS_DT,
        B.TOKN_REQSTR_ID,
        C.TOKEN_WALLET_IND
    FROM DDWV05.CLNT_CRD_POS_LOG  AS B
    INNER JOIN DL_DECMAN.TOKEN_LIST AS C
        ON B.TOKN_REQSTR_ID = C.TOKEN_ID
    WHERE B.AMT1 = 0
      AND SUBSTR(B.CLNT_CRD_NO, 1, 5)  = '45190'
      AND SUBSTR(B.VISA_DR_CRD_NO, 1, 5) = '45199'
      AND SUBSTR(B.TOKN_REQSTR_ID, 1, 1) > '0'
      AND B.POS_ENTR_MODE_CD_NON_EMV = '000'
      AND B.SRVC_CD = 36
      AND C.TOKEN_WALLET_IND = 'Y'
    ORDER BY B.TXN_DT DESC

);
DISCONNECT FROM EDW;
QUIT;"""

    summary = """\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT
        EXTRACT(YEAR FROM B.TXN_DT)  AS yr,
        EXTRACT(MONTH FROM B.TXN_DT) AS mo,
        COUNT(DISTINCT CAST(SUBSTR(B.CLNT_CRD_NO, 7, 9) AS INTEGER))
                                      AS unique_clients,
        COUNT(*)                      AS total_events
    FROM DDWV05.CLNT_CRD_POS_LOG  AS B
    INNER JOIN DL_DECMAN.TOKEN_LIST AS C
        ON B.TOKN_REQSTR_ID = C.TOKEN_ID
    WHERE B.AMT1 = 0
      AND SUBSTR(B.CLNT_CRD_NO, 1, 5)  = '45190'
      AND SUBSTR(B.VISA_DR_CRD_NO, 1, 5) = '45199'
      AND SUBSTR(B.TOKN_REQSTR_ID, 1, 1) > '0'
      AND B.POS_ENTR_MODE_CD_NON_EMV = '000'
      AND B.SRVC_CD = 36
      AND C.TOKEN_WALLET_IND = 'Y'
    GROUP BY 1, 2
    ORDER BY 1, 2

);
DISCONNECT FROM EDW;
QUIT;"""
    return sample, summary


def wallet_campaign(mne):
    sample = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT TOP 10
        CAST(SUBSTR(B.CLNT_CRD_NO, 7, 9) AS INTEGER)  AS CLNT_NO,
        B.TXN_DT                                        AS SUCCESS_DT,
        D.TACTIC_ID,
        D.TREATMT_STRT_DT,
        D.TREATMT_END_DT
    FROM DDWV05.CLNT_CRD_POS_LOG  AS B
    INNER JOIN DL_DECMAN.TOKEN_LIST AS C
        ON B.TOKN_REQSTR_ID = C.TOKEN_ID
    INNER JOIN DG6V01.TACTIC_EVNT_IP_AR_HIST AS D
        ON CAST(SUBSTR(B.CLNT_CRD_NO, 7, 9) AS INTEGER) = D.CLNT_NO
    WHERE B.AMT1 = 0
      AND SUBSTR(B.CLNT_CRD_NO, 1, 5)  = '45190'
      AND SUBSTR(B.VISA_DR_CRD_NO, 1, 5) = '45199'
      AND SUBSTR(B.TOKN_REQSTR_ID, 1, 1) > '0'
      AND B.POS_ENTR_MODE_CD_NON_EMV = '000'
      AND B.SRVC_CD = 36
      AND C.TOKEN_WALLET_IND = 'Y'
      AND SUBSTR(D.TACTIC_ID, 8, 3) = '{mne}'
      AND B.TXN_DT BETWEEN D.TREATMT_STRT_DT AND D.TREATMT_END_DT
    ORDER BY B.TXN_DT DESC

);
DISCONNECT FROM EDW;
QUIT;"""

    summary = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT
        EXTRACT(YEAR FROM B.TXN_DT)  AS yr,
        EXTRACT(MONTH FROM B.TXN_DT) AS mo,
        COUNT(DISTINCT CAST(SUBSTR(B.CLNT_CRD_NO, 7, 9) AS INTEGER))
                                      AS unique_clients,
        COUNT(*)                      AS total_events
    FROM DDWV05.CLNT_CRD_POS_LOG  AS B
    INNER JOIN DL_DECMAN.TOKEN_LIST AS C
        ON B.TOKN_REQSTR_ID = C.TOKEN_ID
    INNER JOIN DG6V01.TACTIC_EVNT_IP_AR_HIST AS D
        ON CAST(SUBSTR(B.CLNT_CRD_NO, 7, 9) AS INTEGER) = D.CLNT_NO
    WHERE B.AMT1 = 0
      AND SUBSTR(B.CLNT_CRD_NO, 1, 5)  = '45190'
      AND SUBSTR(B.VISA_DR_CRD_NO, 1, 5) = '45199'
      AND SUBSTR(B.TOKN_REQSTR_ID, 1, 1) > '0'
      AND B.POS_ENTR_MODE_CD_NON_EMV = '000'
      AND B.SRVC_CD = 36
      AND C.TOKEN_WALLET_IND = 'Y'
      AND SUBSTR(D.TACTIC_ID, 8, 3) = '{mne}'
      AND B.TXN_DT BETWEEN D.TREATMT_STRT_DT AND D.TREATMT_END_DT
    GROUP BY 1, 2
    ORDER BY 1, 2

);
DISCONNECT FROM EDW;
QUIT;"""
    return sample, summary


# --- IMT (IRI) --------------------------------------------------------------

def imt_organic():
    sample = """\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT TOP 10
        CLNT_NO,
        CAPTR_DT          AS SUCCESS_DT,
        EVNT_ID,
        EVNT_AMT_CAD,
        CHNL_TYP_CD,
        EVNT_CRNCY_CD
    FROM DDWV01.EXT_CDS_CHNL_EVNT
    WHERE ACTVY_TYP_CD = '031'
    ORDER BY CAPTR_DT DESC

);
DISCONNECT FROM EDW;
QUIT;"""

    summary = """\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT
        EXTRACT(YEAR FROM CAPTR_DT)  AS yr,
        EXTRACT(MONTH FROM CAPTR_DT) AS mo,
        COUNT(DISTINCT CLNT_NO)      AS unique_clients,
        COUNT(DISTINCT EVNT_ID)      AS unique_transactions,
        SUM(EVNT_AMT_CAD)            AS total_amt_cad
    FROM DDWV01.EXT_CDS_CHNL_EVNT
    WHERE ACTVY_TYP_CD = '031'
    GROUP BY 1, 2
    ORDER BY 1, 2

);
DISCONNECT FROM EDW;
QUIT;"""
    return sample, summary


def imt_campaign(mne):
    sample = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT TOP 10
        A.CLNT_NO,
        A.CAPTR_DT           AS SUCCESS_DT,
        A.EVNT_ID,
        A.EVNT_AMT_CAD,
        A.CHNL_TYP_CD,
        B.TACTIC_ID,
        B.TREATMT_STRT_DT,
        B.TREATMT_END_DT
    FROM DDWV01.EXT_CDS_CHNL_EVNT        AS A
    INNER JOIN DG6V01.TACTIC_EVNT_IP_AR_HIST AS B
        ON A.CLNT_NO = B.CLNT_NO
    WHERE A.ACTVY_TYP_CD = '031'
      AND SUBSTR(B.TACTIC_ID, 8, 3) = '{mne}'
      AND A.CAPTR_DT BETWEEN B.TREATMT_STRT_DT AND B.TREATMT_END_DT
    ORDER BY A.CAPTR_DT DESC

);
DISCONNECT FROM EDW;
QUIT;"""

    summary = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
SELECT * FROM CONNECTION TO EDW (

    SELECT
        EXTRACT(YEAR FROM A.CAPTR_DT)  AS yr,
        EXTRACT(MONTH FROM A.CAPTR_DT) AS mo,
        COUNT(DISTINCT A.CLNT_NO)      AS unique_clients,
        COUNT(DISTINCT A.EVNT_ID)      AS unique_transactions,
        SUM(A.EVNT_AMT_CAD)            AS total_amt_cad
    FROM DDWV01.EXT_CDS_CHNL_EVNT        AS A
    INNER JOIN DG6V01.TACTIC_EVNT_IP_AR_HIST AS B
        ON A.CLNT_NO = B.CLNT_NO
    WHERE A.ACTVY_TYP_CD = '031'
      AND SUBSTR(B.TACTIC_ID, 8, 3) = '{mne}'
      AND A.CAPTR_DT BETWEEN B.TREATMT_STRT_DT AND B.TREATMT_END_DT
    GROUP BY 1, 2
    ORDER BY 1, 2

);
DISCONNECT FROM EDW;
QUIT;"""
    return sample, summary


# ---------------------------------------------------------------------------
# Tab configuration
# (mnemonic, title, mapping_fn, organic_fn, campaign_fn)
# ---------------------------------------------------------------------------
TABS = [
    ("VCN", "Card Acquisition",         _card_acq_mapping,   card_acq_organic,   card_acq_campaign),
    ("VDA", "Card Acquisition",         _card_acq_mapping,   card_acq_organic,   card_acq_campaign),
    ("VDT", "Card Activation",          _card_actv_mapping,  card_actv_organic,  card_actv_campaign),
    ("VUI", "Card Usage",               _card_usage_mapping, card_usage_organic, card_usage_campaign),
    ("VUT", "Wallet Provisioning",      _wallet_mapping,     wallet_organic,     wallet_campaign),
    ("VAW", "Wallet Provisioning",      _wallet_mapping,     wallet_organic,     wallet_campaign),
    ("IRI", "Intl Money Transfer",      _imt_mapping,        imt_organic,        imt_campaign),
]


# ---------------------------------------------------------------------------
# Workbook builder
# ---------------------------------------------------------------------------
def _write_sql_block(ws, row, sql_text):
    """Write SQL lines into column A starting at `row`. Returns next empty row."""
    for line in sql_text.splitlines():
        cell = ws.cell(row=row, column=1, value=line)
        cell.font = SQL_FONT
        cell.alignment = WRAP_ALIGN
        row += 1
    return row


def build_workbook(output_path):
    wb = openpyxl.Workbook()
    wb.remove(wb.active)

    for mne, title, mapping_fn, organic_fn, campaign_fn in TABS:
        ws = wb.create_sheet(title=f"{mne}_Success")
        ws.column_dimensions["A"].width = COL_A_WIDTH
        ws.column_dimensions["B"].width = COL_B_WIDTH
        ws.column_dimensions["C"].width = COL_C_WIDTH

        row = 1

        # ==== SOURCE-TO-TARGET MAPPING TABLE ================================
        for col, hdr in enumerate(["Target Column", "source table", "source column/logic"], 1):
            c = ws.cell(row=row, column=col, value=hdr)
            c.font = MAP_HDR_FONT
            c.fill = MAP_HDR_FILL
            c.border = THIN_BORDER
        row += 1

        for tcol, stbl, slogic in mapping_fn(mne):
            ws.cell(row=row, column=1, value=tcol).font = MAP_DATA_FONT
            ws.cell(row=row, column=2, value=stbl).font = MAP_DATA_FONT
            ws.cell(row=row, column=3, value=slogic).font = MAP_DATA_FONT
            for col in range(1, 4):
                ws.cell(row=row, column=col).border = THIN_BORDER
            row += 1

        row += 2  # blank

        # ==== ORGANIC SECTION ===============================================
        ws.cell(row=row, column=1, value="Query:").font = LABEL_FONT
        row += 1

        # -- Organic Sample --
        c = ws.cell(row=row, column=1, value="ORGANIC — Sample (10 rows)")
        c.font = HEADER_FONT
        c.fill = GREEN_FILL
        row += 1

        org_sample, org_summary = organic_fn()
        row = _write_sql_block(ws, row, org_sample)
        row += 1

        # -- Organic Summary --
        c = ws.cell(row=row, column=1, value="ORGANIC — Summary (by year-month)")
        c.font = HEADER_FONT
        c.fill = YELLOW_FILL
        row += 1

        row = _write_sql_block(ws, row, org_summary)
        row += 2

        # ==== CAMPAIGN SECTION ==============================================

        # -- Campaign Sample --
        c = ws.cell(row=row, column=1, value=f"CAMPAIGN ({mne}) — Sample (10 rows)")
        c.font = HEADER_FONT
        c.fill = BLUE_FILL
        row += 1

        cmp_sample, cmp_summary = campaign_fn(mne)
        row = _write_sql_block(ws, row, cmp_sample)
        row += 1

        # -- Campaign Summary --
        c = ws.cell(row=row, column=1, value=f"CAMPAIGN ({mne}) — Summary (by year-month)")
        c.font = HEADER_FONT
        c.fill = YELLOW_FILL
        row += 1

        row = _write_sql_block(ws, row, cmp_summary)

    # Save
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    wb.save(output_path)
    print(f"Workbook saved to: {output_path}")
    print(f"Tabs: {[s.title for s in wb.worksheets]}")


# ---------------------------------------------------------------------------
if __name__ == "__main__":
    OUTPUT = (
        "/mnt/c/Users/andre/New_projects/"
        "NBA Souccess Library - Copy/metadata/success_queries.xlsx"
    )
    build_workbook(OUTPUT)
