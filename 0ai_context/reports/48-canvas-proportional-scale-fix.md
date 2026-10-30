# Laporan 48: Perbaikan Penskalaan Proporsional Foreground Blurred Canvas Terhadap Dimensi Target (Universal 5% Inset Margin)

## 1. Executive Summary & Verdict

- **Masalah Utama**: Pada implementasi sebelumnya, video foreground diskalakan berdasarkan resolusi inputnya sendiri (`iw*0.95`), sedangkan latar belakang blur dipaksa ke resolusi kanvas target (`1080:1920`). Ketika video input beresolusi lebih kecil dari kanvas target (misal 720×1280 atau 540×960), video foreground tampil sangat kecil di tengah dengan margin blur yang sangat tebal secara tidak proporsional.
- **Penyebab Akar (Root Cause)**: Penggunaan ekspresi `scale=w=trunc(iw*0.95/2)*2:h=trunc(ih*0.95/2)*2` tidak mengaitkan ukuran foreground dengan dimensi kanvas target (1080×1920 untuk portrait, 1920×1080 untuk landscape).
- **Solusi Rekayasa**:
  1. Menyelaraskan penskalaan foreground langsung terhadap 95% dari ukuran kanvas target dengan mempertahankan aspek rasio (`force_original_aspect_ratio=decrease`):
     - Portrait (`1080x1920`): 95% lebar adalah $1080 \times 0.95 = 1026$, 95% tinggi adalah $1920 \times 0.95 = 1824$.
       `[fg]scale=w=1026:h=1824:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[main]`
     - Landscape (`1920x1080`): 95% lebar adalah $1920 \times 0.95 = 1824$, 95% tinggi adalah $1080 \times 0.95 = 1026$.
       `[fg]scale=w=1824:h=1026:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[main]`
  2. Memperhalus radius pemburaman latar belakang menjadi `boxblur=luma_radius=min(h\,w)/40:luma_power=2[blurred]`.
  3. Memastikan overlay presisi di tengah kanvas via `overlay=(W-w)/2:(H-h)/2[outv]`.
- **Kualitas & Arsitektur**:
  - `flutter analyze --fatal-infos` -> **0 issues found**.
  - `flutter test` -> **107/107 passed** (0 gagal, 0 di-skip).
  - `lib/core/services/filter_builders.dart`: 154 LOC (plafon <= 400 LOC).

---

## 2. Sintaks Filtergraph FFmpeg Verbatim Baru

### Mode Portrait (Vertical 9:16)
```bash
[0:v]split=2[bg][fg];[bg]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=luma_radius=min(h\,w)/40:luma_power=2[blurred];[fg]scale=w=1026:h=1824:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[main];[blurred][main]overlay=(W-w)/2:(H-h)/2[outv];[outv]setpts=0.9723*PTS,eq=brightness=-0.0034:contrast=1.0041:saturation=0.9982,noise=alls=4:allf=t+u,scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p
```

### Mode Landscape (Horizontal 16:9)
```bash
[0:v]split=2[bg][fg];[bg]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=luma_radius=min(h\,w)/40:luma_power=2[blurred];[fg]scale=w=1824:h=1026:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[main];[blurred][main]overlay=(W-w)/2:(H-h)/2[outv];[outv]setpts=0.9723*PTS,eq=brightness=-0.0034:contrast=1.0041:saturation=0.9982,noise=alls=4:allf=t+u,scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p
```

---

## 3. Matriks Perbandingan Parameter

| Komponen | Implementasi Lama | Rekalibrasi Laporan 48 | Efek Visual |
|---|---|---|---|
| **Foreground Width (Portrait)** | `iw*0.95` (bergantung resolusi sumber) | `w=1026:h=1824` (95% kanvas target) | Selalu menempati 95% area kanvas target |
| **Foreground Width (Landscape)**| `iw*0.95` (bergantung resolusi sumber) | `w=1824:h=1026` (95% kanvas target) | Selalu menempati 95% area kanvas target |
| **Aspect Ratio Preservation**  | Tidak ada flag proteksi | `force_original_aspect_ratio=decrease` | Video tidak pernah terdistorsi atau gepeng |
| **Margin Blurred Border**      | Dinamis/acak (bisa >20% jika resolusi kecil) | **Konsisten tepat ~2.5% per sisi** | Tampilan seragam, modern, dan profesional |
| **Blur Radius Divisor**        | `/35` | `/40` | Latar belakang buram yang lebih halus dan bersih |

---

## 4. Hasil Verifikasi Pengujian

- `flutter test test/ffmpeg_service_test.dart` -> **30/30 passed** (termasuk validasi kanvas portrait `w=1026:h=1824` dan landscape `w=1824:h=1026`).
- `flutter test` (seluruh suite aplikasi) -> **107/107 passed**.
- `flutter analyze --fatal-infos` -> **0 issues found**.

---

## 5. MCP Evidence Appendix

| MCP Tool | Kueri / Parameter | Hasil & Metrik | Status Verifikasi |
|---|---|---|---|
| `mcp__codebase_memory_mcp__index_status` | Pre-task check | 1729 nodes, 4172 edges, status: ready | Terverifikasi |
| `mcp__codebase_memory_mcp__index_repository` | Mode `full` | Status: indexed, 1729 nodes, 4172 edges | Terverifikasi |
