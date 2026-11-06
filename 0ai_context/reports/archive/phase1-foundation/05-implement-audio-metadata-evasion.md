# Execution Report: Audio Mutation & Container Metadata Evasion

- Status: Resolved
- Task: Implement audio mutation hardening (expanded pitch range, stereo micro-delay phase dispersion) and MP4 container metadata profile randomization with libx264 stitchable flags
- Date: 2026-11-04
- Scope: `lib/core/services/ffmpeg_service.dart`, `lib/core/services/filter_builders.dart`, `lib/core/utils/variation_generator.dart`, `test/ffmpeg_service_test.dart`

---

## 1. Perubahan Teknis yang Diterapkan

Berdasarkan blueprint laporan 03 (`0ai_context/reports/03-audit-tiktok-evasion-and-fix-p3.md`), diterapkan penguatan pada sektor akustik dan penyamaran wadah MP4:

### 1.1 Perlebaran Spektral Audio & Dispersi Fasa Stereo Mikro
- **Lokasi**: `lib/core/utils/variation_generator.dart` & `lib/core/services/filter_builders.dart`
- **Masalah Sebelumnya**:
  - Rentang `pitchFactor` sebelumnya [0.985, 1.015] (±1.5%) masih berada dalam radius toleransi de-biasing ByteDance/Chromaprint acoustic fingerprint.
  - Phase overtones audio asli tetap utuh sehingga algoritma de-warping mudah menyamakan kembali spektrum audio.
- **Perubahan**:
  - `pitchFactor` diperlebar ke rentang `[0.960, 1.040]` (±4.0%):
    ```dart
    final pitch = 0.960 + rng.nextDouble() * 0.080;
    ```
  - Menambahkan modul mikro-chorus / stereo phase dispersion pada rantai audio saat `modifyAudio` aktif:
    ```dart
    const phaseChorus = 'chorus=0.5:0.9:50|60:0.4|0.32:0.25|0.4:2|1.2';
    final phaseMod = modifyAudio ? ',$phaseChorus' : '';
    ```
    Dispersi ini mengacaukan keselarasan fasa akustik multi-kanal tanpa menimbulkan dengung yang mengganggu pendengaran manusia.

### 1.2 Rotasi Profil Perangkat Smartphone & Penyamaran Container MP4
- **Lokasi**: `lib/core/utils/variation_generator.dart` (`DeviceProfile`) & `lib/core/services/ffmpeg_service.dart` (`_writeMetadataTags`)
- **Masalah Sebelumnya**:
  - Metadata menulis string statis `"iPhone 15 Pro Max"` dan `"Apple QuickTime"` berulang kali, kontras dengan tanda tangan NAL encoder `libx264`.
- **Perubahan**:
  - Dibuat struktur model `DeviceProfile` dengan pool profil smartphone terpercaya:
    - Apple iPhone 15 Pro Max (`Core Media Video` / `Core Media Audio`)
    - Apple iPhone 16 Pro (`Core Media Video` / `Core Media Audio`)
    - Samsung Galaxy S24 Ultra (`VideoHandle` / `SoundHandle`, encoder: `Samsung Camera`)
    - Google Pixel 8 Pro (`VideoHandler` / `SoundHandler`, encoder: `Google Camera`)
    - Google Pixel 9 Pro (`VideoHandler` / `SoundHandler`, encoder: `Google Camera`)
  - Profil dipilih secara acak per eksekusi dan disuntikkan ke dalam container MP4 via `-metadata`.

### 1.3 Penambahan Parameter Kompresi Anti-Fingerprint (`stitchable=1`)
- **Lokasi**: `lib/core/services/filter_builders.dart` (`_resolveCodecArgs`)
- **Perubahan**:
  - Menambahkan flag `-x264-params "stitchable=1"` pada setiap konfigurasi encoding H.264 (`libx264`). Flag ini mencegah penyisipan penanda NAL header berulang dan header info yang memudahkan pendeteksian pengkodean sintetis.

---

## 2. Hasil Verifikasi Deterministik

- **Dart Analyze**:
  `dart analyze` → exit 0, **0 issues found**.
- **Flutter Test**:
  `flutter test` → exit 0, **173/173 tests passed** (100% pass rate).
- **Dart Format**:
  `dart format --set-exit-if-changed lib/core/services/ffmpeg_service.dart lib/core/services/filter_builders.dart lib/core/utils/variation_generator.dart` → exit 0, 0 unformatted.
- **Section 14 Inviolable Boundaries**:
  - Strictly offline-first (tidak memerlukan jaringan atau telemetri).
  - Tidak mengubah atau merusak berkas masukan asli.
