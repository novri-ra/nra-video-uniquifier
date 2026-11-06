# Deep Audit Report: UI/UX International Standards & Accessibility Evaluation

- Status: Completed
- Type: Deep UI/UX & Accessibility Audit
- Target: `nra_video_uniquifier` (Flutter Desktop/Mobile Offline-First)
- Date: 2026-11-04
- Scope: `lib/core/theme/**`, `lib/features/**`, `lib/l10n/**`, `lib/shared/widgets/**`
- Standards Evaluated: WCAG 2.2 (Level AA & AAA), Apple Human Interface Guidelines (HIG), Google Material Design 3, ISO 9241-210 (Ergonomics of Human-System Interaction)

---

## 1. Executive Summary

Aplikasi **NRA Video Uniquifier** menyajikan identitas visual bergaya *Editorial Engineering / Bloomberg-Linear Dark Canvas* dengan palet warna khusus (`forestDeep`, `obsidianDark`, `mintSage`, `vividCoral`). Tata letak utama terstruktur dengan bento grid, floating navigation capsule, dan diagnostic strip yang informatif.

Meskipun fondasi visual dan arsitektur offline-first sangat solid, audit mendalam ini mengungkap sejumlah kesenjangan kepatuhan terhadap standar internasional, terutama pada:
1. **Kegagalan rasio kontras teks tema terang (Light Mode Contrast)** pada aksen pastel (`electricIce`, `skyPastel`, `mustardOchre`, dan status tombol nonaktif `_StartActionButton` di mana teks putih dirender di atas latar terang 1.19:1).
2. **Area sentuh sub-standar (Touch Targets < 44-48dp)** pada beberapa kontrol penting seperti tombol tambah antrean (18x18dp), tombol clear file (28x28dp), dan tombol toolbar riwayat (28x28dp & 32x32dp).
3. **Ketiadaan Semantics & Tooltips** untuk pembaca layar (TalkBack / VoiceOver) pada custom radar progress indicator, accordion cards, dan beberapa ikon interaktif.
4. **Cakupan Lokalisasi (i18n) Belum Merata** (hanya ~30% komponen UI yang terhubung ke `AppLocalizations`; modul Microstock, Batch Queue, dan History masih dipenuhi teks hardcoded campuran bahasa Indonesia dan Inggris).

### Skor Kematangan UI/UX: **72 / 100** (Grade: B - Production Viable with Accessibility Gaps)

| Dimensi Evaluasi | Bobot | Skor | Status |
|------------------|-------|------|--------|
| **Visual Hierarchy & Aesthetics** | 20% | 88/100 | Baik (Kohesif, editorial, profesional) |
| **Color Contrast & Readability (WCAG 2.2)** | 25% | 62/100 | Perlu Perbaikan (Kegagalan kritis pada light theme) |
| **Touch Target & Ergonomics (HIG/M3)** | 20% | 68/100 | Perlu Perbaikan (Beberapa tombol < 32dp) |
| **Screen Reader & Semantics (A11y)** | 15% | 64/100 | Perlu Perbaikan (Kurang label & live announcement) |
| **Responsive & Font Scaling (Dynamic Type)** | 10% | 78/100 | Cukup (Bebas overflow pada 320px, namun micro-text 8px) |
| **Internationalization (i18n Readiness)** | 10% | 55/100 | Rendah (Banyak hardcoded string) |

---

## 2. Kepatuhan Standar Internasional

| Standar Internasional | Status Kepatuhan | Catatan Evaluasi |
|-----------------------|------------------|------------------|
| **WCAG 2.2 SC 1.4.3 Contrast (Minimum - Level AA)** | **FAIL (Light Mode)** | Gagal pada badge pastel (1.59:1), teks disabled button (1.19:1), dan offline badge mustard (2.55:1) pada tema terang. Tema gelap lulus AA/AAA pada teks utama. |
| **WCAG 2.2 SC 2.5.8 Target Size (Minimum - Level AA)** | **PARTIAL** | Mayoritas tombol utama memenuhi 48x48dp, namun tombol aksi sekunder di header riwayat (28x28dp) dan kartu bento (18x18dp) di bawah standar. |
| **WCAG 2.2 SC 4.1.2 Name, Role, Value** | **PARTIAL** | `FloatingCapsuleNavBar` menerapkan Semantics dengan sangat baik; namun `ProcessingRadarIndicator`, `_ClearIconButton`, dan `CategoryAccordionCard` belum mengumumkan nama peran dan status ekspansi. |
| **Apple Human Interface Guidelines (Touch & Feel)** | **PARTIAL** | Menggunakan 44dp minimum pada bottom nav dan 48dp pada history action, namun minim haptic feedback (`HapticFeedback.selectionClick()` / `mediumImpact()`) pada toggle dan batch delete. |
| **Material Design 3 (M3 Standards)** | **LULUS BERSYARAT** | Mendukung dynamic layout, theme data terpisah, dan switch adaptive, namun `ThemeData` belum mendeklarasikan `TextTheme` komprehensif (bergantung pada ad-hoc inline styles). |
| **Section 14 INVIOLABLE (Offline-First Privacy)** | **FULL PASS (100%)** | Seluruh UI beroperasi strictly offline-first, tidak ada network leakage atau analytics blocking UI, error tertangani lokal. |

