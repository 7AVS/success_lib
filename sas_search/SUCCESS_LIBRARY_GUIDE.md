# SAS Search — How to Use

This guide covers how to run the scripts, interpret the outputs, and use Helios Assist to extract the success definitions from the results.

All scripts are in: `sas_search/scripts/`
All prompts are in: `sas_search/prompts/`

---

## Getting Started — Setting Up VS Code

You need VS Code to open and run the scripts. If you already have it set up, skip to the next section.

### Opening VS Code

1. Open **VS Code** from your Start menu or taskbar
2. Go to **File > Open Folder** and navigate to the Success Library folder on the network drive
3. On the left panel you'll see the file explorer — expand `sas_search/scripts/` to see all scripts

### Opening the Terminal

You need a PowerShell terminal to run the scripts.

1. In VS Code, go to **Terminal > New Terminal** (or press `` Ctrl+` ``)
2. A panel opens at the bottom of VS Code — this is your terminal
3. Make sure it says **PowerShell** in the top-right of the terminal panel. If it says something else (like "bash" or "cmd"), click the dropdown arrow next to the `+` button and select **PowerShell**
4. You're ready to run scripts

### Running a Script

1. Open the script file in VS Code (click it in the left panel)
2. Change the paths at the top (see each step below for details)
3. Save the file (**Ctrl+S**)
4. In the terminal, type the path to the script and press Enter:
   ```
   .\sas_search\scripts\step1_scan.ps1
   ```
   Or right-click the script file in the left panel and select **Run in Terminal**

---

## Quick Search — Single Mnemonic Lookup

If you need to look up one mnemonic (or a small handful), use `quick_search.ps1`. It does everything in one script — scan, tag, and extract — with no CSVs or pipeline steps.

**Script:** `sas_search/scripts/quick_search.ps1`

### How to Use

1. Open the script in VS Code
2. Edit the three sections at the top:

```
# Your mnemonics (one or many)
$mnemonics = @("FTH", "MOM")

# Your keywords (searched IN ADDITION to "success" which is always included)
$keywords = @("mortgage", "open", "funded", "approved", "maturity", "retain")

# Paths
$searchPath = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\..."
$outFile    = "\\maple.fg.rbc.com\data\...\quick_search_output.txt"
```

3. Save (**Ctrl+S**)
4. Run in terminal:
   ```
   .\sas_search\scripts\quick_search.ps1
   ```

### What It Does

| Step | Action |
|------|--------|
| 1/3 Scan | Finds all `.sas` files on the network that contain your mnemonics |
| 2/3 Tag | For each file, records which of your mnemonics it actually contains |
| 3/3 Extract | Pulls code blocks (20 lines above / 20 lines below) around every line that contains "success" or any of your keywords |

### Output

A single text file with code blocks grouped by mnemonic. Each block is annotated with line markers:

| Marker | Meaning |
|--------|---------|
| `>>>` | Line where "success" was found |
| `>>>[keyword]` | Line where one of your keywords was found (keyword name shown) |
| `?` | Line with conditional logic (if/where/case/when) |
| (blank) | Context line |

### Settings

These can be adjusted but usually don't need to be:

| Setting | Default | What it controls |
|---------|---------|-----------------|
| `$contextAbove` | 20 | Lines to show above each keyword match |
| `$contextBelow` | 20 | Lines to show below each keyword match |
| `$maxBlocks` | 10 | Max code blocks per mnemonic-file pair |

### When to Use Quick Search vs the Pipeline

| Scenario | Use |
|----------|-----|
| Looking up 1-3 mnemonics, want fast results | **Quick Search** |
| Running a batch of many mnemonics | **Pipeline** (step 1 - 4a) |
| Need to submit results to Helios Assist for AI extraction | **Pipeline** (structured output with headers) |
| Need a summary dashboard of all mnemonics | **Pipeline** (step 5) |

Quick Search is ideal for ad-hoc investigation — when you need to quickly see what SAS code exists for a specific campaign before deciding next steps.

---

## The Pipeline

The default pipeline is:

```
Step 1 (scan) → Step 2 (tag) → Step 4a (extract) → Split → Helios Assist
```

| Script | What it does | Input | Output |
|--------|-------------|-------|--------|
| `step1_scan.ps1` | Finds all .sas files containing any mnemonic | Network folder + `keyword_mapping.csv` | CSV of matching files |
| `step2_tag.ps1` | Tags which mnemonics are in each file | Step 1 output + `keyword_mapping.csv` | CSV with mnemonic-file pairs |
| `step4a_extract_success.ps1` | Extracts code blocks around the word "success" | Step 2 output + `keyword_mapping.csv` | Text file with code extracts |
| `split_extracts.ps1` | Splits large text files for Helios | Any step 4 text output | Multiple text files (part1.txt, part2.txt, etc.) |

**If step 4a has gaps** (mnemonics came back as NOISE or LABEL ONLY from Helios):

| Script | What it does |
|--------|-------------|
| `step4b_extract_keywords.ps1` | Fallback — extracts code blocks around mapped business keywords |

**Other tools:**

| Script | What it does |
|--------|-------------|
| `step5_summary.ps1` | Dashboard CSV — status of every mnemonic |
| `step3_dedup.ps1` | Optional — narrows to one file per mnemonic (not used in default pipeline) |
| `step4_extract.ps1` | Legacy — extracts around mnemonic reference (finds client selection code, not success logic) |

Each script is standalone. You can run any one of them by itself as long as you have the input file it needs.

---

## How to Edit Any Script

Every script has the same layout at the top — paths marked with `=== IN ===` and `=== OUT ===`:

```
# === IN: ... ===
$inFile = "\\path\to\input.csv"

# === IN: mnemonic reference file ===
$mappingFile = "\\path\to\keyword_mapping.csv"

# === OUT: where results go ===
$outFile = "\\path\to\output.csv"
```

1. Open the script in VS Code
2. Change only the text between the quotes `"..."` for each path
3. Save (**Ctrl+S**)
4. Run the script

The output folder is created automatically if it doesn't exist.

---

## Step 1 — Scan

Scans a network folder for `.sas` files that contain any mnemonic code. This is the slow step (network search).

**Change these paths:**
- `$searchPath` — the root folder to search
- `$mappingFile` — path to `keyword_mapping.csv`
- `$outFile` — where to save the results

**Output columns:** FileName, FolderPath, FullPath

---

## Step 2 — Tag

Opens each file from step 1 and records which specific mnemonics are inside it, when it was last modified, and whether it contains the word "success". Also reports which mnemonics from `keyword_mapping.csv` were not found in any file.

Step 2 keeps **all files per mnemonic** — no deduplication. A mnemonic that appears in 5 different SAS files will have 5 rows.

**Change these paths:**
- `$inFile` — the CSV from step 1 (or the v1 output: `sas_mnemonic_files.csv`)
- `$mappingFile` — path to `keyword_mapping.csv`
- `$outFile` — where to save the results

**Output columns:** Mnemonic, FileName, LastModified, FullPath, HasSuccess

---

## Step 4a — Extract (default)

Searches for the word **"success"** in each SAS file. Pulls 20 lines above and 20 below each match. This targets the actual success measurement logic directly.

Since step 2 keeps all files per mnemonic, step 4a will extract from **every file** for each mnemonic. The same mnemonic may produce multiple sections in the output — one per file. The Helios prompts handle this by asking the AI to compare versions and pick the best one.

**Change these paths:**
- `$inFile` — the CSV from step 2
- `$mappingFile` — path to `keyword_mapping.csv`
- `$outFile` — where to save the text file

**Settings you can adjust:**
- `$contextAbove` — lines to show above each match (default: 20)
- `$contextBelow` — lines to show below each match (default: 20)
- `$maxBlocks` — max code blocks per mnemonic per file (default: 10)

**Output markers:**

| Marker | Meaning |
|--------|---------|
| `>>>` | Line where "success" was found |
| `?` | Line with conditional logic (if/where/case/when) |
| (blank) | Context line |

---

## Step 4b — Extract (fallback)

Searches for **mapped keywords** specific to each mnemonic (from the `Suggested_Keywords` column in `keyword_mapping.csv`). For example, for FTH it searches for "mortgage, open, approved, funded, fhsa, homebuyer, close, booked".

Use this only for mnemonics where step 4a didn't find usable code — meaning the word "success" wasn't helpful but the actual logic might use business-specific terms instead.

**Same paths and settings as step 4a.**

**Additional output marker:**

| Marker | Meaning |
|--------|---------|
| `>>>[keyword]` | Line where a mapped keyword was found (keyword name in brackets) |

---

## Split Script — `split_extracts.ps1`

Splits large step 4 output files into smaller parts that fit within Helios Assist's character limit. Splits on mnemonic section boundaries (never cuts a section in half).

**Change these paths:**
- `$inFile` — the text file to split (any step 4a/4b output)
- `$outFolder` — folder where parts go (created automatically)
- `$maxChars` — max characters per part (default: 275,000)

**Output:** `part1.txt`, `part2.txt`, etc. in the output folder. If a single mnemonic section is larger than the limit, it gets saved as its own part with a warning.

---

## Step 5 — Summary

Generates a dashboard CSV showing the status of every mnemonic: found or not, how many files, which have success logic.

**Change these paths:**
- `$inFile` — the CSV from step 2
- `$mappingFile` — path to `keyword_mapping.csv`
- `$outFile` — where to save the summary

**Output columns:** Mnemonic, Description, Product, ExpectedSuccess, FileFound, FileCount, HasSuccessTerm, Files, LatestModified

---

## Using Helios Assist to Extract Success Definitions

After running step 4a, you'll have a text file with SAS code extracts. The next step is to submit that file to **Helios Assist** to identify and extract the actual success code.

### File Size Limit

Helios Assist has a limit of approximately **275,000 characters** per submission. If your output file is larger than that, split it using `split_extracts.ps1`.

### Submitting to Helios Assist

There are two phases. Phase 1 is a quick scan. Phase 2 is the detailed extraction.

The prompt files are in: `sas_search/prompts/`

| Prompt file | Use with |
|-------------|----------|
| `prompt_broad_4a_success.md` | Step 4a output (default — multiple files per mnemonic) |
| `prompt_broad_4b_keywords.md` | Step 4b output (fallback — multiple files per mnemonic) |
| `prompt_step4a_success.md` | Step 4a output if you used optional step 3 dedup (one file per mnemonic) |
| `prompt_step4b_keywords.md` | Step 4b output if you used optional step 3 dedup (one file per mnemonic) |

For the default pipeline (no step 3), use the **broad** prompts. These handle multiple files per mnemonic — they ask the AI to compare versions by file name and date, then pick the best one.

### Recommended Workflow

1. **Run the default pipeline**: step 1 → step 2 → step 4a → split if needed
2. **Submit to Helios** with `prompt_broad_4a_success.md` — run Phase 1
3. **Review Phase 1 results.** Note which mnemonics came back as LABEL ONLY, NOISE, or UNCLEAR
4. **For those gaps**: run step 4b for those mnemonics → submit with `prompt_broad_4b_keywords.md`

### Phase 1 — Scan and Categorize (do this first)

This is a quick pass to find out which mnemonics have usable code and which are noise.

1. Open the prompt file that matches your extraction type
2. Upload your output file (or paste the content) to Helios Assist
3. Copy the **PHASE 1** prompt from the prompt file and paste it into Helios Assist
4. Submit

Helios will return a categorization table:

| Mnemonic | File | Modified | Category | Note |
|----------|------|----------|----------|------|
| FTH | prog_a.sas | 2024-11-15 | COMPLETE | Success defined as mortgage funded within 90 days |
| FTH | prog_b.sas | 2023-06-20 | NOISE | "mortgage" matched in a comment only |
| MOM | renew_v3.sas | 2024-09-01 | PARTIAL | Renewal flag visible but conditions cut off |

**Categories for step 4a output:**

| Category | Meaning | Action |
|----------|---------|--------|
| COMPLETE | Full success logic is visible | Proceed to Phase 2 |
| PARTIAL | Some logic visible but cut off | Proceed to Phase 2 |
| LABEL ONLY | "success" is just a variable name, no logic | Try step 4b |
| UNCLEAR | Cannot determine | Try step 4b |

**Categories for step 4b output:**

| Category | Meaning | Action |
|----------|---------|--------|
| USEFUL | Code clearly relates to success measurement | Proceed to Phase 2 |
| PARTIAL | Some relevant logic but incomplete | Proceed to Phase 2 |
| NOISE | Keywords matched but code is unrelated | Manual investigation needed |
| UNCLEAR | Cannot determine | Manual investigation needed |

### Phase 2 — Extract the Code (only for usable mnemonics)

This is where you get the actual SAS code — the asset we're building.

1. From the Phase 1 results, make a list of the mnemonics that came back as COMPLETE/USEFUL or PARTIAL
2. Copy the **PHASE 2** prompt from the same prompt file
3. Replace `[LIST THE COMPLETE AND PARTIAL ONES HERE]` with your list of mnemonics
4. Submit to Helios Assist

Helios will return for each mnemonic:
- The **expected success** (from the header)
- The **actual SAS code** copied from the extract — this is the main deliverable
- A **plain language** summary of what the code does
- Whether the code **matches** the expected success
- Any **gaps** if the code is incomplete

**Save the Phase 2 output.** The SAS code it returns is the success definition asset for your library.

### If the File is Too Large for One Submission

1. Split the file using `split_extracts.ps1`
2. Run Phase 1 on each part separately
3. Combine the Phase 1 tables from all parts
4. Run Phase 2 only for the usable mnemonics (you can combine them into one Phase 2 request if it fits)

---

## Using Existing v1/v2 Files

These scripts are backwards compatible. If you already ran v1 or v2, you can skip steps:

| You already have | Point it to | Then run from |
|-----------------|------------|---------------|
| `sas_mnemonic_files.csv` (v1 output) | Step 2 `$inFile` | Step 2 |
| `sas_success_by_mnemonic.csv` (v2 section 1) | Step 4a/4b `$inFile` | Step 4a |
| `sas_latest_per_mnemonic.csv` (v2 section 2) | Step 4a/4b `$inFile` | Step 4a |

The `HasSuccess` column is optional — if your file doesn't have it, the script computes it automatically.

---

## Adding New Campaigns

1. Open `keyword_mapping.csv`
2. Add a new row with the mnemonic, description, product, and expected success
3. Re-run from whatever step you need

The scripts read the mnemonic list from this file — no code changes needed.

**Key columns in keyword_mapping.csv:**

| Column | What it controls |
|--------|-----------------|
| `Mnemonic` | The campaign code to search for in SAS files |
| `Description` | Shows in step 4 output header |
| `Product` | Shows in step 4 output header |
| `Event_Type` | Shows in step 4 output header |
| `Event_Category` | Shows in step 4 output header |
| `Clean_Primary` | Shows as EXPECTED SUCCESS in step 4 output |
| `Primary_Subset` | Shows as SUBSET/QUALIFIER in step 4 output |
| `Suggested_Keywords` | Used by step 4b to search for business terms in SAS files |

---

## All Files Reference

| File | Location | What it is |
|------|----------|-----------|
| `keyword_mapping.csv` | `sas_search/` | Master list of all campaigns — source of truth |
| `keyword_mapping_final.csv` | `sas_search/` | Campaigns grouped by product (reference only) |
| `quick_search.ps1` | `sas_search/scripts/` | All-in-one single mnemonic lookup (scan + tag + extract) |
| `step1_scan.ps1` | `sas_search/scripts/` | Broad scan script |
| `step2_tag.ps1` | `sas_search/scripts/` | Tagging script (+ missing mnemonics report) |
| `step4a_extract_success.ps1` | `sas_search/scripts/` | Extract around "success" keyword (default) |
| `step4b_extract_keywords.ps1` | `sas_search/scripts/` | Extract around mapped keywords (fallback) |
| `step5_summary.ps1` | `sas_search/scripts/` | Summary dashboard |
| `split_extracts.ps1` | `sas_search/scripts/` | Split large text files for Helios Assist |
| `step3_dedup.ps1` | `sas_search/scripts/` | Optional — dedup to one file per mnemonic |
| `step4_extract.ps1` | `sas_search/scripts/` | Legacy — extract around mnemonic reference |
| `prompt_broad_4a_success.md` | `sas_search/prompts/` | Helios prompts for step 4a output (default) |
| `prompt_broad_4b_keywords.md` | `sas_search/prompts/` | Helios prompts for step 4b output (fallback) |
| `prompt_step4a_success.md` | `sas_search/prompts/` | Helios prompts for step 4a with optional dedup |
| `prompt_step4b_keywords.md` | `sas_search/prompts/` | Helios prompts for step 4b with optional dedup |
