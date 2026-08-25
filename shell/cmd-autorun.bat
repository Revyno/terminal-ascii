@echo off
rem === Fastfetch auto-run for interactive CMD only ===
rem Registered under HKCU\Software\Microsoft\Command Processor -> AutoRun.
rem
rem CMD runs AutoRun for EVERY cmd.exe, including the non-interactive
rem `cmd /c ...` used by build tools, installers and scripts. Printing a logo
rem there would corrupt their captured output, so bail out when /c is present.
echo %CMDCMDLINE% | find /i "/c" >nul && goto :eof

chcp 65001 >nul
where fastfetch >nul 2>&1 && fastfetch -c "__FASTFETCH_DIR__/config.jsonc"
