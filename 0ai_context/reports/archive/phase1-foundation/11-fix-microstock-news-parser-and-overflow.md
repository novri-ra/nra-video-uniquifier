# Execution Report: Sanitasi HTML RSS Microstock & Perbaikan RenderFlex Overflow

- Status: Resolved
- Task: Sanitasi entitas dan tag mentah HTML pada Microstock Intel Feed, eliminasi Google News residual link, serta perbaikan RenderFlex overflow pada `MicrostockNewsCard` dan modal `MicrostockArticleSheet`.
- Date: 2026-11-04
- Scope:
  - `lib/features/microstock/utils/html_sanitizer.dart` (berkas baru)
  - `lib/core/services/microstock_news_service.dart`
  - `lib/features/microstock/widgets/microstock_news_card.dart`
  - `lib/features/microstock/widgets/microstock_article_sheet.dart`
  - `lib/features/microstock/widgets/microstock_article_footer_widgets.dart`
  - `lib/features/microstock/screens/microstock_news_screen.dart`

---

## 1. Masalah & Analisis Akar Masalah

Pada pengujian di emulator dan peninjauan DevTools Inspector:
1. **Entitas & Tag HTML Mentah**:
   - Google News RSS menyematkan tag HTML seperti `<a href="https://news.google.com/rss/articles/..." target="_blank">...</a>`, `<font>`, `<p>`, `<br>`, serta entitas seperti `&amp;`, `&quot;`, `&#39;`, `&lt;`, `&gt;`, `&nbsp;`, dan hex entities (`&#x27;`).
   - Teks mentah ini ter-render langsung di kartu berita (`MicrostockNewsCard`) dan pembaca artikel (`MicrostockArticleSheet`), sehingga tampak kotor dan menampilkan URL eksternal Google News yang tidak relevan.
2. **RenderFlex Overflow pada Kartu Berita (`MicrostockNewsCard`)**:
   - Header baris pada kartu berita menggunakan widget `Row` yang membungkus `_CategoryBadge`, `_SourceBadge`, `Spacer()`, dan `Text(widget.article.publishedDate)`.
   - Ketika nama publisher berita dari RSS Google News panjang atau format tanggal menyertakan jam RFC-822 lengkap, kombinasi `Spacer()` tanpa batasan lebar (`Flexible`/`Expanded`) menyebabkan horizontal `RenderFlex overflow` (Error 13/20 di Flutter DevTools).
   - `_TagsRow` dan tombol `_TranslateButton` juga berisiko overflow pada viewport sempit jika teks terjemahan atau tag melebihi ruang yang tersedia.
3. **RenderFlex Overflow pada Modal Pembaca (`MicrostockArticleSheet`) & Screen Header**:
   - Judul di `_HeaderBar` berada dalam inner `Row` tanpa `Expanded`, memicu overflow bila judul atau nama reader melebihi lebar dialog.
   - Toolbar aksi (`_ActionToolbar`) menggunakan `Row` dengan `Spacer()`, memicu overflow jika tombol `ArticleTranslateButton` dan tombol `Buka Sumber` bersanding pada layar sempit.
   - Header pada `MicrostockNewsScreen` (`_FeedHeader`) memiliki baris teks status sinkronisasi tanpa batasan lebar (`Expanded`).

---

## 2. Solusi & Implementasi Teknis

### 2.1 Pembuatan `HtmlSanitizer` Utilitas Terpusat
- **Berkas**: `lib/features/microstock/utils/html_sanitizer.dart`
- **Implementasi**:
  1. Ekstraksi konten dari tag `<content:encoded>` atau `<![CDATA[...]]>`.
  2. Normalisasi tag pemisah struktural (`<br>`, `</p>`, `</div>`, `</li>`) menjadi newline bersih.
  3. Decode entitas dua arah (tahap awal dan tahap kedua untuk menangani nested/double-encoded entities seperti `&amp;quot;` dan decimal/hex numeric entities `&#...;`).
  4. Pembersihan seluruh tag HTML melalui regex `RegExp(r'<[^>]*>')`.
  5. Pembersihan sisa URL Google News RSS (`https://news.google.com/...`) dan teks boilerplate (`View Full Coverage on Google News`).
  6. Normalisasi spasi, tabulasi, dan limitasi baris kosong berurutan maksimum 2 baris.

