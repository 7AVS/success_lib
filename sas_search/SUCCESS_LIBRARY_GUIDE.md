# NBA Success Library — How It Works

## What Is This?

Every time we send a customer an NBA (Next Best Action) recommendation — like "open a mortgage" or "upgrade your credit card" — we need to measure **did it work?** Did the customer actually do the thing we suggested?

That measurement is called the **success definition**. For example:
- We recommended a mortgage (**FTH**) → Did the customer get a mortgage funded? That's success.
- We recommended a credit card (**PCQ**) → Did the customer open and activate a card? That's success.

The problem: these success definitions are buried inside **hundreds of SAS code files** across the network, written by different people over the years. There's no single place to look them up.

**The Success Library solves this.** It's an automated pipeline that finds, extracts, and organizes the success logic for every NBA campaign — so we don't have to dig through code manually.

---

## The 46 NBA Campaigns

Each campaign has a **3-letter code** (called a mnemonic). Here are some examples:

| Code | Campaign | What Success Looks Like |
|------|----------|------------------------|
| FTH | First Time Homebuyer | Mortgage opened / funded |
| MOM | Mortgage Maturity Touchpoint | Mortgage retained / renewed |
| PCQ | Cards Acquisition | Credit card opened and activated |
| GIS | GIC Exclusive Rate | GIC investment opened |
| NMI | NOMI Find & Save | NOMI feature enrolled / activated |
| O2P | Pre-approved Overdraft | Overdraft opened |

The full list of all 46 campaigns lives in the reference file: **`keyword_mapping.csv`**

---

## How the Pipeline Works

The pipeline runs in **5 steps**, each one narrowing down the search. Think of it as a funnel:

```
  STEP 1                  Scan the entire network for SAS files
  ~hundreds of files      mentioning any of our 46 campaign codes.
        |
        v
  STEP 2                  For each file found, identify exactly
  ~tagged pairs           which campaigns it contains, when it
                          was last updated, and whether it mentions
                          "success" anywhere.
        |
        v
  STEP 3                  Keep only ONE file per campaign — the most
  ~46 files (1 per        relevant one (preferring files that mention
   campaign)              "success", then the most recently modified).
        |
        v
  STEP 4                  Open each file and pull out the specific
  ~code snippets          code sections where the campaign code is
                          referenced. This is where the success
                          logic lives.
        |
        v
  STEP 5                  Generate a summary showing the status
  ~status dashboard       of all 46 campaigns: found or not found,
                          has success logic or not.
```

---

## What Gets Produced (The Output Files)

The pipeline creates **5 output files** in the `pipeline` folder:

### 1. `step1_scan.csv` — The Broad Search Results

A list of every SAS file on the network that mentions any of our 46 campaign codes. This is the starting point — casting a wide net.

| Column | What It Tells You |
|--------|-------------------|
| FileName | Name of the SAS file |
| FolderPath | Which folder it's in |
| FullPath | Full network path to the file |

---

### 2. `step2_tagged.csv` — Files Mapped to Campaigns

Each row connects a specific campaign code to a specific file. One file may appear multiple times if it contains logic for several campaigns.

| Column | What It Tells You |
|--------|-------------------|
| Mnemonic | The 3-letter campaign code (e.g., FTH) |
| FileName | Name of the SAS file |
| LastModified | When the file was last updated |
| FullPath | Full network path |
| MnemonicCount | How many different campaigns this file covers |
| HasSuccess | Does the file contain the word "success"? (Yes/No) |

---

### 3. `step3_latest.csv` — One File Per Campaign (Deduplicated)

The **best candidate file** for each campaign. "Best" means:
- First preference: files that contain the word "success" (strongest signal)
- Second preference: the most recently modified file (most current logic)

Same columns as step 2, but only one row per campaign.

---

### 4. `step4_extracts.txt` — The Main Output

**This is the key deliverable.** For each campaign, it shows:
- What the campaign is and what success should look like
- Which SAS file the logic was found in
- The actual code snippets where the campaign is referenced

Each campaign section looks like this:

```
################################################################################
MNEMONIC:         FTH
DESCRIPTION:      First Time Homebuyer with FHSA
PRODUCT:          Mortgage
EVENT:            Acquisition / Product Open
EXPECTED SUCCESS: Mortgage Open
################################################################################
FILE:          some_program.sas
PATH:          \\network\path\some_program.sas
MODIFIED:      2024-11-15 09:30:00
MATCH METHOD:  quoted string
REFERENCES:    3 occurrence(s) in file
HAS 'SUCCESS': Yes
--------------------------------------------------------------------------------

--- Block 1 of 2  (Lines 230 - 270) ---
       230: proc sql;
       231:   create table work.fth_results as
       232:   select client_id,
 ?     233:   where campaign_type = 'MORTGAGE'
>>>    234:     and mnemonic = 'FTH'
 *     235:     and success_flag = 1
       236:     and funded_date is not null
       237: ;
```

**What the markers mean:**

| Marker | Meaning |
|--------|---------|
| `>>>` | This line references the campaign code — the anchor point |
| `*` | This line mentions success, flag, or indicator — likely part of the success definition |
| `?` | This line contains conditional logic (if/where/case) — likely a rule or filter |
| (blank) | Context line — surrounding code for understanding |

---

### 5. `step5_summary.csv` — Campaign Status Dashboard

A one-row-per-campaign overview showing where we stand:

| Column | What It Tells You |
|--------|-------------------|
| Mnemonic | Campaign code |
| Description | What the campaign does |
| Product | Product category (Mortgage, Credit Card, etc.) |
| ExpectedSuccess | What we believe success looks like |
| FileFound | Did we find a SAS file for this campaign? (Yes/No) |
| HasSuccessTerm | Does that file mention "success"? (Yes/No) |
| FileName | Which file was selected |
| LastModified | When that file was last updated |

Use this to quickly see:
- Which campaigns have good coverage (FileFound = Yes, HasSuccessTerm = Yes)
- Which campaigns need manual investigation (FileFound = No, or HasSuccessTerm = No)

---

## How to Use the Extracts

1. Open **`step4_extracts.txt`**
2. Search for the campaign code you're interested in (e.g., `FTH`)
3. Read the code blocks — look for lines marked with `>>>` (campaign reference) and `*` (success logic)
4. Compare what the code does against the **EXPECTED SUCCESS** listed in the header
5. For faster review, submit the file to an LLM and ask it to summarize the success definition for each campaign

---

## How to Add New Campaigns

When new NBA campaigns are created:

1. Open **`keyword_mapping.csv`**
2. Add a new row with the campaign's mnemonic, description, product, and expected success outcome
3. Re-run the pipeline — it reads the campaign list from this file automatically

No code changes needed.

---

## Reference Files

| File | Purpose | Location |
|------|---------|----------|
| `keyword_mapping.csv` | Master list of all 46 campaigns with descriptions and expected success outcomes | `sas_search/` |
| `keyword_mapping_final.csv` | Campaigns grouped by product category | `sas_search/` |
| `v3_pipeline.ps1` | The pipeline script (runs all 5 steps) | `sas_search/scripts/` |

---

## Quick Reference: Running the Pipeline

```powershell
# Run the full pipeline (skips steps that already have output)
.\sas_search\scripts\v3_pipeline.ps1

# Force a step to re-run: delete its output file, then run again
Remove-Item "...\pipeline\step2_tagged.csv"
.\sas_search\scripts\v3_pipeline.ps1
```

The pipeline is safe to re-run at any time. It picks up where it left off.
