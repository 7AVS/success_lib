# Success Library Schema v2.0 Upgrade

**Date:** 2026-01-24
**Author:** VVD Vintage Engine Integration
**Previous Version:** v0.1-pilot
**New Version:** v0.2-pilot (Schema v2.0)

---

## Executive Summary

This document captures the upgrade of the Success Library schema from v1.0 to v2.0. The upgrade adds technical attributes required for automated engine integration, replacing placeholder/mockup data with production code from the VVD Vintage Engine v2.3.

---

## What Changed

### 1. JSON Schema Enhanced

**New top-level fields:**
```json
{
  "schema_version": "2.0",
  "schema_notes": "Added 'technical' block for engine integration. Code files contain executable PySpark."
}
```

**New blocks per metric:**

| Block | Purpose | Contents |
|-------|---------|----------|
| `technical` | Engine integration | source, table_path, date_field, client_field, partition_field, filters |
| `measurement` | Vintage curve config | default_window_days, attribution_model |
| `governance` | Status tracking | status, last_validated |

### 2. VVD Metrics Updated with Production Code

| Metric ID | Before | After |
|-----------|--------|-------|
| VVD_ACQ_001 | Placeholder | Real PySpark from engine |
| VVD_ACT_001 | Placeholder | Real PySpark from engine |
| VVD_USG_001 | Placeholder | Real PySpark from engine |
| VVD_PRV_001 | Placeholder | Real PySpark from engine |

### 3. Code Files Now Include

Each `.md` file in `code/VVD/` now contains:
- Metadata table with all attributes
- Business definition with success criteria
- Source tables with actual HDFS paths
- Filter logic table (field, condition, reason)
- Working PySpark code
- SQL equivalent for Data Warehouse
- Integration notes for Vintage Engine
- Change log

---

## Schema v2.0 Structure

### Full Metric Schema

```json
{
  "metric_id": "VVD_ACQ_001",
  "metric_name": "Card Acquisition",
  "product": "VVD",
  "line_of_business": "Debit Cards",
  "metric_type": "Acquisition",
  "pillar": "Conversion",
  "business_definition": "Client acquired a new VVD card...",
  "code_path": "code/VVD/VVD_ACQ_001.md",
  "source_tables": ["DDWTA_VISA_DR_CRD"],
  "staged_source": "",
  "grain": "Client",
  "owner": "Marketing Analytics",
  "version": "v1.0",
  "campaigns_using": ["VCN", "VDA"],

  "technical": {
    "source": "HIVE",
    "table_path": "/prod/sz/tsz/00050/data/DDWTA_VISA_DR_CRD/PartitionColumn=Latest/CAPTR_DT=",
    "date_field": "ISS_DT",
    "client_field": "CLNT_NO",
    "partition_field": "CAPTR_DT",
    "filters": {
      "STS_CD": ["06", "08"],
      "SRVC_ID": 36,
      "ISS_DT_NOT_NULL": true
    },
    "add_card_type": true
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

### Technical Block Fields

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `source` | string | Data source: "HIVE" or "EDW" | Yes |
| `table_path` | string/null | HDFS path (null for EDW) | Yes |
| `date_field` | string | Field containing success date | Yes |
| `client_field` | string | Field containing client identifier | Yes |
| `partition_field` | string | Partition column name | No |
| `filters` | object | Filter conditions (varies by metric) | Yes |
| `add_card_type` | boolean | Whether to include card type | No |
| `client_extraction_logic` | string | How to extract CLNT_NO if not direct | No |

### Measurement Block Fields

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `default_window_days` | integer | Default measurement window | Yes |
| `attribution_model` | string | FIRST_TOUCH, LAST_TOUCH, etc. | Yes |

### Governance Block Fields

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `status` | string | ACTIVE, PLACEHOLDER, DEPRECATED, RETIRED | Yes |
| `last_validated` | string/null | Date of last validation | No |

---

## VVD Metrics Technical Details

### VVD_ACQ_001 - Card Acquisition

| Attribute | Value |
|-----------|-------|
| Source | HIVE |
| Table | DDWTA_VISA_DR_CRD |
| Date Field | ISS_DT |
| Campaigns | VCN, VDA |
| Key Filters | STS_CD IN ('06','08'), SRVC_ID=36 |

### VVD_ACT_001 - Card Activation

| Attribute | Value |
|-----------|-------|
| Source | HIVE |
| Table | DDWTA_VISA_DR_CRD |
| Date Field | ACTV_DT |
| Campaigns | VDT |
| Key Filters | STS_CD IN ('06','08'), SRVC_ID=36 |

### VVD_USG_001 - Card Usage

| Attribute | Value |
|-----------|-------|
| Source | HIVE |
| Table | DDWTA_T_PT_OF_SALE_TXN |
| Date Field | TXN_DT |
| Campaigns | VUI (primary), VUT, VAW (secondary) |
| Key Filters | SRVC_CD=36, TXN_TP/MSG_TP combos, AMT1>0 |
| Special | Client extracted from CLNT_CRD_NO |

### VVD_PRV_001 - Wallet Provisioning

| Attribute | Value |
|-----------|-------|
| Source | EDW (Teradata) |
| Tables | DDWV05.CLNT_CRD_POS_LOG + DL_DECMAN.TOKEN_LIST |
| Date Field | TXN_DT |
| Campaigns | VAW, VUT (primary), VUI (secondary) |
| Key Filters | TOKEN_WALLET_IND='Y', card prefixes, AMT1=0 |
| Special | Requires EDW connection, not HIVE |

---

## Integration with VVD Vintage Engine

### Current State (v2.3)

Engine has hardcoded `SUCCESS_DEFINITIONS` dict:
```python
SUCCESS_DEFINITIONS = {
    "card_acquisition": {
        "source": "HIVE",
        "table_path": PATHS["visa_dr_crd"],
        "date_field": "ISS_DT",
        ...
    }
}
```

### Future State (v2.4+)

Engine reads from Success Library JSON:
```python
# Load from Success Library
with open('success_library_index.json') as f:
    library = json.load(f)

