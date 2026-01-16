# VVD_USG_001 - Usage Success
<!-- Owner: [TO BE ASSIGNED] | Version: v1.0 -->

## Metadata

| Attribute | Value |
|-----------|-------|
| Product | VVD (Virtual Visa Debit) |
| Metric Type | Usage |
| Pillar | Engagement |
| Campaigns Using | VUT |
| Grain | Client |

## Business Definition

[TO BE FILLED]

## Source Tables

[TO BE FILLED]

---

## SQL (Data Warehouse)

```sql
-- Usage Success Logic
-- [TO BE IMPLEMENTED]

SELECT
    CLNT_NO,
    -- usage success calculation here
    NULL AS USAGE_SUCCESS
FROM
    -- source table here (e.g., DGNV01.TACTIC_EVNT_IP_AR_HIST)
WHERE
    -- conditions here
;
```

---

## PySpark (Hive)

```python
# Usage Success Logic
# [TO BE IMPLEMENTED]

usage_df = spark.sql("""
    SELECT
        CLNT_NO,
        -- usage success calculation here
        NULL AS USAGE_SUCCESS
    FROM
        -- hive table here (e.g., hive_analytics.tactic_evnt_hist)
    WHERE
        -- conditions here
""")

# Alternative: DataFrame API if needed
# usage_df = spark.table("hive_analytics.tactic_evnt_hist") \
#     .select("CLNT_NO") \
#     .withColumn("USAGE_SUCCESS", lit(None))
```
