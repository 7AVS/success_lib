# V1 - Look for .sas files with MNE inside
# ONLY NON-NBO
# Network: \\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library

$pattern =
"FTH|MOM|ESV|MRF|NMI|RIS|TAO|RMG|VCN|IDE|ZRR|PFS|PRA|DAR|VSX|RCR|COB|VAW|GNE|COR|VUI|PVE|MOS|RAT|MFY|MMT|IPC"

# === IN PATH (where you're searching) ===
$searchPath = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics"

# === OUT PATH (where results go) ===
$outFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\sas_mnemonic_files.csv"

Get-ChildItem -LiteralPath $searchPath -Filter "*.sas" -Recurse -File -ErrorAction SilentlyContinue |
    Select-String -Pattern $pattern -List -ErrorAction SilentlyContinue |
    Select-Object @{N='FileName';E={$_.Filename}}, @{N='FolderPath';E={$_.Path | Split-Path}}, @{N='FullPath';E={$_.Path}} |
    Export-Csv -LiteralPath $outFile -NoTypeInformation

Write-Host "Done — saved to $outFile"
