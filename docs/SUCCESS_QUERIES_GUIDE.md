# Success Queries Workbook Guide

**File:** `metadata/success_queries.xlsx`
**Last Updated:** 2026-02-04
**Status:** Active - 12 campaigns documented

---

## What Is This File?

The `success_queries.xlsx` workbook contains the SQL logic used to identify **success events** for marketing campaigns. Each tab represents one campaign mnemonic and provides ready-to-run Teradata SQL queries via the `PROC SQL / CONNECT TO TERADATA` pattern used in SAS.

The workbook is designed so that anyone on the team can:

1. Understand what data sources each campaign uses
2. Run a **sample query** (10 rows) to see what the raw data looks like
3. Run a **summary query** (grouped by year-month) to validate volumes and trends
4. See both **organic** (all events regardless of campaign) and **campaign-linked** (events tied to a specific tactic) views

---

## Tab Structure

Every tab follows the same layout:

### 1. Source-to-Target Mapping Table (top of tab)

A bordered table with three columns:

| Column | Description |
|--------|-------------|
| **Target Column** | The standardized output field name (e.g., `clnt_no`, `event_dt`, `amount`) |
| **source table** | The EDW table where this field comes from |
| **source column/logic** | The specific column name or transformation logic |

This mapping shows how raw source data maps to our standardized success event schema.

### 2. Organic - Sample (10 rows)

**Green header.** Returns 10 recent rows from the source table with no campaign filter. This shows all events of that type regardless of whether a campaign was involved.

Use this to: verify the data exists, check field values, confirm date ranges.

### 3. Organic - Summary (by year-month)

**Yellow header.** Aggregates all organic events by year and month, showing `unique_clients` and `total_events`. Some campaigns also include amount totals.

Use this to: validate overall volumes, spot seasonality, confirm data freshness.

### 4. Campaign - Sample (10 rows)

**Blue header.** Returns 10 recent rows joined to `DG6V01.TACTIC_EVNT_IP_AR_HIST` filtered by the campaign mnemonic. This links success events to specific campaign treatments.

The join logic uses:
- `SUBSTR(TACTIC_ID, 8, 3) = '<MNE>'` to filter by mnemonic
- `SUCCESS_DT BETWEEN TREATMT_STRT_DT AND TREATMT_END_DT` to match within the treatment window

Use this to: verify campaign-level attribution is working, check tactic IDs.

### 5. Campaign - Summary (by year-month)

**Yellow header.** Same aggregation as organic summary but filtered to campaign-linked events only.

Use this to: compare campaign volumes vs organic volumes, validate campaign attribution rates.

---

## Campaigns Covered (12 tabs)

### VVD Card Campaigns (6 tabs)

| Tab | Mnemonic | Metric | Source Table |
|-----|----------|--------|--------------|
| VCN_Success | VCN | Card Acquisition | DDWV01.VISA_DR_CRD_DLY |
| VDA_Success | VDA | Card Acquisition | DDWV01.VISA_DR_CRD_DLY |
| VDT_Success | VDT | Card Activation | DDWV01.VISA_DR_CRD_DLY |
| VUI_Success | VUI | Card Usage | DDWV01.VISA_DR_CRD_DLY |
| VUT_Success | VUT | Wallet Provisioning | DDWV05.CLNT_CRD_POS_LOG + DL_DECMAN.TOKEN_LIST |
| VAW_Success | VAW | Wallet Provisioning | DDWV05.CLNT_CRD_POS_LOG + DL_DECMAN.TOKEN_LIST |

**Key filters for VVD cards:** `STS_CD IN ('06','08')`, `SRVC_ID = 36`, `SNAP_DT = MAX(SNAP_DT)`.

**Key filters for wallet:** `AMT1 = 0`, BIN prefix `45190`/`45199`, `TOKEN_WALLET_IND = 'Y'`, `SRVC_CD = 36`.

### Payments (1 tab)

| Tab | Mnemonic | Metric | Source Table |
|-----|----------|--------|--------------|
| IRI_Success | IRI | IMT Transaction | DDWV01.EXT_CDS_CHNL_EVNT |

**Key filters:** `ACTVY_TYP_CD = '031'` (international money transfer activity type).

### Loans (1 tab)

| Tab | Mnemonic | Metric | Source Table |
|-----|----------|--------|--------------|
| O2P_Success | O2P | Overdraft Open | DDWV01.CR_APP_PROD + CR_APP_CLNT_RELTN + OVRL_CR_APP + CR_APP_CLNT_PROD_RELTN |

**Key filters:** `APPL_FOR_PROD_TYP IN ('OP','CR','AP')`, `PROD_STS_CD IN (32,37,45,47,51,56,62)`.