# Get metric by ID
def get_metric(metric_id):
    for m in library['metrics']:
        if m['metric_id'] == metric_id:
            return m['technical']
    return None

# Use in engine
config = get_metric('VVD_ACQ_001')
```

### Mapping: Library → Engine

| Library Field | Engine Field |
|---------------|--------------|
| `technical.source` | `success_source` |
| `technical.table_path` | `success_table_path` |
| `technical.date_field` | `success_date_field` |
| `technical.client_field` | `client_field` |
| `technical.filters` | `filters` |

---

## Why This Matters

### Before (v1.0)
- Placeholder code: `[TO BE IMPLEMENTED]`
- No technical attributes
- Library and engine were separate systems
- Manual sync required

### After (v2.0)
- Real production code
- Full technical specifications
- Library can feed engine
- Single source of truth for metric definitions

---

## Files Changed

| File | Change |
|------|--------|
| `metadata/success_library_index.json` | Added technical/measurement/governance blocks |
| `code/VVD/VVD_ACQ_001.md` | Real code, full documentation |
| `code/VVD/VVD_ACT_001.md` | Real code, full documentation |
| `code/VVD/VVD_USG_001.md` | Real code, full documentation |
| `code/VVD/VVD_PRV_001.md` | Real code, full documentation |

---

## Next Steps

1. **Regenerate index.html** - Run `python build.py` to update the web interface
2. **Build engine bridge** - Create function to read from library JSON
3. **Test integration** - Verify engine can use library definitions
4. **Expand to other products** - Apply same pattern to CC, MTG metrics

---

## Related Documents

- `DESIGN_DECISIONS.md` - Original architecture decisions
- `success_library_project_context.md` - Full project specification
- VVD Engine: `vintage_engine_v2.3.py` - Source of production code

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-01-24 | Initial v2.0 schema upgrade documentation | VVD Integration |
