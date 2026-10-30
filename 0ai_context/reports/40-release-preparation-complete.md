# Laporan 40: Persiapan Rilis Otomatis Lengkap (Full Automated Release Preparation)

## 1. Executive Verdict

- **Preflight (V54–V58)**: Berhasil mengidentifikasi kesenjangan pra-rilis: `applicationId` masih menggunakan format default (`com.example.*`), keystore rilis belum ada, dan ikon peluncur masih berupa template bawaan.
- **Perbaikan Terpasang (FIX 14–18)**:
  - **FIX 14**: `applicationId` dan `namespace` diperbarui permanen menjadi `id.novrira.videouniquifier`. File Kotlin dipindahkan ke package path baru, dan seluruh referensi MethodChannel di Dart dan Android disinkronkan (0 residual matches).
  - **FIX 15**: Keystore rilis 2048-bit RSA (`release-keystore.jks`) dibuat dengan kata sandi acak 32 karakter yang aman, konfigurasi penandatanganan Gradle diotomatisasi via `key.properties`, dan seluruh kredensial dirahasiakan dalam `.gitignore`.
  - **FIX 16**: Label aplikasi dipastikan berbunyi `NRA Video Uniquifier`.
  - **FIX 17**: Catatan rilis v1.0.0 diperbarui menjadi ringkas (368 karakter) dan bebas jargon teknis.
  - **FIX 18**: Deskripsi lengkap Play Store diperbarui mencakup spesifikasi kebutuhan sistem dan catatan privasi on-device (2.694 karakter).
- **Gerbang Kualitas (Quality Gates)**:
  - `flutter analyze --fatal-infos` -> **0 issues**.
  - `flutter test` -> **100 passed**, **0 failed**, **0 skipped**.
  - `flutter build appbundle --release` -> Sukses menghasilkan berkas produksi `app-release.aab` (130.6 MB).
  - `jarsigner -verify` -> **LULUS** (`jar verified.`, ditandatangani oleh `CN=NRA Video Uniquifier, OU=Dev, O=Novrira, L=Unknown, ST=Unknown, C=ID`).

---

## 2. Tabel Preflight (V54 – V58)

| ID | Item | Status Sebelum Perbaikan | Vonis | Catatan |
|---|---|---|---|---|
| **V54** | `applicationId` saat ini | `com.example.nra_video_uniquifier` di `build.gradle.kts:29` | `com.example.* — MUST CHANGE` | Wajib diganti sebelum unggah Play Store pertama |
| **V55** | Keberadaan Keystore / `key.properties` | `no key.properties`, 0 berkas `.jks`/`.keystore` | `absent — will generate` | Dibutuhkan untuk penandatanganan rilis resmi |
| **V56** | Versi Aplikasi | `pubspec.yaml` memuat `version: 1.0.0+1` | `valid (1.0.0+1)` | VersionCode: 1 (memenuhi syarat >= 1) |
| **V57** | Status Ikon Peluncur | `mipmap-*/ic_launcher.png` berkisar antara 442B hingga 1443B (< 5KB) | `default Flutter placeholder (<5KB)` | Bukan pemblokir teknis; dapat dipercantik pada rilis berkala |
| **V58** | `android:label` (Display Name) | `android:label="NRA Video Uniquifier"` di `AndroidManifest.xml:16` | `matches Play Store title` | Sesuai dengan spesifikasi listing Play Store |

---

## 3. Ringkasan Perbaikan (Fix Summary Table)

