# AGENTS.md — Project Context & Rules

Project: `nra_video_uniquifier`
Stack: Flutter 3.47+ / Dart 3.10+ / FFmpegKit (`ffmpeg_kit_flutter_new`)
Target: Cross-platform offline video deduplication, anti-fingerprint evasion, and 4K upscale.

## 1. Quick Commands
- Dev Run: `flutter run`
- Test All: `flutter test`
- Single Test: `flutter test test/ffmpeg_service_test.dart`
- Lint & Analyze: `flutter analyze`
- Pub Dependencies: `flutter pub get`
- Build Android APK: `flutter build apk --release --split-per-abi`
- Build Windows: `flutter build windows`

## 2. Architecture Summary
- Pattern: Feature-First structure + Provider (`ChangeNotifier`) reactivity + Service Layer.
- Data Flow:
  1. UI Layer (`lib/features/process/screens/process_screen.dart`): User selects video via `file_picker` [E1].
  2. State Layer (`lib/core/providers/uniquifier_provider.dart`): Holds toggles, metadata, presets, and live progress [E1, E2].
  3. Service Layer (`lib/core/services/ffmpeg_service.dart`): Constructs FFmpeg filtergraph args and runs pipeline [E3].
  4. Diagnostic Layer (`lib/core/services/render_diagnostic_service.dart`): Post-render verification (true portrait vs landscape scale) [E3].
  5. Persistence & History (`lib/core/services/settings_service.dart`, `history_service.dart`): Stores presets, targets, and exported items [E4].

## 3. Module Map
- `lib/main.dart`: Root widget setup and multi-provider injection.
- `lib/core/providers/`: State management (`uniquifier_provider.dart`).
- `lib/core/services/`: Engine services:
  - `ffmpeg_service.dart`: CLI filtergraph generation and background execution.
  - `history_service.dart`: Scans and manages output video directory.
  - `settings_service.dart`: Persistent configuration via `SharedPreferences`.
  - `media_scanner_service.dart`: Android MediaScanner broadcast and gallery opener.
  - `render_diagnostic_service.dart`: FFprobe verification of output dimensions and codecs.
- `lib/core/theme/`: Dark theme tokens and color constants (`app_theme.dart`).
- `lib/features/navigation/`: Shell navigation with `IndexedStack` (`root_navigation_screen.dart`).
- `lib/features/process/`: Processing workflow screens (`process`, `processing`, `success`, `error`) and telemetry widgets.
- `lib/features/settings/`: Sheets for upscale targets, tuning sliders, and GPU acceleration.
- `lib/features/history/`: Exported items gallery, storage quota meter, and action chips.

## 4. Core Entities & Data Models
- `UniquifierProvider` (`lib/core/providers/uniquifier_provider.dart:6-396`): Central state notifier [E1].
- `TargetResolution` (`lib/core/services/settings_service.dart:7-25`): Enum `r1080p`, `r2k`, `r4k` [E3].
- `VideoExportItem` (`lib/core/services/history_service.dart:12-42`): File metadata model for exported items.
- `RenderDiagnosticInfo` (`lib/core/services/render_diagnostic_service.dart:6-35`): Forensic render diagnostic model.

## 5. Development Conventions & Hard Rules
- Code Limits: Functions <= 40 lines; files <= 400 lines (strictly enforced).
- Simplicity (Ponytail): Minimal diffs, no unnecessary abstractions or wrappers.
- Evidence-First: Claims backed by MCP query or `path:line`.
- Quality Gate: Run `flutter analyze` and `flutter test` before completing tasks.
- No Direct Source Modification without verification; preserve test coverage (61 tests passing).

## 6. Report Policy
- Location: `0ai_context/reports/NN-[task-slug].md` (zero-padded, sequential, no dates).
- Mandatory Section: Include MCP Evidence appendix with tool name, query, and result counts.

## 7. Context Pointers
- Deep Human Context: `0ai_context/SEED.md`
- Active State & Roadmap: `0ai_context/STATE.md`
- Hermes Native Protocols: `0ai_context/HERMES-WORKFLOW.md`
- Skills & MCP Matrix: `0ai_context/SKILLS.md`

## 8. MCP Evidence Index
- E1: `search_graph(name_pattern=".*UniquifierProvider.*")` -> 1 class node, in-degree 17.
- E2: `get_file_outline(file_path="lib/core/providers/uniquifier_provider.dart")` -> 34 declaration nodes.
- E3: `trace_path(function_name="processVideo")` -> 1 caller, 12 callees.
- E4: `index_status()` -> 1119 nodes, 2734 edges, status ready.
