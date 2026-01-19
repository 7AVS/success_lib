# Code File Creation and Update Process

This document describes the workflow for creating and updating code files in the Success Library. Code files contain the SQL and PySpark logic that defines how each metric is calculated.

---

## Overview

The Success Library has two types of content:

| Content Type | Storage | Update Method |
|--------------|---------|---------------|
| **Metadata** | `metadata/success_library_index.json` | Excel intake form → `excel_to_json.py` |
| **Code** | `code/{PRODUCT}/{METRIC_ID}.md` | Manual creation using template |

This document covers the **code** update process.

---

## Roles

| Role | Responsibility |
|------|----------------|
| **Analyst/Requester** | Provides code (SQL/PySpark) for new or updated metrics |
| **Admin/Maintainer** | Creates/updates code files, runs build, maintains library |

---

## When to Use This Process

| Scenario | What to Do |
|----------|------------|
| New metric (metadata + code) | 1. Process intake form for metadata, 2. Create code file |
| Update existing code logic | Update the code file directly |
| Update metadata only (no code change) | Use intake form only, no code file change |
| Update code only (no metadata change) | Update code file, run build |

---

## Process: Creating a New Code File

### Step 1: Receive Code from Requester

The requester provides:
- SQL code (for Data Warehouse / Teradata / Snowflake)
- PySpark code (for Hive / Data Lake)
- Or both, or just one (depending on what's available)

**Accepted formats:**
- Text file (.txt, .sql, .py)
- Email body
- Teams/Slack message
- Confluence page
- Any readable text format

### Step 2: Copy the Template

```
Source: intake/template/code_template.md
Destination: code/{PRODUCT}/{METRIC_ID}.md
```

**Example:**
```
cp intake/template/code_template.md code/VVD/VVD_ACQ_002.md
```

### Step 3: Fill in the Template

Open the new file and replace all `{placeholder}` values:

| Section | What to Fill |
|---------|--------------|
| Title | `# VVD_ACQ_002 - Virtual Visa Debit Acquisition (Digital)` |
| Owner/Version | `<!-- Owner: Jane Smith | Version: v1.0 -->` |
| Metadata table | Product, Metric Type, Pillar, Campaigns, Grain |
| Business Definition | Plain English description |
| Source Tables | List actual table names |
| SQL block | Paste the SQL code |
| PySpark block | Paste the PySpark code |
| Notes | Any caveats or special handling |
| Change History | Initial creation entry |

### Step 4: Validate the Code Structure

Before saving, verify:

- [ ] SQL code is inside the ` ```sql ` code block
- [ ] PySpark code is inside the ` ```python ` code block
- [ ] No placeholder text remains (search for `{` characters)
- [ ] File is saved as `.md` extension
- [ ] Filename matches the metric_id exactly (case-sensitive)

### Step 5: Verify Metadata Exists

The code file must have a corresponding entry in `metadata/success_library_index.json`.

Check that:
- `metric_id` in the JSON matches the filename
- `code_path` in the JSON points to the correct file

**Example JSON entry:**
```json
{
  "metric_id": "VVD_ACQ_002",
  "metric_name": "Virtual Visa Debit Acquisition (Digital)",
  "code_path": "code/VVD/VVD_ACQ_002.md",
  ...
}
```

If metadata doesn't exist, process the intake form first using `excel_to_json.py`.

### Step 6: Run the Build

```bash
python3 build.py
```

This regenerates `index.html` with the new code file included.

### Step 7: Verify in Browser

Open `index.html` in a browser and:
- Search for the new metric
- Click to view details
- Verify SQL code displays correctly
- Verify PySpark code displays correctly

### Step 8: Commit to Git

```bash
git add code/{PRODUCT}/{METRIC_ID}.md
git add index.html
git commit -m "Add code for {METRIC_ID} - {brief description}"
```

---

## Process: Updating an Existing Code File

### Step 1: Locate the File

```
code/{PRODUCT}/{METRIC_ID}.md
```

### Step 2: Make Changes

Edit the relevant section:
- Update SQL code within the ` ```sql ` block
- Update PySpark code within the ` ```python ` block
- Update the Change History table

### Step 3: Update Version (if major change)

If this is a significant logic change:
- Update version in header: `<!-- Owner: Name | Version: v2.0 -->`
- Add entry to Change History table

### Step 4: Run Build and Verify

```bash
python3 build.py
```

Open `index.html` and verify the changes appear correctly.

### Step 5: Commit to Git

```bash
git add code/{PRODUCT}/{METRIC_ID}.md
git add index.html
git commit -m "Update {METRIC_ID}: {brief description of change}"
```

---

## File Structure Requirements

The `build.py` script parses code files by looking for specific markers. The file **must** follow this structure:

```markdown
# {METRIC_ID} - {Name}
<!-- Owner: {Name} | Version: {version} -->

## Metadata
(table with attributes)

## Business Definition
(description text)

## Source Tables
(list of tables)

---

## SQL (Data Warehouse)

```sql
(SQL code here - this entire block is extracted)
```

---

## PySpark (Hive)

```python
(PySpark code here - this entire block is extracted)
```
```

**Critical requirements:**

| Requirement | Why |
|-------------|-----|
| Section headers must match exactly | `build.py` searches for these headers |
| Code must be in fenced code blocks | ` ```sql ` and ` ```python ` markers define extraction boundaries |
| One SQL block, one PySpark block | Multiple blocks may cause parsing issues |
| No nested code blocks | Will break the parser |

---

## Handling Partial Submissions

Sometimes a requester only provides SQL or only PySpark.

| Situation | What to Do |
|-----------|------------|
| SQL only | Fill SQL block, leave PySpark block with placeholder note: `-- PySpark implementation pending` |
| PySpark only | Fill PySpark block, leave SQL block with placeholder note: `# SQL implementation pending` |
| Neither (metadata only) | Create file with both blocks containing placeholder notes |

**Example placeholder:**
```sql
-- SQL implementation pending
-- Contact: {owner_name}
-- Expected completion: {date or TBD}
```

---

## Quality Checklist

Before finalizing any code file:

| Check | Status |
|-------|--------|
| Metric ID matches filename | [ ] |
| Metric ID matches JSON entry | [ ] |
| Owner is identified | [ ] |
| Business definition is clear | [ ] |
| Source tables are listed | [ ] |
| SQL code is syntactically correct | [ ] |
| PySpark code is syntactically correct | [ ] |
| Code has been tested against real data (if possible) | [ ] |
| Change history is updated | [ ] |
| Build completes without errors | [ ] |
| HTML displays correctly | [ ] |

---

## Troubleshooting

### Build fails or code doesn't appear in HTML

1. Check file extension is `.md`
2. Check filename matches `metric_id` exactly
3. Check `code_path` in JSON is correct
4. Check code blocks use correct markers (` ```sql ` and ` ```python `)
5. Check for unclosed code blocks

### Code appears garbled or incomplete

1. Check for special characters that might break markdown
2. Check for nested code blocks (not supported)
3. Check for tabs vs spaces issues

### Metadata shows but code section is empty

1. Verify code file exists at the path specified in JSON
2. Verify the section headers match exactly (`## SQL (Data Warehouse)`, etc.)

---

## Workflow Summary

```
Requester                          Admin
─────────                          ─────

Submits intake form (metadata) ──► Process with excel_to_json.py
                                         │
Provides code (SQL/PySpark) ─────► Copy template
                                         │
                                   Fill in template with code
                                         │
                                   Validate structure
                                         │
                                   Run build.py
                                         │
                                   Verify in browser
                                         │
                                   Commit to Git
                                         │
                                   ◄──── Done, notify requester
```

---

## Related Documents

- `intake/template/code_template.md` - Template file for new metrics
- `intake/template/intake_template.xlsx` - Metadata intake form
- `docs/DESIGN_DECISIONS.md` - Why we chose this structure
- `README.md` - General usage instructions

---

*Document created: 2026-01-19*
*Last updated: 2026-01-19*
