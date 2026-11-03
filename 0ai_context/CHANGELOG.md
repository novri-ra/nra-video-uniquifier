# Changelog — NRA Video Uniquifier

## v2.0.0+72 (2026-11-03)

### Major Features (Sprint 64–68)
- **Google Sheets Real-Time Telemetry & Video Metadata Vault Webhook:** Live export of render metrics and video fingerprint metadata to Google Sheets via HTTP webhook integration.
- **Adaptive Keyword Chips Carousel (YouTube-Style Self-Learning):** Context-aware keyword tag suggestions with carousel UI, learning from user selection patterns.
- **Natural Context-Aware Translation Engine with Microstock Glossary:** Intelligent translation pipeline leveraging domain-specific glossary for microstock video metadata fields.
- **High-End Bento Grid Dashboard with Expanded 78dp Gauges & Live Intel Ticker:** Redesigned main dashboard with bento-grid layout, real-time processing gauges, and scrolling intel ticker for engine status.
- **Trashed File Filtering & Graceful Eviction on History Deletion:** History screen filters trashed/deleted files from listings and gracefully evicts stale entries without crash.

### Sprint 68 — Notification & FPS
- Android notification channel registration (`nra_video_processing_channel`) via native `MainActivity.kt` and Flutter plugin.
- Bootstrap 1x self-canceling notification forces OS channel registration in system settings.
- Live rendering progress dispatch (ID 101) with 2% / 1s throttle and Indonesian stage descriptions.
- Completion notification: "Ekspor Berhasil — Video siap di galeri".
- Target framerate control (24 / 30 / 60 FPS) with `SettingFpsSelectorRow` UI widget.
- FFmpeg pipeline injection: `-fps_mode cfr -r $targetFps` and zoompan `fps=$targetFps`.

### Sprint 67 — Responsive Terminal Log
- Dynamic flex-fill terminal log viewer using `Expanded` instead of fixed 120dp height.
- Stateful auto-scroll `ScrollController` jumping to `maxScrollExtent` on new log entries.
- Fallback initialization log when `terminalLogs` is null.

### Sprint 66 — Workspace Cleanup & Deployment
- Archived sprint reports 01–63 into `0ai_context/reports/archive/`.
- Generated comprehensive `INDEX.md` covering all 66 sprints.
- Release APK build with obfuscation and ADB deployment.

### Sprint 65 — Master Engine Optimization
- 100% engine load (`-threads 0`), FastStart (`-movflags +faststart`), even dimension guard.
- CFR mode (`-fps_mode cfr`), studio audio AAC 192k, PopScope back-press guard.
- Batch queue resilience, storage health guard (2 GB minimum), preset chips UI.

### Sprint 64 — Hardware Profiler & Icons
- Dynamic hardware profiling via `DeviceCapabilityService`.
- Background wakelock resilience for long renders.
- App icon branding integration.

### Earlier Sprints (01–63)
See archived reports in `0ai_context/reports/archive/` and `0ai_context/reports/INDEX.md`.
