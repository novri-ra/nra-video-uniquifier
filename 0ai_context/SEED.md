# SEED.md: NRA Video Uniquifier Context Packet

## 0. Reading Guide
- Primary reference manual for humans and persistent context for Hermes Agent.
- Session logs reside in `0ai_context/reports/`.
- Sequentially numbered filenames: `NN-[task-slug].md` (zero-padded, no dates).
- Every architectural claim must cite `codebase-memory-mcp` or exact `path:line`.

## 1. Project Identity
- **Project Name**: `nra_video_uniquifier`
- **Platform**: Flutter (Android, iOS, Windows, macOS, Linux, Web)
- **Language**: Dart 3.10+ / Flutter SDK 3.47+
- **Purpose**: Offline video uniquifier and anti-fingerprint evasion tool. Alters metadata, audio spectrogram/pitch, and visual attributes (micro-crop, subtle EQ, scale, filtergraph) via FFmpeg to prevent platform duplicate detection while maintaining high visual quality.

## 2. Command Cheat Sheet
```bash
# Run application (default connected device)
flutter run

# Run full test suite
flutter test

# Run single test file
flutter test test/ffmpeg_service_test.dart

# Static analysis and linting
flutter analyze

# Update / fetch dependencies
flutter pub get

# Build Windows desktop executable
flutter build windows

# Build split-ABI release APKs for Android
flutter build apk --release --split-per-abi
```

## 3. High-Level Architecture
- **Design Pattern**: Feature-First architecture + Provider (`ChangeNotifier`) reactivity + Service Layer [E1, E2].
- **Data Flow**:
  1. UI Layer (`lib/features/process/screens/process_screen.dart`): User selects video via `file_picker`.
  2. State Layer (`lib/core/providers/uniquifier_provider.dart`): Coordinates toggles (metadata, audio, visual, upscale), selected file metadata, and probe info [E1].
  3. Service Layer (`lib/core/services/ffmpeg_service.dart`): Assembles FFmpeg CLI filter strings and executes jobs via `ffmpeg_kit_flutter_new` [E3].
  4. Diagnostic Layer (`lib/core/services/render_diagnostic_service.dart`): Probes output to confirm true aspect ratio and resolution (e.g., 2160x3840 portrait 4K vs landscape scale) [E3].
  5. Persistence & History (`lib/core/services/settings_service.dart`, `history_service.dart`): Stores user preferences and indexes exported files [E4].

## 4. Module Dependency Map
Derived from `codebase-memory-mcp` query graph (1119 nodes, 2734 edges):
- `lib/main.dart`
  ├── `lib/core/providers/uniquifier_provider.dart`
  ├── `lib/core/theme/app_theme.dart`
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
  ├── `lib/features/settings/screens/app_settings_bottom_sheet.dart`
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

## 5. Core Entities / Data Model
- **`UniquifierProvider`** (`lib/core/providers/uniquifier_provider.dart`):
  - State: `selectedFilePath`, `selectedFileName`, `selectedFileSize`, `videoDuration`, `videoResolution`, `removeMetadata`, `modifyAudio`, `modifyVisuals`, `upscale1080p`, `targetResolution`, `enableEnhanceAndDenoise`, `enableDeepAntiFingerprint`, `enableHorizontalFlip`, `enableAggressiveAudio`, `enableAutoTrim`, `hardwareAcceleration`.
  - Methods: `setVideoFile()`, `applyPreset()`, `toggleRemoveMetadata()`, `toggleModifyAudio()`, `toggleModifyVisuals()`, `toggleEnhanceAndDenoise()`, `toggleDeepAntiFingerprint()`, `toggleHorizontalFlip()`, `toggleAggressiveAudio()`, `toggleAutoTrim()`, `setUpscaleTarget()`, `formatDuration()`, `formatFileSize()`.
- **`SettingsService` & `TargetResolution`** (`lib/core/services/settings_service.dart`):
  - Enum: `TargetResolution`: `r1080p` (1920x1080), `r2k` (2560x1440), `r4k` (3840x2160).
  - Persistence: SharedPreferences storage for defaults, resolution notifier, and tuning toggles.
- **`HistoryService` & `VideoExportItem`** (`lib/core/services/history_service.dart`):
  - Model: `VideoExportItem(file, fileName, bytes, modified)` with formatting helpers.
  - Operations: directory scanning, safe deletion, storage sizing.
