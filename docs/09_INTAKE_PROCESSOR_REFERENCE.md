# Intake Processor Reference Guide

**File:** `excel_to_json.py`
**Version:** 2.0
**Last Updated:** 2026-01-24
**Purpose:** Process Excel intake forms and update the Success Library

---

## What This Script Does

The intake processor is the **bridge between human input (Excel) and machine-readable output (JSON)**. It:

1. Reads Excel files from `intake/pending/`
2. Validates all entries against business rules
3. Transforms the data into Schema v2.0 format
4. Updates `metadata/success_library_index.json`
5. Generates code file stubs for new metrics
6. Moves processed files to `intake/processed/`

**Think of it as:** An automated intake clerk that checks your paperwork, files it correctly, and creates the folder structure for you.

---

## When to Use This Script

| Scenario | Action |
|----------|--------|
| Adding a new metric | Fill Excel template, run script |
| Updating an existing metric | Fill Excel with `action=update`, run script |
| Bulk import of metrics | Fill multiple rows, run script once |
| After teammate submits intake | Run script to process their submission |

---

## How to Run

```bash
cd "NBA Souccess Library - Copy"
python3 excel_to_json.py
```

**What happens:**
1. Script finds all `.xlsx` files in `intake/pending/`
2. Reads and validates each file
3. Shows you a summary of changes
4. Asks for confirmation (`yes` to proceed)
5. Creates backup, applies changes, moves files

---

## Input: Excel Template Structure

The script expects an Excel file with **three sheets**:

### Sheet 1: Business Metadata (Required)

| Column | What It Means | Example |
|--------|---------------|---------|
| action | Are you adding or changing? | `new` or `update` |
| metric_id | Unique identifier | `VVD_ACQ_001` |
| metric_name | Human name | `Card Acquisition` |
| product | Product code | `VVD`, `CC`, `MTG` |
| line_of_business | Business area | `Debit Cards` |
| metric_type | What does it measure? | `Acquisition`, `Usage` |
| pillar | Success Library category | `Conversion`, `Engagement` |
| business_definition | Plain English explanation | `Client acquired a new card` |
| source_tables | Where does data come from? | `DDWTA_VISA_DR_CRD` |
| staged_source | Processed table (if any) | |
| grain | Level of detail | `Client`, `Account` |
| owner | Who maintains this? | `Marketing Analytics` |
| campaigns_using | Which campaigns use it? | `VCN, VDA` |

### Sheet 2: Technical (Required for Engine)

| Column | What It Means | Example |
|--------|---------------|---------|
| metric_id | Must match Sheet 1 | `VVD_ACQ_001` |
| complexity | How complex is the query? | `SIMPLE`, `TRANSFORM`, `MULTI_TABLE` |
| source | Where is the data? | `HIVE`, `EDW` |
| table_path | Full path to table | `/prod/sz/tsz/.../TABLE/` |
| date_field | Column with success date | `ISS_DT` |
| client_field | Column with client ID | `CLNT_NO` |
| partition_field | Partition column | `CAPTR_DT` |
| client_extraction_logic | SQL if client ID needs extraction | `SUBSTR(CARD_NO, 7, 9)` |
| add_card_type | Include card type? | `TRUE` or `FALSE` |
| filter_1_field | First filter column | `STS_CD` |
| filter_1_condition | How to filter | `IN`, `=`, `>`, `NOT_NULL` |
| filter_1_value | Filter value(s) | `06,08` |
| (filter_2, 3, 4...) | Additional filters | |
| join_table | For multi-table joins | `TOKEN_LIST` |
| join_type | Join type | `INNER`, `LEFT` |
| join_condition | Join clause | `A.KEY = B.KEY` |

### Sheet 3: Measurement (Optional)

| Column | What It Means | Default |
|--------|---------------|---------|
| metric_id | Must match Sheet 1 | |
| default_window_days | Measurement window | `90` |
| attribution_model | How to attribute success | `FIRST_TOUCH` |
| status | Current state | `PLACEHOLDER` |
| last_validated | When was code validated? | `null` |
| notes | Any comments | |

---

## Output: What Gets Created/Updated

### 1. JSON Index Updated

`metadata/success_library_index.json` gets a new entry like:

```json
{
  "metric_id": "VVD_ACQ_001",
  "metric_name": "Card Acquisition",
  "product": "VVD",
  "code_path": "code/VVD/VVD_ACQ_001.md",

  "technical": {
    "source": "HIVE",
    "table_path": "/prod/sz/.../DDWTA_VISA_DR_CRD/",
    "date_field": "ISS_DT",
    "client_field": "CLNT_NO",
    "filters": {
      "STS_CD": ["06", "08"],
      "SRVC_ID": 36
    }
  },

  "measurement": {
    "default_window_days": 90,
    "attribution_model": "FIRST_TOUCH"
  },

  "governance": {
    "status": "ACTIVE",
    "last_validated": "2026-01-24"
  }
}
```

### 2. Code Stub Generated

For new metrics, a code file is created at `code/{PRODUCT}/{METRIC_ID}.md`:

```markdown
# VVD_ACQ_001 - Card Acquisition

## Metadata
(auto-filled from intake)

## PySpark (Hive)
```python
# TODO: Add working code
```

## SQL (Data Warehouse)
```sql
-- TODO: Add SQL query
```
```

**You must edit this file** to add the actual working code.

### 3. Backup Created

Before any changes, a backup is saved to:
```
metadata/backups/success_library_index_backup_YYYYMMDD_HHMMSS.json
```

