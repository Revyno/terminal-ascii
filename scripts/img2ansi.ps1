

# ubah  dengan directory path file kamu sendiri
param(
    # [string]$Image  = "C:\Users\User\.config\fastfetch\logo.jpg",
    # [string]$Out    = "C:\Users\User\.config\fastfetch\logo-ansi.txt",
    [int]$Cols      = 40,   # terminal columns wide
    [int]$Rows      = 20    # terminal rows tall (each row = 2 image pixels)
)

$ErrorActionPreference = "Stop"

$W = $Cols
$H = $Rows * 2          # half-block: each cell holds 2 vertical pixels
$raw = Join-Path $env:TEMP "ff_img_$W`x$H.rgb"

# Decode + scale with ffmpeg to raw RGB24
& ffmpeg -y -v error -i $Image -vf "scale=$W`:$H`:flags=lanczos" -pix_fmt rgb24 -f rawvideo $raw
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed (exit $LASTEXITCODE)" }

$bytes = [System.IO.File]::ReadAllBytes($raw)
$expected = $W * $H * 3
if ($bytes.Length -ne $expected) { throw "Unexpected size: got $($bytes.Length), expected $expected" }

$ESC = [char]27
$sb  = New-Object System.Text.StringBuilder

for ($cy = 0; $cy -lt $Rows; $cy++) {
    $lastTop = $null
    $lastBot = $null
    for ($x = 0; $x -lt $W; $x++) {
        $iTop = (( ($cy * 2)     * $W) + $x) * 3
        $iBot = (( ($cy * 2 + 1) * $W) + $x) * 3

        $tr = $bytes[$iTop]; $tg = $bytes[$iTop+1]; $tb = $bytes[$iTop+2]
        $br = $bytes[$iBot]; $bg = $bytes[$iBot+1]; $bb = $bytes[$iBot+2]

        $top = "$tr;$tg;$tb"
        $bot = "$br;$bg;$bb"

        # emit color codes only when they change (keeps file small)
        if ($top -ne $lastTop) { [void]$sb.Append("$ESC[38;2;$top`m"); $lastTop = $top }
        if ($bot -ne $lastBot) { [void]$sb.Append("$ESC[48;2;$bot`m"); $lastBot = $bot }

        [void]$sb.Append([char]0x2580)   # UPPER HALF BLOCK
    }
    [void]$sb.Append("$ESC[0m")
    if ($cy -lt $Rows - 1) { [void]$sb.Append("`n") }
}

# UTF-8 without BOM
[System.IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

Remove-Item $raw -ErrorAction SilentlyContinue
Write-Output "OK -> $Out  ($Cols x $Rows cells, $([int]((Get-Item $Out).Length/1KB)) KB)"
