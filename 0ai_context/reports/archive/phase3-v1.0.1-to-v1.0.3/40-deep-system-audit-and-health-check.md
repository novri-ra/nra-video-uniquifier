# Technical Report: Deep System Audit & Health Check (v1.0.4+)

**Report Number:** 40  
**Date:** 2026-11-06  
**Type:** Deep Architectural, Engine, Platform & Test Coverage Audit  
**Status:** Complete  
**Target Version:** v1.0.4+  

---

## 1. Executive Scorecard

| Domain | Score | Status | Ringkasan Evaluasi |
|--------|:-----:|:------:|-------------------|
| **Arsitektur & State Management** | **92 / 100** | Stabil | Arsitektur Provider modular dengan mixin domain-specific. Lifecycle timer dan dispose terkelola bersih. Ditemukan 1 parameter drop pada batch queue. |
| **Pipeline FFmpeg & Subproses** | **88 / 100** | Cukup Baik | Subproses terkelola dengan safety cancellation, atomic file export, dan verification pass. Namun ditemukan silent bug: visual effects tidak diteruskan ke export pipeline. |
| **Keamanan & Storage I/O** | **94 / 100** | Sangat Baik | Atomic staging, path escaping, SHA-256 integrity check, Scoped Storage multi-tier intent dispatcher berjalan solid. |
| **Platform Native (Android 7.0 - 16)** | **90 / 100** | Baik | Multi-channel notifications, WakeLock safety cap 1 jam, dan intent storage stabil. Perlu penambahan `mediaProcessing` foreground service type untuk Android 14+. |
| **Kualitas UI/UX & Responsivitas** | **91 / 100** | Baik | Anti-jank slider with throttle/debounce, top floating capsule toast. Perlu penyesuaian margin toast pada orientasi landscape / layar pendek. |
| **Cakupan Pengujian (Test Coverage)** | **75.44%** | Cukup | 215 dari 215 tests lulus (100% pass rate). 5.972 dari 7.916 baris kode ter-cover. Modul ffmpeg & batch UI membutuhkan penambahan coverage. |

---

## 2. Metrik Verifikasi Statis & Dinamis

Hasil pengujian otomatis pada branch `development` (commit `d692bf9`):

```bash
$ dart format --set-exit-if-changed lib/ test/
Formatted 124 files (0 changed) in 0.43 seconds.

$ flutter analyze
Analyzing nra-video-uniquifier...
No issues found! (ran in 26.1s)

$ flutter test --coverage
00:15 +215: All tests passed!
Total Line Coverage: 75.44% (5,972 / 7,916 lines hit)
```

### Distribusi Cakupan Modul Kritis
* **100% Coverage:** `microstock_article_content_blocks.dart`, `root_navigation_screen.dart`, `interactive_preview_slider.dart`, `device_specs.dart`, `unified_effect_preset.dart`.
* **Cakupan Rendah (< 35%):**
  1. `lib/features/microstock/services/article_image_service.dart`: **0.0%** (0 / 64)
  2. `lib/features/batch/screens/batch_queue_tab_screen.dart`: **0.8%** (1 / 121)
  3. `lib/features/history/widgets/history_empty_state.dart`: **12.5%** (1 / 8)
  4. `lib/features/history/screens/recent_history_screen.dart`: **20.0%** (45 / 225)
  5. `lib/core/services/ffmpeg_service.dart`: **20.3%** (30 / 148)
  6. `lib/core/services/storage_service.dart`: **20.8%** (5 / 24)
  7. `lib/core/services/ffmpeg/media_probe_helper.dart`: **25.0%** (2 / 8)
  8. `lib/features/microstock/services/article_reader_extractor.dart`: **28.7%** (41 / 143)

---

## 3. Temuan Kritis (P0 / P1)

### [P1-01] Silent Bug: Multi-Select Visual Effects Preview vs Export Discrepancy
- **Lokasi:**
  * `lib/features/process/screens/processing_screen.dart` (`_processWithNative`, L131-L188)
  * `lib/core/services/ffmpeg/ffmpeg_command_builder.dart` (`buildCommand`)
  * `lib/core/services/ffmpeg_service.dart` (`processVideo`)
- **Masalah:**
  Pengguna dapat memilih efek visual baru melalui `VisualEffectSelectorCard` (`motionEcho`, `rgbSplit`, `dreamyBloom`, `film16mm`, `dynamicGrain`). Efek ini tampil sempurna pada interactive preview slider karena `FilterBuilders.buildPreviewFilterChain` mengintegrasikan `activeEffects`.
  Namun, saat proses ekspor dijalankan melalui `ProcessingScreen`, pemanggilan `FfmpegService.processVideo` sama sekali **tidak meneruskan parameter `activeVisualEffects`**. Akibatnya, `FfmpegCommandBuilder.buildCommand` hanya merender anti-fingerprint standar dan blurred canvas, sementara efek visual multi-select yang dipilih pengguna **hilang total pada file hasil ekspor**.
