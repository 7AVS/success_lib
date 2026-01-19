# Success Library (SuperFact): Executive Summary

## The Challenge

Marketing Analytics manages **200-300 active campaigns** with no single source of truth for success measurement:

| Problem | Business Impact |
|---------|-----------------|
| Metrics defined ad-hoc per experiment | Inconsistent results across similar campaigns |
| Success definitions scattered across tech specs, Confluence, spreadsheets | No auditability when results are questioned |
| Manual data extraction via SAS | Slow, error-prone, not scalable |
| No linkage from experiment design to reporting | Weeks spent recreating the same metrics |

**The core question we cannot answer today:** "Here's what Cross-Sell means, here's how it's calculated" - consistently from design through to reporting.

---

## The Solution: Four-Layer Semantic Architecture

SuperFact establishes a governed data architecture that connects experiment design to dashboards:

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         SUPERFACT ARCHITECTURE                             │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  LAYER 1                    LAYER 2                    LAYER 3             │
│  ┌──────────────┐          ┌──────────────┐          ┌──────────────┐     │
│  │  GOVERNED    │          │   MANAGED    │          │   SUCCESS    │     │
│  │  EXPERIMENT  │    →     │   CAMPAIGN   │    →     │   LIBRARY    │     │
│  │  METADATA    │          │   METADATA   │          │              │     │
│  │              │          │  (Mnemonic   │          │  Centralized │     │
│  │  Who is in   │          │  Mapping V2) │          │  Logic Repo  │     │
│  │  the test?   │          │              │          │              │     │
│  │              │          │  What to     │          │  How to      │     │
│  │              │          │  measure?    │          │  calculate?  │     │
│  └──────────────┘          └──────────────┘          └──────────────┘     │
│         │                         │                         │              │
│         └─────────────────────────┼─────────────────────────┘              │
│                                   ↓                                        │
│                          ┌──────────────┐                                  │
│                   LAYER 4│   CLIENT     │                                  │
│                          │   MARKETING  │                                  │
│                          │  INTERACTION │→ DASHBOARDS → INSIGHTS           │
│                          │   JOURNEY    │                                  │
│                          └──────────────┘                                  │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

### Layer 1: Governed Experiment Metadata
Links experiments to clients using Tactic History fields (Report Group Code, Treatment Meaning, Test Group, Tactic ID). Enables traceability from experiment design to client-level outcomes.

### Layer 2: Managed Campaign Metadata (Mnemonic Mapping V2)
Classifies campaigns and maps them to success metrics. When a campaign is created, Primary/Secondary/Tertiary metrics are selected from the governed library - not defined ad-hoc.

### Layer 3: Success Library (Current Focus)
GitHub-based repository containing standardized SQL/PySpark code for each metric. Like LEGO bricks - consistent connectors enable limitless joins. Campaign metadata points to the right calculation logic.

### Layer 4: Client Marketing Interaction Journey
Maps end-to-end client touchpoints from decision to fulfillment. Enables accurate measurement of treatment effect and funnel analysis.

---

## Source of Truth Metrics Library

Five core measurement pillars with pre-defined, governed metrics:

| Pillar | Example Metrics |
|--------|-----------------|
| **Conversion** | Cheque Account Opening, Credit Card Opening, Mortgage Funded, Loan Approved |
| **Share of Wallet** | Utilization, Avg Balance, PAC Indicator, Number of Transactions |
| **Engagement** | Email Unsubscribe Rate, Banner View Rate, Mobile Logins, Branch Visits |
| **Retention** | Account Closure, Client Attrition, Change in Products/Services |
| **Profitability** | Account Level, Client Level |

### NBA OKRs (On-by-Default Metrics)
These run automatically for all campaigns:
- Attrition
- 2 or More Products
- Engagement Score >30
- New Products

### Digital Footprint Metrics
- Thumbs Up
- Email Unsubscribe

---

## Vision: Final Data Output

When all layers are connected, every campaign automatically produces:

| Campaign | Experiment | Primary | Secondary | Tertiary | Attrition | 2+ Products | Engagement | New Products |
|----------|------------|---------|-----------|----------|-----------|-------------|------------|--------------|
| FTH: FHSA Lead | Expansion | Mortgage Funded 4% | Application Started 6% | Appointment 10% | 1% | 30% | 40% | 0.1 |
| MVP: TPA Nurture | Education | Card Open 0.4% | N/A | N/A | 1% | 20% | 45% | 0.1 |

