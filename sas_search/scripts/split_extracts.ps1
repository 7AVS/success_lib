# Split extract files into chunks under 275,000 characters for Helios Assist
# Splits on mnemonic section boundaries (never cuts a section in half)
# Each section starts with a line of ####

# === IN: the extract file to split ===
$inFile = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\step4a_success_extracts.txt"

# === OUT: folder where parts go (part1.txt, part2.txt, etc.) ===
$outFolder = "\\maple.fg.rbc.com\data\Toronto\wrkgrp\wrkgrp16\Marketing Services & Transformation\Marketing Analytics\Andre Santos\Success Library\pipeline\split"

# === SETTINGS ===
$maxChars = 275000

# ---------------------------------------------------------------
if (-not (Test-Path $outFolder)) { New-Item -Path $outFolder -ItemType Directory -Force | Out-Null }

$content = Get-Content -LiteralPath $inFile -Raw
$separator = "################################################################################"

# Split into sections (each mnemonic starts with ####)
$sections = $content -split "(?=################################################################################)"
$sections = $sections | Where-Object { $_.Trim() -ne '' }

Write-Host "File: $inFile"
Write-Host "Total characters: $($content.Length)"
Write-Host "Mnemonic sections found: $($sections.Count)"
Write-Host "Max chars per part: $maxChars"
Write-Host ""

$partNum = 0
$currentChunk = ""

foreach ($section in $sections) {
    # If adding this section would exceed the limit, save current chunk and start new
    if ($currentChunk.Length -gt 0 -and ($currentChunk.Length + $section.Length) -gt $maxChars) {
        $partNum++
        $partFile = "$outFolder\part$partNum.txt"
        Set-Content -LiteralPath $partFile -Value $currentChunk -Encoding UTF8
        Write-Host "  part$partNum.txt - $($currentChunk.Length) chars"
        $currentChunk = ""
    }

    # If a single section is bigger than the limit, save it as its own part
    if ($section.Length -gt $maxChars) {
        if ($currentChunk.Length -gt 0) {
            $partNum++
            $partFile = "$outFolder\part$partNum.txt"
            Set-Content -LiteralPath $partFile -Value $currentChunk -Encoding UTF8
            Write-Host "  part$partNum.txt - $($currentChunk.Length) chars"
            $currentChunk = ""
        }
        $partNum++
        $partFile = "$outFolder\part$partNum.txt"
        Set-Content -LiteralPath $partFile -Value $section -Encoding UTF8
        Write-Host "  part$partNum.txt - $($section.Length) chars (oversized section)" -ForegroundColor Yellow
        continue
    }

    $currentChunk += $section
}

# Save last chunk
if ($currentChunk.Trim().Length -gt 0) {
    $partNum++
    $partFile = "$outFolder\part$partNum.txt"
    Set-Content -LiteralPath $partFile -Value $currentChunk -Encoding UTF8
    Write-Host "  part$partNum.txt - $($currentChunk.Length) chars"
}

Write-Host ""
Write-Host "Done - $partNum parts saved to $outFolder"
