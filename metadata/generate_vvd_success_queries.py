#!/usr/bin/env python3
"""
Generate success_queries.xlsx - one tab per campaign mnemonic.
Each tab follows the source_to_target_mapping template:
  TOP:    Source-to-target mapping table (Target Column | source table | source column/logic)
  MIDDLE: Organic Success query  (all events, no campaign filter)
  BOTTOM: Campaign Success query (events joined to tactic population within treatment window)

All queries use EDW (Teradata) SQL syntax with PROC SQL / CONNECTION TO TERADATA pattern.
"""

import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from pathlib import Path

# ---------------------------------------------------------------------------
# Style constants
# ---------------------------------------------------------------------------
TITLE_FONT       = Font(name="Calibri", bold=True, size=14)
HEADER_FONT      = Font(name="Calibri", bold=True, size=12)
META_FONT        = Font(name="Calibri", size=11)
SQL_FONT         = Font(name="Consolas", size=10)
LABEL_FONT       = Font(name="Calibri", bold=True, size=11)

# Mapping table styles
MAP_HDR_FONT     = Font(name="Calibri", bold=True, size=11)
MAP_DATA_FONT    = Font(name="Calibri", size=11)
MAP_HDR_FILL     = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")  # green header

GREEN_FILL       = PatternFill(start_color="C6EFCE", end_color="C6EFCE", fill_type="solid")
BLUE_FILL        = PatternFill(start_color="BDD7EE", end_color="BDD7EE", fill_type="solid")

WRAP_ALIGN       = Alignment(wrap_text=False, vertical="top")
THIN_BORDER      = Border(
    left=Side(style="thin"), right=Side(style="thin"),
    top=Side(style="thin"), bottom=Side(style="thin"),
)

COL_A_WIDTH      = 30
COL_B_WIDTH      = 45
COL_C_WIDTH      = 50

# ---------------------------------------------------------------------------
# Snap-date subquery (reused everywhere except POS/Wallet tabs)
# ---------------------------------------------------------------------------
SNAP_SUBQUERY = (
    "(SELECT MAX(SNAP_DT) FROM DDWV01.VISA_DR_CRD_DLY "
    "WHERE SNAP_DT >= CURRENT_DATE - 7)"
)

# ---------------------------------------------------------------------------
# Source-to-target mapping rows per metric type
# Each entry is a list of (target_column, source_table, source_column_logic)
# ---------------------------------------------------------------------------

def _card_acq_mapping(mnemonic):
    return [
        ("clnt_no",            "DDWV01.VISA_DR_CRD_DLY",  "CLNT_NO"),
        ("acct_no",            "DDWV01.VISA_DR_CRD_DLY",  ""),
        ("amount",             "",                          ""),
        ("event_mnemonic_cd",  "",                          mnemonic),
        ("event_type_cd",      "",                          ""),
        ("event_attributes",   "DDWV01.VISA_DR_CRD_DLY",  "JSON(STS_CD, SRVC_ID)"),
        ("event_dt",           "DDWV01.VISA_DR_CRD_DLY",  "ISS_DT"),
        ("snap_dt",            "",                          "<GENERATED>"),
        ("job_id",             "",                          "<GENERATED>"),
    ]

def _card_actv_mapping(mnemonic):
    return [
        ("clnt_no",            "DDWV01.VISA_DR_CRD_DLY",  "CLNT_NO"),
        ("acct_no",            "DDWV01.VISA_DR_CRD_DLY",  ""),
        ("amount",             "",                          ""),
        ("event_mnemonic_cd",  "",                          mnemonic),
        ("event_type_cd",      "",                          ""),
        ("event_attributes",   "DDWV01.VISA_DR_CRD_DLY",  "JSON(STS_CD, SRVC_ID)"),
        ("event_dt",           "DDWV01.VISA_DR_CRD_DLY",  "ACTV_DT"),
        ("snap_dt",            "",                          "<GENERATED>"),
        ("job_id",             "",                          "<GENERATED>"),
    ]

def _card_usage_mapping(mnemonic):
    return [
        ("clnt_no",            "DDWV01.VISA_DR_CRD_DLY",  "CLNT_NO"),
        ("acct_no",            "DDWV01.VISA_DR_CRD_DLY",  ""),
        ("amount",             "",                          ""),
        ("event_mnemonic_cd",  "",                          mnemonic),
        ("event_type_cd",      "",                          ""),
        ("event_attributes",   "DDWV01.VISA_DR_CRD_DLY",  "JSON(STS_CD, SRVC_ID)"),
        ("event_dt",           "DDWV01.VISA_DR_CRD_DLY",  "ACTV_DT"),
        ("snap_dt",            "",                          "<GENERATED>"),
        ("job_id",             "",                          "<GENERATED>"),
    ]

