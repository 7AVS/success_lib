# Quick Search — Single-file scan + extract
# All-in-one: scans network for .sas files matching your mnemonics,
# then extracts code blocks around your keywords. No CSVs, no pipeline.
#
# HOW TO USE:
#   1. Edit the 3 sections below (MNEMONICS, KEYWORDS, PATHS)
#   2. Run:  .\sas_search\scripts\quick_search.ps1
#
# Output markers:
#   >>>          = line where "success" was found
#   >>>[keyword] = line where one of your keywords was found
#    ?           = line with conditional logic (if/where/case/when)

# =============================================================================
# === EDIT THESE: your mnemonics (one or many, comma-separated) ===
# =============================================================================
$mnemonics = @("FTH", "MOM")

# =============================================================================
# === EDIT THESE: your keywords (one or many, comma-separated) ===
# These are searched IN ADDITION to the word "success" which is always included
# =============================================================================
$keywords = @("mortgage", "open", "funded", "approved", "maturity", "retain")

# =============================================================================
# === EDIT THESE: paths ===
# =============================================================================
$searchPath = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics"
$outFile    = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\quick_search_output.txt"

# === SETTINGS (usually no need to change) ===
$contextAbove = 20
$contextBelow = 20
$maxBlocks    = 10

# =============================================================================
# STEP 1: Scan — find .sas files containing any of the mnemonics
# =============================================================================
$mnePattern = ($mnemonics | Sort-Object { $_.Length } -Descending) -join '|'

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Quick Search" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Mnemonics: $($mnemonics -join ', ')"
Write-Host "  Keywords:  $($keywords -join ', ')"
Write-Host "  Search:    $searchPath"
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[1/3] Scanning for .sas files containing: $($mnemonics -join ', ') ..." -ForegroundColor Yellow

$sasFiles = Get-ChildItem -LiteralPath $searchPath -Filter "*.sas" -Recurse -File -ErrorAction SilentlyContinue |
    Select-String -Pattern $mnePattern -List -ErrorAction SilentlyContinue |
    Select-Object @{N='FullPath';E={$_.Path}},
                  @{N='FileName';E={$_.Filename}}

if (-not $sasFiles -or $sasFiles.Count -eq 0) {
    Write-Host "  No .sas files found containing those mnemonics." -ForegroundColor Red
    Write-Host "  Check the search path and mnemonic list."
    exit
}

Write-Host "  Found $($sasFiles.Count) file(s)" -ForegroundColor Green

# =============================================================================
# STEP 2: Tag — for each file, which mnemonics does it contain?
# =============================================================================
Write-Host ""
Write-Host "[2/3] Tagging files by mnemonic ..." -ForegroundColor Yellow

$tagged = @()
foreach ($file in $sasFiles) {
    $content = Get-Content -LiteralPath $file.FullPath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $lastMod = (Get-Item -LiteralPath $file.FullPath -ErrorAction SilentlyContinue).LastWriteTime.ToString("yyyy-MM-dd")

    foreach ($mne in $mnemonics) {
        if ($content -match "(?i)\b$mne\b") {
            $tagged += [PSCustomObject]@{
                Mnemonic     = $mne
                FileName     = $file.FileName
                FullPath     = $file.FullPath
                LastModified = $lastMod
            }
        }
    }
}

if ($tagged.Count -eq 0) {
    Write-Host "  No mnemonics matched inside the files." -ForegroundColor Red
    exit
}

$grouped = $tagged | Group-Object Mnemonic
foreach ($g in $grouped) {
    Write-Host "  $($g.Name): $($g.Count) file(s)"
}

# =============================================================================
# STEP 3: Extract — pull code blocks around "success" + your keywords
# =============================================================================
Write-Host ""
Write-Host "[3/3] Extracting code blocks ..." -ForegroundColor Yellow

# Build combined search pattern: always include "success" + user keywords
$allKeywords = @("success") + $keywords | Select-Object -Unique
$kwPattern = ($allKeywords | Sort-Object { $_.Length } -Descending) -join '|'

$sb = [System.Text.StringBuilder]::new()

# Header
[void]$sb.AppendLine("================================================================================")
[void]$sb.AppendLine("QUICK SEARCH RESULTS")
[void]$sb.AppendLine("DATE:       $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
[void]$sb.AppendLine("MNEMONICS:  $($mnemonics -join ', ')")
[void]$sb.AppendLine("KEYWORDS:   $($allKeywords -join ', ')")
[void]$sb.AppendLine("FILES:      $($sasFiles.Count) scanned, $($tagged.Count) tagged")
[void]$sb.AppendLine("================================================================================")
[void]$sb.AppendLine("")

$extractCount = 0

foreach ($entry in $tagged) {
    $mne = $entry.Mnemonic

    $lines = Get-Content -LiteralPath $entry.FullPath -ErrorAction SilentlyContinue
    if (-not $lines) {
        Write-Host "  SKIP $mne - cannot read: $($entry.FullPath)" -ForegroundColor Yellow
        continue
    }
    $totalLines = $lines.Count

    # --- Find lines containing any keyword ---
    $matchLines = @()
    $matchKeywords = @{}
    for ($i = 0; $i -lt $totalLines; $i++) {
        if ($lines[$i] -match "(?i)\b($kwPattern)") {
            $matchLines += $i
            $matched = $allKeywords | Where-Object { $lines[$i] -match "(?i)\b$_" }
            $matchKeywords[$i] = $matched -join ', '
        }
    }

    if ($matchLines.Count -eq 0) { continue }

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

    # --- Write section header ---
    [void]$sb.AppendLine("################################################################################")
    [void]$sb.AppendLine("MNEMONIC:  $mne")
    [void]$sb.AppendLine("################################################################################")
    [void]$sb.AppendLine("FILE:      $($entry.FileName)")
    [void]$sb.AppendLine("PATH:      $($entry.FullPath)")
    [void]$sb.AppendLine("MODIFIED:  $($entry.LastModified)")
    [void]$sb.AppendLine("HITS:      $($matchLines.Count) keyword match(es)")
    [void]$sb.AppendLine("BLOCKS:    $($merged.Count) extracted (context: $contextAbove above / $contextBelow below)")
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
                $kw = $matchKeywords[$j]
                if ($kw -eq 'success') {
                    $marker = ">>>"
                } else {
                    $marker = ">>>[$kw]"
                }
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
    Write-Host "  $mne | $($entry.FileName) | $($matchLines.Count) hits, $($merged.Count) blocks"
}

# =============================================================================
# SAVE
# =============================================================================
$outDir = Split-Path $outFile
if (-not (Test-Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }
Set-Content -LiteralPath $outFile -Value $sb.ToString() -Encoding UTF8

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Done" -ForegroundColor Green
Write-Host "  Extracted: $extractCount mnemonic-file pairs"
Write-Host "  Output:    $outFile"
Write-Host "============================================" -ForegroundColor Green
