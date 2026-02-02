# VVD_ACT_001 - Card Activation
<!-- Owner: Marketing Analytics | Version: v1.0 | Last Validated: 2026-01-24 -->

## Metadata

| Attribute | Value |
|-----------|-------|
| Product | VVD (Virtual Visa Debit) |
| Metric Type | Activation |
| Pillar | Conversion |
| Campaigns Using | VDT |
| Grain | Client |
| Date Field | ACTV_DT |
| Source | HIVE |

## Business Definition

Client activated their VVD card.

**Success Criteria:**
- Activation is measured when `ACTV_DT` (Activation Date) is populated
- Status must be Active (06) or Approved (08)
- Only VVD cards (`SRVC_ID = 36`)

**Note:** This metric measures activation AFTER issuance. The card must first exist (ISS_DT populated) before it can be activated.

## Source Tables

| Table | Path | Partition |
|-------|------|-----------|
| DDWTA_VISA_DR_CRD | `/prod/sz/tsz/00050/data/DDWTA_VISA_DR_CRD/PartitionColumn=Latest/` | CAPTR_DT |

## Filter Logic

| Field | Condition | Reason |
|-------|-----------|--------|
| STS_CD | IN ('06', '08') | Active or Approved cards only |
| SRVC_ID | = 36 | VVD product identifier |
| ISS_DT | IS NOT NULL | Card must have been issued first |

---

## PySpark (Hive)

```python
# VVD_ACT_001: Card Activation Success
# Source: VVD Vintage Engine v2.3
# Validated: 2026-01-24

from pyspark.sql import functions as F

# Configuration
TABLE_PATH = "/prod/sz/tsz/00050/data/DDWTA_VISA_DR_CRD/PartitionColumn=Latest/CAPTR_DT="
DATE_FIELD = "ACTV_DT"
CLIENT_FIELD = "CLNT_NO"
YEARS = [2025, 2026]

# Build partition paths
paths = [f"{TABLE_PATH}{year}*" for year in YEARS]

# Load data
activation_df = spark.read.parquet(*paths)

# Apply filters
activation_df = activation_df \
    .filter(F.col("STS_CD").isin(["06", "08"])) \
    .filter(F.col("SRVC_ID") == 36) \
    .filter(F.col("ISS_DT").isNotNull())

# Select output columns (using ACTV_DT as success date)
activation_df = activation_df.select(
    F.col(CLIENT_FIELD).alias("CLNT_NO"),
    F.col(DATE_FIELD).alias("SUCCESS_DT")
)

# Result: DataFrame with CLNT_NO, SUCCESS_DT
# Join with tactic data where SUCCESS_DT BETWEEN TREATMT_STRT_DT AND TREATMT_END_DT
```

---

## SQL (Data Warehouse)

```sql
-- VVD_ACT_001: Card Activation Success
-- Note: Adjust table/schema names for Data Warehouse environment

SELECT
    CLNT_NO,
    ACTV_DT AS SUCCESS_DT
FROM
    -- Data Warehouse equivalent of DDWTA_VISA_DR_CRD
    SCHEMA.VISA_DR_CRD
WHERE
    STS_CD IN ('06', '08')      -- Active or Approved
    AND SRVC_ID = 36            -- VVD product
    AND ISS_DT IS NOT NULL      -- Card was issued
;
```

---

## Integration Notes

**For Vintage Engine:**
- This metric is used as PRIMARY for campaign: VDT
- Join on `CLNT_NO` with tactic data
- Success window: `SUCCESS_DT BETWEEN TREATMT_STRT_DT AND TREATMT_END_DT`
- Aggregation: First activation date per client

**Difference from VVD_ACQ_001:**
- VVD_ACQ_001 uses `ISS_DT` (Issue Date) - when the card was created
- VVD_ACT_001 uses `ACTV_DT` (Activation Date) - when the card was first used/activated

**Engine Reference:**
```python
# In vintage_engine_v2.3.py, this metric is defined as:
SUCCESS_DEFINITIONS["card_activation"] = {
    "source": "HIVE",
    "table_path": PATHS["visa_dr_crd"],
    "date_field": "ACTV_DT",
    "client_field": "CLNT_NO",
    "filters": {
        "STS_CD": ["06", "08"],
        "SRVC_ID": 36,
        "ISS_DT_NOT_NULL": True
    }
}
```

---

## Change Log

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2026-01-24 | v1.0 | Initial production code from VVD Vintage Engine v2.3 | Marketing Analytics |
