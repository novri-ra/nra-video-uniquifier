# Project State: NRA Video Uniquifier

## 1. Environment & Git Status
- **Timestamp**: 2026-10-30 11:15:00 UTC+07:00
- **Git Branch**: `development`
- **HEAD Commit**: `57ee297 refactor(provider): extract pure formatters from UniquifierProvider [P2-L-EXT-1]`
- **Working Tree**: Anti-vDNA TikTok evasion hardened, Sprint 4 decomposition phase 1 complete, 99/99 tests passed, analyze 0 errors.

## 2. Active Roadmap & Next Items
- [x] Full responsive UI across phone, desktop, and tablet layouts.
- [x] FFmpeg portrait 4K orientation-aware scaling and render diagnostics.
- [x] Advanced vDNA evasion: chroma jitter, subtle pitch shift, audio spectrogram masking, micro-crop.
- [x] Split-ABI Android release pipeline verification.
- [x] Bootstrap native Hermes context packet (`AGENTS.md`, `0ai_context/`).
- [x] ProGuard/R8 keep rules applied for FFmpegKit release crash fix.
- [x] Security vulnerabilities patched (SEC-01 quote escaping, SEC-02 source deletion guard, SEC-03 FileProvider).
- [x] Workflow standards updated with declarative skill loading and graph verification blocks.
- [x] Remediate A/V Desync (+5.84s drift eliminated, pure 1.015 tempo matched to 0.9852*PTS).
- [x] Even macroblock bounds enforced on spatial rotation (`trunc(rotw/2)*2`).
- [x] Enable release R8 minification (`isMinifyEnabled = true`, `isShrinkResources = true`).
- [x] Suppress Play Core / Dynamic Delivery R8 warnings (`-dontwarn com.google.android.play.core.**`).
- [x] Ongoing progress notifications, throttled updates, completion sound, and background execution resilience.
- [x] Core library desugaring enabled for `flutter_local_notifications`.
- [x] Purge dead code (5 functions, 5 color tokens) and free line budget.
- [x] Storage & progress bar hardening (stop fake ticker on real onProgress, filter 0-byte history files, purge temp cache on startup).
- [x] Implement batch video processing queue for multiple file selections.
- [x] Prepare Google Play Store release metadata and production key signing.
- [x] Fix color corruption (purge `curves=preset=vintage`, enforce `format=yuv420p`, `-pix_fmt yuv420p`, `-movflags +faststart`, BT.709 color metadata).
- [x] Implement configurable video codec engine (H.264 AVC vs H.265 HEVC with `-tag:v hvc1`).
- [x] Dedicated Settings tab in root navigation bar (`SettingsScreen`).
- [x] Harden anti-vDNA evasion filters to bypass TikTok originality detection (8% offset crop, 0.8° tilt, noise grain 4, 0.975*PTS, 1.0256 audio tempo & dual-band EQ).
- [ ] Connect physical device or emulator for end-to-end smoke test on device.

## 3. MCP Index Status
- **MCP Server**: `codebase-memory-mcp`
- **Trust Tier**: Managed via Hermes config (`command: C:/Users/Administrator/.local/bin/codebase-memory-mcp.exe`).
- **Indexed At**: 2026-10-30T04:10:00Z
- **Index Counts**: 1421 nodes, 3658 edges, status ready.

## 4. Module Health (5 Most Critical Files)
All critical modules strictly respect the <= 400 lines ceiling:
1. `lib/core/services/ffmpeg_service.dart` — 396 lines
2. `lib/features/settings/screens/settings_screen.dart` — 394 lines
3. `lib/core/providers/uniquifier_provider.dart` — 367 lines
4. `lib/features/process/screens/processing_screen.dart` — 318 lines
5. `lib/features/process/widgets/source_file_section.dart` — 316 lines

## 5. Hygiene & Dead Code Audit
- **Junk Scan**: Scanned for `__pycache__`, `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.log`. None found in tracked source paths.
- **Gitignore**: Updated with `Movies/`, `0ai_context[0-9]*/`, `*.mp4`, `Thumbs.db`, `*.tmp`.
- **Dead Code Audit**:
  - Query: `tools["codebase-memory-mcp"].search_graph({ file_pattern: "lib/.*", max_degree: 0 })`
  - Result: 0 unreferenced symbols found in `lib/`.
  - Manual import scan: All 33 Dart source files in `lib/` are actively imported and exercised in test suites.
- **Dead Code Candidates**: 0 candidates flagged.

## 6. Skills Status
Mandatory skills installed and verified via `hermes skills list`:
- `/senior-architect` (`opencode-imported/senior-architect`): Available
- `/clean-code` (`opencode-imported/clean-code`): Available
- `/systematic-debugging` (`software-development/systematic-debugging`): Available
- `/senior-qa` (`opencode-imported/senior-qa`): Available
- **Configuration Note**: Added to `~/.hermes/config.yaml` under `skills.auto_load` to ensure identical byte loading across sessions without cache invalidation.

## 7. Cache Note
No skills added or removed mid-session. Persistent auto-load registered in global configuration.
