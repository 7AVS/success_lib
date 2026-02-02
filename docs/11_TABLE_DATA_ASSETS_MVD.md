# Table Data Assets - Minimum Viable Document

This document captures the data asset table designs from the whiteboard session (2026-01-31). These schemas define the core data model underpinning the SuperFact four-layer architecture.

> **Source:** Whiteboard photos in `agent_sessions/pic/PXL_20260131_*`

---

## Overview

The data model consists of **five core tables**, **two Share of Wallet tables**, **one mapping reference**, **two reporting views**, and a **crosstab pivot** output. The tables are numbered and lettered to show their relationships.

```
┌─────────────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│  A. experiment      │     │  B. experiment       │     │  C. campaign        │
│     _mapping        │────▶│     _population      │────▶│     _mapping        │
│                     │     │                      │     │                     │
│  "What is the       │     │  "Who is in the      │     │  "What counts as    │
│   experiment?"      │     │   experiment?"       │     │   success?"         │
└─────────────────────┘     └──────────────────────┘     └─────────────────────┘
                                                                  │
                                     ┌────────────────────────────┘
                                     ▼
                  ┌──────────────────────────────────────┐
                  │  GitHub Repo for Logic (Layer 2)     │
                  │  → first production deployment       │
                  │  → pre-defined mnemonic successes    │
                  └──────────────────────────────────────┘
```

---

## A. experiment_mapping

Defines the experiment design: what is being tested, the hypothesis, and the statistical approach.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `data_asset` | string | Table identifier | `experiment_mapping` |
| `experiment_id` | string | Unique experiment identifier | `fth_exp_123` |
| `mnemonic` | string | Campaign mnemonic code | `FTH` |
| `test_type` | string | Experimental design type | `RCT` |
| `hypothesis` | string | What the experiment aims to prove | `higher response with expanded population` |
| `lift_type` | string | Type of causal inference method | `causal inference` |
| `measurement` | string | What is being measured | `test vs. no contact` |
| `sub_type` | string | Statistical method | `frequentist OR bayesian` |

**Sample Row:**

| data_asset | experiment_id | mnemonic | test_type | hypothesis | lift_type | measurement | sub_type |
|------------|---------------|----------|-----------|------------|-----------|-------------|----------|
| experiment_mapping | fth_exp_123 | FTH | RCT | higher response with expanded population | causal inference | test vs. no contact | frequentist OR bayesian |

---

## B. experiment_population

Links individual clients to experiments with their group assignment and segmentation.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `data_asset` | string | Table identifier | `experiment_population` |
| `experiment_id` | string | FK to experiment_mapping | `fth_exp_123` |
| `clnt_no` | string | Client number | `123456789` |
| `tactic_id` | string | Tactic identifier | `20242XXFTH` |
| `start_dt` | date | Experiment start date | `2024-08-25` |
| `group` | string | Test group assignment | `Action` |
| `pre-defined segmentation` | string | Client segment classification | *(pre-defined)* |

**Sample Row:**

| data_asset | experiment_id | clnt_no | tactic_id | start_dt | group | segmentation |
|------------|---------------|---------|-----------|----------|-------|--------------|
| experiment_population | fth_exp_123 | 123456789 | 20242XXFTH | 2024-08-25 | Action | pre-defined |

---

## C. campaign_mapping

Maps each mnemonic to its ordered success definitions. This drives the GitHub Logic Repo (Layer 2).

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `data_asset` | string | Table identifier | `campaign_mapping` |
| `mnemonic` | string | Campaign mnemonic code | `FTH` |
| `1st_success` | string | Primary success metric | `Mortgage Open 6 months` |
| `2nd_success` | string | Secondary success metric | `Mortgage Application Start 3 months` |
| `3rd_success` | string | Tertiary success metric | *(empty)* |

**Sample Row:**

| data_asset | mnemonic | 1st_success | 2nd_success | 3rd_success |
|------------|----------|-------------|-------------|-------------|
| campaign_mapping | FTH | Mortgage Open 6 months | Mortgage Application Start 3 months | |

**Notes:**
- Success definitions are **pre-defined per mnemonic** and drive the logic repo
- This table is the target for the **first production deployment**
- Logic for each success metric lives in the **GitHub Repo for Logic (Layer 2)**

---

## 1. success_event_mapping

Small reference table that links tactic IDs to event type codes and success levels.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `tactic_id` | string | FK to tactic_history / experiment_population | `20243XXPCL` |
| `event_type_cd` | int | Event type code (FK to success_events) | `1` |
| `success_level` | int | Ordinal success level (1st, 2nd, 3rd) | `1` |

