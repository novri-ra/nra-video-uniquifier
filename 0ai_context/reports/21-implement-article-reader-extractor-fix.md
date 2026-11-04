# Execution Report 21: Microstock Intel On-Demand Reader Extractor & External Badge Fix

**Status:** Completed  
**Date:** 2026-11-04  
**Type:** Bug Fix & Resilience Hardening  
**Target:** `lib/features/microstock/services/article_reader_extractor.dart`, `lib/features/microstock/widgets/microstock_article_sheet.dart`, `lib/features/microstock/widgets/microstock_article_footer_widgets.dart`, `lib/core/services/microstock_news_service.dart`

---

## 1. Summary of Changes

Menyelesaikan Bug 1, 2, dan 3 dari Laporan Audit 20:
1. **ArticleReaderExtractor:** Dibangun service parser HTML on-demand menggunakan `package:html`. Mengekstrak konten body lengkap (`<article>`, `.entry-content`, tag `<p>` > 25 karakter) serta Open Graph / Twitter image (`og:image`, `twitter:image`).
2. **On-Demand Reader Mode Integration:** Pada `MicrostockArticleSheet`, jika artikel RSS memiliki konten yang tipis/hanya judul (`fullContent == title` atau panjang < 120 char), extractor dipicu di background saat bottom sheet dibuka. Disertai spinner lembut, fallback teks offline/gagal yang ramah, dan auto-save ke persistent cache.
3. **Hero Banner Fallback:** `_ArticleHeroBanner` kini merender `fallbackImageUrl` dari hasil on-demand `og:image` jika gambar asli dari feed bernilai null.
4. **Footer Source Badge Correction:** `ArticleFooterSourceBox` kini membedakan artikel eksternal RSS/Reddit (`isExternalSource: true`) dengan label *"Dipublikasikan oleh [Sumber] • Sumber Eksternal"* dan ikon `Icons.public_outlined`, sementara panduan internal tetap menampilkan *"Verified Microstock Guideline • [Sumber]"*.
5. **Sanitasi Artefak RSS:** Menghilangkan artefak `[Read More]`, `Read more...`, dan `Continue reading` dari deskripsi feed dan teks ekstraksi.

---

## 2. Inviolable Constraints Compliance (Section 14 HANDOFF.md)
- **Zero External Telemetry:** Tidak ada pengiriman data diagnostik ke server luar.
- **Strictly Offline-First:** Jika perangkat offline atau URL gagal dihubungi dalam 5 detik timeout, aplikasi tidak crash dan menampilkan fallback teks yang sudah tersedia disertai saran membuka di browser eksternal.
- **0 Paid API Keys:** Murni menggunakan standard library `dart:io HttpClient` dan DOM parser `package:html`.

---

## 3. Verification Results

| Step | Command | Result |
|------|---------|--------|
| Git Status | `git status` | Clean whitelist modifications |
| Dart Format | `dart format --set-exit-if-changed` | Clean (0 unformatted) |
| Dart Analyze | `dart analyze` | Exit 0 (0 issues found!) |
| Flutter Test | `flutter test` | **Exit 0 (174/174 passed, 0 regression)** |
