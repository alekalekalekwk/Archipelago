# PLAN.md — Archipelago (macOS, notch island) — v2

Dokumen ini satu-satunya sumber kebenaran buat Hermes. `read_file` PENUH di awal
setiap sesi dan sebelum tiap step. PLAN.md READ-ONLY buat Hermes: jangan edit,
jangan commit perubahan PLAN.md. Gua yang ngedit.

## 0. Tujuan

App macOS (khusus Mac) yang mengubah area notch jadi "island" interaktif.
Fiturnya meniru pengalaman pakai Alcove, tapi kode, desain, dan aset dibuat
sendiri (bukan salinan).

- Mac BERNOTCH: island nempel di notch. Collapsed = seukuran notch.
- Mac TANPA notch: island nempel di tengah atas layar, ukuran "notch virtual".
- Hover/klik: island melebar dan memanjang ke bawah (expanded).
- Modular lewat protokol `IslandModule`.
- Fase 1 (MVP, step di bawah): Now Playing (Apple Music jadi prioritas) + Baterai/Charging.
- Fase 2 (BELUM, jangan dikerjain Hermes sebelum gua bilang): kalender (EventKit),
  AirPods/Bluetooth, HUD volume/kecerahan, gestur swipe, file tray, notifikasi,
  Lock Screen. Detailnya ditulis nanti.
- Tanpa iklan, tanpa telemetry.

UI: hitam polos, font sistem, animasi spring halus. DILARANG: gradient norak,
glow, blur berlebih, emoji di UI, dekorasi tanpa fungsi.

## STATUS (diisi gua)
- S0 DONE (c74cd8e), S1 DONE (440e236), S2 DONE (42e7cde, pill kapsul).
- Mulai S3. Pill kapsul S2 akan DIGANTI bentuk notch; kode S1/S2 dipakai ulang
  dan diubah, bukan ditulis dari nol.
- Mac gua: macOS 27.0.1 (build 26A434), Command Line Tools, Apple Music.

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
   (clone referensi read-only, lihat S12) dan baca-saja `~/SwiftProject/SleeplessClone`.
4. Kerja di `main`. Jangan bikin branch/tag sendiri.

## SAFETY RULES (DILARANG KERAS)

1. DILARANG menjalankan app: `swift run`, `open *.app`, `.build/*/Archipelago`,
   `osascript` yang nargetin Music/Spotify, atau eksekusi binary hasil build.
   Boleh: `swift build`, `swift package resolve`, `./build_app.sh` (cuma bungkus).
2. DILARANG `sudo`, `pmset`, `defaults write`, `tccutil`, `launchctl`,
   `brew/pip/npm install`, atau ubah setting sistem.
3. DILARANG `git push`, `--force`, `reset --hard`, `clean -fd`, `rebase`,
   `commit --amend`, hapus branch, `git init` ulang. Cuma `add` dan `commit`.
4. DILARANG hapus file yang bukan lu bikin di step ini.
5. DILARANG: `#Preview`, `@Observable`, `import Observation`, `@main` di
   executable yang punya `main.swift`. Pakai `ObservableObject` + `@Published`.
6. DILARANG dependency pihak ketiga selain mediaremote-adapter (S12, setelah gua setuju lisensinya).
7. DILARANG bikin/ubah file di luar daftar "File" step yang lagi jalan, DILARANG
   ngerjain fitur step lain (preseden: di S2 kemarin ada file S4 yang nyasar).
   Ide tambahan? Tulis di "Catatan untuk Gua", jangan dikerjain.
8. DILARANG klaim perilaku runtime ("works", "muncul", "jalan"). Cuma boleh
   bilang "build hijau". Tes runtime = tugas gua.
9. DILARANG mengarang output. Blok BUKTI harus hasil tempel mentah dari command
   yang BENAR-BENAR dijalankan di sesi ini. Dilarang nulis hash commit atau
   isi log dari ingatan. (Gua selalu cross-check di terminal gua sendiri.)