**Sample Rows:**

| tactic_id | event_type_cd | success_level |
|-----------|---------------|---------------|
| 20243XXPCL | 1 | |
| 20243XXPCL | 2 | 2 |

---

## 2. tactic_history

Tracks deployed campaigns per client with their success outcomes. Updated daily for automated results.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `data_asset` | string | Table identifier | `success @ client` |
| `mnemonic` | string | Campaign mnemonic code | `PCL` |
| `tactic_id` | string | Tactic identifier | `20243XXPCL` |
| `clnt_no` | string | Client number | `123456789` |
| `start_dt` | date | Campaign start date | `2024-10-01` |
| `end_dt` | date | Campaign end date | `2024-12-01` |
| `1st_success` | date/flag | First success outcome | |
| `2nd_success` | date/flag | Second success outcome | |
| `3rd_success` | date/flag | Third success outcome | |

**Sample Rows:**

| data_asset | mnemonic | tactic_id | clnt_no | start_dt | end_dt | 1st_success | 2nd_success | 3rd_success |
|------------|----------|-----------|---------|----------|--------|-------------|-------------|-------------|
| success @ client | PCL | 20243XXPCL | *(redacted)* | 2024-10-01 | 2024-12-01 | | | |
| success @ client | FTH | 20242XXFTH | 123456789 | 2024-08-25 | 2025-02-25 | | | |

**Notes & Open Questions:**
- **Updated daily** for automated results
- Feeds into **Crosstab Pivot** for cross-sell analysis
- Kelvin raised: "1st 2nd 3rd success dt???" — need to clarify whether these are dates or flags
- Separating success from scalability: "true # all successes vs. # of campaigns"
- Columns being **JSON-based** (e.g., postal codes)
- **Base fact table** to facilitate views + analytics
- Each product open will be sourced from the **GitHub Repo for Logic**

---

## 1 (green). success_events

Core event-level table tracking individual client product events. This is the granular fact table.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `data_asset` | string | Table identifier / event source | `open_event` |
| `clnt_no` | string | Client number | `123456789` |
| `acct_no` | string | Account number | `12345` |
| `lob` | string | Line of business | `HEF` |
| `prod` | string | Product | `Mortgage` |
| `sub_prod` | string | Sub-product | `5 year fixed` |
| `open_amt` | decimal | Amount at open | `500,000` |
| `event_dt` | date | Event date | `2024-12-25` |
| `event_attributes` | JSON | Flexible attributes | `{"postal_cd": "L9T"}` |
| `event_type_cd` | int | Event type code | `1` |

**Additional proposed column:** `event_category` (e.g., `branch_deposit`)

**Sample Rows:**

| data_asset | clnt_no | acct_no | lob | prod | sub_prod | open_amt | event_dt | event_attributes | event_type_cd |
|------------|---------|---------|-----|------|----------|----------|----------|------------------|---------------|
| open_event | 123456789 | 12345 | HEF | Mortgage | 5 year fixed | 500,000 | 2024-12-25 | `{"postal_cd": "L9T"}` | 1 |
| open_event | 987654321 | 54321 | Investments | GIC | 2-Year Registered | 10,000 | 2024-12-01 | `{"employee_id": 200989}` | 2 |
| open_event | 123412341 | 9999999 | PBA | Chequing | VIP | null | 2025-01-01 | `{"branch_code": 224}` | 3 |
| open_event | 123456789 | 555555 | Credit Card | IAV | Credit Limit Increase | 5,000 | 2024-12-20 | NULL | 4 |
| open_event | 123456789 | 555555 | Credit Card | IOP | Credit Card Upgrade | null | 2024-10-31 | NULL | 5 |

**Notes:**
- Row 3 has `event_category = branch_deposit`
- `event_attributes` is a JSON column for flexible metadata (postal codes, employee IDs, branch codes)

---

## 5. cross_sell (Crosstab Pivot)

Derived from `success_events` via a crosstab/pivot transformation. One row per client showing product-level success flags.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `data_asset` | string | Table identifier | `cross-sell` |
| `clnt_no` | string | Client number | `987654321` |
| `hef` | int | Home Equity success flag | `1` |
| `investments` | int | Investments success flag | `0` |
| `cards` | int | Credit Cards success flag | `0` |
| `pba` | int | Personal Banking success flag | `0` |
| `loans` | int | Loans success flag | `0` |
| `event_dt` | date | Event date | `2024-12-25` |

**Sample Row:**

| data_asset | clnt_no | hef | investments | cards | pba | loans | event_dt |
|------------|---------|-----|-------------|-------|-----|-------|----------|
| cross-sell | 987654321 | 1 | 0 | 0 | 0 | 0 | 2024-12-25 |