| Fix | Berkas | Sebelum | Sesudah |
|---|---|---|---|
| **FIX 14** | `android/app/build.gradle.kts` | `applicationId = "com.example.nra_video_uniquifier"`<br>`namespace = "com.example.nra_video_uniquifier"` | `applicationId = "id.novrira.videouniquifier"`<br>`namespace = "id.novrira.videouniquifier"` |
| **FIX 14** | `android/app/src/main/kotlin/` | `com/example/nra_video_uniquifier/MainActivity.kt` | `id/novrira/videouniquifier/MainActivity.kt` (Package `id.novrira.videouniquifier`) |
| **FIX 14** | `lib/core/services/media_scanner_service.dart`<br>`test/media_scanner_service_test.dart` | Channel: `com.example.nra_video_uniquifier/media_scanner` | Channel: `id.novrira.videouniquifier/media_scanner` |
| **FIX 15** | `android/key.properties`<br>`android/release-keystore.jks`<br>`android/release-keystore-password.txt` | Tidak ada (belum dibuat) | Dibuat otomatis: Keystore RSA 2048-bit, validitas 10.000 hari, kata sandi acak 32 karakter |
| **FIX 15** | `.gitignore` | `key.properties`, `*.jks`, `*.keystore` | Ditambahkan: `android/key.properties`, `android/release-keystore-password.txt`, `*password*.txt` |
| **FIX 16** | `android/app/src/main/AndroidManifest.xml` | `android:label="NRA Video Uniquifier"` | Divalidasi dan dipertahankan konsisten |
| **FIX 17** | `docs/play_store_metadata/release_notes_en_US.txt` | Catatan teknis dengan disclaimer internal (755 B) | Versi ramah pengguna bebas jargon (368 karakter) |
| **FIX 18** | `docs/play_store_metadata/listing_details.md` | Tanpa sub-seksi System Requirements & Compatibility | Ditambahkan spesifikasi RAM, OS, dan privasi on-device (2.694 karakter) |

---

## 4. Artefak Keystore Produksi (Sangat Kritis untuk Cadangan Pengembang)

Berkas-berkas ini disimpan secara lokal di mesin pengembang dan **TIDAK DILACAK OLEH GIT** untuk menjaga kerahasiaan:

- **Path Keystore**: `android/release-keystore.jks` (Ukuran: 2.770 bytes)
- **Path File Kata Sandi**: `android/release-keystore-password.txt` (32 karakter acak alfanumerik)
- **Alias Kunci**: `nra-release`
- **Distinguished Name (DName)**: `CN=NRA Video Uniquifier, OU=Dev, O=Novrira, L=Unknown, ST=Unknown, C=ID`
- **Masa Berlaku**: 10.000 hari (~ hingga tahun 2054)
- **Fingerprint SHA-256**:
  ```
  CB:40:7A:A2:B3:88:08:BC:6D:A2:90:62:5D:98:D8:53:A4:92:40:3F:BD:B9:A7:3E:AA:AA:53:11:62:EE:21:A9
  ```
- **Fingerprint SHA-1**:
  ```
  D5:E7:31:49:7B:92:2B:99:B7:A1:DF:F3:1F:55:AD:1E:CA:14:56:E9
  ```

---

## 5. Artefak AAB Deliverable (Siap Diunggah ke Play Console)

- **Path Berkas**: `build/app/outputs/bundle/release/app-release.aab`
- **Ukuran Berkas**: **136.934.497 bytes (~130,6 MB)**
- **Application ID Terverifikasi**: `id.novrira.videouniquifier`
- **Subjek Sertifikat Penandatangan**: `CN=NRA Video Uniquifier, OU=Dev, O=Novrira, L=Unknown, ST=Unknown, C=ID`
- **Kutipan Verbatim Bukti `jarsigner`**:
  ```
  jar verified.
  X.509, CN=NRA Video Uniquifier, OU=Dev, O=Novrira, L=Unknown, ST=Unknown, C=ID
  ```
- **Vonis Penandatanganan**: `signed with release key` (Bukan debug key!).

---

## 6. Verifikasi Karakter Metadata Play Store

| Jenis Metadata | Batas Maksimum | Panjang Aktual | Status Kepatuhan |
|---|---|---|---|
| **App Title** | 30 karakter | 20 karakter (`NRA Video Uniquifier`) | **LULUS** (Slack: 10) |
| **Short Description** | 80 karakter | 66 karakter | **LULUS** (Slack: 14) |
| **Full Description** | 4.000 karakter | 2.694 karakter | **LULUS** (Slack: 1.306) |
| **Release Notes** | 500 karakter | 368 karakter | **LULUS** (Slack: 132) |

---

## 7. Dua Langkah Manual Wajib untuk Pengembang

Bagian ini **TIDAK DAPAT DIOTOMATISASI** oleh AI karena memerlukan akses akun Google pribadi dan penyimpanan fisik:

