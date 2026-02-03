# Prompt for Broad Search Output (Step 4a/4b run against full tagged file)

## When to use this:
## When you ran step 4a or 4b using the step 2 tagged file as input
## (no deduplication). This means the same mnemonic may appear multiple
## times from different SAS files with different dates.

---

## PHASE 1 — Scan, Categorize, and Compare Versions

```
You are reviewing extracts from SAS code files. Each section represents one NBA campaign mnemonic (a 3-letter code like FTH, MOM, PCQ, etc.).

IMPORTANT: The same mnemonic may appear MULTIPLE TIMES because the code was extracted from different SAS files. Each section header shows:
- FILE: the name of the SAS file
- PATH: the full location of the file
- MODIFIED: when the file was last updated

Your task: scan every section and build a table.

For EACH section in the file (not each mnemonic — each section), give me one row with:
- Mnemonic
- File name (from the FILE line in the header)
- Modified date (from the MODIFIED line)
- Category (see below)
- One-line note

Categories:
- COMPLETE: Contains actual success measurement logic — you can see how success is defined
- PARTIAL: Some success logic visible but cut off or incomplete
- NOISE: The search term matched but the code is unrelated to success measurement
- LABEL ONLY: "success" appears as a variable name or label only, no logic
- UNCLEAR: Cannot determine

Format as a table sorted by Mnemonic then Modified date (newest first).

Example:
| Mnemonic | File | Modified | Category | Note |
|----------|------|----------|----------|------|
| FTH | prog_a.sas | 2024-11-15 | COMPLETE | Mortgage funding check with 90-day window |
| FTH | prog_b.sas | 2023-06-20 | NOISE | Just client selection code |
| MOM | renew_v3.sas | 2024-09-01 | PARTIAL | Renewal flag visible but conditions cut off |
```

---

## PHASE 2 — Extract the Best Version

Use this AFTER Phase 1. Pick the mnemonics that have at least one COMPLETE or PARTIAL entry.

```
From the same file, I need you to extract the success definition for the following mnemonics: [LIST THEM HERE]

For each mnemonic, if there are multiple files with usable code, pick the BEST one. Best means:
- COMPLETE over PARTIAL
- If both are COMPLETE, pick the most recently modified
- If only PARTIAL versions exist, pick the most recent one

For each mnemonic, provide:

1. MNEMONIC: the 3-letter code
2. EXPECTED SUCCESS: (from the section header)
3. SELECTED FILE: which file you picked and why (name + date)
4. OTHER FILES: list any other files for this mnemonic and their category (so we know what else exists)
5. SAS CODE: Copy the exact SAS code that defines or measures success. Include the full code block — SQL/SAS statements, WHERE clauses, IF conditions, CASE statements, table references, variable assignments. Copy the code exactly as it appears. Do not paraphrase. Do not summarize. Do not skip.
6. PLAIN LANGUAGE: One or two sentences describing what this code does in business terms.
7. MATCH: Does the logic match the expected success? (Yes / No / Partially / Cannot determine)
8. GAPS: If the code is cut off or incomplete, note what is missing.

IMPORTANT: The SAS code in item 5 is the most important part. Copy it exactly from the extract.
```
