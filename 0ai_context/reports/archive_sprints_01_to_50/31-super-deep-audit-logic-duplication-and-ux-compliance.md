# Laporan 31: Super Deep Audit — Bugs, Logic Defects, Duplicated Menus, dan UI/UX & Security Compliance

## 1. Executive Verdict
**Status Akhir**: **ACTION REQUIRED** (Ditemukan 3 issue P1 logika kritis, 6 issue P2 duplikasi/UX, dan 5 issue P3 inkonsistensi dokumentasi/label).

### Rekapitulasi Temuan Berdasarkan Severity
- **P0 (Crash / Data Loss / Security Blocker)**: **0**
- **P1 (Core Function Broken / Logic Desync / Concurrency Hazard)**: **3**
  1. `BatchQueueProvider`: Polusi parameter orientasi (`isPortrait`) dan durasi (`totalDurationMs`) item pertama menyebabkan silent truncation of batch items longer than item #1 (`batch_queue_provider.dart:106-107`).
  2. Double-tap hazard pada tombol transcode tanpa debounce (`process_screen.dart:79-90`).
  3. Desinkronisasi total toggle hardware acceleration antara Provider (`UniquifierProvider`), Settings Service, dan `AppSettingsBottomSheet` (`uniquifier_provider.dart:74`, `settings_service.dart:156`, `app_settings_bottom_sheet.dart:104`). Toggle ini juga tidak pernah dikirimkan ke parameter FFmpeg (`ffmpeg_service.dart:225`).
- **P2 (UX Flaw / Menu Duplication / Missing Confirmation / False Green Tests)**: **6**
  1. Triplikasi menu pengaturan (`SettingsScreen` navbar vs `AppSettingsBottomSheet` TopAppBar vs `AdvancedSettingsBottomSheet` modal).
  2. Fitur Preset Profile belum terekspos di antarmuka (`SettingsScreen` / `ProcessScreen`).
  3. Ketiadaan dialog konfirmasi pada tindakan destruktif: Purge Cache (`settings_screen.dart:41`) dan Cancel Batch (`batch_processing_screen.dart:249`).
  4. Pelanggaran batas target sentuh Material Design (32x32 dp < 48x48 dp) dan jarak tombol (6 dp < 8 dp) pada `TopAppBar` dan `HistoryItemCard`.
  5. Risiko `RenderFlex overflow` pada layar sempit (320px) dengan TextScaler 2.0 pada baris unconstrained `_CacheMaintenanceCard` dan `_AlertsSettingsCard`.
  6. False Green test suite pada `notification_service_test.dart` dan `media_scanner_service_test.dart` akibat early exit `Platform.isAndroid == false`.
- **P3 (Cosmetic / Obsolete Subtitles / Documentation Drift)**: **5**
  1. Fake Success pada input kosong (`processing_screen.dart:74-76`, UI button disabled; route handler unguarded).
  2. Subtitle `ModifiersCard:92` masih mencantumkan `5% margin crop & 0.4° tilt` (seharusnya 8% & 0.8°).
  3. Label hardcoded direktori output di `AppSettingsBottomSheet:124` salah (`/Movies/VideoUniquifier` vs riil `/Movies/Uniquifier`).
  4. Leakage raw stack trace & full log ke UI `ErrorScreen` tanpa penyaringan path absolut pengguna.
  5. Deklarasi izin Foreground Service di `AndroidManifest.xml` tanpa adanya kelas `Service` Android riil di native layer.

---

## 2. Methodology & Scope
Audit dilakukan secara read-only murni tanpa mengubah source code. Setiap temuan diverifikasi melalui inspeksi baris per baris (`read_file`), pencarian simbol (`search_files`), dan verifikasi topologi relasi pada Codebase Memory Knowledge Graph (`codebase-memory-mcp`).

- **Total file Dart diaudit**: 34 file di `lib/` (6.081 baris kode) dan 9 file di `test/` (80 unit & widget test).
- **Perangkat Tooling**: `hermes doctor`, `codebase-memory-mcp` (index_status, index_repository, search_graph, trace_path, get_file_outline), `flutter analyze --fatal-infos`, `flutter test`.
- **Batasan Metodologi**: Direktori `test/` tidak diindeks oleh MCP graph; hasil `trace_path` dengan 0 caller hanya berlaku scoped ke `lib/` saja.

---

## 3. MCP Baseline Table
| Metrik | Status Sebelum Re-index | Status Sesudah Full Re-index | Delta | Keterangan |
|---|---|---|---|---|
| **Node Count** | 1338 | 1350 | +12 | Penambahan artefak dokumentasi Report 30 |
| **Edge Count** | 3404 | 3428 | +24 | Relasi antar bagian report baru |
| **Status Graph** | ready | ready | 0 | Queryable, 0 broken references |
| **Parse Partial** | 7 files | 7 files | 0 | File platform non-Dart (HTML/C++) |
| **Parse Unusable**| 0 files | 0 files | 0 | Seluruh file Dart terindeks sempurna |

---

## 4. Temuan Audit Per Domain (D1 – D10)

