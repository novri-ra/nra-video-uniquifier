# Project State — nra_video_uniquifier

## 1. Repository Identity
- Name: `nra_video_uniquifier`
- Root: `C:/Users/Administrator/Saved Games/_Project/nra_video_uniquifier`
- Primary language: `dart`
- Stack: `Flutter 3.47.8 / Dart 3.13.7`, app version `1.0.5+5`

## 2. Working Tree State
- Branch: `development`
- Head commit: `6278087bcdd5364538ff2b54de5be7c71e3c82ba`
- Clean tree: no
- Pre-existing changes:
  - ` D OpenCode-Bootstrap-Prompt.txt`
  - ` M lib/core/services/ffmpeg/ffmpeg_command_builder.dart`
  - ` M lib/features/process/widgets/modifiers_card.dart`
  - ` M macos/Flutter/GeneratedPluginRegistrant.swift`
  - ` M windows/flutter/generated_plugin_registrant.cc`
  - ` M windows/flutter/generated_plugins.cmake`

## 3. Git History Snapshot (14 days)
Recent commits:
- 6278087 2026-11-08 chore(release): bump version to v1.0.5
- e020826 2026-11-07 fix(notifications): sync test expectations and showTestNotification with new separated channels
- ad5509e 2026-11-07 docs: update changelog and readme with latest performance and evasion fixes
- f691b04 2026-11-07 perf: optimize battery, enhance TikTok evasion filters, fix FFmpeg preview crash, and update tests
- e3bc546 2026-11-06 docs(README): update feature descriptions and enhance clarity on visual effects and testing
- 7fdb3bb 2026-11-06 test(ffmpeg): add unit tests for activeVisualEffects and rotateAngle wiring
- d1c29da 2026-11-06 fix(android): add mediaProcessing foreground service type for Android 14+ compliance
- 53a786f 2026-11-06 fix(ffmpeg): auto-purge old preview cache files to prevent storage bloat
- 015c987 2026-11-06 fix(batch): forward rotateAngle and activeVisualEffects to processVideo pipeline
- e5ec30f 2026-11-06 fix(ffmpeg): wire multi-select activeVisualEffects from UI to export pipeline

Top churn files:
- 34 `0ai_context/reports/INDEX.md`
- 26 `CHANGELOG.md`
- 14 `lib/core/services/ffmpeg_service.dart`
- 10 `lib/core/services/filter_builders.dart`
- 10 `pubspec.yaml`
- 9 `lib/features/microstock/widgets/microstock_article_sheet.dart`
- 9 `lib/features/history/screens/recent_history_screen.dart`
- 9 `lib/core/providers/uniquifier_provider.dart`
- 8 `lib/core/services/history_service.dart`
- 8 `lib/core/services/microstock_news_service.dart`

## 4. Health Summary
- Analyze: exit 0 — `No issues found!`
- Test: 216/216 passed (exit 0)
- Format: exit 1 — 7 files unformatted

## 5. Graph Index Health
- Project: `C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier`
- Status: ready
- Revision: indexed 2026-11-07T18:01:14Z (watch mode, git strategy, 5s poll)
- Nodes: 2571; Edges: 6819; Files: 273
- Coverage gaps: 7 files parse-partial (`docs/stitch_offline_video_uniquifier_app/*`, `linux/**`, `windows/runner/main.cpp`); 123 files excluded by design (gitignore).

## 6. Active Milestones & Goals
- v1.0.5 shipped; next milestone is not declared in the repository (README/CHANGELOG only describe released work).
- Implied goal from recent commits: harden evasion filters, battery behaviour, and notification delivery.

## 7. In-Flight Work
- `lib/core/services/ffmpeg/ffmpeg_command_builder.dart` modified in the working tree: FFmpeg command construction is being extracted out of `FfmpegService` (610 lines remain).
- `lib/features/process/widgets/modifiers_card.dart` modified: modifier card UI is being reworked.
- Root `OpenCode-Bootstrap-Prompt.txt` is deleted in the working tree (pending commit).

