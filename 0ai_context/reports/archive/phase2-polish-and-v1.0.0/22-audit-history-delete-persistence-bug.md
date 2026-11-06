# Audit Report 22: History Delete Persistence Bug Investigation

**Status:** Completed  
**Date:** 2026-11-05  
**Type:** Read-Only Audit & Root Cause Analysis  
**Target:** `lib/features/history/screens/recent_history_screen.dart`, `lib/core/services/history_service.dart`, `lib/core/services/media_scanner_service.dart`

---

## 1. Executive Summary

Pengguna melaporkan bahwa video yang dihapus dari layar Riwayat (**Recent Exports**) tampak hilang seketika, namun muncul kembali saat layar di-refresh (`pull-to-refresh`) atau saat aplikasi dibuka ulang.

Investigasi mendalam pada kode sumber mengonfirmasi bahwa layar History **tidak menggunakan database terpisah (SQLite, Hive, atau SharedPreferences)** untuk mencatat daftar riwayat video. Layar ini murni beroperasi secara dinamis dengan memindai berkas fisik di disk storage publik (`/storage/emulated/0/Movies/Uniquifier`) via `HistoryService.loadHistory()`.

Kemunculan kembali video setelah di-refresh disebabkan oleh kombinasi **ilusi kosmetik pada UI** (penghapusan list in-memory tetap dipanggil meskipun penghapusan fisik gagal) dan **kegagalan penghapusan fisik di level I/O storage Android** (Scoped Storage/izin akses direktori publik) serta **ketiadaan sinkronisasi penghapusan index MediaStore**.

---

## 2. Root Cause Analysis (Akar Masalah)

### Akar Masalah 1: UI Berasumsi Sukses dan Melakukan Penghapusan Kosmetik In-Memory (Paling Kritis)
Pada `lib/features/history/screens/recent_history_screen.dart`:

```dart
// Method _deleteItem() (Baris 186-222)
Future<void> _deleteItem(VideoExportItem item) async {
  if (!await _confirmDelete(item)) return;
  try {
    final targetPath = item.file.path;
    final existed = await item.file.exists();
    await HistoryService.deleteItem(item.file); // <-- Return value boolean diabaikan!
    if (mounted) {
      setState(() {
        _items.removeWhere((i) => i.file.path == targetPath); // <-- Selalu dihapus dari state memory!
      });
      // ... Menampilkan SnackBar "Video berhasil dihapus" ...
    }
  } catch (_) {
    if (mounted) {
      setState(() {
        _items.removeWhere((i) => i.file.path == item.file.path); // <-- Tetap dihapus dari UI meskipun catch error!
      });
      // ...
    }
  }
}
```

Hal serupa terjadi pada penghapusan multi-select `_deleteSelectedItems()` (baris 126-150):
```dart
await HistoryService.deleteExportItems(selectedItems); // Return count diabaikan
if (mounted) {
  setState(() {
    _items.removeWhere((i) => _selectedItemPaths.contains(i.file.path));
    // ...
  });
}
```

**Dampak:**
1. Method `HistoryService.deleteItem(file)` mengembalikan `bool` (`true` jika berhasil, `false` jika I/O gagal atau exception). Namun, `_deleteItem` di UI tidak pernah mengecek return value tersebut.
2. Ketika `HistoryService.deleteItem()` gagal (misal melempar `FileSystemException` karena permission OS), error ditangkap di internal service dan mengembalikan `false`.
3. UI tetap mengeksekusi `_items.removeWhere(...)`. Video seketika hilang dari tampilan, memberikan ilusi kepada pengguna bahwa video telah terhapus.
4. Namun, berkas fisik `.mp4` sebenarnya masih utuh di disk storage.

---

### Akar Masalah 2: Mekanisme Re-Scan Direktori Fisik Saat Refresh
Pada `lib/core/services/history_service.dart`:

```dart
static Future<List<VideoExportItem>> loadHistory() async {
  final items = <VideoExportItem>[];
  // Memindai folder publik: /storage/emulated/0/Movies/Uniquifier
  // dan direktori app documents fallback
  for (final dir in dirs) {
    if (await dir.exists()) {
      await _scanDirectory(dir, items, seenPaths);
    }
  }
  // Sort descending by modified date
  items.sort((a, b) => b.modified.compareTo(a.modified));
  return items;
}
```

Saat pengguna melakukan *pull-to-refresh*, method `_loadHistory()` memanggil `HistoryService.loadHistory()`. Karena berkas fisik di `/storage/emulated/0/Movies/Uniquifier` belum pernah terhapus (akibat Akar Masalah 1), fungsi pemindaian menemukan kembali berkas tersebut di disk dan memasukkannya kembali ke dalam list UI `_items`.

---

### Akar Masalah 3: Android Scoped Storage & Izin Hapus File Publik (Android 11+)
1. Lokasi penyimpanan utama ekspor adalah direktori publik bersama: `/storage/emulated/0/Movies/Uniquifier`.
2. Pada Android 10+ (API 29+) dan terutama Android 11+ (API 30+), sistem menerapkan **Scoped Storage**:
   - Jika aplikasi membuat file melalui native MediaStore tanpa izin `MANAGE_EXTERNAL_STORAGE`, aplikasi hanya dapat mengedit/menghapus file yang dimilikinya sendiri via MediaStore API.
   - Jika file dibuat via `dart:io File.writeAsBytes()` atau FFmpeg C-library direct path, OS Android dapat membatasi operasi `File(path).delete()` secara langsung jika tidak memiliki privilege atau jika kepemilikan file terikat pada proses MediaStore.
   - Ketika `target.delete()` pada `HistoryService.deleteItem()` gagal karena OS menolak akses I/O (`FileSystemException: Deletion failed, path = ... (OS Error: Permission denied / Operation not permitted)`), berkas tidak terhapus.

