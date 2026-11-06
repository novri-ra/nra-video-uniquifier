# Execution Report 24: Implement MANAGE_EXTERNAL_STORAGE Permission for Android 11+ (Scoped Storage Fix)

**Status:** Completed  
**Date:** 2026-11-05  
**Type:** Feature & Permission Hardening  
**Target:** `android/app/src/main/AndroidManifest.xml`, `lib/core/services/history_service.dart`, `lib/features/history/screens/recent_history_screen.dart`

---

## 1. Problem Context & Root Cause Analysis

Pada pengujian fisik / emulator Android 11+ (misal crDroid Android 14 pada perangkat RMX1851):
1. Pengguna mengekspor video ke folder publik bersama: `/storage/emulated/0/Movies/Uniquifier/`.
2. Saat pengguna mencoba menghapus video dari layar *Recent Exports* (History), operasi `target.delete()` menghasilkan kegagalan I/O (`FileSystemException: Deletion failed, path = ... (OS Error: Permission denied, errno = 13)`).
3. Setelah Laporan 23 menerapkan *strict post-delete verification*, UI dengan benar mencegah penghapusan kosmetik palsu dan menampilkan peringatan kegagalan penghapusan fisik.
4. Di Android App Settings, izin yang aktif hanyalah *"Photos and videos"* (`READ_MEDIA_VIDEO`). Di bawah aturan Scoped Storage Android 11+ (API 30+), izin media tersebut hanya bersifat Read-Only untuk `dart:io File API` pada berkas yang dibuat oleh proses native (FFmpeg) di direktori publik bersama.
5. Logika sebelumnya di `HistoryService.hasStoragePermission()` mengecek `Permission.videos.isGranted` lebih dahulu. Karena izin video sudah aktif, method mengembalikan `true`, sehingga sistem tidak pernah meminta izin *"Akses Semua Berkas"* (`Permission.manageExternalStorage`).

---

## 2. Implementation Details

### A. AndroidManifest Configuration (`android/app/src/main/AndroidManifest.xml`)
Memastikan izin tingkat sistem dideklarasikan dengan benar:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" tools:ignore="ScopedStorage" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" tools:ignore="ScopedStorage" />
```
Atribut `android:requestLegacyExternalStorage="true"` pada tag `<application>` tetap dipertahankan untuk kompatibilitas mundur Android 10 (API 29).

### B. HistoryService Logic (`lib/core/services/history_service.dart`)
1. **Helper `isAndroid11OrHigher`:**
   Mendeteksi secara deterministik apakah perangkat berjalan di Android 11+ (API 30+) menggunakan regex parsing pada `Platform.operatingSystemVersion`.
2. **Method `hasStoragePermission()`:**
   - Pada Android 11+ (API 30+): Memprioritaskan dan memvalidasi `await Permission.manageExternalStorage.isGranted`.
   - Pada Android < 11 (API < 30): Mengevaluasi `await Permission.storage.isGranted`.
   - Di luar Android (host desktop / test runner): Mengembalikan `true` secara aman.
3. **Method `requestStoragePermission()`:**
   - Pada Android 11+: Memanggil `await Permission.manageExternalStorage.request()`, yang memicu peluncuran Intent sistem `Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION`.
   - Menambahkan verifikasi ulang pasca-request (`Permission.manageExternalStorage.isGranted`).
   - Pada Android < 11: Memanggil `await Permission.storage.request()`.

### C. UI & Lifecycle Experience (`lib/features/history/screens/recent_history_screen.dart`)
1. **Pembaruan Dialog Pop-Up Izin:**
   - Mengubah judul menjadi *"Izin Kelola Berkas"*.
   - Menyediakan penjelasan yang transparan kepada pengguna bahwa izin *"Akses Semua Berkas"* (All Files Access) diperlukan untuk menghapus dan mengelola video dari folder publik secara permanen.
2. **Lifecycle Observer (`WidgetsBindingObserver`):**
   - Mengintegrasikan `didChangeAppLifecycleState`: ketika pengguna mengaktifkan toggle switch "Allow access to manage all files" di Settings sistem lalu kembali ke aplikasi (`AppLifecycleState.resumed`), `_loadHistory()` dan status izin otomatis disinkronkan tanpa perlu restart layar.
3. **Fallback Navigasi Pengaturan:**
   - Menyediakan aksi `openAppSettings()` jika izin ditolak atau switch belum dinyalakan.

---

## 3. Inviolable Constraints Compliance (Section 14 HANDOFF.md)

- **Zero External Telemetry:** Tidak ada pengiriman data ke server eksternal.
- **Strictly Offline-First:** Seluruh evaluasi izin dan operasi I/O berjalan lokal pada level sistem operasi Android.
- **0 Paid API Keys:** Murni menggunakan standard APIs dan platform intent.

---

## 4. Verification Results

| Step | Command | Result |
|---|---|---|
| Git Status | `git status` | Clean whitelist modifications |
| Dart Format | `dart format --set-exit-if-changed` | Clean (0 unformatted) |
| Dart Analyze | `dart analyze` | Exit 0 (0 issues found!) |
| Flutter Test | `flutter test` | **Exit 0 (174/174 passed, 0 regression)** |
