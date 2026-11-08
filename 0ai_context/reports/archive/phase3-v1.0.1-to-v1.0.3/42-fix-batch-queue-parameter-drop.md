# Fix Report 42 — Batch Queue Parameter Drop

**Date:** 2026-11-06
**Type:** Manual Fix (P1-02)
**Status:** Complete

## 1. Latar Belakang Masalah

Berdasarkan audit Report 40 §3 [P1-02], ditemukan bahwa saat pengguna memproses video melalui antrean (Batch Queue), parameter `rotateAngle` (rotasi mikro) dan `activeVisualEffects` (efek visual) tidak diteruskan ke `FfmpegService.processVideo`. Hal ini menyebabkan video yang diproses secara batch kehilangan efek yang telah dipilih di pengaturan.

## 2. Investigasi

Ditemukan bahwa fungsi `_executeBatchItem` di `batch_queue_provider.dart` memanggil `FfmpegService.processVideo` dengan banyak parameter `config`, tetapi melewatkan dua parameter krusial tersebut.

## 3. Perubahan yang Dilakukan

- **`lib/core/providers/batch_queue_provider.dart`**: Menambahkan `rotateAngle: config.rotateAngle` dan `activeVisualEffects: config.activeVisualEffects` pada pemanggilan `FfmpegService.processVideo` di dalam fungsi `_executeBatchItem`.

## 4. Hasil Verifikasi

- `dart analyze`: **No issues found! (exit 0)**
- `flutter test`: **215/215 tests passed (100%)**

## 5. Kesimpulan

Batch Queue kini memiliki _parity_ (kesetaraan fitur) dengan pemrosesan tunggal. Video yang diekspor secara batch akan menerapkan rotasi dan efek visual secara akurat.
