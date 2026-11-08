# Fix Report 43 — Temporary Preview Cache Accumulation

**Date:** 2026-11-06
**Type:** Manual Fix (P2-01)
**Status:** Complete

## 1. Latar Belakang Masalah

Berdasarkan audit Report 40 §4 [P2-01], ditemukan bahwa setiap kali pratinjau (preview) video diperbarui, `FfmpegService.renderFilteredPreviewFrame` membuat file gambar baru (`preview_<timestamp>.jpg`) di folder temporary. File-file lama ini tidak pernah dihapus, sehingga jika pengguna sering menggeser slider, folder cache aplikasi akan membengkak dan memakan storage perangkat.

## 2. Perubahan yang Dilakukan

- **`lib/core/services/ffmpeg_service.dart`**:
  - Menambahkan fungsi baru `_cleanupOldPreviews(String currentPath)`.
  - Fungsi ini akan memindai folder temporary, mencari file berawalan `preview_` dan berakhiran `.jpg`, lalu menghapusnya. Fungsi ini dilengkapi pengaman agar **tidak** menghapus file yang baru saja dirender (`currentPath`).
  - Memanggil `_cleanupOldPreviews(result)` tepat setelah proses render frame baru berhasil diselesaikan.

## 3. Hasil Verifikasi

- `dart analyze`: **No issues found! (exit 0)**
- `flutter test`: **215/215 tests passed (100%)**

## 4. Kesimpulan

Pembengkakan cache pratinjau berhasil diatasi. Penggunaan storage untuk file temporary kini bersifat konstan (hanya menyimpan 1 file pratinjau terbaru).
