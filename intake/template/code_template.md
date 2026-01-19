# {METRIC_ID} - {Metric Name}
<!-- Owner: {Owner Name} | Version: v1.0 -->

## Metadata

| Attribute | Value |
|-----------|-------|
| Product | {Product code: VVD, CC, MTG, etc.} |
| Metric Type | {Acquisition / Activation / Usage / Provisioning / Retention} |
| Pillar | {Conversion / Engagement / Retention / Profitability / Share of Wallet} |
| Campaigns Using | {Campaign codes, comma-separated} |
| Grain | {Client / Account / Transaction} |

## Business Definition

{Plain English description of what this metric measures. Be specific about:
- What event/action triggers this metric
- Any conditions or filters applied
- Time windows if applicable}

## Source Tables

**Data Warehouse (Teradata/Snowflake):**
- {schema.table_name}
- {schema.table_name}

**Data Lake (Hive):**
- {database.table_name}
- {database.table_name}

---

## SQL (Data Warehouse)

```sql
-- ============================================================
-- Metric: {METRIC_ID} - {Metric Name}
-- Description: {Brief description}
-- Source: Data Warehouse (Teradata / Snowflake)
-- Author: {Name}
-- Date: {YYYY-MM-DD}
-- ============================================================

-- Parameters (replace with actual values or use as template)
-- @treatment_start_date: Campaign treatment start date
-- @tactic_ids: List of tactic IDs for the campaign

SELECT
    client_id,
    -- metric flag (1 = success, 0 = no success)
    CASE
        WHEN {success_condition} THEN 1
        ELSE 0
    END AS {metric_id}_flag,
    -- event date (when the success occurred)
    {event_date_column} AS event_date,
    -- auxiliary fields (product type, account type, etc.)
    {auxiliary_field_1} AS {field_name_1},
    {auxiliary_field_2} AS {field_name_2}
FROM
    {schema.source_table} src
WHERE
    {filter_conditions}
    AND {date_filter}
;
```

---

## PySpark (Hive)

```python
# ============================================================
# Metric: {METRIC_ID} - {Metric Name}
# Description: {Brief description}
# Source: Data Lake (Hive)
# Author: {Name}
# Date: {YYYY-MM-DD}
# ============================================================

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, when, lit

# Parameters (replace with actual values)
treatment_start_date = '{YYYY-MM-DD}'
tactic_ids = ['{TACTIC_1}', '{TACTIC_2}']

# Query
query = """
SELECT
    client_id,
    CASE
        WHEN {success_condition} THEN 1
        ELSE 0
    END AS {metric_id}_flag,
    {event_date_column} AS event_date,
    {auxiliary_field_1} AS {field_name_1},
    {auxiliary_field_2} AS {field_name_2}
FROM
    {database.source_table} src
WHERE
    {filter_conditions}
    AND {date_filter}
"""

# Execute
df = spark.sql(query)

# Optional: Register as temp view for further processing
df.createOrReplaceTempView("{metric_id}_result")

# Display sample
df.show(10)
```

---

## Notes

{Any additional notes, caveats, known issues, or special handling required}

---

## Change History

| Date | Version | Author | Change Description |
|------|---------|--------|-------------------|
| {YYYY-MM-DD} | v1.0 | {Name} | Initial creation |
