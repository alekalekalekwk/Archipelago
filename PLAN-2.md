# PLAN.md — Archipelago (macOS, notch island) — v3

Dokumen ini satu-satunya sumber kebenaran buat Hermes. `read_file` PENUH di awal
setiap sesi dan sebelum tiap step. PLAN.md READ-ONLY buat Hermes: jangan edit,
jangan commit perubahan PLAN.md. Gua yang ngedit.

## 0. Tujuan

App macOS (khusus Mac) yang mengubah area notch jadi "island" interaktif dan
meniru PENGALAMAN PAKAI Alcove: animasi, Now Playing (Apple Music + Spotify),
kalender, dan tampilan saat Mac terkunci. Kode, desain, dan aset dibuat sendiri,
bukan salinan.

- Mac BERNOTCH: island nempel di notch. Collapsed = seukuran notch.
- Mac TANPA notch: island nempel di tengah atas layar, ukuran "notch virtual".
- Hover/klik: island melebar dan memanjang ke bawah (expanded).
- Modular lewat protokol `IslandModule`.
- Tanpa iklan, tanpa telemetry.

Prioritas gua: **ANIMASI** paling utama, lalu Now Playing, kalender, lock screen.
Lock screen sengaja paling akhir dan paling berisiko (lihat S20).

UI: hitam polos, font sistem. DILARANG: gradient norak, glow, blur berlebih,
emoji di UI, dekorasi tanpa fungsi.

## STATUS (diisi gua)
- S0 (c74cd8e), S1 (440e236), S2 (42e7cde, kapsul), commit lama `c755330`
  (status item Quit, Info.plist, build_app.sh, AppDelegate), PLAN v2 (b27b916),
  S3 (cff8830, geometri notch + panel nempel atas) = DONE dan sudah dites gua
  (panel nongol, nempel atas, di atas menu bar).
- Catatan: S3 menghapus observer perubahan layar dari `c755330`. Ditambah lagi di S5.
- S3-fix (lebar notch dari `auxiliaryTopLeftArea`/`auxiliaryTopRightArea`) = BELUM.
- Mac gua: macOS 27.0.1 (build 26A434), Command Line Tools, Apple Music + Spotify.
- Alcove gua pakai berdampingan; matikan Alcove saat tes manual.

---

## RULE 0 — REPO LOCK (paling tinggi)

1. Satu-satunya direktori kerja: `~/Archipelago`
2. Sebelum SETIAP step, jalanin dan TEMPEL output mentahnya:
   ```
   pwd
   git rev-parse --show-toplevel
   git branch --show-current
   git remote -v
   ```
   Harus: `/Users/macbook/Archipelago` dua kali, branch `main`, remote `.../Archipelago`.
   Kalau beda, STOP. Jangan edit apa pun.
3. Dilarang baca/tulis/hapus di luar repo, KECUALI `/tmp/archipelago-research/`
   (clone referensi read-only) dan baca-saja `~/SwiftProject/SleeplessClone`.
4. Kerja di `main`. Jangan bikin branch/tag sendiri.

## SAFETY RULES (DILARANG KERAS)

1. DILARANG menjalankan app: `swift run`, `open *.app`, `.build/*/DynamicIsland`,
   `osascript` yang nargetin Music/Spotify/Calendar, atau eksekusi binary hasil build.
   Boleh: `swift build`, `swift package resolve`, `./build_app.sh` (cuma bungkus).
2. DILARANG `sudo`, `pmset`, `defaults write`, `tccutil`, `launchctl`,
   `brew/pip/npm install`, atau ubah setting sistem.
3. DILARANG `git push`, `--force`, `reset --hard`, `clean -fd`, `rebase`,
   `commit --amend`, hapus branch, `git init` ulang. Cuma `add` dan `commit`.
4. DILARANG hapus file yang bukan lu bikin di step ini.
5. DILARANG: `#Preview`, `@Observable`, `import Observation`, `@main` di
   executable yang punya `main.swift`. Pakai `ObservableObject` + `@Published`.
