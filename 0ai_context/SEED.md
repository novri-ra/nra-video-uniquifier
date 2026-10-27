# SEED.md: NRA Video Uniquifier Context Packet

## 0. Reading Guide
- Ultimate source of truth for the codebase.
- Always use `0ai_context/reports/` for session reports.
- Name reports sequentially with zero-padded numbers: `01-feature-name.md`, `02-bug-fix.md`.
- Never use dates in report filenames.
- Every architectural claim must cite `codebase-memory-mcp` or `file:line`.

## 1. Project Identity
- **Project Name**: `nra_video_uniquifier`
- **Platform**: Flutter (Cross-platform: Android, iOS, Windows, macOS, Linux, Web)
- **Language**: Dart 3.10+ / Flutter SDK 3.47+
- **Purpose**: Offline video uniquifier tool. Modifies video metadata, audio pitch/frequency, and visual attributes (subtle crop/scale/filter) via FFmpeg to prevent duplicate detection while preserving visual fidelity.

## 2. Command Cheat Sheet
```bash
# Run application (default connected device)
flutter run

# Run tests
flutter test

# Run specific test file
flutter test test/history_service_test.dart

# Static analysis and linting
flutter analyze

# Update / get dependencies
flutter pub get

# Build executable (Windows)
flutter build windows

# Build APK (Android)
flutter build apk --release
```

## 3. High-Level Architecture
- **Pattern**: Feature-First + Provider (ChangeNotifier) State Management + Service Layer.
- **Data Flow**:
  1. UI Layer (`lib/features/*`): User picks video via `file_picker`.
  2. State Layer (`lib/core/providers/uniquifier_provider.dart`): Holds toggles (metadata, audio, visual, upscale), selected file metadata, and probe info.
  3. Service Layer (`lib/core/services/ffmpeg_service.dart`): Generates FFmpeg CLI filter args and runs execution via `ffmpeg_kit_flutter_new`.
  4. Output & History (`lib/core/services/history_service.dart`, `lib/features/history/screens/recent_history_screen.dart`): Inspects exported videos, allows playback (`open_filex`), and sharing (`share_plus`).
- **Evidence**: MCP Architecture Query `get_architecture` identified entry points `lib/main.dart` and `linux/runner/main.cc`.

## 4. Module Dependency Map
Derived from `codebase-memory-mcp` query: `MATCH (a)-[r]->(b) ...`:
- `lib/main.dart`
  └── `lib/core/providers/uniquifier_provider.dart`
  └── `lib/core/theme/app_theme.dart`
  └── `lib/features/navigation/screens/root_navigation_screen.dart`
- `lib/features/navigation/screens/root_navigation_screen.dart`
  ├── `lib/features/process/screens/process_screen.dart`
  ├── `lib/features/history/screens/recent_history_screen.dart`
  └── `lib/shared/widgets/top_app_bar.dart`
- `lib/features/process/screens/process_screen.dart`
  ├── `lib/features/process/widgets/source_file_section.dart`
  ├── `lib/features/process/widgets/modifiers_card.dart`
  ├── `lib/features/process/widgets/engine_state_strip.dart`
  ├── `lib/features/settings/screens/advanced_settings_bottom_sheet.dart`
  ├── `lib/features/process/screens/processing_screen.dart`
  └── `lib/core/providers/uniquifier_provider.dart`
- `lib/features/process/screens/processing_screen.dart`
  ├── `lib/features/process/widgets/processing_radar_indicator.dart`
  ├── `lib/features/process/widgets/processing_stage_tracker.dart`
  ├── `lib/features/process/widgets/processing_log_viewer.dart`
  ├── `lib/core/services/ffmpeg_service.dart`
  ├── `lib/features/process/screens/success_screen.dart`
  └── `lib/features/process/screens/error_screen.dart`
- `lib/features/history/screens/recent_history_screen.dart`
  ├── `lib/core/services/history_service.dart`
  ├── `lib/features/history/widgets/history_item_card.dart`
  ├── `lib/features/history/widgets/history_storage_bar.dart`
  └── `lib/features/history/widgets/history_empty_state.dart`
- `lib/features/settings/screens/advanced_settings_bottom_sheet.dart`
  ├── `lib/features/settings/widgets/upscale_resolution_card.dart`
  ├── `lib/features/settings/widgets/audio_visual_tuning_card.dart`
  └── `lib/features/settings/widgets/hardware_acceleration_card.dart`

Total indexed nodes: 866. Total edges: 1848.

## 5. Core Entities / Data Model
- **`UniquifierProvider`** (`lib/core/providers/uniquifier_provider.dart`):
  - State: `selectedFilePath`, `selectedFileName`, `selectedFileSize`, `videoDuration`, `videoResolution`, `removeMetadata`, `modifyAudio`, `modifyVisuals`, `upscale1080p`, `upscaleTarget`, `hardwareAcceleration`.
  - Methods: `setVideoFile()`, `applyPreset()`, `toggleRemoveMetadata()`, `toggleModifyAudio()`, `toggleModifyVisuals()`, `formatDuration()`, `formatFileSize()`.
