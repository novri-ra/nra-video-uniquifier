# Report 145: Fix LUT Absolute Path Resolution & Asset Extraction

- **Date:** November 15, 2026
- **Status:** Complete / Verified
- **Scope:** Runtime bugfix for LUT feature where FFmpeg failed to read bundled asset `.cube` files directly via Flutter asset paths (`assets/...`). Implemented asset extraction to temporary storage via `rootBundle` and resolved absolute file paths.

---

## 1. Executive Summary
Report 144 introduced LUT feature wiring, passing `lutName` directly into filter strings (`lut3d='assets/luts/$lutName.cube'`). However, native FFmpeg binaries running on Android/iOS/Desktop cannot resolve Flutter package asset URIs directly. 

In Report 145, we resolved this by mirroring the robust asset extraction pattern used in `AiSuperResolutionService`. We created `FfmpegFileHelper.resolveLutPath(lutName)` to bundle-load and extract `.cube` assets to cache storage, passing the resulting absolute filesystem path (`lutPath`) through `FfmpegCommandBuilder` and `FilterBuilders`.

---

## 2. Implementation Details

### A. Asset Extraction Helper (`FfmpegFileHelper`)
- Added `resolveLutPath(String? lutName)`:
  1. Checks if `lutName` is empty/null.
  2. Ensures cache directory `getTemporaryDirectory()/luts` exists.
  3. Checks if extracted `.cube` file exists on disk; if not or empty, loads via `rootBundle.load('assets/luts/$lutName.cube')` and writes bytes.
  4. Returns the absolute file path string.

### B. Service & Pipeline Plumbing (`FfmpegService` & `FfmpegCommandBuilder`)
- Updated `FfmpegService.processVideo` to asynchronously resolve the LUT absolute path prior to building commands.
- Renamed parameter `lutName` to `lutPath` across `FfmpegCommandBuilder` and `FilterBuilders`.

### C. FilterBuilders Update
- Updated `FilterBuilders.buildVideoFilter` to accept `lutPath` and inject `lut3d='$lutPath'` directly into the filterchain.

---

## 3. Verification & Test Results
- **`dart analyze --fatal-infos`**: Clean exit `0` (No issues found).
- **`flutter test`**: **229/229 tests passed successfully**.
- **`git status --short`**: Cleanly tracks all modified services and context files.