**Derivation:**
```
success_events  ──[Crosstab Pivot]──▶  cross_sell
```

---

## Channel Interactions

Tracks client-level channel engagement for campaigns.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `clnt_no` | string | Client number | |
| `tactic_id` | string | Tactic identifier | |
| `email_read` | flag | Email was read | |
| `o&o_status` | flag | Owned & operated channel status | |
| `banner_view` | flag | Banner was viewed | |
| `banner_click` | flag | Banner was clicked | |

**Open Question:** "Need to think about how this joins with responses"

---

## Share of Wallet - PROGRAMS

Tracks client enrollment in banking programs (static/semi-static attributes).

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `clnt_no` | string | Client number | `123456789` |
| `status_type` | string | Program or status name | `Pre-Authorized Contribution` |
| `ind` | Y/N | Active indicator | `Y` |
| `amt (TBD)` | decimal | Derived amount (format TBD) | `500 (derived monthly)` |
| `change_dt` | date | Last change date | `2024-10-31` |

**Key fields (entity):** `clnt_no`, `status_type`, `Y/N`, `change_dt`

**Sample Rows:**

| clnt_no | status_type | ind | amt | change_dt |
|---------|-------------|-----|-----|-----------|
| 123456789 | Pre-Authorized Contribution | Y | 500 (derived monthly) | 2024-10-31 |
| | Vantage Value Program | Y | 3 (tier) | |

---

## Share of Wallet - USAGE

Tracks client transactional behavior across channels (daily/weekly activity).

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `clnt_no` | string | Client number | `123456789` |
| `event_dt` | date | Event/snapshot date | `2025-10-31` |
| `credit_card_txn` | int | Credit card transaction count | `2` |
| `pre-authorized_payment` | int | Pre-authorized payment count | `1` |
| `bill_pay` | int | Bill payment count | |
| `mb_logins` | int | Mobile banking login count | `5` |
| `branch_deposit` | int | Branch deposit count | `1` |

**Key fields (entity):** `clnt_no`, `status_type`, `Y/N`, `change_dt`

**Sample Row:**

| clnt_no | event_dt | credit_card_txn | pre-auth | bill_pay | mb_logins | branch_deposit |
|---------|----------|-----------------|----------|----------|-----------|----------------|
| 123456789 | 2025-10-31 (create row if exists) | 2 | 1 | | 5 | 1 |

**Notes:**
- "Most of this we can take from UCP - this is an alternate format to work for measurement/modelling"
- "Those SOW will require Daily/Weekly refresh; can UCP handle dataset at different frequency?"

---

## View 3: campaign_success @ experiment

Aggregated view showing success counts per experiment, per group. Supports automated high-level reporting.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `data_asset` | string | View identifier | `campaign success @ experiment` |
| `mnemonic` | string | Campaign mnemonic | `FTH` |
| `experiment` | string | Experiment identifier | `fth_exp_123` |
| `start_dt` | date | Experiment start | `2024-08-25` |
| `end_dt` | date | Experiment end | `2024-02-25` |
| `group` | string | Test group (Action/Control) | `Action` |
| `1st_success` | int | Count of 1st success events | `50` |
| `2nd_success` | int | Count of 2nd success events | |
| `3rd_success` | int | Count of 3rd success events | |
| `Leads` | int | Total leads in group | `1000` |

**Sample Rows:**

| data_asset | mnemonic | experiment | start_dt | end_dt | group | 1st_success | 2nd_success | 3rd_success | Leads |
|------------|----------|------------|----------|--------|-------|-------------|-------------|-------------|-------|
| campaign success @ experiment | FTH | fth_exp_123 | 2024-08-25 | 2024-02-25 | Action | 50 | | | 1000 |
| campaign success @ experiment | FTH | fth_exp_123 | 2024-08-25 | 2024-02-25 | Control | 20 | | | 1000 |

**Note:** Enables **automated high-level reporting**.

---

## View 4: campaign_success @ campaign

Aggregated view at the campaign level (across all experiments). Higher-level roll-up for executive reporting.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `data_asset` | string | View identifier | `campaign success @ campaign` |
| `mnemonic` | string | Campaign mnemonic | `FTH` |
| `start_dt` | date | Campaign start | `2024-08-25` |
| `end_dt` | date | Campaign end | `2024-02-25` |
| `group` | string | Test group (Action/Control) | `Action` |
| `1st_success` | int | Count of 1st success events | `500` |
| `2nd_success` | int | Count of 2nd success events | |
| `3rd_success` | int | Count of 3rd success events | |
| `Leads` | int | Total leads in group | `10000` |

