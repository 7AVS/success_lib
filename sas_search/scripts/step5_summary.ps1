# Step 5 - Summary: status dashboard for all mnemonics
# Works with step 2 output (multiple files per mnemonic) or step 3 output (one per mnemonic)
# Input needs columns: Mnemonic, FileName, LastModified, FullPath
# HasSuccess column is optional

# === IN: tagged file from step 2 ===
$inFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step2_tagged.csv"

# === IN: mnemonic reference file ===
$mappingFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\sas_search\keyword_mapping.csv"

# === OUT: where results go ===
$outFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step5_summary.csv"

# ---------------------------------------------------------------
$outDir = Split-Path $outFile
if (-not (Test-Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }

$mapping = Import-Csv $mappingFile | Where-Object { $_.Mnemonic -and $_.Mnemonic.Trim() -ne '' }
$mnemonics = $mapping.Mnemonic

$mneLookup = @{}
foreach ($row in $mapping) { $mneLookup[$row.Mnemonic] = $row }

$data = Import-Csv $inFile
$hasSuccessCol = ($data | Get-Member -Name 'HasSuccess' -MemberType NoteProperty) -ne $null

$summary = foreach ($mne in $mnemonics) {
    $info    = $mneLookup[$mne]
    $entries = @($data | Where-Object { $_.Mnemonic -eq $mne })

    $descVal    = 'N/A'; if ($info) { $descVal    = $info.Description }
    $prodVal    = 'N/A'; if ($info) { $prodVal    = $info.Product }
    $primaryVal = 'N/A'; if ($info) { $primaryVal = $info.Clean_Primary }

    $foundVal   = 'No'
    $fileCount  = 0
    $successVal = 'No'
    $fileNames  = ''
    $latestMod  = ''

    if ($entries.Count -gt 0) {
        $foundVal  = 'Yes'
        $fileCount = $entries.Count

        # Check if any file has success
        if ($hasSuccessCol) {
            $hasAny = $entries | Where-Object { $_.HasSuccess -eq 'Yes' }
            if ($hasAny) { $successVal = 'Yes' }
        } else {
            foreach ($e in $entries) {
                $rawContent = Get-Content -LiteralPath $e.FullPath -Raw -ErrorAction SilentlyContinue
                if ($rawContent -and $rawContent -match '(?i)\bsuccess\b') { $successVal = 'Yes'; break }
            }
        }

        # List unique file names and find latest modified date
        $uniqueFiles = $entries | Select-Object -Property FileName -Unique
        $fileNames = ($uniqueFiles.FileName) -join '; '
        $latestMod = ($entries | Sort-Object @{Expression = { [datetime]$_.LastModified }; Descending = $true} | Select-Object -First 1).LastModified
    }

    [PSCustomObject]@{
        Mnemonic        = $mne
        Description     = $descVal
        Product         = $prodVal
        ExpectedSuccess = $primaryVal
        FileFound       = $foundVal
        FileCount       = $fileCount
        HasSuccessTerm  = $successVal
        Files           = $fileNames
        LatestModified  = $latestMod
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
