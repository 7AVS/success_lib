# Success Library - Current State

This document maps the original SuperFact vision to what has been built, what's pending, and how the pieces connect.

---

## The Big Picture: Four-Layer Architecture

The SuperFact initiative is a four-layer semantic architecture designed to standardize marketing campaign measurement:

| Layer | Name | Purpose | Key Question |
|-------|------|---------|--------------|
| 1 | Governed Experiment Metadata | Links experiments to clients using Tactic History fields | "Who is in the test?" |
| 2 | Managed Campaign Metadata (Mnemonic Mapping V2) | Classifies campaigns and maps them to success metrics | "What should we measure?" |
| 3 | Centralized Logic Repo (Success Library) | GitHub-based repository with standardized SQL/PySpark code | "How do we calculate it?" |
| 4 | Client Marketing Interaction Journey | Maps client touchpoints from decision to fulfillment | "What did the client actually do?" |

**End Goal:** These layers connect so that campaign measurement flows automatically from experiment design → calculation logic → dashboards.

---

## What Has Been Built

**Focus: Layer 3 - Success Library (Infrastructure/Framework)**

The current implementation establishes the governance framework for Layer 3. This is the container that will hold metric definitions - the structure is built, content is placeholder.

### Components Built

| Component | File/Location | Purpose | Status |
|-----------|---------------|---------|--------|
| Metric Catalog | `metadata/success_library_index.json` | Central index of all metrics with metadata | Structure complete |
| Code Storage | `code/{PRODUCT}/{METRIC_ID}.md` | SQL + PySpark logic per metric | Structure complete, logic placeholder |
| Browsable Interface | `index.html` | Search, filter, view metrics and code | Complete |
| HTML Generator | `build.py` | Generates index.html from JSON + code files | Complete |
| Intake Processor | `excel_to_json.py` | Processes analyst submissions into JSON | Complete |
| Intake Workflow | `intake/` folder structure | Pending → Processed pattern | Complete |
| Documentation | `docs/`, `README.md` | Design decisions, usage instructions | Complete |

### Initial Metrics Catalogued

6 metrics across 3 products (placeholder logic):

| Product | Metrics |
|---------|---------|
| VVD (Virtual Visa Debit) | VVD_ACQ_001, VVD_ACT_001, VVD_USG_001, VVD_PRV_001 |
| CC (Credit Card) | CC_ACQ_001 |
| MTG (Mortgage) | MTG_ACQ_001 |

---

## How Layers Connect

The **`metric_id`** (e.g., `VVD_ACQ_001`) and **`metric_name`** (human-readable) serve as the universal identifiers that connect all four layers.

```
LAYER 1: Experiment Metadata
    │
    │  "Experiment X uses metric_id = VVD_ACQ_001"
    ▼
LAYER 2: Campaign Metadata (Mnemonic Mapping V2)
    │
    │  "Campaign Y has Primary Metric = VVD_ACQ_001"
    ▼
LAYER 3: SUCCESS LIBRARY  ◄── CURRENT FOCUS
    │
    │  "VVD_ACQ_001 is calculated using this SQL/PySpark"
    ▼
LAYER 4: Client Journey + Dashboards
    │
    │  "Results for metric_id = VVD_ACQ_001"
    ▼
    REPORTING
```

**The metric_id is the key.** When all layers are connected:
1. Layer 1 tags clients to experiments
2. Layer 2 declares which metrics a campaign uses (by metric_id)
3. Layer 3 provides the calculation logic (looked up by metric_id)
4. Layer 4 applies the logic to journey data and outputs results

---

## Current State vs Future State

### Data Sources

| State | Approach |
|-------|----------|
| **Current** | Code references source-of-truth tables directly (EDW, EDL) |
| **Future** | Curated data warehouse with pre-calculated metrics; Success Library becomes reference documentation for what those metrics mean |

The placeholder code in Layer 3 will initially run against raw source tables. The long-term vision is a curated layer where metrics are pre-calculated on a schedule. When that exists, the Success Library code becomes the audit trail / lineage documentation.

### Layer Status

| Layer | Status | Notes |
|-------|--------|-------|
| Layer 1: Experiment Metadata | Not built | Conceptual - described in design doc |
| Layer 2: Campaign Metadata | Not built | Conceptual - Mnemonic Mapping V2 not implemented |
| **Layer 3: Success Library** | **Framework built** | Infrastructure complete, content placeholder |
| Layer 4: Client Journey | Not built | Conceptual - described in design doc |

---

## What's Pending

### 1. Layer 3 Content (Success Library)

