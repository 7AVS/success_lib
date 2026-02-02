<#
.SYNOPSIS
    NBA Success Library - Automated SAS Discovery Pipeline v3

.DESCRIPTION
    Finds SAS files containing NBA mnemonics, tags them, deduplicates
    to the latest version, and extracts logic blocks around mnemonic
    references for success definition review.

    Steps:
      0. SETUP    - Load mnemonics from keyword_mapping.csv
      1. SCAN     - Find .sas files containing any mnemonic
      2. TAG      - Map each file to specific mnemonics found
      3. DEDUP    - Keep latest file per mnemonic (prefer files with 'success')
      4. EXTRACT  - Pull annotated logic blocks around mnemonic references
      5. SUMMARY  - Status report for all mnemonics

    Steps 1-3 skip if output already exists (delete output to re-run).
    Steps 4-5 always regenerate.

    Output legend (step 4):
      >>>  = line where mnemonic is referenced
       *   = line with success/flag/indicator term
       ?   = line with conditional logic (if/where/case/when)

.NOTES
    To add new campaigns: add rows to keyword_mapping.csv and re-run.
    To re-scan from scratch: delete the pipeline output folder.

    BACKWARDS COMPATIBILITY:
    You can reuse existing v1/v2 output files by setting the input
    overrides below. The pipeline will pick up from whatever step
    you have data for. Required CSV columns per step:
      Step 1 input: FileName, FolderPath, FullPath
      Step 2 input: Mnemonic, FileName, LastModified, FullPath
      Step 3 input: Mnemonic, FileName, LastModified, FullPath
    The HasSuccess column is optional — computed on the fly if missing.
#>

# ================================================================
# CONFIGURATION - Update these paths for your environment
# ================================================================

# Where to scan for .sas files
$scanPath = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics"

# Base output directory (all pipeline results go here)
$outDir = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline"

# Mnemonic reference file (source of truth for campaigns)
$mappingFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\sas_search\keyword_mapping.csv"

# Extraction settings
$contextAbove    = 20    # lines above each mnemonic match
$contextBelow    = 20    # lines below each mnemonic match
$maxBlocksPerFile = 10   # max extracted blocks per mnemonic-file pair

# ================================================================
# INPUT OVERRIDES - Point to existing v1/v2 files to skip steps
# ================================================================
# Set any of these to reuse files you already have.
# Leave as $null to use this pipeline's own outputs.
#
# Examples (uncomment and adjust path):
#   $step1Input = "...\sas_mnemonic_files.csv"
#   $step3Input = "...\sas_latest_per_mnemonic.csv"

$step1Input = $null   # Existing broad scan   (needs: FileName, FolderPath, FullPath)
$step2Input = $null   # Existing tagged file   (needs: Mnemonic, FileName, LastModified, FullPath)
$step3Input = $null   # Existing deduped file  (needs: Mnemonic, FileName, LastModified, FullPath)


# ================================================================
# STEP 0: SETUP - Load mnemonic reference
# ================================================================
Write-Host ""
Write-Host "=== STEP 0: Setup ===" -ForegroundColor Cyan

if (-not (Test-Path $mappingFile)) {
    Write-Host "  ERROR: Mapping file not found: $mappingFile" -ForegroundColor Red
    Write-Host "  Update the mappingFile path in CONFIGURATION." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $outDir)) {
    New-Item -Path $outDir -ItemType Directory -Force | Out-Null
    Write-Host "  Created output directory: $outDir"
}

$mapping = Import-Csv $mappingFile
$mapping = $mapping | Where-Object { $_.Mnemonic -and $_.Mnemonic.Trim() -ne '' }
$mnemonics = $mapping.Mnemonic

# Sort longest-first so VBA_LTA is tried before VBA in regex
$regexPattern = ($mnemonics | Sort-Object { $_.Length } -Descending) -join '|'

Write-Host "  Loaded $($mnemonics.Count) mnemonics from mapping file"

# Build lookup table for enrichment
$mneLookup = @{}
foreach ($row in $mapping) {
    $mneLookup[$row.Mnemonic] = $row
}


# ================================================================
# STEP 1: SCAN - Find .sas files containing any mnemonic
# ================================================================
$step1File = "$outDir\step1_scan.csv"
$step1Source = if ($step1Input) { $step1Input } else { $step1File }

Write-Host ""
Write-Host "=== STEP 1: Broad scan ===" -ForegroundColor Cyan

