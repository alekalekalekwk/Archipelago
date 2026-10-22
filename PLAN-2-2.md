# PLAN-2.md — Archipelago (macOS, notch island) — v4

File ini bernama `PLAN-2.md`. Di mana pun dokumen ini nyebut "plan", itu artinya
file ini. Baca PENUH (`read_file`) di awal sesi dan sebelum tiap step.
File ini dan `scripts/verify.sh` READ-ONLY buat Hermes: dilarang edit, hapus, atau commit
perubahannya.

## 0. Tujuan

App macOS yang mengubah area notch jadi "island" interaktif, meniru PENGALAMAN PAKAI
Alcove (animasi, Now Playing Apple Music/Spotify, kalender, tampilan saat Mac terkunci).
Kode, desain, dan aset dibuat sendiri, bukan salinan. Tanpa iklan, tanpa telemetry.

- Mac bernotch: island nempel di notch, collapsed = seukuran notch.
- Mac tanpa notch: nempel di tengah atas, ukuran "notch virtual".
- Hover/klik: melebar dan memanjang ke bawah.
- Modular lewat protokol `IslandModule`.
- Prioritas: ANIMASI > Now Playing > Kalender > Lock screen (paling berisiko, di akhir).
- UI: hitam polos, font sistem. DILARANG: gradient norak, glow, blur berlebih, emoji,
  dekorasi tanpa fungsi.

## STATUS (diisi gua)
- Selesai: S0-S5-fix (terakhir `cf7d254`). Kode ada di `Sources/DynamicIsland/` sampai
  Step 1 (rename) selesai, setelah itu `Sources/Archipelago/`.
- Yang sudah ada: panel non-activating nempel atas, geometri notch (lebar dari
  `auxiliaryTopLeftArea`/`auxiliaryTopRightArea`), `NotchShape`, status item "Quit Archipelago",
  `ScreenObserver` (sudah terhubung), `Info.plist`, `build_app.sh`.
- Kode nyasar dari step lama: `HoverTrackingView.swift` dan `State/IslandState.swift`
  (belum dipakai, dipakai & disesuaikan di Step 2).
- Mac gua: macOS 27.0.1 (build 26A434), Command Line Tools, Apple Music + Spotify.
- Gua matikan Alcove tiap tes manual. Gua cuma nge-build dan LIHAT tampilan; semua
  verifikasi git/file jadi tugas Hermes lewat `scripts/verify.sh` (di bawah).

---

## RULE 0 — REPO LOCK (paling tinggi)

1. Satu-satunya direktori kerja: `~/Archipelago`. `scripts/verify.sh` mencetak blok RULE 0
   (pwd, toplevel, branch, remote). Harus: `/Users/macbook/Archipelago` dua kali, branch `main`,
   remote `.../Archipelago`. Kalau beda, STOP, jangan edit apa pun.
2. Dilarang baca/tulis/hapus di luar repo, KECUALI `/tmp/archipelago-research/` (clone
   referensi read-only) dan baca-saja `~/SwiftProject/SleeplessClone`.
3. Kerja di `main`. Jangan bikin branch/tag sendiri.

## SAFETY RULES (DILARANG KERAS)

1. DILARANG menjalankan app: `swift run`, `open *.app`, `.build/*/Archipelago`, `osascript`
   yang nargetin Music/Spotify/Calendar, atau eksekusi binary hasil build. Boleh: `swift build`,
   `swift package resolve`, `./build_app.sh` (cuma bungkus), `scripts/verify.sh`.
2. DILARANG `sudo`, `pmset`, `defaults write`, `tccutil`, `launchctl`, `brew/pip/npm install`,
   atau ubah setting sistem.
3. DILARANG `git push`, `--force`, `reset --hard`, `clean -fd`, `rebase`, `commit --amend`,
   hapus branch, `git init` ulang. Cuma `add` (file spesifik, BUKAN `add .`/`-A`) dan `commit`.
4. DILARANG hapus file yang bukan lu bikin di step ini.
5. DILARANG: `#Preview`, `@Observable`, `import Observation`, `@main` di executable yang punya
   `main.swift`. Pakai `ObservableObject` + `@Published`.
6. DILARANG dependency pihak ketiga (kecuali yang disetujui gua eksplisit di chat).
7. DILARANG bikin/ubah file di luar daftar "File" step yang lagi jalan, dan DILARANG ngerjain
   fitur step lain. Ide tambahan? Tulis di "Catatan", jangan dikerjain.
8. DILARANG klaim perilaku runtime ("works", "muncul", "mulus"). Cuma boleh "build hijau".
   Tes runtime dan penilaian animasi = tugas gua.
9. DILARANG mengarang atau mengedit output. Blok VERIFY harus tempel mentah dari
   `scripts/verify.sh` yang BENAR-BENAR dijalankan di sesi ini. Dilarang nulis hash commit,
   isi log, atau output build dari ingatan, dan dilarang nambah komentar di dalam blok itu.