10. DILARANG nyalin kode dari repo/app lain. Cuma boleh baca buat ngerti cara kerjanya.

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
4) git show --stat HEAD    <- harus cuma file yang ada di daftar "File" step
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
- `swift-tools-version:5.9`, `.macOS(.v13)` (disesuaikan nanti kalau perlu).
- `.accessory` activation policy; di bundle `LSUIElement = true`.
- State: `ObservableObject`. UI di `@MainActor`.
- Semua konstanta ukuran/margin/durasi/radius di `IslandMetrics.swift`.

### Geometri notch (acuan buat S3, Hermes WAJIB verifikasi API-nya compile)
- Ada notch kalau `NSScreen.safeAreaInsets.top > 0`.
- Lebar notch ≈ `screen.frame.width - auxiliaryTopLeftArea.width - auxiliaryTopRightArea.width`
  (kalau dua area itu non-nil). Tinggi notch ≈ `safeAreaInsets.top`.
- Tanpa notch: pakai ukuran virtual dari `IslandMetrics` (mis. 200x32).
- Panel diposisikan nempel tepi ATAS layar (`screen.frame.maxY`), BUKAN di bawah
  menu bar, dan di-center horizontal. Level window harus di atas menu bar
  (mis. `.mainMenu + 3`; Hermes verifikasi mana yang berfungsi dan laporkan).
- Bentuk: hitam, sudut atas rata menyatu dengan tepi layar, sudut bawah membulat.
- Panel tetap pas seukuran bentuknya. Jangan panel besar transparan yang nutupin klik.

---

## URUTAN STEP — FASE 1

### S3 — Geometri notch + panel nempel atas (rework S1)
File: `Window/NotchGeometry.swift` (baru), `Window/IslandMetrics.swift`,
`Window/IslandPanel.swift`, `Window/IslandWindowController.swift`.
- `NotchGeometry`: `hasNotch`, `notchSize`, `frameForCollapsed(on:)` dengan fallback virtual.
- Panel level di atas menu bar, collapsed frame = ukuran notch, nempel tepi atas.
- Belum ada perubahan tampilan SwiftUI (itu S4). Jangan sentuh `HoverTrackingView`/`IslandState`.
- Cetak (lewat `print`, tanpa dijalanin) TIDAK perlu; cukup struktur kode yang jelas.
- Commit: `S3: notch geometry and top-attached panel`.

### S4 — Bentuk notch (SwiftUI)
File: `Views/NotchShape.swift` (baru), `Views/IslandRootView.swift`.
- `NotchShape: Shape` dengan dua radius sudut bawah yang animatable (`animatableData`).
  Sudut atas rata.
- `IslandRootView`: ganti Capsule dengan `NotchShape` hitam.
- Commit: `S4: notch-shaped island view`.
- Tes gua: pill hitam kini nempel tepi atas, menyatu dengan notch (atau di tengah atas
  kalau tanpa notch), sudut bawah bulat, sudut atas rata.

### S5 — Status item, bundle, perubahan layar (dulu S3)
File: `Window/ScreenObserver.swift` (baru), `AppDelegate.swift`, `Resources/Info.plist`, `build_app.sh`.
- Observe `NSApplication.didChangeScreenParametersNotification` -> hitung ulang geometri & reposisi.
- `NSStatusItem` minimal: satu item "Quit Archipelago".
- `Info.plist`: `LSUIElement`, `NSAppleEventsUsageDescription` (alasan jujur: kontrol Apple Music).
  `build_app.sh`: build release, rakit `.app`, `codesign --force --sign -`. TIDAK menjalankan app.
- Alasan bundle sekarang: izin Automation & framework adapter butuh bundle beneran.
- Commit: `S5: screen change, status item, build_app.sh`.

### S6 — Hover + resize panel (pakai ulang kode S2 yang nyasar)
File: `Window/HoverTrackingView.swift`, `State/IslandState.swift`, `Window/IslandWindowController.swift`.
- `read_file` penuh dulu dua file existing dan SESUAIKAN dengan spesifikasi ini
  (jangan bikin versi paralel). `NSTrackingArea` `[.mouseEnteredAndExited, .activeAlways, .inVisibleRect]`.