- **`HistoryService` & `VideoExportItem`** (`lib/core/services/history_service.dart`):
  - Model: `VideoExportItem(file, fileName, bytes, modified)` with `formattedSize` and `formattedDate`.
  - Methods: `getTargetDirectories()`, `scanDirectory()`, `loadHistory()`, `deleteItem()`, `formatTotalSize()`.
- **`FfmpegService`** (`lib/core/services/ffmpeg_service.dart`):
  - Methods: `buildCommand()`, `processVideo()`, `cancel()`, `generateOutputPath()`.
- **`AppTheme` & `AppColors`** (`lib/core/theme/app_theme.dart`):
  - Dark obsidian/mint theme tokens (`surfaceContainerLowest`, `primary`, `outlineVariant`, etc.).

## 6. File Structure Map
```
lib/
├── main.dart                                       # Application root entry point
├── core/
│   ├── providers/uniquifier_provider.dart          # Central ChangeNotifier state
│   ├── services/
│   │   ├── ffmpeg_service.dart                     # FFmpeg command builder & runner
│   │   └── history_service.dart                    # File scanning, deletion & model
│   └── theme/app_theme.dart                        # Design tokens & dark theme
├── features/
│   ├── navigation/screens/root_navigation_screen.dart  # IndexedStack 3-tab shell
│   ├── process/
│   │   ├── screens/
│   │   │   ├── process_screen.dart                 # Main video picker coordinator
│   │   │   ├── processing_screen.dart              # Progress & execution coordinator
│   │   │   ├── success_screen.dart                 # Export summary & action buttons
│   │   │   └── error_screen.dart                   # Error reporting & log viewer
│   │   └── widgets/
│   │       ├── source_file_section.dart            # Source file picker & metadata
│   │       ├── modifiers_card.dart                 # 4 Modifier toggle rows
│   │       ├── engine_state_strip.dart             # GPU & render estimate strip
│   │       ├── processing_radar_indicator.dart     # Custom canvas radial progress
│   │       ├── processing_stage_tracker.dart       # 4-Stage pipeline tracker
│   │       └── processing_log_viewer.dart          # Telemetry & terminal console
│   ├── settings/
│   │   ├── screens/advanced_settings_bottom_sheet.dart # Advanced tweaks modal sheet
│   │   └── widgets/
│   │       ├── upscale_resolution_card.dart        # Target resolution option chips
│   │       ├── audio_visual_tuning_card.dart       # Pitch & crop tuning sliders
│   │       └── hardware_acceleration_card.dart     # GPU toggle & shader telemetry
│   └── history/
│       ├── screens/recent_history_screen.dart      # Exported video browser coordinator
│       └── widgets/
│           ├── history_item_card.dart              # Export item card & action buttons
│           ├── history_storage_bar.dart            # Storage meter & queue title
│           └── history_empty_state.dart            # Empty state placeholder
└── shared/widgets/
    └── top_app_bar.dart                            # Reusable branded app header
test/
├── ffmpeg_service_test.dart                        # Unit test suite for FFmpeg commands (6 tests)
├── history_service_test.dart                       # Unit test suite for HistoryService (5 tests)
├── uniquifier_provider_test.dart                   # Unit test suite for UniquifierProvider (15 tests)
└── widget_test.dart                                # UI smoke test suite (1 test)
```

## 7. Continuation Guide
When continuing work on this project in a new session:
1. Load `0ai_context/SEED.md` and read `0ai_context/STATE.md`.
2. Check `codebase-memory-mcp` index status: `tools["codebase-memory-mcp"].index_status`.
3. Create new task report in `0ai_context/reports/NN-[task-slug].md`.
4. Keep functions small (<= 40 lines), files focused (<= 400 lines strictly enforced).
5. Run `flutter analyze` and `flutter test` before completing tasks.

## 8. Glossary
- **Uniquifier**: Process of changing subtle video file properties (hash, audio sample rate, metadata, 4px crop) so content ID algorithms detect it as distinct.
- **Lanczos Scaling**: High-quality video filter resizing algorithm used during upscaling.
- **Provider**: Flutter state management library implementing InheritedWidget wrapping.
- **FFmpegKit**: Flutter plugin executing native FFmpeg commands asynchronously.

## 9. MCP Evidence Index
1. `tools["codebase-memory-mcp"].index_status({ project: "C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier" })`:
   Status: ready, 866 nodes, 1848 edges.
2. `tools["codebase-memory-mcp"].get_architecture({ project: "C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier" })`:
   Entry points: `lib/main.dart`.
