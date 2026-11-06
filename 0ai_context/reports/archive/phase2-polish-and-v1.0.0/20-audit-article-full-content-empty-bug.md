# Audit Report 20: Microstock Article Empty Body, Synthetic Badge & Hero Banner Failure

**Status:** Completed  
**Date:** 2026-11-04  
**Type:** Technical Investigation (100% Read-Only)  
**Target:** `lib/core/services/microstock_news_service.dart`, `lib/features/microstock/widgets/microstock_article_sheet.dart`, `lib/features/microstock/widgets/microstock_article_footer_widgets.dart`, `lib/features/microstock/services/article_image_service.dart`

---

## 1. Executive Summary

Investigasi pada tangkapan layar perangkat uji (RMX1851) terhadap artikel PetaPixel:
- Judul: *"This AI Company Wants to Pay You for Your Photos - PetaPixel"*
- Gejala 1: Isi artikel kosong / hanya menampilkan satu baris teks berupa salinan judul.
- Gejala 2: Muncul badge footer `"Verified Microstock Guideline • PetaPixel"` padahal artikel adalah berita RSS eksternal.
- Gejala 3: Gambar hero banner di atas judul tidak muncul.

Hasil audit mengonfirmasi tiga akar masalah terpisah tanpa kerusakan data integritas.

---

## 2. Root Cause Analysis

### 2.1 Bug 1: Isi Artikel Hanya Berisi Judul (Empty Full Content)
- **Sumber Feed:** Artikel ini berasal dari query Google News RSS (`https://news.google.com/rss/search?q=microstock+contributor+OR+shutterstock+contributor...`).
- **Karakteristik Google News RSS:**
  Google News membungkus setiap item dalam format:
  ```xml
  <item>
    <title>This AI Company Wants to Pay You for Your Photos - PetaPixel</title>
    <link>https://news.google.com/rss/articles/...</link>
    <description><a href="...">This AI Company Wants to Pay You for Your Photos</a>&nbsp;&nbsp;<font color="#6f6f6f">PetaPixel</font></description>
    <source url="https://petapixel.com">PetaPixel</source>
  </item>
  ```
  Tidak ada tag `<content:encoded>`, `<enclosure>`, atau cuplikan paragraf artikel di dalam `<description>`.
- **Parsing Fallback Failure:**
  Pada `MicrostockNewsService._parseRssItemBlock`:
  ```dart
  final cleanContent = HtmlSanitizer.clean(rawContent); // kosong
  final cleanDesc = HtmlSanitizer.clean(rawDesc); // hanya judul link + nama penerbit
  final fullContent = cleanContent.isNotEmpty
      ? cleanContent
      : (cleanDesc.isNotEmpty ? cleanDesc : title);
  ```
  `HtmlSanitizer.clean(rawDesc)` membuang tag `<a>` dan `<font>`, menyisakan teks judul yang sama persis dengan `title`.
  Akibatnya, `article.fullContent` bernilai string judul satu kalimat.
- **Tidak Ada Mekanisme On-Demand Article Fetcher:**
  Saat user mengetuk kartu berita untuk membuka `MicrostockArticleSheet`, aplikasi hanya membaca `article.fullContent` yang sudah diparsing dari RSS tanpa pernah melakukan HTTP GET ke `article.sourceUrl` untuk mengambil paragraf body asli (`<article>`, `<p>`).

### 2.2 Bug 2: Badge "Verified Microstock Guideline" Muncul di Artikel Eksternal
- **Lokasi Kode:** `lib/features/microstock/widgets/microstock_article_sheet.dart` baris 393 dan `lib/features/microstock/widgets/microstock_article_footer_widgets.dart` baris 75-116.
- **Evaluasi Boolean Salah Sasaran:**
  Di `MicrostockArticleSheet`:
  ```dart
  bool get _isSyntheticArticle =>
      article.id.startsWith('rss-') || article.id.startsWith('reddit-');
  ```
  Flag `!_isSyntheticArticle` hanya digunakan untuk menyembunyikan `ArticleKeyTakeawaysBox`, `ArticleTechnicalSpecsBox`, dan `ArticleContributorChecklistBox`.
- **Footer Box Tanpa Guard:**
  `ArticleFooterSourceBox(article: article, isDark: isDark)` di baris 393 dipanggil tanpa conditional check `_isSyntheticArticle`.
  Di dalam `ArticleFooterSourceBox.build`:
  ```dart
  Text('Verified Microstock Guideline • ${article.source}')
  ```
  Teks hardcoded tersebut selalu dirender untuk semua jenis artikel, termasuk artikel RSS feed luar.

### 2.3 Bug 3: Hero Banner Tidak Tampil
- **Ketiadaan Tag Media:**
  Google News RSS tidak menyertakan `<media:content>`, `<enclosure>`, maupun tag `<img>` di dalam payload XML.
- **Nilai `imageUrl` Null:**
  Metode `_extractImageUrl` menghasilkan `null`.
- **Conditional Visibility di Sheet:**
  Di `MicrostockArticleSheet`:
  ```dart
  if ((article.localImagePath != null && article.localImagePath!.isNotEmpty) ||
      (article.imageUrl != null && article.imageUrl!.isNotEmpty)) ...[
    _ArticleHeroBanner(article: article, isDark: isDark),
  ]
  ```
  Karena kedua properti bernilai `null` / kosong, `_ArticleHeroBanner` tidak dirender sama sekali.

---

## 3. Recommended Remediation Plan

### 3.1 On-Demand Reader Mode Scraper (Offline-First / Zero-Telemetry Compliant)
1. **Layanan Ekstraksi Konten:** Buat parser on-demand ringan (misal `ArticleReaderExtractor`) menggunakan `package:html` yang dipanggil saat user membuka `MicrostockArticleSheet` jika `article.fullContent == article.title` atau panjang kata < 40 kata.
2. **Target Selector:** Ekstrak elemen standar `<article>`, `.entry-content`, `.post-content`, atau fallback tag `<p>`.
3. **Hero Image Extractor:** Ambil `og:image` dari metadata `<head>` halaman sumber jika `article.imageUrl` awalnya null.
4. **Caching:** Simpan hasil scraping ke SQLite / SharedPreferences cache artikel sehingga hanya diunduh 1 kali.
5. **Fallback:** Jika offline atau request gagal, tampilkan pesan ramah: *"Summary only. Tap 'Open in Browser' to read full coverage on PetaPixel."*

### 3.2 Koreksi Penamaan & Guard Badge Footer
1. Pada `ArticleFooterSourceBox`:
   - Jika `_isSyntheticArticle` bernilai true (artikel RSS/Reddit):
     Ubah teks menjadi: `Published by ${article.source} • External Source` atau `Community News • ${article.source}` dengan ikon `Icons.public_outlined`.
   - Jika artikel asli internal (Seed/Guideline):
     Tetap tampilkan `Verified Microstock Guideline • ${article.source}` dengan ikon `Icons.verified_outlined`.

---

## 4. Verification Check
- Status working tree: 100% read-only pada `lib/` dan `test/`.
- Verifikasi kepatuhan: Section 14 HANDOFF.md (Strictly offline-first, no external telemetry).