6. DILARANG dependency pihak ketiga selain mediaremote-adapter (S14, setelah gua setuju lisensinya).
7. DILARANG bikin/ubah file di luar daftar "File" step yang lagi jalan, DILARANG
   ngerjain fitur step lain.
   Ide tambahan? Tulis di "Catatan untuk Gua", jangan dikerjain.
8. DILARANG klaim perilaku runtime ("works", "muncul", "mulus", "jalan"). Cuma boleh
   bilang "build hijau". Tes runtime dan penilaian animasi = tugas gua.
9. DILARANG mengarang output. Blok BUKTI harus hasil tempel mentah dari command
   yang BENAR-BENAR dijalankan di sesi ini. Dilarang nulis hash commit, isi log,
   atau output build dari ingatan, dan dilarang nambah komentar/anotasi di dalam
   blok output. (Gua selalu cross-check di terminal gua sendiri.)
10. DILARANG nyalin kode dari repo/app lain. Cuma boleh baca buat ngerti cara kerjanya.
11. DILARANG memakai API privat (SkyLight, CGS*, framework privat lain) KECUALI
    yang sudah gua setujui eksplisit di chat, dan hanya di folder yang ditentukan.
12. DILARANG hardcode angka ukuran/radius/durasi/spring di view. Semua lewat
    `IslandMetrics.swift` dan `AnimationTokens.swift`.

## ATURAN KERJA PER SUB-TASK

**A. Satu file per tool call.** Bikin/edit satu file, verifikasi, baru file berikutnya.
**B. Ukuran.** Target <= 120 baris per file Swift. Lebih? Pecah, bikin satu-satu.
**C. Edit file existing:** `read_file` PENUH dulu, baru edit. Berubah? Baca ulang.
**D. Build.** `swift build 2>&1 | tail -25` tiap file/step. Gagal? Perbaiki maks 2x.
Gagal ke-3: STOP, laporkan error apa adanya. Jangan rewrite besar buat nyelamatin build.
**E. Satu commit per sub-task.** Format `S<n>: <ringkas>`. Jangan commit kalau build merah.
**F. BUKTI (tempel mentah, jangan diringkas):**
```
BUKTI S<n>
0) pwd / git rev-parse --show-toplevel / git branch --show-current / git remote -v
1) swift build 2>&1 | tail -15
2) git log --oneline -3
3) git status --short      <- harus kosong setelah commit
4) git --no-pager show --stat HEAD   <- harus cuma file yang ada di daftar "File" step
5) wc -l <file yang dibuat/diubah>
```
Tanpa blok ini, step BELUM SELESAI.
**G. Laporan akhir:**
```
S<n> SELESAI (build hijau, belum diuji manual)
File dibuat/diubah: ...
Cara gua tes manual: <3-6 langkah konkret + apa yang HARUS kelihatan>
Catatan untuk Gua: <risiko / ide / yang gak yakin>
Menunggu "next".
```
**H. STOP** setelah laporan. Jangan mulai step berikutnya sampai gua ketik "next".
"fix: ..." = perbaiki di step yang sama, commit baru `S<n>-fix: ...`.
**I. Ragu?** STOP dan tanya satu pertanyaan. Jangan nebak API Apple; kalau gak yakin
sebuah API ada, bilang di laporan dan pakai cara paling konservatif.

## KONSTRAIN TEKNIS

- SwiftPM saja (Command Line Tools). Target executable pakai `main.swift`.
- `swift-tools-version:5.9`, `.macOS(.v13)` (disesuaikan kalau API tertentu butuh lebih tinggi; laporkan).
- `.accessory` activation policy; di bundle `LSUIElement = true`.
- State: `ObservableObject`. UI di `@MainActor`.

