# Laporan 25: Upgrade Microstock News Reader, Google News URL Decoder, Freshness Filter, dan Portal Berita Indonesia

## 1. Ringkasan Eksekutif
Dalam iterasi ini, Microstock Intel News Aggregator & In-App Reader ditingkatkan secara komprehensif untuk mengatasi masalah tautan pengalihan Google News format 2024, penyaringan berita basi/kedaluwarsa, kurangnya cakupan berita pasar lokal Indonesia, serta keandalan ekstraksi konten artikel HTML berbasis CMS seperti WordPress (Inside Imaging, PetaPixel).

Semua perubahan dilakukan secara **strictly offline-first**, **tanpa telemetri eksternal tak berizin**, dan **0 API key berbayar**, dengan validasi 100% lulus pada seluruh pengujian unit/widget Flutter (`176/176 passed`, `flutter analyze 0 issues`).

---

## 2. Hasil Riset Webfetch & Decoding Google News URL
### Masalah Utama Google News URL 2024
Tautan RSS Google News (`https://news.google.com/rss/articles/...`) tidak lagi menggunakan pengalihan HTTP 301/302 sederhana langsung ke penerbit. Google News menghasilkan URL berbasis base64/protobuf (`CBM...` atau `AU_yq...`) yang memuat splash page JavaScript.

### Solusi Decoding URL (Reverse Engineering RPC batchexecute)
Melalui investigasi dan pengujian live endpoint:
1. Permintaan GET awal ke splash URL Google News (`/rss/articles/{id}?hl=en-US&gl=US&ceid=US:en`) dengan User-Agent browser modern mengembalikan atribut signature token `data-n-a-sg` dan timestamp `data-n-a-ts`.
2. Token tersebut dikirimkan via payload POST ke endpoint Google internal RPC:
   - **Endpoint**: `https://news.google.com/_/DotsSplashUi/data/batchexecute`
   - **RPC Method ID**: `Fbv4je`
   - **Inner Request**: `["garturlreq", ctx, articleId, timestamp, signature]`
3. Respons batchexecute mengembalikan URL asli penerbit dalam format JSON array: `["garturlres", "https://publisher.com/...", 1]`.
4. Jika bukan Google News atau URL langsung, sistem mengikuti rantai pengalihan HTTP standar (hingga 8 redirect hop) menggunakan header browser Chrome Android modern:
   `Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36`

---

## 3. Peningkatan Ekstraksi DOM (ArticleReaderExtractor)
- **Prioritas Selektor Kontainer**:
  Mendukung selektor CMS populer:
  - `.entry-content` (WordPress standar, Inside Imaging)
  - `.post-content` (WordPress modern / Genesis)
  - `.td-post-content` (TagDiv Newspaper theme)
  - `.article-content`, `.story-content`, `<article>`, `<main>`, `<body>`
- **Fallback Ekstraksi `<p>`**:
  Bila kontainer spesifik tidak ditemukan atau tidak memuat paragraf, parser memindai seluruh dokumen untuk tag `<p>` bermakna (> 20 karakter) dan memfilter teks pengisi/boilerplate (`Read More...`, `Continue reading`).
- **Ekstraksi Hero Image**:
  Mengekstrak gambar utama resolusi tinggi dari meta tag OpenGraph (`og:image`) atau `twitter:image`.

---

## 4. Parameter Freshness dan Portal Berita Indonesia
### Filter Freshness Google News
Untuk mengeliminasi artikel lama/kedaluwarsa, parameter pencarian Google News ditambahkan batasan waktu:
- **Global / Internasional**: `q=microstock+contributor+OR+shutterstock+contributor+when:7d` (7 hari terakhir).
- **Indonesia**: `q=kontributor+microstock+OR+fotografi+komersial+OR+desain+grafis+when:14d&hl=id&gl=ID&ceid=ID:id` (14 hari terakhir).

### Sumber Portal Berita Indonesia
- Diintegrasikan melalui feed RSS Google News regional Indonesia (`hl=id&gl=ID&ceid=ID:id`) dengan sumber default `Warta Microstock ID`.
- Mengagregasi berita dari portal nasional (seperti Detik, Antara, Kompas, Kontan) terkait ekosistem kreator digital, hak cipta foto komersial, dan royalti aset microstock.

### Kategori 'All' Tanpa Filter Sempit
- Pada tab 'All' (`_selectedChip == 'All'`), semua artikel dari seluruh feed hybrid (PetaPixel, Fstoppers, Google News US, Google News ID, RSS2JSON, Reddit r/microstock, Reddit r/stockphotography) disajikan tanpa filter label atau sumber.
- Hasil agregasi diurutkan secara kronologis terbalik (**newest-first**) berdasarkan `publishedDate`.

---

## 5. Berkas yang Diubah / Ditambahkan
1. `lib/features/microstock/services/article_reader_extractor.dart`
   - Implementasi batchexecute RPC decoder `Fbv4je` untuk URL Google News.
   - User-Agent browser modern Chrome Android 14.
   - Dukungan manual dan otomatis multi-hop redirect (maxRedirects = 8).
   - Penambahan selektor DOM `.entry-content`, `.post-content`, `.td-post-content`, `.story-content`, dan fallback tag `<p>`.
2. `lib/core/services/microstock_news_service.dart`
   - Penambahan feed `_fetchGoogleNewsIndonesiaRss()`.
   - Penerapan freshness parameter `when:7d` dan `when:14d`.
   - Agregasi hybrid feed paralel dan pengurutan newest-first.
3. `test/microstock_news_and_translation_test.dart`
   - Penambahan pengujian unit untuk `ArticleReaderExtractor` DOM parsing dan User-Agent.
   - Penambahan pengujian untuk hybrid feed agregasi feed lokal Indonesia.
4. `0ai_context/reports/INDEX.md`
   - Registrasi Laporan 25.
5. `0ai_context/reports/25-upgrade-news-reader-indonesia-freshness.md`
   - Dokumentasi lengkap hasil riset, arsitektur decoding, dan verifikasi mutu.

---

## 6. Verifikasi Mutu & Kepatuhan
- **Analisis Statis**:
  `flutter analyze` -> `No issues found!` (0 issues).
- **Formatting**:
  `dart format --set-exit-if-changed lib/ test/` -> Seluruh berkas rapi dan konsisten.
- **Suite Pengujian**:
  `flutter test` -> **176/176 passed** (bertambah dari 174 berkat 2 unit test baru untuk ArticleReaderExtractor dan feed Indonesia).
- **Inviolable Constraints**:
  - Offline-first: Ekstraktor memiliki fallback instan jika offline / gagal jaringan tanpa memblokir UI thread.
  - Telemetri: Tidak ada pengiriman data analitik ke pihak ketiga tanpa izin.
  - Zero paid API key: Menggunakan RSS publik dan native RPC decode tanpa lisensi komersial.
