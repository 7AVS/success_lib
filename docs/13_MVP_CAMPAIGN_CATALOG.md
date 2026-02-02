# MVP Campaign Catalog - Dataset v1 Scope

This document defines the minimum viable set of campaigns for the first iteration of the SuperFact dataset. Every campaign listed here must have its success metric identified, cataloged, and code validated before handoff to the team building the production dataset.

> **Source:** `agent_sessions/pic/IMG_20260130_235531_749.jpg`

---

## Summary

| Metric | Count |
|--------|-------|
| **Total campaigns in scope** | **46** |
| NBO-owned campaigns | 15 |
| NBA-owned campaigns (ours) | 31 |
| NBA campaigns with MISSING success definitions | 5 |
| NBA campaigns with incomplete fields | 2 |

### What needs to happen

- **NBO campaigns (15):** Owned by the NBO team. Their code, their responsibility.
- **NBA campaigns (31):** Owned by us. We must **identify the success metric, catalog it, and run the code** to validate it works before sending it to be included in the production dataset pipeline.
- **5 NBA campaigns** are flagged as **MISSING** their Clean Primary success definition and need resolution before code can be written.

---

## NBA Campaigns by Product (our scope)

| Product | Count | Mnemonics |
|---------|-------|-----------|
| Investments | 6 | TAO, RMG, IDE, GNE, MOS, RAT |
| Mortgage | 4 | FTH, MOM, MRF, MFY |
| PBA | 4 | ESV, PFS, PRA, DAR |
| Loans | 4 | RSS, O2P, RCR, COR |
| Credit Card | 3 | CRV, COB, VBA_LTA |
| Digital Footprint | 3 | NMI, VCN, VAW |
| Payments | 3 | IRI, VUI, IFC |
| Value Program | 1 | PVE |
| Client | 1 | VSX |
| Unassigned | 2 | ZHR, MMT |
| **Total** | **31** | |

### NBA Campaigns by Event Type

| Event Type | Count | Mnemonics |
|------------|-------|-----------|
| Conversion | 12 | ESV, MRF, NMI, RSS, TAO, IDE, ZHR, PFS, PRA, VSX, RCR, VUI |
| Engagement | 10 | RMG, IRI, COB, VAW, GNE, PVE, MOS, MFY, MMT, IFC |
| Acquisition | 5 | FTH, VCN, O2P, CRV, RAT |
| Attrition | 1 | DAR |
| Retention | 1 | MOM |
| N/A | 2 | VBA_LTA, COR |
| **Total** | **31** | |

### Action Items

| Status | Count | Details |
|--------|-------|---------|
| Ready to catalog | 24 | Have Clean Primary defined - code can be written and validated |
| MISSING definition | 5 | VSX, RCR, COR, MFY, MMT - need success metric defined first |
| Incomplete fields | 2 | ZHR (no product/success), MMT (no product) |

---

## Full Campaign Catalog

### NBO Campaigns (15) - NBO Team Owns

| No. | Mnemonic | Description | Event Type | Event Category | Product | Clean Primary | Primary Subset |
|-----|----------|-------------|------------|----------------|---------|---------------|----------------|
| 7 | BOL | Pre-approved Business Operating Line of Credit Opportunity | N/A | | Loans | Business Credit Line Open | |
| 16 | GIS | GIC Exclusive Rate Acquisition | Conversion | Product Open | Investments | Investment Open | GIC |
| 3 | LTA | Pre-approved Royal Credit Line Opportunity (RCL LTA) | Conversion | Product Open | Loans | Royal Credit Line Open | |
| 2 | RCL | Pre-approved Royal Credit Line Opportunity (RCL TPA) | Conversion | Product Open | Loans | Royal Credit Line Open | |
| 4 | RCU | Royal Credit Line - Utilization | Conversion | Product Usage | Loans | Royal Credit Line Balance | $1 |
| 5 | VBA | Pre-approved Business Credit Card Opportunity (VBA TPA) | N/A | | Credit Card | Credit Card Open | Business ASC Matched |
| 24 | CTU | Advantage & Value Program Right Fit Check | Conversion | Product Enhancement | PBA | PBA Upgrade | Target Path |
| 21 | PCD | Credit Card Best Fit Check | Conversion | Product Enhancement | Credit Card | Credit Card Upgrade | Targeted Personal Card Path |
| 9 | PCL | Credit Card Limit Increase Opportunity | Conversion | Product Open | Credit Card | Credit Limit Increase | AR_ID Matched |
| 1 | PCQ | Cards Acquisition | Conversion | Product Open | Credit Card | Credit Card Open | Personal ASC Matched |
| 11 | PPQ | Personal Bank Account Opportunity | Conversion | Product Open | PBA | PBA Open | Chequing |
| 22 | TFP | TFSA and RRSP Grow with a PAC | Conversion | Product Usage | Investments | PAC Start | *Min duration TBD* |
| 14 | VBU | Business Cards Upgrade | N/A | Product Enhancement | Credit Card | Credit Card Upgrade | Targeted Business Card Path |
| 28 | EBR | PBA Value Program | Conversion | Product Open | Value Program | Value Program Enrollment | |
| 19 | RPB | PBA Client Retention Check-in | Attrition | Product Retention | PBA | PBA Open | Status = Active/Open at 180 days |

---

### NBA Campaigns (31) - Our Scope

These are the campaigns we own. Each one needs its success metric identified, code written, and validated.

#### Ready to Catalog (24)