10. DILARANG nyalin kode dari repo/app lain. Cuma boleh baca buat ngerti cara kerjanya.
11. DILARANG API privat (SkyLight, CGS*, framework privat) kecuali disetujui gua eksplisit.
12. DILARANG hardcode angka ukuran/radius/durasi/spring di view. Semua lewat
    `Window/IslandMetrics.swift` dan `Window/AnimationTokens.swift`.
13. Kalau `scripts/verify.sh` mencetak `FILES EXTRA`, build gagal, atau `FORBIDDEN PATTERNS`
    bukan `none`, JANGAN disembunyikan dan JANGAN "diperbaiki" diam-diam: laporkan apa adanya
    dan STOP.

## ATURAN KERJA PER STEP

**A.** Satu file per tool call. Target <= 120 baris per file Swift; lebih? pecah.
**B.** Edit file existing: `read_file` PENUH dulu, baru edit.
**C.** Build: `swift build 2>&1 | tail -25` tiap file. Gagal? Perbaiki maks 2x; ke-3: STOP,
laporkan error apa adanya.
**D.** Satu commit per step, format `S<n>: <ringkas>` (Step 3 dst: `Step<n>: <ringkas>`).
Jangan commit kalau build merah. Jangan commit file di luar daftar "File".
**E.** Setelah commit, jalankan (satu kali):
```
scripts/verify.sh Step<n> <path lengkap tiap file di daftar File>
```
(path relatif dari root repo, mis. `Sources/Archipelago/Window/HoverTrackingView.swift`).
**F.** Laporan akhir WAJIB format ini, dan tempel seluruh output verify di dalamnya:
```
LAPORAN KONSULTAN — Step<n>
Status: selesai (build hijau, belum diuji manual) | gagal | berhenti karena <alasan>
Commit: <hash dari output verify>
File dibuat/diubah: ...
--- OUTPUT VERIFY (mentah, utuh) ---
<tempel semua dari "=== VERIFY" sampai "=== END VERIFY ===">
--- AKHIR OUTPUT ---
Tes visual buat gua: <2-5 langkah + apa yang HARUS kelihatan>
Catatan/risiko: <hal yang gak yakin, deviasi dari plan, ide yang tidak dikerjakan>
Menunggu "next".
```
**G.** STOP setelah laporan. Jangan mulai step berikutnya sampai gua ketik "next".
"fix: ..." = perbaiki di step yang sama, commit baru `Step<n>-fix: ...`, verify ulang.
**H.** Ragu / spesifikasi kurang jelas: STOP dan tanya satu pertanyaan. Jangan nebak API Apple.

## KONSTRAIN TEKNIS

- SwiftPM saja (Command Line Tools), `swift-tools-version:5.9`, `.macOS(.v13)`; naikkan hanya
  kalau API butuh dan laporkan. Executable pakai `main.swift`. `.accessory` / `LSUIElement`.
- State `ObservableObject`, UI di `@MainActor`.
- Notch: ada kalau `safeAreaInsets.top > 0`. Panel nempel `screen.frame.maxY`, center, level di
  atas menu bar. Bentuk hitam, sudut atas rata, sudut bawah bulat. Panel pas seukuran bentuknya
  (jangan panel transparan besar yang nutupin klik).

### Spesifikasi animasi (kualitatif; angka dituning lewat ronde T)
- Island tumbuh DARI bentuk notch (satu shape yang morph ukuran + radius sudut bawah), bukan
  crossfade dua view.
- Konten expanded masuk sedikit TERLAMBAT dari shape (fade + scale kecil, stagger per elemen).
  Saat collapse, konten hilang DULU, baru shape mengecil.
- Spring expand dan collapse TERPISAH. Hover grow kecil sebelum expand penuh; hover keluar pakai
  jeda kecil (anti-flicker).
- INTERRUPTIBLE: hover masuk-keluar cepat tidak boleh bikin state nyangkut atau panel patah.
- Resize panel disinkronkan dengan animasi (panel dibesarkan dulu saat expand, dikecilkan SETELAH
  animasi selesai saat collapse). Semua nilai ada di `AnimationTokens.swift`.

---

## 12 STEP

### Step 1 — Rename ke Archipelago
File: `Package.swift`, `build_app.sh`, `Resources/Info.plist`, `Sources/Archipelago/AppDelegate.swift`
(+ `git mv Sources/DynamicIsland Sources/Archipelago`; aturan satu-file dikecualikan khusus `git mv` ini).
- Package, product, target, dan path jadi `Archipelago`. `build_app.sh`: nama `.app` dan binary.
  `Info.plist`: `CFBundleName`, `CFBundleDisplayName`, `CFBundleExecutable`; `CFBundleIdentifier`
  ganti komponen terakhirnya jadi `archipelago` (awalan tetap). `accessibilityDescription` di AppDelegate.