- **Dampak:** Ketidaksesuaian fungsional (WYSIWYG failure). Video output tidak memiliki efek visual yang dijanjikan pada tampilan pratinjau.
- **Rekomendasi Perbaikan:**
  1. Tambahkan parameter `Set<UnifiedVisualEffect>? activeVisualEffects` pada `FfmpegService.processVideo` dan `FfmpegCommandBuilder.buildCommand`.
  2. Sambungkan `FilterBuilders.buildEffectFilterChain` atau urutan `FilterBuilders.orderEffectsByStage` ke dalam penyusunan `-vf` pada `buildCommand`.
  3. Teruskan `provider.activeVisualEffects` dari `ProcessingScreen`.

### [P1-02] Batch Queue Parameter Drop: Rotasi & Visual Effects Terabaikan
- **Lokasi:** `lib/core/providers/batch_queue_provider.dart` (`_executeItemProcessing`, L139-L174)
- **Masalah:**
  Pada saat mengeksekusi antrean batch, `BatchQueueProvider` memanggil `FfmpegService.processVideo` dengan mengabaikan parameter:
  * `rotateAngle`: Diabaikan (tidak di-passing ke `processVideo`), padahal tersedia di `config.rotateAngle`.
  * `activeVisualEffects`: Tidak di-passing.
- **Dampak:** Video yang diproses via Batch Queue tidak menerapkan sudut rotasi dan efek visual yang telah dikonfigurasi.
- **Rekomendasi Perbaikan:** Tambahkan `rotateAngle: config.rotateAngle` dan `activeVisualEffects: config.activeVisualEffects` pada pemanggilan `FfmpegService.processVideo` di `BatchQueueProvider`.

---

## 4. Temuan Menengah & Rendah (P2 / P3)

### [P2-01] Akumulasi File Pratinjau Sementara (Temporary Preview Cache Accumulation)
- **Lokasi:** `lib/core/services/ffmpeg_service.dart` (`renderFilteredPreviewFrame`, L182-L211)
- **Masalah:**
  Setiap kali pratinjau diperbarui (ketika menggeser slider atau mengubah efek), file pratinjau baru dibuat dengan format `preview_${DateTime.now().millisecondsSinceEpoch}.jpg` di folder `getTemporaryDirectory()`. Meskipun session FFmpeg sebelumnya dibatalkan dengan tepat via `_activePreviewSessionId`, file-file JPEG frame lama tidak dihapus secara otomatis dari storage internal.
- **Dampak:** Membengkaknya penggunaan storage cache aplikasi jika pengguna sering melakukan scrubbing slider atau mengganti preset efek.
- **Rekomendasi Perbaikan:** Hapus file frame pratinjau sebelumnya (`File(oldPath).delete()`) saat frame baru berhasil dirender atau bersihkan seluruh frame bertanda `preview_*.jpg` di direktori temporary saat inisialisasi / dispose.

### [P2-02] Kepatuhan Foreground Service Android 14-16 (API 34-36)
- **Lokasi:** `android/app/src/main/AndroidManifest.xml` (L15-L25)
- **Masalah:**
  Saat ini service latar depan hanya mendeklarasikan:
  ```xml
  <service
      android:name="com.dexterous.flutterlocalnotifications.ForegroundService"
      android:foregroundServiceType="dataSync"
      android:exported="false" />
  ```
  Pada pedoman Google Play Store untuk Android 14+ (API 34, 35, 36), aplikasi yang melakukan transcoding / encoding video offline direkomendasikan menggunakan tipe `mediaProcessing` di samping `dataSync`. Penggunaan `dataSync` secara eksklusif untuk transcoding video berisiko ditolak pada Google Play Policy Review masa depan.
- **Rekomendasi Perbaikan:**
  Tambahkan permission `android.permission.FOREGROUND_SERVICE_MEDIA_PROCESSING` dan deklarasikan tipe gabungan:
  ```xml
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROCESSING" />
  ...
  android:foregroundServiceType="dataSync|mediaProcessing"
  ```

### [P2-03] Margin Layout `AppToast` pada Perangkat Layar Pendek / Landscape
- **Lokasi:** `lib/shared/widgets/app_toast.dart` (L19-L30)
- **Masalah:**
  Kalkulasi margin bawah `AppToast` menggunakan formula tetap:
  ```dart
  final bottomMargin = (screenHeight - 130.0).clamp(0.0, double.infinity);
  ```
  Jika aplikasi diputar ke orientasi landscape (misalnya tinggi layar < 420dp) atau dijalankan pada perangkat dengan tinggi layar pendek (< 550dp), margin bawah ini dapat mendorong floating toast terlalu ke atas hingga terpotong di luar area layar yang aman.