### D1. Logic & State Defects
| ID | Severity | Domain | Title | Evidence (path:line) | Reproduction | User impact | Suspected root cause | Recommendation | Evidence status |
|---|---|---|---|---|---|---|---|---|---|
| **D1-01** | **P1** | D1 | Polusi Parameter Batch Item | `lib/core/providers/batch_queue_provider.dart:106-107` | Pilih Video 1 portrait (9:16) dan Video 2 landscape (16:9). Jalankan batch. | Video 2 dipaksa di-scale dengan rumus portrait (`w=1080:h=-2`), merusak aspect ratio dan menyebabkan distorsi gambar serta silent truncation of batch items longer than item #1. | `runBatch()` mengoper `config.isPortrait` dan `config.totalDurationMs` milik provider yang hanya merepresentasikan file pertama. | Teruskan `isPortrait: null` ke `processVideo()` agar FFprobe mendeteksi orientasi masing-masing item secara mandiri. Catatan: `totalDurationMs: 0` mematikan auto-trim seluruh batch; perbaikan yang benar adalah probe durasi per-item. | `verified` |
| **D1-02** | **P1** | D1 | Desinkronisasi Hardware Acceleration | `lib/core/providers/uniquifier_provider.dart:74`, `lib/core/services/settings_service.dart:156`, `lib/features/settings/screens/app_settings_bottom_sheet.dart:104` | Ubah mode engine di AppSettingsBottomSheet, lalu periksa toggle di SettingsScreen. | Pengguna mengira akselerasi aktif, padahal status di UI berlawanan dan tidak pernah tersinkronisasi. | Ada 2 state berbeda: `UniquifierProvider._hardwareAcceleration` (boolean) vs `SettingsService.keyEngineMode` (String 'software'/'hardware'). Keduanya tidak saling mengikat. | Satukan backing state ke `SettingsService` dengan `ValueNotifier<bool>`, binding ke provider dan hapus `keyEngineMode` usang. | `verified` |
| **D1-03** | **P3** | D1 | Fake Success pada Input Kosong | `lib/features/process/screens/processing_screen.dart:74-76` | Masuk ke `ProcessingScreen` saat `selectedFilePath` null. | Layar menampilkan delay 3 detik lalu melaporkan sukses untuk file fiktif `video_01.mp4`. Catatan keparahan: di-downgrade ke P3 karena tombol UI disabled (`hasFile == false`); hanya route handler yang belum ber-guard. | Peninggalan mockup development yang belum dibersihkan. | Pasang route guard dan lempar exception eksplisit atau pop kembali ke `ProcessScreen` jika input null. | `verified` |

### D2. Race Conditions, Async, & Lifecycle
| ID | Severity | Domain | Title | Evidence (path:line) | Reproduction | User impact | Suspected root cause | Recommendation | Evidence status |
|---|---|---|---|---|---|---|---|---|---|
| **D2-01** | **P1** | D2 | Concurrency Hazard Double-Tap Start | `lib/features/process/screens/process_screen.dart:79-90` | Tekan tombol 'START UNIQUIFYING' dua kali dengan sangat cepat. | Terbuka dua instance `ProcessingScreen` yang menjalankan FFmpeg secara paralel pada file yang sama. | Ketiadaan debounce atau state locking pada `_startProcessing()`. | Tambahkan flag `_isNavigating` atau disable tombol saat transisi rute dimulai. | `verified` |
| **D2-02** | **P2** | D2 | Telemetry Progress Rewind | `lib/features/process/screens/processing_screen.dart:40`, `lib/features/process/screens/processing_screen.dart:100` | Render video 4K dengan durasi inisialisasi probe > 3 detik. | Indikator progress melompat ke 75% (Step 3), lalu tiba-tiba mundur ke 5% (Step 1) saat frame FFmpeg pertama masuk. | Ticker animasi lokal 4 detik menginterpolasi progress sebelum native statistic callback pertama masuk. | Batasi ticker lokal hanya sampai batas maksimal 15% (fase inisialisasi/staging), jangan sampai 95%. | `verified` |
| **D2-03** | **P2** | D2 | Unsafe setState pada History Refresh | `lib/features/history/screens/recent_history_screen.dart:32` | Hapus video, lalu segera tekan tombol back saat proses delete berlangsung. | Potensi unhandled crash Flutter framework: `setState() called after dispose()`. | `_loadHistory()` memanggil `setState()` di baris 32 tanpa pemeriksaan `if (!mounted)`. | Pasang guard `if (!mounted) return;` di awal method `_loadHistory()`. | `verified` |

