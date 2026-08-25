# --- terminal-ascii: fastfetch on startup ---
# Appended to ~/.bashrc by install.ps1. The $- test keeps the logo out of
# non-interactive shells, so scp/rsync/ssh command runs stay clean.
if [[ $- == *i* ]] && command -v fastfetch >/dev/null 2>&1; then
    fastfetch -c "__FASTFETCH_DIR__/config.jsonc"
fi
# --- end terminal-ascii ---