if ($step1Input) {
    Write-Host "  Using existing file (override): $step1Input"
} elseif (Test-Path $step1File) {
    $step1Count = (Import-Csv $step1File).Count
    Write-Host "  Output exists ($step1Count files), skipping."
    Write-Host "  Delete to re-run: $step1File"
} else {
    Write-Host "  Scanning: $scanPath"
    Write-Host "  This may take a while on a network drive..."

    $scanResults = Get-ChildItem -LiteralPath $scanPath -Filter "*.sas" -Recurse -File -ErrorAction SilentlyContinue |
        Select-String -Pattern $regexPattern -List -ErrorAction SilentlyContinue |
        Select-Object @{N='FileName';E={$_.Filename}},
                      @{N='FolderPath';E={$_.Path | Split-Path}},
                      @{N='FullPath';E={$_.Path}}

    $scanResults | Export-Csv -LiteralPath $step1File -NoTypeInformation
    Write-Host "  Found $($scanResults.Count) files -> $step1File"
}


# ================================================================
# STEP 2: TAG - Which mnemonics appear in each file
# ================================================================
$step2File = "$outDir\step2_tagged.csv"
$step2Source = if ($step2Input) { $step2Input } else { $step2File }

Write-Host ""
Write-Host "=== STEP 2: Tagging files with mnemonics ===" -ForegroundColor Cyan

if ($step2Input) {
    Write-Host "  Using existing file (override): $step2Input"
} elseif (Test-Path $step2File) {
    $step2Count = (Import-Csv $step2File).Count
    Write-Host "  Output exists ($step2Count rows), skipping."
    Write-Host "  Delete to re-run: $step2File"
} else {
    $files = Import-Csv $step1Source
    $tagged = [System.Collections.ArrayList]@()
    $counter = 0

    foreach ($file in $files) {
        $counter++
        if ($counter % 50 -eq 0) {
            Write-Host "  Processing file $counter of $($files.Count)..."
        }

        $content = Get-Content -LiteralPath $file.FullPath -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        $fileInfo = Get-Item -LiteralPath $file.FullPath -ErrorAction SilentlyContinue

        # Find all mnemonic matches (word boundary)
        $regMatches = [regex]::Matches($content, "\b($regexPattern)\b")
        $foundMne = $regMatches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

        if (-not $foundMne) { continue }

        $hasSuccess = 'No'
        if ($content -match '(?i)\bsuccess\b') { $hasSuccess = 'Yes' }

        foreach ($mne in $foundMne) {
            [void]$tagged.Add([PSCustomObject]@{
                Mnemonic      = $mne
                FileName      = $file.FileName
                LastModified  = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                FullPath      = $file.FullPath
                MnemonicCount = @($foundMne).Count
                HasSuccess    = $hasSuccess
            })
        }
    }

    $tagged | Export-Csv -LiteralPath $step2File -NoTypeInformation
    Write-Host "  Tagged $($tagged.Count) mnemonic-file combos -> $step2File"
}


# ================================================================
# STEP 3: DEDUPLICATE - Latest file per mnemonic
# ================================================================
$step3File = "$outDir\step3_latest.csv"
$step3Source = if ($step3Input) { $step3Input } else { $step3File }

Write-Host ""
Write-Host "=== STEP 3: Deduplicating ===" -ForegroundColor Cyan

if ($step3Input) {
    Write-Host "  Using existing file (override): $step3Input"
} elseif (Test-Path $step3File) {
    $step3Count = (Import-Csv $step3File).Count
    Write-Host "  Output exists ($step3Count mnemonics), skipping."
    Write-Host "  Delete to re-run: $step3File"
} else {
    $step2Data = Import-Csv $step2Source

    # Check if HasSuccess column exists in the input
    $hasSuccessCol = ($step2Data | Get-Member -Name 'HasSuccess' -MemberType NoteProperty) -ne $null

    if ($hasSuccessCol) {
        # Prefer files WITH 'success', then most recently modified
        $latest = $step2Data |
            Sort-Object Mnemonic,
                        @{Expression = { if ($_.HasSuccess -eq 'Yes') { 0 } else { 1 } }},
                        @{Expression = { [datetime]$_.LastModified }; Descending = $true} |
            Group-Object Mnemonic |
            ForEach-Object { $_.Group | Select-Object -First 1 }
    } else {
        # No HasSuccess column (v2 format) - sort by date only
        Write-Host "  (Input has no HasSuccess column - sorting by date only)" -ForegroundColor Yellow
        $latest = $step2Data |
            Sort-Object Mnemonic,
                        @{Expression = { [datetime]$_.LastModified }; Descending = $true} |
            Group-Object Mnemonic |
            ForEach-Object { $_.Group | Select-Object -First 1 }
    }

    $latest | Export-Csv -LiteralPath $step3File -NoTypeInformation

    $withSuccess = @($latest | Where-Object { $_.HasSuccess -eq 'Yes' }).Count
    if ($hasSuccessCol) {
        Write-Host "  Unique mnemonics: $($latest.Count)  ($withSuccess with 'success' in file)"
    } else {
        Write-Host "  Unique mnemonics: $($latest.Count)"
    }

    # Report any mnemonics not found in any file
    $foundMne = $latest.Mnemonic
    $missing = $mnemonics | Where-Object { $_ -notin $foundMne }
    if ($missing) {
        Write-Host "  NOT FOUND in any .sas file: $($missing -join ', ')" -ForegroundColor Yellow
    }

    Write-Host "  -> $step3File"
}


