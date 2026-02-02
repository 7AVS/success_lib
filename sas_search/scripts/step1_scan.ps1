<#
.SYNOPSIS
    Step 1: Broad scan — Find all .sas files containing any NBA mnemonic.

.DESCRIPTION
    Scans a directory (recursively) for .sas files that mention any
    mnemonic from the mapping file. Outputs a CSV listing every match.

.PARAMETER scanPath
    The root folder to search for .sas files.

.PARAMETER mappingFile
    Path to keyword_mapping.csv (mnemonics are read from here).

.PARAMETER outFile
    Where to save the results CSV.

.EXAMPLE
    .\step1_scan.ps1 -scanPath "\\server\share\Analytics" `
                     -mappingFile "C:\lib\keyword_mapping.csv" `
                     -outFile "C:\lib\step1_scan.csv"
#>
param(
    [Parameter(Mandatory=$true)]  [string]$scanPath,
    [Parameter(Mandatory=$true)]  [string]$mappingFile,
    [Parameter(Mandatory=$true)]  [string]$outFile
)

# --- Load mnemonics ---
$mapping = Import-Csv $mappingFile | Where-Object { $_.Mnemonic -and $_.Mnemonic.Trim() -ne '' }
$mnemonics = $mapping.Mnemonic
$pattern = ($mnemonics | Sort-Object { $_.Length } -Descending) -join '|'

Write-Host "Loaded $($mnemonics.Count) mnemonics"
Write-Host "Scanning: $scanPath"
Write-Host "This may take a while on a network drive..."

# --- Scan ---
$results = Get-ChildItem -LiteralPath $scanPath -Filter "*.sas" -Recurse -File -ErrorAction SilentlyContinue |
    Select-String -Pattern $pattern -List -ErrorAction SilentlyContinue |
    Select-Object @{N='FileName';E={$_.Filename}},
                  @{N='FolderPath';E={$_.Path | Split-Path}},
                  @{N='FullPath';E={$_.Path}}

$results | Export-Csv -LiteralPath $outFile -NoTypeInformation

Write-Host "Done. Found $($results.Count) files -> $outFile"
