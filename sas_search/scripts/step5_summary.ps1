# Step 5 - Summary: status dashboard for all mnemonics
# Input needs columns: Mnemonic, FileName, LastModified, FullPath
# HasSuccess column is optional (compatible with v2 output: sas_latest_per_mnemonic.csv)

# === IN: deduplicated file from step 3 (or v2 output: sas_latest_per_mnemonic.csv) ===
$inFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step3_latest.csv"

# === IN: mnemonic reference file ===
$mappingFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\sas_search\keyword_mapping.csv"

# === OUT: where results go ===
$outFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step5_summary.csv"

# ---------------------------------------------------------------
$mapping = Import-Csv $mappingFile | Where-Object { $_.Mnemonic -and $_.Mnemonic.Trim() -ne '' }
$mnemonics = $mapping.Mnemonic

$mneLookup = @{}
foreach ($row in $mapping) { $mneLookup[$row.Mnemonic] = $row }

$deduped = Import-Csv $inFile
$hasSuccessCol = ($deduped | Get-Member -Name 'HasSuccess' -MemberType NoteProperty) -ne $null

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
Write-Host "Done - saved to $outFile"
