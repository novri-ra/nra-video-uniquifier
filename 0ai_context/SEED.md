---
generator: prompt-pemetaan-v3.1
schema_version: 3.1
mode_created: MIGRATE-LEGACY
mode_last_update: MIGRATE-LEGACY
generated_at: 2026-11-15T00:00:00Z
evidence_map_version: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
parent_report: null
---

# Project Seed — nra_video_uniquifier

## §0 Reading Guide
Read SEED first; cite E-NN or path:line; write report `reports/138-migrate-legacy.md`; update STATE after session.

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
- **Rendering**: Software H.264 (`libx264`, `-preset fast -crf 18`, `-hwaccel none`) locked to ensure 100% stability on Android 15+ devices.
<!-- 0AI_CONTEXT:AUTO:id=arch:end -->

<!-- 0AI_CONTEXT:AUTO:id=deps:start -->
## §4 Module Dependency Map
- Top dependencies: `path_provider`, `provider`, `shared_preferences`, `ffmpeg_kit_flutter_new_https`, `http`, `sqflite`.
- Folder-level top relationships: `lib/services/` -> `lib/models/`, `lib/ui/` -> `lib/services/`.
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
├── main.dart
├── models/
├── services/
├── ui/
├── widgets/
└── l10n/
android/
ios/
macos/
test/
```
<!-- 0AI_CONTEXT:AUTO:id=tree:end -->

<!-- 0AI_CONTEXT:AUTO:id=continuation:start -->
## §7 Continuation Guide
Acknowledged SEED v3.1. Current STATE: development@HEAD. Next: maintain stabilization & feature enhancement.
<!-- 0AI_CONTEXT:AUTO:id=continuation:end -->

<!-- 0AI_CONTEXT:HYBRID:id=glossary:start -->
<!-- 0AI_CONTEXT:human-line -->## §8 Glossary
<!-- 0AI_CONTEXT:auto-line -->- **Uniquifier**: Algorithmic video transformation engine modifying metadata, bitrate, watermarks, and frames to prevent platform fingerprint matching.
- **H.264 Software Lock**: Forcing libx264 encoding to prevent hardware encoder crashes.
<!-- 0AI_CONTEXT:HYBRID:id=glossary:end -->

<!-- 0AI_CONTEXT:AUTO:id=evidence-index:start -->
## §9 MCP Evidence Index
- [E-01] `search_graph`: `FfmpegService`
- [E-02] `search_graph`: `StorageService`
- [E-03] `get_graph_schema`: Graph schema inventory
<!-- 0AI_CONTEXT:AUTO:id=evidence-index:end -->