### Geometri notch
- Ada notch kalau `NSScreen.safeAreaInsets.top > 0`.
- Lebar notch ≈ `screen.frame.width - auxiliaryTopLeftArea.width - auxiliaryTopRightArea.width`
  (kalau dua area itu non-nil, kalau tidak, fallback dari `IslandMetrics`). Tinggi ≈ `safeAreaInsets.top`.
- Panel nempel tepi ATAS layar (`screen.frame.maxY`), center horizontal, level di atas
  menu bar. Bentuk: hitam, sudut atas rata, sudut bawah membulat.
- Panel pas seukuran bentuknya. Jangan panel besar transparan yang nutupin klik.

### Spesifikasi animasi (acuan kualitatif; angka dituning lewat ronde T)
- Island tumbuh DARI bentuk notch itu sendiri (satu shape yang morph ukuran dan radius
  sudut bawah), bukan dua view berbeda yang di-crossfade.
- Konten expanded masuk sedikit TERLAMBAT dari shape (fade + scale kecil, bisa stagger
  per elemen). Saat collapse, konten hilang DULU, baru shape mengecil.
- Expand dan collapse pakai spring TERPISAH. Tanpa overshoot kasar di collapse.
- Hover grow kecil (mis. beberapa poin) sebelum expand penuh. Hover keluar pakai
  jeda kecil supaya tidak flicker.
- Semua animasi harus INTERRUPTIBLE: hover masuk-keluar cepat tidak boleh bikin
  state nyangkut atau panel patah.
- Target 60 fps. Resize panel dan animasi SwiftUI disinkronkan (panel dibesarkan dulu
  saat expand, dikecilkan SETELAH animasi selesai saat collapse). Tidak ada kedip.
- Semua nilai (response, damping, delay, durasi, scale, radius) ada di
  `AnimationTokens.swift`. Itu satu-satunya file yang diubah saat tuning.

---

## FASE 1 — FONDASI + ANIMASI

### S3-fix — Lebar notch beneran
File: `Window/NotchGeometry.swift`.
- Hitung lebar dari `auxiliaryTopLeftArea`/`auxiliaryTopRightArea`; nil -> fallback `IslandMetrics`.
- Hapus angka 200 dan komentar "ponytail".
- Commit: `S3-fix: derive notch width from auxiliary areas`.

### S4 — Bentuk notch (SwiftUI)
File: `Views/NotchShape.swift` (baru), `Views/IslandRootView.swift`.
- `NotchShape: Shape`: dua radius sudut bawah animatable (`animatableData`), sudut atas rata.
- `IslandRootView`: ganti Capsule dengan `NotchShape` hitam.
- Commit: `S4: notch-shaped island view`.
- Tes gua: nempel tepi atas, menyatu dengan notch, sudut bawah bulat, tak lebih lebar dari notch.

### S5 — Observer layar + review bundle
File: `Window/ScreenObserver.swift` (baru), `AppDelegate.swift`, `Resources/Info.plist`, `build_app.sh`.
- Observe `NSApplication.didChangeScreenParametersNotification` -> hitung ulang geometri & reposisi.
- Status item sudah ada: ganti judul menu jadi "Quit Archipelago". Review `Info.plist`
  dan `build_app.sh` yang sudah ada; JANGAN tulis ulang, cuma perbaiki yang kurang.
- Commit: `S5: screen change observer`.

### S6 — Hover + resize panel
File: `Window/HoverTrackingView.swift`, `State/IslandState.swift`, `Window/IslandWindowController.swift`.
- `read_file` penuh dua file existing dan SESUAIKAN (jangan bikin versi paralel).
  `NSTrackingArea` `[.mouseEnteredAndExited, .activeAlways, .inVisibleRect]`.
- Enter: `isExpanded = true` + resize panel (anchor tengah-atas, tumbuh ke bawah dan melebar).
  Exit: balik collapsed. Panel TIDAK boleh lebih besar dari area yang kelihatan.
- Commit: `S6: hover tracking and panel resize`.

