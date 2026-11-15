---
generator: prompt-pemetaan-v3.1
schema_version: 3.1
mode_created: MIGRATE-LEGACY
mode_last_update: UPDATE
generated_at: 2026-11-15T00:00:00Z
evidence_map_version: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
parent_report: 151-chore-resolve-final-p3-findings.md
---

# Project Seed — nra_video_uniquifier

## §0 Reading Guide
Read SEED first; cite E-NN or path:line; write report; update STATE after session.

<!-- 0AI_CONTEXT:HYBRID:id=identity:start -->
<!-- 0AI_CONTEXT:human-line -->## §1 Project Identity
<!-- 0AI_CONTEXT:auto-line -->High-performance Flutter video uniquifier and anti-fingerprint suite with advanced FFmpeg integration, software-locked H.264 rendering pipeline (`libx264`), and robust privacy controls.
- Stack: Flutter 3.47.8 / Dart 3.13.7
- App Version: 1.0.5+5
<!-- 0AI_CONTEXT:HYBRID:id=identity:end -->

<!-- 0AI_CONTEXT:AUTO:id=cmd:start -->
## §2 Command Cheat Sheet
- Build: `flutter build apk --release`
- Run: `flutter run`
- Test: `flutter test`
- Lint: `flutter analyze`
<!-- 0AI_CONTEXT:AUTO:id=cmd:end -->

<!-- 0AI_CONTEXT:AUTO:id=arch:start -->
## §3 High-Level Architecture
- **Core Services**: `FfmpegService` (E-01), `StorageService` (E-02), `SettingsService`, `HistoryService`, `NotificationService`, `MicrostockNewsService`, `TranslationService`, `UserInterestService`, `ConnectivityService`.
- **UI / Features**: Studio (ModifiersCard, Preview, ProcessingScreen), History, Profile, Settings.
- **Rendering**: Software H.264 (`libx264`, `-preset fast -crf 18`, `-hwaccel none`) locked to ensure 100% stability on Android 15+ devices. Includes adaptive OOM safeguards for entry/mid-tier devices (`_isHighOomRisk` guard) and buffer queue depth guard (`-max_muxing_queue_size 20`).
- **Color Grading (LUT)**: `lutName` persists via `SettingsService` (`app_lut_name`) → `UniquifierModifiersMixin` → restored on startup → forwarded in single, batch (`BatchQueueProvider`), and live preview (`FilterBuilders.buildPreviewFilterChain`) pipelines. `FfmpegFileHelper.resolveLutPath()` handles both bundled `.cube` assets (extracted via `rootBundle`) and user-imported custom `.cube` files (absolute paths from `file_picker` saved in `<documents>/custom_luts/`), hardened with try-catch safety, 5MB size check, and `.cube` header validation (`LUT_3D_SIZE`/`TITLE`).
<!-- 0AI_CONTEXT:AUTO:id=arch:end -->

<!-- 0AI_CONTEXT:AUTO:id=deps:start -->
## §4 Module Dependency Map
- Top dependencies: `path_provider`, `provider`, `shared_preferences`, `file_picker`, `ffmpeg_kit_flutter_new_https`, `http`, `sqflite`.
- Folder-level top relationships: `lib/services/` -> `lib/models/`, `lib/ui/` -> `lib/services/`.
- Asset flow: `assets/luts/*.cube` or custom imported files (`file_picker` → `<documents>/custom_luts/`) → `FfmpegFileHelper.resolveLutPath` (rootBundle or absolute path) → `FilterBuilders.lutPath`.
- Findings source of truth: `0ai_context/findings.json` only (`0ai_context/raw/findings.json` removed in commit `5f385bf`; confirmed in report 146).
<!-- 0AI_CONTEXT:AUTO:id=deps:end -->

<!-- 0AI_CONTEXT:AUTO:id=entities:start -->
## §5 Core Entities / Data Model
- `UniquifyJob`: Queue item tracking input video path, modifiers, output destination, progress, and status.
- `HistoryItem`: Persistent record of processed video tasks.
- `MicrostockNewsItem`: Cached news articles for microstock trends.
<!-- 0AI_CONTEXT:AUTO:id=entities:end -->

<!-- 0AI_CONTEXT:AUTO:id=tree:start -->
## §6 File Structure Map
```text
lib/
├ main.dart
├ models/
├ services/
├ ui/
├ widgets/
└ l10n/
android/
ios/
macos/
test/
```
<!-- 0AI_CONTEXT:AUTO:id=tree:end -->

<!-- 0AI_CONTEXT:AUTO:id=continuation:start -->
## §7 Continuation Guide
Acknowledged SEED v3.1. Current STATE: development@HEAD. Context mapping files fully synchronized (INDEX.md, index.json, STATE.md, HANDOFF.md, SEED.md, findings.json, handoff-diff.json). Zero Active Findings achieved in Report 151. Next: proceed to Task 152 feature enhancement.
<!-- 0AI_CONTEXT:AUTO:id=continuation:end -->

<!-- 0AI_CONTEXT:HYBRID:id=glossary:start -->
<!-- 0AI_CONTEXT:human-line -->## §8 Glossary
<!-- 0AI_CONTEXT:auto-line -->- **Uniquifier**: Algorithmic video transformation engine modifying metadata, bitrate, watermarks, and frames to prevent platform fingerprint matching.
- **H.264 Software Lock**: Forcing libx264 encoding to prevent hardware encoder crashes.
- **OOM Adaptive Guard**: Device-tier-aware fallback that surfaces advisory messages instead of exit code 1 crashes on resource-constrained mobile.
<!-- 0AI_CONTEXT:HYBRID:id=glossary:end -->

<!-- 0AI_CONTEXT:AUTO:id=evidence-index:start -->
## §9 MCP Evidence Index
- [E-01] `search_graph`: `FfmpegService`
- [E-02] `search_graph`: `StorageService`
- [E-03] `get_graph_schema`: Graph schema inventory
- [E-04] `search_graph`: `UniquifierProvider`
- [E-05] `search_graph`: `FilterBuilders`
- [E-06] `search_graph`: `DeviceCapabilityService`
<!-- 0AI_CONTEXT:AUTO:id=evidence-index:end -->