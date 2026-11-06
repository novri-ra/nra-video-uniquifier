# Laporan 34: Rilis Produksi v1.0.2 (Build 3) & Clean Install Target Device RMX1851

**Tanggal:** 2026-11-05  
**Kategori:** release  
**Target:** SemVer 1.0.2+3, Merge main, Annotated Git Tag v1.0.2, Release APK Build, Clean Install Target Device (Realme 3 Pro - RMX1851)  
**Status:** Selesai, 100% Terverifikasi (versionName=1.0.2, versionCode=3)

---

## 1. Ringkasan Eksekutif

Rilis patch version **v1.0.2 (Build 3)** untuk **NRA Video Uniquifier** menuntaskan kendala izin penyimpanan (storage permission) secara tuntas pada Android 14 dan menyinkronkan status izin secara real-time saat aplikasi di-resume:
1. **Real-Time Lifecycle Observer (`RecentHistoryScreen`):**
   - Menghubungkan `WidgetsBindingObserver` pada `_RecentHistoryScreenState`.
   - Mengimplementasikan `_verifyStoragePermissionOnResume()` saat `AppLifecycleState.resumed` untuk memverifikasi `Permission.manageExternalStorage.isGranted` secara instan ketika pengguna kembali dari halaman Pengaturan Sistem (Settings).
   - Memicu pembaruan state antarmuka (`setState(() {})`) dan memuat ulang berkas riwayat (`_loadHistory()`).
2. **Integrasi `device_info_plus` & Deteksi Versi SDK Dinamis:**
   - Menambahkan dependensi `device_info_plus: ^12.4.0` pada `pubspec.yaml`.
   - Menyediakan `HistoryService.getAndroidSdkVersion()` menggunakan `DeviceInfoPlugin().androidInfo.version.sdkInt` dengan fallback cerdas berbasis regex pada `Platform.operatingSystemVersion`.
3. **Deklarasi Izin Media Granular Android 13/14:**
   - Mendaftarkan izin granular `READ_MEDIA_VIDEO`, `READ_MEDIA_IMAGES`, dan `READ_MEDIA_AUDIO` pada `android/app/src/main/AndroidManifest.xml` berdampingan dengan `MANAGE_EXTERNAL_STORAGE` dan izin legacy bertarget `maxSdkVersion`.

---

## 2. Alur Eksekusi Rilis

1. **Pembaruan Versi & Changelog**:
   - `pubspec.yaml`: Versi dinaikkan menjadi `1.0.2+3`.
   - `CHANGELOG.md`: Ditambahkan bagian rilis `## [1.0.2] - 2026-11-05` dan pembukaan `## [Unreleased]` baru di atasnya:
     * `feat(storage): implement WidgetsBindingObserver for real-time permission sync on resume`
     * `feat(storage): integrate device_info_plus for dynamic Android SDK version detection`
     * `fix(manifest): register granular media permissions (READ_MEDIA_VIDEO, READ_MEDIA_IMAGES, READ_MEDIA_AUDIO)`
2. **Kompilasi Pengujian Kualitas**:
   - `flutter analyze --no-pub`: **0 issues found** (exit code 0).
   - `flutter test`: **176/176 tests passed** (exit code 0, 100% pass rate).
3. **Git Branching, Merge & Tagging**:
   - Commit di branch `development`: `chore(release): bump version to 1.0.2+3` (`9c4dc6d`).
   - Merge `development` ke `main` menggunakan strategi `ort` (`67dee63`).
   - Pembuatan annotated tag: `git tag -a v1.0.2 -m "Release v1.0.2 - Android 14 Storage Permission & Real-Time Lifecycle Sync"`.
   - Push commit dan tags ke remote origin: `git push origin main --tags` dan kembali ke branch `development`.
4. **Kompilasi APK Produksi**:
   - Perintah: Gradle release build via daemon (`assembleRelease`).
   - Output: `build/app/outputs/flutter-apk/app-release.apk` (243.8 MB).
5. **Clean Install Target Device (Realme 3 Pro / RMX1851)**:
   - Identifikasi perangkat ADB: `5e599699` (`ro.product.model = RMX1851`).
   - Pencopotan bersih: `adb -s 5e599699 uninstall id.novrira.videouniquifier` -> **Success**.
   - Pemasangan APK rilis: `adb -s 5e599699 install -r build/app/outputs/flutter-apk/app-release.apk` -> **Performing Streamed Install -> Success**.

---

## 3. Bukti Verifikasi Pasca-Instalasi

### A. Verifikasi Dumpsys Paket di Perangkat Android RMX1851
```text
$ adb -s 5e599699 shell dumpsys package id.novrira.videouniquifier | Select-String "version"

    versionCode=3 minSdk=24 targetSdk=36
    minExtensionVersions=[]
    versionName=1.0.2
    apkSigningVersion=2
```

### B. Verifikasi Git Tag
```text
$ git tag -l
v1.0.0
v1.0.1
v1.0.2
v1.4.0
```

### C. Status Git Branch
- Branch aktif saat ini: `development`.
- Remote origin tersinkronisasi penuh pada `main` dan `development`.

---

## 4. Kesimpulan

Rilis produksi patch version **v1.0.2 (Build 3)** telah berhasil diselesaikan secara menyeluruh. Seluruh guardrails dipenuhi (strictly offline-first, 0 external telemetry, 0 paid API keys), seluruh 176 unit/widget tests lulus 100%, 0 issues pada static analysis, dan berkas biner rilis telah terpasang serta diverifikasi aktif pada perangkat fisik target (Realme 3 Pro - RMX1851).
