# Success Library - What We're Building and Why

## The Problem We're Solving

Marketing Analytics manages 200-300 active campaigns at any given time. Each campaign needs to be measured - did it work? Did customers respond? Did we hit our targets?

The problem is how we answer those questions today.

When an analyst needs to measure a campaign, they write their own code. They dig through tech specs, Confluence pages, old scripts, maybe ask a colleague. They piece together a query that calculates "success" for that campaign. Then the next analyst does the same thing for their campaign. And the next.

There's no single source that says: *"Here's what Acquisition means. Here's what Activation means. Here's the exact SQL that calculates it."*

The consequences are real:

- **Inconsistency** - Two analysts measuring similar campaigns might define "activation" differently. When results are compared, they're not actually comparable.

- **No auditability** - When someone asks "how did you calculate that number?", the answer is buried in someone's personal script folder. If that person leaves, the knowledge goes with them.

- **Wasted time** - Analysts spend weeks recreating logic that's been written before. Every new campaign starts from scratch.

- **No scalability** - This might work for 20 campaigns. It doesn't work for 300.

---

## The Big Picture: SuperFact Architecture

The solution is a governed data architecture called SuperFact. It has four layers that connect experiment design to reporting:

### Layer 1: Governed Experiment Metadata
**Question it answers: "Who is in the test?"**

This layer links experiments to clients. When we run a test vs control experiment, Layer 1 tracks which clients are in which group. It uses fields in the Tactic History table - Report Group Code, Treatment Meaning, Test Group, Tactic ID - combined with client identifiers.

This is foundational because you can't measure treatment effect if you don't know who received the treatment.

### Layer 2: Managed Campaign Metadata (Mnemonic Mapping V2)
**Question it answers: "What should we measure?"**

This layer classifies campaigns and declares their success metrics upfront. When a campaign is created, it gets tagged with its Primary, Secondary, and Tertiary success metrics - selected from a governed library, not made up on the spot.

This is where the connection happens: Layer 2 says "Campaign X uses metric VVD_ACQ_001 as its primary success measure." That metric_id points to Layer 3.

### Layer 3: Success Library (Current Focus)
**Question it answers: "How do we calculate it?"**

This is the centralized repository of metric definitions. For every governed metric, there's a definition (what it means in plain English), metadata (what product, what type, what pillar), and code (the actual SQL and PySpark that calculates it).

When Layer 2 declares "this campaign measures VVD_ACQ_001", Layer 3 is where you find out what VVD_ACQ_001 actually is and how to compute it.

### Layer 4: Client Marketing Interaction Journey
**Question it answers: "What did the client actually do?"**

This layer maps the end-to-end client experience - from the moment a marketing decision was made, through every touchpoint, to the final outcome. Did they open the email? Click through? Start an application? Complete it?

This is where the measurement actually happens. Layer 4 takes the population from Layer 1, the metric definition from Layer 3, and produces the results.

---

## How The Layers Connect

The key insight is that **one identifier connects everything: `metric_id`**.

```
Campaign is designed
       │
       ▼
Layer 2 declares: "Primary metric = VVD_ACQ_001"
       │
       │  ← metric_id is the link
       ▼
Layer 3 defines: "VVD_ACQ_001 means X, calculated by Y"
       │
       │  ← same metric_id
       ▼
Layer 4 executes: "For population Z, VVD_ACQ_001 = 4.2%"
       │
       ▼
Dashboard displays result
```

This is what creates consistency. The metric_id `VVD_ACQ_001` means the same thing everywhere - in the campaign setup, in the calculation, in the report. There's no ambiguity because there's only one definition, maintained in one place.

---

## What We've Built: Layer 3 Framework

We started with Layer 3 because it's the foundation. You can't automate metric calculation without first defining what the calculations are. You can't have Layer 2 point to metrics that don't exist. You can't have Layer 4 execute logic that hasn't been written.

Layer 3 is the source of truth that everything else references.

### What Exists Today

**Metric Catalog (`metadata/success_library_index.json`)**

A structured index of all governed metrics. Each metric has:
- Unique identifier (metric_id)
- Human-readable name
- Product (VVD, Credit Card, Mortgage, etc.)
- Line of Business
- Metric type (Acquisition, Activation, Usage, Provisioning, Retention)
- Pillar (Conversion, Engagement, Retention, Profitability, Share of Wallet)
- Business definition (plain English)
- Source tables
- Grain (client, account, transaction level)
- Owner
- Version
- List of campaigns using this metric

**Code Files (`code/{PRODUCT}/{METRIC_ID}.md`)**

For each metric, a markdown file containing:
- SQL implementation (for Data Warehouse / Teradata / future Snowflake)
- PySpark implementation (for Hive / Data Lake)

Both implementations exist because we have two data environments with different access patterns. The same business logic, adapted for each platform.

**Browsable Interface (`index.html`)**

An HTML page generated from the catalog that lets users:
- Search by metric name, ID, product, campaign
- Filter by product, type, pillar
- View full metadata for any metric
- View and copy the SQL/PySpark code