# ================================================================
# STEP 4: EXTRACT - Pull logic blocks around mnemonic references
# ================================================================
$step4File = "$outDir\step4_extracts.txt"

Write-Host ""
Write-Host "=== STEP 4: Extracting logic blocks ===" -ForegroundColor Cyan

$deduped = Import-Csv $step3Source
$hasSuccessInInput = ($deduped | Get-Member -Name 'HasSuccess' -MemberType NoteProperty) -ne $null
if (-not $hasSuccessInInput) {
    Write-Host "  (Input has no HasSuccess column - will compute per file)" -ForegroundColor Yellow
}

# Always regenerate extracts
if (Test-Path $step4File) { Remove-Item $step4File }

$sb = [System.Text.StringBuilder]::new()
$extractCount = 0
$noMatchMne = @()

foreach ($entry in $deduped) {
    $mne = $entry.Mnemonic
    $lines = Get-Content -LiteralPath $entry.FullPath -ErrorAction SilentlyContinue
    if (-not $lines) { continue }
    $totalLines = $lines.Count

    # --- Enrichment from mapping ---
    $info = $mneLookup[$mne]
    $desc        = 'N/A'; if ($info) { $desc        = $info.Description }
    $product     = 'N/A'; if ($info) { $product     = $info.Product }
    $eventType   = 'N/A'; if ($info) { $eventType   = $info.Event_Type }
    $eventCat    = 'N/A'; if ($info) { $eventCat    = $info.Event_Category }
    $primary     = 'N/A'; if ($info) { $primary     = $info.Clean_Primary }
    $subset      = '';     if ($info) { $subset      = $info.Primary_Subset }

    # --- Find mnemonic reference lines (priority order) ---

    # Priority 1: quoted string  'MNE'  or  "MNE"
    $matchLines = @()
    for ($i = 0; $i -lt $totalLines; $i++) {
        if ($lines[$i] -match "'$mne'" -or $lines[$i] -match "`"$mne`"") {
            $matchLines += $i
        }
    }

    # Priority 2: assignment context  (mne=, mnemonic=, campaign=)
    if ($matchLines.Count -eq 0) {
        for ($i = 0; $i -lt $totalLines; $i++) {
            if ($lines[$i] -match "(?i)(mne|mnemonic|campaign)\s*=\s*.*\b$mne\b") {
                $matchLines += $i
            }
        }
    }

    # Priority 3: word-boundary fallback
    if ($matchLines.Count -eq 0) {
        for ($i = 0; $i -lt $totalLines; $i++) {
            if ($lines[$i] -match "\b$mne\b") {
                $matchLines += $i
            }
        }
    }

    if ($matchLines.Count -eq 0) {
        $noMatchMne += $mne
        continue
    }

    # --- Compute HasSuccess if not in input ---
    $hasSuccessVal = $entry.HasSuccess
    if (-not $hasSuccessVal) {
        $rawContent = Get-Content -LiteralPath $entry.FullPath -Raw -ErrorAction SilentlyContinue
        $hasSuccessVal = 'No'
        if ($rawContent -and $rawContent -match '(?i)\bsuccess\b') { $hasSuccessVal = 'Yes' }
    }

    # --- Build context windows ---
    $windows = @()
    foreach ($lineIdx in $matchLines) {
        $winStart = [Math]::Max(0, $lineIdx - $contextAbove)
        $winEnd   = [Math]::Min($totalLines - 1, $lineIdx + $contextBelow)
        $windows += [PSCustomObject]@{
            Start      = $winStart
            End        = $winEnd
            MatchLines = @($lineIdx)
        }
    }

    # --- Merge overlapping windows ---
    $windows = $windows | Sort-Object Start
    $merged = @()

    $curStart  = $windows[0].Start
    $curEnd    = $windows[0].End
    $curMatch  = [System.Collections.ArrayList]@($windows[0].MatchLines)

    for ($w = 1; $w -lt $windows.Count; $w++) {
        if ($windows[$w].Start -le ($curEnd + 1)) {
            # Overlapping - extend
            if ($windows[$w].End -gt $curEnd) { $curEnd = $windows[$w].End }
            foreach ($ml in $windows[$w].MatchLines) { [void]$curMatch.Add($ml) }
        } else {
            # Gap - save current, start new
            $merged += [PSCustomObject]@{
                Start      = $curStart
                End        = $curEnd
                MatchLines = @($curMatch | Sort-Object -Unique)
            }
            $curStart = $windows[$w].Start
            $curEnd   = $windows[$w].End
            $curMatch = [System.Collections.ArrayList]@($windows[$w].MatchLines)
        }
    }
    $merged += [PSCustomObject]@{
        Start      = $curStart
        End        = $curEnd
        MatchLines = @($curMatch | Sort-Object -Unique)
    }

    # Cap number of blocks
    if ($merged.Count -gt $maxBlocksPerFile) {
        $merged = $merged | Select-Object -First $maxBlocksPerFile
    }

    # --- Determine match method used ---
    $matchMethod = "quoted string"
    # Re-check: did we find via priority 1?
    $hasQuotedMatch = $false
    foreach ($i in $matchLines) {
        if ($lines[$i] -match "'$mne'" -or $lines[$i] -match "`"$mne`"") {
            $hasQuotedMatch = $true; break
        }
    }
    if (-not $hasQuotedMatch) {
        $hasAssignMatch = $false
        foreach ($i in $matchLines) {
            if ($lines[$i] -match "(?i)(mne|mnemonic|campaign)\s*=\s*.*\b$mne\b") {
                $hasAssignMatch = $true; break
            }
        }
        if ($hasAssignMatch) { $matchMethod = "assignment context" }
        else { $matchMethod = "word boundary (fallback)" }
    }

    # --- Write header ---
    [void]$sb.AppendLine("################################################################################")
    [void]$sb.AppendLine("MNEMONIC:         $mne")
    [void]$sb.AppendLine("DESCRIPTION:      $desc")
    [void]$sb.AppendLine("PRODUCT:          $product")
    [void]$sb.AppendLine("EVENT:            $eventType / $eventCat")
    [void]$sb.AppendLine("EXPECTED SUCCESS: $primary")
    if ($subset) { [void]$sb.AppendLine("SUBSET/QUALIFIER: $subset") }
    [void]$sb.AppendLine("################################################################################")
    [void]$sb.AppendLine("FILE:          $($entry.FileName)")
    [void]$sb.AppendLine("PATH:          $($entry.FullPath)")
    [void]$sb.AppendLine("MODIFIED:      $($entry.LastModified)")
    [void]$sb.AppendLine("MATCH METHOD:  $matchMethod")
    [void]$sb.AppendLine("REFERENCES:    $($matchLines.Count) occurrence(s) in file")
    [void]$sb.AppendLine("BLOCKS:        $($merged.Count) extracted (context: $contextAbove above / $contextBelow below)")
    [void]$sb.AppendLine("HAS 'SUCCESS': $hasSuccessVal")
    [void]$sb.AppendLine("--------------------------------------------------------------------------------")

    # --- Write blocks ---
    $blockNum = 0
    foreach ($block in $merged) {
        $blockNum++
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("--- Block $blockNum of $($merged.Count)  (Lines $($block.Start + 1) - $($block.End + 1)) ---")

        for ($j = $block.Start; $j -le $block.End; $j++) {
            $num  = ($j + 1).ToString().PadLeft(5)
            $text = $lines[$j]

            # Annotation markers
            if ($j -in $block.MatchLines) {
                $marker = ">>>"                                          # mnemonic reference
            } elseif ($text -match '(?i)\b(success|succ_|_succ|succflg|success_flag)\b') {
                $marker = " * "                                          # success-related term
            } elseif ($text -match '(?i)\b(flag|_flag|_ind\b|indicator)\b') {
                $marker = " * "                                          # flag/indicator term
            } elseif ($text -match '(?i)^\s*(if\b|else\b|where\b|when\b|case\b|%if\b)') {
                $marker = " ? "                                          # conditional logic
            } else {
                $marker = "   "
            }

            [void]$sb.AppendLine("$marker $num`: $text")
        }
    }

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("")
    $extractCount++
}

