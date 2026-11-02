# Technical Report 62: Real Bundled Real-ESRGAN NCNN Vulkan Neural Weights & Crystal-Clear 2K/4K Pipeline

**Project:** `nra_video_uniquifier`  
**Sprint:** 62  
**Date:** October 31, 2026  
**Status:** Complete & Verified  

---

## 1. Executive Summary
Sprint 62 remedies the root causes of visual blurriness and silent degradation during video upscaling. The official neural model weights (`realesr-animevideov3-x2` and `x4` `.param` & `.bin`) have been bundled directly into `assets/models/` and registered in Flutter asset packaging. The filterchain was overhauled to bypass destructive `hqdn3d` filtering during upscale, inject pre-scale edge definition (`unsharp=3:3:0.6:3:3:0.0`), upgrade Lanczos interpolation with accurate rounding (`lanczos+accurate_rnd` + `unsharp=5:5:1.2:5:5:0.5`), and enforce high-fidelity encoding (`-crf 17 -preset medium -tune film`) on 2K/4K exports.

---

## 2. Root Cause Analysis
1. **Asset Void:** The previous APK did not bundle physical Real-ESRGAN binary weights (`.bin`/`.param`), causing neural execution to fall back to standard scaling.
2. **Destructive Denoise Stacking:** `hqdn3d=1.5:1.5:4:4` was actively applied before scaling, wiping away high-frequency facial textures, hair, and edges.
3. **Lossy Compression:** High compression settings smoothed out restored detail on 2K/4K targets.

---

## 3. Architecture & Implementation Changes

### 3.1 Neural Asset Bundling & Staging
- Bundled official binaries in `assets/models/`:
  - `realesr-animevideov3-x2.bin` (1.25 MB)
  - `realesr-animevideov3-x2.param` (3.17 KB)
  - `realesr-animevideov3-x4.bin` (1.25 MB)
  - `realesr-animevideov3-x4.param` (3.08 KB)
- Registered assets in `pubspec.yaml`.
- Implemented `prepareModelAssets()` in `AiSuperResolutionService` to unpack model assets to app cache directory on first run.

### 3.2 Filtergraph & Encoding Overhaul (`filter_builders.dart`)
- **Denoise Bypass:** When `upscale: true`, `hqdn3d` is bypassed to preserve source micro-textures.
- **Pre-Scale Edge Clarity:** Injected `unsharp=3:3:0.6:3:3:0.0` before spatial upscaling.
- **High-Acuity Lanczos:** Updated terminal scale to `scale=w=TARGET_W:h=TARGET_H:flags=lanczos+accurate_rnd,unsharp=5:5:1.2:5:5:0.5`.
- **Lossless Acuity Encoding:** 2K and 4K resolutions enforce `-crf 17 -preset medium -tune film` across both H.264 and H.265.
- **Strict Budget Compliance:** Split helper methods (`_resolveCodecArgs`, `_buildSpatialCrop`, `_fallbackVideoFilter`) ensuring `filter_builders.dart` functions stay <= 40 lines and the file is under 250 LOC.

---

## 4. Verification & Quality Gates
- **`flutter analyze --fatal-infos`:** 0 issues found (clean pass).
- **`flutter test`:** 120/120 tests passed across all unit, widget, and integration test suites.
- **Code Limits:** Every file in `lib/` <= 400 LOC, functions <= 40 LOC.

---

## 5. MCP Evidence Appendix
- `tools["codebase-memory-mcp"].index_repository`: Full re-indexing executed.
- `tools["codebase-memory-mcp"].index_status`: 1953 nodes, 4775 edges, status ready.
- `search_graph`: Symbol references verified for `AiSuperResolutionService` and `FilterBuilders`.
