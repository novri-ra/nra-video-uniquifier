# Execution Report: Visual Evasion Pipeline Upgrades

- Status: Resolved
- Task: Implement visual evasion upgrades (Canvas foreground spatial crop, sinusoidal zoompan, dynamic RGB color curves)
- Date: 2026-11-04
- Scope: `lib/core/services/filter_builders.dart`, `lib/core/utils/variation_generator.dart`, `test/ffmpeg_service_test.dart`

---

## 1. Perubahan Teknis yang Diterapkan

Berdasarkan diagnosis blueprint pada laporan 03 (`0ai_context/reports/03-audit-tiktok-evasion-and-fix-p3.md`), dilakukan 3 upgrade visual evasion utama:

### 1.1 Spatial Crop & Micro-Rotation pada Aliran Foreground Canvas Blur
- **Lokasi**: `lib/core/services/filter_builders.dart` (`_buildCanvasChain` & `buildVideoFilter`)
- **Masalah Sebelumnya**: Pada mode `enableBlurredCanvas`, aliran `[fg]` hanya di-scale tanpa asymmetric crop maupun micro-rotation, menyisakan kemiripan spasial >98% terhadap deteksi visual TikTok (ViT/SSCD).
- **Perubahan**:
  - `_buildCanvasChain` kini menerima `vars`, `modifyVisuals`, `enableDeepAntiFingerprint`, `cropZoomScale`, dan `cropAnchor`.
  - Aliran `[fg]` kini melewati `_buildSpatialCrop` (asymmetric micro-crop 7–9% dan micro-rotation ~0.8°) sebelum di-scale ke batas kanvas `$fgDim` dan di-overlay di atas `[blurred]`.

### 1.2 Sinusoidal Breathing Motion pada Dynamic Zoompan
- **Lokasi**: `lib/core/services/filter_builders.dart` (`_buildPostCanvasFilters` & `_buildFiltersList`)
- **Masalah Sebelumnya**: Ekspresi `min(zoom+0.0002,1.03)` membeku di zoom 1.03 setelah frame ke-150 (~5 detik), menyebabkan sisa durasi video menjadi statis.
- **Perubahan**:
  - Digantikan dengan formula osilasi sinusoidal kontinu berbasis waktu input `it`:
    ```
    zoompan=z='1.02+0.015*sin(2*PI*it/12)':d=1:x='(iw-iw/zoom)/2*(1+0.3*sin(2*PI*it/8))':y='(ih-ih/zoom)/2*(1+0.3*cos(2*PI*it/8))':s=$zoomDim:fps=$targetFps
    ```
  - Zoom berosilasi halus antara 1.005x dan 1.035x dengan periode 12 detik.
  - Micro-pan dikoordinasikan secara proporsional terhadap sisa margin frame (`(1+0.3*sin(...))`), menjamin `x` dan `y` tidak pernah bernilai negatif atau melebihi dimensi frame pada resolusi berapapun.

### 1.3 Variasi Dinamis Kurva Warna Multi-Channel RGB Per Render
- **Lokasi**: `lib/core/utils/variation_generator.dart` (`generateRgbCurves`) & `lib/core/services/filter_builders.dart`
- **Masalah Sebelumnya**: Filter `curves=all='0/0 0.15/0.18 0.5/0.5 0.85/0.82 1/1'` bersifat statis di setiap video, mudah dinetralkan oleh normalisasi histogram ByteDance.
- **Perubahan**:
  - Menambahkan generator `generateRgbCurves({math.Random? random})` yang menghasilkan kurva non-linier independen untuk masing-masing kanal Red, Green, dan Blue dengan margin aman ±0.02.
  - Properti `curves` disimpan dalam `VideoVariations` dan disuntikkan ke dalam filter graph via `curves=${vars.curves}`.

---

## 2. Hasil Verifikasi Deterministik

- **Dart Analyze**:
  `dart analyze` → exit 0, **0 issues found**.
- **Flutter Test**:
  `flutter test` → exit 0, **173/173 tests passed** (100% pass rate).
- **Dart Format**:
  `dart format --set-exit-if-changed lib/core/services/filter_builders.dart lib/core/utils/variation_generator.dart` → exit 0, 0 unformatted.
- **Section 14 Inviolable Boundaries**:
  - Strictly offline-first dipertahankan (tanpa telemetri atau jaringan luar).
  - File sumber asli tidak dimodifikasi secara destruktif in-place.
