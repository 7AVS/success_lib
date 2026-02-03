# Prompt for Broad Search — Step 4a (Success Keyword)

## When to use this:
## When you ran step4a_extract_success.ps1 using the step 2 tagged file
## as input (no deduplication). The same mnemonic may appear multiple
## times from different SAS files with different dates.
## Each section was found because the word "success" appeared in the file.

---

## PHASE 1 — Scan, Categorize, and Compare Versions

```
You are reviewing extracts from SAS code files. Each section represents one NBA campaign mnemonic (a 3-letter code like FTH, MOM, PCQ, etc.).

HOW THESE EXTRACTS WERE CREATED:
- Each section comes from a SAS file that was identified as containing a specific mnemonic
- Within that file, the code was extracted around every occurrence of the word "success"
- Lines marked with >>> are the lines where "success" was found
- Lines marked with ? contain conditional logic (if/where/case/when)
- 20 lines above and 20 lines below each "success" match are included for context

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
- COMPLETE: The extract contains actual success measurement logic — you can see how "success" is defined (what conditions, what tables, what flags determine success)
- PARTIAL: Some success logic visible but cut off or incomplete — you can see pieces but not the full picture
- LABEL ONLY: "success" appears only as a variable name, column header, table name, or label — no actual measurement logic is visible
- NOISE: The code around "success" is unrelated to measuring campaign outcomes (e.g., it's a comment, a print statement, or generic code)
- UNCLEAR: Cannot determine from the extract

Format as a table sorted by Mnemonic then Modified date (newest first).

Example:
| Mnemonic | File | Modified | Category | Note |
|----------|------|----------|----------|------|
| FTH | prog_a.sas | 2024-11-15 | COMPLETE | success_flag set based on mortgage funded date |
| FTH | prog_b.sas | 2023-06-20 | LABEL ONLY | "success" used as column alias in select |
| MOM | renew_v3.sas | 2024-09-01 | PARTIAL | renewal success check visible but conditions cut off |
```

---

## PHASE 2 — Extract the Best Version

Use this AFTER Phase 1. Pick the mnemonics that have at least one COMPLETE or PARTIAL entry.

```
From the same file, I need you to extract the success definition for the following mnemonics: [LIST THE COMPLETE AND PARTIAL ONES HERE]

For each mnemonic, if there are multiple files with usable code, pick the BEST one. Best means:
- COMPLETE over PARTIAL
- If both are COMPLETE, pick the most recently modified
- If only PARTIAL versions exist, pick the most recent one

For each mnemonic, provide:

1. MNEMONIC: the 3-letter code
2. EXPECTED SUCCESS: (from the section header)
3. SELECTED FILE: which file you picked and why (name + modified date)
4. OTHER FILES: list any other files for this mnemonic and their category (so we know what else exists)
5. SAS CODE: Copy the exact SAS code that defines or measures success for this mnemonic. Include the full code block — the SQL/SAS statements, WHERE clauses, IF conditions, CASE statements, table references, and variable assignments that determine success. Copy the code exactly as it appears in the extract. If the success logic spans multiple blocks, include all relevant blocks. Do not paraphrase or summarize the code — I need the actual code as-is so I can reuse it.
6. PLAIN LANGUAGE: In one or two sentences, describe what this code is doing in business terms.
7. MATCH: Does the actual logic match the expected success? (Yes / No / Partially / Cannot determine)
8. GAPS: If the code is cut off or incomplete, note what is missing.

IMPORTANT: The SAS code in item 5 is the most important part. Copy it exactly. Do not skip it. Do not replace it with a description.
```
