param(
    [string]$Image     = "C:\Users\User\.config\fastfetch\logo.jpg",
    [string]$Out       = "C:\Users\User\.config\fastfetch\ascii-anime.txt",
    [int]$Cols         = 36,      # cells wide  (2 braille dots each)
    [int]$Rows         = 18,      # cells tall  (4 braille dots each)
    [int]$Threshold    = 110,     # gray < this  => dot ON (captures dark outlines)
    [double]$CropKeep  = 0.94,    # trim the picture frame around the source
    [string]$Preview   = ""       # optional PNG preview of the dot bitmap
)

$ErrorActionPreference = "Stop"

$DW = $Cols * 2      # dot grid width
$DH = $Rows * 4      # dot grid height
$raw = Join-Path $env:TEMP "ff_gray_$DW`x$DH.gray"

$vf = "crop=iw*$CropKeep`:ih*$CropKeep,format=gray,scale=$DW`:$DH`:flags=lanczos"
& ffmpeg -y -v error -i $Image -vf $vf -pix_fmt gray -f rawvideo $raw
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed ($LASTEXITCODE)" }

$g = [System.IO.File]::ReadAllBytes($raw)
if ($g.Length -ne ($DW * $DH)) { throw "size mismatch: $($g.Length) vs $($DW*$DH)" }

# dot bit weights for a 2x4 braille cell: [x][y]
$bit = @(
    @(0x01, 0x02, 0x04, 0x40),   # left  column, rows 0..3
    @(0x08, 0x10, 0x20, 0x80)    # right column, rows 0..3
)

$sb = New-Object System.Text.StringBuilder
$on = New-Object 'bool[]' ($DW * $DH)

for ($cy = 0; $cy -lt $Rows; $cy++) {

    # colour bands, mirroring the old wolf art: $1..$9 top to bottom
    $ci = [int][Math]::Floor($cy * 9.0 / $Rows) + 1
    [void]$sb.Append("`$$ci")

    for ($cx = 0; $cx -lt $Cols; $cx++) {
        $pat = 0
        for ($dx = 0; $dx -lt 2; $dx++) {
            for ($dy = 0; $dy -lt 4; $dy++) {
                $px = $cx * 2 + $dx
                $py = $cy * 4 + $dy
                if ($g[$py * $DW + $px] -lt $Threshold) {
                    $pat = $pat -bor $bit[$dx][$dy]
                    $on[$py * $DW + $px] = $true
                }
            }
        }
        [void]$sb.Append([char](0x2800 + $pat))
    }
    if ($cy -lt $Rows - 1) { [void]$sb.Append("`n") }
}

[System.IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

if ($Preview) {
    Add-Type -AssemblyName System.Drawing
    $z = 6
    $bmp = New-Object System.Drawing.Bitmap ($DW * $z), ($DH * $z)
    $gfx = [System.Drawing.Graphics]::FromImage($bmp)
    $gfx.Clear([System.Drawing.Color]::White)
    $br = [System.Drawing.Brushes]::Black
    for ($y = 0; $y -lt $DH; $y++) {
        for ($x = 0; $x -lt $DW; $x++) {
            if ($on[$y * $DW + $x]) { $gfx.FillRectangle($br, $x*$z, $y*$z, $z-1, $z-1) }
        }
    }
    $gfx.Dispose(); $bmp.Save($Preview, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
}

$dots = ($on | Where-Object { $_ }).Count
Write-Output "OK -> $Out   grid=${DW}x${DH} dots  ink=$([int]($dots*100/($DW*$DH)))%  thr=$Threshold"
Remove-Item $raw -ErrorAction SilentlyContinue