### 2.2 Integrasi Sanitizer pada Layer Service & Display
- **Berkas**: `lib/core/services/microstock_news_service.dart`
  - Mengarahkan `MicrostockNewsService.parseRssContent(rawXml)` langsung ke `HtmlSanitizer.clean(rawXml)`, menjamin kompatibilitas backward bagi seluruh test suite sekaligus membersihkan entitas dan tag HTML.
- **Berkas**: `lib/features/microstock/widgets/microstock_news_card.dart`
  - Menambahkan sanitasi pada runtime getter `displayTitle`, `displaySummary`, `_CategoryBadge`, `_SourceBadge`, dan `_TagsRow` untuk melindungi aplikasi dari artikel kotor yang sudah tersimpan di cache lokal (`SharedPreferences`).
- **Berkas**: `lib/features/microstock/widgets/microstock_article_sheet.dart`
  - Menerapkan sanitasi pada seluruh getter tampilan: `_displayTitle`, `_displayContent`, `_displayTakeaways`, `_displaySpecs`, dan `_displayChecklist`.

### 2.3 Eliminasi RenderFlex Overflow dengan Kontrak Responsif
- **`MicrostockNewsCard`**:
  - Mengganti `Spacer()` pada baris header dengan pembungkus `Flexible` pada `_SourceBadge` dan widget tanggal.
  - Menambahkan helper `_cleanDate` untuk memangkas format tanggal panjang (mengambil format standar `DD Mon YYYY` dari RFC-822 date string) dan perataan `Alignment.centerRight`.
  - Memberikan `maxLines: 1` dan `overflow: TextOverflow.ellipsis` pada seluruh teks di dalam `_SourceBadge`, `_CategoryBadge`, dan `_TranslateButton`.
- **`MicrostockArticleSheet`**:
  - Membungkus teks reader di `_HeaderBar` dengan `Expanded` dan `TextOverflow.ellipsis`.
  - Mengubah `_ActionToolbar` dari `Row` kaku menjadi `Wrap` dengan `alignment: WrapAlignment.spaceBetween`, `spacing: 8`, dan `runSpacing: 8` sehingga tombol aksi terlipat secara alami ke baris berikutnya jika layar sangat sempit.
- **`ArticleTranslateButton` (`microstock_article_footer_widgets.dart`)**:
  - Membungkus label teks terjemahan dengan `Flexible`, `maxLines: 1`, dan `TextOverflow.ellipsis`.
- **`_FeedHeader` (`microstock_news_screen.dart`)**:
  - Membungkus kolom judul dan status sinkronisasi dengan `Expanded` dan `TextOverflow.ellipsis`.

---

## 3. Hasil Verifikasi Kualitas

1. **Format Kode (`dart format`)**:
   ```
   Formatted 9 files (0 changed) in 0.04 seconds.
   ```
2. **Analisis Statis (`dart analyze`)**:
   ```
   Analyzing nra-video-uniquifier...
   No issues found! (exit code 0)
   ```
3. **Pengujian Unit & Widget (`flutter test`)**:
   ```
   00:18 +174: All tests passed! (174/174 passed, exit code 0)
   ```
4. **Offline-First & Security Compliance**:
   - Tetap 100% offline-first tanpa telemetri luar.
   - File whitelist dipatuhi tanpa menyentuh core engine ffmpeg atau file test.

---

## 4. Kesimpulan & Status
Seluruh isu RenderFlex overflow pada Microstock Intel dan residu format HTML mentah dari Google News RSS berhasil dituntaskan secara bersih, deterministik, dan bebas regresi.