### S7 — Morph dasar
File: `Views/IslandRootView.swift`, `Window/AnimationTokens.swift` (baru), `Window/IslandMetrics.swift`.
- Shape morph ukuran + radius dengan satu spring dulu. Pindahkan semua angka ke `AnimationTokens`.
- Commit: `S7: base morph animation`.

### S8 — Koreografi animasi
File: `Views/IslandRootView.swift`, `Window/AnimationTokens.swift`, `Window/IslandWindowController.swift`.
- Implement spesifikasi animasi di atas: konten telat/stagger, spring expand vs collapse
  terpisah, hover grow, jeda hover keluar, interruptible, sinkron resize panel.
- Commit: `S8: animation choreography`.

### T1..Tn — RONDE TUNING (diulang sampai gua puas)
Bukan step Hermes biasa. Alur: gua tes, gua kirim video/screenshot + deskripsi beda
dari Alcove, gua kasih angka baru ke chat. Hermes HANYA mengubah `AnimationTokens.swift`
sesuai angka dari gua (satu file, satu commit `T<n>: tune <apa>`), BUKTI lengkap, STOP.
Hermes DILARANG ngubah angka sendiri dan DILARANG nilai "mulus/bagus".

---

## FASE 2 — NOW PLAYING

### S9 — Protokol modul
File: `Modules/IslandModule.swift`, `Modules/ModuleRegistry.swift`, `Views/IslandRootView.swift`.
```swift
protocol IslandModule: AnyObject {
    var id: String { get }
    var priority: Int { get }
    var isActive: Bool { get }
    func compactView() -> AnyView    // isi "telinga" kiri/kanan notch saat collapsed
    func expandedView() -> AnyView
}
```
- Collapsed: konten TIDAK boleh menutupi area notch asli; modul di telinga kiri/kanan
  (island boleh melebar di kiri-kanan notch kalau modul aktif).
- `ModuleRegistry`: modul aktif dengan priority tertinggi. Satu placeholder (dihapus di S11).
- Commit: `S9: IslandModule protocol and registry`.

### S10 — Model Now Playing + provider tiruan
File: `Modules/NowPlaying/NowPlayingInfo.swift`, `NowPlayingProvider.swift`, `MockNowPlayingProvider.swift`.
- `NowPlayingInfo`: title, artist, album, artwork `NSImage?`, duration, elapsed, isPlaying, bundleID.
- `protocol NowPlayingProvider` (info, onChange, start, stop, play/pause/next/prev/seek). Mock data palsu.
- Commit: `S10: now playing model and mock provider`.

### S11 — UI Now Playing (pakai mock)
File: `Modules/NowPlaying/NowPlayingModule.swift`, `NowPlayingViews.swift`, `Views/PlaybackBars.swift`.
- Collapsed: artwork mini di telinga kiri, bar animasi palsu (ikut play/pause) di kanan.
- Expanded: cover, judul, artis, progress bar, tombol prev / play-pause / next.
- Progress jalan dari `elapsed` + timer lokal, koreksi saat info baru masuk.
- SF Symbols, font sistem. Semua animasi lewat `AnimationTokens`. Hapus placeholder S9.
- Visualizer audio beneran DITUNDA (butuh `AudioHardwareCreateProcessTap` + izin).
- Commit: `S11: now playing UI with mock`.

### S12 — Apple Music via AppleScript
File: `Modules/NowPlaying/AppleScriptNowPlayingProvider.swift` (+ helper kalau >120 baris).
- Baca state Music (`com.apple.Music`): judul, artis, album, durasi, posisi, status, artwork.
- WAJIB cek `NSWorkspace.shared.runningApplications` dulu. `tell application "Music"`
  bisa MELUNCURKAN Music kalau mati. Dilarang.
- Polling ~1 detik hanya saat Music running; selain itu berhenti/jarang.
- Izin Automation ditolak? State "tidak ada izin", jangan crash/loop.
- Kontrol: play/pause, next, previous, seek.
- Commit: `S12: Apple Music provider via AppleScript`.