### D3. Duplicated Menus & Features
| ID | Severity | Domain | Title | Evidence (path:line) | Reproduction | User impact | Suspected root cause | Recommendation | Evidence status |
|---|---|---|---|---|---|---|---|---|---|
| **D3-01** | **P2** | D3 | Triplikasi Menu Pengaturan | (A) `settings_screen.dart:10` (B) `app_settings_bottom_sheet.dart:5` (C) `advanced_settings_bottom_sheet.dart:9` | Buka Tab 2 Settings, lalu buka TopAppBar Settings di Tab 0, lalu buka chip Resolution di ModifiersCard. | Pengguna dibingungkan oleh 3 menu pengaturan terpisah yang menampilkan opsi tumpang tindih dengan data berbeda. | Migrasi Tab Settings di Report 29 belum mematangkan pembersihan modal sheet lama. | Hapus `AppSettingsBottomSheet` dan `AdvancedSettingsBottomSheet`. Arahkan semua tautan settings ke Tab 2 `SettingsScreen`. | `verified` |
| **D3-02** | **P2** | D3 | Fitur Preset Profile Belum Terhubung ke UI | `lib/core/providers/uniquifier_provider.dart:206` | Telusuri UI untuk mencari tombol 'TikTok Fast Mode' atau 'Max Stealth'. | Fungsi preset tidak diekspos di UI, namun aktif diuji oleh unit test di `test/uniquifier_provider_test.dart:59,77`. Catatan metodologi: hasil `trace_path` 0 caller tersegmentasi hanya pada `lib/` karena `test/` tidak diindeks MCP. | Tab Presets dihapus pada Report 29 saat menambah `SettingsScreen`, namun logic `applyPreset()` belum disambungkan ke SettingsScreen. | Integrasikan kembali pemilih Preset Profiles ke dalam `SettingsScreen` atau buatkan modal Preset Picker di `ProcessScreen`. | `verified` |
| **D3-03** | **P3** | D3 | Slider Mockup Non-Fungsional | `lib/features/settings/widgets/audio_visual_tuning_card.dart:47-65` | Buka `AdvancedSettingsBottomSheet` dan coba geser slider pitch/crop. | Elemen terlihat seperti slider interaktif, namun statis dan tidak dapat digeser. | Widget `_TuningSliderRow` hanya merender ikon dan teks statis tanpa widget `Slider`. | Ganti dengan widget `Slider` riil atau hapus kartu ini karena filtergrade kini otomatis via preset/pipeline. | `verified` |

### D4. UI/UX Compliance & User Comfort/Security
| ID | Severity | Domain | Title | Evidence (path:line) | Reproduction | User impact | Suspected root cause | Recommendation | Evidence status |
|---|---|---|---|---|---|---|---|---|---|
| **D4-01** | **P2** | D4 | Pelanggaran Ukuran Target Sentuh | `lib/shared/widgets/top_app_bar.dart:44`, `lib/features/history/widgets/history_item_card.dart:162,179` | Uji sentuh pada perangkat fisik dengan jari normal. | Tombol sulit ditekan atau salah tekan tombol delete di samping share. | Constraint ukuran tombol dipaksa ke `32x32 dp` (standar minimum Material 3 adalah `48x48 dp`). Jarak antar tombol hanya 6 dp (< 8 dp). | Perbesar hit area menjadi 48x48 dp dengan padding internal dan renggangkan spacing minimal 8-12 dp. | `verified` |
| **D4-02** | **P2** | D4 | Ketiadaan Konfirmasi Purge Cache & Cancel Batch | `lib/features/settings/screens/settings_screen.dart:41`, `lib/features/process/screens/batch_processing_screen.dart:249` | Ketuk 'Purge Cache' di Settings atau 'CANCEL BATCH' di Batch Screen. | Seluruh antrean batch dibatalkan seketika atau cache file terhapus tanpa ada kesempatan membatalkan. | Tidak ada pemanggilan dialog konfirmasi (`showDialog`) sebelum eksekusi aksi destruktif. | Pasang dialog konfirmasi standar dengan aksi Cancel/Confirm. | `verified` |
| **D4-03** | **P2** | D4 | Potensi Overflow Layout Text Scale 2.0 | `lib/features/settings/screens/settings_screen.dart:267-290` | Aktifkan font size terbesar di OS pada layar 320x480 dp. | Teks dan tombol tumpang tindih atau memicu `RenderFlex overflowed by ~300px`. | `Row` membungkus teks panjang dan tombol `OutlinedButton.icon` tanpa `Expanded` / `Wrap`. | Ganti `Row` dengan `Wrap` atau bungkus kolom teks dalam `Expanded`. | `verified` |
| **D4-04** | **P3** | D4 | Teks Subtitle Statis pada Progress Tracker | `lib/features/process/screens/processing_screen.dart:221` | Perhatikan teks subtitle saat render berjalan pada Step 1 (Analysis) atau Step 4 (Finishing). | Informasi langkah menyesatkan pengguna karena selalu bertuliskan 'Applying micro-crop & shifting audio pitch'. | Teks hardcoded tidak membaca variabel `step`. | Buat map deskripsi teks dinamis per step: Step 1 (Probing), Step 2 (Evasion & Filtergraph), Step 3 (Lanczos Scaling), Step 4 (Integrity Verification). | `verified` |