The framework exists but needs to be populated with actual content:

| Item | Status | Notes |
|------|--------|-------|
| Business definitions | Placeholder | Plain English descriptions of what each metric measures |
| SQL logic (Data Warehouse) | Placeholder | Actual queries against EDW tables |
| PySpark logic (Hive) | Placeholder | Actual queries against EDL/Hive tables |
| Source table mappings | Placeholder | Which tables feed each metric |
| Measurement windows | Not defined | Days post-treatment for each metric |
| Metric owners | Not assigned | Who maintains each metric definition |

### 2. Content Population Process (To Be Defined)

Two potential approaches:

| Approach | Description | Considerations |
|----------|-------------|----------------|
| A. Analyst-driven | Analysts populate metrics for their respective portfolios via intake workflow | Requires coordination, training on intake process |
| B. Centralized | Single person catalogs all products and campaigns | More consistent, but bottleneck on one person |

**Decision pending.** May need hybrid approach or phased rollout.

### 3. Dashboard Handoff

| Aspect | Status |
|--------|--------|
| Responsible team | Different team (not Success Library team) |
| Handoff | Not initiated |
| Challenges | Not yet discussed |
| Gap | Dashboard team uses SAS/SQL, cannot read from Hive |

This requires cross-team coordination to resolve. The Success Library can output data, but the format and delivery mechanism for the dashboard team is undefined.

### 4. Validation Against Real Data

The placeholder code has not been tested against actual Teradata/Hive tables. Before metrics go "live," each needs:
- SQL tested against Data Warehouse
- PySpark tested against Hive
- Results validated by business owner

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SUPERFACT ARCHITECTURE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   LAYER 1                    LAYER 2                    LAYER 3             │
│   ┌──────────────┐          ┌──────────────┐          ┌──────────────┐     │
│   │  GOVERNED    │          │   MANAGED    │          │   SUCCESS    │     │
│   │  EXPERIMENT  │          │   CAMPAIGN   │          │   LIBRARY    │     │
│   │  METADATA    │    →     │   METADATA   │    →     │              │     │
│   │              │          │  (Mnemonic   │          │  metric_id   │     │
│   │  NOT BUILT   │          │  Mapping V2) │          │  = key       │     │
│   │              │          │              │          │              │     │
│   │              │          │  NOT BUILT   │          │  FRAMEWORK   │     │
│   │              │          │              │          │  BUILT ✓     │     │
│   └──────────────┘          └──────────────┘          └──────────────┘     │
│          │                         │                         │              │
│          └─────────────────────────┼─────────────────────────┘              │
│                                    ↓                                        │
│                           ┌──────────────┐                                  │
│                    LAYER 4│   CLIENT     │                                  │
│                           │   MARKETING  │                                  │
│                           │  INTERACTION │→ DASHBOARDS → INSIGHTS           │
│                           │   JOURNEY    │                                  │
│                           │              │                                  │
│                           │  NOT BUILT   │   HANDOFF PENDING                │
│                           └──────────────┘                                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Why Start with Layer 3?

Layer 3 (Success Library) is the right starting point because:

1. **Foundation** - You can't automate metric calculation without first defining what the calculations are
2. **Self-contained** - Doesn't require Layers 1, 2, 4 to exist first
3. **Immediate value** - Even before automation, analysts can reference governed definitions instead of writing ad-hoc code
4. **Scalable** - Framework handles hundreds of metrics once content is populated

The other layers depend on Layer 3 existing. Layer 2 needs to reference metrics that are defined somewhere. Layer 4 needs calculation logic to apply. Layer 3 is the source of truth they all point to.

---

## Next Steps (Suggested)

| Priority | Action | Owner | Notes |
|----------|--------|-------|-------|
| 1 | Define content population process | TBD | Analyst-driven vs centralized |
| 2 | Populate first batch of real metrics | TBD | Start with highest-use campaigns |
| 3 | Validate SQL/PySpark against real data | TBD | Test each metric before "publishing" |
| 4 | Initiate dashboard team handoff discussion | TBD | Understand their requirements |
| 5 | Define connection interface to Layer 2 | TBD | How will Mnemonic Mapping V2 reference metric_id? |

---

## References

- `docs/01_EXECUTIVE_SUMMARY.md` - High-level overview for stakeholders
- `docs/DESIGN_DECISIONS.md` - Technical architecture decisions
- `support/success_library_project_context.md` - Original design vision (living document)
- `agent_sessions/` - Working session notes

---

*Document created: 2026-01-18*
*Last updated: 2026-01-18*