- **`FfmpegService` & `RenderDiagnosticService`** (`lib/core/services/ffmpeg_service.dart`, `lib/core/services/render_diagnostic_service.dart`):
  - Model: `RenderDiagnosticInfo` (width, height, codecs, bitrates, isTrue4kPortrait, isTruncatedPortrait).
  - Operations: command construction, video filter pipeline assembly, execution, probe inspection.
- **`AppTheme` & `AppColors`** (`lib/core/theme/app_theme.dart`):
  - Obsidian dark theme palette and token configurations.

## 6. File Structure Map
```
lib/
├── main.dart                                       # Application root entry point
├── core/
│   ├── providers/uniquifier_provider.dart          # Central ChangeNotifier state
│   ├── services/
│   │   ├── ffmpeg_service.dart                     # FFmpeg command builder & runner
│   │   ├── history_service.dart                    # File scanning, deletion & model
│   │   ├── media_scanner_service.dart              # Android media scanner integration
│   │   ├── render_diagnostic_service.dart          # FFprobe verification
│   │   └── settings_service.dart                   # SharedPreferences persistence
│   └── theme/app_theme.dart                        # Design tokens & dark theme
├── features/
│   ├── navigation/screens/root_navigation_screen.dart  # IndexedStack shell
│   ├── process/
│   │   ├── screens/                                # Process, processing, success, error
│   │   └── widgets/                                # Source picker, modifiers, stage tracker
│   ├── settings/
│   │   ├── screens/                                # Advanced and App settings modal sheets
│   │   └── widgets/                                # Resolution chips, audio tuning, GPU
│   └── history/
│       ├── screens/recent_history_screen.dart      # Exported videos browser
│       └── widgets/                                # Item card, storage meter, empty state
└── shared/widgets/
    └── top_app_bar.dart                            # Branded application header
test/
├── ffmpeg_service_test.dart                        # FFmpeg filtergraph unit tests
├── history_service_test.dart                       # History scanner tests
├── media_scanner_service_test.dart                 # MediaScanner mock tests
├── processing_log_viewer_test.dart                 # Responsive layout tests
├── settings_service_test.dart                      # Persistence tests
├── uniquifier_provider_test.dart                   # State & preset logic tests
└── widget_test.dart                                # Multi-resolution responsive UI tests
```

## 7. Continuation Guide
When starting a new session:
1. Review `AGENTS.md` and read `0ai_context/STATE.md`.
2. Check `codebase-memory-mcp` status via `tools["codebase-memory-mcp"].index_status`.
3. Create sequential report in `0ai_context/reports/NN-[task-slug].md`.
4. Keep functions <= 40 lines, files <= 400 lines (strictly enforced).
5. Always run `flutter test` and `flutter analyze` before committing.

## 8. Glossary
- **Anti-Fingerprint Evasion**: Altering micro-features (hash, chroma, slight zoom, EQ, auto-trim) to bypass hash-based content identification algorithms.
- **Lanczos Scaling**: High-fidelity sinc interpolation filter utilized for video upscaling.
- **True Portrait 4K**: Explicit orientation-aware scaling (2160x3840 for portrait videos) preventing letterbox/pillarbox distortions.
- **FFmpegKit**: Flutter plugin embedding native platform FFmpeg libraries.

## 9. MCP Evidence Index
1. `tools["codebase-memory-mcp"].index_status({ project: "C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier" })`:
   Result: ready, 1119 nodes, 2734 edges, indexed_at 2026-10-29T01:23:38Z.
2. `tools["codebase-memory-mcp"].search_graph({ project: "C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier", name_pattern: ".*UniquifierProvider.*" })`:
   Result: 1 symbol returned (`UniquifierProvider` Class, `lib/core/providers/uniquifier_provider.dart:6-396`, in-degree 17, out-degree 0).
3. `tools["codebase-memory-mcp"].trace_path({ project: "C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier", function_name: "processVideo" })`:
   Result: 1 caller (`FfmpegService.executePipeline`), 12 callees (`_buildAudioFilter`, `_buildVideoFilter`, `_deletePartialFile`, `_executeFFmpeg`, etc.).
4. `tools["codebase-memory-mcp"].get_graph_schema({ project: "C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier" })`:
   Result: 14 node labels, 17 edge types.
5. `tools["codebase-memory-mcp"].search_graph({ project: "C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier", file_pattern: "lib/.*", max_degree: 0 })`:
   Result: 0 dead symbols in `lib/`.
