# V2 - Enriching tagging and deduplication - all mne
# Which specific mne, in which file, and which is the most current
# Network: \\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics

$basePath = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\mne search"

# ============================================================
# SECTION 1: One row per FILE + MNEMONIC combo
# ============================================================
$pattern =
"FTH|MOM|BOL|ESV|GIS|LTA|RCL|RCU|VBA|CTU|MRF|NMI|PCD|PCL|PCQ|PPQ|TFP|VBU|RIS|TAO|RMG|VCN|IRI|O2P|CRV|EBR|IDE|RPB|ZRR|PFS|PRA|DAR|VSX|RCR|COB|VAW|GNE|COR|VUI|PVE|MOS|RAT|MFY|MMT|IPC"
$mnemonics = $pattern -split '\|'

$results = @()
$files = Import-Csv "$basePath\sas_mnemonic_files_all.csv"

foreach ($file in $files) {
    $content = Get-Content -LiteralPath $file.FullPath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $info = Get-Item -LiteralPath $file.FullPath -ErrorAction SilentlyContinue
    $found = $mnemonics | Where-Object { $content -match "\b$_\b" }

    foreach ($mne in $found) {
        $results += [PSCustomObject]@{
            Mnemonic      = $mne
            FileName      = $file.FileName
            LastModified  = $info.LastWriteTime
            FullPath      = $file.FullPath
            MnemonicCount = $found.Count
        }
    }
}

$results | Export-Csv "$basePath\sas_success_by_mnemonic.csv" -NoTypeInformation

# ============================================================
# SECTION 2: Most recent and deduplications
# ============================================================
$latest = Import-Csv "$basePath\sas_success_by_mnemonic.csv" |
    Sort-Object Mnemonic, LastModified -Descending |
    Group-Object Mnemonic |
    ForEach-Object { $_.Group | Select-Object -First 1 }

$latest | Export-Csv "$basePath\sas_latest_per_mnemonic.csv" -NoTypeInformation
Write-Host "Unique mnemonics: $($latest.Count)"

# ============================================================
# SECTION 3: Extract 30 lines around each $success% match
# ============================================================
$deduped = Import-Csv "$basePath\sas_latest_per_mnemonic.csv"
$output = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\mne search\success_logic_review.txt"

foreach ($file in $deduped) {
    $lines = Get-Content -LiteralPath $file.FullPath -ErrorAction SilentlyContinue
    if (-not $lines) { continue }

    $matchList = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '(?i)success') {
            $start = [Math]::Max(0, $i - 15)
            $end = [Math]::Min($lines.Count - 1, $i + 15)
            $matchList += [PSCustomObject]@{
                LineNum = $i + 1
                Start   = $start
                End     = $end
            }
        }
    }

    if ($matchList.Count -gt 0) {
        Add-Content $output "`n$('='*80)"
        Add-Content $output "FILE: $($file.FileName)"
        Add-Content $output "PATH: $($file.FullPath)"
        Add-Content $output "DATE: $($file.LastModified)"
        Add-Content $output "$('-'*80)"

        foreach ($m in $matchList) {
            Add-Content $output "`n--- Line $($m.LineNum) ---"
            for ($j = $m.Start; $j -le $m.End; $j++) {
                $marker = if ($j -eq ($m.LineNum - 1)) { ">>>" } else { "   " }
                Add-Content $output "$marker $($j+1): $($lines[$j])"
            }
        }
    }
}
Write-Host "Review file created: $output"
