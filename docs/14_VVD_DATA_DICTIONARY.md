# VVD Data Dictionary & Schema Reference

<!-- Owner: Marketing Analytics | Version: v1.0 | Last Updated: 2026-02-03 -->
<!-- Source: VVD Vintage Engine v2.7 + Table Data Assets whiteboard (2026-01-31) -->

---

## Purpose

This document maps the VVD (Virtual Visa Debit) vintage engine's success logic to the Success Library Table Data Assets framework. It serves as the formal data dictionary for all VVD data assets — source tables, success metrics, campaign mappings, and output schemas — providing the team a single reference to understand how VVD success is detected, calculated, and reported.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Campaign-to-Metric Mapping](#2-campaign-to-metric-mapping)
3. [Source Data Assets](#3-source-data-assets)
4. [Success Metric Definitions](#4-success-metric-definitions)
5. [Experiment & Population Schema](#5-experiment--population-schema)
6. [Output Schemas](#6-output-schemas)
7. [Entity Relationship Map](#7-entity-relationship-map)
8. [Business Rules Reference](#8-business-rules-reference)
9. [Open Questions](#9-open-questions)

---

## 1. Architecture Overview

The VVD vintage engine implements the SuperFact four-layer architecture in code:

```
┌─────────────────────────────────────────────────────────────────────┐
│  LAYER 1: EXPERIMENT METADATA                                       │
│  Source: DG6V01.TACTIC_EVNT_IP_AR_HIST (EDW)                       │
│  Question: "Who is in the test?"                                    │
│  Output: Client-level experiment assignments with group & cohort    │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 2: CAMPAIGN MAPPING                                          │
│  Source: CAMPAIGN_METADATA (hardcoded in engine)                    │
│  Question: "What do we measure?"                                    │
│  Output: Mnemonic → primary/secondary metric mapping                │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 3: SUCCESS DEFINITIONS (Logic Repo)                          │
│  Source: SUCCESS_DEFINITIONS (hardcoded in engine)                  │
│  Question: "How do we calculate success?"                           │
│  Output: CLNT_NO + SUCCESS_DT per metric                           │
├─────────────────────────────────────────────────────────────────────┤
│  LAYER 4: CLIENT JOURNEY                                            │
│  Source: VENDOR_FEEDBACK_MASTER/EVENT (EDW)                         │
│  Question: "What did clients do?"                                   │
│  Output: Engagement flags (sent, opened, clicked, unsubscribed)     │
├─────────────────────────────────────────────────────────────────────┤
│  ANALYSIS LAYER: VINTAGE ENGINE                                     │
│  Joins: Layer 1 + Layer 3 + Layer 4                                 │
│  Processing: Cumulative success rate by day                         │
│  Output: Vintage curves + channel breakdown                         │
└─────────────────────────────────────────────────────────────────────┘
```

**Current state:** All mappings and definitions are hardcoded in the vintage engine Python code. This document extracts and formalizes them for the transition to the governed Success Library.

---

## 2. Campaign-to-Metric Mapping

### C. campaign_mapping (VVD)

Maps each VVD mnemonic to its success metrics. This is the VVD-specific implementation of the whiteboard's **Table C**.

| mnemonic | campaign_name | success_type | 1st_success (primary) | 2nd_success (secondary) | metric_code_primary | metric_code_secondary |
|----------|--------------|--------------|----------------------|------------------------|--------------------|-----------------------|
| **VCN** | VVD Contextual Notification | ACQUISITION | card_acquisition | -- | VVD_ACQ_001 | -- |
| **VDA** | VVD Black Friday Cyber Monday Targeted | ACQUISITION | card_acquisition | -- | VVD_ACQ_001 | -- |
| **VDT** | VVD Activation Trigger | ACTIVATION | card_activation | -- | VVD_ACT_001 | -- |
| **VUI** | VVD Usage Trigger | USAGE | card_usage | wallet_provisioning | VVD_USG_001 | VVD_PRV_001 |
| **VUT** | VVD Tokenization Usage Campaign | TOKENIZATION | wallet_provisioning | card_usage | VVD_PRV_001 | VVD_USG_001 |
| **VAW** | VVD Add To Wallet Contextual Notification | TOKENIZATION | wallet_provisioning | card_usage | VVD_PRV_001 | VVD_USG_001 |

### Metric Reuse Matrix

Shows which metrics are shared across campaigns:

| Metric | VCN | VDA | VDT | VUI | VUT | VAW |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|
| card_acquisition (VVD_ACQ_001) | P | P | | | | |
| card_activation (VVD_ACT_001) | | | P | | | |
| card_usage (VVD_USG_001) | | | | P | S | S |
| wallet_provisioning (VVD_PRV_001) | | | | S | P | P |

*P = Primary, S = Secondary*

---

## 3. Source Data Assets

### 3.1 Experiment Sources

#### DG6V01.TACTIC_EVNT_IP_AR_HIST — Experiment Population

| Attribute | Value |
|-----------|-------|
| **Purpose** | Identifies which clients are in each experiment |
| **Layer** | 1 (Experiment Metadata) |
| **Source System** | EDW (Teradata) |
| **Schema** | DG6V01 |
| **Grain** | One row per client per tactic event |

| Column | Type | Description | Used As |
|--------|------|-------------|---------|
| `TACTIC_ID` | string | Full tactic identifier (mnemonic at pos 8-10) | Campaign identifier |
| `TACTIC_EVNT_ID` | string | Client identifier (requires trim + leading zero strip) | Derives `CLNT_NO` |
| `TREATMT_STRT_DT` | date | Treatment start date | Success window start |
| `TREATMT_END_DT` | date | Treatment end date | Success window end |
| `TST_GRP_CD` | string | Test group code (TG4 = test) | Action/Control split |
| `RPT_GRP_CD` | string | Report group code | Cell-level detail |
| `TACTIC_CELL_CD` | string | Tactic cell code (contains channel info) | Channel identification |
| `EVNT_STRT_DT` | date | Event start date | Partition key |

**Derived columns:**

| Derived Column | Transformation | Description |
|----------------|---------------|-------------|
| `CLNT_NO` | `regexp_replace(trim(TACTIC_EVNT_ID), '^0+', '')` | Client number |
| `MNE` | `substring(TACTIC_ID, 8, 3)` | Campaign mnemonic |
| `COHORT` | `date_format(TREATMT_STRT_DT, 'yyyy-MM')` | Monthly cohort |
| `WINDOW_DAYS` | `datediff(TREATMT_END_DT, TREATMT_STRT_DT)` | Treatment window length |
| `CHANNEL` | Extracted from `TACTIC_CELL_CD` | Channel (email = "EM") |

---

#### DDWV01.VISA_DR_CRD_DLY — Visa Debit Card Data

| Attribute | Value |
|-----------|-------|
| **Purpose** | Card issuance, activation, and usage events |
| **Layer** | 3 (Success Definitions) |
| **Source System** | EDW (Teradata) |
| **Schema** | DDWV01 |
| **Grain** | One row per card per snapshot |
| **Metric ID** | VVD_ACQ_001 (Card Acquisition), VVD_ACT_001 (Card Activation), VVD_USG_001 (Card Usage) |

| Column | Type | Description | Used As |
|--------|------|-------------|---------|
| `CLNT_NO` | string | Client number | Join key |
| `ISS_DT` | date | Card issue date | SUCCESS_DT for VVD_ACQ_001 |
| `ACTV_DT` | date | Card activation date | SUCCESS_DT for VVD_ACT_001 |
| `STS_CD` | string | Card status code | Filter: '06' (Active), '08' (Approved) |
| `SRVC_ID` | int | Service identifier | Filter: 36 (Visa Direct / VVD) |
| `SNAP_DT` | date | Snapshot date | Filter: MAX(SNAP_DT) within 7 days |

---

### 3.2 EDW Sources (Teradata)

#### DDWV05.CLNT_CRD_POS_LOG — Card POS Log

| Attribute | Value |
|-----------|-------|
| **Purpose** | Wallet provisioning events (zero-amount token transactions) |
| **Layer** | 3 (Success Definitions) |
| **Source System** | EDW (Teradata) |
| **Schema** | DDWV05 |
| **Grain** | One row per POS transaction |
| **Metric ID** | VVD_PRV_001 (Wallet Provisioning) |

| Column | Type | Description | Used As |
|--------|------|-------------|---------|
| `CLNT_CRD_NO` | string | Client card number | Derives `CLNT_NO`; filter prefix '45190' |
| `VISA_DR_CRD_NO` | string | Visa debit card number | Filter prefix '45199' |
| `TOKN_REQSTR_ID` | string | Token requestor ID | Join to TOKEN_LIST; filter first char > '0' |
| `TXN_DT` | date | Transaction date | SUCCESS_DT |
| `AMT1` | decimal | Transaction amount | Filter: = 0 (provisioning event) |
| `POS_ENTR_MODE_CD_NON_EMV` | string | POS entry mode | Filter: '000' (token provisioning) |
| `SRVC_CD` | int | Service code | Filter: 36 (Visa Direct) |

---

#### DL_DECMAN.TOKEN_LIST — Token Registry

| Attribute | Value |
|-----------|-------|
| **Purpose** | Token/wallet provisioning registry |
| **Layer** | 3 (Success Definitions) |
| **Source System** | EDW (Teradata) |
| **Schema** | DL_DECMAN |
| **Grain** | One row per token |
| **Metric ID** | VVD_PRV_001 (Wallet Provisioning) — joined to CLNT_CRD_POS_LOG |

| Column | Type | Description | Used As |
|--------|------|-------------|---------|
| `TOKEN_ID` | string | Token identifier | Join key to TOKN_REQSTR_ID |
| `TOKEN_WALLET_IND` | string | Wallet provisioning indicator | Filter: 'Y' |

---

#### DTZV01.VENDOR_FEEDBACK_MASTER / VENDOR_FEEDBACK_EVENT — Email Engagement

| Attribute | Value |
|-----------|-------|
| **Purpose** | Email engagement tracking (sent, opened, clicked, unsubscribed) |
| **Layer** | 4 (Client Journey) |
| **Source System** | EDW (Teradata) |
| **Schema** | DTZV01 |
| **Grain** | One row per client per disposition event |
| **Metric ID** | N/A — engagement layer, not a success metric |

| Column | Type | Description | Used As |
|--------|------|-------------|---------|
| `CLNT_NO` | string | Client number | Join key |
| `TREATMENT_ID` | string | Treatment/tactic identifier | Campaign association |
| `disposition_cd` | int | Disposition type code | See disposition codes below |
| `disposition_dt_tm` | datetime | Event timestamp | Engagement date |

**Disposition codes:**

| Code | Meaning | Derived Flag | Derived Date Field |
|------|---------|-------------|-------------------|
| 1 | Sent | `EMAIL_SENT` | `EMAIL_SENT_DT` |
| 2 | Opened | `EMAIL_OPENED` | `EMAIL_OPENED_DT` |
| 3 | Clicked | `EMAIL_CLICKED` | `EMAIL_CLICKED_DT` |
| 4 | Unsubscribed | `EMAIL_UNSUBSCRIBED` | `EMAIL_UNSUBSCRIBED_DT` |

---

## 4. Success Metric Definitions

Each metric follows a standard contract: given a date range, return `CLNT_NO` + `SUCCESS_DT` for all clients who met the success criteria.

### VVD_ACQ_001 — Card Acquisition

| Attribute | Value |
|-----------|-------|
| **Metric ID** | VVD_ACQ_001 |
| **Metric Name** | Card Acquisition |
| **Pillar** | Conversion |
| **Business Definition** | Client acquired a new VVD card (issued in active/approved status) |
| **Success Date** | `ISS_DT` (card issue date) |
| **Source** | EDW — `DDWV01.VISA_DR_CRD_DLY` |
| **Grain** | Client (first issue date per client) |
| **Campaigns** | VCN (primary), VDA (primary) |

**Filters:**

| Field | Operator | Value | Reason |
|-------|----------|-------|--------|
| `STS_CD` | IN | ('06', '08') | Card must be Active or Approved |
| `SRVC_ID` | = | 36 | Visa Direct / VVD product only |
| `ISS_DT` | IS NOT NULL | -- | Card must have been issued |

**Output contract:** `CLNT_NO (string), SUCCESS_DT (date)`

---

### VVD_ACT_001 — Card Activation

| Attribute | Value |
|-----------|-------|
| **Metric ID** | VVD_ACT_001 |
| **Metric Name** | Card Activation |
| **Pillar** | Conversion |
| **Business Definition** | Client activated their VVD card (first use after issuance) |
| **Success Date** | `ACTV_DT` (card activation date) |
| **Source** | EDW — `DDWV01.VISA_DR_CRD_DLY` |
| **Grain** | Client (first activation date per client) |
| **Campaigns** | VDT (primary) |

**Filters:**

| Field | Operator | Value | Reason |
|-------|----------|-------|--------|
| `STS_CD` | IN | ('06', '08') | Card must be Active or Approved |
| `SRVC_ID` | = | 36 | Visa Direct / VVD product only |
| `ISS_DT` | IS NOT NULL | -- | Card must have been issued first |

**Note:** Same source table and filters as VVD_ACQ_001 but uses `ACTV_DT` instead of `ISS_DT`. Activation is a downstream event from acquisition.

**Output contract:** `CLNT_NO (string), SUCCESS_DT (date)`

---

### VVD_USG_001 — Card Usage

| Attribute | Value |
|-----------|-------|
| **Metric ID** | VVD_USG_001 |
| **Metric Name** | Card Usage |
| **Pillar** | Engagement |
| **Business Definition** | Client used their VVD card for a point-of-sale transaction |
| **Success Date** | `TXN_DT` (transaction date) |
| **Source** | EDW — `DDWV01.VISA_DR_CRD_DLY` |
| **Grain** | Client (first transaction date per client) |
| **Campaigns** | VUI (primary), VUT (secondary), VAW (secondary) |

**Filters:**

| Field | Operator | Value | Reason |
|-------|----------|-------|--------|
| `SRVC_CD` | = | 36 | Visa Direct / VVD product only |
| `AMT1` | > | 0 | Must be a real transaction, not zero-amount |
| `TXN_TP` + `MSG_TP` | IN | See below | Valid purchase transaction types |

**Valid transaction types:**

| TXN_TP | MSG_TP | Description |
|--------|--------|-------------|
| 10 | 0210 | Standard purchase |
| 13 | 0210 | E-commerce purchase |
| 12 | 0220 | Recurring / subscription |

**Client extraction:** `CLNT_NO = regexp_replace(SUBSTR(CLNT_CRD_NO, 7, 9), '^0+', '')`

**Output contract:** `CLNT_NO (string), SUCCESS_DT (date)`

---

### VVD_PRV_001 — Wallet Provisioning

| Attribute | Value |
|-----------|-------|
| **Metric ID** | VVD_PRV_001 |
| **Metric Name** | Wallet Provisioning |
| **Pillar** | Conversion |
| **Business Definition** | Client provisioned their VVD card to a digital wallet (Apple Pay, Google Pay, Samsung Pay, etc.) |
| **Success Date** | `TXN_DT` (provisioning transaction date) |
| **Source** | EDW — `DDWV05.CLNT_CRD_POS_LOG` JOIN `DL_DECMAN.TOKEN_LIST` |
| **Grain** | Client (first provisioning date per client) |
| **Campaigns** | VUT (primary), VAW (primary), VUI (secondary) |

**Filters:**

| Field | Operator | Value | Reason |
|-------|----------|-------|--------|
| `AMT1` | = | 0 | Provisioning events are zero-amount |
| `SUBSTR(CLNT_CRD_NO, 1, 5)` | = | '45190' | VVD card BIN prefix |
| `SUBSTR(VISA_DR_CRD_NO, 1, 5)` | = | '45199' | VVD debit card BIN verification |
| `SUBSTR(TOKN_REQSTR_ID, 1, 1)` | > | '0' | Valid token requestor |
| `POS_ENTR_MODE_CD_NON_EMV` | = | '000' | Token provisioning POS mode |
| `SRVC_CD` | = | 36 | Visa Direct / VVD product only |
| `TOKEN_WALLET_IND` | = | 'Y' | Confirmed wallet provisioning |

**Join:** `CLNT_CRD_POS_LOG.TOKN_REQSTR_ID = TOKEN_LIST.TOKEN_ID`

**Client extraction:** `CLNT_NO = CAST(SUBSTR(CLNT_CRD_NO, 7, 9) AS INTEGER)`

**Join note:** Token registry (`DL_DECMAN.TOKEN_LIST`) is joined to confirm wallet provisioning via `TOKEN_WALLET_IND`.

**Output contract:** `CLNT_NO (string), SUCCESS_DT (date)`

---

## 5. Experiment & Population Schema

### A. experiment_mapping (VVD)

Populated from `DTZTA_T_TACTIC_EVNT_HIST` with mnemonic filter.

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `experiment_id` | string | Derived | `{MNE}_{COHORT}` (e.g., `VCN_2025-06`) |
| `mnemonic` | string | `SUBSTRING(TACTIC_ID, 8, 3)` | Campaign mnemonic (VCN, VDA, VDT, VUI, VUT, VAW) |
| `test_type` | string | -- | Not currently captured in vintage engine |
| `hypothesis` | string | -- | Not currently captured in vintage engine |
| `lift_type` | string | -- | Not currently captured in vintage engine |
| `measurement` | string | Implicit | Test vs. no contact (TG4 vs others) |
| `sub_type` | string | -- | Not currently captured in vintage engine |

**Gap:** The vintage engine does not store experiment design metadata (hypothesis, test_type, lift_type). These fields exist in the whiteboard schema but are not populated by the engine. They would need to come from tech specs or an intake form.

---

### B. experiment_population (VVD)

One row per client per experiment assignment.

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `experiment_id` | string | Derived | Links to experiment_mapping |
| `clnt_no` | string | `regexp_replace(trim(TACTIC_EVNT_ID), '^0+', '')` | Client number |
| `tactic_id` | string | `TACTIC_ID` | Full tactic identifier |
| `start_dt` | date | `TREATMT_STRT_DT` | Treatment start date |
| `end_dt` | date | `TREATMT_END_DT` | Treatment end date |
| `group` | string | `TST_GRP_CD` | Test group (TG4 = Action, others = Control) |
| `rpt_grp_cd` | string | `RPT_GRP_CD` | Report group / cell detail |
| `cohort` | string | `date_format(TREATMT_STRT_DT, 'yyyy-MM')` | Monthly cohort |
| `window_days` | int | `datediff(TREATMT_END_DT, TREATMT_STRT_DT)` | Treatment window in days |
| `channel` | string | Extracted from `TACTIC_CELL_CD` | Channel (e.g., email = "EM") |

---

## 6. Output Schemas

### 6.1 Vintage Curves (Primary Output)

The main output of the vintage engine. One row per mnemonic/cohort/group/metric/day combination.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `MNE` | string | Campaign mnemonic | `VCN` |
| `COHORT` | string | Treatment month (yyyy-MM) | `2025-06` |
| `TST_GRP_CD` | string | Test group code | `TG4` |
| `RPT_GRP_CD` | string | Report group code | `RPT01` |
| `METRIC` | string | Metric type | `PRIMARY`, `SECONDARY`, `EMAIL_SENT`, `EMAIL_OPEN`, `EMAIL_CLICK`, `EMAIL_UNSUB` |
| `DAY` | int | Days since treatment start | `0, 1, 2, ..., 90` |
| `WINDOW_DAYS` | int | Total treatment window (median) | `90` |
| `CLIENT_CNT` | int | Total clients in this cell | `15000` |
| `SUCCESS_CNT` | int | Cumulative successes by this day | `450` |
| `RATE` | decimal(8,4) | Success rate percentage | `3.0000` |

**Metric types explained:**

| METRIC value | Source | Denominator | Numerator |
|-------------|--------|-------------|-----------|
| `PRIMARY` | Campaign's 1st_success metric | All clients in cell | Clients with success event |
| `SECONDARY` | Campaign's 2nd_success metric | All clients in cell | Clients with success event |
| `EMAIL_SENT` | Engagement data | All clients targeted with email | Clients who received email |
| `EMAIL_OPEN` | Engagement data | Clients who received email | Clients who opened |
| `EMAIL_CLICK` | Engagement data | Clients who received email | Clients who clicked |
| `EMAIL_UNSUB` | Engagement data | Clients who received email | Clients who unsubscribed |

---

### 6.2 Channel Breakdown

One row per mnemonic/cohort/group/channel combination.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `MNE` | string | Campaign mnemonic | `VCN` |
| `COHORT` | string | Treatment month | `2025-06` |
| `TST_GRP_CD` | string | Test group code | `TG4` |
| `RPT_GRP_CD` | string | Report group code | `RPT01` |
| `CHANNEL` | string | Channel from TACTIC_CELL_CD | `EM` |
| `CLIENT_CNT` | int | Clients in channel | `8000` |
| `SUCCESS_CNT` | int | Successes in channel | `240` |
| `RATE` | decimal(6,2) | Success rate percentage | `3.00` |

---

### 6.3 Client-Level Success (Intermediate)

Intermediate dataset created during processing. One row per client per metric.

| Column | Type | Description |
|--------|------|-------------|
| `CLNT_NO` | string | Client number |
| `MNE` | string | Campaign mnemonic |
| `COHORT` | string | Treatment month |
| `TST_GRP_CD` | string | Test group code |
| `RPT_GRP_CD` | string | Report group code |
| `WINDOW_DAYS` | int | Treatment window |
| `SUCCESS_FLAG` | int | 1 if success occurred, 0 otherwise |
| `FIRST_SUCCESS_DT` | date | Earliest success date within window |
| `DAYS_TO_FIRST_SUCCESS` | int | Days from treatment start to first success |
| `SUCCESS_COUNT` | int | Number of success events within window |
| `EMAIL_SENT` | int | 1 if email was sent |
| `EMAIL_OPENED` | int | 1 if email was opened |
| `EMAIL_CLICKED` | int | 1 if email was clicked |
| `EMAIL_UNSUBSCRIBED` | int | 1 if client unsubscribed |

---

## 7. Entity Relationship Map

```
                    ┌───────────────────────────────────────────────┐
                    │        CAMPAIGN_METADATA (Layer 2)            │
                    │  VCN → card_acquisition (P)                   │
                    │  VDA → card_acquisition (P)                   │
                    │  VDT → card_activation (P)                    │
                    │  VUI → card_usage (P), wallet_provisioning (S)│
                    │  VUT → wallet_provisioning (P), card_usage (S)│
                    │  VAW → wallet_provisioning (P), card_usage (S)│
                    └───────────────────┬───────────────────────────┘
                                        │ selects metric
                                        ▼
┌──────────────────────┐     ┌──────────────────────────────────────┐
│  TACTIC_EVNT_IP_AR   │     │  SUCCESS_DEFINITIONS (Layer 3)       │
│  _HIST (Layer 1-EDW) │     │                                      │
│                      │     │  VVD_ACQ_001 ← VISA_DR_CRD_DLY      │
│  CLNT_NO             │     │  VVD_ACT_001 ← VISA_DR_CRD_DLY      │
│  TACTIC_ID           │     │  VVD_USG_001 ← VISA_DR_CRD_DLY      │
│  TREATMT_STRT_DT     │     │  VVD_PRV_001 ← CLNT_CRD_POS_LOG     │
│  TREATMT_END_DT      │     │                + TOKEN_LIST           │
│  TST_GRP_CD          │     │                                      │
│  RPT_GRP_CD          │     │  Output: CLNT_NO + SUCCESS_DT        │
└──────────┬───────────┘     └──────────────────┬───────────────────┘
           │                                     │
           │          ┌──────────────────┐       │
           │          │  JOIN CONDITION   │       │
           └─────────▶│  ON CLNT_NO      │◀──────┘
                      │  WHERE SUCCESS_DT │
                      │  BETWEEN          │
                      │  TREATMT_STRT_DT  │
                      │  AND              │
                      │  TREATMT_END_DT   │
                      └────────┬──────────┘
                               │
                               ▼
                    ┌──────────────────────────┐
                    │  CLIENT-LEVEL SUCCESS     │
                    │  (Intermediate Dataset)   │
                    │                           │
                    │  CLNT_NO, MNE, COHORT,    │
                    │  TST_GRP_CD, RPT_GRP_CD,  │
                    │  SUCCESS_FLAG,             │
                    │  FIRST_SUCCESS_DT,         │
                    │  DAYS_TO_FIRST_SUCCESS     │
                    └────────┬──────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
   ┌──────────────┐  ┌─────────────┐  ┌──────────────┐
   │  VINTAGE     │  │  CHANNEL    │  │  ENGAGEMENT  │
   │  CURVES      │  │  BREAKDOWN  │  │  CURVES      │
   │              │  │             │  │              │
   │  DAY-level   │  │  Per-channel│  │  EMAIL_SENT  │
   │  cumulative  │  │  aggregation│  │  EMAIL_OPEN  │
   │  rates       │  │             │  │  EMAIL_CLICK │
   └──────────────┘  └─────────────┘  │  EMAIL_UNSUB │
                                      └──────────────┘
```

---

## 8. Business Rules Reference

### 8.1 Global Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `YEARS_TO_INCLUDE` | [2025, 2026] | Data years included in queries |
| `AGGREGATION_LEVEL` | MONTH | Cohorts are monthly (yyyy-MM) |
| `TEST_GROUP_CODE` | TG4 | TG4 = test/action group; all others = control |
| `VVD_SERVICE_CODE` | 36 | Visa Direct / VVD product identifier |
| `CARD_BIN_PREFIX` | 45190 | VVD client card BIN |
| `DEBIT_BIN_PREFIX` | 45199 | VVD Visa debit card BIN |

### 8.2 Success Window Rule

All success metrics follow the same temporal window rule:

```
SUCCESS is counted IF AND ONLY IF:
  SUCCESS_DT >= TREATMT_STRT_DT
  AND SUCCESS_DT <= TREATMT_END_DT
```

First success date per client is used for vintage curve day calculation:
```
DAYS_TO_FIRST_SUCCESS = datediff(FIRST_SUCCESS_DT, TREATMT_STRT_DT)
```

### 8.3 Client Number Extraction Rules

| Source Table | Extraction Method |
|-------------|-------------------|
| DG6V01.TACTIC_EVNT_IP_AR_HIST | `regexp_replace(trim(TACTIC_EVNT_ID), '^0+', '')` |
| DDWV01.VISA_DR_CRD_DLY | Direct `CLNT_NO` column |
| DDWV05.CLNT_CRD_POS_LOG | `CAST(SUBSTR(CLNT_CRD_NO, 7, 9) AS INTEGER)` |

### 8.4 Engagement Denominator Rules

| Metric | Denominator | Numerator |
|--------|-------------|-----------|
| EMAIL_SENT | All clients targeted with email channel | Clients with disposition_cd = 1 |
| EMAIL_OPEN | Clients with EMAIL_SENT = 1 | Clients with disposition_cd = 2 |
| EMAIL_CLICK | Clients with EMAIL_SENT = 1 | Clients with disposition_cd = 3 |
| EMAIL_UNSUB | Clients with EMAIL_SENT = 1 | Clients with disposition_cd = 4 |

---

## 9. Open Questions

### From Whiteboard (Applicable to VVD)

| # | Question | Status | Impact |
|---|----------|--------|--------|
| 1 | Should `1st_success`, `2nd_success` in tactic_history be dates or flags? | Open | Affects how View 3 and View 4 aggregate |
| 2 | How does the VVD vintage output map to the `tactic_history` table schema? | Open | Vintage curves are day-level; tactic_history is client-level |

### From Vintage Engine Implementation

| # | Question | Status | Impact |
|---|----------|--------|--------|
| 3 | Experiment metadata (hypothesis, test_type, lift_type) is not in the vintage engine. Where does it come from? | Open | Layer 1 schema is incomplete without it |
| 4 | The engine hardcodes `TST_GRP_CD = TG4` as test. Is this universal across all VVD campaigns? | Open | Affects Action/Control classification |
| 5 | VVD_USG_001 transaction types: TXN_TP=13 is labeled "E-commerce" and TXN_TP=12 is "Recurring" in the code — are these confirmed correct? | Open | Affects what counts as "usage" |
| 6 | Wallet provisioning uses `AMT1 = 0` to identify provisioning events. Are there edge cases where real zero-amount transactions exist? | Open | Could create false positives |
| 7 | The engine currently produces CSV output. What is the target persistence layer (Hive table, Teradata, S3)? | Open | Affects the delivery/output schema |

### Gaps Between Vintage Engine and Target Architecture

| # | Gap | Current State | Target State |
|---|-----|---------------|--------------|
| 1 | Campaign mapping | Hardcoded Python dict | `campaign_mapping` table (Table C) |
| 2 | Success definitions | Hardcoded Python dict | GitHub Logic Repo (Layer 3) |
| 3 | Experiment metadata | Not captured | `experiment_mapping` table (Table A) |
| 4 | Cross-sell view | Not implemented | `cross_sell` crosstab pivot (Table 5) |
| 5 | Share of Wallet | Not implemented | SOW Programs + SOW Usage tables |
| 6 | Channel Interactions | Partial (email only) | Full channel tracking table |
| 7 | Daily automated refresh | Manual notebook execution | Scheduled pipeline |

---

*Document created: 2026-02-03*
*Source: VVD Vintage Engine v2.7 + Table Data Assets whiteboard session (2026-01-31)*
*Author: Marketing Analytics Team*