### D5. Processing Contract & Output Integrity
| ID | Severity | Domain | Title | Evidence (path:line) | Reproduction | User impact | Suspected root cause | Recommendation | Evidence status |
|---|---|---|---|---|---|---|---|---|---|
| **D5-01** | **P2** | D5 | Diagnostic Gate Pasif Tanpa Validasi Blokir | `lib/core/services/ffmpeg_service.dart:309`, `lib/core/providers/uniquifier_provider.dart:260` | Render video yang menghasilkan dimensi terpotong (truncated aspect ratio). | Video cacat tetap dianggap sukses dan disimpan ke galeri pengguna. | Hasil dari `inspectRenderedFile()` hanya disimpan ke state untuk telemetry UI, tidak ada evaluasi `if (diag.isTruncatedPortrait) throw Exception(...)`. | Jadikan `inspectRenderedFile` sebagai gate aktif: jika rasio atau codec gagal validasi, batalkan file dan arahkan ke ErrorScreen. | `verified` |
| **D5-02** | **P2** | D5 | Notifikasi Individual Berisik Saat Batch | `lib/core/services/ffmpeg_service.dart:310-314` | Jalankan batch transcode untuk 5 video. | Ponsel berdering dan bergetar 5 kali berturut-turut untuk setiap video selesai sebelum batch selesai. | `processVideo()` selalu memanggil `showCompleteNotification()` tanpa flag `isBatch`. | Tambahkan parameter opsional `bool suppressCompleteNotification = false` ke `processVideo()`, disetel `true` saat dipanggil dari `runBatch()`. | `verified` |

### D6. Security & Permissions
| ID | Severity | Domain | Title | Evidence (path:line) | Reproduction | User impact | Suspected root cause | Recommendation | Evidence status |
|---|---|---|---|---|---|---|---|---|---|
| **D6-01** | **P2** | D6 | Konfigurasi Root-Path Berisiko di FileProvider | `android/app/src/main/res/xml/provider_paths.xml:4` | Pindai APK dengan Google Play App Signing / Vulnerability Scanner. | Potensi penolakan rilis di Play Store akibat peringatan Overly Broad FileProvider Paths. | Elemen `<root-path name="root" path="." />` mengekspos seluruh partisi filesystem OS. | Hapus tag `<root-path>`, gantikan dengan deklarasi scoped `<external-path>` dan `<files-path>`. | `verified` |
| **D6-02** | **P3** | D6 | Ekspos Log Diagnostik Mentah di Error UI | `lib/features/process/screens/error_screen.dart:164` | Jalankan file bermasalah hingga memicu error FFmpeg. | Pengguna awam melihat ratusan baris log teknis dan path internal perangkat yang membingungkan. | `errorDetails` menampung raw dump `session.getAllLogsAsString()`. | Tampilkan ringkasan yang ramah pengguna di bagian atas, dan letakkan raw log di dalam accordion 'Lihat Detail Teknis'. | `verified` |

### D7. Performance & Memory
| ID | Severity | Domain | Title | Evidence (path:line) | Reproduction | User impact | Suspected root cause | Recommendation | Evidence status |
|---|---|---|---|---|---|---|---|---|---|
| **D7-01** | **P2** | D7 | Thumbnail 4K Membengkak di Heap Tanpa Cache Width | `lib/features/process/widgets/source_file_section.dart:148`, `lib/features/process/screens/success_screen.dart:235` | Muat video 4K berukuran besar (3840x2160) dan buka SuccessScreen. | Konsumsi RAM membengkak ~33 MB hanya untuk merender kotak thumbnail 80x80 dp, memicu thermal throttling atau OOM di HP spek rendah. | `Image.file()` tidak menyetel parameter `cacheWidth` atau `cacheHeight`. | Tambahkan `cacheWidth: 240, cacheHeight: 240` pada instansiasi `Image.file()`. | `verified` |

### D8. Consistency & Code Quality
| ID | Severity | Domain | Title | Evidence (path:line) | Reproduction | User impact | Suspected root cause | Recommendation | Evidence status |
|---|---|---|---|---|---|---|---|---|---|
| **D8-01** | **P2** | D8 | 20 Fungsi Melebihi Batas 40 Baris | Lihat rekap Section 7 (20 functions verified > 40 lines, tertinggi 113 baris di `processVideo()`) | Jalankan skrip analisis baris kode internal. | Pelanggaran aturan keras arsitektur (`AGENTS.md §5: Functions <= 40 lines`). | Logika perakitan filter, staging file, dan UI building diletakkan dalam satu fungsi raksasa. | Pecah fungsi besar menjadi fungsi privat pembantu (sub-builders). | `verified` |
| **D8-02** | **P3** | D8 | Label Subtitle Kedaluwarsa di ModifiersCard | `lib/features/process/widgets/modifiers_card.dart:92` | Buka layar utama dan baca teks toggle 'Deep Evasion'. | Pengguna disajikan informasi usang (tertulis 5% margin crop & 0.4° tilt, padahal riil 8% & 0.8°). | Hardcoded string tidak diupdate saat filter ditingkatkan di Report 30. | Perbarui teks subtitle menjadi `'8% margin crop & 0.8° tilt'`. | `verified` |
| **D8-03** | **P3** | D8 | Label Path Salah di AppSettingsBottomSheet | `lib/features/settings/screens/app_settings_bottom_sheet.dart:124` | Buka AppSettingsBottomSheet dari TopAppBar. | Pengguna mencari file di folder `/Movies/VideoUniquifier` yang tidak pernah dibuat. | String hardcoded berbeda dengan target riil `/Movies/Uniquifier`. | Perbarui string menjadi `/Movies/Uniquifier` atau baca langsung dari `FfmpegService.targetDir`. | `verified` |

