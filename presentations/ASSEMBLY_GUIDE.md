# Presentation Assembly Guide
## Director Briefing: Success Library

This guide explains how to assemble the presentation using the provided assets.

---

## Quick Start

1. Open your corporate PowerPoint template (4:3 aspect ratio)
2. Create slides following the structure below
3. Copy text from `assets/text/slide_content.md`
4. Copy-paste tables from `assets/tables/*.xlsx`
5. Build diagrams using PPT SmartArt or shapes (instructions below)

---

## Assets Provided

```
presentations/
├── assets/
│   ├── tables/
│   │   ├── 01_components.xlsx
│   │   ├── 02_before_after.xlsx
│   │   ├── 03_architecture_tradeoffs.xlsx
│   │   ├── 04_decisions_needed.xlsx
│   │   ├── 05_status_timeline.xlsx
│   │   ├── 06_asks.xlsx
│   │   ├── 07_initial_metrics.xlsx
│   │   └── 08_value_proposition.xlsx
│   └── text/
│       ├── slide_content.md
│       └── speaker_notes.md
├── ASSEMBLY_GUIDE.md (this file)
└── build_assets.py
```

---

## RBC Color Reference

Use these colors for diagrams and accents:

| Purpose | Color | Hex |
|---------|-------|-----|
| Primary/Headers | Bright Blue | #0051A5 |
| Secondary | Dark Blue | #003168 |
| Highlight/Success | Warm Yellow | #FFC72C |
| Background | Cool White | #E7EEF1 |
| Accent 1 | Ocean | #0091DA |
| Accent 2 | Tundra | #07AFBF |
| Neutral | Gray | #9EA2A2 |

---

## Slide-by-Slide Assembly

### SLIDE 1: Title
- Title: "Success Library"
- Subtitle: "Building the Foundation for Standardized Campaign Measurement"
- Footer: "Marketing Analytics | January 2026"

**No diagram needed.**

---

### SLIDE 2: Agenda
- Use numbered list SmartArt or bullets
- 6 items (see slide_content.md)

**No diagram needed.**

---

### SLIDE 3: The Problem (DIAGRAM)

**Build this diagram using PPT shapes:**

```
┌─────────────────────────────────────────────────────────────┐
│                     ❌ Today: Chaos                          │
│                                                              │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐            │
│  │ Analyst 1│     │ Analyst 2│     │ Analyst 3│            │
│  └────┬─────┘     └────┬─────┘     └────┬─────┘            │
│       │                │                │                   │
│       ▼                ▼                ▼                   │
│  "writes own      "writes own      "writes own              │
│   code"            code"            code"                   │
│       │                │                │                   │
│       ▼                ▼                ▼                   │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐            │
│  │ Result A │     │ Result B │     │ Result C │            │
│  └──────────┘     └──────────┘     └──────────┘            │
│       ╎                ╎                ╎                   │
│       ╎....Different...╎...Cannot.......╎                   │
│            definitions      compare                         │
└─────────────────────────────────────────────────────────────┘
```

