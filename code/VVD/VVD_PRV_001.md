# VVD_PRV_001 - Provisioning Success
<!-- Owner: [TO BE ASSIGNED] | Version: v1.0 -->

## Metadata

| Attribute | Value |
|-----------|-------|
| Product | VVD (Virtual Visa Debit) |
| Metric Type | Provisioning |
| Pillar | Conversion |
| Campaigns Using | VAW, VUI |
| Grain | Client |

## Business Definition

[TO BE FILLED]

## Source Tables

[TO BE FILLED]

---

## SQL (Data Warehouse)

```sql
-- Provisioning Success Logic
-- [TO BE IMPLEMENTED]

SELECT
    CLNT_NO,
    -- provisioning success calculation here
    NULL AS PROVISIONING_SUCCESS
FROM
    -- source table here (e.g., DGNV01.TACTIC_EVNT_IP_AR_HIST)
WHERE
    -- conditions here
;
```

---

## PySpark (Hive)

```python
# Provisioning Success Logic
# [TO BE IMPLEMENTED]

provisioning_df = spark.sql("""
    SELECT
        CLNT_NO,
        -- provisioning success calculation here
        NULL AS PROVISIONING_SUCCESS
    FROM
        -- hive table here (e.g., hive_analytics.tactic_evnt_hist)
    WHERE
        -- conditions here
""")

# Alternative: DataFrame API if needed
# provisioning_df = spark.table("hive_analytics.tactic_evnt_hist") \
#     .select("CLNT_NO") \
#     .withColumn("PROVISIONING_SUCCESS", lit(None))
```
