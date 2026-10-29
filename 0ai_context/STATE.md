# Project State: NRA Video Uniquifier

## 1. Environment & Git Status
- **Timestamp**: 2026-10-29 08:35:00 UTC+07:00
- **Git Branch**: `development`
- **HEAD Commit**: `1bfde3b fix(android): remove redundant ndk abiFilters to enable clean split-per-abi release builds`
- **Working Tree**: Modified: `.gitignore`, `AGENTS.md`, `0ai_context/*` (clean pipeline, tests passing 61/61).
- **Recent 5 Commits**:
  - `1bfde3b` fix(android): remove redundant ndk abiFilters to enable clean split-per-abi release builds
  - `ee17278` chore(release): finalize stable build with full anti-fingerprint evasion and 4K pipeline
  - `dbc8ebe` fix(ffmpeg): orientation-aware scaling for true portrait 4K and render diagnostics
  - `a5d2f7f` feat(pipeline): advanced vDNA evasion, audio spectrogram masking, and auto-trim
  - `419437c` feat(pipeline): modular denoise, clarity enhancer, and deep evasion filters

## 2. Active Roadmap & Next Items
- [x] Full responsive UI across phone, desktop, and tablet layouts.
- [x] FFmpeg portrait 4K orientation-aware scaling and render diagnostics.
- [x] Advanced vDNA evasion: chroma jitter, subtle pitch shift, audio spectrogram masking, micro-crop.
- [x] Split-ABI Android release pipeline verification.
- [x] Bootstrap native Hermes context packet (`AGENTS.md`, `0ai_context/`).
- [x] ProGuard/R8 keep rules applied for FFmpegKit release crash fix.
- [x] Security vulnerabilities patched (SEC-01 quote escaping, SEC-02 source deletion guard, SEC-03 FileProvider).
- [x] Workflow standards updated with declarative skill loading and graph verification blocks.
- [ ] Prepare Google Play Store release metadata and production key signing.
- [ ] Implement optional batch video processing queue for multiple file selections.

## 3. MCP Index Status
- **MCP Server**: `codebase-memory-mcp`
- **Trust Tier**: Managed via Hermes config (`command: C:/Users/Administrator/.local/bin/codebase-memory-mcp.exe`).
- **Indexed At**: 2026-10-29T01:23:38Z
- **Index Counts**: 1119 nodes, 2734 edges, status ready.
- **Node Breakdown**: File 132, Class 177, Method 236, Section 240, Module 126, Folder 80, Variable 68, Function 30, Field 13, Macro 12, Decorator 2, Enum 1, Branch 1, Project 1.
- **Tools Tested & Discovered**: 17 tools discovered via `hermes mcp test codebase-memory-mcp` (pass in 6912ms).
- **MCP Calls Performed**:
  - `index_repository`: refreshed and verified.
  - `index_status`: verified ready.
  - `get_graph_schema`: full edge/node census.
  - `search_graph`: symbol and degree filtering.
  - `get_file_outline`: verified outline extraction.
  - `trace_path`: verified call graph hops.
  - `query_graph`: openCypher queries executed.

## 4. Module Health (5 Most Critical Files)
All critical modules strictly respect the <= 400 lines ceiling:
1. `lib/core/providers/uniquifier_provider.dart` — 396 lines (fan-in: 17)
2. `lib/core/services/ffmpeg_service.dart` — 386 lines (fan-out: 12)
3. `lib/features/navigation/screens/root_navigation_screen.dart` — 343 lines
4. `lib/features/process/screens/processing_screen.dart` — 318 lines
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
