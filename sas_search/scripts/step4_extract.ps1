<#
.SYNOPSIS
    Step 4: Extract — Pull annotated logic blocks from SAS files.

.DESCRIPTION
    Reads a deduplicated CSV (one file per mnemonic) and extracts code
    blocks around each mnemonic reference. Produces an annotated text
    file ready for LLM review.

    Input CSV needs columns: Mnemonic, FileName, LastModified, FullPath
    HasSuccess column is optional (computed on the fly if missing).

    (Compatible with v2 output: sas_latest_per_mnemonic.csv)

    Output markers:
      >>>  = line where mnemonic is referenced
       *   = line with success/flag/indicator term
       ?   = line with conditional logic (if/where/case/when)

.PARAMETER inFile
    Deduplicated CSV (one row per mnemonic with FullPath to .sas file).

.PARAMETER mappingFile
    Path to keyword_mapping.csv (used for enrichment headers).

.PARAMETER outFile
    Where to save the annotated extract text file.

.PARAMETER contextAbove
    Lines to extract above each mnemonic match (default: 20).

.PARAMETER contextBelow
    Lines to extract below each mnemonic match (default: 20).

.PARAMETER maxBlocks
    Max blocks to extract per mnemonic (default: 10).

.EXAMPLE
    .\step4_extract.ps1 -inFile "C:\lib\sas_latest_per_mnemonic.csv" `
                        -mappingFile "C:\lib\keyword_mapping.csv" `
                        -outFile "C:\lib\success_extracts.txt"
#>
param(
    [Parameter(Mandatory=$true)]   [string]$inFile,
    [Parameter(Mandatory=$true)]   [string]$mappingFile,
    [Parameter(Mandatory=$true)]   [string]$outFile,
    [int]$contextAbove  = 20,
    [int]$contextBelow  = 20,
    [int]$maxBlocks     = 10
)

# --- Load mapping for enrichment ---
$mapping = Import-Csv $mappingFile | Where-Object { $_.Mnemonic -and $_.Mnemonic.Trim() -ne '' }
$mneLookup = @{}
foreach ($row in $mapping) { $mneLookup[$row.Mnemonic] = $row }

# --- Load input ---
$deduped = Import-Csv $inFile
Write-Host "Loaded $($deduped.Count) mnemonics from $inFile"
Write-Host "Context window: $contextAbove above / $contextBelow below"

# --- Process ---
$sb = [System.Text.StringBuilder]::new()
$extractCount = 0
$noMatchMne = @()

foreach ($entry in $deduped) {
    $mne = $entry.Mnemonic
    $lines = Get-Content -LiteralPath $entry.FullPath -ErrorAction SilentlyContinue
    if (-not $lines) {
        Write-Host "  SKIP $mne - cannot read file: $($entry.FullPath)" -ForegroundColor Yellow
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

    $curStart  = $windows[0].Start
    $curEnd    = $windows[0].End
    $curMatch  = [System.Collections.ArrayList]@($windows[0].MatchLines)

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

    # Cap number of blocks
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

# --- Write output ---
Set-Content -LiteralPath $outFile -Value $sb.ToString() -Encoding UTF8

Write-Host ""
Write-Host "Extracted blocks for $extractCount mnemonics -> $outFile"
if ($noMatchMne.Count -gt 0) {
    Write-Host "No refs found for: $($noMatchMne -join ', ')" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Legend:  >>>  mnemonic reference"
Write-Host "          *   success/flag/indicator term"
Write-Host "          ?   conditional logic (if/where/case/when)"
