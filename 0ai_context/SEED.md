# Repository Seed — nra_video_uniquifier

## 1. Executive Summary
NRA Video Uniquifier is an offline-first Flutter application that rewrites video characteristics and container metadata so uploaded clips stop matching automated fingerprint hashes. It runs FFmpegKit on-device, supports Lanczos/AI upscaling to 1080p/2K/4K, batch queues, and a live debounced preview. Current state: v1.0.5+5 on branch `development`, analyze clean, 216/216 tests passing, format gate failing on 7 files.

## 2. Core Architecture & Stack
- Framework: Flutter 3.47.8 (stable) / Dart SDK 3.13.7, pubspec constraint `>=3.10.0 <4.0.0`
- State management: Provider (`ChangeNotifier`) — `UniquifierProvider` (composed from `uniquifier_progress_mixin`, `uniquifier_media_mixin`, `uniquifier_modifiers_mixin`), `BatchQueueProvider`, `ThemeProvider`, `LocaleProvider`
- Data layer: local filesystem (Movies/Uniquifier public storage + app cache), `shared_preferences`
- Engine: FFmpegKit (`ffmpeg_kit_flutter_new`), optional ncnn Vulkan super-resolution native lib (`android/app/src/main/cpp/ncnn_sr_jni.cpp`)
- Runtime targets: Android, iOS, Windows, macOS, Linux, Web scaffold

## 3. Build, Run & Verification
- Analyze: `dart analyze --fatal-infos`
- Test: `flutter test`
- Format: `dart format --set-exit-if-changed .`
- Run: `flutter run`

## 4. High-Level Dependency Graph
- Entry: `lib/main.dart` → registers 8 services/providers → `RootNavigationScreen`
- Presentation: `lib/features/**` (dashboard, process, batch, history, microstock, settings, profile, navigation)
- State orchestration: `lib/core/providers/**` → `UniquifierProvider`, `BatchQueueProvider`
- Engine core: `lib/core/services/**` → `FfmpegService` → `FfmpegCommandBuilder` → `FilterBuilders` → `VariationGenerator`
- Platform I/O: `lib/core/services/**` → storage, notification, history, connectivity, device capability
- Design system: `lib/core/theme/**` (`AppColors` fan-in 181) + `lib/shared/widgets/**` + `lib/l10n/**`

## 5. Entry Points
- `lib/main.dart` — `main()` — initializes FFmpeg session history, prunes stale files, purges temp cache, mounts MultiProvider + MaterialApp.
- `lib/features/navigation/screens/root_navigation_screen.dart` — 4-slot floating navbar shell (Studio / Batch / History / Settings).
- `lib/core/services/ffmpeg_service.dart` — `processVideo()` — the real export entry point invoked from `UniquifierProvider`.
- `lib/core/services/ffmpeg_service.dart` — `renderFilteredPreviewFrame()` — live preview render path.

## 6. Module Inventory
- `core/models` (`lib/core/models/`) — `UnifiedVisualEffect` catalog and shared value objects.
- `core/providers` (`lib/core/providers/`) — Uniquifier state (split into 3 mixins), batch queue, theme, locale.
- `core/services` (`lib/core/services/`) — FFmpeg orchestration, settings, storage, history, notification, connectivity, device capability, render diagnostics.
- `core/services/ffmpeg` (`lib/core/services/ffmpeg/`) — `FfmpegCommandBuilder`, metadata builder, file helper, media probe helper.
- `core/theme` (`lib/core/theme/`) — `AppColors` tokens and `AppTheme`.
- `core/utils` (`lib/core/utils/`) — variation generator (device profiles), formatters.
- `features/process` (`lib/features/process/`) — studio screen, processing screen, success/error screens, modifier cards, preview slider.
- `features/batch` (`lib/features/batch/`) — batch queue screen.
- `features/history` (`lib/features/history/`) — export history list and storage bar.
- `features/microstock` (`lib/features/microstock/`) — RSS news reader, article sheet, HTML sanitizer, bookmark service.
- `features/dashboard` (`lib/features/dashboard/`) — bento metric grid, live intel ticker.
- `features/settings`, `features/profile`, `features/navigation` — configuration, about, app shell.
- `shared/widgets` (`lib/shared/widgets/`) — `TopAppBar`, toast, reusable controls.
- `l10n` (`lib/l10n/`) — generated `AppLocalizations` (English default).

## 7. External Integrations & I/O
- FFmpegKit — outbound subprocess — transcoding, filtering, metadata scrubbing, probe.
- Android public storage (`/storage/emulated/0/Movies/Uniquifier`) — bidirectional — final export destination.
- `shared_preferences` — bidirectional — settings, history ledger, locale, theme, interest affinity.
- `flutter_local_notifications` — outbound — silent progress channel + alerting completion channel.
- `connectivity_plus` — inbound — offline indicator (event-driven, no polling).
- Microstock RSS feeds (petapixel.com, fstoppers.com) — inbound HTTP GET — news reader only; this is the single network path in the app.
- ncnn Vulkan native library — in-process — optional super-resolution engine.

## 8. Data Models & Persistence
- `BatchVideoItem` — id, path, status, progress, targetResolution — in-memory queue state.
- `VideoExportItem` — id, originalPath, outputPath, timestamp, size — SharedPreferences ledger + filesystem.
- `MicrostockNewsArticle` — id, title, content, publishedAt, category — local cache.
- `UnifiedVisualEffect` — id, displayName, description — static enum, drives filter selection.
- `DeviceProfile` — make, model, encoder, videoHandler, audioHandler — metadata masquerade presets.
- `DeviceSpecs` / `DeviceTier` — RAM, cores, ABI, Vulkan support, tier — runtime capability gate.

## 9. Key Constraints
- Offline-first execution: video processing requires no network.
- No user video data or absolute paths leave the device; only the news reader performs outbound HTTP.
- Non-destructive execution: originals are never mutated; exports are staged then atomically moved.
- Android 7.0+ through 16 supported; foreground service declares `dataSync|mediaProcessing`.
- All UI copy and localization default to English.

## 10. Link Map
| ID | Target | Description |
|----|--------|-------------|
| L-01 | `0ai_context/HANDOFF.md` | Self-contained briefing for AI chat |
| L-02 | `0ai_context/STATE.md` | Current project state |
| L-03 | `0ai_context/SKILLS.md` | Available tools |
| L-04 | `0ai_context/reports/86-audit.md` | Findings |
| L-05 | `0ai_context/OPENCODE-PROMPT-SPEC.md` | Canonical prompt structure |
