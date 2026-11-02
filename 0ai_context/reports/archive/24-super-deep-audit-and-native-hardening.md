# Super Deep Forensic Audit & Native Hardening Report

Report ID: `24-super-deep-audit-and-native-hardening`
Date: October 2026 (Hermes Autonomous Environment)
Target: `nra_video_uniquifier`
Branch: `development`
Status: **ACTION REQUIRED**

---

## 1. Executive Summary & Verdict

Forensic evaluation completed across `lib/`, `android/`, and `test/`. The codebase exhibits solid test coverage (62/62 passing tests) and clean lint compliance (`flutter analyze --fatal-infos` passed with zero errors). All 29 Dart files strictly comply with the <= 400 LOC ceiling.

However, forensic inspection identified **3 high-severity issues** requiring immediate remediation:
1. **Algorithmic A/V Desync**: Compounding audio filters (`atempo=1.015` and `asetrate=48000*1.01`) result in a cumulative 2.515% audio speedup against a 1.502% video speedup (`setpts=0.9852*PTS`), creating a severe +5.84s audio drift per 10 minutes of footage.
2. **Lanczos / Rotate Macroblock Parity Break**: Arbitrary angular rotation (`0.4*PI/180`) without dimension truncation produces odd pixel dimensions (e.g. 1039x1831 from 1080x1920 inputs). When upscaling is disabled, `libx264` aborts encoding under `yuv420p` chroma subsampling.
3. **Inactive R8 / ProGuard in Release**: `android/app/build.gradle.kts` lacks `isMinifyEnabled = true`, rendering `proguard-rules.pro` completely inert during release builds.

---

## 2. Raw Terminal Output & Verification Baselines

### 2.1 Static Analysis (`flutter analyze --fatal-infos`)
```
Analyzing nra_video_uniquifier...                               
No issues found! (ran in 3.0s)
```

### 2.2 Full Regression Suite (`flutter test`)
```
00:00 +0: loading C:/Users/Administrator/Saved Games/_Project/nra_video_uniquifier/test/ffmpeg_service_test.dart
...
00:05 +61: C:/Users/Administrator/Saved Games/_Project/nra_video_uniquifier/test/widget_test.dart: Video Uniquifier - Multi-Resolution Responsive Smoke Tests ModifiersCard displays dynamic title and subtitle for resolution state
00:05 +62: All tests passed!
```

---

## 3. Android Native & Release Packaging Audit

### 3.1 ProGuard / R8 & JNI Verification
- **File**: `android/app/build.gradle.kts:33-41`
- **Finding**: While `proguard-rules.pro` is specified under `buildTypes.release`, AGP 8.x defaults `isMinifyEnabled` to `false`. Without explicit `isMinifyEnabled = true`, R8 code shrinking and symbol obfuscation are entirely bypassed.
- **Rule Coverage**: `android/app/proguard-rules.pro` correctly preserves `com.arthenica.ffmpegkit.**`, `com.antonkarpenko.ffmpegkit.**`, `io.flutter.**`, `com.github.dart_lang.jni.**`, and Kotlin coroutine reflection.
- **Remediation**: Add `isMinifyEnabled = true` and `isShrinkResources = true` to `buildTypes.release`.

### 3.2 Multi-ABI Slice Integrity
- **Finding**: Redundant `ndk.abiFilters` was previously removed (`1bfde3b`), enabling clean APK splits (`armeabi-v7a`, `arm64-v8a`, `x86_64`) via `flutter build apk --release --split-per-abi`. `ffmpeg_kit_flutter_new: ^3.1.0` bundles standalone `.so` libraries for all target architectures.