- Jangan ubah logika apa pun. Bukti tambahan: `grep -rni "dynamicisland" . --exclude-dir=.git
  --exclude-dir=.build` hanya boleh sisa di PLAN-2.md.
- Tes gua: `rm -rf .build && swift build`, jalanin binary `Archipelago`, nama di menu bar benar.

### Step 2 — Hover + resize panel
File: `Window/HoverTrackingView.swift`, `State/IslandState.swift`, `Window/IslandWindowController.swift`,
`Views/IslandRootView.swift`.
- `read_file` penuh dua file nyasar dan SESUAIKAN (jangan bikin versi paralel). `NSTrackingArea`
  `[.mouseEnteredAndExited, .activeAlways, .inVisibleRect]`.
- Enter: `isExpanded = true` + resize panel (anchor tengah-atas, tumbuh ke bawah dan melebar). Exit:
  balik collapsed. Panel TIDAK boleh lebih besar dari area yang kelihatan.
- Tes gua: hover ke notch -> island melebar; keluar -> mengecil; klik area sekitar tidak ketahan.

### Step 3 — Animasi (morph + koreografi)
File: `Window/AnimationTokens.swift` (baru), `Window/IslandMetrics.swift`, `Views/IslandRootView.swift`,
`Window/IslandWindowController.swift`.
- Implement seluruh spesifikasi animasi di atas. Semua angka di `AnimationTokens`.
- Tes gua: bandingkan rasanya dengan Alcove. Lalu ronde T.

### T1..Tn — RONDE TUNING (bukan step; diulang sampai gua puas)
Gua kirim angka dari hasil tes ke chat. Hermes HANYA ubah `AnimationTokens.swift` sesuai angka gua
(satu file, satu commit `T<n>: tune <apa>`), jalanin verify dengan file itu saja, laporan format F, STOP.
Hermes DILARANG ngubah angka sendiri dan DILARANG menilai "bagus/mulus".

### Step 4 — Modul + model Now Playing + provider tiruan
File: `Modules/IslandModule.swift`, `Modules/ModuleRegistry.swift`, `Modules/NowPlaying/NowPlayingInfo.swift`,
`Modules/NowPlaying/NowPlayingProvider.swift`, `Modules/NowPlaying/MockNowPlayingProvider.swift`.
```swift
protocol IslandModule: AnyObject {
    var id: String { get }
    var priority: Int { get }
    var isActive: Bool { get }
    func compactView() -> AnyView
    func expandedView() -> AnyView
}
```
- `ModuleRegistry`: modul aktif dengan priority tertinggi.
- `NowPlayingInfo`: title, artist, album, artwork `NSImage?`, duration, elapsed, isPlaying, bundleID.
- `protocol NowPlayingProvider` (info, onChange, start, stop, play/pause/next/prev/seek) + mock palsu.
- Belum ada UI baru. Tes gua: cukup build.

### Step 5 — UI Now Playing (pakai mock)
File: `Modules/NowPlaying/NowPlayingModule.swift`, `Modules/NowPlaying/NowPlayingViews.swift`,
`Views/PlaybackBars.swift`, `Views/IslandRootView.swift`.
- Collapsed: konten TIDAK menutupi area notch asli; artwork mini di telinga kiri, bar animasi palsu
  (ikut play/pause) di kanan; island boleh melebar kiri-kanan notch saat modul aktif.
- Expanded: cover, judul, artis, progress bar, prev / play-pause / next. SF Symbols, font sistem.
- Progress jalan dari `elapsed` + timer lokal, koreksi saat info baru. Visualizer audio beneran DITUNDA.
- Tes gua: lihat tampilan dengan data palsu.

### Step 6 — Apple Music via AppleScript
File: `Modules/NowPlaying/AppleScriptNowPlayingProvider.swift` (+ helper bila >120 baris),
`Modules/NowPlaying/NowPlayingModule.swift`, `Resources/Info.plist` (kalau perlu).
- Baca state Music (`com.apple.Music`): judul, artis, album, durasi, posisi, status, artwork.
- WAJIB cek `NSWorkspace.shared.runningApplications` dulu (`tell application "Music"` bisa
  MELUNCURKAN app yang mati). Polling ~1 detik hanya saat Music running.
- Izin Automation ditolak -> state "tidak ada izin", tanpa crash/loop. Kontrol: play/pause/next/prev/seek.
- Tes gua: `./build_app.sh`, buka `.app`, kasih izin Automation, putar lagu di Apple Music.

