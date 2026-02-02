# Strategic Vision Boards

This document captures the strategic planning boards from the whiteboard session (2026-01-31). These include the project roadmap, current-state impact analysis, and the experimentation tracking evolution narrative.

> **Source:** Whiteboard photos in `agent_sessions/pic/PXL_20260131_*`

---

## 1. Evolving Experimentation Tracking

A before/after comparison of three systemic problems the SuperFact initiative addresses.

### Traceability

| | Description |
|---|---|
| **Before** | No centralized tracking of in-market and past experiments creates gaps in traceability, leading to inefficiencies and data debt for all collaborating teams. |
| **After** | Centralized database of all in-market and past experiments, with additional documentation regarding purpose, design, and inference method. |

### Reportability

| | Description |
|---|---|
| **Before** | Test group logic and client targeting documentation are inconsistently stored across multiple platforms: Confluence, spreadsheets, or informal communication channels. |
| **After** | Consolidated additional data required for reporting is prepopulated as of campaign deployment to assist in generating Day 1 reporting. |

### Silos

| | Description |
|---|---|
| **Before** | Inconsistent methodologies and design flaws compromise data quality, resulting in unreliable outcomes. |
| **After** | With the single experimentation framework and the above two corrections, the governance on data quality will significantly improve the reporting and its speed to market. |

---

## 2. Current State and Impact

A detailed before/after analysis showing operational pain points and how the SuperFact architecture resolves each one.

### Experiment Measurement

| | Description |
|---|---|
| **Before** | Manual data transformations for E2E, from design to report back. Teams identify target and test population through tactic history and strategy codes — not documented in databases. Identify and QA 100s of unique success metrics and logic on ad hoc basis. |
| **After** | All transformations standardized and automated with experiments and success pre-determined to create daily report back for measurement and MVP. Once the official process is established, all deployed campaigns will follow this procedure which will mean no downstream debt on the measurement team. This will also increase speed to market dramatically as all reporting will be set up Day 1 of launch and repeat daily. |

### Vintage and Daily Trending

| | Description |
|---|---|
| **Before** | Majority of measurement is at end of experiment so queries need to be adapted to be able to create daily trending. Due to previous requirements, queries largely leveraged month-end data which meant many processes are not equipped to report back daily. The need did not exist previously so many data assets may not have a daily equivalent. |
| **After** | With the daily capability on-by-default, trendlines will also be available on demand. No additional effort required to populate the trendlines, and dashboards will have it readily available. |

### One Pagers and Documentation

| | Description |
|---|---|
| **Before** | Due to non-standard practices in deployments and experiment designs, documentation is scattered and generally not available on demand. Experimentation team currently needs to spend effort to identify test and treatment groups through word of mouth or hidden documents which normally sat in a tech spec. If the document exists, the logic needed to be converted to SQL which is prone to error due to the various methods of implementing a campaign. |
| **After** | All test groups and experiments will be documented as part of the creation and deployment process, hosted inside a database for consistency. Since all documentation will be in databases in an identical format, all required information is readily available for all users with access to the data asset. |

---

## 3. Roadmap

A three-horizon roadmap for the SuperFact platform build-out.

### Short Term (ending January)

| # | Workstream | Details | Dependencies |
|---|-----------|---------|--------------|
| 1 | **Stand up Metadata / Datasets** | MVP/POC — have working demo to show in next design review | Organic Required: Body metrics, NBO Queries |
| 2 | **Core TODO: Success Events** | Build the success_events base table | Organic not Required: Copy / Variable Datasets |
| 3 | **AWS** | Cloud infrastructure setup | "Do you even want to bring up P3?" |

**Key Deliverable:** All queries can be leveraged from metadata tables.

### Medium Term (6+ months)

| Workstream | Details |
|-----------|---------|
| **E2E Campaign Results to Customer View** | End-to-end pipeline from campaign to customer-level view |
| **Orchestration** | Airflow, Digiplex |
| **Transformations** | dbt, Spark SQL |
| **Storage** | S3 |
| **CDC** | Change Data Capture for Near-Time Ingestion |

### Long Term (12+ months)

| Workstream | Details |
|-----------|---------|
| **Streaming / Real-time Loading** | Real-time data pipeline |
| **Orchestration** | Digiplex |
| **Transformations** | dbt, Spark SQL |
| **Storage** | Iceberg, Snowflake |
| **Compute** | Amazon Redshift |

### Open Questions (from sticky notes)

1. "Can we have some time estimation on manual data pull and manual vintage?"
2. "How can we update the MNE V2 table and Experiment Metadata as interim?"

---

## Summary: How These Boards Connect

```
Evolving Experimentation Tracking     Current State and Impact          Roadmap
(THE WHY)                             (THE WHAT)                        (THE WHEN)
─────────────────────────             ────────────────────────          ─────────────

Traceability gaps          ──▶        Experiment Measurement pain  ──▶  Short Term: Metadata + Events
Reportability gaps         ──▶        Vintage & Daily Trending     ──▶  Medium Term: E2E + Orchestration
Silo problems              ──▶        One Pagers & Documentation   ──▶  Long Term: Streaming + Snowflake
```

The three boards tell a coherent story:
- **Evolving Experimentation Tracking** frames the organizational problems (why we need this)
- **Current State and Impact** details the specific operational pain and the target state (what changes)
- **Roadmap** lays out the phased delivery plan (when it gets built)
