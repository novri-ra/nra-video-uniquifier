# Laporan 31: Implementasi Fitur Superior Evasion 2026 & 4-Tier Native Intent All Files Access (Tahap 2 & 3)

**Tanggal:** 5 November 2026  
**Pelaksana:** Senior Architect, Mobile Systems & Signal Processing Specialist  
**Cakupan Eksekusi:** Algoritma Dynamic GOP Jittering, Micro Color Matrix Shifting, SEI NAL Unit Leak Stripping, Inaudible Subliminal Audio Layering, dan 4-Tier Native Intent Dispatcher untuk MANAGE_EXTERNAL_STORAGE Android 11+  
**Status:** Sukses Terverifikasi (176/176 tests passed, flutter analyze 0 issues)

---

## 1. Ringkasan Eksekutif

Menindaklanjuti Roadmap Laporan 29, fase ini mengeksekusi integrasi fitur mutakhir Evasion 2026 (Tahap 2) serta Intent Native 1-Klik untuk izin penyimpanan Android 11+ (Tahap 3):
1. **Dynamic GOP Jittering:** Mengintegrasikan parameter `-g 36 -keyint_min 18 -sc_threshold 40` ke seluruh encoder x264 guna mengacak interval dan letak I-frame, mematahkan ekstraksi frame deterministik pada algoritma pHash scanner bot (TikTok/Meta/YouTube Shorts).
2. **Sub-Perceptual Micro Color Matrix Shifting:** Menambahkan filter `colorchannelmixer` yang memodifikasi nilai numerik RGB pada 100% piksel secara sub-perceptual tanpa distorsi visual.
3. **Sanitasi SEI NAL Unit Software Leak:** Menerapkan bitstream filter `-bsf:v filter_units=remove_types=6` pada output MP4 untuk menghapus SEI user data unreg metadata encoder bawaan libx264.
4. **Inaudible Psychoacoustic Masking:** Melengkapi dither pink noise dengan sinyal subliminal infrasound 24 Hz dan near-ultrasound 18.2 kHz (`aevalsrc`) guna memecah fingerprint AcoustID/Chromaprint tanpa menimbulkan audible noise.
5. **4-Tier Native Intent Dispatcher:** Membangun mekanisme fallback 4 tingkat pada `HistoryService.requestAllFilesAccessDirectly()` dan menghubungkannya ke dialog izin di `RecentHistoryScreen`.

---

## 2. Rincian Teknis & Implementasi

### A. Dynamic Keyframe / GOP Jittering
- **File:** `lib/core/services/filter_builders.dart`
- **Tujuan:** Mencegah bot mendeteksi kesamaan frame pada interval waktu tertentu dengan mengacak letak I-frame melalui dynamic scene cut detection.
- **Implementasi:**
  ```dart
  const x264GopParams = '-g 36 -keyint_min 18 -sc_threshold 40 -x264-params "stitchable=1"';
  ```
  Diterapkan secara seragam pada output libx264 (resolusi standard, 2K, maupun 4K).

### B. Sub-Perceptual Micro Color Matrix Shifting
- **File:** `lib/core/services/filter_builders.dart`
- **Tujuan:** Mengubah nilai numerik matriks warna setiap piksel secara matematis namun tetap imperceptible oleh mata manusia.
- **Implementasi:**
  Pada method `_buildFiltersList` dan `_buildPostCanvasFilters`, saat `modifyVisuals == true`, disuntikkan filter:
  ```dart
  colorchannelmixer=rr=0.994:rg=0.003:rb=0.003:gg=0.995:gr=0.003:gb=0.002:bb=0.994:br=0.003:bg=0.003
  ```
  Total bobot tiap kanal tetap `1.000` (menjaga luminans dan keseimbangan warna netral), namun setiap koordinat piksel RGB mengalami pergeseran matematis sehingga hash perceptual mendeteksi matriks yang sepenuhnya berbeda.

### C. SEI NAL Unit Software Leak Sanitization
- **File:** `lib/core/services/ffmpeg/ffmpeg_command_builder.dart`
- **Tujuan:** libx264 secara otomatis menyematkan NAL unit type 6 (SEI user data unregistered) yang berisi string versi encoder, build config, dan signature software yang dapat diinspeksi oleh bot.
- **Implementasi:**
  Pada pembentukan final command jika output adalah MP4:
  ```dart
  if (outputPath.toLowerCase().endsWith('.mp4')) {
    buffer.write(' -bsf:v filter_units=remove_types=6');
  }
  ```
  Ini mengeliminasi seluruh SEI user data unreg tanpa merusak kompatibilitas decoding hardware smartphone.

### D. Inaudible Psychoacoustic Masking
- **File:** `lib/core/services/filter_builders.dart`
- **Tujuan:** Menggagalkan algoritma fingerprint audio (AcoustID / Chromaprint) menggunakan spektrum subliminal di luar rentang vokal manusia.
- **Implementasi:**
  Menyuntikkan generator gelombang subliminal 24 Hz (infrasound) dan 18.2 kHz (near-ultrasound) via `aevalsrc`:
  ```dart
  aevalsrc=exprs=0.0008*sin(2*PI*24*t)+0.0006*sin(2*PI*18200*t):d=7200:s=44100[subliminal];
  [noise][subliminal]amix=inputs=2:duration=first:weights=0.5 0.5[dither];
  [a0][dither]amix=inputs=2:duration=first:weights=1 0.001[out]
  ```
  Gain audio asli video tetap `1.0` (0 dB), sementara dither subliminal dicampur pada bobot mikro `0.001`, menjaga volume vokal jernih dan bebas distorsi desis.

### E. 4-Tier Native Intent Dispatcher (MANAGE_EXTERNAL_STORAGE)
- **File:** `lib/core/services/history_service.dart` & `lib/features/history/screens/recent_history_screen.dart`
- **Tujuan:** Memastikan pengguna Android 11+ langsung diarahkan secara 1-klik ke toggle "Akses semua berkas" aplikasi, tanpa harus mencari manual di menu pengaturan.
- **Arsitektur Fallback:**
  - **Tier 1:** Action `android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION` dengan URI `package:id.novrira.videouniquifier` (membuka langsung toggle izin aplikasi spesifik).
  - **Tier 2:** Fallback ke `android.settings.MANAGE_ALL_FILES_ACCESS_PERMISSION` (membuka daftar aplikasi dengan akses semua berkas).
  - **Tier 3:** Fallback ke `android.settings.APPLICATION_DETAILS_SETTINGS` dengan URI `package:id.novrira.videouniquifier` (halaman info aplikasi).
  - **Tier 4:** Fallback ke `openAppSettings()` via `permission_handler`.
- **Integrasi UI:** Tombol "Izinkan Akses" di dialog perizinan `RecentHistoryScreen` memanggil dispatcher 4-tier ini secara otomatis saat dijalankan di Android 11+.

---

## 3. Hasil Pengujian & Verifikasi

1. **Dart Format:**
   `dart format --set-exit-if-changed lib/ test/` -> 0 unformatted files (clean).
2. **Flutter Analyze:**
   `flutter analyze` -> 0 issues found (clean).
3. **Flutter Test:**
   `flutter test` -> **176/176 tests passed** (100% success rate).
   - Pengujian `test/ffmpeg_service_test.dart` memvalidasi keberadaan `colorchannelmixer`, `filter_units=remove_types=6`, `g 36`, `keyint_min 18`, `sc_threshold 40`, serta rantai dither subliminal `aevalsrc`.
