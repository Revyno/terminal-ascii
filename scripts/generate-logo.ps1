<#
.SYNOPSIS
    Auto-generate the fastfetch logo art from one image.

.DESCRIPTION
    Wraps img2braille.ps1 + img2ansi.ps1 and writes straight into
    config/logos/ using the exact filenames config.jsonc references:
      braille -> config/logos/ascii-anime.txt   (default logo, "type": "file")
      ansi    -> config/logos/logo-ansi.txt      ("type": "file-raw")

    Point it at any picture and re-run install.ps1 (or copy the logos folder)
    to see it. With no arguments it retraces the bundled assets/logo.jpg.

.EXAMPLE
    pwsh scripts/generate-logo.ps1
    pwsh scripts/generate-logo.ps1 -Image me.png -Threshold 90
    pwsh scripts/generate-logo.ps1 -Image me.png -Mode braille
#>
param(
    [string]$Image,                                    # source picture; default = assets/logo.jpg
    [ValidateSet('both','braille','ansi')]
    [string]$Mode      = 'both',
    [int]$Threshold    = 110,                          # braille: small = thin lines, big = bolder
    [int]$BrailleCols  = 36,
    [int]$BrailleRows  = 18,
    [int]$AnsiCols     = 40,
    [int]$AnsiRows     = 20
)

$ErrorActionPreference = 'Stop'

$Scripts = $PSScriptRoot
$Root    = Split-Path $Scripts -Parent
$Logos   = Join-Path $Root 'config\logos'

if (-not $Image) { $Image = Join-Path $Root 'assets\logo.jpg' }

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    throw "ffmpeg not on PATH. Install it:  winget install Gyan.FFmpeg"
}
if (-not (Test-Path $Image)) { throw "Image not found: $Image" }
New-Item -ItemType Directory -Force -Path $Logos | Out-Null

Write-Host "generating logo from: $Image" -ForegroundColor Magenta

if ($Mode -in 'both','braille') {
    & (Join-Path $Scripts 'img2braille.ps1') `
        -Image $Image -Out (Join-Path $Logos 'ascii-anime.txt') `
        -Cols $BrailleCols -Rows $BrailleRows -Threshold $Threshold
}
if ($Mode -in 'both','ansi') {
    & (Join-Path $Scripts 'img2ansi.ps1') `
        -Image $Image -Out (Join-Path $Logos 'logo-ansi.txt') `
        -Cols $AnsiCols -Rows $AnsiRows
}
# if ($Mode -of 'both') {
#     & (Join-Path $Scripts 'generate-logo.ps1') `
#         -Image $Image -Out (Join-Path $Logos 'logo-ansi.txt') `
#         -Cols $AnsiCols -Rows $AnsiRows
# }
Write-Host "done. install (or re-run install.ps1) to apply." -ForegroundColor Green
