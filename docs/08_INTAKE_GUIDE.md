# Success Library Intake Guide (Schema v2.0)

**Date:** 2026-01-24
**Version:** 2.0
**Audience:** Analysts, Campaign Owners, Marketing Analytics Team

---

## Overview

This guide explains how to submit new success metrics to the Success Library. The intake process collects all information needed for:

1. **Governance** - Metric ID, owner, status, validation dates
2. **Business Context** - Definition, campaigns using, pillar alignment
3. **Technical Execution** - Source tables, filters, date fields, code
4. **Engine Integration** - Everything needed to plug into Vintage Engine v2.3+

---

## Quick Start

1. Download the intake template from `intake/template/intake_template.xlsx`
2. Fill in all three sheets:
   - **Business Metadata** (required)
   - **Technical** (required for engine integration)
   - **Measurement** (optional, defaults provided)
3. Place the completed file in `intake/pending/`
4. Run `python3 excel_to_json.py`
5. Edit the generated code file in `code/{PRODUCT}/{METRIC_ID}.md`
6. Run `python3 build.py` to update the HTML

---

## Intake Form Structure

### Sheet 1: Business Metadata (Required)

This sheet captures the "what" and "who" of the metric.

| Column | Required | Description | Example |
|--------|----------|-------------|---------|
| action | Yes | `new` or `update` | new |
| metric_id | Yes | Unique ID: `{PRODUCT}_{TYPE}_{SEQ}` | VVD_ACQ_001 |
| metric_name | Yes | Human-readable name | Card Acquisition |
| product | Yes | Product code | VVD, CC, MTG, PL |
| line_of_business | No | LOB category | Debit Cards, Lending |
| metric_type | Yes | What it measures | Acquisition, Activation, Usage, Retention |
| pillar | Yes | Success Library pillar | Conversion, Engagement, Retention, Profitability |
| business_definition | Yes | Plain English description | Client acquired a new VVD card |
| source_tables | No | Comma-separated tables | DDWTA_VISA_DR_CRD, TOKEN_LIST |
| staged_source | No | Staged/processed table if applicable | |
| grain | No | Level of measurement | Client, Account, Transaction |
| owner | Yes | Team/person responsible | Marketing Analytics |
| campaigns_using | No | Campaigns that use this metric | VCN, VDA, VDT |

**Metric ID Convention:**
```
{PRODUCT}_{TYPE}_{SEQUENCE}

Examples:
- VVD_ACQ_001 = VVD Card Acquisition, first metric
- CC_USG_002 = Credit Card Usage, second metric
- MTG_RET_001 = Mortgage Retention, first metric
```

**Pillar Values:**
- Conversion (getting clients to act)
- Engagement (usage, activity)
- Retention (keeping clients)
- Profitability (revenue, margins)
- Share of Wallet (cross-sell, expansion)

---

### Sheet 2: Technical Metadata (Required for Engine)

This sheet captures the "how" - everything needed for automated execution.

| Column | Required | Description | Example |
|--------|----------|-------------|---------|
| metric_id | Yes | Must match Sheet 1 | VVD_ACQ_001 |
| complexity | Yes | SIMPLE, TRANSFORM, MULTI_TABLE | SIMPLE |
| source | Yes | Data environment | HIVE, EDW, TERADATA |
| table_path | Conditional | Full HDFS path (for HIVE) | /prod/sz/tsz/00050/data/DDWTA_VISA_DR_CRD/ |
| date_field | Yes | Column for success date | ISS_DT, TXN_DT, ACTV_DT |
| client_field | Yes | Output column for client ID | CLNT_NO |
| partition_field | No | Partition column (for optimization) | CAPTR_DT, SNAP_DT |
| client_extraction_logic | Conditional | SQL if client not direct | SUBSTR(CLNT_CRD_NO, 7, 9) |
| add_card_type | No | Include card type flag | TRUE/FALSE |
| filter_1_field | No | First filter field | STS_CD |
| filter_1_condition | No | IN, =, >, <, NOT_NULL | IN |
| filter_1_value | No | Filter value(s) | 06,08 |
| filter_2_field | No | Second filter field | SRVC_ID |
| filter_2_condition | No | | = |
| filter_2_value | No | | 36 |
| filter_3_field | No | Third filter field | |
| filter_3_condition | No | | |
| filter_3_value | No | | |
| filter_4_field | No | Fourth filter field | |
| filter_4_condition | No | | |
| filter_4_value | No | | |
| join_table | Conditional | For MULTI_TABLE only | DL_DECMAN.TOKEN_LIST |
| join_type | Conditional | INNER, LEFT | INNER |
| join_condition | Conditional | Join clause | A.TOKN_ID = B.TOKEN_ID |