**PPT Steps:**
1. Insert > Shapes > Rectangle (rounded) for "Today: Chaos" container
2. Insert 3 rectangles for Analysts (use Gray #9EA2A2)
3. Insert arrows pointing down
4. Insert 3 rectangles for Results (use different colors to show inconsistency)
5. Add dashed lines between results
6. Add text labels

**Colors:**
- Container: Light red/pink fill or no fill with red border
- Analyst boxes: Gray (#9EA2A2)
- Result boxes: Different colors (red, orange, yellow) to show chaos

---

### SLIDE 4: The Solution (DIAGRAM)

**Build this diagram:**

```
┌─────────────────────────────────────────────────────────────┐
│                    ✅ Future: Governed                       │
│                                                              │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐            │
│  │ Analyst 1│     │ Analyst 2│     │ Analyst 3│            │
│  └────┬─────┘     └────┬─────┘     └────┬─────┘            │
│       │                │                │                   │
│       └────────────────┼────────────────┘                   │
│                        ▼                                    │
│                ┌───────────────┐                            │
│                │   SUCCESS     │                            │
│                │   LIBRARY     │                            │
│                └───────┬───────┘                            │
│                        ▼                                    │
│                ┌───────────────┐                            │
│                │  Consistent   │                            │
│                │    Result     │                            │
│                └───────────────┘                            │
└─────────────────────────────────────────────────────────────┘
```

**PPT Steps:**
1. Insert container rectangle with green tint
2. 3 Analyst boxes at top
3. All arrows converge to center "Success Library" box
4. One arrow down to "Consistent Result"

**Colors:**
- Container: Light green fill (#E7F5E7) or Cool White
- Success Library box: Bright Blue (#0051A5) with white text
- Result box: Warm Yellow (#FFC72C)

---

### SLIDE 5: SuperFact Big Picture (DIAGRAM)

**Use SmartArt > Process > Vertical Process**

Or build manually:

```
┌─────────────────────────────────────┐
│  Layer 1: Experiment Metadata       │  ← Gray
│  "Who is in the test?"              │
└─────────────────┬───────────────────┘
                  ▼
┌─────────────────────────────────────┐
│  Layer 2: Campaign Metadata         │  ← Gray
│  "What to measure?"                 │
└─────────────────┬───────────────────┘
                  ▼
┌─────────────────────────────────────┐
│  Layer 3: SUCCESS LIBRARY ✓         │  ← BRIGHT BLUE (highlight)
│  "How to calculate?"                │
└─────────────────┬───────────────────┘
                  ▼
┌─────────────────────────────────────┐
│  Layer 4: Client Journey            │  ← Gray
│  "What did they do?"                │
└─────────────────┬───────────────────┘
                  ▼
            [Dashboards]
```

**Colors:**
- Layers 1, 2, 4: Gray (#9EA2A2) or Cool White (#E7EEF1)
- Layer 3: Bright Blue (#0051A5) with white text - THIS IS THE FOCUS

---

### SLIDE 6: Why Layer 3 First (DIAGRAM)

**Horizontal flow:**

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   Layer 2      │     │   Layer 3      │     │   Layer 4      │
│                │     │                │     │                │
│  Campaign says:│────▶│ Success Library│────▶│   Executes:    │
│  "Measure      │     │  translates:   │     │                │
│  CC_ACQ_001"   │     │ CC_ACQ_001=SQL │     │ Result = 4.2%  │
└────────────────┘     └────────────────┘     └────────────────┘
       │                      │                      │
    metric_id              code                   result
```

**Use SmartArt > Process > Basic Chevron Process** or manual shapes.

---

### SLIDE 7: What We Built

**Use bullet list or SmartArt > List**

No complex diagram needed.

---

### SLIDE 8: Components Summary

**Insert table from Excel:**
1. Open `assets/tables/01_components.xlsx`
2. Select all cells
3. Copy (Ctrl+C)
4. In PowerPoint: Paste Special > Keep Source Formatting

---

### SLIDES 9-11: Design Principle & How It Works

See `slide_content.md` for text.

For sequence diagrams, use **SmartArt > Process > Basic Timeline** or numbered list with arrows.

---

### SLIDE 12: Value Now vs Future

**Insert table from:** `08_value_proposition.xlsx`

---

### SLIDES 13-18: Decisions

Build simple diagrams using shapes:
- Decision questions as rectangles
- Options as branching arrows or bullet lists
- Use `03_architecture_tradeoffs.xlsx` for comparison table

---

### SLIDE 19: Current Status

**Insert table from:** `05_status_timeline.xlsx`

For visual progress bar:
1. Insert > Shapes > Rectangle
2. Create 5 segments: Framework, Content, Validation, Training, Automation
3. Color first segment green, second yellow, rest gray

---

### SLIDE 21: What I Need From You

**Insert table from:** `06_asks.xlsx`

---

### SLIDE 22: Summary

**Three boxes in a row:**

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    BUILT     │────▶│     WHY      │────▶│    NEXT      │
│              │     │              │     │              │
│  Layer 3     │     │ Consistency  │     │  Content &   │
│  Framework   │     │              │     │  Training    │
└──────────────┘     └──────────────┘     └──────────────┘
```

Use SmartArt > Process > Basic Process

---

## Rebuilding Assets

If content changes, regenerate tables:

```bash
cd presentations
python build_assets.py
```

This recreates all Excel files with RBC styling.

---

## Tips

1. **Tables:** Always paste from Excel using "Keep Source Formatting" to preserve RBC colors
2. **Diagrams:** SmartArt is faster, but manual shapes give more control
3. **Colors:** When in doubt, use Bright Blue (#0051A5) for emphasis
4. **Text:** Copy from slide_content.md to ensure consistency
5. **Sizing:** 4:3 slides = 10" x 7.5" - keep diagrams proportional

---

## Questions?

Refer to documentation in `docs/` folder for detailed explanations.