**Cross-campaign patterns emerge:** With standardized metrics, insights like "opening a new mortgage results in fewer PACs" become discoverable.

---

## Current State vs Future State

| Dimension | Current State | Future State |
|-----------|---------------|--------------|
| **Traceability** | No centralized tracking; data debt across teams | Centralized database with full lineage from design to results |
| **Reportability** | Manual hunting across Confluence, spreadsheets | Day 1 reporting enabled; data prepopulated before deployment |
| **Speed to Market** | Weeks of manual data prep per campaign | Governance enables automated, reliable outcomes |
| **Measurement** | Manual end-to-end transformations | Automated Day 1 reporting; daily trending by default |
| **Documentation** | Scattered, inconsistent, not on-demand | Test groups and experiments documented as part of deployment |

---

## Technology Roadmap

| Timeframe | Platform | Status |
|-----------|----------|--------|
| **Short Term** | Teradata Datalab | Current working environment |
| **Medium Term (6+ months)** | Airflow/Dagster + Spark SQL + AWS S3 | Orchestration and transformation |
| **Long Term (12+ months)** | Snowflake Analytics Layer (or Redshift) | Enterprise-scale analytics |

**Design Principle:** Build on existing infrastructure but architect for portability. The solution remains platform-agnostic with high accessibility for seamless adoption across skill levels.

---

## Current Scope: Success Library (Layer 3)

We are building the **Centralized Logic Repository** - the GitHub-based success metric definitions:

### What's Delivered
- **Metric Catalog:** Searchable HTML index of all governed metrics
- **Dual Implementation:** SQL (Data Warehouse) and PySpark (Hive) code for each metric
- **Intake Workflow:** Excel-based submission process for new metrics
- **Governance:** Version control, audit trail, clear ownership

### What's In Place
| Component | Status |
|-----------|--------|
| Metric metadata index (JSON) | Complete |
| Code files per metric (SQL + PySpark) | Complete |
| HTML index with search/filter | Complete |
| Intake template and processing | Complete |
| Git version control | Complete |

### Initial Metrics Catalogued
6 metrics across 3 products (VVD, CC, MTG) covering Acquisition, Activation, Usage, and Provisioning.

---

## Impact Areas

The fully-developed SuperFact framework enables:

1. **Real-time ADT Value Capture** - Immediate visibility into campaign performance
2. **Faster MBR / QBR / PowerPack / Vintages** - Automated recurring reports
3. **MVP Feedback Loop** - Data-driven iteration on campaigns
4. **Quicker Deep Dives** - Skip manual data prep, start with clean ETL
5. **Dashboard Foundation** - Direct feed to Tableau visualization layer
6. **Future LLM Integration** - Clean metadata enables natural language querying

---

## Resource Requirements

| Phase | Resources Needed |
|-------|------------------|
| **Current (Success Library)** | Analytics team maintains catalog |
| **Intermediate (2 Quarters)** | Data Engineering to build automated pipelines |
| **Long Term (3 Quarters)** | Data Engineering + BI + dedicated pipeline/dashboard manager |

---

## Recommendations

1. **Executive Sponsorship** - Organization-wide mandate to use governed metrics
2. **Adoption Campaign** - Onboard analytics teams to reference the library
3. **Metric Expansion** - Extend coverage beyond initial 6 metrics to all products
4. **Integration Roadmap** - Connect Layer 2 (Mnemonic Mapping V2) and Layer 4 (Journey)
5. **Data Engineering Investment** - Required to move from manual to automated pipelines

---

## Summary

The Success Library is the **governance backbone** of the SuperFact architecture. By standardizing "what success means" and "how it's calculated," we eliminate ad-hoc metric creation, enable Day 1 reporting, and create the foundation for automated, trustworthy campaign measurement at scale.

**Current focus:** Layer 3 - Centralized Logic Repository
**Next integration:** Layer 2 (Campaign Metadata) and Layer 4 (Client Journey)
**End state:** Design of Experiments → Success Library → Dashboards - fully connected

---

*For detailed operational procedures, see: Operations Guide*
*For technical architecture decisions, see: DESIGN_DECISIONS.md*
