# Repository Seed — nra_video_uniquifier

## 1. Executive Summary
NRA Video Uniquifier is an offline-first Flutter desktop and mobile application designed to bypass video content matching algorithms (e.g., TikTok, Instagram Reels, YouTube Shorts) and prepare assets for microstock agencies. It applies randomized subtle audio-visual transformations, metadata scrubbing, neural/mathematical video upscaling, and real-time hardware telemetry. The application is production-grade with comprehensive unit, integration, and widget test coverage.

## 2. Core Architecture & Stack
- Framework: Flutter 3.47.8 (Dart SDK 3.13.7, pinned `>=3.10.0 <4.0.0`)
- State management: Provider (`ChangeNotifier`, `ChangeNotifierProvider`, `MultiProvider`)
- Data layer: SharedPreferences (settings persistence, translation cache) and local filesystem
- Runtime: Native FFmpeg (ffmpeg-kit-flutter) with C++ JNI Vulkan/NCNN neural upscale bindings on Android; desktop runners on Windows and Linux

## 3. Build, Run & Verification
- Analyze: `dart analyze --fatal-infos`
- Test: `flutter test`
- Format: `dart format --set-exit-if-changed .`
- Run: `flutter run`

## 4. High-Level Dependency Graph
```
UI Layer (Screens & Widgets: Dashboard, Process, Batch, History, Settings, Microstock)
   │
   ▼
State Layer (Providers: UniquifierProvider, BatchQueueProvider, ThemeProvider, LocaleProvider)
   │
   ▼
Service Layer (FfmpegService, AiSuperResolutionService, DeviceCapabilityService, SettingsService)
   │
   ▼
Infrastructure / Native (ffmpeg-kit-flutter, C++ NCNN JNI, SharedPreferences, PathProvider)
```

## 5. Entry Points
- `lib/main.dart` — `main()` — Application bootstrap, background service init, MultiProvider registration
- `linux/runner/main.cc` — `main()` — Linux native GTK desktop runner entry point

## 6. Module Inventory
- `core/models` (`lib/core/models/`) — Domain models including BatchVideoItem, VideoExportItem, and VideoVariations
- `core/providers` (`lib/core/providers/`) — Global state providers for pipeline configuration, batch queues, theme, and localization
- `core/services` (`lib/core/services/`) — Processing engines, FFmpeg CLI builder, AI super-resolution planner, storage management, and telemetry
- `core/theme` (`lib/core/theme/`) — Design tokens, color palettes, and typography definition
- `features/dashboard` (`lib/features/dashboard/`) — Bento-grid dashboard, performance metrics, and seasonal inspiration cards
- `features/process` (`lib/features/process/`) — Single and batch video transformation screens, stage tracker, and radar indicator
- `features/batch` (`lib/features/batch/`) — Queue monitoring, parallel item cancellation, and batch stats
- `features/history` (`lib/features/history/`) — Export gallery, file scanning, and output directory management
- `features/microstock` (`lib/features/microstock/`) — Microstock trends feed, metadata vault, and offline translation engine
- `features/settings` (`lib/features/settings/`) — Hardware acceleration toggles, codec selection, preset management, and language picker
- `shared/widgets` (`lib/shared/widgets/`) — Shared components such as TopAppBar, sliders, and navigation bar

## 7. External Integrations & I/O
- `FFmpegKit (ffmpeg-kit-flutter)` — Bidirectional — Video transcoding, audio resampling, and filter execution
- `C++ NCNN Vulkan Engine` — Outbound — Real-ESRGAN neural super-resolution compute on Android
- `Google Apps Script Webhook` — Outbound — Microstock metadata vault telemetry dispatching (optional / offline resilient)
- `RSS2JSON & Reddit Feeds` — Inbound — Microstock trend news polling with local fallback

## 8. Data Models & Persistence
- `BatchVideoItem` — Video path, resolution, status, progress, timestamps — In-memory queue
- `VideoExportItem` — File path, size, modified date, thumbnail path — Scanned filesystem entities
- `VideoVariations` — Crop percentage, brightness, contrast, noise, speed, rotation — Generated transformation parameters
- `DeviceSpecs` — RAM, ABI, CPU cores, GPU vendor, Vulkan support — Dynamic hardware profiling
- `SettingsService` — Codec, resolution, engine, audio/visual toggles — Persistent `SharedPreferences`

## 9. Key Constraints
- Offline-first: Full video transformation and anti-fingerprinting must execute entirely on-device without network dependency
- Scoped I/O: Video outputs save to user-accessible Movies/Uniquifier directory
- Non-blocking rendering: Native processing runs asynchronously via ffmpeg-kit sessions without freezing UI isolates
- Safe fallbacks: AI neural upscaling automatically falls back to Lanczos3 when Vulkan compute is unavailable

## 10. Link Map
| ID | Target | Description |
|----|--------|-------------|
| L-01 | `0ai_context/HANDOFF.md` | Self-contained briefing for AI chat |
| L-02 | `0ai_context/STATE.md` | Current project state |
| L-03 | `0ai_context/SKILLS.md` | Available tools |
| L-04 | `0ai_context/reports/01-audit.md` | Findings |
| L-05 | `0ai_context/OPENCODE-PROMPT-SPEC.md` | Canonical OpenCode Prompt Specification |
