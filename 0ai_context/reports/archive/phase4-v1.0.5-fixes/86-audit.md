# Project Audit — Report 86

## Summary
- Revision: `6278087bcdd5364538ff2b54de5be7c71e3c82ba` (branch `development`)
- Stack: Dart 3.13.7, Flutter 3.47.8, FFmpegKit, ncnn Vulkan (optional), targets Android/iOS/Windows/macOS/Linux
- Deterministic: analyze=exit 0, test=216/216, format=7 files changed
- Findings: P0=0, P1=6, P2=9, P3=5
- Graph checks: run — 2571 nodes / 6819 edges, fan-in, co-change, cycles, dead-code (via zero-degree search)

## Deterministic Checks
| Check | Command | Result | Evidence |
|-------|---------|--------|----------|
| Analyze | `dart analyze --fatal-infos` | exit 0, `No issues found!` | `raw/health/analyze.log` |
| Test | `flutter test` | 216/216 passed, exit 0 | `raw/health/test.log` |
| Format | `dart format --set-exit-if-changed .` | exit 1, 7 files changed | `raw/health/format.log` |

## Findings

### AUDIT-20261108-001 — P1 — 27 empty catch blocks swallow modifier persistence
- Category: correctness
- Location: `lib/core/providers/uniquifier/uniquifier_modifiers_mixin.dart:142`
- Evidence: E1 — pattern scan `catch (_) {}`, 27 hits in this file out of 85 in `lib/`
- Impact: settings writes and preview-render failures are discarded, so UI state silently diverges from stored state.
- Fix: log the exception with the setting key, or propagate a typed failure to the provider.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-002 — P1 — Empty catches in FFmpeg staging and cleanup
- Category: correctness
- Location: `lib/core/services/ffmpeg_service.dart:147`
- Evidence: E1 — 5 empty catches at lines 147, 168, 254, 449, 464
- Impact: staging and cleanup failures surface later as unexplained export errors with no trace.
- Fix: log with file path context and surface through `RenderIntegrityException`.
- Scope: requires-source-edit
- Since: AUDIT-20261104-001 (location moved after the command-builder extraction)

### AUDIT-20261108-003 — P1 — 9 empty catches hide RSS failures
- Category: correctness
- Location: `lib/core/services/microstock_news_service.dart:241`
- Evidence: E1 — 9 empty catches at lines 241, 256, 270, 285, 487, 525, 589, 676, 727
- Impact: the news feed can render empty with no diagnostic path.
- Fix: record failing feed URL and error, expose a degraded state to the UI.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-004 — P1 — 6 empty catches hide notification failures
- Category: correctness
- Location: `lib/core/services/notification_service.dart:65`
- Evidence: E1 — 6 empty catches at lines 65, 156, 172, 244, 295, 333
- Impact: permission or delivery failures silently disable completion alerts.
- Fix: log and fall back to the in-app toast path.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-005 — P1 — 5 empty catches can lose the export ledger
- Category: correctness
- Location: `lib/core/services/history_service.dart:62`
- Evidence: E1 — 5 empty catches at lines 62, 67, 99, 136, 156
- Impact: history read/write errors return an empty list, which looks like "no history" instead of a failure.
- Fix: log and mark the store degraded instead of returning empty.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-006 — P1 — Affinity migration swallows decode errors
- Category: correctness
- Location: `lib/core/services/user_interest_service.dart:262`
- Evidence: E1 — `catch (_) {}` wrapping legacy v1 `jsonDecode`
- Impact: corrupt legacy payload discards all accumulated interest weights without notice.
- Fix: catch `FormatException` explicitly, log, and reset deterministically.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-007 — P2 — Filter builder monolith with a call cycle
- Category: quality
- Location: `lib/core/services/filter_builders.dart:323`
- Evidence: E2 — graph: 691 lines, cycle `buildVideoFilter` ↔ `_fallbackVideoFilter`
- Impact: every visual-effect change edits one large file with a recursive fallback path.
- Fix: extract per-effect segments and remove the recursion.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-008 — P2 — 901-line article sheet widget
- Category: quality
- Location: `lib/features/microstock/widgets/microstock_article_sheet.dart:1`
- Evidence: E1 — `wc -l` 901
- Impact: rendering, bookmark state, and share actions are entangled in one widget.
- Fix: split into header, body renderer, and action bar widgets.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-009 — P2 — 791-line news service
- Category: quality
- Location: `lib/core/services/microstock_news_service.dart:1`
- Evidence: E1 — `wc -l` 791; E2 — co-changes with `microstock_news_card.dart`
- Impact: transport, parsing, translation, and caching in one unit.
- Fix: extract transport and parser collaborators.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-010 — P2 — FFmpeg service still 610 lines
- Category: quality
- Location: `lib/core/services/ffmpeg_service.dart:1`
- Evidence: E1 — `wc -l` 610
- Impact: orchestration, staging, probing, and verification remain in one class after the builder extraction.
- Fix: move probe/export/verification into `lib/core/services/ffmpeg/` helpers.
- Scope: requires-source-edit
- Since: AUDIT-20261104-003

