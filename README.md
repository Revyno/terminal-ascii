# terminal-ascii

Setup [fastfetch](https://github.com/fastfetch-cli/fastfetch) buat Windows: tiap
buka terminal, langsung muncul ASCII art berwarna di sebelah kiri dan info sistem
di sebelah kanan — dan jalan **identik di PowerShell, CMD, sama Git Bash**.

Logonya di-trace otomatis dari file gambar apa pun, jadi kamu bisa pakai foto,
avatar, atau karakter favorit sendiri.

```
⠀⠀⡰⠃⠀⡄⠀⢠⠀⠀⠀⠀⠈⢣⡀⠀⠀⠀⠀⠀⡀⠀⠳     User@USER
⡜⠀⠀⠀⡞⠀⠀⠀⡞⠀⠀⠀⠀⠊⢻⡍⠙⠀⠀⢦⠀⠀⢆
⠀⠀⠀⣸⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠈⡏⢦⠀⠀⢸⠑⣄⠀      Windows 11 Home Single Language (25H2) x86_64
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀      13th Gen Intel(R) Core(TM) i7-13650HX (20) @ 2.80 GHz
        (dst.)                        󰚗 LNVNB161216 (SDK0T76493 WIN)
                                       10.53 GiB / 11.71 GiB (90%)
                                       437.01 GiB / 474.72 GiB (92%) - NTFS

                                      ● ● ● ● ● ● ● ●
```

---

## Kenapa perlu repo ini

fastfetch punya `--logo-type chafa` buat nampilin gambar langsung, **tapi build
Windows dari winget nggak nyertain DLL chafa/ImageMagick-nya**. Fiturnya kedetek
ada di `--list-features`, tapi pas dipakai gagal diam-diam dan cuma keluar
deretan karakter `/`.

Repo ini muter lewat jalan lain: gambarnya dikonversi jadi **teks ANSI biasa**
pakai ffmpeg, sekali di awal. Hasilnya nol dependensi runtime, dan rendernya
sama persis di ketiga shell.

## Butuh apa

| | |
|---|---|
| **fastfetch** | `winget install Fastfetch-cli.Fastfetch` |
| **ffmpeg** | `winget install Gyan.FFmpeg` — cuma dipakai kalau mau trace ulang gambar |
| **Terminal** | Windows Terminal (butuh dukungan truecolor + UTF-8) |
| **Nerd Font** | Opsional, buat icon di label modul. Lihat [Catatan font](#catatan-font) |

## Install

```powershell
git clone https://github.com/<username>/terminal-ascii.git
cd terminal-ascii
.\install.ps1
```

Buka terminal baru, atau lihat langsung dengan `fastfetch`.

Installer-nya **aman dijalankan berulang** — tiap hook dijaga penanda, jadi
nggak akan ketumpuk dobel. Mau pasang sebagian aja juga bisa:

```powershell
.\install.ps1 -SkipCmd          # PowerShell + Git Bash doang
.\install.ps1 -SkipBash -SkipCmd
```

### Yang disentuh installer

| Shell | Caranya | Lokasi |
|---|---|---|
| PowerShell | Nambah blok di profile | `$PROFILE.CurrentUserAllHosts` |
| Git Bash | Nambah blok di `.bashrc` | `~/.bashrc` |
| CMD | Registry AutoRun | `HKCU\Software\Microsoft\Command Processor` |

Semua file config disalin ke `~/.config/fastfetch/`.

> **CMD itu kasus khusus.** AutoRun kepanggil di **setiap** `cmd.exe`, termasuk
> `cmd /c` yang dipakai build tool, installer, sama script. Kalau logonya ikut
> kecetak di situ, output yang mereka tangkap jadi rusak. Makanya
> `cmd-autorun.bat` ngecek `%CMDCMDLINE%` dan langsung keluar kalau ada `/c`.

## Uninstall

```powershell
.\uninstall.ps1              # copot hook, file config dibiarkan
.\uninstall.ps1 -RemoveFiles # copot hook + hapus ~/.config/fastfetch
```

## Struktur folder

```
terminal-ascii/
├── install.ps1              # pasang ke tiga shell (idempoten)
├── uninstall.ps1            # copot lagi
├── assets/
│   └── logo.jpg             # gambar sumber
├── config/
│   ├── config.jsonc         # config fastfetch (pakai token __FASTFETCH_DIR__)
│   └── logos/
│       ├── ascii-anime.txt  # braille line art  (dipakai default)
│       ├── ascii-wolf.txt   # ASCII serigala
│       └── logo-ansi.txt    # blok warna penuh (foto asli)
├── scripts/
│   ├── img2braille.ps1      # gambar -> braille line art
│   └── img2ansi.ps1         # gambar -> blok warna penuh
└── shell/
    ├── powershell-profile.ps1
    ├── bashrc-snippet.sh
    └── cmd-autorun.bat
```

`config/config.jsonc` nyimpen path sebagai `__FASTFETCH_DIR__`; `install.ps1`
yang nulis ulang jadi path asli waktu dipasang. Jadi repo-nya tetep portabel
walau dipakai user lain.

## Ganti logo

Edit `source` di `~/.config/fastfetch/config.jsonc`:

| File | `type` | Tampilan |
|---|---|---|
| `logos/ascii-anime.txt` | `file` | Braille line art, background transparan |
| `logos/ascii-wolf.txt` | `file` | ASCII serigala |
| `logos/logo-ansi.txt` | `file-raw` | Blok warna penuh, mirip foto aslinya |

## Pakai gambar sendiri

**Braille line art** — cocok buat gambar yang outline-nya tegas (anime, logo,
line art):

```powershell
pwsh scripts/img2braille.ps1 -Image foto.png -Cols 36 -Rows 18 -Threshold 90
```

| Opsi | Fungsi |
|---|---|
| `-Threshold` | Angka kecil = garis tipis, besar = tebal/lebih terisi. Coba 75–120 |
| `-Cols` / `-Rows` | Ukuran logo. Jaga `Cols = Rows × 2` biar proporsinya nggak gepeng |
| `-CropKeep` | Motong bingkai gambar sumber. Default `0.94` |
| `-Preview` | Simpan PNG pola titiknya, buat ngecek sebelum dipasang |

Pakai `-Preview` buat nyari threshold yang pas tanpa tebak-tebakan:

```powershell
pwsh scripts/img2braille.ps1 -Image foto.png -Threshold 110 -Preview cek.png
```

**Blok warna penuh** — cocok buat foto yang warnanya penting:

```powershell
pwsh scripts/img2ansi.ps1 -Image foto.png -Cols 44 -Rows 22
```

Di sini rasio yang bener juga `Cols = Rows × 2`, soalnya tiap sel dirender pakai
setengah-blok (`▀`) yang muat 2 piksel vertikal.

## Ganti warna

Blok `logo.color` di `config.jsonc` isinya 9 warna, dipetakan ke penanda
`$1`–`$9` di file art-nya, dari atas ke bawah. Defaultnya palet
[Catppuccin Mocha](https://github.com/catppuccin/catppuccin). Ganti hex-nya aja
buat bikin gradasi lain.

Yang versi `logo-ansi.txt` udah bawa warna aslinya sendiri, jadi `logo.color`
nggak ngefek ke situ.

## Catatan font

Label modul (`os`, `cpu`, `memory`, …) pakai glyph Nerd Font. Kalau font
terminal kamu bukan Nerd Font, glyph-nya bakal jadi kotak tofu. Perbaikannya:

```powershell
winget install DEVCOM.JetBrainsMonoNerdFont
```

lalu ganti fontnya di Settings Windows Terminal. Atau ya tinggal hapus aja
`"key"` dari config kalau nggak mau ribet.

## Troubleshooting

**Art-nya jadi mojibake / karakter aneh.**
Terminalnya nggak jalan di UTF-8. Snippet PowerShell udah nyetel `chcp 65001`;
buat CMD udah ditangani `cmd-autorun.bat`. Kalau manggil fastfetch dari script
sendiri, set dulu code page-nya.

**Teks info kedorong kejauhan ke kanan.**
Ada `"width"` atau `"height"` di blok `logo` config-mu. Buat logo tipe `file`
dan `file-raw`, fastfetch **nambahin** nilai itu ke lebar hasil auto-detect,
bukan menggantikannya — jadi `"width": 44` di art selebar 44 kolom bikin teksnya
mulai di kolom 91, bukan 47. Hapus aja dua key itu; auto-detect-nya udah bener.

**`--logo-type chafa` cuma keluar karakter `/`.**
DLL chafa/ImageMagick-nya nggak ikut ke-bundle di build winget. Itu alasan repo
ini ada — pakai `scripts/` buat pre-render, jangan andelin chafa.

**Logo muncul di output script/build.**
Guard di `cmd-autorun.bat` seharusnya nyegah ini. Cek registry-nya masih nunjuk
ke batch bawaan repo ini, bukan langsung ke `fastfetch.exe`:

```powershell
Get-ItemProperty "HKCU:\Software\Microsoft\Command Processor" -Name AutoRun
```

## Credit

- [fastfetch](https://github.com/fastfetch-cli/fastfetch) — mesin system info
- [Catppuccin](https://github.com/catppuccin/catppuccin) — palet warna
- ASCII serigala aslinya karya **tnka**

## Lisensi

[MIT](LICENSE) — kecuali gambar di `assets/`, hak ciptanya punya pemilik
masing-masing.
