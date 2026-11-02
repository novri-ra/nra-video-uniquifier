# 11-device-run-test: Android Physical Device Run & Runtime Verification

## Task Summary
Detected attached physical Android test device (`Realme RMX1851`, Android 15 / API 35), resolved Android NDK, AGP subproject `compileSdk 36` dependencies, compiled `app-debug.apk`, streamed install via ADB, launched the application on the hardware device, and captured screenshots confirming live interactive rendering across all 3 navigation tabs.

## Skills Loaded
- `flutter-expert`
- `systematic-debugging`

## MCP Evidence
- **Server**: `codebase-memory-mcp`
- **Project**: `C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier`
- **Graph Status**: ready (866 nodes, 1,848 edges).
- **Stability**: Zero schema drift, zero code regression.

## Detected Device Information
- **Device Model**: Realme 3 Pro (`RMX1851`)
- **Serial / ADB ID**: `5e599699`
- **CPU / ABI**: `arm64-v8a` (Snapdragon 710)
- **OS Version**: Android 15 (API 35)
- **Screen Resolution**: 1080 x 2340

## Build & Installation Details
- **NDK Resolved**: Side-by-side NDK `28.2.13676358` installed via `sdkmanager`.
- **AGP Subproject Alignment**:
  - `flutter_plugin_android_lifecycle` required `compileSdk = 36`.
  - Added Gradle subproject `afterEvaluate` hook in `android/build.gradle.kts` dynamically assigning `compileSdkVersion(36)` to plugins such as `:file_picker`.
  - Added `id("com.android.library") version "9.1.0" apply false` in `android/settings.gradle.kts`.
- **Build Output**: `build/app/outputs/flutter-apk/app-debug.apk` (318 MB).
- **Install Verdict**: `Performing Streamed Install -> Success` in 10s.

## Runtime Bootstrap & Telemetry
```log
I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(104)] Using the Impeller rendering backend (OpenGLES).
I flutter : The Dart VM service is listening on http://127.0.0.1:41759/yRtXd9sXDRs=/
D ffmpeg-kit-flutter: FFmpegKitFlutterPlugin created com.antonkarpenko.ffmpegkit.FFmpegKitFlutterPlugin@ebf3f8b.
I ffmpeg-kit: Loaded ffmpeg-kit-full-gpl-arm64-v8a-6.0-20250810.
I ffmpeg-kit-flutter: FFmpegKitFlutterPlugin method channel was already initialised.
D nativeloader: Load .../libdartjni.so using class loader ns clns-7: ok
```

## Visual UI Verification (Screenshots Captured)
1. **Process Screen (`device-screenshot.png`)**:
   - Status badge: `OFFLINE` (green).
   - Card: `video_01.mp4`, `1080x1920`, `24.8 MB`, `H.264`, `60 FPS`, `AAC 48kHz`.
   - Modifiers: Metadata (ON), Audio (ON), Visuals (ON), Upscale (OFF).
   - Engine strip: `GPU Accel: Metal / GLES (A... Est. Render: ~2.4s`.
   - CTA button: `Process Video`.
2. **Presets Screen (`device-screenshot-presets.png`)**:
   - `TikTok Fast Mode` (Speed Optimized).
   - `Maximum Anti-Fingerprint` (Max Stealth).
   - `Lossless Stealth` (Instant Render).
3. **Inspect / History Screen (`device-screenshot-inspect.png`)**:
   - Storage bar: `Local Sandbox Storage: 0.0 KB used`.
   - Isolation badge: `V-SANDBOX ISOLATION: ACTIVE • ZERO NETWORK LEAK`.
   - Empty state: `No exported videos yet`.

## Test & Static Analysis Results
- `flutter analyze`: **0 issues found** (passed).
- `flutter test`: **27/27 tests passed** (0 failures, 0 errors, 0 skips).

## Next Steps
- Commit Gradle build fix to `development` branch.
- Push to remote `origin/development`.
- Implement end-to-end video processing flow on device with sample media.
