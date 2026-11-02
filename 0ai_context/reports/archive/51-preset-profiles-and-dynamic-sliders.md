# Laporan 51: Redesain UI Preset Profiles Obsidian Cards dan Implementasi Dynamic Parameter Sliders In-Line (0% - 100%)

## 1. Executive Summary & Architecture Verdict

- **Masalah Utama**:
  1. Bagian "PRESET PROFILES" pada `SettingsScreen` sebelumnya menggunakan tombol `ActionChip` dasar yang terpisah-pisah tanpa metadata deskriptif, lencana tag, atau kontainer obsidian yang kohesif, kontras dengan kartu `VideoCodec` dan `UpscaleResolutionCard` di bawahnya.
  2. Nilai parameter kanvas buram (*blurred canvas*) sebelumnya terkunci secara kaku (*hardcoded*) pada 95%. Pengguna membutuhkan kontrol interaktif langsung untuk menentukan proporsi margin/skala latar belakang secara fleksibel melalui slider in-line 0% - 100% yang terintegrasi secara elegan di bawah toggle modifier.
- **Solusi & Implementasi**:
  - **Redesain Kartu Preset Profiles (`PresetProfileCard`)**:
    - Diekstrak ke berkas arsitektur mandiri `lib/features/settings/widgets/preset_profile_card.dart` (176 LOC).
    - Menghadirkan 3 kartu opsi profil obsidian terstruktur:
      * **TikTok Fast**: Ikon kilat (`Icons.bolt`), badge `FAST` (`AppColors.primaryContainer`), deskripsi: *8% crop, dynamic micro-tilt, metadata scrub & auto-trim*.
      * **Maximum Anti-Fingerprint**: Ikon perisai keamanan (`Icons.security`), badge `ULTRA` (`AppColors.secondary`), deskripsi: *2K Lanczos, flip, pink noise, dual-band EQ & trim*.
      * **Lossless Stealth**: Ikon perisai garis (`Icons.shield_outlined`), badge `CLEAN` (`AppColors.outline`), deskripsi: *Zero visual distortion • Pure container & EXIF scrubbing*.
    - Visual terpadu: `AppColors.surfaceContainerLow`, outline border, highlight status terpilih aktif/glow, dan tipografi monospace.
  - **Komponen Slider In-Line Dinamis (`SettingSliderToggleRow`)**:
    - Dibuat di `lib/shared/widgets/setting_slider_toggle_row.dart` (184 LOC) dengan dekomposisi fungsi bersih (`_HeaderRow` dan `_SliderRow`, `<= 25` baris per fungsi).
    - Slider hanya muncul dan aktif saat toggle induk berstatus `ON`, menghemat ruang vertikal dan menjaga estetika antarmuka tetap tenang.
    - Menampilkan lencana nilai persentase real-time monospace (`Scale: 95%`).
  - **Dukungan Dynamic Blurred Canvas pada Pipeline FFmpeg**:
    - `FilterBuilders._buildCanvasChain` kini menghitung dimensi foreground secara dinamis:
      * Lebar foreground: $w = \text{trunc}(\text{targetWidth} \times (\text{percent}/100) / 2) \times 2$
      * Tinggi foreground: $h = \text{trunc}(\text{targetHeight} \times (\text{percent}/100) / 2) \times 2$
    - Terkoneksi menyeluruh dari `UniquifierProvider.canvasScalePercent` -> `SettingsService` (`app_canvas_scale_percent`) -> `FfmpegService.buildCommand` -> native CLI filtergraph.
- **Kualitas & Metrik Arsitektur**:
  - `flutter analyze --fatal-infos` -> **0 issues found**.
  - `flutter test` -> **111/111 passed** (lolos seluruh pengujian unit, widget, dan skenario dynamic scaling 50%, 95%, 100%).
  - Seluruh berkas di `lib/` patuh plafon `<= 380 LOC` (batas maksimal 400 LOC).
  - Seluruh fungsi `<= 40 baris`.

---

## 2. Spesifikasi Redesain UI Preset Profiles (Before vs After)