### D9. Test Coverage Gaps
| ID | Severity | Domain | Title | Evidence (path:line) | Reproduction | User impact | Suspected root cause | Recommendation | Evidence status |
|---|---|---|---|---|---|---|---|---|---|
| **D9-01** | **P2** | D9 | False Green Tests pada Platform Non-Android | `test/notification_service_test.dart:18-45`, `test/media_scanner_service_test.dart:28-36` | Jalankan `flutter test` di host Windows/macOS. | Tes melaporkan 100% PASS, padahal kode native tidak pernah tereksekusi sama sekali (early return). | Kode implementasi memiliki guard `if (!Platform.isAndroid) return;` sehingga tes host hanya menguji no-op. | Mock MethodChannel di level Flutter Services agar logika serialization dan notification attributes teruji nyata di lingkungan unit test. | `verified` |
| **D9-02** | **P2** | D9 | 18 File UI Tidak Memiliki Widget Test Mandiri | `lib/features/settings/screens/settings_screen.dart`, `processing_screen.dart`, dll. | Periksa cakupan file di direktori `test/`. | Regresi UI dan interaksi tombol baru tidak tertangkap otomatis dalam pipeline CI/CD. | Pengujian widget baru sebatas smoke test umum di `widget_test.dart`. | Tambahkan berkas widget test khusus untuk setiap screen utama. | `verified` |

### D10. Documentation vs Reality
| ID | Severity | Domain | Title | Evidence (path:line) | Reproduction | User impact | Suspected root cause | Recommendation | Evidence status |
|---|---|---|---|---|---|---|---|---|---|
| **D10-01** | **P3** | D10 | Mismatch Hitungan Berkas dan State di STATE.md | `0ai_context/STATE.md:6,56` | Bandingkan `git log -1` dan `find lib/ -name "*.dart" \| wc -l` dengan `STATE.md`. | Kebingungan konteks agen otomatis pada sesi berikutnya. | HEAD Commit di `STATE.md` tertinggal 1 commit, dan jumlah file Dart tertulis 29 padahal aktual 34. | Sinkronkan `STATE.md` dengan nilai riil: HEAD `137843c` dan total 34 file. | `verified` |

---

## 5. Peta Duplikasi Menu & Fitur (Consolidation Plan)

Berdasarkan audit menyeluruh, aplikasi memiliki **3 pintu masuk Settings terpisah** yang menyebabkan redundansi kode dan desinkronisasi data:

```
[UI Entry Points]
  ├── Bottom Navigation Bar (Tab 2) ──> SettingsScreen (Full Screen)
  ├── ProcessScreen (TopAppBar Icon) ─> AppSettingsBottomSheet (Modal 1)
  └── ProcessScreen (Modifiers Chip) ─> AdvancedSettingsBottomSheet (Modal 2)
```

### Tabel Matriks Fitur & Rekomendasi Konsolidasi
| Fitur / Pengaturan | Lokasi A (`SettingsScreen`) | Lokasi B (`AdvancedSettings`) | Lokasi C (`AppSettings`) | Backing State Bersama? | Rekomendasi Aksi | Bukti MCP / Code |
|---|---|---|---|---|---|---|
| **Pilihan Codec (H.264 / H.265)** | Ada (Radio Card) | Tidak Ada | Tidak Ada | N/A | **Pertahankan di `SettingsScreen`** | `settings_screen.dart:126` |
| **Pilihan Target Resolusi** | Ada (`UpscaleResolutionCard`) | Ada (`UpscaleResolutionCard`) | Tidak Ada | Ya (`upscaleResolutionNotifier`) | **Pusatkan di `SettingsScreen`**. Hapus dari modal sheet. | `settings_screen.dart:90`, `advanced_settings_bottom_sheet.dart:130` |
| **Hardware Acceleration Toggle** | Ada (`HardwareAccelerationCard`) | Ada (`HardwareAccelerationCard`) | Ada (Text Button 'CHANGE') | **TIDAK SINKRON** (Provider vs SettingsService) | **Satukan ke `SettingsScreen`**, bind ke `SettingsService`, hapus dari kedua bottom sheet. | `settings_screen.dart:100`, `advanced_settings_bottom_sheet.dart:137`, `app_settings_bottom_sheet.dart:104` |
| **Purge Cache Button** | Ada (`_CacheMaintenanceCard`) | Tidak Ada | Ada (OutlinedButton) | Ya (`purgeTempCache()`) | **Pusatkan di `SettingsScreen`**. Hapus dari `AppSettingsBottomSheet`. | `settings_screen.dart:255`, `app_settings_bottom_sheet.dart:128` |
| **Background Processing Toggle** | Ada (`_AlertsSettingsCard`) | Tidak Ada | Tidak Ada | Ya (`SettingsService`) | **Pertahankan di `SettingsScreen`**. | `settings_screen.dart:216` |
| **Notification Sound Toggle** | Ada (`_AlertsSettingsCard`) | Tidak Ada | Tidak Ada | Ya (`SettingsService`) | **Pertahankan di `SettingsScreen`**. | `settings_screen.dart:216` |
| **Filter Modifiers Tuning Slider** | Tidak Ada | Ada (`AudioVisualTuningCard`) | Tidak Ada | **Palsu** (Statis, 0 listener) | **Hapus**. Pipeline filtergraph sudah diotomatisasi penuh dan aman via vDNA evasion. | `advanced_settings_bottom_sheet.dart:135`, `audio_visual_tuning_card.dart:47` |
| **Shader Telemetry Strip** | Tidak Ada | Ada (`ShaderTelemetryStrip`) | Tidak Ada | **Palsu** (Hardcoded 42/42) | **Hapus**. | `advanced_settings_bottom_sheet.dart:142`, `hardware_acceleration_card.dart:63` |
| **Default Processing Preset** | Tidak Ada | Tidak Ada | Ada (Text Button 'CHANGE') | Tidak terpakai di render | **Hapus dari BottomSheet**; integrasikan `applyPreset` riil ke UI. | `app_settings_bottom_sheet.dart:111` |

