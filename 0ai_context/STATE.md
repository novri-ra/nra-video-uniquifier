# Project State — nra_video_uniquifier

## 1. Repository Identity
- Name: `nra_video_uniquifier`
- Root: `C:/Users/Administrator/Saved Games/_Project/nra_video_uniquifier`
- Primary language: `dart`
- Stack: `Flutter 3.47.8 / Dart 3.13.7`, app version `1.0.5+5`
- Video engine: software H.264 only (`libx264`, `-preset fast -crf 18`, `-hwaccel none`)

## 2. Working Tree State
- Branch: `development`
- Head commit: `3d4d4ed` (fix(core): resolve filter bottleneck, audio leak, and export hang)
- Clean tree: yes (mapper run 129 applied on top of `3d4d4ed`)

## 3. Git History Snapshot
Recent commits:
- 3d4d4ed 2026-11-14 fix(core): resolve filter bottleneck, audio leak, and export hang
- fbeb09f 2026-11-14 fix(audit): chunk ffmpeg log to prevent logcat truncation
- 108b937 2026-11-13 fix(ffmpeg): force software decoding and add command audit log
- 1e42095 2026-11-13 feat(core): ultimate stability lock, remove intel tab, and setup lut engine

## 4. Health Summary
- Analyze: exit 0 — No issues found!
- Test: 240/240 passed (exit 0)
- Format: exit 0 — 0 files changed (PASS)

## 5. Graph Index Health
- Project: `nra_video_uniquifier`
- Status: ready
- Nodes: 2908; Edges: 7070; indexed_at 2026-11-13T14:31:12Z

## 6. Active Milestones & Goals
- Android 15/16 stability lock shipped: hardware decode/encode and H.265 are
  disabled in the UI and in the command builder; software `libx264` is forced.
- CapCut-style editor pivot started: the News tab is gone and the LUT (`lut3d`)
  asset pipeline is in place (`assets/luts/`).

## 7. In-Flight Work
- None. Clean baseline at commit `3d4d4ed`.

## 8. Completed Work
- Reports 123–128: software encoding lock, H.265/HW-accel UI locks, News tab
  removal, LUT engine foundation, chunked FFmpeg audit logging, audio leak fix
  (`d=7200` → `d=60`), filter-thread unblocking, 30 s export timeout.

## 9. Blockers & Impediments
- None.

## 10. Incident Log
- MCP index_status exit code 1 once during preflight; retry succeeded (finding 027).
- Finding 036 (dual findings.json) resolved by report 137.

## 11. Update-Mode Incidents
- Format gate is green (exit 0); 127 files, 0 changed.

## 12. Structural Debt
- High fan-in on AppColors, AppLocalizations, UniquifierProvider.
- News/Intel tab removed from `FloatingCapsuleNavBar` and `RootNavigationScreen`
  (4 tabs: Home, Studio, History, Profile); `microstock_news_screen.dart` and its
  services remain in the tree but are no longer reachable from the shell.
- 2 active findings (0 P0, 0 P1, 0 P2, 2 P3): 027, 028.

## 13. Security & Safety Risks
- AUDIT-20261108-022 (P2) is resolved (report 105).
- AUDIT-20261108-024 (P2) is invalid (report 120 — the temp-cache walks diverge).
- AUDIT-20261108-037 (P2) is resolved (report 123 — `_cleanupOldPreviews` logs
  basename + `e.runtimeType` only).
- Remaining P3 items: MCP flakiness (027), basename policy
  ambiguity (028), dual findings.json locations (036). (Finding 020 resolved via reports 134-135).

## 14. Missing / Unverified
- Basename vs absolute path policy in logs (finding 028).

## 15. Next Actions
- Decide the canonical `findings.json` path and retire `0ai_context/raw/findings.json`
  (finding 036).
- Re-verify finding 020 (silent catch count) or close it as superseded.

## 16. Run Manifest
- Mapper run 129 generated at commit `3d4d4ed`.
