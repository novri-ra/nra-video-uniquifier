# Audit Arsitektur: Modul Microstock Intel, Model Berita, RSS Parsing, & Manajemen Cache

- Status: Completed (Read-Only Architectural Audit)
- Target: Investigasi menyeluruh terhadap arsitektur Microstock Intel saat ini untuk transformasi menjadi agregator berita profesional berkinerja tinggi, dinamis, cerdas (affinitas lokal), dan kaya konten (ekstraksi utuh & kompresi WebP lokal).
- Date: 2026-11-04
- Scope: Read-Only Audit terhadap `pubspec.yaml`, `lib/core/services/microstock_news_service.dart`, `lib/core/services/user_interest_service.dart`, `lib/features/microstock/**`, dan `test/microstock_news_and_translation_test.dart`.

---

## 1. Gambaran Arsitektur Saat Ini vs Arsitektur Target

| Aspek Arsitektur | Kondisi Saat Ini (Legacy) | Arsitektur Target (Next-Gen) |
|---|---|---|
| **Ekosistem Paket** | Tanpa `html` & `image`. Menggunakan regex string replacement dan `HttpClient()`. | Menambahkan `html: ^0.15.4` (DOM parser) dan `image: ^4.3.0` (WebP encode). |
| **Model Data (`Article`)** | 13 atribut tekstual. Tanpa `imageUrl`, `localImagePath`, `author`, atau `cachedAt`. | Model diperluas dengan `imageUrl`, `localImagePath`, `author`, dan `cachedAt`. |
| **Sumber Feed RSS** | Google News search RSS, Shutterstock via RSS2JSON, dan Reddit JSON API. | Direct Photography/Microstock RSS (PetaPixel, Fstoppers, Shutterstock) + Reddit. |
| **Parsing & Sanitasi** | Regex `<[^>]*>` bertahap. Rentan terpotong di tengah tag atau nested entity. | Real DOM Tree Parsing via `package:html/parser.dart`. Zero tag leakage. |
| **Ekstraksi Konten** | Deskripsi RSS dipotong 150 karakter. Konten utuh diisi boilerplate sintetis. | Ekstraksi konten utuh (`<content:encoded>` atau DOM body scraping) tanpa template statis. |
| **Media Gambar** | Tidak ada dukungan gambar. Tampilan kartu murni teks/badge. | Background Isolate downloader -> Resize -> Pure Dart WebP compression di local storage. |
| **Manajemen Cache** | Overwrite total (`saveNewsToCache` menimpa seluruh cache). TTL 1 jam tidak dicek. | Append-merge deduplikasi berbasis `sourceUrl`/`id` + validasi TTL 1 jam otomatis. |
| **Filter Bar Kategori** | 9 chip statis (`defaultKeywords`). Tag dinamis artikel tersembunyi. | 100% dinamis diekstrak dari kumpulan artikel aktif, diurutkan skor affinitas. |
| **Personalisasi Berita** | Skor affinitas hanya menyortir chip horizontal. Feed diurutkan tanggal saja. | Feed diurutkan formula hibrida: `Skor = (Recency * 0.4) + (UserAffinity * 0.6)`. |
| **Kepatuhan Privasi** | Memiliki telemetry dispatcher aktif ke Google Apps Script webhook. | 100% offline-first, local-only SharedPreferences, tanpa telemetri luar (Section 14). |

---

## 2. Audit Dependensi & Ekosistem Paket

### 2.1 Analisis `pubspec.yaml`
1. **Paket yang Sudah Tersedia**:
   - `path_provider: ^2.1.5` -> Siap digunakan untuk mengalokasikan direktori penyimpanan cache gambar (`getTemporaryDirectory()` / `getApplicationDocumentsDirectory()`).
   - `shared_preferences: ^2.5.6` -> Siap untuk penyimpanan metadata artikel JSON dan map affinitas pengguna.
   - `url_launcher: ^6.3.3` -> Digunakan untuk membuka sumber artikel di browser eksternal.
2. **Paket yang Belum Ada**:
   - `html`: Belum terpasang. Parsing RSS XML dan ekstraksi DOM HTML saat ini mengandalkan `RegExp` manual yang rapuh terhadap variasi markup web.
   - `image`: Belum terpasang. Diperlukan untuk manipulasi citra murni Dart (resize, downscale, dan konversi ke WebP).
   - `http`: Belum terpasang. Kode saat ini menggunakan `dart:io` `HttpClient()`.