| No. | Mnemonic | Description | Event Type | Event Category | Product | Clean Primary | Primary Subset |
|-----|----------|-------------|------------|----------------|---------|---------------|----------------|
| 44 | FTH | First Time Homebuyer with FHSA | Acquisition | Product Open | Mortgage | | |
| 43 | MOM | Mortgage 1 Year from Maturity Touchpoint | Retention | Product Retention | Mortgage | Mortgage Retained | Past Maturity |
| 10 | ESV | New eSavings Bonus Interest Offer | Conversion | Product Open | PBA | PBA Open | HISA |
| 13 | MRF | Mortgage Refinance Advice Opportunity | Conversion | | Mortgage | Mortgage Refinance | |
| 23 | NMI | NOAM Find & Save | Conversion | Product Open | Digital Footprint | NOAM Open | |
| 9 | RSS | RCL Balance Stimulation | Conversion | Product Usage | Loans | Royal Credit Line Balance | $1 |
| 25 | TAO | Tax Free Savings Account Opportunity | Conversion | Product Open | Investments | Investment Open | TFSA, RRSP |
| 32 | RMG | GIC - Maturity | Engagement | Product Open | Investments | GIC Renewal | |
| 34 | VCN | VVD Acquisition Mobile Banner | Acquisition | Product Enhancement | Digital Footprint | Virtual Visa Debit Activation | |
| 35 | IRI | International Remittance | Engagement | Product Action | Payments | International Money Transfer | IMT Transaction |
| 45 | O2P | Pre-approved Overdraft Opportunity | Acquisition | Product Open | Loans | Overdraft Open | |
| 46 | CRV | Credit Card Installment Plan Offer | Acquisition | Product Usage | Credit Card | Installment Purchase | >$0 |
| 15 | IDE | Invest and Trade Online Services | Conversion | Product Open | Investments | Investment Open | Direct Investing or InvestEase (GoSmart) |
| 6 | VBA_LTA | Pre-approved Business Credit Card Opportunity (VBA LTA) | N/A | Product Open | Credit Card | Credit Card Open | Business ASC Matched |
| 17 | PFS | PBA Funding Strategy | Conversion | Product Usage | PBA | Funding | >$25 PBA Account Credit |
| 18 | PRA | Personal Account Opened in Restraint | Conversion | Product Open | PBA | PBA Open | Status Change out of Restraint |
| 20 | DAR | Dormant Account Reactivation | Attrition | Product Retention | PBA | PBA Open | Status = Inactive to Active |
| 29 | COB | Cards Onboarding | Engagement | Product Enhancement | Credit Card | Credit Card Activation | |
| 30 | VAW | VVD Mobile App Acquisition Contextual Notification | Engagement | Product Enhancement | Digital Footprint | Digital Wallet | Virtual Visa Debit |
| 31 | GNE | Explore & Continue GIC Journey | Engagement | Product Open | Investments | All GIC >$0 (ins and outs) | |
| 36 | VUI | VVD Usage Increase Trigger | Conversion | Product Usage | Payments | Virtual Visa Debit Transaction | ~$0 |
| 37 | PVE | Value Program Enrollment | Engagement | Product Open | Value Program | Product Cross-Sell | |
| 38 | MOS | Investments Advice Connect | Engagement | Product Usage | Investments | Positive Long-Term Net Sales | RESP |
| 39 | RAT | Explore Education Saving Options | Acquisition | Product Open | Investments | Investment Open | |

#### Needs Success Definition (5 MISSING + 2 Incomplete)

These campaigns cannot have code written until their success metrics are defined.

| No. | Mnemonic | Description | Event Type | Product | Clean Primary | Issue |
|-----|----------|-------------|------------|---------|---------------|-------|
| 26 | VSX | Value Ecosystem Engagement | Conversion | Client | **MISSING** | No success definition |
| 27 | RCR | RCL Price Optimization | Conversion | Loans | **MISSING** | No success definition |
| 33 | COR | Student RCL - Confirmation of Repayment Terms | N/A | Loans | **MISSING** | No success definition, no event type |
| 40 | MFY | New Mortgage Touchpoint | Engagement | Mortgage | **MISSING** | No success definition |
| 41 | MMT | Mortgage Milestone Touchpoint | Engagement | *(empty)* | **MISSING** | No success definition, no product |
| 12 | ZHR | Client Relationship Retention | Conversion | *(empty)* | *(empty)* | No product, no success, no category |
| 42 | IFC | International Money Transfer Winback Campaign | Engagement | Payments | International Money Transfer | IMT Transaction — *verify if complete* |

---

## Workflow: From This Catalog to Production

```
For each NBA campaign:

  1. IDENTIFY    → Confirm the Clean Primary success metric
                   (resolve MISSING items first)

  2. CATALOG     → Write the success metric code
                   (SQL/PySpark in the Success Library format)

  3. VALIDATE    → Run the code against data to verify it works

  4. HAND OFF    → Send validated code to the team building
                   the production dataset pipeline
```

---

## Cross-Reference: Products x Event Types (NBA only)

|  | Acquisition | Retention | Conversion | Engagement | Attrition | N/A |
|--|-------------|-----------|------------|------------|-----------|-----|
| **Mortgage** | FTH | MOM | MRF | MFY* | | |
| **PBA** | | | ESV, PFS, PRA | | DAR | |
| **Investments** | RAT | | TAO, IDE | RMG, GNE, MOS | | |
| **Loans** | O2P | | RSS, RCR* | | | COR*, VBA_LTA |
| **Credit Card** | CRV | | | COB | | |
| **Digital Footprint** | VCN | | NMI | VAW | | |
| **Payments** | | | VUI | IRI, IFC | | |
| **Value Program** | | | VSX* | PVE | | |
| **Other/Missing** | | | ZHR* | MMT* | | |

*Asterisk = has MISSING or incomplete success definition*
