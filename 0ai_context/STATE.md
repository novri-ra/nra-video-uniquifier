# Project State: NRA Video Uniquifier

## 1. Environment & Git Status
- **Timestamp**: 2026-10-29 19:35:00 UTC+07:00
- **Git Branch**: `development`
- **HEAD Commit**: `de8536a fix(pipeline): resolve A/V desync, enforce even macroblock rotation, enable release R8 minification`
- **Working Tree**: Play Core ProGuard rules updated, tests passing (64/64), analyze 0 errors.
- **Recent 5 Commits**:
  - `de8536a` fix(pipeline): resolve A/V desync, enforce even macroblock rotation, enable release R8 minification
  - `de02417` fix(android): add ffmpegkit proguard keep rules, patch path security, and update workflow standards
  - `1bfde3b` fix(android): remove redundant ndk abiFilters to enable clean split-per-abi release builds
  - `ee17278` chore(release): finalize stable build with full anti-fingerprint evasion and 4K pipeline
  - `dbc8ebe` fix(ffmpeg): orientation-aware scaling for true portrait 4K and render diagnostics

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
- [x] Purge dead code (5 functions, 5 color tokens) and free line budget.
- [x] Storage & progress bar hardening (stop fake ticker on real onProgress, filter 0-byte history files, purge temp cache on startup).
- [ ] Prepare Google Play Store release metadata and production key signing.
- [ ] Implement optional batch video processing queue for multiple file selections.

## 3. MCP Index Status
- **MCP Server**: `codebase-memory-mcp`
- **Trust Tier**: Managed via Hermes config (`command: C:/Users/Administrator/.local/bin/codebase-memory-mcp.exe`).
- **Indexed At**: 2026-10-29T12:29:06Z
- **Index Counts**: 1227 nodes, 3022 edges, status ready.

## 4. Module Health (5 Most Critical Files)
All critical modules strictly respect the <= 400 lines ceiling:
1. `lib/core/providers/uniquifier_provider.dart` — 390 lines
2. `lib/core/services/ffmpeg_service.dart` — 355 lines
3. `lib/features/navigation/screens/root_navigation_screen.dart` — 343 lines
4. `lib/features/process/screens/processing_screen.dart` — 322 lines
5. `lib/features/process/widgets/source_file_section.dart` — 308 lines

## 5. Hygiene & Dead Code Audit
- **Junk Scan**: Scanned for `__pycache__`, `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.log`. None found in tracked source paths.
- **Gitignore**: Updated with `Movies/`, `0ai_context[0-9]*/`, `*.mp4`, `Thumbs.db`, `*.tmp`.
- **Dead Code Audit**:
  - Query: `tools["codebase-memory-mcp"].search_graph({ file_pattern: "lib/.*", max_degree: 0 })`
  - Result: 0 unreferenced symbols found in `lib/`.
  - Manual import scan: All 29 Dart source files in `lib/` are actively imported and exercised in test suites.
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