### AUDIT-20261108-011 — P2 — 35-parameter `processVideo` and 0.89 coupling
- Category: quality
- Location: `lib/core/services/ffmpeg_service.dart:274`
- Evidence: E1 — signature spans lines 274–311; E2 — co-change score 0.89 with `filter_builders.dart`
- Impact: every filter change touches two large files in lockstep.
- Fix: introduce one immutable `ProcessVideoOptions` value object shared by service and builder.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-012 — P2 — Dead UI surface `MicrostockAiScreen`
- Category: quality
- Location: `lib/features/microstock/screens/microstock_ai_screen.dart:6`
- Evidence: E2 — `search_graph` returns zero inbound and outbound edges; no textual reference in `lib/`
- Impact: unreachable screen adds maintenance cost.
- Fix: confirm with the owner, then delete the screen and its route.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-013 — P2 — 1147-line test file
- Category: quality
- Location: `test/ffmpeg_service_test.dart:1`
- Evidence: E1 — `wc -l` 1147
- Impact: slow targeted runs and unclear failure attribution.
- Fix: split into command-builder, filter, and lifecycle test files.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-014 — P2 — README zero-network claim contradicts the news reader
- Category: documentation
- Location: `README.md:7`
- Evidence: E1 — README "Zero Network Transmission"; E2 — `MicrostockNewsService._fetchDirectRss` calls `https://petapixel.com/feed/` and `https://fstoppers.com/feed`
- Impact: a privacy claim that the code does not honour.
- Fix: scope the claim to video processing and document the news feed network path.
- Scope: doc-only
- Since: new

### AUDIT-20261108-015 — P2 — Android storage path duplicated in 4 files
- Category: safety
- Location: `lib/core/services/ffmpeg/ffmpeg_file_helper.dart:24`
- Evidence: E1 — same literal in `ffmpeg_file_helper.dart:24`, `history_service.dart:52`, `error_screen.dart:191`, `success_screen.dart:169`
- Impact: a storage-policy change requires four coordinated edits.
- Fix: centralize the path in one constants file.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-016 — P3 — Empty catch on locale decode
- Category: quality
- Location: `lib/core/providers/locale_provider.dart:34`
- Evidence: E1 — `catch (_) {}` at line 34
- Impact: corrupt stored locale values fail silently.
- Fix: `debugPrint` the offending value.
- Scope: requires-source-edit
- Since: AUDIT-20261104-006

### AUDIT-20261108-017 — P3 — 3 empty catches in settings service
- Category: quality
- Location: `lib/core/services/settings_service.dart:396`
- Evidence: E1 — lines 396, 416, 420
- Impact: `SharedPreferences` write failures are invisible.
- Fix: log and keep the in-memory value authoritative.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-018 — P3 — 3 empty catches in storage service
- Category: quality
- Location: `lib/core/services/storage_service.dart:49`
- Evidence: E1 — lines 49, 52, 62
- Impact: free-space probe failures fall through to an optimistic default.
- Fix: log and use a conservative estimate.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-019 — P3 — Indonesian comments in notification service
- Category: documentation
- Location: `lib/core/services/notification_service.dart:24`
- Evidence: E1 — `// <-- ID BARU (SUNYI)`, `// <-- ID BARU (BERSUSUARA)`
- Impact: mixed-language comments after the English-only i18n standardization.
- Fix: translate the remaining comments.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261108-020 — P3 — Format gate failing on 7 files
- Category: quality
- Location: `lib/features/process/widgets/modifiers_card.dart:1`
- Evidence: E1 — `dart format --set-exit-if-changed .` exit 1, 7 files changed
- Impact: the format check cannot be used as a CI gate.
- Fix: run `dart format` over `lib/` and `test/` in a whitespace-only commit.
- Scope: requires-source-edit
- Since: new

## Test Coverage Gaps
| Module | Test files | Coverage |
|--------|-----------|----------|
| core/services (ffmpeg, filters) | `ffmpeg_service_test.dart`, `sprint_65_engine_optimization_test.dart`, `unified_effect_preview_test.dart` | not measured this run; report 40 claimed 75.44% at commit `d692bf9` |
| core/services (settings, history, notifications) | `settings_service_test.dart`, `history_service_test.dart`, `notification_service_test.dart`, `hardware_resilience_and_persistence_test.dart` | unit-covered |
| core/providers | `uniquifier_provider_test.dart`, `batch_queue_provider_test.dart`, `locale_provider_test.dart` | unit-covered |
| features/process | `processing_screen_test.dart`, `success_screen_thumbnail_test.dart`, `interactive_preview_slider_test.dart`, `visual_effect_selector_card_test.dart`, `processing_log_viewer_test.dart`, `processing_stage_tracker_test.dart` | widget-covered |
| features/microstock | `microstock_news_and_translation_test.dart` | partial: 1 file for service + widgets + sanitizer |
| features/batch | `batch_processing_screen_test.dart` | widget-covered |
| features/dashboard | none dedicated | **gap** |
| features/history | covered indirectly via `widget_test.dart` | **gap** |
| features/settings | `settings_screen_test.dart`, `setting_toggle_row_test.dart`, `setting_fps_selector_row_test.dart` | widget-covered |

## Documentation Drift
| Claim | Actual | Recommendation |
|-------|--------|----------------|
| `README.md:7` "Zero Network Transmission … zero external telemetry" | `MicrostockNewsService` fetches external RSS over HTTP | Scope the claim to the video pipeline; document the news reader |
| `pubspec.yaml:2` `description: "A new Flutter project."` | Mature v1.0.5 app | Replace with a real description |
| `CHANGELOG.md` `## [Unreleased]` block | v1.0.5 already released at HEAD | Move entries under a `[1.0.5]` heading |

## Prioritized Next Actions
1. Fix the six P1 empty-catch clusters (001–006) — start with `uniquifier_modifiers_mixin.dart`, it holds 27 of 85 occurrences.
2. Repair the format gate (020) with a whitespace-only commit so `git diff -w --exit-code` proves no logic change.
3. Correct the README network claim and the `pubspec.yaml` description (014, drift table).
4. Break the `processVideo` parameter wall with a `ProcessVideoOptions` value object (011), which also relieves the 0.89 coupling.
5. Decompose `filter_builders.dart` and remove the call cycle (007).

Computed: P0=0 P1=6 P2=9 P3=5 (total 20)