### 3.3 Storage Boundaries & Scoped Storage Compliance
- **File**: `lib/core/services/ffmpeg_service.dart:181-198` and `lib/core/services/history_service.dart:43-64`
- **Finding**: The primary export path attempts write to `/storage/emulated/0/Movies/Uniquifier`. On Android 11+ without `MANAGE_EXTERNAL_STORAGE`, this throws and falls back to `getExternalStorageDirectories(type: StorageDirectory.movies)`.
- **MediaScanner Limitation**: Android MediaStore ignores files inside `Android/data/`. When the fallback path is used, `MediaScannerService.scanFile` succeeds silently, but the video will NOT appear in Android's public gallery.

---

## 4. Algorithmic Correctness & Math Verification

### 4.1 Audio/Video Timing Drift Forensics
- **File**: `lib/core/services/ffmpeg_service.dart:89, 132-139`
- **Video filter**: `setpts=0.9852*PTS` -> duration multiplier = 0.985200 (speedup = 1.015022x).
- **Audio filter**: `atempo=1.015,asetrate=48000*1.01,aresample=48000`.
- **Mathematical flaw**: `asetrate` alters playback sample rate, which changes both pitch AND playback tempo by 1.01x. `atempo=1.015` adds a further 1.015x tempo increase.
- **Compound Audio Multiplier**: `1 / (1.015 * 1.01) = 0.975467` (speedup = 1.02515x).
- **Drift Simulation Table**:
  | Original Duration | Video Duration | Audio Duration | Drift (Video - Audio) | Frame Lag (@30fps) |
  |---|---|---|---|---|
  | 1 min (60s) | 59.112s | 58.528s | +583.98 ms | +17.5 frames |
  | 5 min (300s) | 295.560s | 292.640s | +2,919.90 ms | +87.6 frames |
  | 10 min (600s) | 591.120s | 585.280s | +5,839.80 ms | +175.2 frames |
  | 30 min (1800s) | 1,773.360s | 1,755.841s | +17,519.39 ms | +525.6 frames |
  | 60 min (3600s) | 3,546.720s | 3,511.681s | +35,038.78 ms | +1,051.2 frames |
- **Impact**: On a 10-minute video, audio ends 5.84 seconds before the video, rendering speech completely out of sync.
- **Correction**: If pitch modification via `asetrate=48000*1.01` is desired, adjust `atempo` to compensate: `atempo = 1.015 / 1.01 ≈ 1.00495`, or remove the extraneous `asetrate` multiplier.

### 4.2 Spatial Rotation & Macroblock Alignment
- **File**: `lib/core/services/ffmpeg_service.dart:97-98`
- **Filter**: `rotate=0.4*PI/180:ow=rotw(0.4*PI/180):oh=roth(0.4*PI/180):fillcolor=black`
- **Mathematical flaw**: For 1080x1920 input cropped to 1026x1824:
  - `rotw = 1038.71` -> rounds to 1039 (odd).
  - `roth = 1831.12` -> rounds to 1831 (odd).
- **Impact**: When `upscale` is false (default toggle off), 1039x1831 feeds directly to `-c:v libx264`. H.264 encoders fail fatal: `width/height not divisible by 2`.
- **Correction**: Append `scale=trunc(iw/2)*2:trunc(ih/2)*2` or `pad=ceil(iw/2)*2:ceil(ih/2)*2` immediately after `rotate`.

### 4.3 Synthetic Pink Noise & Spectrogram Invalidation
- **File**: `lib/core/services/ffmpeg_service.dart:133`
- **Filter**: `anoisesrc=d=7200:c=pink:a=0.003[noise];[a0][noise]amix=inputs=2:duration=first[out]`
- **Evaluation**:
  - Noise amplitude `a=0.003` = -50.46 dBFS (dither level, non-intrusive).
  - Pink noise is uncorrelated; zero risk of phase cancellation.
  - Duration ceiling `d=7200` restricts noise generation to 2 hours.
  - `amix` default weights divide input amplitudes by N (dropping master track by 6 dB) unless `dropout_transition=0:weights=1 1` or `normalize=0` is specified.

---

## 5. Security, Injection Defense & Sanitization

