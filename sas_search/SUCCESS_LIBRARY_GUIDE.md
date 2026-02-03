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

## The Scripts — Overview

| Script | What it does | Input | Output |
|--------|-------------|-------|--------|
| `step1_scan.ps1` | Finds all .sas files containing any mnemonic | Network folder + `keyword_mapping.csv` | CSV of matching files |
| `step2_tag.ps1` | Tags which mnemonics are in each file | Step 1 output + `keyword_mapping.csv` | CSV with mnemonic-file pairs |
| `step3_dedup.ps1` | Keeps one file per mnemonic (latest) | Step 2 output + `keyword_mapping.csv` | CSV with one row per mnemonic |
| `step4_extract.ps1` | Extracts code blocks around the mnemonic reference | Step 3 output + `keyword_mapping.csv` | Text file (client selection context) |
| `step4a_extract_success.ps1` | Extracts code blocks around the word "success" | Step 3 output + `keyword_mapping.csv` | Text file (success logic context) |
| `step4b_extract_keywords.ps1` | Extracts code blocks around mapped keywords | Step 3 output + `keyword_mapping.csv` | Text file (keyword-matched context) |
| `step5_summary.ps1` | Status dashboard for all mnemonics | Step 3 output + `keyword_mapping.csv` | CSV summary |

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

Opens each file from step 1 and records which specific mnemonics are inside it, when it was last modified, and whether it contains the word "success".

**Change these paths:**
- `$inFile` — the CSV from step 1 (or the v1 output: `sas_mnemonic_files.csv`)
- `$mappingFile` — path to `keyword_mapping.csv`
- `$outFile` — where to save the results

**Output columns:** Mnemonic, FileName, LastModified, FullPath, MnemonicCount, HasSuccess

---

## Step 3 — Deduplicate

Keeps only one file per mnemonic. Prefers files that contain "success", then picks the most recently modified.

**Change these paths:**
- `$inFile` — the CSV from step 2 (or the v2 output: `sas_success_by_mnemonic.csv`)
- `$mappingFile` — path to `keyword_mapping.csv`
- `$outFile` — where to save the results

**Output columns:** same as step 2, one row per mnemonic

---

## Step 4 — Extract (3 Versions)

There are three versions of step 4. Each one searches the SAS files differently. Use whichever gives the best results — or run all three.

### Step 4 (original) — `step4_extract.ps1`

Searches for the **mnemonic code itself** (`'FTH'`, `"FTH"`) in the SAS file. Useful for seeing where the mnemonic is referenced, but this usually pulls the **client selection code** (who got the campaign), not the success measurement.

### Step 4a — `step4a_extract_success.ps1`

Searches for the word **"success"** in the SAS file. Pulls 20 lines above and 20 below each match. This targets the actual success measurement logic directly.

### Step 4b — `step4b_extract_keywords.ps1`

Searches for the **mapped keywords** specific to each mnemonic (from the `Suggested_Keywords` column in `keyword_mapping.csv`). For example, for FTH it searches for "mortgage, open, approved, funded, fhsa, homebuyer, close, booked". The `>>>` markers show which keyword matched.

**All three versions use the same input and paths:**
- `$inFile` — the CSV from step 3 (or the v2 output: `sas_latest_per_mnemonic.csv`)
- `$mappingFile` — path to `keyword_mapping.csv`
- `$outFile` — where to save the text file

**Settings you can adjust (in step 4, 4a, and 4b):**
- `$contextAbove` — lines to show above each match (default: 20)
- `$contextBelow` — lines to show below each match (default: 20)
- `$maxBlocks` — max code blocks per mnemonic (default: 10)

**Output markers:**

| Marker | Meaning |
|--------|---------|
| `>>>` | Line where the search term was found (mnemonic, "success", or keyword) |
| `>>>[keyword]` | (step 4b only) Shows which keyword matched |
| `*` | (step 4 only) Line with success/flag/indicator term |
| `?` | Line with conditional logic (if/where/case/when) |
| (blank) | Context line |

---

## Step 5 — Summary

Generates a dashboard CSV showing the status of every mnemonic: found or not, has success logic or not.

**Change these paths:**
- `$inFile` — the CSV from step 3 (or the v2 output: `sas_latest_per_mnemonic.csv`)
- `$mappingFile` — path to `keyword_mapping.csv`
- `$outFile` — where to save the summary

**Output columns:** Mnemonic, Description, Product, ExpectedSuccess, FileFound, HasSuccessTerm, FileName, LastModified

---

## Using Helios Assist to Extract Success Definitions

