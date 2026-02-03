# Step 4a - Extract: pull code blocks around the word "success"
# Searches each SAS file for "success" and pulls 20 lines above / 20 below
# Does NOT search for the mnemonic — searches for the success logic itself
# Input: step 2 tagged file (all files per mnemonic) or step 3 deduped file (one per mnemonic)
#
# Output markers:
#   >>>  = line where "success" appears
#    ?   = line with conditional logic (if/where/case/when)

# === IN: tagged file from step 2 ===
$inFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step2_tagged.csv"

# === IN: mnemonic reference file ===
$mappingFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\sas_search\keyword_mapping.csv"

# === OUT: where results go ===
$outFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step4a_success_extracts.txt"

# === SETTINGS ===
$contextAbove  = 20
$contextBelow  = 20
$maxBlocks     = 10

# ---------------------------------------------------------------
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

    # --- Find lines containing "success" ---
    $matchLines = @()
    for ($i = 0; $i -lt $totalLines; $i++) {
        if ($lines[$i] -match '(?i)\bsuccess\b') {
            $matchLines += $i
        }
    }

    if ($matchLines.Count -eq 0) {
        $noMatchMne += $mne
        continue
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
    [void]$sb.AppendLine("SEARCH:        keyword 'success'")
    [void]$sb.AppendLine("HITS:          $($matchLines.Count) occurrence(s)")
    [void]$sb.AppendLine("BLOCKS:        $($merged.Count) extracted (context: $contextAbove above / $contextBelow below)")
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
    Write-Host "  $mne - $($matchLines.Count) 'success' hits, $($merged.Count) blocks"
}

Set-Content -LiteralPath $outFile -Value $sb.ToString() -Encoding UTF8

Write-Host ""
Write-Host "Extracted $extractCount mnemonics - saved to $outFile"
if ($noMatchMne.Count -gt 0) {
    Write-Host "No 'success' found for: $($noMatchMne -join ', ')" -ForegroundColor Yellow
}