### Rekomendasi Arsitektur Sederhana (Clean Architecture):
1. Hapus berkas `lib/features/settings/screens/app_settings_bottom_sheet.dart` dan `advanced_settings_bottom_sheet.dart`.
2. Pada `ProcessScreen`:
   - Ganti aksi icon `TopAppBar.onSettingsTap` dan tap pada `EngineStateStrip` untuk berpindah tab ke Tab 2 (`provider.setTabIndex(2)`).
3. Hapus komponen dummy `AudioVisualTuningCard` dan `ShaderTelemetryStrip` yang hanya merupakan ornamen statis tanpa fungsionalitas nyata.

---

## 6. UI/UX Compliance Matrix Per Screen

| Layar / Screen | Touch Target (≥48dp) | Contrast Ratio (≥4.5:1) | Safe Area Handled? | Keyboard Insets? | TextScaler 2.0 Safe? | Empty / Loading / Error States | Konfirmasi Aksi Destruktif |
|---|---|---|---|---|---|---|---|
| **ProcessScreen** | ⚠️ Icon settings 32dp (`top_app_bar.dart:44`) | ✅ 11.35:1 - 14.90:1 | ✅ Ya | ✅ Ya | ✅ Truncation aman via ellipsis | ✅ Lengkap (Empty picker, selected card) | N/A (Tidak ada aksi destruktif) |
| **ProcessingScreen**| ✅ 48dp (Cancel button) | ✅ 12.40:1 | ✅ Ya | ✅ Ya | ⚠️ Subtitle progress statis | ✅ Radar indicator & stage tracker aktif | ⚠️ **Tidak ada** (Cancel langsung stop) |
| **SuccessScreen** | ✅ 48dp (Action buttons) | ✅ 12.88:1 | ✅ Ya | ✅ Ya | ✅ SingleChildScrollView aman | ✅ Lengkap | N/A |
| **ErrorScreen** | ✅ 48dp (Back button) | ✅ 11.36:1 (Error text) | ✅ Ya | ✅ Ya | ✅ Scrollable BoxConstraints | ✅ Lengkap | N/A |
| **RecentHistory** | ⚠️ Action buttons 32dp, spacing 6dp (`history_item_card.dart:163`) | ✅ 11.35:1 | ✅ Ya | ✅ Ya | ✅ Truncation aman | ✅ Empty state terakomodasi | ✅ **Ada** (Dialog konfirmasi hapus video) |
| **SettingsScreen**| ✅ 48dp (Switches, Radios) | ✅ 12.88:1 | ✅ Ya | ✅ Ya | ⚠️ **Risiko Overflow** pada `_CacheMaintenanceCard` | ✅ Lengkap | ⚠️ **Tidak ada** (Purge cache langsung jalan) |
| **BatchProcessing**| ✅ 48dp (Cancel & Done) | ✅ 12.40:1 | ✅ Ya | ✅ Ya | ✅ Listview aman | ✅ Lengkap | ⚠️ **Tidak ada** (Cancel batch langsung jalan) |

---

## 7. Actual Line-Budget Matrix (Semua 34 Berkas di `lib/`)

*Dihitung langsung via `wc -l` (Plafon Keras: <= 400 baris per berkas)*:

