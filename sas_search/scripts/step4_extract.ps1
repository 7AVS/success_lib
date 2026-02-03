# LEGACY — Use step4a_extract_success.ps1 or step4b_extract_keywords.ps1 instead.
# This script extracts code around the mnemonic reference, which typically finds
# CLIENT SELECTION code (who got the campaign), not the success measurement logic.
#
# Step 4 - Extract: pull annotated logic blocks from SAS files
# Input needs columns: Mnemonic, FileName, LastModified, FullPath
# HasSuccess column is optional (compatible with v2 output: sas_latest_per_mnemonic.csv)
#
# Output markers:
#   >>>  = line where mnemonic is referenced
#    *   = line with success/flag/indicator term
#    ?   = line with conditional logic (if/where/case/when)

# === IN: deduplicated file from step 3 (or v2 output: sas_latest_per_mnemonic.csv) ===
$inFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step3_latest.csv"

# === IN: mnemonic reference file ===
$mappingFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\sas_search\keyword_mapping.csv"

# === OUT: where results go ===
$outFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step4_extracts.txt"

# === SETTINGS ===
$contextAbove  = 20    # lines above each mnemonic match
$contextBelow  = 20    # lines below each mnemonic match
$maxBlocks     = 10    # max blocks per mnemonic

# ---------------------------------------------------------------
# Create output folder if it doesn't exist
$outDir = Split-Path $outFile
if (-not (Test-Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }

$mapping = Import-Csv $mappingFile | Where-Object { $_.Mnemonic -and $_.Mnemonic.Trim() -ne '' }
$mneLookup = @{}
foreach ($row in $mapping) { $mneLookup[$row.Mnemonic] = $row }

$deduped = Import-Csv $inFile
Write-Host "Loaded $($deduped.Count) mnemonics from input"

$sb = [System.Text.StringBuilder]::new()
$extractCount = 0
$noMatchMne = @()

foreach ($entry in $deduped) {
    $mne = $entry.Mnemonic
    $lines = Get-Content -LiteralPath $entry.FullPath -ErrorAction SilentlyContinue
    if (-not $lines) {
        Write-Host "  SKIP $mne - cannot read: $($entry.FullPath)" -ForegroundColor Yellow
        continue
    }
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
    $curStart = $windows[0].Start
    $curEnd   = $windows[0].End
    $curMatch = [System.Collections.ArrayList]@($windows[0].MatchLines)

    for ($w = 1; $w -lt $windows.Count; $w++) {
        if ($windows[$w].Start -le ($curEnd + 1)) {
            if ($windows[$w].End -gt $curEnd) { $curEnd = $windows[$w].End }
            foreach ($ml in $windows[$w].MatchLines) { [void]$curMatch.Add($ml) }
        } else {
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

    if ($merged.Count -gt $maxBlocks) {
        $merged = $merged | Select-Object -First $maxBlocks
    }

    # --- Determine match method ---
    $matchMethod = "quoted string"
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

            if ($j -in $block.MatchLines) {
                $marker = ">>>"
            } elseif ($text -match '(?i)\b(success|succ_|_succ|succflg|success_flag)\b') {
                $marker = " * "
            } elseif ($text -match '(?i)\b(flag|_flag|_ind\b|indicator)\b') {
                $marker = " * "
            } elseif ($text -match '(?i)^\s*(if\b|else\b|where\b|when\b|case\b|%if\b)') {
                $marker = " ? "
            } else {
                $marker = "   "
            }

            [void]$sb.AppendLine("$marker $num`: $text")
        }
    }

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("")
    $extractCount++
    Write-Host "  $mne - $($matchLines.Count) refs, $($merged.Count) blocks [$matchMethod]"
}

Set-Content -LiteralPath $outFile -Value $sb.ToString() -Encoding UTF8

Write-Host ""
Write-Host "Extracted $extractCount mnemonics - saved to $outFile"
if ($noMatchMne.Count -gt 0) {
    Write-Host "No refs found for: $($noMatchMne -join ', ')" -ForegroundColor Yellow
}