This is practical - analysts can find what they need without digging through files or asking around.

**Intake Workflow**

A process for adding new metrics or updating existing ones:
- Excel template for submissions
- Processing script that validates and updates the catalog
- Pending → Processed folder pattern for tracking
- Automatic backups before any change

This makes the system maintainable. It's not a one-time artifact - it's designed to grow as new metrics are defined.

**Build System**

A script (`build.py`) that generates the HTML interface from the JSON catalog and code files. Edit the source files, run the build, get an updated interface. Single source of truth, no duplication.

---

## Why Layer 3 First?

The other layers depend on Layer 3 existing.

**Layer 2 needs something to reference.** When a campaign declares "my primary metric is X", X has to be defined somewhere. That's Layer 3. Without the Success Library, Mnemonic Mapping V2 has nothing to point to.

**Layer 4 needs logic to execute.** The Client Journey layer calculates results, but it needs to know how to calculate them. That logic lives in Layer 3.

**Layer 1 is parallel, not dependent.** Experiment metadata can be built independently - it's about tagging populations, not defining metrics.

Starting with Layer 3 also delivers value immediately. Even before the other layers exist, even before automation, analysts can use the Success Library today:

- Look up the governed definition of a metric
- Copy the standardized code
- Run it against source data
- Get results that are consistent with everyone else using the same metric

The governance value is immediate. The automation value comes later when the layers connect.

---

## Current State: Framework Built, Content Placeholder

The infrastructure is complete. What's placeholder is the content itself.

We have 6 metrics catalogued across 3 products (VVD, CC, MTG). The structure is there - metadata populated, code files created - but the actual SQL/PySpark logic is placeholder. The business definitions need to be written. The source table mappings need to be specified.

This is deliberate. We built the container first to prove the architecture works. Now the container needs to be filled.

The path forward involves:
1. Populating actual business definitions for each metric
2. Writing real SQL/PySpark logic validated against source tables
3. Expanding coverage to more products and metric types
4. Defining the process for ongoing maintenance (who adds metrics, who validates them)

---

## Value: Now and Future

### Value Now (Before Curated Layer Exists)

Today, there is no pre-calculated metric warehouse. Analysts pull from source tables directly - EDW, EDL, Teradata, Hive.

The Success Library's value today is **governance and consistency**:
- Instead of every analyst writing their own "activation" logic, there's one governed definition
- Instead of hunting through Confluence for how a metric was calculated last time, it's in the library
- Instead of questioning whether two campaign results are comparable, they use the same metric definition

Analysts still run the code manually. But they run the *same* code.

### Value Future (When Curated Layer Exists)

The long-term vision is a curated data warehouse where these metrics are pre-calculated on a schedule. When that exists:

- Layer 3 becomes **documentation and audit trail**
- The code shows exactly what the pre-calculated metric is based on
- When someone asks "how is this number calculated?", you point to the Success Library
- If the automated calculation seems wrong, you can trace it back to the logic

The code doesn't become obsolete when automation arrives. It becomes the lineage.

---

## Integration Path

### Today's State
```
Layer 3 stands alone
       │
       ▼
Analyst manually browses Success Library
       │
       ▼
Copies SQL/PySpark code
       │
       ▼
Runs against source tables (EDW, EDL)
       │
       ▼
Produces results manually
```

### Intermediate State
```
Layer 2 (Mnemonic Mapping V2) gets implemented
       │
       ▼
Campaigns declare their metrics using metric_id
       │
       ▼
Layer 3 provides the definitions
       │
       ▼
Analysts still run manually, but now there's
formal linkage between campaign and metric
```

### Future State
```
Campaign created → Layer 2 tags metric_id
       │
       ▼
Layer 1 identifies test population
       │
       ▼
Layer 4 pulls logic from Layer 3, executes automatically
       │
       ▼
Results flow to dashboards
       │
       ▼
Layer 3 serves as audit trail
```

**The metric_id defined today is the same metric_id the automated system will use.** We're not building throwaway work. We're building the foundation.

---

## For Different Audiences

### For Analysts
Stop reinventing the wheel. When you need to measure acquisition success for VVD, look up VVD_ACQ_001. The definition is there. The code is there. Use it. If it doesn't exist, submit an intake form to add it.

### For Leadership
Consistent, auditable metrics across all campaigns. When someone questions a number, we can show exactly how it was calculated. When we compare campaigns, we're comparing apples to apples.

### For Data Engineering
When you build the curated layer, the specifications exist. The Success Library defines what each metric means and how it's calculated. You're not starting from scratch - you're implementing governed definitions.

### For Dashboard Team
Standardized outputs with clear definitions. When a metric shows up on a dashboard, its meaning is documented in the Success Library. No ambiguity about what the number represents.

---

## Summary

The Success Library is where we define "what success means" - once, governed, with code attached.

It's Layer 3 of a four-layer architecture. We built it first because the other layers need it. It delivers value today (consistency, governance) and enables value tomorrow (automation, dashboards).

The metric_id is the connector. Define it once in Layer 3, reference it everywhere else.

---

*Document created: 2026-01-18*
