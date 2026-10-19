# PLAN.md — DynamicIsland (macOS, floating pill)

Dokumen ini adalah satu-satunya sumber kebenaran buat Hermes. Baca SELURUHNYA
(read_file penuh) di awal setiap sesi dan sebelum mulai tiap step.

## 0. Tujuan

App macOS (khusus Mac) berupa pill hitam mengambang di tengah atas layar.
BUKAN nempel notch, jadi jalan di semua Mac.

- Collapsed: pill kecil ~120x32.
- Hover: morph jadi expanded (cover, judul, artis, progress, kontrol).
- Modular lewat protokol `IslandModule`.
- MVP: modul Now Playing + modul Baterai/Charging.
- Nanti (di luar MVP): Kalender (EventKit), Timer, sisa durasi Sleepless, dll.
- Pengganti NotchBox (yang ada iklannya). Tanpa iklan, tanpa telemetry.

Gaya UI: minimalis, hitam polos, font sistem, animasi spring halus.
DILARANG: gradient norak, glow, blur berlebih, emoji di UI, dekorasi tanpa fungsi.

---

## RULE 0 — REPO LOCK (paling tinggi, mengalahkan semua aturan lain)

1. Satu-satunya direktori kerja: `~/Archipelago`
   (kalau path ini beda dari yang asli di Mac gua, gua edit baris ini sendiri
   sebelum Hermes mulai).
2. Sebelum SETIAP step, jalanin dan tampilkan hasilnya:
   ```
   pwd
   git rev-parse --show-toplevel
   git branch --show-current
   ```
   Kalau `pwd` / toplevel BUKAN repo di atas, STOP. Jangan edit apa pun.
3. Dilarang baca/tulis/hapus file di luar repo, KECUALI:
   - `/tmp/dynamicisland-research/` untuk clone referensi read-only (lihat S9).
   - Baca-saja ke `~/SwiftProject/SleeplessClone` kalau perlu contoh pola
     (HUD NSPanel, hotkey). Jangan modif, jangan copy mentah tanpa gua minta.
4. Kerja di branch `main` kecuali gua bilang lain. Jangan bikin branch/tag sendiri.

---

## SAFETY RULES (DILARANG KERAS)

1. DILARANG menjalankan app. Termasuk: `swift run`, `open *.app`,
   `./.build/debug/DynamicIsland`, `./.build/release/...`, `osascript` yang
   nargetin Music/Spotify, atau script apa pun yang mengeksekusi binary hasil build.
   Yang boleh: `swift build`, `swift package resolve`, `./build_app.sh`
   (cuma ngebungkus, tidak menjalankan). Gua yang tes manual.
2. DILARANG `sudo`, `pmset`, `defaults write`, `tccutil`, `launchctl`,
   `brew install`, `pip install`, `npm install`, atau ubah setting sistem.
3. DILARANG `git push`, `git push --force`, `git reset --hard`, `git clean -fd`,
   `git rebase`, `git commit --amend`, hapus branch. Cuma `add` dan `commit`.
4. DILARANG hapus file yang bukan lu bikin di step ini.
5. DILARANG pakai: `#Preview`, `@Observable`, `@main` di executable yang
   punya `main.swift`, `import Observation`. Pakai `ObservableObject` + `@Published`.
   (Plugin SwiftUIMacros error di setup gua: cuma Command Line Tools.)
6. DILARANG nambah dependency pihak ketiga selain yang tertulis di plan ini
   (cuma mediaremote-adapter di S9, dan itu pun setelah cek lisensi).
7. DILARANG nambah fitur di luar step yang lagi jalan. Ada ide bagus?
   Tulis di bagian "Catatan untuk Gua" di laporan, jangan dikerjain.
8. DILARANG klaim "works / jalan / done" untuk perilaku runtime. Lu cuma boleh
   bilang "build hijau". Perilaku runtime = urusan tes manual gua.

---

## ATURAN KERJA PER SUB-TASK (wajib)