### 2.2 Kelayakan Teknis Encoding & Decoding WebP di Runtime
- **Rendering WebP**: Mesin Flutter (Skia / Impeller) pada Android, iOS, macOS, Windows, dan Linux secara native mendukung rendering WebP (baik lossy maupun lossless) melalui `Image.file(File(path))` tanpa dependensi native tambahan.
- **Encoding WebP Murni Dart**: Pustaka `package:image` (versi 4.x ke atas) menyediakan fungsi `encodeWebp()` yang ditulis 100% dalam Dart murni. Hal ini menjamin:
  - Tidak ada kompilasi NDK/C++ tambahan pada Android.
  - Tidak ada CocoaPods / native framework issues pada iOS.
  - Kompatibel lintas platform secara deterministik.
- **Strategi Beban CPU (Threading)**:
  - Encoding WebP dalam Dart murni membutuhkan komputasi CPU intensif.
  - **Aturan Wajib**: Seluruh proses pengunduhan byte gambar, decoding, downscaling (misal: lebar maksimum 720px), dan kompresi WebP (kualitas 75-80%) **wajib dijalankan di dalam background Isolate** (`compute()` atau `Isolate.run()`) agar UI thread tetap stabil di 60/120 FPS tanpa frame drop.

---

## 3. Audit Model Data Berita Saat Ini

Model berita saat ini didefinisikan pada `lib/core/services/microstock_news_service.dart` (`MicrostockNewsArticle`):
```dart
class MicrostockNewsArticle {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String category;
  final String publishedDate;
  final String sourceUrl;
  final List<String> tags;
  final String fullContent;
  final String readTime;
  final String keyTakeaways;
  final List<String> technicalSpecs;
  final List<String> contributorChecklist;
}
```

### Keterbatasan Kritis Model:
1. **Ketiadaan Atribut Citra**:
   - Tidak ada field `imageUrl` (URL gambar remote dari RSS enclosure / OpenGraph).
   - Tidak ada field `localImagePath` (path lokal berkas `.webp` di storage perangkat).
2. **Ketiadaan Metadata Caching & Attribution**:
   - Tidak ada field `author` (penulis/fotografer asli).
   - Tidak ada field `crawledAt` / `cachedAt` (waktu saat artikel disimpan, menyulitkan pruning berkas usang).
3. **Penyuntikan Data Palsu (Synthetic Boilerplate)**:
   - Field `keyTakeaways`, `technicalSpecs`, dan `contributorChecklist` pada artikel Google News, RSS2JSON, dan Reddit diisi oleh string template statis yang di-hardcode di service parser:
     ```dart
     technicalSpecs: const [
       'Resolution: 4K UHD & 1080p',
       'Cadence: 30 / 60 FPS CFR',
       'Color: Rec.709 compliant',
     ],
     contributorChecklist: const [
       'Adhere to commercial stock standards.',
       'Maintain pristine metadata tagging.',
     ],
     ```
   - Akibatnya, setiap artikel berita umum (misal berita akuisisi perusahaan atau sensor kamera baru) menampilkan parameter teknis video yang identik dan tidak relevan.

---

## 4. Audit Parser RSS & Akar Masalah Kebocoran HTML

### 4.1 Mengapa Potongan `<a href="` Bisa Lolos?
1. **Pemotongan String Sebelum Sanitasi Tuntas**:
   Pada `parseRssXmlFeed`:
   `summary: desc.length > 150 ? '${desc.substring(0, 150)}...' : desc`
   Jika deskripsi mengandung markup HTML mentah, pemotongan substring pada indeks 150 dapat membelah tag di tengah (misal memotong `<a href="https://news.google.com...` sebelum tanda `>`). Akibatnya, regex penghapus tag `r'<[^>]*>'` gagal mengenali potongan tersebut sebagai tag HTML valid, sehingga string teks sisa `<a href="` lolos ke UI.
2. **Nested & Double-Encoded Entities**:
   RSS feed sering menyematkan entitas ganda seperti `&amp;lt;a href=...`. Pada single-pass decoding, entitas ini bertransformasi menjadi `&lt;a href=...`, yang tidak terdeteksi oleh tag stripper, lalu ter-decode downstream di layer terjemahan menjadi literal tag HTML.
3. **Karakteristik Opaque Google News RSS**:
   Feed Google News RSS menyematkan link redirect server (`news.google.com/rss/articles/...`) dan HTML ringkasan berformat list (`<ol><li>...</li></ol>`). Feed ini **tidak menyediakan**:
   - Tag `<category>`.
   - Konten artikel utuh (`<content:encoded>`).
   - Gambar resolusi tinggi (`<media:content>` / `<enclosure>`).

