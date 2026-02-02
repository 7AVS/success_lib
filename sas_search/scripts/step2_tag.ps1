# Step 2 - Tag: identify which mnemonics appear in each .sas file
# Input needs column: FullPath (compatible with v1 output and step1 output)

# === IN: file list from step 1 (or v1 output) ===
$inFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step1_scan.csv"

# === IN: mnemonic reference file ===
$mappingFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\sas_search\keyword_mapping.csv"

# === OUT: where results go ===
$outFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step2_tagged.csv"

# ---------------------------------------------------------------
$mapping = Import-Csv $mappingFile | Where-Object { $_.Mnemonic -and $_.Mnemonic.Trim() -ne '' }
$pattern = ($mapping.Mnemonic | Sort-Object { $_.Length } -Descending) -join '|'

Write-Host "Loaded $($mapping.Count) mnemonics"

$files = Import-Csv $inFile
$tagged = [System.Collections.ArrayList]@()
$counter = 0

foreach ($file in $files) {
    $counter++
    if ($counter % 50 -eq 0) { Write-Host "  Processing file $counter of $($files.Count)..." }

    $content = Get-Content -LiteralPath $file.FullPath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $fileInfo = Get-Item -LiteralPath $file.FullPath -ErrorAction SilentlyContinue

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
Write-Host "Done. Tagged $($tagged.Count) mnemonic-file combos - saved to $outFile"
