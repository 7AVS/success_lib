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
3. KEYWORDS MATCHED: which of the mapped keywords actually appeared in the relevant code blocks (not all keyword hits — only the ones that matter)
4. SAS CODE: Copy the exact SAS code that defines or measures success for this mnemonic. Include the full code block — the SQL/SAS statements, WHERE clauses, IF conditions, CASE statements, table references, and variable assignments that determine success. Copy the code exactly as it appears in the extract. If the success logic spans multiple blocks, include all relevant blocks. Do not paraphrase or summarize the code — I need the actual code as-is so I can reuse it.
5. PLAIN LANGUAGE: In one or two sentences, describe what this code is doing in business terms.
6. MATCH: Does the actual logic match the expected success? (Yes / No / Partially / Cannot determine)
7. GAPS: If the code is cut off or incomplete, note what is missing.

IMPORTANT: The SAS code in item 4 is the most important part. Copy it exactly. Do not skip it. Do not replace it with a description.
```