**Complexity Levels:**

| Level | When to Use | Example |
|-------|-------------|---------|
| SIMPLE | Single table, direct filters, CLNT_NO available | VVD_ACQ_001 |
| TRANSFORM | Single table, client extraction needed | VVD_USG_001 |
| MULTI_TABLE | Multiple tables, joins required | VVD_PRV_001 |

**Filter Conditions:**
- `IN` - Multiple values (comma-separated): `STS_CD IN ('06','08')`
- `=` or `EQ` - Exact match: `SRVC_ID = 36`
- `>` or `GT` - Greater than: `AMT1 > 0`
- `<` or `LT` - Less than: `DAYS_SINCE < 90`
- `NOT_NULL` - Field is not null: `ISS_DT IS NOT NULL`

---

### Sheet 3: Measurement & Governance (Optional)

This sheet captures the operational context.

| Column | Required | Description | Example | Default |
|--------|----------|-------------|---------|---------|
| metric_id | Yes | Must match Sheet 1 | VVD_ACQ_001 | |
| default_window_days | No | Measurement window in days | 90 | 90 |
| attribution_model | No | How success is attributed | FIRST_TOUCH | FIRST_TOUCH |
| status | No | Current status | ACTIVE | PLACEHOLDER |
| last_validated | No | Date of last validation | 2026-01-24 | null |
| notes | No | Any additional notes | Requires EDW access | |

**Status Values:**
- `PLACEHOLDER` - Definition exists, code not validated
- `ACTIVE` - Code validated, ready for production
- `DEPRECATED` - Being phased out, don't use in new campaigns
- `RETIRED` - No longer in use

**Attribution Models:**
- `FIRST_TOUCH` - Credit first success event
- `LAST_TOUCH` - Credit last success event
- `LINEAR` - Credit split evenly across events
- `TIME_DECAY` - More credit to recent events

---

## Code Submission

After the intake is processed, a code stub is generated at:
```
code/{PRODUCT}/{METRIC_ID}.md
```

**You must edit this file to add the actual SQL and PySpark code.**

### Code File Structure

```markdown
# VVD_ACQ_001 - Card Acquisition

## Metadata
(auto-generated from intake)

## Business Definition
(expand with success criteria)

## Source Tables
(fill in paths and partitions)

## Filter Logic
(document each filter with business reason)

## PySpark (Hive)
```python
# Add working PySpark code here
```

## SQL (Data Warehouse)
```sql
-- Add SQL equivalent here
```

## Integration Notes
(document engine usage)
```

### Required Output Columns

All success metrics must output exactly two columns:

| Column | Type | Description |
|--------|------|-------------|
| CLNT_NO | string | Client identifier |
| SUCCESS_DT | date | Date when success occurred |

This standardized output enables the Vintage Engine to join with tactic data.

---

## Examples

### Example 1: Simple Single-Table Metric

**Sheet 1: Business Metadata**
| action | metric_id | metric_name | product | metric_type | pillar | business_definition | owner | campaigns_using |
|--------|-----------|-------------|---------|-------------|--------|---------------------|-------|-----------------|
| new | VVD_ACQ_001 | Card Acquisition | VVD | Acquisition | Conversion | Client acquired a new VVD card | Marketing Analytics | VCN, VDA |

**Sheet 2: Technical**
| metric_id | complexity | source | table_path | date_field | client_field | filter_1_field | filter_1_condition | filter_1_value | filter_2_field | filter_2_condition | filter_2_value |
|-----------|------------|--------|------------|------------|--------------|----------------|--------------------|----------------|----------------|--------------------|----------------|
| VVD_ACQ_001 | SIMPLE | HIVE | /prod/sz/tsz/00050/data/DDWTA_VISA_DR_CRD/ | ISS_DT | CLNT_NO | STS_CD | IN | 06,08 | SRVC_ID | = | 36 |

