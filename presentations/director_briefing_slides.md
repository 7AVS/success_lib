---
marp: true
theme: default
paginate: true
header: 'Success Library - Director Briefing'
footer: 'Marketing Analytics | January 2026'
html: true
style: |
  section {
    font-size: 24px;
  }
  h1 {
    color: #2563eb;
  }
  h2 {
    color: #1e40af;
  }
  table {
    font-size: 20px;
  }
  .mermaid {
    font-size: 16px;
  }
---

<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
  mermaid.initialize({ startOnLoad: true, theme: 'default' });
</script>

# Success Library
## Director Briefing

Building the Foundation for Standardized Campaign Measurement

**Marketing Analytics | January 2026**

---

# Agenda

1. The Problem We're Solving
2. The Big Picture (SuperFact Architecture)
3. What We Built (Layer 3)
4. How It Works
5. Decisions Needed
6. Next Steps

---

# The Problem

<div class="mermaid">
flowchart LR
    subgraph Today["❌ Today: Chaos"]
        A1[Analyst 1] -->|writes own code| R1[Result A]
        A2[Analyst 2] -->|writes own code| R2[Result B]
        A3[Analyst 3] -->|writes own code| R3[Result C]
    end
    R1 -.-|Different definitions| R2
    R2 -.-|Cannot compare| R3
</div>

**Same metric, three different answers. No audit trail. No consistency.**

---

# The Solution

<div class="mermaid">
flowchart LR
    subgraph Future["✅ Future: Governed"]
        SL[Success Library]
        A1[Analyst 1] --> SL
        A2[Analyst 2] --> SL
        A3[Analyst 3] --> SL
        SL --> R[Consistent Result]
    end
</div>

**One definition. One calculation. Everyone uses the same code.**

---

# SuperFact: The Big Picture

<div class="mermaid">
flowchart TB
    L1["Layer 1: Experiment Metadata<br/>Who is in the test?"]
    L2["Layer 2: Campaign Metadata<br/>What to measure?"]
    L3["Layer 3: Success Library ✓<br/>How to calculate?"]
    L4["Layer 4: Client Journey<br/>What did they do?"]
    D[Dashboards]
    L1 --> L2 --> L3 --> L4 --> D
    style L3 fill:#22c55e,color:#fff
</div>

**We built Layer 3 - the foundation the other layers depend on.**

---

# Why Layer 3 First?

<div class="mermaid">
flowchart LR
    L2["Layer 2<br/>Campaign says:<br/>Measure CC_ACQ_001"]
    L3["Layer 3<br/>Success Library:<br/>CC_ACQ_001 = SQL"]
    L4["Layer 4<br/>Executes:<br/>Result = 4.2%"]
    L2 -->|metric_id| L3 -->|code| L4
    style L3 fill:#22c55e,color:#fff
</div>

**You can't automate "what to measure" without first defining "how to calculate."**

---

# What We Built

<div class="mermaid">
flowchart TB
    subgraph Framework["Success Library Framework ✓"]
        CAT[Metric Catalog]
        CODE[Code Files]
        UI[HTML Interface]
        INTAKE[Intake Workflow]
        DOCS[Documentation]
    end
    INTAKE --> CAT
    CAT --> UI
    CODE --> UI
    style Framework fill:#f0fdf4
</div>

**6 metrics catalogued across 3 products (VVD, CC, MTG)**

---

# What Each Component Does

| Component | Purpose | Who Uses It |
|-----------|---------|-------------|
| **Metric Catalog** | Central index of all metrics | System |
| **Code Files** | SQL + PySpark calculation logic | Analysts, Data Eng |
| **HTML Interface** | Browse, search, copy code | Analysts |
| **Intake Workflow** | Submit new metrics | Analysts → Admin |
| **Documentation** | Processes, decisions, guides | Everyone |

---

# Key Design Principle

<div class="mermaid">
flowchart LR
    subgraph Correct["✅ Product-Level"]
        M1["CC_ACQ_001<br/>Was a card issued?"]
    end
    subgraph Wrong["❌ Campaign-Level"]
        M2["CC_ACQ_CAMP_X<br/>Issued in Campaign X?"]
    end
</div>

**Why product-level?**
- Same metric reusable across campaigns
- Enables cross-sell analysis
- Campaign filtering happens in analytical layer

---

# How It Works: Adding a Metric

<div class="mermaid">
sequenceDiagram
    participant A as Analyst
    participant AD as Admin
    participant SYS as System
    A->>AD: 1. Submit intake form
    A->>AD: 2. Provide code
    AD->>SYS: 3. Process intake
    AD->>SYS: 4. Create code file
    AD->>SYS: 5. Run build
    AD->>A: 6. Done
</div>

---

# How It Works: Using the Library

<div class="mermaid">
sequenceDiagram
    participant A as Analyst
    participant UI as index.html
    participant CODE as Code File
    A->>UI: 1. Open browser
    A->>UI: 2. Search metric
    UI->>A: 3. Show metadata
    A->>CODE: 4. View Code
    CODE->>A: 5. Copy SQL
    A->>A: 6. Run query
</div>

---

# Value: Now vs Future

