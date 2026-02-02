# {METRIC_ID} - {METRIC_NAME}
<!-- Owner: {OWNER} | Version: v1.0 | Last Validated: {DATE} -->

## Metadata

| Attribute | Value |
|-----------|-------|
| Product | {PRODUCT} |
| Metric Type | {METRIC_TYPE} |
| Pillar | {PILLAR} |
| Campaigns Using | {CAMPAIGNS} |
| Grain | {GRAIN} |
| Date Field | {DATE_FIELD} |
| Source | {SOURCE} |

## Business Definition

{BUSINESS_DEFINITION}

**Success Criteria:**
- {CRITERION_1}
- {CRITERION_2}
- {CRITERION_3}

## Source Tables

| Table | Path / Schema | Partition |
|-------|---------------|-----------|
| {TABLE_NAME} | {TABLE_PATH} | {PARTITION_FIELD} |

## Filter Logic

| Field | Condition | Reason |
|-------|-----------|--------|
| {FILTER_FIELD_1} | {FILTER_CONDITION_1} | {FILTER_REASON_1} |
| {FILTER_FIELD_2} | {FILTER_CONDITION_2} | {FILTER_REASON_2} |

## Client Extraction

**Direct or Transformation Required:**

If client ID is not directly available:
```
CLNT_NO = {CLIENT_EXTRACTION_LOGIC}
```

---

## PySpark (Hive)

```python
# {METRIC_ID}: {METRIC_NAME}
# Source: Success Library v2.0
# Validated: {DATE}

from pyspark.sql import functions as F

# Configuration
TABLE_PATH = "{TABLE_PATH}"
DATE_FIELD = "{DATE_FIELD}"
YEARS = [2025, 2026]

# Build partition paths
paths = [f"{TABLE_PATH}{year}*" for year in YEARS]

# Load data
df = spark.read.parquet(*paths)

# Apply filters
df = df.filter(
    # TODO: Add filter conditions
    # F.col("FIELD") == VALUE
)

# Extract client number (if transformation needed)
# df = df.withColumn(
#     "CLNT_NO",
#     F.regexp_replace(F.substring(F.col("CARD_FIELD"), 7, 9), "^0+", "")
# )

# Select output columns
df = df.select(
    F.col("CLNT_NO"),
    F.col(DATE_FIELD).alias("SUCCESS_DT")
)

# Result: DataFrame with CLNT_NO, SUCCESS_DT
# Join with tactic data where SUCCESS_DT BETWEEN TREATMT_STRT_DT AND TREATMT_END_DT
```

---

## SQL (Data Warehouse)

```sql
-- {METRIC_ID}: {METRIC_NAME}
-- Environment: EDW / Teradata / Snowflake
-- Note: Adjust schema/table names for your environment

SELECT
    CLNT_NO,
    {DATE_FIELD} AS SUCCESS_DT
FROM
    {SCHEMA}.{TABLE_NAME}
WHERE
    -- TODO: Add filter conditions
    1=1
;
```

---

## Integration Notes

**For Vintage Engine:**
- This metric is used as:
  - PRIMARY for campaigns: {PRIMARY_CAMPAIGNS}
  - SECONDARY for campaigns: {SECONDARY_CAMPAIGNS}
- Join on `CLNT_NO` with tactic data
- Success window: `SUCCESS_DT BETWEEN TREATMT_STRT_DT AND TREATMT_END_DT`
- Aggregation: First success date per client

**Engine Reference:**
```python
# In vintage_engine, this metric is defined as:
SUCCESS_DEFINITIONS["{METRIC_ID}"] = {
    "source": "{SOURCE}",
    "table_path": "{TABLE_PATH}",
    "date_field": "{DATE_FIELD}",
    "client_field": "CLNT_NO",
    "filters": {
        # TODO: Add filters
    }
}
```

---

## Change Log

| Date | Version | Change | Author |
|------|---------|--------|--------|
| {DATE} | v1.0 | Initial creation from intake | {OWNER} |
