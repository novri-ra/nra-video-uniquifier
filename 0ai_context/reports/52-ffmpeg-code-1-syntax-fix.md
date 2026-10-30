# Laporan 52: Diagnosis dan Perbaikan Crash FFmpeg Exit Code 1 Akibat Sintaks Filtergraph Evasion Baru

## 1. Executive Summary & Audit Verdict

- **Masalah Utama**:
  Eksekusi render pada aplikasi mengalami kegagalan dengan pengecualian:
  `"Exception: FFmpeg failed with code 1 - Processing Failed: Out of Memory or Unsupported Format"`.
- **Penyebab Akar (Root Cause Analysis)**:
  1. **Koma Tanpa Escape pada Ekspresi `zoompan`**:
     Pada ekspresi `zoompan=z='if(lte(zoom,1.0),1.08,max(1.001,zoom-0.0015))'`, terdapat karakter koma `,` di dalam pemanggilan fungsi evaluasi matematis (`if(...)` dan `max(...)`). Saat `ffmpeg-kit` memecah argumen perintah pada runtime Android, tanda kutip tunggal dilepaskan (*stripped*), menyebabkan parser tokenisasi filtergraph FFmpeg menganggap koma tersebut sebagai pemisah filter baru (*filterchain delimiter*). FFmpeg gagal mem-parsing dan melempar error: `No option name near '1'` / `Error parsing filterchain`.
  2. **Penempatan Filter `decimate` yang Terlalu Awal**:
     Filter `decimate=cycle=25` sebelumnya diletakkan sebelum filter spasial dan pewarnaan (`upscale`, `hqdn3d`, `unsharp`). Karena `decimate` memangkas 1 frame per siklus 25 frame, filter temporal berikutnya menerima desinkronisasi timestamp dan frame buffer pad yang rusak.
  3. **Dimensi Hardcoded pada `_buildPostCanvasFilters`**:
     Argumen `zoompan` pada `_buildPostCanvasFilters` sebelumnya mengunci `s=1080x1920` secara statis, menyebabkan korupsi aspek rasio dan kegagalan alokasi buffer saat memproses video landscape (1920×1080).
  4. **Ketiadaan Logging Konsol Native FFmpeg saat Error**:
     Pada `FfmpegService._executeFFmpeg`, ketika eksekusi gagal, buffer string log lengkap dibentuk namun tidak dipancarkan ke `debugPrint`, sehingga teknis kegagalan native FFmpeg tertutup dari logcat.
- **Solusi Rekayasa & Implementasi**:
  1. Meng-escape seluruh koma di dalam ekspresi `zoompan` dengan `\,` (`if(lte(zoom\,1.0)\,1.08\,max(1.001\,zoom-0.0015))`), menjamin parser FFmpeg tidak pernah memecah ekspresi matematis menjadi filter terpisah.
  2. Menata ulang urutan filter secara berurutan dan disiplin:
     `canvas/scale -> spatial crop/tilt -> color/curves -> noise -> decimate -> format=yuv420p`.
  3. Mengikat dimensi `s=$zoomDim` secara dinamis pada `_buildPostCanvasFilters` sesuai orientasi portrait (`1080x1920`) atau landscape (`1920x1080`).
  4. Menambahkan `debugPrint(buffer.toString())` di `FfmpegService._executeFFmpeg` agar log kegagalan native FFmpeg langsung terpampang transparan di konsol.
- **Hasil Kualitas**:
  - `flutter analyze --fatal-infos` -> **0 issues found**.
  - `flutter test` -> **111/111 passed** (memvalidasi urutan filter presisi dan sintaks `zoompan` escaped).
  - Seluruh berkas di `lib/` patuh plafon `<= 381 LOC` (batas maksimal 400 LOC).
  - Seluruh fungsi `<= 40 baris`.

---

## 2. Matriks Perbandingan Sintaks Filtergraph (Before vs After)

