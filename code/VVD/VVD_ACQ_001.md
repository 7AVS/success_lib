# VVD_ACQ_001 - Acquisition Success
<!-- Owner: [TO BE ASSIGNED] | Version: v1.0 -->

## Metadata

| Attribute | Value |
|-----------|-------|
| Product | VVD (Virtual Visa Debit) |
| Metric Type | Acquisition |
| Pillar | Conversion |
| Campaigns Using | VCN, VDA |
| Grain | Client |

## Business Definition

[TO BE FILLED]

## Source Tables

[TO BE FILLED]

---

## SQL (Data Warehouse)

```sql
-- Acquisition Success Logic
-- [TO BE IMPLEMENTED]

SELECT
    CLNT_NO,
    -- acquisition success calculation here
    NULL AS ACQUISITION_SUCCESS
FROM
    -- source table here (e.g., DGNV01.TACTIC_EVNT_IP_AR_HIST)
WHERE
    -- conditions here
;
```

---

## PySpark (Hive)

```python
# Acquisition Success Logic
# [TO BE IMPLEMENTED]

acquisition_df = spark.sql("""
    SELECT
        CLNT_NO,
        -- acquisition success calculation here
        NULL AS ACQUISITION_SUCCESS
    FROM
        -- hive table here (e.g., hive_analytics.tactic_evnt_hist)
    WHERE
        -- conditions here
""")

# Alternative: DataFrame API if needed
# acquisition_df = spark.table("hive_analytics.tactic_evnt_hist") \
#     .select("CLNT_NO") \
#     .withColumn("ACQUISITION_SUCCESS", lit(None))
```
