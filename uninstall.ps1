<#
.SYNOPSIS
    Removes the terminal-ascii fastfetch hooks from PowerShell, CMD and Git Bash.

.DESCRIPTION
    Strips the marker-delimited blocks from ~/.bashrc and the PowerShell profile,
    clears the CMD AutoRun value, and optionally deletes ~/.config/fastfetch.

.PARAMETER RemoveFiles
    Also delete the installed ~/.config/fastfetch directory.

.EXAMPLE
    .\uninstall.ps1
    .\uninstall.ps1 -RemoveFiles
#>
[CmdletBinding()]
param(
    [switch]$RemoveFiles
)

$ErrorActionPreference = 'Stop'

$Target = Join-Path $HOME '.config\fastfetch'
$Utf8   = New-Object System.Text.UTF8Encoding($false)
$Begin  = '# --- terminal-ascii'
$End    = '# --- end terminal-ascii ---'

function Write-Ok  ($msg) { Write-Host "  OK   $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "  --   $msg" -ForegroundColor DarkGray }

Write-Host "`nterminal-ascii uninstaller" -ForegroundColor Magenta

# Drops every line from the marker start through the marker end.
function Remove-Block {
    param([string]$Path, [string]$Newline)

    if (-not (Test-Path $Path)) { Write-Skip "$Path (not present)"; return }

    $lines = [System.IO.File]::ReadAllText($Path) -split "`r?`n"
    $keep  = New-Object System.Collections.Generic.List[string]
    $inside = $false
    $found  = $false

    foreach ($line in $lines) {
        if (-not $inside -and $line.TrimStart().StartsWith($Begin)) { $inside = $true; $found = $true; continue }
        if ($inside) {
            if ($line.Trim() -eq $End) { $inside = $false }
            continue
        }
        $keep.Add($line)
    }

    if (-not $found) { Write-Skip "$Path (no block found)"; return }

    [System.IO.File]::WriteAllText($Path, (($keep -join $Newline).TrimEnd() + $Newline), $Utf8)
    Write-Ok "cleaned $Path"
}

Remove-Block -Path $PROFILE.CurrentUserAllHosts -Newline "`r`n"
Remove-Block -Path (Join-Path $HOME '.bashrc')  -Newline "`n"

# --------------------------------------------------------------------- CMD ---
$key = 'HKCU:\Software\Microsoft\Command Processor'
$current = (Get-ItemProperty -Path $key -Name AutoRun -ErrorAction SilentlyContinue).AutoRun
if ($current -like "*cmd-autorun.bat*") {
    Remove-ItemProperty -Path $key -Name AutoRun
    Write-Ok "cleared CMD AutoRun"
} elseif ($current) {
    Write-Skip "CMD AutoRun points elsewhere, left alone: $current"
} else {
    Write-Skip "CMD AutoRun (not set)"
}

# ------------------------------------------------------------------- files ---
if ($RemoveFiles) {
    if (Test-Path $Target) {
        Remove-Item $Target -Recurse -Force
        Write-Ok "deleted $Target"
    }
} else {
    Write-Skip "kept $Target (use -RemoveFiles to delete)"
}

Write-Host "`nDone. Open a new terminal to confirm.`n" -ForegroundColor Magenta