- Enter: `isExpanded = true` + resize panel ke ukuran expanded (anchor tengah-atas tetap,
  tumbuh ke bawah dan melebar). Exit: balik collapsed. Debounce ~80 ms saat exit.
- Panel TIDAK boleh lebih besar dari area yang kelihatan.
- Commit: `S6: hover tracking and panel resize`.

### S7 — Morph animasi spring
File: `Views/IslandRootView.swift`, `Window/IslandMetrics.swift`.
- Animasi ukuran dan radius sudut bawah (mis. 10 -> 24) dengan
  `spring(response ~0.35, dampingFraction ~0.8)`.
- Sinkron resize panel dan animasi SwiftUI: saat expand, panel dibesarkan dulu;
  saat collapse, panel dikecilkan SETELAH animasi selesai.
- Commit: `S7: spring morph`.

### S8 — Protokol modul
File: `Modules/IslandModule.swift`, `Modules/ModuleRegistry.swift`, `Views/IslandRootView.swift`.
```swift
protocol IslandModule: AnyObject {
    var id: String { get }
    var priority: Int { get }
    var isActive: Bool { get }
    func compactView() -> AnyView    // isi sisi kiri/kanan notch saat collapsed
    func expandedView() -> AnyView
}
```
- Saat collapsed, konten TIDAK boleh menutupi area notch asli; modul menempati
  "telinga" kiri/kanan di sisi notch (lebar island collapsed boleh melebar
  di kiri-kanan notch kalau modul aktif).
- `ModuleRegistry`: modul aktif dengan priority tertinggi.
- Satu modul placeholder buat verifikasi alur (dihapus di S10).
- Commit: `S8: IslandModule protocol and registry`.

### S9 — Model Now Playing + provider tiruan
File: `Modules/NowPlaying/NowPlayingInfo.swift`, `NowPlayingProvider.swift`, `MockNowPlayingProvider.swift`.
- `NowPlayingInfo`: title, artist, album, artwork `NSImage?`, duration, elapsed, isPlaying, bundleID.
- `protocol NowPlayingProvider` (info, onChange, start, stop, play/pause/next/prev/seek).
- Mock dengan data palsu.
- Commit: `S9: now playing model and mock provider`.

### S10 — UI Now Playing (pakai mock)
File: `Modules/NowPlaying/NowPlayingModule.swift`, `NowPlayingViews.swift`, `Views/PlaybackBars.swift`.
- Collapsed: artwork mini di telinga kiri, bar animasi (palsu, ikut play/pause) di telinga kanan.
- Expanded: cover, judul, artis, progress bar, tombol prev / play-pause / next.
- Progress jalan dari `elapsed` + timer lokal, koreksi saat info baru masuk.
- SF Symbols, font sistem. Hapus modul placeholder S8.
- Visualizer audio beneran DITUNDA (butuh `AudioHardwareCreateProcessTap` + izin).
- Commit: `S10: now playing UI with mock`.

### S11 — Apple Music via AppleScript (jalur utama buat gua)
File: `Modules/NowPlaying/AppleScriptNowPlayingProvider.swift` (+ helper kalau >120 baris).
- Baca state Music (`com.apple.Music`): judul, artis, album, durasi, posisi, status, artwork.
- WAJIB cek `NSWorkspace.shared.runningApplications` dulu. `tell application "Music"`
  bisa MELUNCURKAN Music kalau mati. Dilarang.
- Polling ~1 detik hanya saat Music running; selain itu berhenti/jarang. Hemat CPU.
- Izin Automation ditolak? State "tidak ada izin", jangan crash/loop.
- Kontrol: play/pause, next, previous, seek.
- Spotify: tambahkan setelah Music stabil (`com.spotify.client`), commit terpisah `S11b`.
- Commit: `S11: Apple Music provider via AppleScript`.

