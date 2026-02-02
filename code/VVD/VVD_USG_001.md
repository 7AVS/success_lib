# VVD_USG_001 - Card Usage
<!-- Owner: Marketing Analytics | Version: v1.0 | Last Validated: 2026-01-24 -->

## Metadata

| Attribute | Value |
|-----------|-------|
| Product | VVD (Virtual Visa Debit) |
| Metric Type | Usage |
| Pillar | Engagement |
| Campaigns Using | VUI, VUT, VAW |
| Grain | Client |
| Date Field | TXN_DT |
| Source | HIVE |

## Business Definition

Client used their VVD card for a transaction.

**Success Criteria:**
- Point-of-sale transaction with VVD card (`SRVC_CD = 36`)
- Specific transaction types that indicate actual purchases
- Transaction amount greater than 0

**Transaction Types Included:**
| TXN_TP | MSG_TP | Description |
|--------|--------|-------------|
| 10 | 0210 | Standard purchase |
| 13 | 0210 | E-commerce purchase |
| 12 | 0220 | Recurring/subscription |

## Source Tables

| Table | Path | Partition |
|-------|------|-----------|
| DDWTA_T_PT_OF_SALE_TXN | `/prod/sz/tsz/00050/data/DDWTA_T_PT_OF_SALE_TXN/` | SNAP_DT |

## Filter Logic

| Field | Condition | Reason |
|-------|-----------|--------|
| SRVC_CD | = 36 | VVD product identifier |
| TXN_TP/MSG_TP | See above | Valid purchase transactions |
| AMT1 | > 0 | Non-zero transaction amount |

## Client Extraction

**Important:** The POS transaction table does not have a direct `CLNT_NO` field. Client number must be extracted from the card number:

```
CLNT_NO = SUBSTR(CLNT_CRD_NO, 7, 9) with leading zeros removed
```

---

## PySpark (Hive)

```python
# VVD_USG_001: Card Usage Success
# Source: VVD Vintage Engine v2.3
# Validated: 2026-01-24

from pyspark.sql import functions as F

# Configuration
TABLE_PATH = "/prod/sz/tsz/00050/data/DDWTA_T_PT_OF_SALE_TXN/SNAP_DT="
DATE_FIELD = "TXN_DT"
YEARS = [2025, 2026]

# Transaction type filters
TXN_TYPES = [
    {"TXN_TP": 10, "MSG_TP": "0210"},
    {"TXN_TP": 13, "MSG_TP": "0210"},
    {"TXN_TP": 12, "MSG_TP": "0220"}
]

# Build partition paths
paths = [f"{TABLE_PATH}{year}*" for year in YEARS]

# Load data
usage_df = spark.read.parquet(*paths)

# Apply service code filter
usage_df = usage_df.filter(F.col("SRVC_CD") == 36)

# Apply transaction type filters
txn_cond = None
for t in TXN_TYPES:
    c = (F.col("TXN_TP") == t["TXN_TP"]) & (F.col("MSG_TP") == t["MSG_TP"])
    txn_cond = c if txn_cond is None else txn_cond | c
usage_df = usage_df.filter(txn_cond)

# Apply amount filter
usage_df = usage_df.filter(F.col("AMT1") > 0)

# Extract client number from card number
usage_df = usage_df.withColumn(
    "CLNT_NO",
    F.regexp_replace(F.substring(F.col("CLNT_CRD_NO"), 7, 9), "^0+", "")
)

# Select output columns
usage_df = usage_df.select(
    F.col("CLNT_NO"),
    F.col(DATE_FIELD).alias("SUCCESS_DT")
)

# Result: DataFrame with CLNT_NO, SUCCESS_DT
# Join with tactic data where SUCCESS_DT BETWEEN TREATMT_STRT_DT AND TREATMT_END_DT
```

---

## SQL (Data Warehouse)

```sql
-- VVD_USG_001: Card Usage Success
-- Note: Adjust table/schema names for Data Warehouse environment

SELECT
    -- Extract client number from card number (positions 7-15, remove leading zeros)
    CAST(LTRIM(SUBSTR(CLNT_CRD_NO, 7, 9), '0') AS VARCHAR(20)) AS CLNT_NO,
    TXN_DT AS SUCCESS_DT
FROM
    -- Data Warehouse equivalent of DDWTA_T_PT_OF_SALE_TXN
    SCHEMA.PT_OF_SALE_TXN
WHERE
    SRVC_CD = 36                -- VVD product
    AND AMT1 > 0                -- Non-zero amount
    AND (
        (TXN_TP = 10 AND MSG_TP = '0210')   -- Standard purchase
        OR (TXN_TP = 13 AND MSG_TP = '0210') -- E-commerce
        OR (TXN_TP = 12 AND MSG_TP = '0220') -- Recurring
    )
;
```

---

## Integration Notes

**For Vintage Engine:**
- This metric is used as:
  - PRIMARY for campaign: VUI
  - SECONDARY for campaigns: VUT, VAW
- Join on `CLNT_NO` with tactic data
- Success window: `SUCCESS_DT BETWEEN TREATMT_STRT_DT AND TREATMT_END_DT`
- Aggregation: First usage date per client

**Client Number Extraction:**
The `CLNT_CRD_NO` field format:
```
Position: 123456|789012345|...
          ------|---------
          Prefix  CLNT_NO (9 digits, may have leading zeros)
```

**Engine Reference:**
```python
# In vintage_engine_v2.3.py, this metric is defined as:
SUCCESS_DEFINITIONS["card_usage"] = {
    "source": "HIVE",
    "table_path": PATHS["pos_txn"],
    "date_field": "TXN_DT",
    "client_field": "CLNT_NO",
    "filters": {
        "SRVC_CD": 36,
        "TXN_TYPES": [
            {"TXN_TP": 10, "MSG_TP": "0210"},
            {"TXN_TP": 13, "MSG_TP": "0210"},
            {"TXN_TP": 12, "MSG_TP": "0220"}
        ],
        "AMT1_GT": 0,
        "EXTRACT_CLNT_NO": True
    }
}
```

---

## Change Log

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2026-01-24 | v1.0 | Initial production code from VVD Vintage Engine v2.3 | Marketing Analytics |