| Aspek UI | Implementasi Sebelumnya (Laporan 49) | Redesain Baru (Laporan 51) |
|---|---|---|
| **Struktur Komponen** | `Wrap` dengan 3 `ActionChip` statis di dalam `SettingsScreen` | Widget mandiri `PresetProfileCard` dengan ubin vertikal terstruktur |
| **Ikon Kategori** | Tidak ada ikon | Ikon semantik: `Icons.bolt`, `Icons.security`, `Icons.shield_outlined` |
| **Deskripsi Penjelasan** | Tidak ada deskripsi | Subtitle monospace 11dp menjelaskan parameter teknis setiap profil |
| **Lencana Status / Tag** | Tidak ada lencana | Tag penanda eksklusif: `FAST` (Mint), `ULTRA` (Secondary), `CLEAN` (Outline) |
| **Indikator Aktif** | Tidak terlacak visual | Border highlight primer 2px dan background `surfaceContainerHigh` |
| **Konsistensi Desain** | Kontras dengan ubin codec/resolusi | 100% selaras dengan desain obsidian `CodecSelectorCard` |

---

## 3. Rincian Implementasi In-Line Dynamic Slider

- **Berkas**: `lib/shared/widgets/setting_slider_toggle_row.dart`
- **Fitur Interaktivitas**:
  - Header Row: Ikon modifier 18dp, judul 13dp w500, subtitle monospace 10dp, dan Material 3 switch toggle.
  - Sub-Row Slider: Muncul bersyarat (`if (value)`) dengan indentasi optik 28dp (sejajar dengan teks judul).
  - Slider Theme: Track height 2dp, warna aktif `AppColors.primaryContainer`, thumb radius ramping 5dp.
  - Label Nilai: Monospace mint 10dp w700 terformat (misal `Scale: 95%`).
- **Penerapan pada Modifiers**:
  - Diimplementasikan pada `Blurred Canvas Frame` di dalam accordion `FRAMING & TEXTURE`.
  - Struktur reusable siap diterapkan untuk modifier continuous lainnya (seperti Opasitas Grain/Noise atau Chroma Shift Curve).

---

## 4. Formulasi Perintah FFmpeg untuk Dynamic Blurred Canvas

### Mode Portrait (1080×1920) pada Skala 95% (Default)
```bash
[0:v]split=2[bg][fg];[bg]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=luma_radius=min(h\,w)/40:luma_power=2[blurred];[fg]scale=w=1026:h=1824:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[main];[blurred][main]overlay=(W-w)/2:(H-h)/2[outv]
```

### Mode Portrait (1080×1920) pada Skala 50%
```bash
[0:v]split=2[bg][fg];[bg]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=luma_radius=min(h\,w)/40:luma_power=2[blurred];[fg]scale=w=540:h=960:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[main];[blurred][main]overlay=(W-w)/2:(H-h)/2[outv]
```

### Mode Portrait (1080×1920) pada Skala 100%
```bash
[0:v]split=2[bg][fg];[bg]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=luma_radius=min(h\,w)/40:luma_power=2[blurred];[fg]scale=w=1080:h=1920:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[main];[blurred][main]overlay=(W-w)/2:(H-h)/2[outv]
```

---

## 5. Hasil Pengujian & Cakupan Uji Otomatis

- `flutter analyze --fatal-infos` -> **0 issues found**.
- `flutter test` (111/111 passed):
  - `test/ffmpeg_service_test.dart` -> 32/32 passed (termasuk verifikasi formula skala dinamis 50%, 95%, dan 100%).
  - `test/setting_toggle_row_test.dart` -> 2/2 passed (termasuk verifikasi interaktivitas dan penampakan dinamis slider `SettingSliderToggleRow`).
  - `test/settings_service_test.dart` -> 13/13 passed (termasuk persistensi persentase skala kanvas pada SharedPreferences).
  - `test/uniquifier_provider_test.dart` -> 21/21 passed (termasuk mutasi state `setCanvasScalePercent`).
  - `test/widget_test.dart` -> 13/13 passed (termasuk pengujian interaksi tap ubin preset baru `TikTok Fast`, `Maximum Anti-Fingerprint`, dan `Lossless Stealth`).
  - Suite pengujian lainnya -> 30/30 passed.

---

## 6. MCP Evidence Appendix

| MCP Tool | Kueri / Parameter | Hasil & Metrik | Status Verifikasi |
|---|---|---|---|
| `mcp__codebase_memory_mcp__index_status` | Pre-task check | 1773 nodes, 4278 edges, status: ready | Terverifikasi |
| `mcp__codebase_memory_mcp__index_repository` | Mode `full` | Status: indexed, 1773 nodes, 4278 edges | Terverifikasi |
| `search_files` | `TikTok Fast` di `test/widget_test.dart` | 2 kecocokan pemanggilan teks | Kompatibilitas Terjaga |