### 4.2 Struktur Feed RSS Media Fotografi Profesional
Berbeda dengan Google News, feed dari media industri fotografi & microstock (seperti PetaPixel, Fstoppers, Shutterstock Blog):
- Menyediakan tag `<category><![CDATA[News]]></category>` dan `<category><![CDATA[AI]]></category>` asli yang dapat langsung diekstraksi menjadi chip filter dinamis.
- Menyediakan `<dc:creator>` untuk atribusi fotografer/jurnalis.
- Menyediakan `<content:encoded>` berisi paragraf artikel utuh dan tag `<img>` resolusi tinggi yang dapat diunduh langsung tanpa scraping sekunder.

---

## 5. Audit Manajemen Cache & Siklus Pembaruan (1 Jam)

### 5.1 Masalah Penimpaan Total (Overwrite vs Append-Merge)
Pada `MicrostockNewsService.saveNewsToCache`:
```dart
final encoded = jsonEncode(articles.map((a) => a.toJson()).toList());
await prefs.setString(_cacheKey, encoded);
await prefs.setString(_lastFetchedKey, DateTime.now().toIso8601String());
```
- Sistem saat ini **menimpa total** cache lama dengan data baru yang baru saja di-fetch.
- Jika koneksi internet terputus di tengah jalan atau salah satu sumber hanya mengembalikan 2 artikel, seluruh riwayat artikel terdahulu akan hilang dari cache.
- **Solusi**: Diperlukan mekanisme *append-merge* yang menggabungkan artikel baru dengan artikel yang sudah ada di cache berdasarkan keunikan `sourceUrl` atau `id`, dengan batasan kapasitas (misal: retensi 100 artikel teratas).

### 5.2 Masalah Siklus Pembaruan 1 Jam (TTL Inactive)
Pada `MicrostockNewsService.loadNews`:
```dart
final cached = await getCachedNews();
if (cached.isNotEmpty && !forceRefresh) return cached;
```
- Walaupun `_lastFetchedKey` tersimpan di SharedPreferences, fungsi `loadNews` **sama sekali tidak memeriksa selisih waktu**.
- Jika `cached` sudah berisi artikel, sistem akan selalu mengembalikan cache tersebut selamanya kecuali pengguna melakukan *pull-to-refresh* manual.
- **Solusi**: Tambahkan pengecekan TTL (Time-To-Live):
  ```dart
  final lastSync = await getLastSyncTime();
  final isExpired = lastSync == null || 
      DateTime.now().difference(DateTime.parse(lastSync)) > const Duration(hours: 1);
  if (isOnline && isExpired) {
    return await fetchAndCacheNews();
  }
  ```

---

## 6. Audit Antarmuka Pengguna (UI/UX Layer)

### 6.1 `microstock_news_screen.dart` (Hardcoded Chips)
- Filter chips saat ini menggunakan daftar statis dari `UserInterestService.defaultKeywords`:
  `['All', '4K Footage', 'Shutterstock', 'Adobe Stock', 'AI Video', 'Reels Algorithm', 'Color Grading', 'Curation Tips', 'Commercial Rights']`.
- Tag dinamis yang ada pada artikel RSS (seperti `#PetaPixel`, `#Sony`, `#Drone`, `#Copyright`) tidak pernah muncul di barisan chip filter kecuali pengguna mencarinya secara manual.

### 6.2 `microstock_article_sheet.dart` (Hardcoded Static Boxes)
- Reader modal menampilkan tiga container statis:
  1. `ArticleKeyTakeawaysBox` -> Menampilkan teks boilerplate sintetis.
  2. `ArticleTechnicalSpecsBox` -> Menampilkan spesifikasi video hardcoded (4K, Rec.709, CFR).
  3. `ArticleContributorChecklistBox` -> Menampilkan poin checklist kurasi generik.
- Ketiadaan gambar: Tidak ada ruang untuk menampilkan banner/hero image artikel yang diunduh secara lokal.

---

## 7. Evaluasi Algoritma User Affinity Scoring

### 7.1 Kondisi Saat Ini di `UserInterestService`
- Menyimpan bobot di SharedPreferences (`nra_keyword_affinity_v1`):
  - Pencarian: +3
  - Klik chip: +2
  - Buka artikel: +2 (kategori), +1 (tags)
  - Toggle terjemahan: +1
