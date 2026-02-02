<#
.SYNOPSIS
    Step 5: Summary — Generate a status dashboard for all mnemonics.

.DESCRIPTION
    Reads a deduplicated CSV and the mapping file, produces a summary
    CSV showing which mnemonics have files, which have "success" terms,
    and which are missing.

    Input CSV needs columns: Mnemonic, FileName, LastModified, FullPath
    HasSuccess column is optional (computed on the fly if missing).

    (Compatible with v2 output: sas_latest_per_mnemonic.csv)

.PARAMETER inFile
    Deduplicated CSV (one row per mnemonic).

.PARAMETER mappingFile
    Path to keyword_mapping.csv.

.PARAMETER outFile
    Where to save the summary CSV.

.EXAMPLE
    .\step5_summary.ps1 -inFile "C:\lib\sas_latest_per_mnemonic.csv" `
                        -mappingFile "C:\lib\keyword_mapping.csv" `
                        -outFile "C:\lib\summary.csv"
#>
param(
    [Parameter(Mandatory=$true)]  [string]$inFile,
    [Parameter(Mandatory=$true)]  [string]$mappingFile,
    [Parameter(Mandatory=$true)]  [string]$outFile
)

# --- Load mapping ---
$mapping = Import-Csv $mappingFile | Where-Object { $_.Mnemonic -and $_.Mnemonic.Trim() -ne '' }
$mnemonics = $mapping.Mnemonic

$mneLookup = @{}
foreach ($row in $mapping) { $mneLookup[$row.Mnemonic] = $row }

# --- Load deduped ---
$deduped = Import-Csv $inFile
$hasSuccessCol = ($deduped | Get-Member -Name 'HasSuccess' -MemberType NoteProperty) -ne $null

if (-not $hasSuccessCol) {
    Write-Host "No HasSuccess column in input - will compute per file"
}

# --- Build summary ---
$summary = foreach ($mne in $mnemonics) {
    $info  = $mneLookup[$mne]
    $entry = $deduped | Where-Object { $_.Mnemonic -eq $mne }

    $descVal     = 'N/A'; if ($info)  { $descVal     = $info.Description }
    $prodVal     = 'N/A'; if ($info)  { $prodVal     = $info.Product }
    $primaryVal  = 'N/A'; if ($info)  { $primaryVal  = $info.Clean_Primary }
    $foundVal    = 'No';  if ($entry) { $foundVal    = 'Yes' }
    $fileVal     = '';     if ($entry) { $fileVal     = $entry.FileName }
    $modVal      = '';     if ($entry) { $modVal      = $entry.LastModified }

    $successVal = 'N/A'
    if ($entry) {
        if ($hasSuccessCol -and $entry.HasSuccess) {
            $successVal = $entry.HasSuccess
        } else {
            $rawContent = Get-Content -LiteralPath $entry.FullPath -Raw -ErrorAction SilentlyContinue
            $successVal = 'No'
            if ($rawContent -and $rawContent -match '(?i)\bsuccess\b') { $successVal = 'Yes' }
        }
    }

    [PSCustomObject]@{
        Mnemonic        = $mne
        Description     = $descVal
        Product         = $prodVal
        ExpectedSuccess = $primaryVal
        FileFound       = $foundVal
        HasSuccessTerm  = $successVal
        FileName        = $fileVal
        LastModified    = $modVal
    }
}

$summary | Export-Csv -LiteralPath $outFile -NoTypeInformation

$foundCount   = @($summary | Where-Object { $_.FileFound -eq 'Yes' }).Count
$successCount = @($summary | Where-Object { $_.HasSuccessTerm -eq 'Yes' }).Count
$missingCount = @($summary | Where-Object { $_.FileFound -eq 'No' }).Count

Write-Host "$foundCount / $($mnemonics.Count) mnemonics found"
Write-Host "$successCount with 'success' term"
Write-Host "$missingCount not found"
Write-Host "Done -> $outFile"