def _wallet_mapping(mnemonic):
    return [
        ("clnt_no",            "DDWV05.CLNT_CRD_POS_LOG",  "CAST(SUBSTR(CLNT_CRD_NO, 7, 9) AS INTEGER)"),
        ("acct_no",            "DDWV05.CLNT_CRD_POS_LOG",  "CLNT_CRD_NO"),
        ("amount",             "",                           ""),
        ("event_mnemonic_cd",  "",                           mnemonic),
        ("event_type_cd",      "",                           ""),
        ("event_attributes",   "DDWV05.CLNT_CRD_POS_LOG + DL_DECMAN.TOKEN_LIST",
                                                             "JSON(TOKN_REQSTR_ID, TOKEN_WALLET_IND)"),
        ("event_dt",           "DDWV05.CLNT_CRD_POS_LOG",  "TXN_DT"),
        ("snap_dt",            "",                           "<GENERATED>"),
        ("job_id",             "",                           "<GENERATED>"),
    ]

def _imt_mapping(mnemonic):
    return [
        ("clnt_no",            "DDWV01.EXT_CDS_CHNL_EVNT",  "CLNT_NO"),
        ("acct_no",            "DDWV01.EXT_CDS_CHNL_EVNT",  "AR_ID"),
        ("amount",             "DDWV01.EXT_CDS_CHNL_EVNT",  "EVNT_AMT_CAD"),
        ("event_mnemonic_cd",  "",                            mnemonic),
        ("event_type_cd",      "",                            ""),
        ("event_attributes",   "DDWV01.EXT_CDS_CHNL_EVNT",  "JSON(CHNL_TYP_CD, EVNT_CRNCY_CD, ACTVY_TYP_CD)"),
        ("event_dt",           "DDWV01.EXT_CDS_CHNL_EVNT",  "CAPTR_DT"),
        ("snap_dt",            "",                            "<GENERATED>"),
        ("job_id",             "",                            "<GENERATED>"),
    ]

# ---------------------------------------------------------------------------
# Query definitions
# ---------------------------------------------------------------------------

# ---- VCN / VDA  (Card Acquisition - ISS_DT) --------------------------------
_CARD_ACQ_ORGANIC = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
CREATE TABLE work.organic_success AS
SELECT * FROM CONNECTION TO EDW (

    SELECT DISTINCT
        CLNT_NO,
        ISS_DT  AS SUCCESS_DT
    FROM DDWV01.VISA_DR_CRD_DLY
    WHERE STS_CD IN ('06','08')
      AND SRVC_ID = 36
      AND ISS_DT IS NOT NULL
      AND SNAP_DT = {SNAP_SUBQUERY}

);
DISCONNECT FROM EDW;
QUIT;"""


def _card_acq_campaign(mnemonic):
    return f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
CREATE TABLE work.campaign_success AS
SELECT * FROM CONNECTION TO EDW (

    SELECT DISTINCT
        A.CLNT_NO,
        A.ISS_DT            AS SUCCESS_DT,
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
      AND SUBSTR(B.TACTIC_ID, 8, 3) = '{mnemonic}'
      AND A.ISS_DT BETWEEN B.TREATMT_STRT_DT AND B.TREATMT_END_DT

);
DISCONNECT FROM EDW;
QUIT;"""


# ---- VDT  (Card Activation - ACTV_DT) --------------------------------------
_CARD_ACTV_ORGANIC = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
CREATE TABLE work.organic_success AS
SELECT * FROM CONNECTION TO EDW (

    SELECT DISTINCT
        CLNT_NO,
        ACTV_DT  AS SUCCESS_DT
    FROM DDWV01.VISA_DR_CRD_DLY
    WHERE STS_CD IN ('06','08')
      AND SRVC_ID = 36
      AND ISS_DT IS NOT NULL
      AND SNAP_DT = {SNAP_SUBQUERY}

);
DISCONNECT FROM EDW;
QUIT;"""


_CARD_ACTV_CAMPAIGN = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
CREATE TABLE work.campaign_success AS
SELECT * FROM CONNECTION TO EDW (

    SELECT DISTINCT
        A.CLNT_NO,
        A.ACTV_DT            AS SUCCESS_DT,
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
      AND SUBSTR(B.TACTIC_ID, 8, 3) = 'VDT'
      AND A.ACTV_DT BETWEEN B.TREATMT_STRT_DT AND B.TREATMT_END_DT

);
DISCONNECT FROM EDW;
QUIT;"""