### 5.1 CLI Parameter Escaping
- **File**: `lib/core/services/ffmpeg_service.dart:14`
- **Current Escaping**: `_escapePath(String path) => path.replaceAll('"', r'\"');`
- **Finding**: On Windows, file paths contain backslashes `\`. In FFmpegKit argument parsing, unescaped backslashes can be consumed as escape sequences (e.g., `\t` -> tab).
- **Recommendation**: Transition from `FFmpegKit.execute(String command)` to `FFmpegKit.executeWithArguments(List<String> args)` to eliminate parsing ambiguities.

### 5.2 Partial Render & Staged File Deletion
- **File**: `lib/core/services/ffmpeg_service.dart:386-392`
- **Finding**: `_deletePartialFile()` safely handles cancellation and runtime exceptions. However, if the process is terminated abruptly by the Android OS (low memory killer), orphaned `.mp4` and `staged_*.mp4` files remain in `cacheDir` and output directories.
- **Defect in HistoryService**: `lib/core/services/history_service.dart:70-80` checks only `entry.path.toLowerCase().endsWith('.mp4')` without verifying `stat.size > 0`. A 0-byte aborted render is indexed and rendered as a corrupted history item.

---

## 6. Concurrency, Lifecycle & Memory Leak Audit

### 6.1 State Management & Subscriptions
- `UniquifierProvider` properly detaches from `SettingsService.upscaleResolutionNotifier` on `dispose()`.
- `ProcessingScreen` disposes `_controller` and cancels FFmpeg sessions in `dispose()`.

### 6.2 Telemetry Desynchronization Race
- **File**: `lib/features/process/screens/processing_screen.dart:29-50, 91-106`
- **Finding**: `_controller` runs a 4-second animation that updates `_progress` via `_onProgressTick`. Simultaneously, the `onProgress` callback from `FFmpegService` updates `_progress` based on actual render speed. For encodes exceeding 4 seconds, `_controller` and `onProgress` fight over `setState()`, creating erratic visual glitches in the progress bar.

### 6.3 Native Heap & Memory Footprint
- `FFmpegKitConfig.setSessionHistorySize(3)` in `lib/main.dart:11` successfully constrains native log ring-buffers to prevent native heap exhaustion across repeated runs.

---

## 7. Dead Code & Orphan Symbols Table

Audited via MCP `trace_path`, `search_graph`, and AST cross-reference:

| Symbol | File:Line | In-Degree | Out-Degree | Status | Action |
|---|---|---|---|---|---|
| `executePipeline` | `lib/core/services/ffmpeg_service.dart:217` | 0 | 14 | Uncalled wrapper | Remove or deprecate |
| `setOutputThumbnail` | `lib/core/providers/uniquifier_provider.dart:260` | 0 | 0 | Unused setter | Delete |
| `formatBytes` | `lib/core/providers/uniquifier_provider.dart:383` | 0 | 1 | Redundant alias of `formatFileSize` | Delete |
| `targetWidth` | `lib/core/services/settings_service.dart:19` | 0 | 0 | Dead helper | Delete |
| `targetHeight` | `lib/core/services/settings_service.dart:20` | 0 | 0 | Dead helper | Delete |
| `AppColors.background` | `lib/core/theme/app_theme.dart:5` | 0 | 0 | Unused color token | Prune |
| `AppColors.surfaceDim` | `lib/core/theme/app_theme.dart:7` | 0 | 0 | Unused color token | Prune |
| `AppColors.surfaceBright` | `lib/core/theme/app_theme.dart:8` | 0 | 0 | Unused color token | Prune |
| `AppColors.secondaryContainer`| `lib/core/theme/app_theme.dart:22` | 0 | 0 | Unused color token | Prune |
| `AppColors.surfaceTint` | `lib/core/theme/app_theme.dart:23` | 0 | 0 | Unused color token | Prune |
| `lastDiagnosticInfo` | `lib/core/providers/uniquifier_provider.dart:87` | 0 | 0 | State stored, never rendered in UI | Keep for diagnostic UI or prune |

---

## 8. Line Budget Compliance Matrix

Every file in `lib/` satisfies the project rule (<= 400 lines).

| File Path | Total LOC | Status | Max Function Length |
|---|---|---|---|
| `lib/core/providers/uniquifier_provider.dart` | 396 | **Warning** (99.0% of limit) | 36 lines (`applyPreset`) |
| `lib/core/services/ffmpeg_service.dart` | 393 | **Warning** (98.2% of limit) | 38 lines (`_buildVideoFilter`) |
| `lib/features/navigation/screens/root_navigation_screen.dart` | 343 | Pass | 38 lines (`build`) |
| `lib/features/process/screens/processing_screen.dart` | 318 | Pass | 45 lines (`build` widget tree) |
| `lib/features/process/screens/success_screen.dart` | 308 | Pass | 38 lines (`build`) |
| `lib/features/process/widgets/source_file_section.dart` | 308 | Pass | 42 lines (`build` widget tree) |
| `lib/features/process/screens/error_screen.dart` | 247 | Pass | 35 lines (`build`) |
| `lib/features/process/widgets/modifiers_card.dart` | 248 | Pass | 75 lines (`build` widget tree) |
| `lib/features/settings/widgets/upscale_resolution_card.dart` | 238 | Pass | 36 lines (`build`) |
| `lib/features/history/widgets/history_storage_bar.dart` | 199 | Pass | 34 lines (`build`) |
| `lib/features/settings/screens/app_settings_bottom_sheet.dart` | 189 | Pass | 97 lines (`build` widget tree) |
| `lib/features/history/widgets/history_item_card.dart` | 186 | Pass | 45 lines (`build` widget tree) |
| `lib/features/process/screens/process_screen.dart` | 183 | Pass | 32 lines (`build`) |
| `lib/features/history/screens/recent_history_screen.dart` | 179 | Pass | 38 lines (`build`) |
| `lib/features/settings/screens/advanced_settings_bottom_sheet.dart` | 169 | Pass | 35 lines (`build`) |
| `lib/core/services/settings_service.dart` | 168 | Pass | 19 lines (`purgeTempCache`) |
| `lib/features/process/widgets/processing_log_viewer.dart` | 160 | Pass | 36 lines (`build`) |
| `lib/core/services/history_service.dart` | 127 | Pass | 22 lines (`getTargetDirectories`) |
| `lib/shared/widgets/top_app_bar.dart` | 127 | Pass | 35 lines (`build`) |
| `lib/features/settings/widgets/audio_visual_tuning_card.dart` | 126 | Pass | 51 lines (`build` widget tree) |
| `lib/core/theme/app_theme.dart` | 123 | Pass | N/A (declarative tokens) |
| `lib/features/settings/widgets/hardware_acceleration_card.dart` | 113 | Pass | 46 lines (`build` widget tree) |
| `lib/core/services/render_diagnostic_service.dart` | 113 | Pass | 38 lines (`inspectRenderedFile`) |
| `lib/features/process/widgets/processing_radar_indicator.dart` | 97 | Pass | 44 lines (`build` widget tree) |
| `lib/features/process/widgets/engine_state_strip.dart` | 78 | Pass | 32 lines (`build`) |
| `lib/features/process/widgets/processing_stage_tracker.dart` | 64 | Pass | 28 lines (`build`) |
| `lib/main.dart` | 35 | Pass | 14 lines (`main`) |
| `lib/features/history/widgets/history_empty_state.dart` | 30 | Pass | 24 lines (`build`) |
| `lib/core/services/media_scanner_service.dart` | 28 | Pass | 10 lines (`scanFile`) |

---

## 9. Prioritized Remediation Plan

### High Priority
1. **Fix Audio/Video Timing Alignment**: In `lib/core/services/ffmpeg_service.dart`, either remove `asetrate=48000*1.01` from the audio filtergraph or adjust `atempo` to `atempo=1.00495` to eliminate the +5.84s desync on 10-minute videos.
2. **Add Even Macroblock Truncation**: In `lib/core/services/ffmpeg_service.dart:98`, append `scale=trunc(iw/2)*2:trunc(ih/2)*2` after `rotate` to prevent `libx264` aborts when upscaling is disabled.
3. **Enable R8 Minification**: In `android/app/build.gradle.kts:33-41`, add `isMinifyEnabled = true` and `isShrinkResources = true` to `buildTypes.release`.

### Medium Priority
4. **Prevent Progress Telemetry Collision**: In `lib/features/process/screens/processing_screen.dart`, stop `_controller` animation as soon as real FFmpeg `onProgress` events start arriving.
5. **Filter 0-byte Files in History**: In `lib/core/services/history_service.dart:73`, check `stat.size > 0` before adding items to prevent corrupted partial files from rendering.
6. **Automatic Staged Cache Cleanup**: Invoke `SettingsService.purgeTempCache()` on application startup in `main.dart` to clean up abandoned temporary files.

### Low Priority
7. **Eliminate Dead Code**: Remove `executePipeline`, `setOutputThumbnail`, `formatBytes`, `targetWidth`, `targetHeight`, and unused theme tokens.
8. **Decompose High-LOC Files**: Split `uniquifier_provider.dart` (396 LOC) and `ffmpeg_service.dart` (393 LOC) into smaller sub-modules before new features push them past 400 LOC.

---

## 10. Pengakuan Jujur (Honest Admission)

- **Search Graph Degree-0**: Initial query with `max_degree: 0` via `search_graph` yielded 0 results because the MCP graph represents file-to-declaration hierarchy as structural edges, giving every AST node a non-zero degree. True orphan detection was verified by running symbol-reference tracing and `trace_path` caller analysis.
- **Initial Python Escape Error**: An initial bash execution of Python script failed due to an unescaped path separator in an inline string literal; corrected immediately in the subsequent run.

---

## 11. Mandatory MCP Evidence Appendix

| MCP Tool Name | Arguments | Result Count / Findings |
|---|---|---|
| `mcp__codebase_memory_mcp__list_projects` | `detail: "stats"` | 4 projects returned; identified target project `C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier` |
| `mcp__codebase_memory_mcp__index_status` | `project: "...", diagnostics: "summary"` | 1183 nodes, 2871 edges, status `ready` |
| `mcp__codebase_memory_mcp__index_repository` | `repo_path: "...", mode: "full"` | Project fully re-indexed: 1183 nodes, 2873 edges, status `indexed` |
| `mcp__codebase_memory_mcp__search_graph` | `file_pattern: "lib/.*", max_degree: 0` | 0 results (due to AST file-hierarchy edges) |
| `mcp__codebase_memory_mcp__query_graph` | `MATCH (n) WHERE n.file =~ "lib/.*" RETURN count(n)` | 381 nodes in `lib/` |
| `mcp__codebase_memory_mcp__trace_path` | `function_name: "processVideo"` | 1 caller (`executePipeline`), 13 callees |
| `mcp__codebase_memory_mcp__trace_path` | `function_name: "executePipeline"` | 0 callers, 14 callees (confirmed orphan) |
| `mcp__codebase_memory_mcp__trace_path` | `function_name: "setOutputThumbnail"` | 0 callers, 0 callees (confirmed orphan) |
| `mcp__codebase_memory_mcp__trace_path` | `function_name: "formatBytes"` | 0 callers, 1 callee (confirmed orphan) |
| `mcp__codebase_memory_mcp__search_graph` | `name_pattern: ".*targetWidth.*"` | 1 node, in=0, out=0 (confirmed orphan) |
| `mcp__codebase_memory_mcp__search_graph` | `name_pattern: ".*targetHeight.*"` | 1 node, in=0, out=0 (confirmed orphan) |
