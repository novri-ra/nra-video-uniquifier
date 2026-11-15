# Project Handoff — nra_video_uniquifier

## 1. Project DNA & Executive Summary
- Name: `nra_video_uniquifier`
- Current Commit: Latest (Report 154: Auto-Dispatch Video Metadata Vault Telemetry)
- Branch: `development`
- Health Status: Analyze exit 0, Test 229/229 passed, Format exit 0 (0 changed).
- Executive Summary: Reports 123–145 locked the app to software H.264 (`libx264`, CRF 18, `-hwaccel none`), added timeout recovery, blurred-canvas effects, diagnostic path redaction, audio d=60 masking, path redactor hardening, converted all remaining silent + empty catch handlers to `debugPrint`, shipped the LUT color-grading pipeline end-to-end (Report 144), fixed its runtime asset-path bug via `rootBundle` extraction (Report 145), expanded LUT presets (Report 147), completed full P1 LUT wiring across batch execution, startup settings restore, and live preview filter chains plus custom LUT import (Reports 148, 149), hardened custom LUT import (Report 150), resolved final P3 findings (Report 151), introduced UI Polish displaying the active LUT indicator chip on `ProcessingScreen` and the Color Grading LUT manifest entry on `SuccessManifestCard` (Report 152), implemented HTTP POST telemetry dispatch to Google Sheets Webhook with online-guard and offline fallback from `UserInterestService` (Report 153), and automated the dispatch of `UserInterestService.dispatchVideoMetadataVault` upon successful video export in `UniquifierProgressMixin` (Report 154). Zero Active Findings maintained.

## 2. Architecture & Core Systems
- Built on Flutter 3.47.8 / Dart 3.13.7.
- Core pipeline: UniquifierProvider -> FfmpegService + FilterBuilders -> FFmpegKit.
- Supporting services: StorageService, SettingsService, HistoryService, NotificationService, MicrostockNewsService, TranslationService, UserInterestService, ConnectivityService.

## 3. Tech Stack & Version Pinning
- Flutter SDK: 3.47.8
- Dart SDK: 3.13.7
- Packages: provider, shared_preferences, path_provider, ffmpeg_kit_flutter_new, http (dart:io), connectivity_plus, etc.
- Video engine: software H.264 only (`libx264 -preset fast -crf 18 -pix_fmt yuv420p -tag:v avc1`, `-hwaccel none`); hardware acceleration and H.265 are disabled.

## 4. Current Environment & Health
- Git status: modified (`user_interest_service.dart`, `0ai_context/`).
- Analysis: 0 issues.
- Tests: 229/229 passing.

## 5. Directory Structure & Key Paths
- `lib/core/services/`: core business logic, FFmpeg rendering, storage, network.
- `lib/features/`: UI screens and widgets (Studio, History, Profile, Settings).
- `assets/luts/`: LUT `.cube` drop-in directory for the `lut3d` filter.
- `test/`: unit and widget test suite (229 tests).
- `0ai_context/`: context mapper state, reports, raw files.

## 6. Build, Test & Verification Commands
- `dart analyze --fatal-infos`
- `flutter test`
- `dart format --set-exit-if-changed .`

## 7. Active Milestones & Roadmap
- v1.0.5 shipped. Zero active findings. Google Sheets telemetry integration complete.

## 8. In-Flight Work & Open Threads
- None. Whitelist tasks successfully completed.

## 9. Blockers, Risks & Technical Debt
- 0 active findings (0 P0, 0 P1, 0 P2, 0 P3).
- The News/Intel tab was removed from the shell; the microstock screens and services still exist in the tree but are unreachable from navigation.

## 10. Findings Inventory (Active)
- *(Zero Active Findings achieved in Report 151).*

## 11. Code Snippets & Key Patterns
- `FfmpegService`: manages video rendering pipeline and multi-pass evasion filters.
- `UniquifierProvider`: centralized state container coordinating modifiers, preview, and execution.
- `lib/core/utils/path_redactor.dart`: `redactFileSystemPaths` redacts absolute filesystem paths before they reach user-visible error text.
- `lib/core/services/user_interest_service.dart`: `_dispatchTelemetry` now performs HTTP POST to Google Sheets Webhook when online, with ConnectivityService guard and debugPrint error handling.

```dart
// UserInterestService._dispatchTelemetry - Google Sheets webhook dispatch
static Future<void> _dispatchTelemetry(Map<String, dynamic> payload) async {
  if (mockDispatcher != null) {
    await mockDispatcher!(payload);
    return;
  }

  if (!ConnectivityService.instance.isOnline.value) {
    return;
  }

  try {
    final urlStr = await getWebhookUrl();
    final url = Uri.parse(urlStr);
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);

    try {
      final request = await client.postUrl(url);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      await response.drain();
    } finally {
      client.close();
    }
  } catch (e) {
    debugPrint('[UserInterestService] telemetry dispatch failed: $e');
  }
}
```

## 12. Coding Standards & Policy Checklist
- English-only comments and docs.
- Strict privacy constraints on user paths and video identifiers.
- Zero tolerance for fatal analysis warnings or test failures.

## 13. Collaboration & Communication Guidelines
- Terse, structured reporting.
- Exact file paths and code references.

## 14. Troubleshooting & Known Gotchas
- FFmpeg native method channel requires mock handling in unit tests.
- SharedPreferences plugin binding in tests.
- Export hangs (`100 buffers queued`) on Android 15+ if hardware encoding is allowed; use `libx264` only.
- Telemetry data only sent when device is online; silent offline fallback preserves battery and UI responsiveness.
- **Policy Clarification (`AUDIT-20261108-028`)**: Video basenames (e.g., `video.mp4`) are explicitly permitted in `debugPrint` for diagnostic tracing, but absolute filesystem paths must strictly be redacted via `redactFileSystemPaths`.
- **Accepted Risk (`AUDIT-20261108-027`)**: MCP index tooling may intermittently fail with exit code 1 on the first run. The mapper must retry once before aborting.

## 15. Next Immediate Actions
- Proceed to Task 154.