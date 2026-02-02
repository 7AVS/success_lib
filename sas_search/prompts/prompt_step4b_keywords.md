# Prompt for Step 4B Output (Keyword Extracts)

## Instructions for use:
## 1. Upload the step4b_keyword_extracts.txt file
## 2. Copy-paste the PHASE 1 prompt below
## 3. Review the results — identify which mnemonics have usable code
## 4. For those mnemonics, copy-paste the PHASE 2 prompt

---

## PHASE 1 — Scan and Categorize

```
You are reviewing extracts from SAS code files. Each section represents one NBA campaign mnemonic (a 3-letter code like FTH, MOM, PCQ, etc.).

For each section, the code was pulled because specific business keywords appeared in the SAS file. The keywords used are listed in the KEYWORDS line of each section header. The extract shows 20 lines above and 20 lines below each keyword match. Lines marked with >>> show where a keyword was found, and the matching keyword is shown in brackets.

WARNING: Because these are keyword matches (not exact logic matches), many extracts will be noise — the keyword appeared but in an unrelated context. Your job is to separate signal from noise.

Your task: scan every mnemonic section and categorize it.

For EACH mnemonic in the file, give me one row with:
- Mnemonic code
- Category (see below)
- One-line note explaining what you see

Categories:
- USEFUL: The extract contains code that is clearly related to measuring the success of this campaign — you can see outcome logic (did the client do the thing?)
- PARTIAL: Some relevant logic is visible but it's incomplete or mixed with unrelated code
- NOISE: The keywords matched but the code is unrelated to success measurement — it's client selection, data prep, reporting, or something else entirely
- UNCLEAR: Cannot determine from the extract

Format your response as a table. Do not explain the SAS code. Do not summarize each block. Just categorize.

If a mnemonic has multiple blocks, base your category on the BEST block (the one most likely to contain success logic).

Example output:
| Mnemonic | Category | Note |
|----------|----------|------|
| FTH | USEFUL | Block 3 shows mortgage funding check with date condition |
| MOM | NOISE | "mature" keyword matched a date variable, not success logic |
| GIS | PARTIAL | GIC deposit check visible but amount threshold cut off |
```

---

## PHASE 2 — Extract Success Definitions

Use this AFTER Phase 1. Only ask about mnemonics that came back as USEFUL or PARTIAL.

```
From the same file, I need you to extract the success definition for the following mnemonics: [LIST THE USEFUL AND PARTIAL ONES HERE]

For each mnemonic, provide:

1. MNEMONIC: the 3-letter code
2. EXPECTED SUCCESS: (this is already in the section header — copy it)
3. KEYWORDS MATCHED: which of the mapped keywords actually appeared in the useful code (not all keyword hits — only the ones in the relevant blocks)
4. ACTUAL SUCCESS LOGIC: Describe in plain language what the SAS code is checking. What conditions must be true for a client to be counted as "successful"? Be specific — include table names, column names, date ranges, or flag values if visible.
5. MATCH: Does the actual logic match the expected success? (Yes / No / Partially / Cannot determine)
6. GAPS: If there are missing pieces or the code is cut off, note what is missing.

Keep each answer short and factual. Do not explain SAS syntax. Focus on the business logic — what is being measured.
```