# ---- VUI  (Card Usage - ACTV_DT from VISA_DR_CRD_DLY in EDW) --------------
_CARD_USAGE_ORGANIC = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
CREATE TABLE work.organic_success AS
SELECT * FROM CONNECTION TO EDW (

    SELECT DISTINCT
        CLNT_NO,
        ACTV_DT  AS SUCCESS_DT
    FROM DDWV01.VISA_DR_CRD_DLY
    WHERE STS_CD IN ('06','08')
      AND SRVC_ID = 36
      AND ISS_DT IS NOT NULL
      AND SNAP_DT = {SNAP_SUBQUERY}

);
DISCONNECT FROM EDW;
QUIT;"""


_CARD_USAGE_CAMPAIGN = f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
CREATE TABLE work.campaign_success AS
SELECT * FROM CONNECTION TO EDW (

    SELECT DISTINCT
        A.CLNT_NO,
        A.ACTV_DT            AS SUCCESS_DT,
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
      AND SUBSTR(B.TACTIC_ID, 8, 3) = 'VUI'
      AND A.ACTV_DT BETWEEN B.TREATMT_STRT_DT AND B.TREATMT_END_DT

);
DISCONNECT FROM EDW;
QUIT;"""


# ---- VUT / VAW  (Wallet Provisioning - POS + Token) ------------------------
_WALLET_ORGANIC = """\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
CREATE TABLE work.organic_success AS
SELECT * FROM CONNECTION TO EDW (

    SELECT DISTINCT
        CAST(SUBSTR(B.CLNT_CRD_NO, 7, 9) AS INTEGER)  AS CLNT_NO,
        B.TXN_DT                                        AS SUCCESS_DT
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

);
DISCONNECT FROM EDW;
QUIT;"""


def _wallet_campaign(mnemonic):
    return f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
CREATE TABLE work.campaign_success AS
SELECT * FROM CONNECTION TO EDW (

    SELECT DISTINCT
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
      AND SUBSTR(D.TACTIC_ID, 8, 3) = '{mnemonic}'
      AND B.TXN_DT BETWEEN D.TREATMT_STRT_DT AND D.TREATMT_END_DT

);
DISCONNECT FROM EDW;
QUIT;"""


# ---- IRI  (International Money Transfer - any IMT transaction = success) ----
_IMT_ORGANIC = """\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
CREATE TABLE work.organic_success AS
SELECT * FROM CONNECTION TO EDW (

    SELECT DISTINCT
        CLNT_NO,
        CAPTR_DT  AS SUCCESS_DT
    FROM DDWV01.EXT_CDS_CHNL_EVNT
    WHERE ACTVY_TYP_CD = '031'        /* 031 = International Money Transfer */

);
DISCONNECT FROM EDW;
QUIT;"""


def _imt_campaign(mnemonic):
    return f"""\
