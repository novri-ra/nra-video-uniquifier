# Fix Report 41 — Wire Active Visual Effects into Export Pipeline

**Date:** 2026-11-06
**Type:** Manual Fix (P1-01)
**Status:** Complete

## 1. Latar Belakang Masalah

Berdasarkan audit Report 40 §3 [P1-01], ditemukan bahwa efek visual (seperti Motion Echo, RGB Split, Dreamy Bloom, dll) yang dipilih pengguna lewat `VisualEffectSelectorCard` hanya diterapkan pada pratinjau (preview) di UI, tetapi **tidak pernah diteruskan ke pipeline ekspor**. Hal ini menyebabkan video output kehilangan efek yang dijanjikan (WYSIWYG failure).

## 2. Investigasi & Penyesuaian Asumsi

Pada versi terbaru (`db764d3`), `UniquifierProvider` sudah di-upgrade menggunakan `Set<UnifiedVisualEffect>` untuk mendukung _multi-select_. Namun, parameter tersebut masih terputus di jalur FFmpeg. Fungsi filter builder (`filter_builders.dart`) juga belum menerapkan perulangan (loop) untuk merangkai multi-efek ke dalam string `-vf`.

## 3. Perubahan yang Dilakukan

Kami menyambungkan parameter secara berantai dari UI hingga ke FFmpeg Command Builder:

1. **`lib/features/process/screens/processing_screen.dart`**: Mengirimkan `activeVisualEffects: provider.activeVisualEffects` pada pemanggilan `FfmpegService.processVideo`.
2. **`lib/core/services/ffmpeg_service.dart`**: Menerima parameter `Set<UnifiedVisualEffect>? activeVisualEffects` dan meneruskannya ke `FfmpegCommandBuilder`.
3. **`lib/core/services/ffmpeg/ffmpeg_command_builder.dart`**: Meneruskan parameter tersebut melalui `buildCommand` dan `writeFilterAndCodecOptions` hingga ke `buildVideoFilter`.
4. **`lib/core/services/filter_builders.dart`**:
   - Menerima parameter `activeVisualEffects` di `buildVideoFilter` dan meneruskannya ke `_buildFiltersList`.
   - Menambahkan logika _loop_ di `_buildFiltersList` untuk memetakan setiap efek terpilih menjadi filter FFmpeg menggunakan `buildUnifiedEffectFilter`, lalu memasukkannya ke dalam `return <String>[ ... ]`.

## 4. Hasil Verifikasi

- `dart analyze`: **No issues found! (exit 0)**
- `flutter test`: **215/215 tests passed (100%)**

## 5. Kesimpulan

Fitur multi-select efek visual kini sudah terintegrasi penuh. Pengguna yang memilih beberapa efek visual secara bersamaan akan mendapatkan hasil ekspor video yang sesuai dengan pratinjau.
