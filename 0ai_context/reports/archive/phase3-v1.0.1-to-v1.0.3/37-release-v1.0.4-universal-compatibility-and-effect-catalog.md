# Laporan 37: Rilis Produksi v1.0.4 (Build 5) & Universal Android Compatibility Pass

**Tanggal:** 2026-11-06  
**Kategori:** release  
**Target:** SemVer 1.0.4+5, Merge main, Annotated Git Tag v1.0.4, Release APK Build, Clean Install Target Device (Realme 3 Pro - RMX1851)  
**Status:** Selesai, 100% Terverifikasi (versionName=1.0.4, versionCode=5)

---

## 1. Ringkasan Eksekutif

Rilis patch version **v1.0.4 (Build 5)** untuk **NRA Video Uniquifier** menghadirkan arsitektur Universal Android Compatibility lintas spektrum versi OS (Android 7.0 / API 24 hingga Android 16 / targetSdk 36) serta meluncurkan antarmuka Filter Catalog Selector interaktif di layar Studio/Pemrosesan:
1. **Universal Android Manifest & Permission Hierarchy:**
   - Menyelaraskan izin penyimpanan bertingkat: `READ_EXTERNAL_STORAGE` (maxSdkVersion 32) dan `WRITE_EXTERNAL_STORAGE` (maxSdkVersion 29) untuk OS lawas.
   - Mengintegrasikan scoped media modern untuk Android 13-16: `READ_MEDIA_VIDEO`, `READ_MEDIA_IMAGES`, dan `READ_MEDIA_AUDIO`.
   - Mengaktifkan permission notifikasi runtime Android 13+: `POST_NOTIFICATIONS`.
   - Menambahkan deklarasi foreground service spesifik Android 14+: `FOREGROUND_SERVICE` dan `FOREGROUND_SERVICE_DATA_SYNC`.
   - Mendaftarkan service `com.dexterous.flutterlocalnotifications.ForegroundService` dengan atribut wajib Android 14 `android:foregroundServiceType="dataSync"` dan `android:exported="false"`.
2. **Runtime Notification Logic & AndroidNotificationChannel Adaptation:**
   - Mengimplementasikan runtime request `requestNotificationsPermission()` via `AndroidFlutterLocalNotificationsPlugin` sebelum memulai render dan saat bootstrap aplikasi.
   - Mendaftarkan channel resmi `video_processing_channel` ('Video Processing') dengan `Importance.high`, sound, dan vibration aktif, berdampingan dengan `nra_uniquifier_channel_v2` dan `nra_video_processing_channel`.
   - Menyesuaikan notifikasi penyelesaian render dengan `Priority.high`, `Importance.high`, serta icon default valid `@mipmap/ic_launcher`.
3. **ProGuard / R8 Shrinking & Obfuscation Keep Rules:**
   - Mengamankan seluruh kelas and member `com.dexterous.flutterlocalnotifications.**` dari stripping R8.
   - Menambahkan keep rules untuk `androidx.core.app.NotificationCompat**` dan `androidx.core.app.NotificationManagerCompat`.
4. **Visual Filter Catalog Selector (`VisualEffectSelectorCard`):**
   - Komponen horizontal scrollable carousel yang memuat 7 preset visual: None, Blurred Canvas, Temporal Motion Echo, RGB Temporal Split, Dreamy Bloom, 16mm Nostalgia, dan Dynamic Grain.
   - Dilengkapi dynamic contextual sub-controls: slider foreground scale untuk Blurred Canvas (70%-100%) dan slider clone delay untuk Motion Echo (0.05s-0.40s).
   - Terintegrasi dengan debounced single-frame preview FFmpeg instan saat kartu filter dipilih.

---

## 2. Alur Eksekusi Rilis

1. **Pembaruan Versi & Changelog**:
   - `pubspec.yaml`: Versi dinaikkan menjadi `1.0.4+5`.
   - `CHANGELOG.md`: Ditambahkan bagian rilis `## [1.0.4] - 2026-11-06` dan pembukaan `## [Unreleased]` baru di atasnya.
2. **Kompilasi Pengujian Kualitas**:
   - `dart format --set-exit-if-changed lib/ test/`: **0 changed** (exit code 0).
   - `flutter analyze`: **0 issues found** (exit code 0).
   - `flutter test`: **206/206 tests passed** (exit code 0, 100% pass rate).
3. **Git Branching, Merge & Tagging**:
   - Commit di branch `development`: `chore(release): bump version to 1.0.4+5 with universal android compatibility and visual effect catalog` (`c5ddb4e`).
   - Merge `development` ke `main` menggunakan strategi `ort` (`168f219`).
   - Pembuatan annotated tag: `git tag -a v1.0.4 -m "Release v1.0.4 - Universal Android Compatibility, Visual Effect Catalog, and High-Fidelity Preview"`.
   - Push commit dan tags ke remote origin: `git push origin development main --tags`.
4. **Kompilasi APK Produksi**:
   - Perintah: `flutter build apk --release`.
   - Output: `build/app/outputs/flutter-apk/app-release.apk` (232.2 MB).
5. **Clean Install Target Device (Realme 3 Pro / RMX1851)**:
   - Identifikasi perangkat ADB: `5e599699` (`ro.product.model = RMX1851`).
   - Pencopotan bersih: `adb -s 5e599699 uninstall id.novrira.videouniquifier` -> **Success**.
   - Pemasangan APK rilis: `adb -s 5e599699 install -r build/app/outputs/flutter-apk/app-release.apk` -> **Performing Streamed Install -> Success**.

---

## 3. Bukti Verifikasi Pasca-Instalasi

### A. Verifikasi Dumpsys Paket di Perangkat Android RMX1851
```text
$ adb -s 5e599699 shell dumpsys package id.novrira.videouniquifier | Select-String "version"

    versionCode=5 minSdk=24 targetSdk=36
    minExtensionVersions=[]
    versionName=1.0.4
    apkSigningVersion=2
```

### B. Verifikasi Git Tag
```text
$ git tag -l
v1.0.0
v1.0.1
v1.0.2
v1.0.3
v1.0.4
v1.4.0
```

### C. Verifikasi Pengujian Unit & Statis
- `flutter analyze`: No issues found!
- `flutter test`: 206/206 passed.