- **Kelemahan Kritis**:
  1. **Monotonic Accumulation**: Skor terus bertambah tanpa peluruhan (*decay*). Minat pengguna dari 6 bulan lalu akan mendominasi urutan selamanya.
  2. **Pelanggaran Batasan Inviolable (Section 14)**:
     `UserInterestService._dispatchTelemetry` saat ini mengirim data pencarian dan baca artikel ke URL webhook Google Apps Script (`script.google.com/macros/s/...`). Sesuai aturan arsitektur strictly offline-first, telemetri eksternal ini **wajib dihapus** dan diubah menjadi kalkulasi murni lokal pada perangkat pengguna.
  3. **Feed Tidak Terpengaruh**: Skor affinitas saat ini hanya dipakai untuk mengurutkan posisi chip filter, dan **sama sekali tidak dipakai** untuk mengurutkan daftar berita utama.

### 7.2 Rumusan Algoritma Affinitas Rekomendasi (Local-First Decayed Scoring)
1. **Struktur Data SharedPreferences (`nra_user_affinity_v2`)**:
   ```json
   {
     "ai video": { "score": 12.5, "lastUpdated": 1730700000000 },
     "4k footage": { "score": 8.0, "lastUpdated": 1730600000000 }
   }
   ```
2. **Formula Peluruhan Waktu (Exponential Half-Life Decay 7 Hari)**:
   $$\text{DecayedScore} = \text{Score} \times 0.5^{\frac{\Delta t}{7 \text{ hari}}}$$
3. **Formula Peringkat Berita Hibrida**:
   $$\text{ArticleRank} = (S_{\text{recency}} \times 0.4) + (S_{\text{affinity}} \times 0.6)$$
   - Menghasilkan urutan feed yang segar namun sangat relevan dengan topik yang sering dibaca oleh pengguna secara personal.

---

## 8. Rencana Langkah Kerja Eksekusi Bertahap

Untuk memastikan transisi berjalan aman tanpa regresi pada 174 test suite yang ada, pekerjaan dibagi menjadi 3 tahap terpisah:

### Tahap 1: Ekosistem Paket, Fondasi Model, Parser Mandiri & Append-Merge Cache
1. Tambahkan dependensi `html: ^0.15.4` dan `image: ^4.3.0` pada `pubspec.yaml`.
2. Perluas model `MicrostockNewsArticle` dengan field `imageUrl`, `localImagePath`, `author`, dan `cachedAt` (dengan nilai default untuk menjaga backward compatibility).
3. Bangun parser RSS berbasis `package:html/dom.dart` untuk mengekstrak `<category>`, `<dc:creator>`, dan `<content:encoded>` secara bersih.
4. Ganti Google News RSS dengan feed direct fotografi (PetaPixel, Shutterstock Blog, Fstoppers).
5. Implementasikan logika append-merge cache dengan TTL 1 jam dan retensi maksimum 100 artikel.

### Tahap 2: Pipeline Pengunduhan & Kompresi WebP Lokal (Background Isolate)
1. Buat servis pengelola citra artikel (`ArticleImageService`):
   - Unduh byte citra secara timeout-guarded (maks 5 detik).
   - Eksekusi downscaling (lebar maks 720px) dan encoding WebP (kualitas 75%) di dalam `compute()` / `Isolate.run()`.
   - Simpan berkas WebP di direktori aplikasi sandboxed (`path_provider`).
2. Perbarui `MicrostockNewsCard` dan `MicrostockArticleSheet` untuk merender citra lokal WebP secara responsif dengan fallback placeholder bersih.

### Tahap 3: Dynamic Category Chips, Decayed Affinity Engine, & Clean Reader UI
1. Ekstraksi kategori dan tag 100% dinamis dari kumpulan artikel aktif dalam cache (menghapus array `defaultKeywords` yang kaku).
2. Terapkan exponential half-life decay pada skor affinitas lokal di SharedPreferences.
3. Hapus seluruh pemanggilan webhook telemetri eksternal di `UserInterestService` (menegakkan batasan Inviolable Section 14).
4. Urutkan daftar artikel feed menggunakan formula hibrida (Recency + Affinity).
5. Rombak `MicrostockArticleSheet` untuk merender artikel utuh yang dinamis dan menghapus container spesifikasi teknis sintetis.

---

## 9. Kesimpulan & Rekomendasi
Arsitektur Microstock Intel saat ini telah memiliki fondasi offline-first dan sistem serialisasi yang stabil, namun dibatasi oleh regex parser yang rentan, penimpaan cache yang merusak riwayat, data sintetis yang tidak relevan, dan chip kategori yang statis. Transformasi 3 tahap di atas sangat layak secara teknis dan dapat dieksekusi secara mulus dengan menjaga seluruh 174 pengujian tetap lulus.
