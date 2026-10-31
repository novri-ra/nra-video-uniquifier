# Report 29: Color Corruption Remediation, H.264/H.265 Codec Engine, and Dedicated Settings Screen

## 1. Executive Summary
- Remedied video color corruption (neon green/magenta artifacts) and TikTok/Instagram ingest rejection caused by RGB planar conversions (`gbrp`) in the FFmpeg filtergraph.
- Enforced non-destructive YUV-domain evasion via `eq=contrast=1.03:saturation=1.04`, terminated filtergraphs explicitly with `format=yuv420p`, and injected standard output flags: `-pix_fmt yuv420p`, `-movflags +faststart`, `-colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv`.
- Engineered configurable Video Codec engine (`VideoCodec.h264` vs `VideoCodec.h265`) with `-tag:v hvc1` for Apple/Android hardware playback compatibility.
- Implemented dedicated Settings tab (`SettingsScreen`, 330 LOC) in root navigation bar, reducing `root_navigation_screen.dart` from 343 to 69 LOC.
- Maintained strict code limits across the entire repository (all files in `lib/` <= 400 LOC). All 80 unit/widget tests passing with zero analyze warnings.

---

## 2. Root Cause Analysis: Color Space Corruption
1. **The Bug**:
   - The FFmpeg video filter pipeline in `ffmpeg_service.dart` included `curves=preset=vintage`.
   - `curves` filter in FFmpeg operates natively in RGB colorspace, forcing automatic intermediate conversion from planar YUV (`yuv420p`) into planar GBR (`gbrp` or `rgb24`).
   - When fed into encoders without explicit color space tagging or pixel format termination, mobile hardware decoders (MediaCodec / ExoPlayer) and platform ingest pipelines (TikTok, Instagram) misinterpret chroma channel planes, manifesting as neon green/magenta discoloration, inverted hues, or fatal container upload rejections.
2. **The Fix**:
   - Completely purged `curves=preset=vintage`.
   - Replaced with direct YUV-domain adjustment: `eq=contrast=1.03:saturation=1.04` (does not touch or convert chroma subsampling).
   - Terminated filtergraph chain explicitly with `format=yuv420p`.
   - Enforced container flags on encoder:
     `-pix_fmt yuv420p`
     `-movflags +faststart`
     `-colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv`

---

## 3. Configurable Video Codec Engine (H.264 vs H.265)
- Defined `enum VideoCodec { h264, h265 }` with user-friendly display labels in `settings_service.dart`.
- Persisted preference under `app_video_codec` via `SharedPreferences` with reactive `videoCodecNotifier`.
- Exposed `videoCodec` getter and `setVideoCodec` mutator in `uniquifier_provider.dart`.
- Dynamically generates codec parameters:
  - `VideoCodec.h264`: `-c:v libx264 -preset fast -crf 22`
  - `VideoCodec.h265`: `-c:v libx265 -preset fast -crf 26 -tag:v hvc1`
- Wired through single video processing (`ProcessingScreen`) and sequential batch processing (`BatchQueueProvider`).

---

## 4. Dedicated Settings Screen in Root Navigation
- Created `lib/features/settings/screens/settings_screen.dart` (330 LOC):
  - **Video Codec Card**: Radio tile selection between H.264 (TikTok Universal) and H.265 (High Efficiency).
  - **Default Resolution Selector**: 1080p Lanczos, 2K QHD, 4K UHD.
  - **Hardware Acceleration**: MediaCodec / OpenGL toggle.
  - **Background & Alerts**: Background processing & notification sound toggles.
  - **Storage & Cache Maintenance**: Real-time display of temporary file cache size (`getTempCacheSize`) with `purgeTempCache` action.
  - **App Information**: v1.0.0 status, offline privacy guarantee badge.
- Re-architected `lib/features/navigation/screens/root_navigation_screen.dart`:
  - Expanded from 2 tabs to 3 clean tabs:
    - Tab 0: Process (`Icons.auto_fix_high`)
    - Tab 1: History (`Icons.history`)
    - Tab 2: Settings (`Icons.tune_rounded`)
  - Pruned unused embedded preset screens, dropping file size from 343 to 69 lines.

---

## 5. Line Budget Verification
All files in `lib/` strictly obey the <= 400 LOC ceiling:
- `lib/core/providers/uniquifier_provider.dart`: 387 LOC
- `lib/core/services/ffmpeg_service.dart`: 378 LOC
- `lib/features/settings/screens/settings_screen.dart`: 330 LOC (<= 350 LOC requirement)
- `lib/features/process/screens/processing_screen.dart`: 323 LOC
- `lib/features/process/widgets/source_file_section.dart`: 319 LOC
- `lib/features/navigation/screens/root_navigation_screen.dart`: 69 LOC

---

## 6. Verification Results
1. `flutter analyze --fatal-infos`:
   - Output: `No issues found! (ran in 5.2s)`
2. `flutter test`:
   - Output: `All 80 tests passed!`
   - Asserted `format=yuv420p`, `-pix_fmt yuv420p`, `-movflags +faststart`, BT.709 tags, H.264/H.265 arguments, and zero presence of `curves=preset=vintage`.

---

## 7. MCP Evidence Appendix
| MCP Tool | Target / Query | Result Counts |
|---|---|---|
| `mcp__codebase_memory_mcp__list_projects` | `detail: "stats"` | 4 projects, `nra_video_uniquifier` selected |
| `mcp__codebase_memory_mcp__index_status` | `project: "C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier"` | Initial: 1310 nodes, 3283 edges |
| `mcp__codebase_memory_mcp__index_repository` | `repo_path: "C:/Users/Administrator/Saved Games/_Project/nra_video_uniquifier", mode: "full"` | Re-indexed: 1328 nodes, 3371 edges |
| `mcp__codebase_memory_mcp__index_status` | Post-index verification | Status: ready, 1328 nodes, 3371 edges |
