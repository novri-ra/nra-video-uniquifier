# Repository Seed — nra_video_uniquifier

## 1. Executive Summary
NRA Video Uniquifier is an offline-first video processing Flutter application designed to modify video characteristics and metadata to evade automated digital fingerprinting. It supports hardware-accelerated transformations, AI upscaling, and batch processing. The project is currently in an active and verified production baseline state.

## 2. Core Architecture & Stack
- Framework: Flutter 3.47.8 / Dart 3.13.7
- State management: Provider (`ChangeNotifier`)
- Data layer: Local filesystem, `shared_preferences`
- Runtime: Flutter Engine (Android, iOS, Windows, macOS, Linux)

## 3. Build, Run & Verification
- Analyze: `dart analyze`
- Test: `flutter test`
- Format: `dart format --set-exit-if-changed .`
- Run: `flutter run`

## 4. High-Level Dependency Graph
- Entry & Presentation Layer: `lib/main.dart` -> `lib/features/**`
- State Orchestration Layer: `lib/core/providers/**` (`UniquifierProvider`, `BatchQueueProvider`, `LocaleProvider`, `ThemeProvider`)
- Core Business Logic & Engine: `lib/core/services/**` (`FfmpegService`, `AiSuperResolutionService`, `DeviceCapabilityService`)
- Shared & Design System: `lib/core/theme/**` (`AppColors`), `lib/shared/widgets/**`, `lib/l10n/**`

## 5. Entry Points
- `lib/main.dart` — `main()` — App startup, initializes bindings, configures Providers, mounts root MaterialApp.

## 6. Module Inventory
- `core/providers` (`lib/core/providers/`) — State management for processing, batch queue, localization, and theme.
- `core/services` (`lib/core/services/`) — Low-level services for FFmpeg orchestration, AI super-resolution, device capability detection, and notifications.
- `core/theme` (`lib/core/theme/`) — Design tokens, color system, and typography constants.
- `features/dashboard` (`lib/features/dashboard/`) — Dashboard views, metrics, and live telemetry widgets.
- `features/process` (`lib/features/process/`) — Main processing workflow screens, log viewer, and stage trackers.
- `features/history` (`lib/features/history/`) — History screen and media export item components.
- `features/settings` (`lib/features/settings/`) — Application and engine configuration settings.
- `features/microstock` (`lib/features/microstock/`) — Microstock trends, articles, and RSS feed views.

## 7. External Integrations & I/O
- FFmpegKit — Bidirectional — Video transcoding, filtering, and metadata scrubbing.
- Local Storage — Bidirectional — Persisting settings, processing history, and cached models.
- Connectivity / RSS — Inbound — Microstock news feed sync (gracefully disabled when offline).

## 8. Data Models & Persistence
- `BatchVideoItem` — id, path, status, progress, targetResolution — In-memory queue state.
- `VideoExportItem` — id, originalPath, outputPath, timestamp, size — SharedPreferences and filesystem.
- `MicrostockNewsArticle` — id, title, content, publishedAt, category — Local cache in SharedPreferences.

## 9. Key Constraints
- Offline-first execution: Video processing strictly operates without network requirements.
- Zero telemetry leakage: No sensitive user video data or paths transmitted externally.
- Non-destructive execution: Original input video files are never mutated directly.

## 10. Link Map
| ID | Target | Description |
|----|--------|-------------|
| L-01 | `0ai_context/HANDOFF.md` | Self-contained briefing for AI chat |
| L-02 | `0ai_context/STATE.md` | Current project state |
| L-03 | `0ai_context/SKILLS.md` | Available tools |
| L-04 | `0ai_context/reports/01-audit.md` | Findings |