**Sample Rows:**

| data_asset | mnemonic | start_dt | end_dt | group | 1st_success | 2nd_success | 3rd_success | Leads |
|------------|----------|----------|--------|-------|-------------|-------------|-------------|-------|
| campaign success @ campaign | FTH | 2024-08-25 | 2024-02-25 | Action | 500 | | | 10000 |
| campaign success @ campaign | FTH | 2024-08-25 | 2024-02-25 | Control | 200 | | | 10000 |

**Note:** Enables **automated high-level reporting**.

---

## Mnemonic Reference Table (Full Catalog)

Complete catalog of all campaign mnemonics with their event types, categories, products, and success definitions. This is the master reference for the campaign_mapping table.

| No. | Mnemonic | Description | Event Type | Event Category | Product | Clean Primary | Primary Subset |
|-----|----------|-------------|------------|----------------|---------|---------------|----------------|
| 44 | FTH | First Time Homebuyer with FHSA | Acquisition | Product Open | Mortgage | | |
| 43 | MOM | Mortgage 1 Year from Maturity Touchpoint | Retention | Product Retention | Mortgage | Mortgage Retained | Past Maturity |
| 7 | BOL | Pre-approved Business Operating Line of Credit Opportunity | N/A | | Loans | Business Credit Line Open | |
| 10 | ESV | New eSavings Bonus Interest Offer | Conversion | Product Open | PBA | PBA Open | HISA |
| 16 | GIS | GIC Exclusive Rate Acquisition | Conversion | Product Open | Investments | Investment Open | GIC |
| 3 | LTA | Pre-approved Royal Credit Line Opportunity (RCL LTA) | Conversion | Product Open | Loans | Royal Credit Line Open | |
| 2 | RCL | Pre-approved Royal Credit Line Opportunity (RCL TPA) | Conversion | Product Open | Loans | Royal Credit Line Open | |
| 4 | RCU | Royal Credit Line - Utilization | Conversion | Product Usage | Loans | Royal Credit Line Balance | $1 |
| 5 | VBA | Pre-approved Business Credit Card Opportunity (VBA TPA) | N/A | | Credit Card | Credit Card Open | Business ASC Matched |
| 24 | CTU | Advantage & Value Program Right Fit Check | Conversion | Product Enhancement | PBA | PBA Upgrade | Target Path |
| 13 | MRF | Mortgage Refinance Advice Opportunity | Conversion | | Mortgage | Mortgage Refinance | |
| 23 | NMI | NOAM Find & Save | Conversion | Product Open | Digital Footprint | NOAM Open | |
| 21 | PCD | Credit Card Best Fit Check | Conversion | Product Enhancement | Credit Card | Credit Card Upgrade | Targeted Personal Card Path |
| 9 | PCL | Credit Card Limit Increase Opportunity | Conversion | Product Open | Credit Card | Credit Limit Increase | AR_ID Matched |
| 1 | PCQ | Cards Acquisition | Conversion | Product Open | Credit Card | Credit Card Open | Personal ASC Matched |
| 11 | PPQ | Personal Bank Account Opportunity | Conversion | Product Open | PBA | PBA Open | Chequing |
| 22 | TFP | TFSA and RRSP Grow with a PAC | Conversion | Product Usage | Investments | PAC Start | *Is it just at least one payment? How long as minimum?* |
| 14 | VBU | Business Cards Upgrade | N/A | Product Enhancement | Credit Card | Credit Card Upgrade | Targeted Business Card Path |
| 9 | RSS | RCL Balance Stimulation | Conversion | Product Usage | Loans | Royal Credit Line Balance | $1 |
| 25 | TAO | Tax Free Savings Account Opportunity | Conversion | Product Open | Investments | Investment Open | TFSA, RRSP |
| 32 | RMG | GIC - Maturity | Engagement | Product Open | Investments | GIC Renewal | |
| 34 | VCN | VVD Acquisition Mobile Banner | Acquisition | Product Enhancement | Digital Footprint | Virtual Visa Debit Activation | |
| 35 | IRI | International Remittance | Engagement | Product Action | Payments | International Money Transfer | IMT Transaction |
| 45 | O2P | Pre-approved Overdraft Opportunity | Acquisition | Product Open | Loans | Overdraft Open | |
| 46 | CRV | Credit Card Installment Plan Offer | Acquisition | Product Usage | Credit Card | Installment Purchase | >$0 |
| 28 | EBR | PBA Value Program | Conversion | Product Open | Value Program | Value Program Enrollment | |
| 15 | IDE | Invest and Trade Online Services | Conversion | Product Open | Investments | Investment Open | Direct Investing or InvestEase (GoSmart) |
| 19 | RPB | PBA Client Retention Check-in | Attrition | Product Retention | PBA | PBA Open | Status = Active/Open at 180 days |
| 6 | VBA_LTA | Pre-approved Business Credit Card Opportunity (VBA LTA) | N/A | Product Open | Credit Card | Credit Card Open | Business ASC Matched |
| 12 | ZHR | Client Relationship Retention | Conversion | Product Usage | | | |
| 17 | PFS | PBA Funding Strategy | Conversion | Product Usage | PBA | Funding | >$25 PBA Account Credit |
| 18 | PRA | Personal Account Opened in Restraint | Conversion | Product Open | PBA | PBA Open | Status Change out of Restraint |
| 20 | DAR | Dormant Account Reactivation | Attrition | Product Retention | PBA | PBA Open | Status = Inactive to Active |
| 26 | VSX | Value Ecosystem Engagement | Conversion | Product Open | Client | MISSING | |
| 27 | RCR | RCL Price Optimization | Conversion | Product Open | Loans | MISSING | |
| 29 | COB | Cards Onboarding | Engagement | Product Enhancement | Credit Card | Credit Card Activation | |
| 30 | VAW | VVD Mobile App Acquisition Contextual Notification | Engagement | Product Enhancement | Digital Footprint | Digital Wallet | Virtual Visa Debit |
| 31 | GNE | Explore & Continue GIC Journey | Engagement | Product Open | Investments | All GIC >$0 (ins and outs) | |
| 33 | COR | Student RCL - Confirmation of Repayment Terms | N/A | | Loans | MISSING | |
| 36 | VUI | VVD Usage Increase Trigger | Conversion | Product Usage | Payments | Virtual Visa Debit Transaction | ~$0 |
| 37 | PVE | Value Program Enrollment | Engagement | Product Open | Value Program | Product Cross-Sell | |
| 38 | MOS | Investments Advice Connect | Engagement | Product Usage | Investments | Positive Long-Term Net Sales | RESP |
| 39 | RAT | Explore Education Saving Options | Acquisition | Product Open | Investments | Investment Open | |
| 40 | MFY | New Mortgage Touchpoint | Engagement | | Mortgage | MISSING | |
| 41 | MMT | Mortgage Milestone Touchpoint | Engagement | Product Enhancement | | MISSING | |
| 42 | IFC | International Money Transfer Winback Campaign | Engagement | | Payments | International Money Transfer | IMT Transaction |

