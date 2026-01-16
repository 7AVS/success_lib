# VVD_ACT_001 - Activation Success
<!-- Owner: [TO BE ASSIGNED] | Version: v1.0 -->

## Metadata

| Attribute | Value |
|-----------|-------|
| Product | VVD (Virtual Visa Debit) |
| Metric Type | Activation |
| Pillar | Conversion |
| Campaigns Using | VDT |
| Grain | Client |

## Business Definition

[TO BE FILLED]

## Source Tables

[TO BE FILLED]

---

## SQL (Data Warehouse)

```sql
-- Activation Success Logic
-- [TO BE IMPLEMENTED]

SELECT
    CLNT_NO,
    -- activation success calculation here
    NULL AS ACTIVATION_SUCCESS
FROM
    -- source table here (e.g., DGNV01.TACTIC_EVNT_IP_AR_HIST)
WHERE
    -- conditions here
;
```

---

## PySpark (Hive)

```python
# Activation Success Logic
# [TO BE IMPLEMENTED]

activation_df = spark.sql("""
    SELECT
        CLNT_NO,
        -- activation success calculation here
        NULL AS ACTIVATION_SUCCESS
    FROM
        -- hive table here (e.g., hive_analytics.tactic_evnt_hist)
    WHERE
        -- conditions here
""")

# Alternative: DataFrame API if needed
# activation_df = spark.table("hive_analytics.tactic_evnt_hist") \
#     .select("CLNT_NO") \
#     .withColumn("ACTIVATION_SUCCESS", lit(None))
```
