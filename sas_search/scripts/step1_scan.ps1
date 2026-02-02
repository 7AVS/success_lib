# Step 1 - Broad scan: find all .sas files containing any mnemonic
# Network: \\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics

# === IN: where to search for .sas files ===
$searchPath = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics"

# === IN: mnemonic reference file ===
$mappingFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\sas_search\keyword_mapping.csv"

# === OUT: where results go ===
$outFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step1_scan.csv"

# ---------------------------------------------------------------
$outDir = Split-Path $outFile
if (-not (Test-Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }

$mapping = Import-Csv $mappingFile | Where-Object { $_.Mnemonic -and $_.Mnemonic.Trim() -ne '' }
$pattern = ($mapping.Mnemonic | Sort-Object { $_.Length } -Descending) -join '|'

Write-Host "Loaded $($mapping.Count) mnemonics"
Write-Host "Scanning: $searchPath"

Get-ChildItem -LiteralPath $searchPath -Filter "*.sas" -Recurse -File -ErrorAction SilentlyContinue |
    Select-String -Pattern $pattern -List -ErrorAction SilentlyContinue |
    Select-Object @{N='FileName';E={$_.Filename}},
                  @{N='FolderPath';E={$_.Path | Split-Path}},
                  @{N='FullPath';E={$_.Path}} |
    Export-Csv -LiteralPath $outFile -NoTypeInformation

Write-Host "Done - saved to $outFile"
