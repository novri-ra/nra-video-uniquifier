# Laporan 46: Penyesuaian Proporsi Blurred Canvas Inset 0.95 dan Pemulihan Eksekusi Latar Belakang & Notifikasi Notifikasi Suara

## 1. Executive Summary & Verdict

- **Tujuan**:
  1. Menyesuaikan proporsi kanvas buram (*blurred canvas*) dari faktor `0.88` ke `0.95` dan menghaluskan radius blur (`boxblur=luma_radius=min(h\,w)/35`) untuk menghasilkan bingkai latar belakang berestetika tinggi tanpa mengecilkan video utama secara berlebihan.
  2. Melakukan audit komprehensif dan perbaikan pada sistem notifikasi progres, penyelesaian dengan suara (*completion sound alert*), serta ketahanan eksekusi di latar belakang (*background execution resilience*) pada perangkat fisik Android (khususnya Android 13+ / API 33+).
- **Hasil Eksekusi**:
  - **Skala Foreground Canvas Diperbarui**: `scale=w=trunc(iw*0.95/2)*2:h=trunc(ih*0.95/2)*2[main]` dengan pembulatan macroblock genap dan chaining pad stream `[blurred][main]overlay=(W-w)/2:(H-h)/2[outv]`.
  - **Radius Boxblur Disempurnakan**: Menggunakan pembagi 35 (`boxblur=luma_radius=min(h\,w)/35:luma_power=2[blurred]`), menghasilkan efek blur halus yang menyatu natural.
  - **Registrasi Channel Android Notifikasi Eksplisit**: `NotificationService.init()` kini mendaftarkan `video_process_channel` (Importance.low, tanpa suara/getar, ongoing: true) dan `video_complete_channel` (Importance.high, playSound: true, enableVibration: true) secara eksplisit via `createNotificationChannel` pada runtime Android.
  - **Logika Throttling Diperbaiki**: Pembaruan progres 0% dan 100% dipastikan selalu menembus batas throttling waktu/persentase (`!force && clamped != 0 && clamped != 100`), menjamin bar progres muncul seketika saat render dimulai dan hilang tepat waktu saat selesai.
  - **Suara Penyelesaian Tersambung ke Pengaturan**: `showCompleteNotification` membaca setelan pengguna melalui `SettingsService.getNotificationSound()` (default `true`) untuk menentukan flag `playSound`.
  - **Siklus Hidup Main App**: `lib/main.dart` dikonfigurasi `async` dan melakukan `await` pada `NotificationService.init()` serta `NotificationService.requestPermission()` agar dialog izin `POST_NOTIFICATIONS` langsung tampil saat peluncuran awal.
- **Kualitas & Arsitektur**:
  - `flutter analyze --fatal-infos` -> **0 issues found**.
  - `flutter test` -> **107/107 passed** (0 gagal, 0 di-skip).
  - Seluruh 36 berkas di `lib/` patuh plafon `<= 400 LOC` (berkas terpanjang 381 LOC).
  - Seluruh fungsi `<= 40 baris`.

---

## 2. Sintaks FFmpeg Verbatim Blurred Canvas Pasca-Penyesuaian

```bash
[0:v]split=2[bg][fg];[bg]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=luma_radius=min(h\,w)/35:luma_power=2[blurred];[fg]scale=w=trunc(iw*0.95/2)*2:h=trunc(ih*0.95/2)*2[main];[blurred][main]overlay=(W-w)/2:(H-h)/2[outv];[outv]setpts=0.9723*PTS,eq=brightness=-0.0034:contrast=1.0041:saturation=0.9982,noise=alls=4:allf=t+u,scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p
```

---

## 3. Matriks Perubahan & Audit Pemulihan

| Komponen | Status Sebelum Audit | Perbaikan / Status Terpasang | Status Verifikasi |
|---|---|---|---|
| **Canvas Scale Factor** | `0.88` (terlalu kecil, tepi blur terlalu tebal) | `0.95` (proporsi ramping, video fokus di tengah) | **TERVALIDASI** (`test/ffmpeg_service_test.dart`) |
| **Blur Radius Divisor** | `/20` (blur terlalu agresif / washed-out) | `/35` (bokeh halus berestetika tinggi) | **TERVALIDASI** (`test/ffmpeg_service_test.dart`) |
| **Pendaftaran Channel Android** | Mengandalkan deklarasi implisit per-notifikasi | Terdaftar eksplisit di `init()` via `createNotificationChannel` | **TERVALIDASI** (`NotificationService.init()`) |
| **Logika Throttling Progres** | Memblokir perubahan < 5% / < 1000ms secara ketat | 0% dan 100% selalu tembus tanpa terhambat throttling | **TERVALIDASI** (`test/notification_service_test.dart`) |
| **Suara Notifikasi Selesai** | Nilai hardcoded `playSound: true` | Terkoneksi dinamis ke `SettingsService.getNotificationSound()` | **TERVALIDASI** (`NotificationService.showCompleteNotification`) |
| **Inisialisasi Permisi Startup** | Panggilan tanpa `await` di `main.dart` | `main()` async dengan `await init()` & `await requestPermission()` | **TERVALIDASI** (`lib/main.dart`) |
| **Manifest Permissions** | Lengkap di `AndroidManifest.xml` | `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE`, `WAKE_LOCK` aktif | **TERVALIDASI** (`AndroidManifest.xml`) |

---

## 4. Hasil Pengujian Otomatis

- `flutter analyze --fatal-infos` -> **0 issues found**.
- `flutter test`:
  - `test/ffmpeg_service_test.dart` -> **28/28 passed** (memvalidasi canvas 0.95 inset dan boxblur /35).
  - `test/notification_service_test.dart` -> **6/6 passed** (memvalidasi init, checkPermissionStatus, ongoing progress, bypass throttling 0%/100%, cancel, dan high-importance complete notification).
  - Total pengujian seluruh aplikasi -> **107/107 passed**.

---

## 5. MCP Evidence Appendix

| MCP Tool | Kueri / Parameter | Hasil & Metrik | Status Verifikasi |
|---|---|---|---|
| `mcp__codebase_memory_mcp__index_status` | Pre-task check | 1711 nodes, 4127 edges, status: ready | Terverifikasi |
| `mcp__codebase_memory_mcp__index_repository` | Mode `full` | Status: indexed, 1711 nodes, 4127 edges | Terverifikasi |
