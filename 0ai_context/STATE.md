# Project State — nra_video_uniquifier

## 1. Repository Identity
- Name: `nra_video_uniquifier`
- Root: `C:/Users/Administrator/Saved Games/_Project/nra_video_uniquifier`
- Primary language: `dart`
- Stack: `Flutter 3.47.8 / Dart 3.13.7`

## 2. Working Tree State
- Branch: `development`
- Head commit: `c1db18f1261bacb0580d8319cdc47413c9598e12`
- Clean tree: yes
- Pre-existing changes: none

## 3. Git History Snapshot (14 days)
Recent Commits:
- c1db18f chore(ai): remove 0ai_context completely for fresh bootstrap
- eae9ca1 docs(changelog): record initial baseline and project context initialization
- 4945417 docs(context): regenerate context packet and audit report
- e231459 docs(changelog): record initial baseline and project context initialization
- cfae1ca docs(context): regenerate context packet and audit report
- 7d997f7 docs(context): regenerate context packet and audit report
- 341f2a3 docs(context): regenerate context packet and audit report
- 78c3b73 docs(context): regenerate context packet and audit report
- 4a53da2 docs(context): regenerate context packet and audit report
- a4a974b docs(context): regenerate context packet and audit report

Top Churn Files:
- 4 OpenCode-Bootstrap-Prompt.txt
- 3 0ai_context/OPENCODE-PROMPT-SPEC.md
- 2 lib/core/services/notification_service.dart
- 2 lib/core/services/ffmpeg_service.dart
- 2 lib/core/services/microstock_news_service.dart
- 2 CHANGELOG.md
- 2 lib/core/providers/uniquifier_provider.dart
- 2 lib/core/services/device_capability_service.dart
- 2 lib/features/process/screens/processing_screen.dart
- 2 test/notification_service_test.dart

## 4. Health Summary
- Analyze: exit 0 (0 issues found)
- Test: 173/173 passed
- Format: 0 files unformatted

## 5. Graph Index Health
- Project: `C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier`
- Status: ready
- Revision: `c1db18f1261bacb0580d8319cdc47413c9598e12`
- Nodes: 1660; Edges: 4607; Files: 185

## 6. Active Milestones & Goals
- Release v2.0.0 baseline preparation and production stabilization.

## 7. In-Flight Work
- Context mapping, documentation hardening, and codebase health verification.

## 8. Completed Work
- Verified all 173 test cases across UI widgets and FFmpeg services.
- Confirmed zero static analysis issues across Flutter codebase.

## 9. Blockers & Impediments
None currently blocking.

## 10. Incident Log
None recorded.

## 11. Update-Mode Incidents
None recorded.

## 12. Structural Debt
- High fan-in symbols: `AppColors` (169), `SettingsService` (50), `AppLocalizations` (27), `TargetResolution` (19), `UpscaleEngine` (17), `FfmpegService` (12), `UniquifierProvider` (10).
- God-classes: `FfmpegService` (699 lines), `UniquifierProvider` (605 lines).

## 13. Security & Safety Risks
- AUDIT-20261104-001 (P1): `lib/core/services/ffmpeg_service.dart:227` — Swallowed exception in media processing.
- AUDIT-20261104-002 (P1): `lib/core/providers/uniquifier_provider.dart:97` — Unhandled exception during provider init.

## 14. Missing / Unverified
None recorded.

## 15. Deferred Tasks & Shortcuts
None currently deferred.

## 16. Append-Only Chronology
### 2026-11-04
- Context bootstrap run completed cleanly with full test pass.