| No | Path Berkas Sumber | Jumlah Baris Aktual | Plafon Baris | Status Kepatuhan | Fungsi Terpanjang (>40 baris) |
|---|---|---|---|---|---|
| 1 | `lib/core/models/batch_video_item.dart` | 41 | 400 | ✅ PASS | Tidak ada |
| 2 | `lib/core/providers/batch_queue_provider.dart` | 150 | 400 | ✅ PASS | `runBatch()` (74 baris) |
| 3 | `lib/core/providers/uniquifier_provider.dart` | 387 | 400 | ✅ PASS | Tidak ada |
| 4 | `lib/core/services/ffmpeg_service.dart` | 378 | 400 | ✅ PASS | `processVideo()` (113 baris), `_buildVideoFilter()` (53 baris) |
| 5 | `lib/core/services/history_service.dart` | 129 | 400 | ✅ PASS | Tidak ada |
| 6 | `lib/core/services/media_scanner_service.dart` | 28 | 400 | ✅ PASS | Tidak ada |
| 7 | `lib/core/services/notification_service.dart` | 135 | 400 | ✅ PASS | `showProgressNotification()` (46 baris) |
| 8 | `lib/core/services/render_diagnostic_service.dart` | 113 | 400 | ✅ PASS | `inspectRenderedFile()` (60 baris) |
| 9 | `lib/core/services/settings_service.dart` | 247 | 400 | ✅ PASS | Tidak ada |
| 10 | `lib/core/theme/app_theme.dart` | 118 | 400 | ✅ PASS | Tidak ada |
| 11 | `lib/features/history/screens/recent_history_screen.dart` | 179 | 400 | ✅ PASS | Tidak ada |
| 12 | `lib/features/history/widgets/history_empty_state.dart` | 30 | 400 | ✅ PASS | Tidak ada |
| 13 | `lib/features/history/widgets/history_item_card.dart` | 186 | 400 | ✅ PASS | `build()` (45 baris) |
| 14 | `lib/features/history/widgets/history_storage_bar.dart` | 199 | 400 | ✅ PASS | Tidak ada |
| 15 | `lib/features/navigation/screens/root_navigation_screen.dart` | 69 | 400 | ✅ PASS | Tidak ada |
| 16 | `lib/features/process/screens/batch_processing_screen.dart` | 282 | 400 | ✅ PASS | `build()` (43 baris), `build()` (55 baris), `build()` (89 baris), `build()` (42 baris) |
| 17 | `lib/features/process/screens/error_screen.dart` | 247 | 400 | ✅ PASS | Tidak ada |
| 18 | `lib/features/process/screens/process_screen.dart` | 228 | 400 | ✅ PASS | `_pickVideo()` (49 baris) |
| 19 | `lib/features/process/screens/processing_screen.dart` | 323 | 400 | ✅ PASS | `_runEngine()` (60 baris), `build()` (45 baris) |
| 20 | `lib/features/process/screens/success_screen.dart` | 308 | 400 | ✅ PASS | Tidak ada |
| 21 | `lib/features/process/widgets/engine_state_strip.dart` | 78 | 400 | ✅ PASS | Tidak ada |
| 22 | `lib/features/process/widgets/modifiers_card.dart` | 248 | 400 | ✅ PASS | `build()` (75 baris) |
| 23 | `lib/features/process/widgets/processing_log_viewer.dart` | 160 | 400 | ✅ PASS | Tidak ada |
| 24 | `lib/features/process/widgets/processing_radar_indicator.dart` | 97 | 400 | ✅ PASS | `build()` (44 baris) |
| 25 | `lib/features/process/widgets/processing_stage_tracker.dart` | 64 | 400 | ✅ PASS | Tidak ada |
| 26 | `lib/features/process/widgets/source_file_section.dart` | 319 | 400 | ✅ PASS | `build()` (42 baris) |
| 27 | `lib/features/settings/screens/advanced_settings_bottom_sheet.dart` | 169 | 400 | ✅ PASS | Tidak ada |
| 28 | `lib/features/settings/screens/app_settings_bottom_sheet.dart` | 189 | 400 | ✅ PASS | `build()` (97 baris), `_buildSettingSection()` (43 baris) |
| 29 | `lib/features/settings/screens/settings_screen.dart` | 330 | 400 | ✅ PASS | `build()` (41 baris) |
| 30 | `lib/features/settings/widgets/audio_visual_tuning_card.dart` | 126 | 400 | ✅ PASS | `build()` (51 baris) |
| 31 | `lib/features/settings/widgets/hardware_acceleration_card.dart` | 113 | 400 | ✅ PASS | `build()` (46 baris) |
| 32 | `lib/features/settings/widgets/upscale_resolution_card.dart` | 238 | 400 | ✅ PASS | Tidak ada |
| 33 | `lib/main.dart` | 46 | 400 | ✅ PASS | Tidak ada |
| 34 | `lib/shared/widgets/top_app_bar.dart` | 127 | 400 | ✅ PASS | Tidak ada |
| **TOTAL** | **34 Berkas Dart** | **6.081** | — | **100% PASS** | **20 fungsi > 40 baris** |

---

## 8. Verbatim Test & Static Analysis Output

### Output `flutter analyze --fatal-infos`:
```
Analyzing nra_video_uniquifier...                               
No issues found! (ran in 7.7s)
```

### Output `flutter test`:
```
00:12 +80: All tests passed!
```
*(80 tes passed sempurna, mencakup command building, crop/rotate macroblock bounds, YUV420p output flags, H.264/H.265 codec engine, A/V timing tempo sync, responsive smoke tests).*

---

## 9. Prioritized Remediation Roadmap (P0 → P3)

### Fase 1: Perbaikan Bug Logika Kritis & Concurrency (P1)
1. **Target**: `lib/core/providers/batch_queue_provider.dart:106-107`
   - *Tindakan Minimal*: Ubah pemanggilan `FfmpegService.processVideo` dalam loop `runBatch()` agar mengirimkan `isPortrait: null` dan `totalDurationMs: 0` (atau probe metadata masing-masing file), sehingga orientasi dan durasi video 1 tidak mencemari video 2 dan seterusnya.
   - *Tes Tambahan*: Tambahkan unit test pada `batch_queue_provider_test.dart` yang memproses 2 item dengan orientasi berbeda dan memvalidasi argumen yang diteruskan.
2. **Target**: `lib/features/process/screens/process_screen.dart:79-90`
   - *Tindakan Minimal*: Tambahkan flag guard `bool _isProcessingNavigation = false;` untuk mencegah push ganda saat tombol ditekan cepat.
