# NRA Video Uniquifier

Cross-platform offline video deduplication, anti-fingerprint evasion, and AI/Lanczos upscaling tool built with Flutter and FFmpegKit. Modifies metadata, audio pitch, subtle visual scaling/crops, dynamic blurred canvas framing, and handles 1080p, 2K, and 4K upscaling on-device without network transmission.

---

## Key Capabilities & Features

- **Zero Network Transmission**: 100% on-device processing isolate with zero external telemetry or cloud upload.
- **15 Evasion Modifiers**:
  1. Metadata Strip & Hardware Profile Masquerade (iPhone/Samsung camera EXIF)
  2. Audio Frequency EQ & Spectrum Modulation
  3. Audio Tempo / Pitch Reciprocal Time-Scale Adjustment
  4. Subtle Micro-Crop Border Evasion (>= 7% margin)
  5. Micro-Tilt Rotation (with inner-box mathematical crop eliminating black letterbox corners)
  6. Color Space / Gamma / Hue Micro-Drift (+/-0.01 threshold)
  7. Horizontal Flip (`hflip`)
  8. Aggressive Audio Masking (Pink noise mixing via `amix`)
  9. Auto-Trim Seek (Trims leading 500ms and trailing margins safely)
  10. Dynamic Blurred Canvas Frame (Centered foreground over Gaussian-blurred target-scaled background)
  11. Mute Original Audio (Volume ducking to near-zero for platform background audio overlay)
  12. Dynamic Continuous Zoom (`zoompan` smooth respiratory scaling)
  13. Dynamic Frame Decimation (`fps` / frame drop cadence)
  14. Chroma Channel Shift (`colorbalance` subtle sub-channel offset)
  15. Micro-Noise Dither Overlay (`noise` grain generator preventing spatial hash matching)
- **Dual Upscale Engine**:
  - **Lanczos3 Mathematical Scaler**: Fast, deterministic, hardware-friendly multi-tap sinc filter.
  - **Real-ESRGAN Neural AI Super-Resolution**: C++ JNI NCNN Vulkan compute bridge with transparent Lanczos fallback when GPU Vulkan is unavailable.
- **Canonical Standard Resolutions**:
  - **1080p Full HD**: Portrait `1080x1920` / Landscape `1920x1080`
  - **2K Quad HD**: Portrait `1440x2560` / Landscape `2560x1440`
  - **4K Ultra HD**: Portrait `2160x3840` / Landscape `3840x2160`
- **Scoped Storage Compliance**: 2-stage staged internal sandbox rendering (`app_flutter/cache/staged_*.mp4`) with safe atomic export to public `Movies/VideoUniquifier/` via `MediaScannerService`.
- **Codebase Health**:
  - 100% compliant with strict line budget: all files in `lib/` <= 400 LOC, functions <= 40 LOC.
  - 118 unit and widget smoke tests passing (0 failures, 0 warnings).

---

## Architecture Overview

```
                      +---------------------------------------+
                      |       Flutter UI Layer (Dark)        |
                      |  ProcessScreen | Settings | History   |
                      +-------------------+-------------------+
                                          |
                                          v
                      +---------------------------------------+
                      |   State: UniquifierProvider           |
                      |   15 Modifier Toggles + Presets       |
                      +-------------------+-------------------+
                                          |
                                          v
                      +---------------------------------------+
                      |         FfmpegService Engine          |
                      | Stage 1: Build Filtergraph Chain      |
                      +-------------------+-------------------+
                                          |
         +--------------------------------+--------------------------------+
         |                                                                 |
         v                                                                 v
+-----------------------------+                           +--------------------------------+
|  Internal Sandbox Storage   |                           |    Dual Upscale Strategy       |
|  cache/staged_*.mp4         |                           |  Lanczos3 / NCNN Vulkan AI     |
+--------------+--------------+                           +----------------+---------------+
               |                                                           |
               +--------------------------+--------------------------------+
                                          |
                                          v
                      +---------------------------------------+
                      |   Diagnostic & Public Export Pipeline |
                      |   RenderDiagnosticService (FFprobe)   |
                      |   MediaScannerService (MediaStore)    |
                      +---------------------------------------+
```

### Filtergraph Order of Operations
```
[0:v] (Canvas Scale / Background Blur)
  -> Spatial Crop / Micro-Tilt Rotation (Inner-box crop)
  -> Dynamic Zoompan (Smooth scale oscillation)
  -> Color Curves & EQ Balance
  -> Micro-Noise Grain Overlay
  -> Frame Decimation / FPS Drop
  -> Canonical Upscale (1080p / 1440p / 2160p) + Unsharp Clarity Restoration
  -> format=yuv420p [outv]
```

---

## Development & Verification

```bash
# Get dependencies
flutter pub get

# Run static analysis (0 issues enforced)
flutter analyze --fatal-infos

# Run full test suite (118/118 passing)
flutter test

# Run application locally
flutter run
```

---

## Production Build Instructions

Compile an optimized, obfuscated, split-per-ABI release APK for Android devices:

```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
```

Generated release artifacts in `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (~59 MB - standard modern 64-bit Android)
- `app-armeabi-v7a-release.apk` (~55 MB - 32-bit legacy Android)
- `app-x86_64-release.apk` (~61 MB - x86_64 emulation / tablet)

---

## Documentation Index
- Architecture blueprint: `0ai_context/SEED.md`
- Active state & roadmap: `0ai_context/STATE.md`
- Sprint reports index: `0ai_context/reports/REPORTS_INDEX.md`
- Latest cleanup report: `0ai_context/reports/60-project-cleanup-and-report-archival.md`
