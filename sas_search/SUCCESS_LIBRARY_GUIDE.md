# SAS Search — How to Use

5 standalone scripts to find and extract success logic from SAS files. Each script runs independently — open it, change the paths at the top, run it.

All scripts are in: `sas_search/scripts/`

---

## Scripts

| Script | What it does | Input | Output |
|--------|-------------|-------|--------|
| `step1_scan.ps1` | Finds all .sas files containing any mnemonic | Network folder + `keyword_mapping.csv` | CSV of matching files |
| `step2_tag.ps1` | Tags which mnemonics are in each file | Step 1 output + `keyword_mapping.csv` | CSV with mnemonic-file pairs |
| `step3_dedup.ps1` | Keeps one file per mnemonic (latest) | Step 2 output + `keyword_mapping.csv` | CSV with one row per mnemonic |
| `step4_extract.ps1` | Extracts code blocks around each mnemonic | Step 3 output + `keyword_mapping.csv` | Text file with annotated snippets |
| `step5_summary.ps1` | Status dashboard for all mnemonics | Step 3 output + `keyword_mapping.csv` | CSV summary |

---

## How to Run Any Script

Every script has the same structure at the top:

```
# === IN: ... ===
$inFile = "\\path\to\input.csv"

# === IN: mnemonic reference file ===
$mappingFile = "\\path\to\keyword_mapping.csv"

# === OUT: where results go ===
$outFile = "\\path\to\output.csv"
```

1. Open the script
2. Change the paths under `=== IN ===` and `=== OUT ===`
3. Run it

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

## Step 4 — Extract

The main script. Opens each SAS file and pulls code blocks around every mnemonic reference. Enriches each section with campaign info from `keyword_mapping.csv`.

**How it finds the mnemonic in the SAS code (in order):**
1. Quoted string — `'FTH'` or `"FTH"` (most precise)
2. Assignment — `mnemonic = FTH` or `mne = FTH`
3. Word boundary — any standalone `FTH` (fallback)

**Change these paths:**
- `$inFile` — the CSV from step 3 (or the v2 output: `sas_latest_per_mnemonic.csv`)
- `$mappingFile` — path to `keyword_mapping.csv`
- `$outFile` — where to save the text file

**Settings you can adjust:**
- `$contextAbove` — lines to show above each match (default: 20)
- `$contextBelow` — lines to show below each match (default: 20)
- `$maxBlocks` — max code blocks per mnemonic (default: 10)

**Output markers:**

| Marker | Meaning |
|--------|---------|
| `>>>` | Line where the mnemonic code appears |
| `*` | Line with success, flag, or indicator term |
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

## Using Existing v1/v2 Files

These scripts are backwards compatible. If you already ran v1 or v2, you can skip steps:

| You already have | Point it to | Then run from |
|-----------------|------------|---------------|
| `sas_mnemonic_files.csv` (v1 output) | Step 2 `$inFile` | Step 2 |
| `sas_success_by_mnemonic.csv` (v2 section 1) | Step 3 `$inFile` | Step 3 |
| `sas_latest_per_mnemonic.csv` (v2 section 2) | Step 4 `$inFile` | Step 4 |

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

---

## Reference Files

| File | What it is |
|------|-----------|
| `keyword_mapping.csv` | Master list of all campaigns — source of truth |
| `keyword_mapping_final.csv` | Campaigns grouped by product (reference only, not used by scripts) |
