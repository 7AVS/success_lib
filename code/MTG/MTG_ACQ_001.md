# MTG_ACQ_001 - Mortgage Acquisition Success
<!-- Owner: Test User | Version: v1.0 -->

## Metadata

| Attribute | Value |
|-----------|-------|
| Product | MTG (Mortgage) |
| Metric Type | Acquisition |
| Pillar | Conversion |
| Campaigns Using | MCA, MCB |
| Grain | Client |

## Business Definition

Measures successful mortgage origination after campaign exposure.

## Source Tables

- LENDING.MORTGAGE_APPLICATIONS

---

## SQL (Data Warehouse)

```sql
-- Mortgage Acquisition Success Logic
-- [TO BE IMPLEMENTED]

SELECT
    CLNT_NO,
    -- mortgage acquisition success calculation here
    NULL AS MTG_ACQUISITION_SUCCESS
FROM
    LENDING.MORTGAGE_APPLICATIONS
WHERE
    -- conditions here
;
```

---

## PySpark (Hive)

```python
# Mortgage Acquisition Success Logic
# [TO BE IMPLEMENTED]

mtg_acquisition_df = spark.sql("""
    SELECT
        CLNT_NO,
        -- mortgage acquisition success calculation here
        NULL AS MTG_ACQUISITION_SUCCESS
    FROM
        hive_lending.mortgage_applications
    WHERE
        -- conditions here
""")
```