| Komponen | Implementasi Bermasalah (Sprint 50) | Implementasi Hardened (Sprint 52) | Status Verifikasi |
|---|---|---|---|
| **Ekspresi `zoompan` `z`** | `z='if(lte(zoom,1.0),1.08,max(1.001,zoom-0.0015))'` (koma unescaped) | `z='if(lte(zoom\,1.0)\,1.08\,max(1.001\,zoom-0.0015))'` (koma `\,` escaped) | **TERVALIDASI** (`test/ffmpeg_service_test.dart`) |
| **Dimensi Canvas `zoompan`** | `s=1080x1920` hardcoded di post-canvas | `s=$zoomDim` dinamis portrait/landscape | **TERVALIDASI** |
| **Posisi `decimate`** | Di tengah sebelum `upscale` & `hqdn3d` | Tepat sebelum format akhir: `noise -> decimate -> format=yuv420p` | **TERVALIDASI** |
| **Posisi `upscale`** | Berpindah-pindah | `crop -> rotate -> hflip -> zoompan -> upscale -> denoise` | **TERVALIDASI** |
| **Error Logging** | Hanya disimpan ke `Exception` tanpa print | `debugPrint(buffer.toString())` mencetak seluruh stack & native log | **TERVALIDASI** |

---

## 3. Verbatim Filtergraph Hardened String

### Kasus: Seluruh 15 Modifiers Aktif Sekaligus
```bash
-y -ss 0.5 -t 4.00 -i "input.mp4" -map_metadata -1 -map_chapters -1 -bitexact -fflags +bitexact -metadata make="Apple" -metadata model="iPhone 15 Pro Max" -metadata encoder="Apple QuickTime" -metadata:s:v:0 handler_name="Core Media Video" -metadata:s:a:0 handler_name="Core Media Audio" -vf "[0:v]split=2[bg][fg];[bg]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=luma_radius=min(h\,w)/40:luma_power=2[blurred];[fg]scale=w=1026:h=1824:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[main];[blurred][main]overlay=(W-w)/2:(H-h)/2[outv];[outv]setpts=0.9723*PTS,hflip,zoompan=z='if(lte(zoom\,1.0)\,1.08\,max(1.001\,zoom-0.0015))':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=1080x1920:fps=30,hqdn3d=1.5:1.5:4:4,unsharp=3:3:0.6:3:3:0.0,curves=all='0/0 0.15/0.18 0.5/0.5 0.85/0.82 1/1',eq=brightness=-0.0034:contrast=1.0041:saturation=0.9982,noise=alls=4:allf=t+u,noise=alls=5:allf=t+u,decimate=cycle=25,scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p" -c:v libx265 -preset fast -crf 26 -tag:v hvc1 -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv -movflags +faststart -af "volume=0.01,atempo=1.028489" -c:a aac -b:a 128k -r 29.85 "output.mp4"
```

---

## 4. Hasil Verifikasi Pengujian

- `flutter analyze --fatal-infos` -> **0 issues found**.
- `flutter test` (111/111 passed):
  - `test/ffmpeg_service_test.dart` -> 32/32 passed (termasuk verifikasi ketat urutan `idxCanvas < idxZoom < idxCurves < idxNoise < idxDecimate < idxFormat`).
  - `test/setting_toggle_row_test.dart` -> 2/2 passed.
  - `test/settings_service_test.dart` -> 13/13 passed.
  - `test/uniquifier_provider_test.dart` -> 21/21 passed.
  - `test/widget_test.dart` -> 13/13 passed.
  - Seluruh suite pengujian lainnya -> 30/30 passed.

---

## 5. MCP Evidence Appendix

| MCP Tool | Kueri / Parameter | Hasil & Metrik | Status Verifikasi |
|---|---|---|---|
| `mcp__codebase_memory_mcp__index_status` | Pre-task check | 1800 nodes, 4358 edges, status: ready | Terverifikasi |
| `mcp__codebase_memory_mcp__index_repository` | Mode `full` | Status: indexed, 1800 nodes, 4358 edges | Terverifikasi |
