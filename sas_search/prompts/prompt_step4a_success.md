# Prompt for Step 4A Output (Success Keyword Extracts)

## Instructions for use:
## 1. Upload the step4a_success_extracts.txt file
## 2. Copy-paste the PHASE 1 prompt below
## 3. Review the results — identify which mnemonics have usable code
## 4. For those mnemonics, copy-paste the PHASE 2 prompt

---

## PHASE 1 — Scan and Categorize

```
You are reviewing extracts from SAS code files. Each section in this file represents one NBA campaign mnemonic (a 3-letter code like FTH, MOM, PCQ, etc.).

For each section, the code was pulled because the word "success" appeared in the SAS file. The extract shows 20 lines above and 20 lines below each "success" occurrence.

Your task: scan every mnemonic section and categorize it.

For EACH mnemonic in the file, give me one row with:
- Mnemonic code
- Category (see below)
- One-line note explaining what you see

Categories:
- COMPLETE: The extract contains actual success measurement logic — you can see how success is defined (what conditions, what tables, what flags)
- PARTIAL: There is some success logic visible but it's cut off or incomplete — you can see pieces but not the full picture
- LABEL ONLY: The word "success" appears but only as a variable name, column header, or label — no actual logic visible
- UNCLEAR: Cannot determine — the code is too fragmented or context is missing

Format your response as a table. Do not explain the SAS code. Do not summarize each section. Just categorize.

Example output:
| Mnemonic | Category | Note |
|----------|----------|------|
| FTH | COMPLETE | Success defined as mortgage funded within 90 days |
| MOM | LABEL ONLY | "success" appears in a column alias only |
| PCQ | PARTIAL | Card activation check visible but cutoff before conditions |
```

---

## PHASE 2 — Extract Success Definitions

Use this AFTER Phase 1. Only ask about mnemonics that came back as COMPLETE or PARTIAL.

```
From the same file, I need you to extract the success definition for the following mnemonics: [LIST THE COMPLETE AND PARTIAL ONES HERE]

For each mnemonic, provide:

1. MNEMONIC: the 3-letter code
2. EXPECTED SUCCESS: (this is already in the section header — copy it)
3. ACTUAL SUCCESS LOGIC: Describe in plain language what the SAS code is checking. What conditions must be true for a client to be counted as "successful"? Be specific — include table names, column names, date ranges, or flag values if visible.
4. MATCH: Does the actual logic match the expected success? (Yes / No / Partially / Cannot determine)
5. GAPS: If there are missing pieces or the code is cut off, note what is missing.

Keep each answer short and factual. Do not explain SAS syntax. Focus on the business logic — what is being measured.
```