PROC SQL;
CONNECT TO TERADATA AS EDW (MODE=TERADATA);
CREATE TABLE work.campaign_success AS
SELECT * FROM CONNECTION TO EDW (

    SELECT DISTINCT
        A.CLNT_NO,
        A.CAPTR_DT           AS SUCCESS_DT,
        B.TACTIC_ID,
        B.TREATMT_STRT_DT,
        B.TREATMT_END_DT
    FROM DDWV01.EXT_CDS_CHNL_EVNT        AS A
    INNER JOIN DG6V01.TACTIC_EVNT_IP_AR_HIST AS B
        ON A.CLNT_NO = B.CLNT_NO
    WHERE A.ACTVY_TYP_CD = '031'          /* 031 = International Money Transfer */
      AND SUBSTR(B.TACTIC_ID, 8, 3) = '{mnemonic}'
      AND A.CAPTR_DT BETWEEN B.TREATMT_STRT_DT AND B.TREATMT_END_DT

);
DISCONNECT FROM EDW;
QUIT;"""


# ---------------------------------------------------------------------------
# Tab configuration
# (mnemonic, title_suffix, mapping_rows, organic_sql, campaign_sql)
# ---------------------------------------------------------------------------
TABS = [
    (
        "VCN",
        "Card Acquisition Success",
        _card_acq_mapping("VCN"),
        _CARD_ACQ_ORGANIC,
        _card_acq_campaign("VCN"),
    ),
    (
        "VDA",
        "Card Acquisition Success",
        _card_acq_mapping("VDA"),
        _CARD_ACQ_ORGANIC,
        _card_acq_campaign("VDA"),
    ),
    (
        "VDT",
        "Card Activation Success",
        _card_actv_mapping("VDT"),
        _CARD_ACTV_ORGANIC,
        _CARD_ACTV_CAMPAIGN,
    ),
    (
        "VUI",
        "Card Usage Success",
        _card_usage_mapping("VUI"),
        _CARD_USAGE_ORGANIC,
        _CARD_USAGE_CAMPAIGN,
    ),
    (
        "VUT",
        "Wallet Provisioning Success",
        _wallet_mapping("VUT"),
        _WALLET_ORGANIC,
        _wallet_campaign("VUT"),
    ),
    (
        "VAW",
        "Wallet Provisioning Success",
        _wallet_mapping("VAW"),
        _WALLET_ORGANIC,
        _wallet_campaign("VAW"),
    ),
    (
        "IRI",
        "International Money Transfer Success",
        _imt_mapping("IRI"),
        _IMT_ORGANIC,
        _imt_campaign("IRI"),
    ),
]


# ---------------------------------------------------------------------------
# Workbook builder
# ---------------------------------------------------------------------------
def build_workbook(output_path):
    wb = openpyxl.Workbook()
    # Remove the default sheet created by openpyxl
    wb.remove(wb.active)

    for mnemonic, title_suffix, mapping_rows, organic_sql, campaign_sql in TABS:
        ws = wb.create_sheet(title=f"{mnemonic}_Success")

        # Column widths
        ws.column_dimensions["A"].width = COL_A_WIDTH
        ws.column_dimensions["B"].width = COL_B_WIDTH
        ws.column_dimensions["C"].width = COL_C_WIDTH

        row = 1

        # =================================================================
        # Source-to-target mapping table (matching template format)
        # =================================================================

        # Header row (green fill)
        for col, header in enumerate(["Target Column", "source table", "source column/logic"], 1):
            cell = ws.cell(row=row, column=col, value=header)
            cell.font = MAP_HDR_FONT
            cell.fill = MAP_HDR_FILL
            cell.border = THIN_BORDER
        row += 1

        # Data rows
        for target_col, src_table, src_logic in mapping_rows:
            ws.cell(row=row, column=1, value=target_col).font = MAP_DATA_FONT
            ws.cell(row=row, column=2, value=src_table).font = MAP_DATA_FONT
            ws.cell(row=row, column=3, value=src_logic).font = MAP_DATA_FONT
            for col in range(1, 4):
                ws.cell(row=row, column=col).border = THIN_BORDER
            row += 1

        # Blank rows
        row += 2

        # =================================================================
        # Query: label
        # =================================================================
        ws.cell(row=row, column=1, value="Query:").font = LABEL_FONT
        row += 1

        # --- Organic header (green) ----------------------------------------
        cell = ws.cell(row=row, column=1, value="ORGANIC SUCCESS (All Events)")
        cell.font = HEADER_FONT
        cell.fill = GREEN_FILL
        row += 1

        # --- Organic SQL lines ----------------------------------------------
        for sql_line in organic_sql.splitlines():
            cell = ws.cell(row=row, column=1, value=sql_line)
            cell.font = SQL_FONT
            cell.alignment = WRAP_ALIGN
            row += 1

        # --- Blank separator ------------------------------------------------
        row += 2

        # --- Campaign header (blue) -----------------------------------------
        cell = ws.cell(row=row, column=1, value="CAMPAIGN SUCCESS (Tactic-Linked)")
        cell.font = HEADER_FONT
        cell.fill = BLUE_FILL
        row += 1

        # --- Campaign SQL lines ---------------------------------------------
        for sql_line in campaign_sql.splitlines():
            cell = ws.cell(row=row, column=1, value=sql_line)
            cell.font = SQL_FONT
            cell.alignment = WRAP_ALIGN
            row += 1

    # Save
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    wb.save(output_path)
    print(f"Workbook saved to: {output_path}")
    print(f"Tabs created: {[s.title for s in wb.worksheets]}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    OUTPUT = (
        "/mnt/c/Users/andre/New_projects/"
        "NBA Souccess Library - Copy/metadata/success_queries.xlsx"
    )
    build_workbook(OUTPUT)