- **Rekomendasi Perbaikan:**
  Gunakan kalkulasi berbasis `MediaQuery.paddingOf(context).top` dan margin persentase relatif atau gunakan `top` margin yang eksplisit:
  ```dart
  final topPadding = MediaQuery.paddingOf(context).top;
  final safeTopMargin = topPadding > 0 ? topPadding + 10.0 : 24.0;
  ```

### [P3-01] Gap Cakupan Unit & Integration Testing
- **Lokasi:** `lib/features/microstock/services/article_image_service.dart` (0%) & `lib/core/services/ffmpeg_service.dart` (20.3%)
- **Masalah:** `FfmpegService` mengeksekusi subprocess native sehingga pengujian otomatis mengandalkan mock/staged test. Bagian resolusi metadata, error recovery, dan partial cleanup belum ter-cover secara mendalam oleh test suite.
- **Rekomendasi Perbaikan:** Tambahkan golden/unit tests untuk `article_image_service` dan unit tests dengan fixture mock FFmpeg untuk menguji branch exception.

---

## 5. Analisis Siklus Hidup & Memory Leaks

Audit menyeluruh terhadap objek-objek reaktif menunjukkan implementasi yang bersih:
1. **Langganan Stream & Timer:**
   * `UniquifierProvider`: `_previewDebounceTimer` dibatalkan dengan benar pada `dispose()` (L48) dan sebelum eksekusi render baru (L250). Semua listener notifikasi settings (`upscaleResolutionNotifier`, `videoCodecNotifier`, dsb.) dilepas secara simetris (`removeListener`).
   * `ConnectivityService`: `_pollingTimer` dibatalkan secara eksplisit pada `stopMonitoring()`.
   * `NewsSearchAndFilterBar`: `_debounceTimer` dibatalkan pada `dispose()`.
2. **Pengendali Animasi (AnimationController):**
   * `ProcessingScreen`: `_controller` dilepas pada `dispose()` (L56).
   * `InteractivePreviewSlider`: `_fadeController` dilepas pada `dispose()` (L109).
   * `LiveIntelTickerCard`: `_pulseController` dilepas pada `dispose()`.
3. **Pemeriksaan Async Gaps (`mounted` validation):**
   * Pemeriksaan pada seluruh screen (`process_screen.dart`, `processing_screen.dart`, `recent_history_screen.dart`) mengonfirmasi bahwa semua operasi navigasi dan snackbar/toast pasca-`await` dilindungi oleh pemeriksaan `if (mounted)`.

---

## 6. Actionable Remediation Plan (Rencana Perbaikan Bertahap)

### Tahap 1: Perbaikan Kritis Pipeline Rendering (P1)
- [ ] Sambungkan `activeVisualEffects` ke `FfmpegService.processVideo` dan `FfmpegCommandBuilder.buildCommand`.
- [ ] Integrasikan `FilterBuilders.orderEffectsByStage` ke dalam filtergraph video saat ekspor.
- [ ] Teruskan `provider.activeVisualEffects` pada `ProcessingScreen._processWithNative`.
- [ ] Teruskan `config.rotateAngle` dan `config.activeVisualEffects` pada `BatchQueueProvider._executeItemProcessing`.
- [ ] Buat unit test verifikasi untuk memastikan command string FFmpeg memuat rantai efek yang terpilih.

### Tahap 2: Manajemen Cache & Stabilitas UI (P2)
- [ ] Implementasikan auto-purge file pratinjau lama pada `FfmpegService.renderFilteredPreviewFrame`.
- [ ] Modifikasi `AppToast` agar menggunakan top safe-area padding alih-alih hardcoded bottom margin.
- [ ] Tambahkan izin `FOREGROUND_SERVICE_MEDIA_PROCESSING` pada `AndroidManifest.xml` untuk kesiapan Android 14-16.

### Tahap 3: Peningkatan Test Coverage (P3)
- [ ] Tulis unit tests untuk `article_image_service.dart` (target: > 80%).
- [ ] Tulis widget test untuk `batch_queue_tab_screen.dart` dan `history_empty_state.dart`.
- [ ] Tingkatkan test coverage `FfmpegService` untuk branch fallback & error catching.

---

## 7. Status Audit & Kesimpulan

Sistem berada dalam kondisi **sangat sehat dan fungsional** dengan 0 analyzer warning dan 100% test pass rate (215/215).
Prioritas tindakan berikutnya adalah menyelesaikan **[P1-01]** dan **[P1-02]** agar seluruh fitur visual effect inovatif yang telah dibangun dapat dirasakan secara penuh oleh pengguna pada hasil video akhir.
