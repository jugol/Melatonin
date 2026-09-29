<p align="center">
  <img src="docs/images/icon.png" width="128" alt="Ikon Melatonin">
</p>

<h1 align="center">Melatonin</h1>

<p align="center">
  <b>Tutup laptopnya. Agen tetap bekerja.</b><br>
  Aplikasi bar menu macOS mungil yang membuat MacBook Anda tetap terjaga meski ditutup —<br>
  pakai baterai, tanpa layar eksternal — selama Claude Code, Codex, dan kawan-kawan menuntaskan tugasnya.
</p>

<p align="center">
  <a href="https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg"><b>Unduh</b></a> ·
  <a href="https://jugol.github.io/Melatonin/">Situs web</a>
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português</a> ·
  <a href="README.ru.md">Русский</a> ·
  <a href="README.ar.md">العربية</a> ·
  <a href="README.hi.md">हिन्दी</a> ·
  <a href="README.id.md">Bahasa Indonesia</a>
</p>

<p align="center">
  <img src="docs/images/notch-expanded-on.png" width="640" alt="Melatonin terbuka penuh di notch">
</p>

## Kenapa

Anda memulai tugas panjang di Claude Code, menutup laptop, lalu pergi. macOS masuk mode tidur dan prosesnya mati di tengah jalan.

Aplikasi anti-tidur seperti `caffeinate`, KeepingYouAwake, dan sebagian besar aplikasi sejenisnya memakai power assertion, padahal macOS mengabaikannya begitu Mac ditutup. Satu-satunya cara yang benar-benar mencegah Mac tidur saat ditutup adalah `pmset disablesleep`, dan itu butuh akses root. Melatonin membungkusnya dalam alat bantu kecil berhak akses root dengan pengaman yang ketat, lalu menaruh sakelarnya di tempat yang selalu terlihat: di notch.

## Fitur

- **Tinggal di notch.** Saat Melatonin menyala, lampu hangat berpendar di samping kamera beserta sisa waktunya. Arahkan kursor ke sana untuk membuka panel kontrol lengkap. Di layar tanpa notch, pil ini menggantung dari bar menu.
- **Sakelar di bar menu.** Garis bulan sabit berarti Mac Anda akan tidur; bulan sabit yang memeluk lampu amber berarti Mac tetap terjaga.
- **Timer.** 1, 2, 4, atau 8 jam, atau sampai Anda mematikannya.
- **Otomatis untuk agen AI.** Tetap terjaga hanya selama ada agen yang benar-benar bekerja: Claude Code, Codex, Hermes, OpenCode, T3 Code, Gemini CLI, Cursor Agent, Amp, Goose, atau Crush. Deteksinya melihat aktivitas CPU di seluruh pohon proses tiap agen, jadi agen yang cuma diam menunggu di prompt tidak dihitung. Agen yang dijalankan oleh T3 Code dihitung sebagai T3 Code.
- **Tetap online.** Pilih jaringan cadangan dari jaringan Wi-Fi yang sudah dikenal Mac Anda, seret untuk mengatur urutan prioritas, lalu tandai hotspot ponsel Anda. Jika internet terputus saat Melatonin membuat Mac Anda tetap terjaga, Melatonin akan bergabung dengan jaringan berikutnya dalam daftar memakai kata sandi yang tersimpan.
- **Keamanan nomor satu.**
  - Mati sendiri saat baterai menyentuh batas yang Anda pilih (bawaannya 20%) ketika Mac memakai baterai.
  - Mati jika Mac Anda terlalu panas. Laptop yang menyala di dalam tas tertutup adalah cara jitu memanggang baterai.
  - Jika Melatonin ditutup, crash, atau dipaksa keluar, alat bantu langsung mengembalikan mode tidur seperti biasa. Setelah restart pun, semuanya dibereskan.
- **Native dan ringan.** SwiftUI dan AppKit, tanpa Electron, CPU sekitar 0% saat diam. Biner universal untuk Apple silicon dan Intel.
- **Fasih berbahasa Anda.** English, 한국어, 简体中文, 日本語, Español, Français, Deutsch, Português (Brasil), Русский, العربية, हिन्दी, dan Bahasa Indonesia. Secara bawaan mengikuti bahasa macOS Anda; pilih bahasa lain di **⋯ › Bahasa**.