### S12 — Adapter MediaRemote (riset dulu, baru integrasi)
**S12a (read-only):** clone ke `/tmp/archipelago-research/`:
`github.com/ungive/mediaremote-adapter`, fork Swift package `github.com/ejbills/mediaremote-adapter`,
referensi arsitektur `github.com/spitfiresb/notch`. Network diblok? STOP, gua clone manual.
- BACA dan laporkan `LICENSE` tiap repo. Jangan lanjut tanpa persetujuan gua.
- Laporkan cara kerja (spawn `/usr/bin/perl` + framework helper, buat lolos pembatasan
  MediaRemote sejak macOS 15.4), format stream, cara dibundel ke .app.
- Kompatibilitas: klaim komunitas cuma sampai macOS 26.x. Di macOS 27.0.1 gua BELUM TERBUKTI;
  tulis itu eksplisit. Tes manual gua yang menentukan.
**S12b (setelah gua setuju lisensi + "next"):** dependency SwiftPM atau vendor.
`AdapterNowPlayingProvider`: stream, parse, restart dengan backoff. Update `build_app.sh`.
- Commit: `S12a: research notes` (kalau ada file) dan `S12b: adapter provider`.

### S13 — Kontrol lewat adapter
- Play/pause, next, previous, seek via adapter. Seek optimistik, koreksi saat update.
- Commit: `S13: playback controls via adapter`.

### S14 — Pemilihan provider
File: `NowPlayingModule.swift`, `NowPlayingProviderSelector.swift`.
- Urutan: kalau adapter terbukti jalan, adapter utama (semua app); AppleScript cadangan.
  Kalau adapter gagal start / error berulang, AppleScript jadi utama. Balik ke adapter kalau pulih.
- Satu sumber `info` ke UI. `os.Logger` mencatat provider aktif, tanpa data sensitif.
- Commit: `S14: provider selection and fallback`.

### S15 — Modul Baterai/Charging
File: `Modules/Battery/BatteryModule.swift`.
- IOKit Power Sources (`IOPSNotificationCreateRunLoopSource`).
- Aktif sementara (~3 detik) saat charger dicolok/dicabut, atau baterai <= 20%.
  Compact: ikon + persen. Expanded: persen, status, estimasi.
- Mac tanpa baterai: modul tak pernah aktif, tanpa crash.
- Commit: `S15: battery module`.

### S16 — Prioritas, live activity, transisi
- Baterai priority lebih tinggi tapi sementara; selesai -> balik ke Now Playing.
  Tak ada modul aktif -> island polos seukuran notch.
- Perpindahan modul: crossfade halus.
- Commit: `S16: module priority and transitions`.

### S17 — Polish & rilis
- `README.md` jujur: apa ini, screenshot (gua isi), cara build, izin Automation, dan
  bagian "Private API" yang terus terang (MediaRemote via adapter bisa pecah di update
  macOS; ada cadangan AppleScript). Tulis juga ini proyek independen yang terinspirasi
  Alcove dan tidak berafiliasi. Tidak butuh sudo (kalau memang tidak).
- `LICENSE` (MIT; nama & tahun gua isi), `NOTICE.md` (atribusi dependency), `.gitignore` final.
- Cek: `git grep -n "/Users/"` tidak nemu path pribadi.
- Commit: `S17: README, LICENSE, NOTICE, gitignore`.

## FASE 2 (placeholder, JANGAN dikerjain dulu)
Kalender (EventKit), AirPods/Bluetooth, HUD volume/kecerahan (butuh izin tambahan),
gestur swipe, file tray, notifikasi, Lock Screen (hampir pasti API privat).
Gua bilang kapan dimulai; detail step ditulis di PLAN versi berikutnya.

## RISIKO (jangan disembunyikan)
- MediaRemote = API privat, bisa pecah kapan saja; belum terbukti di macOS 27.0.1.
- Nempel notch + level di atas menu bar bisa rewel di fullscreen/Spaces/multi-monitor.
- Izin Automation hanya muncul kalau jalan sebagai bundle dengan Info.plist benar.
- Build hijau != jalan benar. Tunggu tes manual gua sebelum "next".
- Nama app "Archipelago" menghindari istilah "Dynamic Island" milik Apple; target
  SwiftPM masih bernama DynamicIsland sampai step rename (kalau gua minta).
