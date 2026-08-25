<#
.SYNOPSIS
    Installs the terminal-ascii fastfetch setup for PowerShell, CMD and Git Bash.

.DESCRIPTION
    Copies the config + logo art into ~/.config/fastfetch and hooks fastfetch
    into each shell's startup. Safe to run repeatedly: every hook is guarded by
    a marker, so nothing is appended twice.

.PARAMETER SkipPowerShell
    Do not touch the PowerShell profile.

.PARAMETER SkipCmd
    Do not register the CMD AutoRun registry value.

.PARAMETER SkipBash
    Do not touch ~/.bashrc.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -SkipCmd
#>
[CmdletBinding()]
param(
    [switch]$SkipPowerShell,
    [switch]$SkipCmd,
    [switch]$SkipBash
)

$ErrorActionPreference = 'Stop'

$Root   = $PSScriptRoot
$Target = Join-Path $HOME '.config\fastfetch'
$Token  = '__FASTFETCH_DIR__'
$Marker = '# --- terminal-ascii'
$Utf8   = New-Object System.Text.UTF8Encoding($false)   # no BOM

# fastfetch reads the config path; forward slashes work on Windows and avoid
# backslash-escaping headaches inside JSON.
$TargetFwd = $Target.Replace('\', '/')

function Write-Step($msg) { Write-Host "  $msg" -ForegroundColor Cyan }
function Write-Ok  ($msg) { Write-Host "  OK   $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "  --   $msg" -ForegroundColor DarkGray }

Write-Host "`nterminal-ascii installer" -ForegroundColor Magenta
Write-Host "  source: $Root"
Write-Host "  target: $Target`n"

# ---------------------------------------------------------------- fastfetch --
if (-not (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
    Write-Warning "fastfetch is not on PATH. Install it first:`n    winget install Fastfetch-cli.Fastfetch`nThen re-run this script."
    return
}
Write-Ok "fastfetch found: $((Get-Command fastfetch).Source)"

# ------------------------------------------------------------------- files ---
New-Item -ItemType Directory -Force -Path $Target, (Join-Path $Target 'logos') | Out-Null

# config.jsonc, with the path token resolved
$cfg = [System.IO.File]::ReadAllText((Join-Path $Root 'config\config.jsonc'))
[System.IO.File]::WriteAllText((Join-Path $Target 'config.jsonc'), $cfg.Replace($Token, $TargetFwd), $Utf8)
Write-Ok "config.jsonc"

Copy-Item (Join-Path $Root 'config\logos\*') (Join-Path $Target 'logos') -Force
Write-Ok "logo art -> logos\"

Copy-Item (Join-Path $Root 'scripts\*.ps1') $Target -Force
Copy-Item (Join-Path $Root 'assets\logo.jpg') $Target -Force -ErrorAction SilentlyContinue
Write-Ok "converter scripts + source image"

# -------------------------------------------------------------- PowerShell ---
if ($SkipPowerShell) {
    Write-Skip "PowerShell profile (-SkipPowerShell)"
} else {
    $profilePath = $PROFILE.CurrentUserAllHosts
    New-Item -ItemType Directory -Force -Path (Split-Path $profilePath) | Out-Null
    if (-not (Test-Path $profilePath)) { New-Item -ItemType File -Path $profilePath | Out-Null }

    $existing = [System.IO.File]::ReadAllText($profilePath)
    if ($existing -like "*$Marker*") {
        Write-Skip "PowerShell profile already hooked"
    } else {
        $snippet = [System.IO.File]::ReadAllText((Join-Path $Root 'shell\powershell-profile.ps1')).Replace($Token, $TargetFwd)
        [System.IO.File]::WriteAllText($profilePath, ($existing.TrimEnd() + "`r`n`r`n" + $snippet), $Utf8)
        Write-Ok "PowerShell profile -> $profilePath"
    }
}

# --------------------------------------------------------------------- CMD ---
if ($SkipCmd) {
    Write-Skip "CMD AutoRun (-SkipCmd)"
} else {
    $bat = [System.IO.File]::ReadAllText((Join-Path $Root 'shell\cmd-autorun.bat')).Replace($Token, $TargetFwd)
    $batPath = Join-Path $Target 'cmd-autorun.bat'
    # .bat must be ASCII with CRLF - a BOM makes cmd.exe choke on the first line
    [System.IO.File]::WriteAllText($batPath, ($bat -replace "`r?`n", "`r`n"), (New-Object System.Text.ASCIIEncoding))

    $key = 'HKCU:\Software\Microsoft\Command Processor'
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }

    $current = (Get-ItemProperty -Path $key -Name AutoRun -ErrorAction SilentlyContinue).AutoRun
    if ($current -and $current -notlike "*cmd-autorun.bat*") {
        Write-Warning "HKCU AutoRun already set to: $current`n           Not overwriting. Chain it manually if you want both."
    } else {
        Set-ItemProperty -Path $key -Name AutoRun -Value "`"$batPath`"" -Type String
        Write-Ok "CMD AutoRun -> $batPath"
    }
}

# ---------------------------------------------------------------- Git Bash ---
if ($SkipBash) {
    Write-Skip "Git Bash (-SkipBash)"
} else {
    $bashrc = Join-Path $HOME '.bashrc'
    $existing = ''
    if (Test-Path $bashrc) { $existing = [System.IO.File]::ReadAllText($bashrc) }

    if ($existing -like "*$Marker*") {
        Write-Skip ".bashrc already hooked"
    } else {
        $snippet = [System.IO.File]::ReadAllText((Join-Path $Root 'shell\bashrc-snippet.sh')).Replace($Token, $TargetFwd)
        # bash wants LF, never CRLF
        $out = ($existing.TrimEnd() + "`n`n" + $snippet) -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($bashrc, $out, $Utf8)
        Write-Ok ".bashrc -> $bashrc"
    }
}

Write-Host "`nDone. Open a new terminal, or preview right now with:" -ForegroundColor Magenta
Write-Host "  fastfetch`n"