<p align="center">
  <img src="docs/images/menu-on-light.png" width="300" alt="Menu, terjaga">
  <img src="docs/images/menu-off-dark.png" width="300" alt="Menu, boleh tidur">
</p>

<p align="center">
  <img src="docs/images/notch-compact.png" width="640" alt="Pil notch ringkas dengan hitung mundur">
</p>

<p align="center">
  <img src="docs/images/connection-light.png" width="420" alt="Pengaturan Tetap online">
</p>

## Instalasi

Memerlukan macOS 14 Sonoma atau yang lebih baru.

**Unduh:** ambil [Melatonin.dmg](https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg) dari [rilis terbaru](https://github.com/jugol/Melatonin/releases/latest), lalu seret aplikasinya ke folder Aplikasi.

**Homebrew:**

```bash
brew install --cask jugol/tap/melatonin
```

**Pembukaan pertama:** build awal belum dinotarisasi oleh Apple, jadi macOS memblokirnya saat pertama kali dibuka. Buka **Pengaturan Sistem › Privasi & Keamanan** lalu klik **Tetap Buka**, atau jalankan:

```bash
xattr -dr com.apple.quarantine /Applications/Melatonin.app
```

Saat pertama kali Anda menyalakan Melatonin, macOS akan meminta kata sandi Anda sekali untuk menginstal alat bantu.

**Dari kode sumber:** Anda memerlukan Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/jugol/Melatonin.git
cd Melatonin
make run
```

## Cara kerjanya

```
Melatonin.app  ──XPC──▶  io.github.jugol.melatonin.helper (root, launchd)
  UI, timers,              pmset -a disablesleep 1 / 0
  safety checks,           …and back to 0 when the app disconnects
  connection watch         networksetup -setairportnetwork (saved networks only)
```

- **Alat bantunya sangat terbatas.** Seluruh antarmukanya hanya `setSleepDisabled(Bool)` dan `joinWiFi(ssid)`, dan ia menolak jaringan apa pun yang belum tersimpan di Mac. Tidak ada akses shell dan tidak ada perintah sembarang yang dijalankan. Lihat [`Sources/MelatoninHelper/main.swift`](Sources/MelatoninHelper/main.swift).
- **Hanya mau bicara dengan Melatonin.** Koneksi XPC harus memenuhi persyaratan code signing untuk bundle identifier aplikasi.
- **Tetap aman saat ada yang gagal.** Mode tidur hanya dinonaktifkan selama ada aplikasi terhubung yang memintanya. Begitu koneksi terputus, mode tidur kembali aktif. Sebuah file penanda menangani saat alat bantu dimulai ulang atau Mac di-reboot.
- **Instal dan copot hanyalah skrip shell biasa** yang bisa Anda baca sendiri: [`Support/install-helper.sh`](Support/install-helper.sh) dan [`Support/uninstall-helper.sh`](Support/uninstall-helper.sh).

## Copot pemasangan

Pilih **⋯ › Copot alat bantu…** di menu, lalu hapus aplikasinya. Untuk menghapus alat bantu secara manual:

```bash
sudo bash Support/uninstall-helper.sh
```

## Pengembangan

```bash
make app        # build build/Melatonin.app (ad-hoc signed)
make run        # build and launch
make package    # universal build, DMG and zip in dist/
make icon       # regenerate the app icon from Scripts/make-icon.swift
swift build && .build/debug/Melatonin --snapshot /tmp/shots   # render every UI state to PNGs
swift build && .build/debug/Melatonin --agents                 # watch agent detection live
```

Setelah menambah atau mengubah terjemahan, jalankan `python3 Scripts/check-localizations.py` untuk menemukan teks yang hilang dan placeholder yang tidak cocok.

Untuk menandatangani dengan Developer ID, atur `SIGN_IDENTITY` dan sematkan team ID Anda di `HelperConstants.clientRequirement`:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" make app
```

## Peta jalan

- [ ] Rilis yang ditandatangani dan dinotarisasi, cask Homebrew, serta pembaruan lewat Sparkle
- [ ] Tetap online: kembali ke jaringan utama begitu jaringan itu tersedia lagi
- [ ] Integrasi hooks Claude Code untuk sinyal mulai dan berhenti yang akurat
- [ ] Ringkasan "Selagi Anda pergi" saat laptop dibuka kembali

## Lisensi

[MIT](LICENSE)