<div class="mermaid">
flowchart LR
    subgraph Now["Value Today"]
        N1[Consistency]
        N2[Speed]
        N3[Auditability]
    end
    subgraph Future["Value Tomorrow"]
        F1[Automated Calc]
        F2[Day 1 Reporting]
        F3[AI Queries]
    end
    Now -->|Foundation| Future
</div>

---

# Decision Needed: Technology Stack

<div class="mermaid">
flowchart TB
    Q["What platform?"]
    Q --> S[Snowflake]
    Q --> H[Hive]
    Q --> R[Redshift]
    S & H & R --> C["Columnar = wide tables OK"]
</div>

**Need input from Data Engineering on constraints.**

---

# Decision Needed: Data Architecture

## Option A: One Table Per Product

<div class="mermaid">
flowchart LR
    CC[cc_metrics] --> Q1[Query CC]
    VVD[vvd_metrics] --> Q2[Query VVD]
    MTG[mtg_metrics] --> Q3[Query MTG]
</div>

**Pros:** Clean, focused, no NULLs | **Cons:** Cross-product needs UNION

---

# Decision Needed: Data Architecture

## Option B: One Unified Table

<div class="mermaid">
flowchart LR
    ALL["all_metrics<br/>(product, metric_id, flag, ...)"] --> Q[Query anything]
</div>

**Pros:** Single source, simple queries | **Cons:** Wide table, many NULLs

---

# Data Architecture Trade-offs

| Approach | Governance | Analytics | AI-Ready |
|----------|-----------|-----------|----------|
| One table per product | Medium | Simple | Good |
| One unified table | High | Simple | Good |
| Generic + dimensions | Medium | Medium | Good |
| Granular metrics | High | Simple | Best |

**Recommendation depends on tech stack answer.**

---

# Decision Needed: AI/Agent Integration

<div class="mermaid">
flowchart TB
    AI[AI Agent]
    AI -->|Option A| DATA[(Dataset)]
    AI -->|Option B| META[Metadata]
    META -->|generates| CODE[SQL]
    CODE --> DATA
    DATA --> R[Results]
</div>

**Success Library already provides metadata AI would need.**

---

# Decision Needed: Governance

<div class="mermaid">
flowchart TB
    Q1["Who maintains dataset?"] --> O1["Dedicated vs Shared"]
    Q2["Who approves metrics?"] --> O2["Single vs Committee"]
    Q3["Who populates content?"] --> O3["Analysts vs Central"]
</div>

---

# Current Status

<div class="mermaid">
flowchart LR
    F["Framework ✅"]
    C["Content 🔄"]
    V["Validation ⏳"]
    T["Training ⏳"]
    A["Automation 🔮"]
    F --> C --> V --> T --> A
    style F fill:#22c55e,color:#fff
    style C fill:#fbbf24
</div>

---

# Immediate Next Steps

<div class="mermaid">
flowchart TB
    S1["1. Tech stack clarity"]
    S2["2. Data architecture decision"]
    S3["3. Populate real metrics"]
    S4["4. Validate against data"]
    S5["5. Schedule training"]
    S1 --> S2 --> S3 --> S4 --> S5
</div>

---

# What I Need From You

| Ask | Why |
|-----|-----|
| **Tech stack decision** | Determines data architecture |
| **Connect me with Data Eng** | Need to understand constraints |
| **AI/agent timeline** | How much to invest now? |
| **Resource alignment** | Who populates metrics? |

---

# Summary

<div class="mermaid">
flowchart LR
    B["Built:<br/>Layer 3 Framework"]
    W["Why:<br/>Consistency"]
    N["Next:<br/>Content & Training"]
    B --> W --> N
    style B fill:#22c55e,color:#fff
</div>

**The metric_id we define today is the same one automation uses tomorrow.**

---

# Questions?

**Supporting Documentation:**
- `03_SUCCESS_LIBRARY_NARRATIVE.md` - Full explanation
- `02_CURRENT_STATE.md` - Vision to implementation
- `05_EXECUTIVE_BRIEFING.md` - Executive summary
- `DESIGN_DECISIONS.md` - Technical decisions

---

# Appendix: Complete Architecture

<div class="mermaid">
flowchart TB
    subgraph L1["Layer 1: Experiment Metadata"]
        L1A["Tactic History"]
    end
    subgraph L2["Layer 2: Campaign Metadata"]
        L2A["Mnemonic Mapping V2"]
    end
    subgraph L3["Layer 3: Success Library"]
        L3A["Definitions + Code"]
    end
    subgraph L4["Layer 4: Client Journey"]
        L4A["Touchpoints"]
    end
    L1 --> L2 -->|metric_id| L3 -->|code| L4 --> D[Dashboards]
    style L3 fill:#22c55e,color:#fff
</div>

---

# Appendix: File Structure

```
success_library/
├── index.html              # Browsable interface
├── build.py                # Generates HTML
├── excel_to_json.py        # Processes intake
├── metadata/
│   └── success_library_index.json
├── code/
│   ├── VVD/    (4 metrics)
│   ├── CC/     (1 metric)
│   └── MTG/    (1 metric)
├── intake/
│   ├── template/
│   ├── pending/
│   └── processed/
└── docs/       (6 documents)
```
