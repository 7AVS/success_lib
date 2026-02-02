# VVD_PRV_001 - Wallet Provisioning
<!-- Owner: Marketing Analytics | Version: v1.0 | Last Validated: 2026-01-24 -->

## Metadata

| Attribute | Value |
|-----------|-------|
| Product | VVD (Virtual Visa Debit) |
| Metric Type | Provisioning |
| Pillar | Conversion |
| Campaigns Using | VAW, VUI, VUT |
| Grain | Client |
| Date Field | TXN_DT |
| Source | EDW |

## Business Definition

Client provisioned their VVD card to a digital wallet (Apple Pay, Google Pay, Samsung Pay, etc.).

**Success Criteria:**
- Token registration event with wallet indicator
- Specific card prefixes (45190, 45199) for VVD cards
- Token requestor ID is valid (not zero)
- VVD product (`SRVC_CD = 36`)

**Digital Wallets Included:**
- Apple Pay
- Google Pay
- Samsung Pay
- Other wallets identified by `TOKEN_WALLET_IND = 'Y'`

## Source Tables

| Table | Environment | Description |
|-------|-------------|-------------|
| DDWV05.CLNT_CRD_POS_LOG | EDW | Card transaction log |
| DL_DECMAN.TOKEN_LIST | EDW | Token registry with wallet indicators |

## Filter Logic

| Field | Condition | Reason |
|-------|-----------|--------|
| AMT1 | = 0 | Provisioning events have zero amount |
| CLNT_CRD_NO prefix | = '45190' | VVD card identifier |
| VISA_DR_CRD_NO prefix | = '45199' | VVD card verification |
| TOKN_REQSTR_ID | First char > '0' | Valid token requestor |
| POS_ENTR_MODE_CD_NON_EMV | = '000' | Token provisioning mode |
| SRVC_CD | = 36 | VVD product |
| TOKEN_WALLET_IND | = 'Y' | Confirmed wallet token |

## Client Extraction

**Important:** Client number must be extracted from the card number:

```
CLNT_NO = CAST(SUBSTR(CLNT_CRD_NO, 7, 9) AS INTEGER)
```

---

## PySpark (Hive)

```python
# VVD_PRV_001: Wallet Provisioning Success
# Source: VVD Vintage Engine v2.3
# Validated: 2026-01-24
# NOTE: This metric uses EDW, not Hive. PySpark creates DataFrame from EDW query result.

import pandas as pd
from pyspark.sql import functions as F

# This metric requires EDW connection
# EDW = teradata connection object (established elsewhere)

def load_wallet_provisioning_from_edw():
    """Load wallet provisioning data from EDW."""

    query = """
    SELECT DISTINCT
        CAST(SUBSTR(B.CLNT_CRD_NO, 7, 9) AS INTEGER) AS CLNT_NO,
        B.TXN_DT
    FROM DDWV05.CLNT_CRD_POS_LOG AS B
    INNER JOIN DL_DECMAN.TOKEN_LIST C
        ON B.TOKN_REQSTR_ID = C.TOKEN_ID
    WHERE B.AMT1 = 0
        AND SUBSTR(B.CLNT_CRD_NO, 1, 5) = '45190'
        AND SUBSTR(B.VISA_DR_CRD_NO, 1, 5) = '45199'
        AND SUBSTR(B.TOKN_REQSTR_ID, 1, 1) > '0'
        AND B.POS_ENTR_MODE_CD_NON_EMV = '000'
        AND B.SRVC_CD = 36
        AND C.TOKEN_WALLET_IND = 'Y'
    """

    cursor = EDW.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]
    cursor.close()

    return pd.DataFrame(rows, columns=columns)

# Load from EDW
provisioning_pdf = load_wallet_provisioning_from_edw()

# Convert to Spark DataFrame
provisioning_df = spark.createDataFrame(provisioning_pdf)

# Standardize column names
provisioning_df = provisioning_df.select(
    F.col("CLNT_NO").cast("string").alias("CLNT_NO"),
    F.col("TXN_DT").alias("SUCCESS_DT")
)

# Result: DataFrame with CLNT_NO, SUCCESS_DT
# Join with tactic data where SUCCESS_DT BETWEEN TREATMT_STRT_DT AND TREATMT_END_DT
```

---

## SQL (EDW - Teradata)

```sql
-- VVD_PRV_001: Wallet Provisioning Success
-- Environment: EDW (Teradata)
-- This is the production query used by the Vintage Engine

SELECT DISTINCT
    CAST(SUBSTR(B.CLNT_CRD_NO, 7, 9) AS INTEGER) AS CLNT_NO,
    B.TXN_DT AS SUCCESS_DT
FROM DDWV05.CLNT_CRD_POS_LOG AS B
INNER JOIN DL_DECMAN.TOKEN_LIST C
    ON B.TOKN_REQSTR_ID = C.TOKEN_ID
WHERE
    B.AMT1 = 0                                    -- Provisioning events
    AND SUBSTR(B.CLNT_CRD_NO, 1, 5) = '45190'    -- VVD card prefix
    AND SUBSTR(B.VISA_DR_CRD_NO, 1, 5) = '45199' -- VVD verification
    AND SUBSTR(B.TOKN_REQSTR_ID, 1, 1) > '0'     -- Valid token requestor
    AND B.POS_ENTR_MODE_CD_NON_EMV = '000'       -- Token mode
    AND B.SRVC_CD = 36                           -- VVD product
    AND C.TOKEN_WALLET_IND = 'Y'                 -- Wallet token confirmed
;
```

---

## Integration Notes

**For Vintage Engine:**
- This metric is used as:
  - PRIMARY for campaigns: VAW, VUT
  - SECONDARY for campaign: VUI
- **Source is EDW, not Hive** - requires Teradata connection
- Join on `CLNT_NO` with tactic data
- Success window: `SUCCESS_DT BETWEEN TREATMT_STRT_DT AND TREATMT_END_DT`
- Aggregation: First provisioning date per client

**EDW Connection:**
The engine establishes EDW connection via:
```python
import teradata
EDW = teradata.connect(...)
```

**Engine Reference:**
```python
# In vintage_engine_v2.3.py, this metric is defined as:
SUCCESS_DEFINITIONS["wallet_provisioning"] = {
    "source": "EDW",
    "table_path": None,  # EDW uses direct query, not path
    "date_field": "TXN_DT",
    "client_field": "CLNT_NO",
    "filters": None  # Filters embedded in SQL query
}
```

**Why EDW instead of Hive?**
- Token data (`DL_DECMAN.TOKEN_LIST`) is only available in EDW
- Wallet indicator (`TOKEN_WALLET_IND`) is maintained in EDW token registry
- Join between POS log and token list is more efficient in EDW

---

## Change Log

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2026-01-24 | v1.0 | Initial production code from VVD Vintage Engine v2.3 | Marketing Analytics |