### S13 — Spotify via AppleScript
File: `Modules/NowPlaying/SpotifyProvider.swift` (baru), selector kalau perlu.
- `com.spotify.client`, aturan sama dengan S12 (cek running dulu, izin ditolak aman).
- Artwork Spotify lewat URL; gagal/offline -> tanpa cover, jangan crash.
- Dua player jalan sekaligus: pilih yang sedang `isPlaying`; kalau dua-duanya, yang terakhir berubah.
- Commit: `S13: Spotify provider`.

### S14 — Adapter MediaRemote (OPSIONAL, riset dulu)
**S14a (read-only):** clone ke `/tmp/archipelago-research/`:
`github.com/ungive/mediaremote-adapter`, fork Swift package `github.com/ejbills/mediaremote-adapter`,
referensi arsitektur `github.com/spitfiresb/notch`. Network diblok? STOP, gua clone manual.
- BACA dan laporkan `LICENSE` tiap repo. Jangan lanjut tanpa persetujuan gua.
- Laporkan cara kerja (spawn `/usr/bin/perl` + framework helper) dan cara dibundel.
- Klaim komunitas cuma sampai macOS 26.x; di macOS 27.0.1 gua BELUM TERBUKTI, tulis eksplisit.
**S14b (hanya setelah gua setuju lisensi + "next"):** dependency SwiftPM atau vendor.
`AdapterNowPlayingProvider`: stream, parse, restart dengan backoff. Update `build_app.sh`.
Manfaatnya: baca lagu dari app lain (browser dll). Tidak wajib buat MVP.
- Commit: `S14a: research notes` (kalau ada file) dan `S14b: adapter provider`.

### S15 — Pemilihan provider
File: `NowPlayingModule.swift`, `NowPlayingProviderSelector.swift`.
- Urutan: Apple Music/Spotify (AppleScript) utama; adapter tambahan kalau S14b ada dan terbukti jalan.
- Satu sumber `info` ke UI. `os.Logger` mencatat provider aktif, tanpa data sensitif.
- Commit: `S15: provider selection`.

---

## FASE 3 — MODUL LAIN

### S16 — Baterai/Charging
File: `Modules/Battery/BatteryModule.swift`.
- IOKit Power Sources (`IOPSNotificationCreateRunLoopSource`).
- Aktif sementara (~3 detik) saat charger dicolok/dicabut, atau baterai <= 20%.
  Compact: ikon + persen. Expanded: persen, status, estimasi.
- Mac tanpa baterai: modul tak pernah aktif, tanpa crash.
- Commit: `S16: battery module`.

### S17 — Prioritas, live activity, transisi
- Baterai priority lebih tinggi tapi sementara; selesai -> balik ke modul sebelumnya.
  Tak ada modul aktif -> island polos seukuran notch.
- Perpindahan modul: crossfade halus, nilai di `AnimationTokens`.
- Commit: `S17: module priority and transitions`.

### S18 — Kalender: izin dan data (EventKit)
File: `Modules/Calendar/CalendarStore.swift` (baru), `Resources/Info.plist`, `build_app.sh` kalau perlu.
- EventKit (`EKEventStore`). Izin kalender: Hermes WAJIB verifikasi API dan key `Info.plist`
  yang benar untuk versi macOS target (ada perbedaan `requestAccess(to:)` vs API full-access
  baru di macOS 14+ dan usage description-nya). Laporkan yang dipilih dan alasannya.
- Ambil event hari ini + beberapa hari ke depan. Izin ditolak -> state "tidak ada izin", tanpa crash.
- Observe `EKEventStoreChangedNotification` buat refresh. Belum ada UI.
- Commit: `S18: calendar store`.

