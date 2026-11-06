# Laporan 27: Resolusi Komprehensif Reader Sheet Rendering & History Storage Management

## 1. Ringkasan Eksekutif
Berdasarkan temuan audit struktural HTML pada feed berita dan alur manajemen izin penyimpanan Android, implementasi Laporan 27 menuntaskan 3 perbaikan inti:
1. **Modul Berita**: Peningkatan ekstraksi DOM `ArticleReaderExtractor` dengan membersihkan selektor iklan/widget spesifik (`.banners`, `.pp-pixelmeter-widget`, `.freestar`, dll) serta pemanggilan reaktif via `WidgetsBinding.instance.addPostFrameCallback` di `MicrostockArticleSheet` dengan indikator progress indeterminasi dinamis.
2. **Modul Riwayat (Storage Permission & Deletion)**:
   - Penegakan dialog "Izin Kelola Berkas" yang hanya muncul tepat 1 kali pada instalasi awal menggunakan flag persisten `has_prompted_manage_storage` di `SharedPreferences`.
   - Eliminasi interupsi dialog izin saat aksi penghapusan per-item maupun batch.
   - Peningkatan ketahanan loop penghapusan massal (`deleteExportItemsDetailed`) dengan penanganan error independen per-berkas dan pelaporan jumlah berkas fisik yang riil terhapus.
3. **Modul Engine Output**: Jaminan sinkronisasi MediaStore melalui `MediaScannerService.scanFile` tetap terpelihara tanpa regresi.

---

## 2. Rincian Modul Berita

### A. Pre-Cleaning Selektor Tambahan pada `ArticleReaderExtractor`
Daftar selektor clutter dan iklan diperluas untuk mengeliminasi widget komersial yang menyela paragraf narasi:
- `aside`
- `.banners`, `.banners-desktop`, `.banners-below-header`
- `.pp-pixelmeter-widget`
- `script[src*="freestar"]`
Elemen-elemen ini dihapus sebelum kueri sekuensial `p, h2, h3, h4, ul, ol, blockquote` dijalankan, mencegah traversal berhenti prematur.

### B. Stateful On-Demand Fetch & Visual Feedback pada `MicrostockArticleSheet`
- Di `initState`, pemanggilan ekstraksi konten artikel penuh diikat melalui `WidgetsBinding.instance.addPostFrameCallback` jika artikel berasal dari sumber eksternal (RSS/Reddit) dan memuat tautan sumber (`sourceUrl`).
- Status ekstraksi `_isExtracting` secara dinamis mengubah bar kemajuan:
  ```dart
  LinearProgressIndicator(
    value: _isExtracting ? null : _scrollProgress,
    minHeight: 2.5,
    backgroundColor: progressTrack,
    valueColor: AlwaysStoppedAnimation<Color>(progressAccent),
  )
  ```
  Menghasilkan umpan balik visual animasi loading yang halus kepada pengguna saat mengekstrak konten penuh dari web publisher.

---

## 3. Rincian Modul Riwayat & Izin Penyimpanan

### A. Pembatasan Dialog Izin Penyimpanan 1 Kali via SharedPreferences
Pada `RecentHistoryScreen._checkStoragePermissionOnMount()`:
- Jika `HistoryService.hasStoragePermission()` sudah `true`, fungsi langsung berhenti (tanpa menampilkan dialog maupun snackbar).
- Jika belum `granted`, sistem memeriksa kunci `'has_prompted_manage_storage'` di `SharedPreferences`.
- Dialog izin modal hanya dimunculkan jika kunci belum diset ke `true`, kemudian kunci diset ke `true` agar tidak pernah muncul lagi pada peluncuran berikutnya.
- Pada `_showOpenSettingsPrompt()`, status izin diperiksa ulang terlebih dahulu untuk mencegah munculnya SnackBar peringatan yang tidak perlu jika izin sudah aktif.

### B. Penghapusan Dialog Izin dari Alur Tombol Delete
- Pemanggilan `_showStoragePermissionDialog` di dalam `_deleteItem` dan `_deleteSelectedItems` dihilangkan sepenuhnya.
- Pengguna yang menekan tombol delete langsung disambut oleh dialog konfirmasi penghapusan ("Delete Video?" atau "Hapus X Video?").
- Jika berkas fisik tidak dapat dihapus karena batasan sistem operasi, sistem memberikan notifikasi yang jelas tanpa memunculkan dialog modal yang mengganggu alur pengguna.

### C. Resilient Bulk Delete (`HistoryService.deleteExportItemsDetailed`)
- Iterasi setiap berkas dalam batch dibungkus dalam blok `try-catch` terisolasi:
  1. Memeriksa keberadaan file via `File.exists()`.
  2. Melakukan `File.delete()`.
  3. Memverifikasi fisik penghapusan via `!await File.exists()`.
  4. Memicu `MediaScannerService.scanFile` dan pembersihan cache thumbnail jika berhasil.
  5. Menambahkan path ke `deletedPaths`.
- UI `RecentHistoryScreen` hanya menghapus berkas yang terdaftar di `deletedPaths`, membersihkan set seleksi, dan mematikan mode seleksi secara aman.

---

## 4. Verifikasi Mutu & Kepatuhan Arsitektur

1. **Dart Format**:
   - `dart format --set-exit-if-changed lib/` exit 0 (0 berkas berubah).
2. **Dart Analyze**:
   - `flutter analyze` exit 0 (**0 issues found**).
3. **Flutter Tests**:
   - `flutter test` exit 0 (**176/176 tests passed**, 0 failures).
4. **Inviolable Constraints (Section 14 HANDOFF.md)**:
   - Modul `ffmpeg/**`, `uniquifier_provider.dart`, `uniquifier/**`, dan `test/**` tidak mengalami modifikasi apa pun.
   - Tetap offline-first tanpa telemetri luar atau API key berbayar.
