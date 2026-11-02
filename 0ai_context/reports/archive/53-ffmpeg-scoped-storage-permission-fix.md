# Laporan 53: Remediasi Crash FFmpeg "Permission denied" Melalui Staged Internal Cache Rendering & MediaStore Export

## 1. Executive Summary & Audit Verdict

- **Masalah Utama**:
  Eksekusi FFmpeg pada perangkat fisik Android (khususnya Android 10, 11, 12, 13, 14) mengalami kegagalan mendadak dengan pesan:
  `<external storage>/... Permission denied` (FFmpeg failed with code 1).
- **Penyebab Akar (Root Cause Analysis)**:
  1. **Batasan POSIX pada Android Scoped Storage**:
     `FfmpegService.processVideo` sebelumnya mengarahkan parameter `outputPath` dari `buildCommand` secara langsung ke direktori penyimpanan eksternal publik: `/storage/emulated/0/Movies/Uniquifier/UQ_<base>_<timestamp>.mp4`.
  2. Pada Android 10+ (API level 29+), subsistem kernel Linux / FUSE menerapkan *Scoped Storage*. Proses native C (FFmpeg C/C++ engine di dalam `ffmpeg-kit`) yang mencoba membuat atau menulis berkas baru secara langsung menggunakan syscall POSIX standar (`open(..., O_CREAT|O_WRONLY)`) langsung ditolak dengan kode kesalahan `EACCES (Permission denied)`.
- **Solusi Rekayasa & Implementasi**:
  1. **Two-Stage Internal Sandbox Rendering**:
     Target output yang diberikan ke `buildCommand` FFmpeg kini **selalu dan mutlak** diarahkan ke direktori cache internal sandbox aplikasi:
     `stagedOutputPath = '${tempDir.path}/staged_out_${DateTime.now().millisecondsSinceEpoch}.mp4'`.
     Penyimpanan sandbox internal aplikasi tidak memerlukan izin runtime Android apa pun dan kebal terhadap penolakan POSIX `EACCES`.
  2. **Safe Staged Export Pipeline (`_exportStagedFile`)**:
     Setelah FFmpeg berhasil menyelesaikan render (Exit Code 0) dan lolos inspeksi integritas dimensi (`inspectRenderedFile`), berkas dari cache internal disalin ke target direktori tujuan publik (`/storage/emulated/0/Movies/Uniquifier`).
     Jika penulisan ke direktori publik tersebut dibatasi oleh versi OS, metode ini otomatis melakukan fallback ke direktori Movies eksternal privat milik aplikasi (`getExternalStorageDirectories(type: StorageDirectory.movies)`), lalu memicu `MediaScannerService.scanFile` agar terdaftar di Android MediaStore dan muncul di galeri perangkat.
  3. **Garansi Cleanup Berkas Staged**:
     Blok `finally` menjamin bahwa setiap berkas sementara (`staged_out_*.mp4` dan `staged_*.mp4`) langsung dibersihkan dari penyimpanan sementara, mencegah kebocoran memori internal.
- **Hasil Kualitas**:
  - `flutter analyze --fatal-infos` -> **0 issues found**.
  - `flutter test` -> **112/112 passed** (bertambah 1 unit test baru memverifikasi staging isolasi storage).
  - Seluruh berkas di `lib/` patuh plafon `<= 393 LOC` (batas maksimal 400 LOC).
  - Seluruh fungsi helper `<= 40 baris`.

---

## 2. Alur Eksekusi Render Baru (Before vs After)

### Sebelum (Bermasalah pada Scoped Storage)
```text
ProcessScreen -> UniquifierProvider
  -> FfmpegService.processVideo()
       -> buildCommand(outputPath: "/storage/emulated/0/Movies/Uniquifier/UQ_xxx.mp4")
       -> FFmpegKit.execute()
            -> POSIX open("/storage/emulated/0/Movies/...") -> EACCES Permission Denied! (CRASH)
```

### Sesudah (Hardened Staged Execution)
```text
ProcessScreen -> UniquifierProvider
  -> FfmpegService.processVideo()
       -> finalDestPath = "/storage/emulated/0/Movies/Uniquifier/UQ_xxx.mp4"
       -> stagedOutputPath = "<app_cache>/staged_out_<timestamp>.mp4"
       -> buildCommand(outputPath: stagedOutputPath)
       -> FFmpegKit.execute()
            -> POSIX open("<app_cache>/...") -> Exit Code 0 (SUKSES)
       -> inspectRenderedFile(stagedOutputPath) -> Valid
       -> _exportStagedFile(stagedOutputPath, finalDestPath)
       -> MediaScannerService.scanFile(exportedPath) -> Terdaftar di MediaStore Galeri
       -> cleanup stagedOutputPath di internal cache
       -> Return final gallery path
```

---

## 3. Audit Izin Penyimpanan & AndroidManifest.xml

| Komponen Izin | Deklarasi Manifest | Fungsi / Target SDK | Status |
|---|---|---|---|
| `READ_MEDIA_VIDEO` | `<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />` | Android 13+ (API 33+) Media Picker & Reader | **TERVERIFIKASI** |
| `READ_EXTERNAL_STORAGE` | `<uses-permission ... android:maxSdkVersion="32" />` | Android 12 ke bawah (API <= 32) | **TERVERIFIKASI** |
| `WRITE_EXTERNAL_STORAGE` | `<uses-permission ... android:maxSdkVersion="29" tools:ignore="ScopedStorage" />` | Android 9 & 10 legacy compatibility | **TERVERIFIKASI** |
| `requestLegacyExternalStorage` | `android:requestLegacyExternalStorage="true"` | Fallback kompatibilitas Android 10 (API 29) | **TERVERIFIKASI** |

---

## 4. Hasil Verifikasi Pengujian

- `flutter analyze --fatal-infos` -> **0 issues found** (0 warnings, 0 infos).
- `flutter test` -> **112/112 passed**:
  - `test/ffmpeg_service_test.dart` -> 33/33 passed (termasuk pengujian isolasi `stageInputFile` dan validasi path).
  - `test/settings_service_test.dart` -> 13/13 passed.
  - `test/uniquifier_provider_test.dart` -> 21/21 passed.
  - `test/widget_test.dart` -> 13/13 passed.
  - Seluruh suite pengujian lainnya -> 32/32 passed.

---

## 5. MCP Evidence Appendix

| MCP Tool | Kueri / Parameter | Hasil & Metrik | Status Verifikasi |
|---|---|---|---|
| `mcp__codebase_memory_mcp__index_status` | Pre-task check | 1800 nodes, 4358 edges, status: ready | Terverifikasi |
| `mcp__codebase_memory_mcp__index_repository` | Mode `full` | Status: indexed, 1800 nodes, 4358 edges | Terverifikasi |
