# Laporan 56: Penguncian Dimensi Resolusi Absolut Standar untuk Upscale Lanczos 1080p, 2K, dan 4K

## 1. Ringkasan Eksekutif & Analisis Akar Masalah

- **Masalah**:
  Sebelum perbaikan ini, proses upscaling video menghasilkan dimensi tinggi atau lebar yang tidak standar (contohnya `1080x1886` bukan standar kanonikal `1080x1920`). Hal ini disebabkan oleh:
  1. Penggunaan skala relatif `h=-2` atau `w=-2` pada filter Lanczos (`scale=w=$height:h=-2:flags=lanczos`).
  2. Filter skala diletakkan di tengah-tengah rantai filter (sebelum denoise, color curves, noise, dan frame decimate).
  3. Adanya filter skala perataan makroblok penutup `scale=trunc(iw/2)*2:trunc(ih/2)*2` yang memotong dimensi akhir berdasarkan rasio aspek sisa dari operasi crop/rotasi.

- **Solusi yang Diterapkan (Option 1 - Absolute Target Resolution Lock)**:
  1. **Pemetaan Resolusi Kanonikal Murni**:
     - **1080p**:
       * Portrait: `1080x1920`
       * Landscape: `1920x1080`
     - **2K**:
       * Portrait: `1440x2560`
       * Landscape: `2560x1440`
     - **4K**:
       * Portrait: `2160x3840`
       * Landscape: `3840x2160`
  2. **Reposisi Filter & Penguncian Mutlak**:
     - Filter upscaling Lanczos dipindahkan ke ujung akhir rantai filter spasial (setelah PTS, crop, rotasi, zoompan, denoise, unsharp, curves, eq, noise, dan decimate).
     - Menggunakan dimensi piksel absolut: `scale=w=TARGET_W:h=TARGET_H:flags=lanczos`.
     - Filter ini langsung diikuti oleh `format=yuv420p`.
     - Ketika opsi `upscale` aktif, filter pemotongan makroblok `scale=trunc(iw/2)*2:trunc(ih/2)*2` ditiadakan karena resolusi kanonikal sudah dijamin merupakan bilangan genap kelipatan 2.

---

## 2. Rincian Modifikasi Kode

### A. `lib/core/services/settings_service.dart`
Pembaruan metode `scaleFilter` pada enum `TargetResolution`:
```dart
  String scaleFilter({bool isPortrait = false}) {
    final targetW = isPortrait ? height : width;
    final targetH = isPortrait ? width : height;
    return 'scale=w=$targetW:h=$targetH:flags=lanczos';
  }
```

### B. `lib/core/services/filter_builders.dart`
Penambahan fungsi pembantu dimensi kanonikal dan pemindahan filter skala ke posisi terminal rantai filter:
```dart
  /// Determines canonical target resolution bounds (width, height).
  static (int, int) canonicalDimensions(TargetResolution res, {required bool isPortrait}) {
    switch (res) {
      case TargetResolution.r1080p:
        return isPortrait ? (1080, 1920) : (1920, 1080);
      case TargetResolution.r2k:
        return isPortrait ? (1440, 2560) : (2560, 1440);
      case TargetResolution.r4k:
        return isPortrait ? (2160, 3840) : (3840, 2160);
    }
  }

  /// Builds absolute Lanczos scale filter enforcing exact canonical pixel dimensions.
  static String buildScaleFilter({
    required TargetResolution targetResolution,
    required bool isPortrait,
  }) {
    final (w, h) = canonicalDimensions(targetResolution, isPortrait: isPortrait);
    return 'scale=w=$w:h=$h:flags=lanczos';
  }
```
Pada `_buildFiltersList`:
```dart
      if (enableFrameSkip) 'decimate=cycle=25',
      if (upscale)
        buildScaleFilter(targetResolution: targetResolution, isPortrait: isPortrait)
      else
        'scale=trunc(iw/2)*2:trunc(ih/2)*2',
      'format=yuv420p',
```

### C. `test/ffmpeg_service_test.dart`
Penyesuaian assertion unit test untuk memeriksa token dimensi absolut dan urutan sekuensial filter:
- 1080p portrait: `scale=w=1080:h=1920:flags=lanczos`
- 2K portrait: `scale=w=1440:h=2560:flags=lanczos`
- 4K portrait: `scale=w=2160:h=3840:flags=lanczos`
- 1080p landscape: `scale=w=1920:h=1080:flags=lanczos`
- 2K landscape: `scale=w=2560:h=1440:flags=lanczos`
- 4K landscape: `scale=w=3840:h=2160:flags=lanczos`
- Verifikasi urutan sekuensial: `PTS` -> `Crop` -> `Rotate` -> `Denoise` -> `Unsharp` -> `EQ` -> `Noise` -> `Scale` -> `Format`.

---

## 3. Hasil Verifikasi & Kepatuhan Kualitas

1. **Analisis Statis**:
   - Perintah: `flutter analyze --fatal-infos`
   - Hasil: **No issues found!** (0 error, 0 warning, 0 info).

2. **Pengujian Unit & Widget**:
   - Perintah: `flutter test`
   - Hasil: **112/112 test lulus** (100% pass rate).

3. **Audit Batasan Baris Kode (Line Budget <= 400 LOC)**:
   - `lib/core/services/ffmpeg_service.dart`: 393 baris
   - `lib/core/providers/uniquifier_provider.dart`: 368 baris
   - `lib/core/services/settings_service.dart`: 311 baris
   - `lib/core/services/filter_builders.dart`: 221 baris
   - Seluruh berkas dalam direktori `lib/` patuh batasan `<= 400 baris`.

---

## 4. MCP Evidence Appendix

| MCP Tool | Kueri / Parameter | Hasil & Metrik | Status |
|---|---|---|---|
| `mcp__codebase_memory_mcp__list_projects` | detail: identity | Ditemukan project target `C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier` | Terverifikasi |
| `mcp__codebase_memory_mcp__index_status` | project: `C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier` | 1841 nodes, 4438 edges, status: ready | Terverifikasi |
| `mcp__codebase_memory_mcp__index_repository` | mode: "full", repo_path: `.../nra_video_uniquifier` | Status: indexed, 1843 nodes, 4447 edges | Terverifikasi |
