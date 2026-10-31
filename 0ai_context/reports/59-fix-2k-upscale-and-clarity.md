# Report 59: Fix 2K Upscale Output Clamping and Real-ESRGAN NCNN Blurriness

**Status:** Completed  
**Branch:** `development`  
**Date:** October 31, 2026  
**Scope:** Pipeline filter generation, dynamic canvas scaling, upscale clarity enhancement, and fallback transparency.

---

## 1. Executive Summary & Root Cause Analysis

### Problem 1: 2K Upscale Output Clamping to 1080p Under Blurred Canvas
- **Symptom:** User selected "2K" (1440x2560 for portrait) with 720x1280 input. Rendered output in MX Player remained locked at 1080x1920 (1080p).
- **Root Cause:**
  1. `FilterBuilders._buildCanvasChain` hardcoded background and foreground target dimensions to `1080:1920` (`isPortrait ? '1080:1920' : '1920:1080'`). Whenever Blurred Canvas was active, the canvas split filter generated a 1080p frame regardless of whether 2K or 4K target resolution was requested.
  2. `_buildPostCanvasFilters` did not scale the canvas composite up to the requested target resolution when `upscale` was flagged, and hardcoded `zoompan` target dimensions to `1080x1920`.
- **Remediation:**
  - Added `TargetResolution targetResolution` parameter to `_buildCanvasChain` and `_buildPostCanvasFilters`.
  - Replaced hardcoded dimensions with `canonicalDimensions(targetResolution, isPortrait: isPortrait)`.
  - Background scale and crop now dynamically generate `1440:2560` for 2K portrait, `2160:3840` for 4K portrait, and foreground scales proportionally based on `canvasScalePercent`.
  - Ensured `_buildPostCanvasFilters` applies `buildScaleFilter` when `upscale` is enabled.

### Problem 2: Real-ESRGAN NCNN Blurriness & Silent Fallback
- **Symptom:** Scaling from 720p to 2K/4K appeared soft, blurry, or washed-out without edge sharpness. On non-Vulkan devices, neural upscaling fell back silently to Lanczos3 without developer/telemetry notice.
- **Root Cause:**
  1. `AiSuperResolutionService.resolvePlan()` silently switched `isFallbackEngaged: true` without logging or notifying when Vulkan hardware support was absent.
  2. Mathematical and neural upscaling pipelines lacked an unsharp mask filter to preserve edge-contrast after spatial interpolation, resulting in softness when blowing up lower resolutions (e.g., 720p -> 1440p/2160p).
- **Remediation:**
  - `AiSuperResolutionService.resolvePlan()` logs explicit diagnostic notice when Vulkan compute is unavailable and fallback engages: `debugPrint('[AiSuperResolution] Vulkan compute unavailable on this device. Transparent fallback: Real-ESRGAN -> Lanczos3.')`.
  - `FilterBuilders.buildScaleFilter` appends post-upscale clarity filter (`unsharp=5:5:0.7:5:5:0.3`), ensuring crisp edge definition across all target resolutions.

---

## 2. Canvas Pipeline Target Resolution Dynamic Scaling (Before vs After)

### Filter Chain Comparison

| Aspect | Before Fix | After Fix |
|---|---|---|
| **Canvas Background (2K Portrait)** | `scale=1080:1920:...,crop=1080:1920` | `scale=1440:2560:...,crop=1440:2560` |
| **Canvas Foreground (2K Portrait, 95%)** | `scale=w=1026:h=1824:...` | `scale=w=1368:h=2432:...` |
| **Canvas Background (4K Portrait)** | `scale=1080:1920:...,crop=1080:1920` | `scale=2160:3840:...,crop=2160:3840` |
| **Canvas Foreground (4K Portrait, 95%)** | `scale=w=1026:h=1824:...` | `scale=w=2052:h=3648:...` |
| **Zoompan Bounds** | Hardcoded `1080x1920` / `1920x1080` | Dynamically derived `canonicalDimensions` |
| **Terminal Scale** | Omitted / clamped in post-canvas | `scale=w=TARGET_W:h=TARGET_H:flags=lanczos,unsharp=5:5:0.7:5:5:0.3` |

---

## 3. Clarity & Sharpening Remediation Details

### Adaptive Edge Sharpening
- **Filter Applied:** `unsharp=5:5:0.7:5:5:0.3`
  - Luma matrix size: `5x5`, amount: `0.7` (restores micro-edge acuity without ringing or haloing).
  - Chroma matrix size: `5x5`, amount: `0.3` (maintains color contrast without color fringing).
- Integrated directly into `FilterBuilders.buildScaleFilter`, ensuring both standalone upscaling and post-canvas upscaling deliver sharp footage when scaling 720p inputs to 2K (1440x2560) or 4K (2160x3840).

---

## 4. Quality Gates & Test Assertions

### Code Budget Verification
- `lib/core/services/filter_builders.dart`: 244 LOC (<= 400 LOC budget).
- `lib/core/services/ai_super_resolution_service.dart`: 115 LOC (<= 400 LOC budget).
- All functions <= 40 lines.

### Unit Tests
- `test/ffmpeg_service_test.dart`:
  - Verified 2K portrait canvas generates `scale=1440:2560` and `crop=1440:2560`.
  - Verified 2K portrait foreground generates `scale=w=1368:h=2432`.
  - Verified 4K portrait canvas generates `scale=2160:3840` and `crop=2160:3840`.
  - Verified 4K portrait foreground generates `scale=w=2052:h=3648`.
  - Verified terminal scale includes `unsharp=5:5:0.7:5:5:0.3`.
- `flutter analyze --fatal-infos`: 0 issues found.
- `flutter test`: 118/118 tests passed across all suites.

---

## 5. Mandatory MCP Evidence Appendix

| Evidence ID | Tool / Action | Query / Target | Result Summary |
|---|---|---|---|
| E1 | `codebase-memory-mcp.index_status` | Working directory root | 1916 nodes, 4679 edges, status `ready` |
| E2 | `grep` | `_buildCanvasChain` | Found definition in `filter_builders.dart:6` with hardcoded 1080:1920 dimensions |
| E3 | `grep` | `canonicalDimensions` | Verified 2K maps to (1440, 2560) portrait, (2560, 1440) landscape |
| E4 | `grep` | `AiSuperResolutionService` | Verified `resolvePlan` and fallback engagement logic |
| E5 | `flutter test` | Full test suite | 118 unit and widget tests passing cleanly |
