# Step 3 - Deduplicate: keep one file per mnemonic (latest, prefer success)
# Input needs columns: Mnemonic, FileName, LastModified, FullPath
# HasSuccess column is optional (compatible with v2 output)

# === IN: tagged file from step 2 (or v2 output: sas_success_by_mnemonic.csv) ===
$inFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step2_tagged.csv"

# === IN: mnemonic reference file ===
$mappingFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\sas_search\keyword_mapping.csv"

# === OUT: where results go ===
$outFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step3_latest.csv"

# ---------------------------------------------------------------
$outDir = Split-Path $outFile
if (-not (Test-Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }

$mapping = Import-Csv $mappingFile | Where-Object { $_.Mnemonic -and $_.Mnemonic.Trim() -ne '' }
$mnemonics = $mapping.Mnemonic

$data = Import-Csv $inFile
$hasSuccessCol = ($data | Get-Member -Name 'HasSuccess' -MemberType NoteProperty) -ne $null

if ($hasSuccessCol) {
    Write-Host "HasSuccess column found - preferring files with 'success'"
    $latest = $data |
        Sort-Object Mnemonic,
                    @{Expression = { if ($_.HasSuccess -eq 'Yes') { 0 } else { 1 } }},
                    @{Expression = { [datetime]$_.LastModified }; Descending = $true} |
        Group-Object Mnemonic |
        ForEach-Object { $_.Group | Select-Object -First 1 }
} else {
    Write-Host "No HasSuccess column - sorting by date only"
    $latest = $data |
        Sort-Object Mnemonic,
                    @{Expression = { [datetime]$_.LastModified }; Descending = $true} |
        Group-Object Mnemonic |
        ForEach-Object { $_.Group | Select-Object -First 1 }
}

$latest | Export-Csv -LiteralPath $outFile -NoTypeInformation

Write-Host "Unique mnemonics: $($latest.Count)"

$foundMne = $latest.Mnemonic
$missing = $mnemonics | Where-Object { $_ -notin $foundMne }
if ($missing) { Write-Host "NOT FOUND: $($missing -join ', ')" -ForegroundColor Yellow }

Write-Host "Done - saved to $outFile"