### 4. Processed File Moved

The intake Excel is moved from `pending/` to `processed/` with timestamp:
```
intake/processed/my_intake_processed_20260124_153000.xlsx
```

---

## Validation Rules

The script enforces these rules:

### Errors (Blocks Processing)

| Rule | Message |
|------|---------|
| Missing action | `'action' is required` |
| Invalid action | `'action' must be 'new' or 'update'` |
| Missing metric_id | `'metric_id' is required` |
| Duplicate in intake | `Duplicate metric_id in intake files` |
| New but exists | `metric_id already exists. Use 'update'` |
| Update but missing | `metric_id not found. Use 'new'` |
| Missing required field | `'{field}' is required for new metrics` |

### Warnings (Non-Blocking)

| Rule | Message |
|------|---------|
| Unknown source | `source 'X' not in ['HIVE', 'EDW', 'TERADATA']` |
| Missing date_field | `'date_field' is recommended` |
| Unknown complexity | `complexity 'X' not in ['SIMPLE', 'TRANSFORM', 'MULTI_TABLE']` |
| Unknown status | `status 'X' not in ['ACTIVE', 'PLACEHOLDER', ...]` |

---

## Complexity Levels Explained

| Level | When to Use | What It Means |
|-------|-------------|---------------|
| **SIMPLE** | Single table, CLNT_NO is a direct column | Standard query with filters |
| **TRANSFORM** | Single table, but CLNT_NO must be extracted | Needs `SUBSTR()` or similar |
| **MULTI_TABLE** | Need to join tables | Fill in join_table, join_type, join_condition |

### Examples by Complexity

**SIMPLE (VVD_ACQ_001):**
```
Table: DDWTA_VISA_DR_CRD
Client: CLNT_NO (direct column)
Filters: STS_CD IN ('06','08'), SRVC_ID = 36
```

**TRANSFORM (VVD_USG_001):**
```
Table: DDWTA_T_PT_OF_SALE_TXN
Client: SUBSTR(CLNT_CRD_NO, 7, 9)  ← extracted from card number
Filters: SRVC_CD = 36, AMT1 > 0
```

**MULTI_TABLE (VVD_PRV_001):**
```
Table A: CLNT_CRD_POS_LOG
Table B: TOKEN_LIST
Join: A.TOKN_REQSTR_ID = B.TOKEN_ID
Client: SUBSTR(CLNT_CRD_NO, 7, 9)
Filters: AMT1 = 0, TOKEN_WALLET_IND = 'Y'
```

---

## Filter Condition Reference

| Condition | SQL Equivalent | Example Value |
|-----------|----------------|---------------|
| `IN` | `field IN (...)` | `06,08` (comma-separated) |
| `=` or `EQ` | `field = value` | `36` |
| `>` or `GT` | `field > value` | `0` |
| `<` or `LT` | `field < value` | `90` |
| `NOT_NULL` | `field IS NOT NULL` | (leave value blank) |

---

## Folder Structure

```
NBA Souccess Library - Copy/
├── intake/
│   ├── pending/          ← Put Excel files here
│   ├── processed/        ← Files move here after processing
│   └── template/
│       ├── intake_template_v2.xlsx   ← Use this template
│       └── code_template.md          ← Code stub template
├── metadata/
│   ├── success_library_index.json    ← Main database
│   └── backups/                      ← Auto-backups
├── code/
│   └── VVD/                          ← Code files by product
│       ├── VVD_ACQ_001.md
│       └── ...
├── excel_to_json.py                  ← This processor
└── build.py                          ← Regenerates HTML
```

---

## Troubleshooting

### "No intake files found"
- Check that files are in `intake/pending/` (not `template/` or `processed/`)
- Files must have `.xlsx` extension

### "metric_id already exists"
- You're trying to add a metric that's already in the library
- Change `action` from `new` to `update`

### "metric_id not found"
- You're trying to update a metric that doesn't exist
- Change `action` from `update` to `new`

### Code stub not created
- File already exists at `code/{product}/{metric_id}.md`
- Edit the existing file manually

### Filters not appearing in JSON
- Check column names match exactly: `filter_1_field`, `filter_1_condition`, `filter_1_value`
- Ensure the field name is filled (condition/value alone won't work)

### Sheet not being read
- Sheet names should be: `Business Metadata`, `Technical`, `Measurement`
- Or: `Data Entry`, `Tech`, `Governance`
- Script also falls back to first non-Instructions sheet

---

## After Running the Script

1. **Edit the code file** at `code/{PRODUCT}/{METRIC_ID}.md`
   - Add working PySpark code
   - Add SQL equivalent
   - Document filters with business reasons

2. **Regenerate HTML**
   ```bash
   python3 build.py
   ```

3. **Verify in browser**
   - Open `index.html`
   - Find your new metric
   - Check all fields display correctly

---

## Quick Reference Commands

```bash
# Generate fresh Excel template
python3 generate_intake_template.py

# Process intake files
python3 excel_to_json.py

# Rebuild HTML after editing code files
python3 build.py
```

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| `docs/08_INTAKE_GUIDE.md` | User guide for filling the Excel form |
| `docs/07_SCHEMA_V2_UPGRADE.md` | Schema v2.0 specification |
| `docs/DESIGN_DECISIONS.md` | Architecture decisions |

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-24 | 2.0 | Added Technical/Measurement sheets, complexity levels, filter parsing, join support |
| 2026-01-16 | 1.0 | Initial single-sheet processor |
