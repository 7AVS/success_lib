<#
.SYNOPSIS
    Step 3: Deduplicate — Keep one file per mnemonic (latest, prefer success).

.DESCRIPTION
    Reads a tagged CSV (from step 2 or v2 output) and keeps only the
    best file for each mnemonic. Preference: files with "success" first,
    then most recently modified.

    Input CSV needs columns: Mnemonic, FileName, LastModified, FullPath
    HasSuccess column is optional (if missing, sorts by date only).

    (Compatible with v2 output: sas_success_by_mnemonic.csv)

.PARAMETER inFile
    Tagged CSV to deduplicate.

.PARAMETER mappingFile
    Path to keyword_mapping.csv (used to report missing mnemonics).

.PARAMETER outFile
    Where to save the deduplicated CSV.

.EXAMPLE
    .\step3_dedup.ps1 -inFile "C:\lib\sas_success_by_mnemonic.csv" `
                      -mappingFile "C:\lib\keyword_mapping.csv" `
                      -outFile "C:\lib\step3_latest.csv"
#>
param(
    [Parameter(Mandatory=$true)]  [string]$inFile,
    [Parameter(Mandatory=$true)]  [string]$mappingFile,
    [Parameter(Mandatory=$true)]  [string]$outFile
)

# --- Load mnemonics (for missing report) ---
$mapping = Import-Csv $mappingFile | Where-Object { $_.Mnemonic -and $_.Mnemonic.Trim() -ne '' }
$mnemonics = $mapping.Mnemonic

# --- Load and deduplicate ---
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

# Report missing
$foundMne = $latest.Mnemonic
$missing = $mnemonics | Where-Object { $_ -notin $foundMne }
if ($missing) {
    Write-Host "NOT FOUND: $($missing -join ', ')" -ForegroundColor Yellow
}

Write-Host "Done -> $outFile"