### Step 7 — Spotify + pemilih provider
File: `Modules/NowPlaying/SpotifyProvider.swift`, `Modules/NowPlaying/NowPlayingProviderSelector.swift`,
`Modules/NowPlaying/NowPlayingModule.swift`.
- `com.spotify.client`, aturan sama dengan Step 6. Artwork lewat URL; gagal -> tanpa cover.
- Dua player: pilih yang `isPlaying`; kalau dua-duanya, yang terakhir berubah. Satu sumber `info` ke UI.
  `os.Logger` untuk provider aktif, tanpa data sensitif.

### Step 8 — Baterai + prioritas & transisi
File: `Modules/Battery/BatteryModule.swift`, `Modules/ModuleRegistry.swift`, `Window/AnimationTokens.swift`.
- IOKit Power Sources (`IOPSNotificationCreateRunLoopSource`). Aktif sementara (~3 detik) saat charger
  dicolok/dicabut atau baterai <= 20%. Compact: ikon + persen. Expanded: persen, status, estimasi.
- Prioritas: baterai lebih tinggi tapi sementara; selesai -> balik ke modul sebelumnya. Tak ada modul
  aktif -> island polos seukuran notch. Crossfade antar modul, nilainya di `AnimationTokens`.
- Mac tanpa baterai: modul tak pernah aktif, tanpa crash.

### Step 9 — Kalender: izin dan data (EventKit)
File: `Modules/Calendar/CalendarStore.swift`, `Resources/Info.plist`, `build_app.sh` (kalau perlu).
- `EKEventStore`. Hermes WAJIB verifikasi API izin dan key `Info.plist` yang benar untuk versi macOS
  target (ada perbedaan `requestAccess(to:)` vs API full-access di macOS 14+) dan laporkan pilihannya.
- Event hari ini + beberapa hari ke depan. Izin ditolak -> state "tidak ada izin", tanpa crash.
  Observe `EKEventStoreChangedNotification`. Belum ada UI.

### Step 10 — Kalender: modul UI
File: `Modules/Calendar/CalendarModule.swift`, `Modules/Calendar/CalendarViews.swift`.
- Compact: aktif beberapa menit sebelum event (ikon + "10m"). Expanded: tanggal + daftar event hari
  ini (judul + jam). Tanpa fitur edit. All-day dan event lewat ditangani rapi. Animasi via tokens.
- Tes gua: `./build_app.sh`, beri izin Kalender, cek event muncul.

### Step 11 — Lock screen: deteksi + riset (belum ada UI di atas layar kunci)
File: `Modules/LockScreen/LockStateMonitor.swift`, `docs/lockscreen-research.md`.
- Deteksi terkunci/terbuka lewat `DistributedNotificationCenter` (`com.apple.screenIsLocked` /
  `com.apple.screenIsUnlocked`) ke `IslandState.isLocked`. Hermes bilang jujur kalau nama notifikasi
  ini tidak bisa dia buktikan dari sumber yang dia baca.
- Riset tertulis: cara menampilkan window di atas layar kunci (window level publik seperti
  `CGShieldingWindowLevel`, atau API privat), kebutuhan, risiko, kemungkinan jalan di macOS 27.0.1.
  Tandai tiap klaim: "terdokumentasi" / "laporan komunitas" / "tebakan". DILARANG nulis kode API privat.
- Gua putusin lanjut atau nggak setelah baca riset. Eksperimen visualnya (island melebar di layar
  kunci dengan ikon kunci + animasi) BUKAN bagian 12 step ini; baru dikerjain kalau gua setuju.

### Step 12 — Polish & rilis
File: `README.md`, `LICENSE`, `NOTICE.md`, `.gitignore`.
- README jujur: apa ini, screenshot (gua isi), cara build, izin (Automation, Kalender), bagian
  "Private API" terus terang (kalau ada). Proyek independen terinspirasi Alcove, tidak berafiliasi.
- `LICENSE` MIT (nama & tahun gua isi), `NOTICE.md`, `.gitignore` final. `git grep -n "/Users/"` tidak
  boleh nemu path pribadi.

---

## DI LUAR 12 STEP (hanya kalau gua minta)
- Adapter MediaRemote (baca lagu dari app lain): riset lisensi dulu, belum terbukti di macOS 27.0.1.
- Eksperimen lock screen (flag default mati; gagal -> dihapus bersih).
- HUD volume/kecerahan, gestur swipe, file tray, notifikasi.

## RISIKO
- Kemiripan animasi dengan Alcove dicapai lewat tuning bertahap, bukan jaminan "persis".
- Lock screen kemungkinan butuh API privat dan belum terbukti di macOS 27.0.1.
- Nempel notch + level di atas menu bar bisa rewel di fullscreen/Spaces/multi-monitor.
- Izin Automation dan Kalender hanya muncul kalau jalan sebagai bundle dengan Info.plist benar.
- Build hijau != jalan benar. Tunggu tes visual gua sebelum "next".