After running step 4a or 4b, you'll have a text file with SAS code extracts. The next step is to submit that file to **Helios Assist** to identify and extract the actual success code.

### File Size Limit

Helios Assist has a limit of approximately **12,800 characters (~250 KB)** per submission. If your output file is larger than that, you need to split it.

### How to Check File Size

1. Find the output file in File Explorer
2. Right-click it and select **Properties**
3. Look at the **Size** field
4. If it's over 250 KB, you need to split it (see below)

### How to Split the File

The output file is organized by mnemonic — each section starts with a line of `####`. You can split by copying groups of mnemonics into separate text files.

1. Open the output file in VS Code
2. Use **Ctrl+F** and search for `####` to jump between mnemonic sections
3. Select a group of mnemonic sections (aim for under 250 KB each)
4. Copy (**Ctrl+C**) and paste (**Ctrl+V**) into a new file
5. Save each chunk as `part1.txt`, `part2.txt`, etc.

Alternatively, you can estimate: each mnemonic section is roughly 2-5 KB. So a 500 KB file with 46 mnemonics could be split into 2 files of ~23 mnemonics each.

### Submitting to Helios Assist

There are two phases. Phase 1 is a quick scan. Phase 2 is the detailed extraction.

The prompt files are in: `sas_search/prompts/`

| Prompt file | Use with |
|-------------|----------|
| `prompt_step4a_success.md` | Output from `step4a_extract_success.ps1` |
| `prompt_step4b_keywords.md` | Output from `step4b_extract_keywords.ps1` |

### Phase 1 — Scan and Categorize (do this first)

This is a quick pass to find out which mnemonics have usable code and which are noise.

1. Open the prompt file that matches your step 4 version
2. Upload your output file (or paste the content) to Helios Assist
3. Copy the **PHASE 1** prompt from the prompt file and paste it into Helios Assist
4. Submit

Helios will return a table like:

| Mnemonic | Category | Note |
|----------|----------|------|
| FTH | COMPLETE | Success defined as mortgage funded within 90 days |
| MOM | LABEL ONLY | "success" appears in a column alias only |
| PCQ | PARTIAL | Card activation check visible but cutoff |

**What the categories mean:**

For step 4a output:
| Category | Meaning | Action |
|----------|---------|--------|
| COMPLETE | Full success logic is visible | Proceed to Phase 2 |
| PARTIAL | Some logic visible but cut off | Proceed to Phase 2 |
| LABEL ONLY | "success" is just a variable name, no logic | Skip — not useful |
| UNCLEAR | Cannot determine | Skip or investigate manually |

For step 4b output:
| Category | Meaning | Action |
|----------|---------|--------|
| USEFUL | Code clearly relates to success measurement | Proceed to Phase 2 |
| PARTIAL | Some relevant logic but incomplete | Proceed to Phase 2 |
| NOISE | Keywords matched but code is unrelated | Skip — not useful |
| UNCLEAR | Cannot determine | Skip or investigate manually |

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

1. Split the file as described above
2. Run Phase 1 on each part separately
3. Combine the Phase 1 tables from all parts
4. Run Phase 2 only for the usable mnemonics (you can combine them into one Phase 2 request if it fits)

---

## Using Existing v1/v2 Files

These scripts are backwards compatible. If you already ran v1 or v2, you can skip steps:

| You already have | Point it to | Then run from |
|-----------------|------------|---------------|
| `sas_mnemonic_files.csv` (v1 output) | Step 2 `$inFile` | Step 2 |
| `sas_success_by_mnemonic.csv` (v2 section 1) | Step 3 `$inFile` | Step 3 |
| `sas_latest_per_mnemonic.csv` (v2 section 2) | Step 4/4a/4b `$inFile` | Step 4 |

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
| `step1_scan.ps1` | `sas_search/scripts/` | Broad scan script |
| `step2_tag.ps1` | `sas_search/scripts/` | Tagging script |
| `step3_dedup.ps1` | `sas_search/scripts/` | Deduplication script |
| `step4_extract.ps1` | `sas_search/scripts/` | Extract around mnemonic reference |
| `step4a_extract_success.ps1` | `sas_search/scripts/` | Extract around "success" keyword |
| `step4b_extract_keywords.ps1` | `sas_search/scripts/` | Extract around mapped keywords |
| `step5_summary.ps1` | `sas_search/scripts/` | Summary dashboard |
| `prompt_step4a_success.md` | `sas_search/prompts/` | Helios prompts for step 4a output |
| `prompt_step4b_keywords.md` | `sas_search/prompts/` | Helios prompts for step 4b output |
