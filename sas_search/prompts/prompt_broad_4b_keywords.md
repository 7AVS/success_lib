# Prompt for Broad Search — Step 4b (Mapped Keywords)

## When to use this:
## When you ran step4b_extract_keywords.ps1 using the step 2 tagged file
## as input (no deduplication). The same mnemonic may appear multiple
## times from different SAS files with different dates.
## Each section was found because specific business keywords matched in the file.

---

## PHASE 1 — Scan, Categorize, and Compare Versions

```
You are reviewing extracts from SAS code files. Each section represents one NBA campaign mnemonic (a 3-letter code like FTH, MOM, PCQ, etc.).

HOW THESE EXTRACTS WERE CREATED:
- Each section comes from a SAS file that was identified as containing a specific mnemonic
- Within that file, the code was extracted around occurrences of business keywords specific to that mnemonic (e.g., for a mortgage campaign: "mortgage", "funded", "approved", etc.)
- The keywords used for each mnemonic are listed in the KEYWORDS line of the section header
- Lines marked with >>>[keyword] show where a keyword matched — the keyword name is in brackets
- Lines marked with ? contain conditional logic (if/where/case/when)
- 20 lines above and 20 lines below each keyword match are included for context

WARNING: Because these are keyword matches, many extracts will be noise — the keyword appeared in the file but in a completely unrelated context (data prep, client selection, reporting, etc.). Your job is to separate signal from noise.

IMPORTANT: The same mnemonic may appear MULTIPLE TIMES because the code was extracted from different SAS files. Each section header shows:
- FILE: the name of the SAS file
- PATH: the full location of the file
- MODIFIED: when the file was last updated
- KEYWORDS: the business terms that were searched for

Your task: scan every section and build a table.

For EACH section in the file (not each mnemonic — each section), give me one row with:
- Mnemonic
- File name (from the FILE line in the header)
- Modified date (from the MODIFIED line)
- Category (see below)
- One-line note

Categories:
- USEFUL: The extract contains code that is clearly related to measuring campaign success — you can see outcome logic (did the client do the thing?)
- PARTIAL: Some relevant success logic is visible but it's incomplete or mixed with unrelated code
- NOISE: The keywords matched but the code is unrelated to success measurement — it's client selection, data prep, reporting, table joins, or something else entirely
- UNCLEAR: Cannot determine from the extract

If a section has multiple blocks, base your category on the BEST block (the one most likely to contain success logic).

Format as a table sorted by Mnemonic then Modified date (newest first).

Example:
| Mnemonic | File | Modified | Category | Note |
|----------|------|----------|----------|------|
| FTH | prog_a.sas | 2024-11-15 | USEFUL | Block 3 has mortgage funding check with date condition |
| FTH | prog_b.sas | 2023-06-20 | NOISE | "mortgage" matched in a comment and a table join |
| GIS | gic_v2.sas | 2024-08-10 | PARTIAL | GIC deposit check visible but amount threshold cut off |
```

---

## PHASE 2 — Extract the Best Version

Use this AFTER Phase 1. Pick the mnemonics that have at least one USEFUL or PARTIAL entry.

```
From the same file, I need you to extract the success definition for the following mnemonics: [LIST THE USEFUL AND PARTIAL ONES HERE]

For each mnemonic, if there are multiple files with usable code, pick the BEST one. Best means:
- USEFUL over PARTIAL
- If both are USEFUL, pick the most recently modified
- If only PARTIAL versions exist, pick the most recent one

For each mnemonic, provide:

1. MNEMONIC: the 3-letter code
2. EXPECTED SUCCESS: (from the section header)
3. SELECTED FILE: which file you picked and why (name + modified date)
4. OTHER FILES: list any other files for this mnemonic and their category (so we know what else exists)
5. KEYWORDS MATCHED: which of the mapped keywords actually appeared in the relevant code blocks (not all keyword hits — only the ones that matter)
6. SAS CODE: Copy the exact SAS code that defines or measures success for this mnemonic. Include the full code block — the SQL/SAS statements, WHERE clauses, IF conditions, CASE statements, table references, and variable assignments that determine success. Copy the code exactly as it appears in the extract. If the success logic spans multiple blocks, include all relevant blocks. Do not paraphrase or summarize the code — I need the actual code as-is so I can reuse it.
7. PLAIN LANGUAGE: In one or two sentences, describe what this code is doing in business terms.
8. MATCH: Does the actual logic match the expected success? (Yes / No / Partially / Cannot determine)
9. GAPS: If the code is cut off or incomplete, note what is missing.

IMPORTANT: The SAS code in item 6 is the most important part. Copy it exactly. Do not skip it. Do not replace it with a description.
```
