# --- terminal-ascii: fastfetch on startup ---
# Appended to $PROFILE by install.ps1.
# UTF-8 first: the braille and block-drawing glyphs need code page 65001,
# otherwise the art renders as mojibake in a fresh console.
try {
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    chcp 65001 > $null
} catch {}

if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch -c "__FASTFETCH_DIR__/config.jsonc"
}
# --- end terminal-ascii ---