**A. Satu file per tool call.** Bikin/edit satu file, lalu verifikasi, baru file berikutnya.

**B. Ukuran file.** Target <= 120 baris per file Swift. Kalau bakal lebih,
pecah jadi beberapa file dan bikin satu-satu. Jangan nulis file besar sekaligus.

**C. Edit file existing.** Verifier nolak edit kalau belum `read_file` penuh.
Jadi: `read_file` penuh dulu -> baru edit. Kalau file berubah, baca ulang.

**D. Build.** Setelah tiap file/step: `swift build 2>&1 | tail -25`.
Gagal? Perbaiki maksimal 2 kali. Gagal ke-3: STOP, laporkan error apa adanya.
Jangan rewrite besar-besaran buat "nyelamatin" build.

**E. Satu commit per sub-task.** Format: `S<n>: <ringkasan singkat>`.
Jangan gabung dua step. Jangan commit kalau build merah.

**F. BUKTI (wajib, tempel output mentah, jangan diringkas):**
```
BUKTI S<n>
1) swift build 2>&1 | tail -15
2) git log --oneline -3
3) git status --short          <- harus kosong setelah commit
4) wc -l <file yang dibuat/diubah>
```
Tanpa 4 bukti ini, step dianggap BELUM SELESAI.

**G. Format laporan akhir step:**
```
S<n> SELESAI (build hijau, belum diuji manual)
File dibuat/diubah: ...
Cara gua tes manual: <langkah konkret, 3-6 baris>
Catatan untuk Gua: <risiko / ide / hal yang gak yakin>
Menunggu "next".
```

**H. STOP.** Setelah laporan, BERHENTI. Jangan mulai step berikutnya sampai gua
ketik "next". Kalau gua ketik "fix: ...", kerjain perbaikan itu aja di step yang sama
dengan commit baru `S<n>-fix: ...`.

**I. Kalau ragu / spesifikasi kurang jelas:** STOP dan tanya satu pertanyaan.
Jangan nebak API Apple. Kalau gak yakin sebuah API ada/tidak, tulis di laporan
dan pakai pendekatan paling konservatif.

---

## KONSTRAIN TEKNIS

- Build: SwiftPM saja (Command Line Tools, kemungkinan tanpa Xcode penuh).
- Target executable pakai `main.swift` (TANPA `@main`).
- `Package.swift`: `swift-tools-version:5.9`, platform `.macOS(.v13)` sebagai
  default (nanti diselaraskan dengan versi macOS gua; lihat S0).
- Activation policy `.accessory` (tanpa Dock icon). Di .app bundle: `LSUIElement = true`.
- State: `ObservableObject` + `@Published`. Concurrency: `@MainActor` untuk UI.
- Semua konstanta ukuran/margin/durasi animasi di SATU file `IslandMetrics.swift`.

### Struktur target (Hermes bikin bertahap, bukan sekaligus)
```
Package.swift
Sources/DynamicIsland/
  main.swift
  AppDelegate.swift
  Window/IslandPanel.swift
  Window/IslandWindowController.swift
  Window/IslandMetrics.swift
  Window/HoverTrackingView.swift
  State/IslandState.swift
  Modules/IslandModule.swift
  Modules/ModuleRegistry.swift
  Modules/NowPlaying/NowPlayingInfo.swift
  Modules/NowPlaying/NowPlayingProvider.swift
  Modules/NowPlaying/MockNowPlayingProvider.swift
  Modules/NowPlaying/AdapterNowPlayingProvider.swift
  Modules/NowPlaying/AppleScriptNowPlayingProvider.swift
  Modules/NowPlaying/NowPlayingModule.swift
  Modules/NowPlaying/NowPlayingViews.swift
  Modules/Battery/BatteryModule.swift
  Views/IslandRootView.swift
  Views/PlaybackBars.swift
build_app.sh
Resources/Info.plist
README.md  LICENSE  .gitignore  NOTICE.md
```

---

## URUTAN STEP

