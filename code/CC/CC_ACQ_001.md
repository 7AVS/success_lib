# CC_ACQ_001 - Credit Card Acquisition Success
<!-- Owner: Jane Doe | Version: v1.0 -->

## Metadata

| Attribute | Value |
|-----------|-------|
| Product | CC (Credit Card) |
| Metric Type | Acquisition |
| Pillar | Conversion |
| Campaigns Using | CCA, CCB, CCC |
| Grain | Client |

## Business Definition

Measures successful credit card acquisition after campaign exposure.

## Source Tables

- DGNV01.TACTIC_EVNT_IP_AR_HIST
- CARDS.CC_APPLICATIONS

---

## SQL (Data Warehouse)

```sql
-- Credit Card Acquisition Success Logic
-- [TO BE IMPLEMENTED]

SELECT
    CLNT_NO,
    -- credit card acquisition success calculation here
    NULL AS CC_ACQUISITION_SUCCESS
FROM
    DGNV01.TACTIC_EVNT_IP_AR_HIST t
    LEFT JOIN CARDS.CC_APPLICATIONS a ON t.CLNT_NO = a.CLNT_NO
WHERE
    -- conditions here
;
```

---

## PySpark (Hive)

```python
# Credit Card Acquisition Success Logic
# [TO BE IMPLEMENTED]

cc_acquisition_df = spark.sql("""
    SELECT
        CLNT_NO,
        -- credit card acquisition success calculation here
        NULL AS CC_ACQUISITION_SUCCESS
    FROM
        hive_analytics.tactic_evnt_hist t
        LEFT JOIN hive_cards.cc_applications a ON t.CLNT_NO = a.CLNT_NO
    WHERE
        -- conditions here
""")
```