### S19 — Kalender: modul UI
File: `Modules/Calendar/CalendarModule.swift`, `CalendarViews.swift`.
- Compact: aktif ~beberapa menit sebelum event mulai (mis. ikon + "10m").
- Expanded: tanggal, daftar event hari ini (judul + jam). Tanpa fitur edit.
- Event all-day dan yang sudah lewat ditangani rapi. Animasi lewat `AnimationTokens`.
- Commit: `S19: calendar module`.

---

## FASE 4 — LOCK SCREEN (RISET DULU, TIDAK DIJAMIN BERHASIL)

### S20a — Riset deteksi kunci (read-only + kode kecil terisolasi)
File: `Modules/LockScreen/LockStateMonitor.swift` (baru).
- Deteksi terkunci/terbuka lewat `DistributedNotificationCenter`
  (`com.apple.screenIsLocked` / `com.apple.screenIsUnlocked`). Kirim ke
  `IslandState` (`isLocked`). Hanya deteksi, belum ada UI baru. Hermes WAJIB bilang
  kalau nama notifikasi ini tidak terbukti dari sumber yang bisa dia baca.
- Commit: `S20a: lock state monitor`.

### S20b — Riset menampilkan di atas layar kunci (READ-ONLY, tanpa kode)
- Tulis `docs/lockscreen-research.md` (satu-satunya file): pendekatan yang mungkin
  (window level publik seperti `CGShieldingWindowLevel`, atau API privat), apa yang
  dibutuhkan masing-masing, risiko, dan apakah terlihat bakal jalan di macOS 27.0.1.
  Tandai tiap klaim: "terdokumentasi" / "laporan komunitas" / "tebakan".
- DILARANG menulis kode memakai API privat di step ini. Gua yang putusin lanjut atau nggak.
- Commit: `S20b: lock screen research notes`.

### S20c — Eksperimen (HANYA setelah gua setuju eksplisit, dan sebatas yang gua setujui)
- Kode taruh di `Modules/LockScreen/` dengan feature flag DEFAULT MATI.
- Efek yang dituju: saat `isLocked`, notch melebar menampilkan ikon kunci dengan
  animasi; saat unlock, animasi buka lalu kembali ke modul normal.
- Kalau gagal di macOS 27.0.1, hapus bersih. Tidak ada kode setengah jadi di `main`.
- Commit: `S20c: lock screen island (experimental)`.

---

## FASE 5 — RILIS

### S21 — Polish & rilis
- `README.md` jujur: apa ini, screenshot (gua isi), cara build, izin (Automation, Kalender),
  bagian "Private API" terus terang (MediaRemote adapter kalau dipakai; lock screen kalau
  memakai API privat). Tulis ini proyek independen yang terinspirasi Alcove, tidak berafiliasi.
  Tidak butuh sudo (kalau memang tidak).
- `LICENSE` (MIT; nama & tahun gua isi), `NOTICE.md` (atribusi dependency), `.gitignore` final.
- Cek: `git grep -n "/Users/"` tidak nemu path pribadi.
- Commit: `S21: README, LICENSE, NOTICE, gitignore`.

## RISIKO (jangan disembunyikan)
- Kemiripan animasi dengan Alcove dicapai lewat tuning bertahap, bukan jaminan "persis".
- Lock screen: menampilkan window di atas layar kunci kemungkinan butuh API privat;
  bisa pecah antar versi macOS dan belum terbukti di macOS 27.0.1.
- MediaRemote = API privat, belum terbukti di macOS 27.0.1. Apple Music/Spotify lewat
  AppleScript tidak bergantung ke situ.
- Nempel notch + level di atas menu bar bisa rewel di fullscreen/Spaces/multi-monitor.
- Izin Automation dan Kalender hanya muncul kalau jalan sebagai bundle dengan Info.plist benar.
- Build hijau != jalan benar. Tunggu tes manual gua sebelum "next".
- Target SwiftPM masih `DynamicIsland` dan nama app di bundle bisa beda dari "Archipelago";
  rename dilakukan kalau gua minta.