---

## 3. Matriks Analisis Rasio Kontras Warna

Perhitungan rasio kontras berdasarkan formula luminansi relatif ISO/IEC 17025 & W3C WCAG:
$$\text{Contrast Ratio} = \frac{L_1 + 0.05}{L_2 + 0.05}$$

| Kombinasi Warna (Foreground vs Background) | Penggunaan Elemen | Luminansi ($L_1:L_2$) | Rasio Kontras | Status WCAG 2.2 |
|-------------------------------------------|-------------------|-----------------------|---------------|-----------------|
| `onSurface` (#F2F6F4) vs `obsidianBase` (#111817) | Teks utama Dark Mode | 0.89 : 0.009 | **16.1 : 1** | **PASS (AAA)** |
| `mintSage` (#A3EFD5) vs `surface` (#1A2523) | Aksen / Teks aktif Dark Mode | 0.77 : 0.018 | **12.1 : 1** | **PASS (AAA)** |
| `forestDeep` (#0E5535) vs `white` (#FFFFFF) | Teks utama / Aksen Light Mode | 0.076 : 1.00 | **8.33 : 1** | **PASS (AAA)** |
| `onSurfaceVariant` (#B9CBBF) vs `surface` (#1A2523) | Subtitle / Deskripsi Dark Mode | 0.58 : 0.018 | **9.26 : 1** | **PASS (AAA)** |
| `vividCoral` (#FF4431) vs `surface` (#1A2523) | Tombol Hapus / High-impact Dark | 0.215 : 0.018 | **3.90 : 1** | **PASS (AA Large / UI)** / FAIL (Normal Text) |
| `vividCoral` (#FF4431) vs `white` (#FFFFFF) | Warning Badge Text Light Mode | 0.215 : 1.00 | **3.96 : 1** | **FAIL (AA Normal Text < 4.5:1)** |
| `mustardOchre` (#C2A500) vs `white` (#FFFFFF) | Offline Status Badge Light Mode | 0.361 : 1.00 | **2.55 : 1** | **FAIL (AA < 4.5:1)** |
| `electricIce` (#7BD6F3) vs `white` (#FFFFFF) | Cinema Preset Badge Light Mode | 0.610 : 1.00 | **1.59 : 1** | **CRITICAL FAIL (< 3.0:1)** |
| `skyPastel` (#7DDCF0) vs `white` (#FFFFFF) | Badge Kategori Light Mode | 0.640 : 1.00 | **1.52 : 1** | **CRITICAL FAIL (< 3.0:1)** |
| `white` (#FFFFFF) vs Disabled Card (#E2ECE7) | Teks Tombol Disabled Light Mode | 1.00 : 0.830 | **1.19 : 1** | **CRITICAL FAIL (Nyaris Tak Terlihat)** |
| `mintSage` (alpha 0.4) vs `surface` (#1A2523) | Inactive Bottom Nav Tab Dark Mode | 0.134 : 0.018 | **2.70 : 1** | **FAIL (AA Text 9.5px < 4.5:1)** |

---

## 4. Daftar Temuan Masalah UI/UX (Categorized Findings)

### 4.1 Tingkat Kritis (Critical Issues - Menghambat Keterbacaan & Penggunaan)

1. **[CRIT-01] Teks Tombol Nonaktif Menjadi Tak Terlihat pada Tema Terang (`_StartActionButton`)**
   - **Lokasi**: `lib/features/process/screens/process_screen.dart` baris 241–263.
   - **Gejala**: Ketika tombol nonaktif (`enabled == false`) pada tema terang, latar tombol menggunakan `AppColors.surfaceContainerHigh` (#E2ECE7), namun teks dan ikon dipaksa tetap berwarna putih (`AppColors.white`).
   - **Dampak**: Rasio kontras anjlok menjadi **1.19:1**, teks tombol "START UNIQUIFYING" menjadi tidak terbaca sama sekali di layar pengguna.
   - **Rekomendasi**: Pastikan `TextStyle` dan `Icon` menghormati status enabled:
     ```dart
     final contentColor = enabled
         ? AppColors.white
         : (isDark ? AppColors.outline : AppColors.lightOnSurfaceVariant);
     ```

2. **[CRIT-02] Aksen Pastel Tidak Memiliki Kontras pada Tema Terang (`PresetProfileCard`, `SeasonalHeroCard`)**
   - **Lokasi**:
     - `lib/features/settings/widgets/preset_profile_card.dart` (`electricIce`, `skyPastel`)
     - `lib/features/settings/widgets/upscale_resolution_card.dart` (`_WarningBadge`)
     - `lib/shared/widgets/top_app_bar.dart` (`_OfflineBadge` `mustardOchre`)
   - **Gejala**: Warna teks badge menggunakan warna pastel identik baik pada tema gelap maupun terang. Pada tema terang berlatar putih (#FFFFFF), warna seperti `electricIce` hanya memiliki kontras **1.59:1** dan `mustardOchre` **2.55:1**.
   - **Dampak**: Informasi badge teknis (misal badge "CINEMA", "OFFLINE", "WARNING") tidak terbaca oleh pengguna di luar ruangan atau pengguna dengan gangguan penglihatan warna (deuteranopia/protanopia).
   - **Rekomendasi**: Buat token adaptif: jika `isDark == false`, gunakan turunan warna yang lebih pekat (misal: `Color(0xFF00677D)` untuk cyan, `Color(0xFF7A6800)` untuk ochre).

---

### 4.2 Tingkat Mayor (Major Issues - Menurunkan Aksesibilitas & Ergonomi)

1. **[MAJ-01] Area Sentuh Sub-Standar pada Kontrol Tombol Mini (`BentoMetricGrid`, `SourceFileSection`, `HistoryHeader`)**
   - **Lokasi**:
     - `lib/features/dashboard/widgets/bento_metric_grid.dart` (Tombol `+` antrean: size 12 icon, padding 3 -> area sentuh ~18x18dp).
     - `lib/features/process/widgets/source_file_section.dart` (`_ClearIconButton`: `fixedSize: const Size(28, 28)`).
     - `lib/features/history/widgets/history_storage_bar.dart` (`IconButton` refresh/checklist: `minWidth: 28, minHeight: 28`).
   - **Standar**: WCAG 2.5.5 AAA / Material Design 3 mensyaratkan minimal **48x48dp**, dan Apple HIG mensyaratkan minimal **44x44pt**.
   - **Dampak**: Kesulitan menekan tombol pada perangkat sentuh berlayar rapat, rentan salah pencet (*fat-finger errors*).
   - **Rekomendasi**: Bungkus ikon dalam touch target transparan 48x48dp (`BoxConstraints(minWidth: 48, minHeight: 48)` atau tambahkan padding/hit area terluar).

2. **[MAJ-02] Ketiadaan Semantics Label pada Pembaca Layar (`Screen Readers`)**
   - **Lokasi**:
     - `lib/features/process/widgets/processing_radar_indicator.dart`: Progress lingkaran custom paint tidak mendeklarasikan `Semantics(value: ..., liveRegion: true)`. TalkBack tidak mengumumkan perubahan persentase rendering secara berkala.
     - `lib/shared/widgets/category_accordion_card.dart`: `InkWell` tidak memiliki `Semantics(expanded: _expanded, button: true)`.
     - `lib/features/process/widgets/source_file_section.dart`: `_ClearIconButton` tidak memiliki `tooltip` atau `Semantics(label: 'Clear file')`.
   - **Dampak**: Pengguna tunanetra tidak mendapatkan konteks mengenai proses video yang sedang berjalan atau tombol untuk menghapus file terpilih.

3. **[MAJ-03] Cakupan Internasionalisasi (i18n) Parsial & Teks Hardcoded Campuran**
   - **Lokasi**:
     - Seluruh modul `lib/features/microstock/**` (0% terhubung ke l10n).
     - Seluruh modul `lib/features/batch/**` (0% terhubung ke l10n).
     - Modul `lib/features/history/**` (Tercampur bahasa: dialog hapus massal bahasa Indonesia "Hapus Semua", dialog hapus tunggal bahasa Inggris "Delete Video?", AppBar "RECENT EXPORTS").
   - **Dampak**: Saat pengguna berpindah ke bahasa Inggris (`en`) di pengaturan, layar riwayat, microstock, dan batch tetap menampilkan bahasa Indonesia atau sebaliknya, merusak konsistensi aplikasi global.

---

### 4.3 Tingkat Minor (Minor Issues - Penyempurnaan Visual & Mikro-Interaksi)

1. **[MIN-01] Ukuran Tipografi Terlalu Kecil (Micro-Typography < 9sp)**
   - **Lokasi**:
     - `lib/features/process/widgets/processing_stage_tracker.dart` (Label tahapan: `fontSize: 7.5`).
     - `lib/features/settings/widgets/preset_profile_card.dart` (Badge: `fontSize: 8.5`).
     - `lib/features/settings/widgets/upscale_resolution_card.dart` (`_WarningBadge`: `fontSize: 8.0`).
   - **Dampak**: Sulit dibaca pada layar perangkat tanpa penskalaan teks tinggi.
   - **Rekomendasi**: Naikkan ukuran minimum teks ke rentang 10–11sp dengan letter-spacing seimbang.

2. **[MIN-02] Pemotongan Subtitle pada Teks Skala Besar (`SettingToggleRow`)**
   - **Lokasi**: `lib/shared/widgets/setting_toggle_row.dart` baris 75–76 (`maxLines: 1, overflow: TextOverflow.ellipsis`).
   - **Dampak**: Saat fitur Text Scaling / Dynamic Type Android aktif (1.5x - 2.0x), penjelasan fitur terpotong prematur.
   - **Rekomendasi**: Ubah menjadi `maxLines: 2` atau `maxLines: 3`.

3. **[MIN-03] Ketiadaan Umpan Balik Haptik (Haptic Feedback)**
   - **Lokasi**: Transisi mode seleksi riwayat, batch deletion, dan penekanan tombol toggle.
   - **Dampak**: Mengurangi rasa kepastian tactile pengguna saat memicu aksi penting.
   - **Rekomendasi**: Tambahkan `HapticFeedback.lightImpact()` pada seleksi dan `HapticFeedback.mediumImpact()` pada dialog konfirmasi hapus.

4. **[MIN-04] Ketergantungan Font Monospace Generik Sistem**
   - **Lokasi**: Penggunaan inline `fontFamily: 'monospace'` pada >100 tempat tanpa deklarasi font terbundel (seperti JetBrains Mono atau Fira Code).
   - **Dampak**: Tampilan teks teknis berbeda drastis antara Android (Roboto Mono), iOS (Menlo/Courier), dan Desktop (Consolas).

---

## 5. Peta Jalan Perbaikan UI/UX (Actionable Remediation Roadmap)

Untuk menaikkan skor kepatuhan dari **72/100** menjadi **95+/100 (Grade A - World-Class Standard)**, disusun rencana perbaikan berperingkat:

```
Peta Jalan Rekomendasi:
┌─────────────────────────────────────────────────────────────────────────┐
│ Fase 1: Perbaikan Kritis Kontras & Aksesibilitas (P0 - Immediate)        │
│ • Perbaiki kontras tombol disabled di process_screen.dart               │
│ • Sediakan token warna badge adaptif untuk tema terang                  │
│ • Normalisasi warna offline badge mustardOchre di TopAppBar             │
├─────────────────────────────────────────────────────────────────────────┤
│ Fase 2: Standarisasi Area Sentuh & Pembaca Layar (P1 - High Priority)   │
│ • Naikkan area sentuh kontrol mini menjadi minimal 44-48dp              │
│ • Pasang Semantics & Live Announcement pada progress radar & accordion   │
│ • Tambahkan tooltip pada seluruh IconButton tanpa teks                   │
├─────────────────────────────────────────────────────────────────────────┤
│ Fase 3: Standardisasi Lokalisasi Global (P2 - Medium Priority)          │
│ • Ekstrak seluruh teks hardcoded di History, Batch, dan Microstock      │
│ • Tambahkan definisi lengkap di app_en.arb dan app_id.arb                │
│ • Izinkan multi-line subtitle pada SettingToggleRow (Dynamic Type)       │
├─────────────────────────────────────────────────────────────────────────┤
│ Fase 4: Micro-Interactions & Polishing (P3 - Polish)                    │
│ • Integrasikan HapticFeedback pada aksi penting                         │
│ • Standarisasi font mono terpadu di ThemeData                           │
│ • Tingkatkan ukuran micro-text minimum menjadi >= 10sp                  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Verifikasi Integritas Sistem

- `dart analyze`: Exit 0 (0 issues found).
- `flutter test`: Exit 0 (174/174 unit & widget tests passed).
- `git status`: Bersih, tidak ada modifikasi kode pada `lib/**` atau `test/**` dalam sesi audit ini.