This is a 4-table join through the credit application chain. Success = application completed with an approved status code for an overdraft product type.

### Investments (4 tabs)

| Tab | Mnemonic | Metric | Source Table |
|-----|----------|--------|--------------|
| RAT_Success | RAT | RESP Open | DG6V01.ARNGMNT_OWN_HIST + ARNGMNT_HIST |
| IDE_Success | IDE | Direct Investing Open | dl_mr_prod.NBO_IDE_Acquisition |
| GIS_Success | GIS | GIC Open | dl_mr_prod.NBO_GIC_Acquisition |
| TAO_Success | TAO | Registered Acct Open | dl_mr_prod.NBO_TAO_Acquisition |

**RAT key filters:** `INVSTMT_PLN_TYPE IN (8)` (RESP), `OP_CLS_STS = 'O'` (Open status). Uses `MTH_END_DT` alignment between owner and arrangement history tables.

**IDE key filters:** `Success = 1`. Success date = `COALESCE(DI_DT_OPEN, IE_DT_OPEN)` (either Direct Investing or InvestEase open date).

**GIS key filters:** `Success = 1`. Success date = `dt_open`.

**TAO key filters:** `PLN_AR_ID IS NOT NULL`. For campaign view: `Control = 'Action'`. Success date = `dt_open`.

---

## Three Types of Data Sources

### Type 1: Raw EDW Tables

Used by: VCN, VDA, VDT, VUI, VUT, VAW, IRI, O2P

These query raw operational tables in EDW (Teradata). The SQL joins source tables directly and applies business rule filters (status codes, product types, etc.) to identify success events.

**Campaign join pattern:** `INNER JOIN DG6V01.TACTIC_EVNT_IP_AR_HIST` on `CLNT_NO` with `SUBSTR(TACTIC_ID, 8, 3)` filter and treatment date window.

### Type 2: Pre-Built Success Tables

Used by: IDE, GIS, TAO

These use pre-built NBO (Next Best Offer) tables in `dl_mr_prod` that already contain success flags. The SQL is simpler because the success logic is pre-computed.

- **Organic:** Filter by `Success = 1`
- **Campaign:** Filter by `Control = 'Action' AND Success = 1`

These tables already include campaign treatment dates (`Treatmt_strt_dt`) so the campaign join is embedded.

### Type 3: DG6V01 Arrangement History

Used by: RAT

These query the arrangement ownership and history tables in `DG6V01`. The key join uses `MTH_END_DT` alignment to match the arrangement snapshot to the treatment end date month.

**Campaign join pattern:** Uses `ADD_MONTHS` calculation to align `OWN.MTH_END_DT` to the month-end of the treatment end date.

---

## How to Run These Queries

1. Open `success_queries.xlsx`
2. Go to the tab for your campaign (e.g., `IRI_Success`)
3. Copy the SQL query from the green or blue section
4. Paste into SAS Enterprise Guide or SAS Studio
5. Run the query - it will connect to Teradata via the `CONNECT TO TERADATA` pass-through

**Notes:**
- Sample queries use `SELECT TOP 10` to limit results
- Summary queries group by `yr, mo` for trend validation
- All queries use `PROC SQL` with Teradata pass-through syntax
- Snap date queries (`SNAP_DT`) use a 7-day lookback window for the latest available snapshot

---

## Related Files

| File | Purpose |
|------|---------|
| `metadata/metric_code_registry.csv` | Master registry of all 46+ campaigns with status tracking |
| `metadata/vvd_success_events.csv` | Sample success event data for development/testing |
| `metadata/generate_vvd_success_queries.py` | Python script that generates the Excel workbook |
| `sas_search/scripts/quick_search.ps1` | PowerShell scanner for finding SAS code by mnemonic |
| `docs/14_VVD_DATA_DICTIONARY.md` | Data dictionary for VVD source tables |
| `docs/15_VVD_SUCCESS_EVENTS_SCHEMA.md` | Schema definition for standardized success events |

---

## Status Summary

**Completed (active, ready for engineering):** VCN, VDA, VDT, VUI, VUT, VAW, IRI, O2P, RAT, IDE, GIS, TAO, GNE (13 campaigns)

**Pending SAS search:** PCQ, VBA, VBA_LTA, FTH, PCL, PCD, VBU, COB, CRV, MOM, MRF, BOL, LTA, RCL, RCU, RIS, ESV, PPQ, CTU, PFS, PRA, DAR, RPB, TFP, RMG, NMI, IPC, EBR, PVE, TAO, GNE, MOS (remaining campaigns)

**Missing definition:** MFY, MMT, RCR, COR, ZRR, VSX (need success metric defined first)

**MOS note:** Registry says "Long-Term Net Sales" but SAS code shows GIC/MF account opened. Needs clarification before proceeding.