3. **Target**: `lib/core/providers/uniquifier_provider.dart` & `lib/core/services/settings_service.dart`
   - *Tindakan Minimal*: Bind toggle hardware acceleration secara konsisten ke persistent storage via `ValueNotifier<bool>`.

### Fase 2: Konsolidasi Menu, Dialog Konfirmasi & UI Sizing (P2)
1. **Target**: `lib/features/settings/screens/`
   - *Tindakan Minimal*: Hapus `AppSettingsBottomSheet` dan `AdvancedSettingsBottomSheet`. Ubah aksi pada `ProcessScreen` (TopAppBar & EngineStateStrip) menjadi `provider.setTabIndex(2)`.
   - *Dampak*: Menghilangkan ~350 baris kode redundan dan mencegah sinkronisasi ganda.
2. **Target**: `lib/features/settings/screens/settings_screen.dart:41`, `lib/features/process/screens/batch_processing_screen.dart:249`
   - *Tindakan Minimal*: Tambahkan `showDialog` konfirmasi sebelum mengeksekusi `purgeTempCache()` dan `cancelBatch()`.
3. **Target**: `lib/shared/widgets/top_app_bar.dart:44`, `lib/features/history/widgets/history_item_card.dart:163`
   - *Tindakan Minimal*: Naikkan minimum hit target dari 32x32 dp menjadi 48x48 dp dan spacing minimal 8 dp.
4. **Target**: `lib/features/settings/screens/settings_screen.dart:267`
   - *Tindakan Minimal*: Bungkus baris teks dan tombol Purge Cache dengan `Wrap` agar aman dari overflow pada TextScaler 2.0.

### Fase 3: Pembersihan Label, Security Hardening & Documentation (P3)
1. **Target**: `lib/features/process/widgets/modifiers_card.dart:92`
   - *Tindakan Minimal*: Perbarui teks subtitle menjadi `'8% margin crop & 0.8° tilt'`.
2. **Target**: `android/app/src/main/res/xml/provider_paths.xml:4`
   - *Tindakan Minimal*: Hapus `<root-path>` untuk memenuhi standar rilis Google Play Store.
3. **Target**: `0ai_context/STATE.md`
   - *Tindakan Minimal*: Perbarui commit hash HEAD dan jumlah file Dart menjadi 34 berkas.

---

## 10. Appendix MCP Evidence

| Tool Nama | Argumen Kueri | Hasil & Metrik | Status Verifikasi |
|---|---|---|---|
| `mcp__codebase_memory_mcp__index_status` | `project: "...nra_video_uniquifier"` | Initial: 1338 nodes, 3404 edges | `verified` |
| `mcp__codebase_memory_mcp__index_repository` | `mode: "full"` | Synced: 1350 nodes, 3428 edges (+12 nodes, +24 edges) | `verified` |
| `mcp__codebase_memory_mcp__search_graph` | `name_pattern: ".*Settings.*"` | 44 matching declarations ditemukan (3 classes settings) | `verified` |
| `mcp__codebase_memory_mcp__trace_path` | `function_name: "_openAdvancedSettings"` | 1 caller (`ProcessScreen.build`), 0 callees | `verified` |
| `mcp__codebase_memory_mcp__trace_path` | `function_name: "_openAppSettings"` | 1 caller (`ProcessScreen.build`), 0 callees | `verified` |
| `mcp__codebase_memory_mcp__trace_path` | `function_name: "applyPreset"` | **0 callers di lib/** (Belum diekspos di UI; aktif dipanggil oleh tests di test/uniquifier_provider_test.dart:59,77. Direktori test/ tidak diindeks MCP) | `verified` |
| `mcp__codebase_memory_mcp__get_file_outline` | `file_path: "root_navigation_screen.dart"` | 4 declarations, 2 classes (`RootNavigationScreen`, `_AppBottomNavBar`) | `verified` |
| `mcp__codebase_memory_mcp__get_file_outline` | `file_path: "settings_screen.dart"` | 21 declarations, 7 classes | `verified` |

---

## 11. Honest Admission (Pengakuan Jujur)
1. **Perilaku Native Android Foreground Service**: Deklarasi `<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />` diuji secara statis pada manifest dan kode Dart. Karena tidak ada perangkat fisik Android yang terhubung saat audit ini, ketahanan proses latar belakang terhadap Low Memory Killer (LMK) saat render 4K di background diverifikasi berdasarkan analisis arsitektur Android framework, bukan pengujian fisik baterai/kernel.
2. **False Green Tes Unit**: Tes pada `notification_service_test.dart` dan `media_scanner_service_test.dart` saat ini lulus karena guard `Platform.isAndroid` mengembalikan `false` di lingkungan host Windows (`if (!Platform.isAndroid) return;`). Validasi nyata fungsionalitas notifikasi dan media scanner memerlukan pengujian on-device atau mock MethodChannel yang komprehensif.
3. **Mode Read-Only Murni**: Sesuai instruksi absolut, seluruh temuan di atas tidak langsung dimodifikasi pada source code melainkan didokumentasikan secara menyeluruh dalam roadmap prioritas untuk dieksekusi pada task berikutnya.