# Write all output at once
Set-Content -LiteralPath $step4File -Value $sb.ToString() -Encoding UTF8

Write-Host "  Extracted blocks for $extractCount of $($deduped.Count) mnemonics"
if ($noMatchMne.Count -gt 0) {
    Write-Host "  No mnemonic refs found in file for: $($noMatchMne -join ', ')" -ForegroundColor Yellow
}
Write-Host "  -> $step4File"
Write-Host ""
Write-Host "  Legend:  >>>  mnemonic reference"
Write-Host "            *   success/flag/indicator term"
Write-Host "            ?   conditional logic (if/where/case/when)"


# ================================================================
# STEP 5: SUMMARY - Quick reference status for all mnemonics
# ================================================================
$step5File = "$outDir\step5_summary.csv"

Write-Host ""
Write-Host "=== STEP 5: Generating summary ===" -ForegroundColor Cyan

# Reload deduped from source (works with both v2 and v3 files)
$dedupedForSummary = Import-Csv $step3Source
$summaryHasSuccessCol = ($dedupedForSummary | Get-Member -Name 'HasSuccess' -MemberType NoteProperty) -ne $null

$summary = foreach ($mne in $mnemonics) {
    $info  = $mneLookup[$mne]
    $entry = $dedupedForSummary | Where-Object { $_.Mnemonic -eq $mne }

    $descVal     = 'N/A'; if ($info)  { $descVal     = $info.Description }
    $prodVal     = 'N/A'; if ($info)  { $prodVal     = $info.Product }
    $primaryVal  = 'N/A'; if ($info)  { $primaryVal  = $info.Clean_Primary }
    $foundVal    = 'No';  if ($entry) { $foundVal    = 'Yes' }
    $fileVal     = '';     if ($entry) { $fileVal     = $entry.FileName }
    $modVal      = '';     if ($entry) { $modVal      = $entry.LastModified }

    # Handle HasSuccess: use column if present, otherwise compute
    $successVal = 'N/A'
    if ($entry) {
        if ($summaryHasSuccessCol -and $entry.HasSuccess) {
            $successVal = $entry.HasSuccess
        } else {
            $rawContent = Get-Content -LiteralPath $entry.FullPath -Raw -ErrorAction SilentlyContinue
            $successVal = 'No'
            if ($rawContent -and $rawContent -match '(?i)\bsuccess\b') { $successVal = 'Yes' }
        }
    }

    [PSCustomObject]@{
        Mnemonic        = $mne
        Description     = $descVal
        Product         = $prodVal
        ExpectedSuccess = $primaryVal
        FileFound       = $foundVal
        HasSuccessTerm  = $successVal
        FileName        = $fileVal
        LastModified    = $modVal
    }
}