### S0 — Scaffold repo
- `git init` (kalau belum), `.gitignore` minimal (`.build/`, `*.app`, `.DS_Store`, `.swiftpm/`, `xcuserdata/`).
- `Package.swift` + `Sources/DynamicIsland/main.swift` isi minimal:
  jalanin `NSApplication.shared`, set delegate, `setActivationPolicy(.accessory)`, `run()`.
- `AppDelegate.swift` kosong tapi valid.
- Jalanin `sw_vers` dan `swift --version`, tempel di laporan (cuma baca, buat nyesuain deployment target).
- Commit: `S0: scaffold SwiftPM`.

### S1 — Panel (kosong)
- `IslandPanel: NSPanel` — `styleMask: [.borderless, .nonactivatingPanel]`,
  `level = .statusBar`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`,
  `isOpaque = false`, `backgroundColor = .clear`, `hasShadow = false` (shadow dipikir di polish),
  `canBecomeKey/Main = false`, `isMovable = false`, `hidesOnDeactivate = false`.
- `IslandMetrics.swift`: collapsed 120x32, expanded awal 340x120 (nanti disesuaikan),
  `topMargin = 6`.
- Panel ukurannya PAS collapsed size. Jangan bikin panel besar transparan.
- `IslandWindowController` posisi: tengah horizontal layar utama, di bawah menu bar
  (`screen.visibleFrame.maxY - height - topMargin`). Pakai `NSScreen.main`.
- Belum ada konten SwiftUI.
- Commit: `S1: borderless non-activating panel`.

### S2 — Pill statis (SwiftUI)
- `IslandRootView`: `Capsule()` hitam, tanpa teks.
- Pasang lewat `NSHostingController`. Set `sizingOptions = []` supaya hosting
  TIDAK mengubah ukuran panel sendiri (kalau gak compile di versi gua, laporkan).
- Background hosting view harus clear, supaya sudut capsule beneran transparan.
- Commit: `S2: static pill`.

### S3 — Posisi, multi-layar, quit, bundle
- Observe `NSApplication.didChangeScreenParametersNotification` -> reposisi.
- Pill ikut layar yang berisi kursor? TIDAK (MVP). Tetap di layar utama.
- `NSStatusItem` minimal: satu menu item "Quit DynamicIsland" (supaya gua bisa
  nutup app tanpa Dock). Ikon: SF Symbol sederhana.
- `Resources/Info.plist` (LSUIElement true, `NSAppleEventsUsageDescription`
  berisi alasan jujur) dan `build_app.sh` yang: `swift build -c release`, bikin
  `DynamicIsland.app/Contents/{MacOS,Resources}`, copy binary + Info.plist,
  `codesign --force --sign - DynamicIsland.app` (ad-hoc). Script TIDAK menjalankan app.
- Alasan bundle sekarang: izin Automation (AppleScript) dan framework adapter
  butuh app bundle beneran, bukan binary mentah.
- Commit: `S3: screen change, status item quit, build_app.sh`.

### S4 — Hover + resize panel (tanpa animasi dulu)
- `IslandState: ObservableObject` dengan `@Published var isExpanded: Bool`.
- `HoverTrackingView: NSView` dengan `NSTrackingArea`
  (`[.mouseEnteredAndExited, .activeAlways, .inVisibleRect]`), callback enter/exit.
- Enter: `isExpanded = true` + resize frame panel ke ukuran expanded
  (anchor: tengah atas tetap). Exit: balik ke collapsed.
- Tambah jeda kecil (debounce ~80 ms) pas exit supaya gak flicker.
- Panel TIDAK boleh lebih besar dari area yang kelihatan saat collapsed.
- Commit: `S4: hover tracking and panel resize`.

### S5 — Morph animasi spring
- Animasi capsule -> rounded rect (corner radius dari 16 ke ~22) dengan
  `spring(response: ~0.35, dampingFraction: ~0.8)`.
- Sinkronkan resize frame panel dan animasi SwiftUI (resize panel dulu saat
  expand, resize panel SETELAH animasi selesai saat collapse) supaya konten
  tidak kepotong.
- Semua angka animasi di `IslandMetrics`.
- Commit: `S5: spring morph`.

### S6 — Protokol modul
```swift
protocol IslandModule: AnyObject {
    var id: String { get }
    var priority: Int { get }
    var isActive: Bool { get }          // lagi punya sesuatu untuk ditampilkan
    func compactView() -> AnyView       // isi pill collapsed
    func expandedView() -> AnyView      // isi saat expanded
}
```
(Boleh disesuaikan kalau ada masalah compile, tapi laporkan perubahannya.)
- `ModuleRegistry: ObservableObject`: daftar modul, `currentModule` = modul
  aktif dengan priority tertinggi.
- Satu modul placeholder (teks statis) buat verifikasi alur. Dihapus di S8.
- Commit: `S6: IslandModule protocol and registry`.

### S7 — Model Now Playing + provider tiruan
- `NowPlayingInfo` (title, artist, album, artwork `NSImage?`, duration,
  elapsed, isPlaying, bundleID).
- `protocol NowPlayingProvider { var info: NowPlayingInfo? {get}; var onChange: ...; start(); stop(); play/pause/next/prev/seek }`.
- `MockNowPlayingProvider` dengan data palsu supaya UI bisa dikerjain tanpa API privat.
- Commit: `S7: now playing model and mock provider`.

### S8 — UI Now Playing (pakai mock)
- Collapsed: bar animasi kecil (fake visualizer, lihat S13) di sisi kanan + artwork mini di kiri, atau kosong kalau tidak ada musik.
- Expanded: cover, judul, artis, progress bar, tombol prev / play-pause / next.
- Progress bar jalan dari `elapsed` + timer lokal; koreksi saat info baru masuk.
- Font sistem. Tombol pakai SF Symbols. Hitam polos.
- Hapus modul placeholder S6.
- Commit: `S8: now playing UI with mock`.

### S9 — Adapter mediaremote (research dulu, baru integrasi)
**S9a (read-only, satu commit sendiri kalau ada catatan):**
- Clone referensi ke `/tmp/dynamicisland-research/`:
  `github.com/ungive/mediaremote-adapter` dan fork Swift package-nya
  (`github.com/ejbills/mediaremote-adapter`), plus `github.com/spitfiresb/notch`
  sebagai bacaan arsitektur.
- Kalau network diblok, STOP dan minta gua clone manual.
- BACA `LICENSE` tiap repo dan laporkan jenis lisensinya. Jangan lanjut
  integrasi sebelum gua setuju. Dilarang copy-paste kode mentah dari repo lain
  ke repo kita. Kalau pakai sebagai dependency/vendor, wajib atribusi di `NOTICE.md`.
- Laporkan: cara kerjanya (adapter spawn `/usr/bin/perl` yang load framework
  helper supaya lolos pembatasan MediaRemote sejak macOS 15.4), format output
  streaming, dan cara dia dibundel ke .app.
- Tulis ringkasan kondisi terkini di macOS versi gua. Klaim "jalan di macOS 26"
  harus dilabeli "laporan komunitas, belum diverifikasi di mesin gua".

**S9b (setelah gua bilang "next" + setuju lisensi):**
- Tambah dependency lewat SwiftPM ATAU vendor framework di `Vendor/` (sesuai
  hasil S9a dan keputusan gua).
- `AdapterNowPlayingProvider` implement `NowPlayingProvider`: stream update,
  parse ke `NowPlayingInfo`, handle proses mati (restart dengan backoff, maksimal N kali).
- `build_app.sh` disesuaikan buat menyalin framework/script ke bundle.
- Commit terpisah: `S9a: research notes` (kalau ada file catatan) dan `S9b: adapter provider`.

### S10 — Kontrol playback lewat adapter
- play/pause, next, previous, seek disambungkan dari tombol UI ke provider.
- Seek optimistik di UI, koreksi saat update masuk.
- Commit: `S10: playback controls via adapter`.

### S11 — Fallback AppleScript (Music & Spotify)
- `AppleScriptNowPlayingProvider`: baca state via `NSAppleScript` / Apple Events
  ke `com.apple.Music` dan `com.spotify.client`.
- WAJIB cek dulu `NSWorkspace.shared.runningApplications` sebelum kirim script.
  `tell application "Music"` bisa MELUNCURKAN app yang lagi mati. Dilarang.
- Polling ~1 detik hanya kalau ada player yang running dan isPlaying atau baru
  berubah; selain itu poll jarang / berhenti. Hemat CPU.
- Artwork: Music via data artwork script, Spotify via URL artwork. Kalau gagal, tanpa cover.
- Handle penolakan izin Automation dengan tenang (state "tidak ada izin"), jangan crash/loop.
- Commit: `S11: AppleScript fallback provider`.

### S12 — Pemilihan provider utama/cadangan
- `NowPlayingModule`: pakai Adapter sebagai utama. Pindah ke AppleScript kalau
  adapter gagal start / diam error berulang. Balik ke adapter kalau pulih.
- Satu sumber kebenaran `info` ke UI. Jangan dua provider nulis bareng.
- Log ringkas (os.Logger) provider mana yang aktif. Tanpa log sensitif.
- Commit: `S12: provider selection and fallback`.

### S13 — Visualizer palsu
- `PlaybackBars`: 3-4 bar, tinggi animasi acak halus, hanya animasi saat `isPlaying`,
  diam kalau pause. Pakai `TimelineView` atau animasi SwiftUI ringan.
- Bukan audio sungguhan (ditunda: butuh `AudioHardwareCreateProcessTap` + izin).
- Commit: `S13: fake visualizer bars`.

### S14 — Modul kedua: Baterai/Charging
- `BatteryModule` pakai IOKit Power Sources (`IOPSNotificationCreateRunLoopSource`).
- Aktif sementara (~3 detik) saat charger dicolok/dicabut atau baterai <= 20%;
  compact: ikon + persen, expanded: persen + status + estimasi (kalau ada).
- Desktop Mac tanpa baterai: modul tidak pernah aktif, tanpa crash.
- Commit: `S14: battery module`.

### S15 — Prioritas & perpindahan modul
- Now Playing priority normal; Baterai priority lebih tinggi tapi sementara.
- Saat baterai selesai, balik ke Now Playing. Kalau tidak ada modul aktif, pill polos.
- Perpindahan: crossfade halus, tanpa geser berlebihan.
- Commit: `S15: module priority and transitions`.

### S16 — Polish & rilis GitHub
- `README.md` jujur dan ringkas: apa ini, screenshot (gua yang isi), cara build,
  izin yang diminta (Automation), dan bagian "Private API" yang terus terang:
  Now Playing memakai MediaRemote lewat mediaremote-adapter, API privat yang bisa
  pecah di update macOS, plus fallback AppleScript. Kalau ada `sudoers` atau
  hal serupa, jelaskan; kalau tidak ada, tulis "tidak butuh sudo".
- `LICENSE` (MIT, tahun & nama gua yang isi), `NOTICE.md` (atribusi dependency),
  `.gitignore` final, `build_app.sh` final.
- Cek: tidak ada path absolut pribadi / token / log tertinggal di repo
  (`git grep -n "/Users/"`).
- Commit: `S16: README, LICENSE, NOTICE, gitignore`.

---

## DAFTAR RISIKO (jangan disembunyikan)
- MediaRemote adalah API privat. Bisa pecah kapan saja karena update macOS.
- Hover di panel non-activating kadang rewel di Spaces/fullscreen. Tes manual gua yang nentuin.
- Izin Automation hanya muncul kalau app jalan sebagai bundle dengan Info.plist yang benar.
- Build hijau != jalan benar. Selalu tunggu hasil tes manual gua sebelum "next".
- Nama "Dynamic Island" adalah istilah Apple; sebelum publik di GitHub, pertimbangkan nama proyek sendiri.