**Owner Types:** Batch, NBO (Next Best Offer)

**Items marked MISSING** need success definitions to be completed before deployment.

---

## Entity Relationship Summary

```
experiment_mapping (A)
    │
    ├──▶ experiment_population (B) ──via experiment_id
    │        │
    │        └──▶ tactic_history (2) ──via tactic_id, clnt_no
    │                 │
    │                 └──▶ success_event_mapping (1) ──via tactic_id
    │                          │
    │                          └──▶ success_events (1 green) ──via event_type_cd
    │                                    │
    │                                    └──▶ cross_sell (5) ──via Crosstab Pivot
    │
    └──▶ campaign_mapping (C) ──via mnemonic
              │
              └──▶ Mnemonic Reference Table ──via mnemonic

Views derived from base tables:
    tactic_history + success_events ──▶ View 3: campaign_success @ experiment
    tactic_history + success_events ──▶ View 4: campaign_success @ campaign

Supplementary tables:
    Channel Interactions ──joins with responses (TBD)
    Share of Wallet - PROGRAMS ──from UCP
    Share of Wallet - USAGE ──from UCP (daily/weekly refresh needed)
```

---

## Open Questions (from whiteboard annotations)

1. **Success date fields:** Kelvin raised — should `1st_success`, `2nd_success`, `3rd_success` in tactic_history be dates or flags?
2. **Channel Interactions joins:** How does Channel Interactions join with campaign responses?
3. **Share of Wallet refresh frequency:** SOW tables require Daily/Weekly refresh; can UCP handle datasets at different frequencies?
4. **SOW data source:** Most SOW data can come from UCP — this is an alternate format for measurement/modelling
5. **TFP minimum definition:** For PAC Start (TFP) — is it at least one payment? What is the minimum duration?
6. **MISSING success definitions:** VSX, RCR, COR, MFY, MMT need Clean Primary / success definitions
7. **Amount field (SOW Programs):** The `amt` column format is TBD — some are derived monthly, some are tier levels