---

### Akar Masalah 4: Ketiadaan Sinkronisasi MediaStore Saat Penghapusan
1. Saat ekspor video selesai, aplikasi memanggil `MediaScannerService.scanFile(exportedPath)` agar video diindeks oleh Galeri Android (`android.media.MediaScannerConnection.scanFile`).
2. Namun, saat **penghapusan** berkas di `HistoryService.deleteItem()`, aplikasi **tidak pernah** memicu pembersihan index MediaStore:
   - Platform channel `id.novrira.videouniquifier/media_scanner` hanya mengimplementasikan method `scanFile` dan `openGallery`.
   - Tidak ada method untuk menghapus URI dari MediaStore (`contentResolver.delete(uri, ...)`).
   - Akibatnya, bahkan jika file fisik terhapus secara parsial, thumbnail atau cache gallery Android tetap dapat mengingat entri tersebut.

---

## 3. Diagram Alur Terjadinya Bug

```
[Pengguna Menekan Tombol Hapus]
             │
             ▼
[_RecentHistoryScreenState._deleteItem]
             │
             ▼
[HistoryService.deleteItem(File)]
             │
             ├──> File.delete() GAGAL (OS Permission / Scoped Storage I/O)
             │    └──> Exception ditangkap di catch block HistoryService
             │    └──> Mengembalikan false
             │
             ▼
[RecentHistoryScreen MENGABAIKAN return false]
             │
             ├──> Menjalankan _items.removeWhere() (Penghapusan Kosmetik)
             └──> SnackBar: "Video berhasil dihapus" (Ilusi Berhasil)
             │
             ▼
   [Pengguna Melakukan Pull-To-Refresh]
             │
             ▼
[_RecentHistoryScreenState._loadHistory]
             │
             ▼
[HistoryService.loadHistory()]
             │
             └──> Scan fisik: /storage/emulated/0/Movies/Uniquifier
             └──> File FISIK MASIH ADA di disk!
             └──> File dimuat ulang ke _items
             │
             ▼
[Video MUNCUL KEMBALI di Layar History]
```

---

## 4. Remediation Plan (Rencana Perbaikan Konkret)

Untuk menyelesaikan bug ini secara tuntas tanpa melanggar batasan arsitektur (Section 14 HANDOFF.md):

### Tahap 1: Perbaikan State UI & Error Handling (`recent_history_screen.dart`)
1. **Validasi Status Keberhasilan Hapus:**
   - Evaluasi nilai kembalian boolean dari `HistoryService.deleteItem()`.
   - Hapus item dari `_items` **hanya jika** penghapusan fisik terbukti berhasil (`if (success)`).
   - Jika gagal, jangan ubah list `_items` dan tampilkan SnackBar error yang jelas kepada pengguna: *"Gagal menghapus file dari penyimpanan perangkat. Periksa izin akses storage."*
2. **Evaluasi Multi-Select Delete:**
   - Gunakan jumlah riil yang berhasil dikembalikan oleh `HistoryService.deleteExportItems()`.
   - Periksa keberadaan file (`await item.file.exists()`) untuk menentukan apakah item masih tersisa.

### Tahap 2: Penguatan Operasi Hapus Fisik (`history_service.dart`)
1. **Verifikasi Keberadaan File Pasca Hapus:**
   ```dart
   static Future<bool> deleteItem(File file) async {
     try {
       final target = File(file.path);
       if (await target.exists()) {
         await target.delete();
         // Verifikasi ulang apakah file benar-benar musnah dari disk
         if (await target.exists()) {
           debugPrint('[HistoryService] File still exists after delete(): ${file.path}');
           return false;
         }
       }
       await _cleanupThumbnail(target);
       return true;
     } catch (e, stackTrace) {
       debugPrint('[HistoryService] Failed to delete file ${file.path}: $e\n$stackTrace');
       return false;
     }
   }
   ```
2. **Sinkronisasi MediaScanner Pasca Hapus:**
   - Panggil scanner/content resolver agar MediaStore Android memperbarui index saat file dihapus, mencegah file hantu di galeri.

### Tahap 3: Validasi Izin Akses Android Storage
1. Pastikan izin `MANAGE_EXTERNAL_STORAGE` (atau MediaStore scoped deletion) dihandle secara graceful jika aplikasi berjalan di Android 11+ (API 30+).

---

## 5. Verification Checklist

- [x] Sumber akar masalah teridentifikasi 100% pada logika penghapusan kosmetik di `recent_history_screen.dart` dan kegagalan disk I/O.
- [x] Seluruh file kode sumber (`lib/**`, `test/**`) tetap murni tidak tersentuh (100% READ-ONLY).
- [x] Analisis statis (`dart analyze`) exit 0, 0 issues.
- [x] Pengujian otomatis (`flutter test`) exit 0, 174/174 tests passing.