**Sheet 3: Measurement**
| metric_id | default_window_days | attribution_model | status |
|-----------|---------------------|-------------------|--------|
| VVD_ACQ_001 | 90 | FIRST_TOUCH | ACTIVE |

---

### Example 2: Transform Metric (Client Extraction)

**Sheet 2: Technical**
| metric_id | complexity | source | table_path | date_field | client_field | client_extraction_logic | filter_1_field | filter_1_condition | filter_1_value |
|-----------|------------|--------|------------|------------|--------------|-------------------------|----------------|--------------------|----------------|
| VVD_USG_001 | TRANSFORM | HIVE | /prod/sz/tsz/00050/data/DDWTA_T_PT_OF_SALE_TXN/ | TXN_DT | CLNT_NO | SUBSTR(CLNT_CRD_NO, 7, 9) | SRVC_CD | = | 36 |

---

### Example 3: Multi-Table Join Metric

**Sheet 2: Technical**
| metric_id | complexity | source | date_field | client_field | client_extraction_logic | join_table | join_type | join_condition |
|-----------|------------|--------|------------|--------------|-------------------------|------------|-----------|----------------|
| VVD_PRV_001 | MULTI_TABLE | EDW | TXN_DT | CLNT_NO | SUBSTR(CLNT_CRD_NO, 7, 9) | DL_DECMAN.TOKEN_LIST | INNER | A.TOKN_REQSTR_ID = B.TOKEN_ID |

---

## Workflow Summary

```
                    +-----------------------+
                    |   Analyst Prepares    |
                    |   Excel Intake Form   |
                    +-----------------------+
                              |
                              v
                    +-----------------------+
                    |   Place in           |
                    |   intake/pending/    |
                    +-----------------------+
                              |
                              v
                    +-----------------------+
                    |   Run:               |
                    |   python3            |
                    |   excel_to_json.py   |
                    +-----------------------+
                              |
        +---------------------+---------------------+
        |                                           |
        v                                           v
+------------------+                    +-------------------+
| success_library_ |                    | code/{PRODUCT}/   |
| index.json       |                    | {METRIC_ID}.md    |
| (updated)        |                    | (stub created)    |
+------------------+                    +-------------------+
                                                  |
                                                  v
                                        +-------------------+
                                        | Analyst Edits     |
                                        | Code File         |
                                        | (add SQL/PySpark) |
                                        +-------------------+
                                                  |
                                                  v
                                        +-------------------+
                                        | Run:              |
                                        | python3 build.py  |
                                        +-------------------+
                                                  |
                                                  v
                                        +-------------------+
                                        | index.html        |
                                        | (updated)         |
                                        +-------------------+
```

---

## Validation Checklist

Before submitting, verify:

- [ ] Metric ID follows naming convention: `{PRODUCT}_{TYPE}_{SEQ}`
- [ ] All required fields in Sheet 1 are filled
- [ ] Technical sheet has source, date_field, and at least one filter
- [ ] Complexity level matches the metric:
  - SIMPLE: Single table, direct CLNT_NO
  - TRANSFORM: Single table, CLNT_NO extracted
  - MULTI_TABLE: Joins required
- [ ] For MULTI_TABLE: join_table, join_type, join_condition are filled
- [ ] For TRANSFORM: client_extraction_logic is provided
- [ ] After processing: Code file is edited with working SQL/PySpark
- [ ] Code outputs exactly: CLNT_NO, SUCCESS_DT

---

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "metric_id already exists" | Duplicate ID | Use `update` instead of `new`, or pick new sequence number |
| "date_field is recommended" | Technical sheet incomplete | Add the success date column name |
| Code stub not created | File already exists | Manually edit existing code file |
| Filters not appearing in JSON | Column names mismatched | Ensure filter columns are exactly as specified |

---

## Support

- **Template Location:** `intake/template/intake_template.xlsx`
- **Processing Script:** `excel_to_json.py`
- **Build Script:** `build.py`
- **Documentation:** `docs/` folder

For questions, contact the Marketing Analytics team.

---

## Change Log

| Date | Version | Change |
|------|---------|--------|
| 2026-01-24 | 2.0 | Added technical/measurement/governance sheets, complexity levels |
| 2026-01-16 | 1.0 | Initial intake guide |
