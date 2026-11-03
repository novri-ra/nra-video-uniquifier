# Project State — nra_video_uniquifier

## 1. Repository Identity
- Name: `nra_video_uniquifier`
- Root: `C:/Users/Administrator/Saved Games/_Project/nra_video_uniquifier`
- Primary language: `Dart`
- Stack: `Flutter 3.47.8 / Dart 3.13.7`

## 2. Working Tree State
- Branch: `development`
- Head commit: `de2fc36f1994ecdb35df3b0a3d989517554a9630`
- Clean tree: yes
- Pre-existing changes: none

## 3. Git History Snapshot (14 days)
Top commits:
- `de2fc36 2026-11-04 feat(webhook): add Google Sheets webhook deployment guide and Apps Script for telemetry`
- `82a164f 2026-11-03 delete: Remove archived sprint reports and project context documentation`
- `acf834a 2026-11-03 feat: Add sprint reports for sprints 91 to 97 and archive historical reports`
- `b175c20 2026-11-03 fix(history): isolate exports, fix thumbnails, clean workspace, and target arm64 single build`
- `e6b62aa 2026-11-03 fix(process): correct pipeline step label contrast and apply vivid coral accent to active step line`
- `4d35c82 2026-11-03 feat(process): wire real processing stage tracker step index in processing screen`
- `ce0df20 2026-11-03 fix(theme): update pipeline stage step text styling for editorial design language compliance`
- `04ec471 2026-11-03 feat(l10n): add localized strings for processing stage tracker and engine state strip`
- `aa487eb 2026-11-03 test: add unit and widget test suite for processing stage tracker in dark and light modes`
- `0a84d49 2026-11-03 feat(ui): replace static text step tracker with dynamic 5-stage progress indicator`

Top changed files:
- `46 0ai_context/STATE.md`
- `34 lib/core/services/ffmpeg_service.dart`
- `32 test/ffmpeg_service_test.dart`
- `26 0ai_context/reports/INDEX.md`
- `25 lib/features/process/screens/processing_screen.dart`
- `25 test/widget_test.dart`
- `24 lib/core/providers/uniquifier_provider.dart`
- `20 lib/core/services/settings_service.dart`
- `18 lib/core/services/filter_builders.dart`
- `17 lib/features/process/widgets/modifiers_card.dart`

## 4. Health Summary
- Analyze: exit 0, No issues found!
- Test: 173/173 passed
- Format: 89 files unformatted (exit 1)

## 5. Graph Index Health
- Project: `C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier`
- Status: ready
- Revision: `de2fc36f1994ecdb35df3b0a3d989517554a9630`
- Nodes: 1671; Edges: 4755; Files: 185

## 6. Active Milestones & Goals
- Microstock automation and telemetry sync via Google Apps Script webhook
- UI polishing and stage tracking adherence to Editorial Architecture Design Tokens
- Maintaining 100% test pass rate across unit and responsive smoke tests

## 7. In-Flight Work
- Context mapping and baseline audit documentation under `0ai_context/`

## 8. Completed Work
- Dynamic 5-stage pipeline progress indicator (Sprint 96)
- Webhook deployment and live Apps Script integration for metadata vault telemetry
- Single-architecture arm64 release configuration and workspace cleanup

## 9. Blockers & Impediments
None currently blocking.

## 10. Incident Log
None recorded.

## 11. Update-Mode Incidents
None recorded.

## 12. Structural Debt
- High fan-in symbols: `AppColors` (169), `AppLocalizations.of` (98), `SettingsService` (50), `UniquifierProvider` (31), `TargetResolution` (26)
- Co-change coupling pairs (score 1.0): `uniquifier_provider.dart` ↔ `settings_service_test.dart`, `ffmpeg_service.dart` ↔ `variation_generator.dart`, `ncnn_sr_jni.cpp` ↔ `ffmpeg_service.dart`
- Cycles: 0 cycles detected
- Monolithic files: `test/ffmpeg_service_test.dart` (737 LOC), `test/widget_test.dart` (575 LOC), `lib/l10n/app_localizations.dart` (489 LOC)

## 13. Security & Safety Risks
- Hardcoded external storage paths (`/storage/emulated/0/Movies/Uniquifier`) in `lib/core/services/ffmpeg_service.dart:149` and `lib/core/services/history_service.dart:46`
- Silent exception swallowing (`catch (_) {}`) across critical service paths (`storage_service.dart:41`, `ffmpeg_service.dart:293`, `uniquifier_provider.dart:138`)

## 14. Missing / Unverified
None recorded.

## 15. Deferred Tasks & Shortcuts
- StatFS free space check on Android uses temp directory write test shortcut in `StorageService.hasEnoughSpace`

## 16. Append-Only Chronology
### 2026-11-04
- Executed context mapping run v6.0; captured health baseline (173/173 tests passing, format gate failure on 89 files)