### Langkah 1: BACKUP KUNSI SEKARANG (Wajib & Permanen)
> ⚠️ **PERINGATAN KERUSAKAN PERMANEN**:
> Jika Anda kehilangan file `android/release-keystore.jks` atau kata sandi di `android/release-keystore-password.txt`, Google Play Store **TIDAK AKAN PERNAH BISA MEMPERBARUI APLIKASI ANDA LAGI**. Anda akan terpaksa mengganti `applicationId` dan memublikasikan ulang sebagai aplikasi baru dari nol serta kehilangan seluruh basis pengguna Anda.
>
> **Tindakan**:
> 1. Buka folder `C:\Users\Administrator\Saved Games\_Project\nra_video_uniquifier\android\`.
> 2. Salin file `release-keystore.jks` dan `release-keystore-password.txt` ke pengelola kata sandi terenkripsi (Bitwarden, 1Password, KeePass) ATAU simpan di flashdisk offline cadangan yang aman.

### Langkah 2: UPLOAD KE GOOGLE PLAY CONSOLE
> 1. Buka peramban dan login ke [Google Play Console](https://play.google.com/console).
> 2. Pilih **Create App** (Nama: `NRA Video Uniquifier`, Default language: `English (US)`, Type: `App`, Free).
> 3. Masuk ke menu **Testing > Internal testing** (atau Closed testing).
> 4. Buat release baru, lalu unggah berkas bundle:
>    `C:\Users\Administrator\Saved Games\_Project\nra_video_uniquifier\build\app\outputs\bundle\release\app-release.aab`
> 5. Salin teks dari `docs/play_store_metadata/release_notes_en_US.txt` ke bagian Release Notes.
> 6. Salin teks dari `docs/play_store_metadata/listing_details.md` ke menu Store Presence > Main store listing (Title, Short description, Full description).
> 7. Simpan dan ajukan rilis untuk peninjauan (Review).

---

## 8. Panduan Pasca-Unggah untuk Pengembang (14 Hari Pertama)

- **Hari ke-1 (H+1)**: Pantau laporan crash di Play Console (Android Vitals). Pasang filter khusus untuk kata kunci `ffmpegkit` dan `mediacodec`.
- **Hari ke-3 (H+3)**: Jika tingkat crash (crash rate) melampaui batas ambang Google (> 1,09%), segera rilis pembaruan v1.0.1 dengan mengubah setelan bawaan `hardwareAcceleration` menjadi `false` di `SettingsService`.
- **Hari ke-7 (H+7)**: Kumpulkan feedback dari pengguna nyata dengan variasi chipset ARM64 (terutama Qualcomm Snapdragon, MediaTek Dimensity, dan Samsung Exynos).
- **Hari ke-14 (H+14)**: Jika metrik stabilitas ANR dan crash rate stabil di bawah 0,2%, promosikan rilis dari Internal/Closed Testing ke jalur **Production**.

---

## 9. Pengakuan Jujur (Honest Admission)

1. **Yang Berhasil Diotomatisasi 100%**:
   - Pembaruan permanen `applicationId` menjadi `id.novrira.videouniquifier` tanpa menyisakan jejak `com.example.*` pada kode sumber.
   - Pembangkitan keystore rilis RSA 2048-bit dan injeksi otomatis ke pipeline Gradle release build.
   - Kompilasi Android App Bundle (AAB) berukuran 130,6 MB dengan optimasi R8 shrinker dan penandatanganan sertifikat rilis yang valid (`jar verified.`).
   - Kelulusan seluruh 100 unit & widget test serta 0 issue pada static analysis.
2. **Yang Tetap Manual**:
   - Pencadangan fisik berkas keystore dan kata sandi rahasia.
   - Login dan pengunggahan AAB ke dashboard web Google Play Console (memerlukan akun pengembang Google berbayar dan 2FA).
3. **Yang Belum Teruji Perangkat Fisik**:
   - Verifikasi performa akselerasi hardware MediaCodec pada silikon fisik ARM64 tetap berstatus caveat terbuka (Path A) sebagaimana disepakati pada Sprint 10.