$summary | Export-Csv -LiteralPath $step5File -NoTypeInformation

$foundCount   = @($summary | Where-Object { $_.FileFound -eq 'Yes' }).Count
$successCount = @($summary | Where-Object { $_.HasSuccessTerm -eq 'Yes' }).Count
$missingCount = @($summary | Where-Object { $_.FileFound -eq 'No' }).Count

Write-Host "  $foundCount / $($mnemonics.Count) mnemonics found in SAS files"
Write-Host "  $successCount with 'success' term in file"
Write-Host "  $missingCount not found in any file"
Write-Host "  -> $step5File"


# ================================================================
# DONE
# ================================================================
Write-Host ""
Write-Host "=== PIPELINE COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "  Outputs:"
Write-Host "    step1_scan.csv       - All .sas files containing any mnemonic"
Write-Host "    step2_tagged.csv     - File-mnemonic pairs with metadata"
Write-Host "    step3_latest.csv     - Deduplicated: one file per mnemonic"
Write-Host "    step4_extracts.txt   - Logic blocks for LLM review  <-- main output"
Write-Host "    step5_summary.csv    - Status dashboard for all mnemonics"
Write-Host ""
Write-Host "  Next: Submit step4_extracts.txt to LLM for success logic parsing."
Write-Host ""
