# 17-dynamic-resolution-4k-and-pipeline-integrity: Dynamic Resolution State Synchronization, 4K Support, Real FFmpeg Execution Audit, & Error Visibility

## Executive Summary
This session addressed static hardcoded resolution labels, added comprehensive 4K upscale support, implemented reactive synchronization between `SettingsService` and `UniquifierProvider`, audited dynamic FFmpeg filtergraph argument generation, and fortified execution integrity with clear diagnostic error reporting.

---

## 1. Audit Findings: Hardcoded Labels Replaced with Reactive Bindings
- **Defect Identified**:
  - `ModifiersCard` (`lib/features/process/widgets/modifiers_card.dart:105-107`) permanently displayed static hardcoded strings `'Upscale to 1080p'` and `'Lanczos algorithm (${provider.selectedUpscaleTarget})'`, showing `(1080p)` or `(2k)` instead of dimension details.
  - `UpscaleResolutionCard` (`lib/features/settings/widgets/upscale_resolution_card.dart`) offered `720p`, `1080p`, and `2k`, omitting explicit 4K UHD support.
  - `SettingsService` lacked persistence and reactive broadcasting for upscale resolution targets.
  - `FfmpegService.buildCommand()` hardcoded `scale=1920:1080:flags=lanczos` regardless of user preset, failing to dynamically adapt to 2K or 4K.
  - `ModifiersCard` as a plain `StatelessWidget` did not independently subscribe to provider updates when rendered in isolated contexts.
- **Remediations**:
  - Defined `TargetResolution` enum in `lib/core/services/settings_service.dart`: `r1080p` (1080p, 1920x1080), `r2k` (2K, 2560x1440), and `r4k` (4K, 3840x2160).
  - Added `SettingsService.upscaleResolutionNotifier` (`ValueNotifier<TargetResolution>`) and `SharedPreferences` persistence under key `app_upscale_resolution`.
  - Bound `UniquifierProvider` to `SettingsService.upscaleResolutionNotifier` on initialization and cleanup on disposal.
  - Wrapped `ModifiersCard` in `ListenableBuilder(listenable: provider, ...)` to guarantee immediate sub-tree rebuilds when resolution changes.
  - Dynamic Title: `'Upscale to ${provider.targetResolutionLabel}'` (`Upscale to 1080p`, `Upscale to 2K`, `Upscale to 4K`).
  - Dynamic Subtitle: `'Lanczos algorithm (${provider.targetResolutionDetails})'` (`Lanczos algorithm (1920x1080)`, `Lanczos algorithm (2560x1440)`, `Lanczos algorithm (3840x2160)`).

---

## 2. Resolution Matrix & FFmpeg Filter Arguments

| Resolution Tier | Value Key | Target Dimensions | Visual Label | Detail Tag | Thermal / Hardware Tag | Dynamic FFmpeg Filtergraph Argument |
|---|---|---|---|---|---|---|
| **1080p Full HD** | `1080p` | `1920x1080` | `1080p` | `1920x1080` | None (Recommended) | `scale=w=-2:h=1080:flags=lanczos` |
| **2K QHD** | `2k` | `2560x1440` | `2K` | `2560x1440` | `HIGH THERMAL` | `scale=w=-2:h=1440:flags=lanczos` |
| **4K UHD** | `4k` | `3840x2160` | `4K` | `3840x2160` | `EXTREME LOAD` | `scale=w=-2:h=2160:flags=lanczos` |

### Filtergraph Sequential Order & Anti-Clash Verification
```
-vf "setpts=0.9852*PTS,crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2,scale=w=-2:h=TARGET_HEIGHT:flags=lanczos,eq=contrast=1.02:brightness=0.01:saturation=1.03:gamma=0.98,noise=alls=2:allf=t+u"
```
- Micro-crop executes first (`crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2`), slicing 2% of frame edges with macroblock-even parity.
- Aspect-ratio preserving scaling executes second (`scale=w=-2:h=TARGET_HEIGHT:flags=lanczos`), automatically computing even width `-2` while scaling height to target (1080, 1440, or 2160) using high-fidelity Lanczos resampling.
- Verified: Zero filter graph syntax collision between `crop` and `scale`.

---

## 3. Error Catching & Pipeline Verification
- **Audit of `FfmpegService.processVideo()` & `FfmpegService.executePipeline()`**:
  - Added `executePipeline()` architectural alias forwarding all parameters directly to `processVideo()`.
  - Added safe staging verification in `finally`: ensures `stagedFile` is removed if temporary, but guarantees active output (`outputPath`) or original input (`inputPath`) are never deleted.
  - Enhanced `_executeFFmpeg`:
    - Checks `ReturnCode.isSuccess()`.
    - If canceled, safely purges partial file via `_deletePartialFile()` and throws explicit cancellation exception.
    - Captures both `session.getAllLogsAsString()` and `session.getFailStackTrace()`.
    - Constructs detailed multi-line diagnostic error message including return code, stack trace, and execution log buffer.
- **Error Visibility in `ErrorScreen`**:
  - Replaced standard `Text` with `SelectableText` in `_TelemetryLogBox` (`lib/features/process/screens/error_screen.dart`), allowing developers and users to select and copy complete native failure traces.
  - Generalized remediation guidance from `Toggle off 1080p Upscaling Lanczos` to `Toggle off Upscaling (or lower target resolution)`.

---

## 4. Test & Analysis Results
- **Static Analysis (`flutter analyze`)**:
  - Result: `No issues found! (ran in 3.3s)`
  - Total analyzer issues: **0**
- **Automated Test Suite (`flutter test`)**:
  - Total suites executed: 7
  - Total tests passed: **48 passed** (0 failed)
  - New test coverage:
    - `test/settings_service_test.dart`: Default upscale resolution unset check, persistence & reactive broadcast validation across 1080p, 2K, and 4K, and `TargetResolution.fromString()` parsing rules.
    - `test/ffmpeg_service_test.dart`: Verified dynamic `-vf` arguments for 1080p, 2K, and 4K, scale/crop ordering check.
    - `test/uniquifier_provider_test.dart`: Verified initial label/detail state, dynamic `setUpscaleTarget` updates for 2K/4K, and reactive listeners responding to external `SettingsService` notifications.
    - `test/widget_test.dart`: Verified `ModifiersCard` displays dynamic title and subtitle reactively when resolution changes without restarting.

---

## 5. Line Budget Audit (Strict <= 400 LOC)
All modified files remain strictly within the architectural line budget:
- `lib/core/providers/uniquifier_provider.dart`: 307 LOC (Target <= 400)
- `lib/core/services/ffmpeg_service.dart`: 261 LOC (Target <= 400)
- `lib/core/services/settings_service.dart`: 107 LOC (Target <= 400)
- `lib/features/process/widgets/modifiers_card.dart`: 208 LOC (Target <= 400)
- `lib/features/settings/widgets/upscale_resolution_card.dart`: 238 LOC (Target <= 400)
- `lib/features/process/screens/processing_screen.dart`: 312 LOC (Target <= 400)
- `lib/features/process/screens/error_screen.dart`: 247 LOC (Target <= 400)

---

## 6. MCP Graph Delta & Commit Hash
- **Baseline Graph**: 1020 nodes, 2337 edges
- **Updated Graph**: 1031 nodes, 2418 edges
- **Graph Delta**: +11 nodes, +81 edges
- **Commit**: `feat(settings): support 4K upscale, reactive modifiers card label, and dynamic FFmpeg filtergraph`
