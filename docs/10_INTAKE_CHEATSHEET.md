# Intake Processor Cheat Sheet

**One-page quick reference for daily use**

---

## The 30-Second Version

```
Excel in intake/pending/ → python3 excel_to_json.py → Edit code file → python3 build.py
```

---

## Commands

| Task | Command |
|------|---------|
| Process intake | `python3 excel_to_json.py` |
| Build HTML | `python3 build.py` |
| New template | `python3 generate_intake_template.py` |

---

## Excel Sheets

| Sheet | Required | What Goes Here |
|-------|----------|----------------|
| Business Metadata | Yes | metric_id, name, product, pillar, definition, owner |
| Technical | Yes* | source, table_path, date_field, filters, joins |
| Measurement | No | window_days, status (defaults: 90, PLACEHOLDER) |

*Required for engine integration

---

## Action Values

| Action | When |
|--------|------|
| `new` | Adding a metric for the first time |
| `update` | Changing an existing metric |

---

## Complexity Levels

| Level | Meaning |
|-------|---------|
| `SIMPLE` | One table, CLNT_NO is a column |
| `TRANSFORM` | One table, CLNT_NO extracted (SUBSTR) |
| `MULTI_TABLE` | Joins required |

---

## Filter Conditions

| Condition | SQL | Example |
|-----------|-----|---------|
| `IN` | `IN (...)` | `06,08` |
| `=` | `= value` | `36` |
| `>` | `> value` | `0` |
| `NOT_NULL` | `IS NOT NULL` | |

---

## Status Values

| Status | Meaning |
|--------|---------|
| `PLACEHOLDER` | Definition exists, code not validated |
| `ACTIVE` | Ready for production |
| `DEPRECATED` | Being phased out |
| `RETIRED` | No longer used |

---

## Folder Locations

| What | Where |
|------|-------|
| Put intake files | `intake/pending/` |
| Processed files go | `intake/processed/` |
| Template | `intake/template/intake_template_v2.xlsx` |
| JSON database | `metadata/success_library_index.json` |
| Code files | `code/{PRODUCT}/{METRIC_ID}.md` |
| Backups | `metadata/backups/` |

---

## Metric ID Format

```
{PRODUCT}_{TYPE}_{SEQ}

VVD_ACQ_001  = VVD Card Acquisition #1
CC_USG_002   = Credit Card Usage #2
MTG_RET_001  = Mortgage Retention #1
```

---

## Output Columns (All Metrics)

Every metric must output exactly:

| Column | Type | Description |
|--------|------|-------------|
| `CLNT_NO` | string | Client identifier |
| `SUCCESS_DT` | date | When success occurred |

---

## Common Errors

| Error | Fix |
|-------|-----|
| "already exists" | Change action to `update` |
| "not found" | Change action to `new` |
| "No intake files" | Check file is in `pending/` with `.xlsx` extension |

---

## After Processing

1. Edit `code/{PRODUCT}/{METRIC_ID}.md` - add real SQL/PySpark
2. Run `python3 build.py`
3. Open `index.html` to verify

---

## Full Docs

- Detailed guide: `docs/09_INTAKE_PROCESSOR_REFERENCE.md`
- User guide: `docs/08_INTAKE_GUIDE.md`
- Schema spec: `docs/07_SCHEMA_V2_UPGRADE.md`