## 8. Completed Work
- Release chain v1.0.0 → v1.0.5 with reports 28–44.
- Provider refactor: `UniquifierProvider` decomposed into `uniquifier_progress_mixin`, `uniquifier_media_mixin`, `uniquifier_modifiers_mixin` (resolves AUDIT-20261104-004).
- `SuccessScreen` reduced to 211 lines (resolves AUDIT-20261104-005).
- Batch queue parameter-drop fix (report 42), preview cache purge (report 43), Android `mediaProcessing` service type (report 44).
- Notification channel split: silent progress channel vs alerting completion channel.

## 9. Blockers & Impediments
None currently blocking.

## 10. Incident Log
None recorded.

## 11. Update-Mode Incidents
- 2026-11-08: the Phase 2 format probe (`dart format --set-exit-if-changed .`) rewrites files before reporting. Six files that were clean at run start were formatted and then restored with `git checkout --`; `lib/features/process/widgets/modifiers_card.dart` was already user-modified, so it kept its formatted state. Recorded in `raw/health/summary.json`.

## 12. Structural Debt
- Highest fan-in: `AppColors` (181), `AppLocalizations.of` (102), `UniquifierProvider` (37), `AppLocalizations` (29), `TargetResolution`/`SettingsService` (26), `UpscaleEngine` (24), `UnifiedVisualEffect` (22), `BatchQueueProvider` (18).
- Oversized files: `test/ffmpeg_service_test.dart` 1147, `lib/features/microstock/widgets/microstock_article_sheet.dart` 901, `lib/core/services/microstock_news_service.dart` 791, `test/widget_test.dart` 730, `lib/core/services/filter_builders.dart` 691, `lib/core/services/ffmpeg_service.dart` 610.
- Call cycle: `FilterBuilders.buildVideoFilter` ↔ `FilterBuilders._fallbackVideoFilter`.
- Coupling: `ffmpeg_service.dart` ↔ `filter_builders.dart` co-change score 0.89 (8 co-changes); `uniquifier_provider.dart` ↔ `ffmpeg_service.dart` 0.86.
- Dead UI surface: `MicrostockAiScreen` (`lib/features/microstock/screens/microstock_ai_screen.dart`) has zero graph edges.
- Empty catch blocks: 85 occurrences across 24 files.

## 13. Security & Safety Risks
- AUDIT-20261108-001 (P1): `lib/core/providers/uniquifier/uniquifier_modifiers_mixin.dart:142` — 27 empty catches swallow settings persistence failures.
- AUDIT-20261108-002 (P1): `lib/core/services/ffmpeg_service.dart:147` — empty catches in staging/cleanup hide filesystem failures.
- AUDIT-20261108-003 (P1): `lib/core/services/microstock_news_service.dart:241` — empty catches hide feed failures.
- AUDIT-20261108-004 (P1): `lib/core/services/notification_service.dart:65` — empty catches hide delivery failures.
- AUDIT-20261108-005 (P1): `lib/core/services/history_service.dart:62` — empty catches can lose the export ledger.
- AUDIT-20261108-006 (P1): `lib/core/services/user_interest_service.dart:262` — affinity migration decode failure swallowed.
- AUDIT-20261108-014 (P2): `README.md:7` — "zero network transmission" claim conflicts with the RSS news fetches.

## 14. Missing / Unverified
- No automated coverage measurement was run in this pass; report 40 claimed 75.44% line coverage at commit `d692bf9`, which is not re-verified here.
- Graph coverage: 7 files parse-partial, so symbols inside those ranges may be missing from graph queries.
- SKILLS enumeration: 98 distinct skill directories detected; 316 `SKILL.md` files exist because several skills ship nested sub-skill files.

## 15. Deferred Tasks & Shortcuts
- Format gate repair (7 files) deferred to a dedicated whitespace-only commit.
- Empty-catch remediation deferred; no single owner file yet.

## 16. Append-Only Chronology
### 2026-11-04
- Context bootstrap run completed cleanly with full test pass (173/173, analyze clean).

### 2026-11-08
- Context mapper re-run (v6.0) at commit `6278087`; analyze clean, 216/216 tests passing, format gate failing on 7 files.
- Graph re-queried: 2571 nodes / 6819 edges, 1 call cycle, 9 file co-change edges.
- 20 findings recorded in report 86 (P0=0, P1=6, P2=9, P3=5).
- Provider god-object and oversized SuccessScreen findings from 2026-11-04 are now resolved.
