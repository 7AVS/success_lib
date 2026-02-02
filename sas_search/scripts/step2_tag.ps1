<#
.SYNOPSIS
    Step 2: Tag — Identify which mnemonics appear in each .sas file.

.DESCRIPTION
    Reads a CSV of .sas file paths (from step 1 or any file list with
    a FullPath column). For each file, identifies which specific mnemonics
    are present, records the last modified date and whether the file
    contains the word "success".

    Input CSV needs columns: FileName, FullPath
    (This is compatible with v1 output: sas_mnemonic_files.csv)

.PARAMETER inFile
    CSV of .sas files to process (needs FullPath column).

.PARAMETER mappingFile
    Path to keyword_mapping.csv.

.PARAMETER outFile
    Where to save the tagged results CSV.

.EXAMPLE
    .\step2_tag.ps1 -inFile "C:\lib\sas_mnemonic_files.csv" `
                    -mappingFile "C:\lib\keyword_mapping.csv" `
                    -outFile "C:\lib\step2_tagged.csv"
#>
param(
    [Parameter(Mandatory=$true)]  [string]$inFile,
    [Parameter(Mandatory=$true)]  [string]$mappingFile,
    [Parameter(Mandatory=$true)]  [string]$outFile
)

# --- Load mnemonics ---
$mapping = Import-Csv $mappingFile | Where-Object { $_.Mnemonic -and $_.Mnemonic.Trim() -ne '' }
$mnemonics = $mapping.Mnemonic
$pattern = ($mnemonics | Sort-Object { $_.Length } -Descending) -join '|'

Write-Host "Loaded $($mnemonics.Count) mnemonics"

# --- Process files ---
$files = Import-Csv $inFile
$tagged = [System.Collections.ArrayList]@()
$counter = 0

foreach ($file in $files) {
    $counter++
    if ($counter % 50 -eq 0) {
        Write-Host "  Processing file $counter of $($files.Count)..."
    }

    $content = Get-Content -LiteralPath $file.FullPath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $fileInfo = Get-Item -LiteralPath $file.FullPath -ErrorAction SilentlyContinue

    # Find all mnemonic matches (word boundary)
    $regMatches = [regex]::Matches($content, "\b($pattern)\b")
    $foundMne = $regMatches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

    if (-not $foundMne) { continue }

    $hasSuccess = 'No'
    if ($content -match '(?i)\bsuccess\b') { $hasSuccess = 'Yes' }

    foreach ($mne in $foundMne) {
        [void]$tagged.Add([PSCustomObject]@{
            Mnemonic      = $mne
            FileName      = $file.FileName
            LastModified  = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            FullPath      = $file.FullPath
            MnemonicCount = @($foundMne).Count
            HasSuccess    = $hasSuccess
        })
    }
}

$tagged | Export-Csv -LiteralPath $outFile -NoTypeInformation

Write-Host "Done. Tagged $($tagged.Count) mnemonic-file combos -> $outFile"
