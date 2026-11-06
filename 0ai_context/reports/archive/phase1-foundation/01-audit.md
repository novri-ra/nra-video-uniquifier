# Project Audit — Report 01

## Summary
- Revision: `c1db18f1261bacb0580d8319cdc47413c9598e12`
- Stack: dart, flutter
- Deterministic: analyze=0, test=173/173 passed, format=0 files changed
- Findings: P0=0, P1=2, P2=3, P3=1
- Graph checks: run

## Deterministic Checks
| Check | Command | Result | Evidence |
|-------|---------|--------|----------|
| Analyze | `dart analyze` | exit 0, 0 issues found | raw/health/analyze.log |
| Test | `flutter test` | 173/173 passed | raw/health/test.log |
| Format | `dart format --set-exit-if-changed .` | 0 files changed | raw/health/format.log |

## Findings

### AUDIT-20261104-001 — P1 — Empty catch in FfmpegService
- Category: correctness
- Location: `lib/core/services/ffmpeg_service.dart:227`
- Evidence: E1 — `git grep 'catch\s*([_a-zA-Z0-9]*)\s*\{\s*\}'`
- Impact: Empty catch block suppresses underlying execution or filesystem errors without telemetry or logging.
- Fix: Add error logging or structured failure propagation to error handler.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-002 — P1 — Silent provider error suppression
- Category: correctness
- Location: `lib/core/providers/uniquifier_provider.dart:97`
- Evidence: E1 — `git grep 'catch\s*([_a-zA-Z0-9]*)\s*\{\s*\}'`
- Impact: Empty catch block silently ignores provider initialization failures.
- Fix: Log caught exception or set an error state on provider.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-003 — P2 — Large FFmpeg service file
- Category: quality
- Location: `lib/core/services/ffmpeg_service.dart:1`
- Evidence: E1 — `git ls-files` LOC scan (699 lines)
- Impact: Large service file exceeding 600 lines creates maintainability and cognitive overhead.
- Fix: Refactor FFmpeg command builders and execution runners into modular helper classes.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-004 — P2 — Over-scoped UniquifierProvider
- Category: quality
- Location: `lib/core/providers/uniquifier_provider.dart:1`
- Evidence: E1 — `git ls-files` LOC scan (605 lines)
- Impact: God-object provider exceeding 600 lines manages excessive state responsibilities.
- Fix: Split processing workflow state from general configuration state.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-005 — P2 — Over-scoped SuccessScreen
- Category: quality
- Location: `lib/features/process/screens/success_screen.dart:1`
- Evidence: E1 — `git ls-files` LOC scan (502 lines)
- Impact: UI screen exceeding 500 lines mixes layout composition with action handlers.
- Fix: Decompose into smaller reusable presentation widgets.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-006 — P3 — Swallowed exception in locale provider
- Category: quality
- Location: `lib/core/providers/locale_provider.dart:22`
- Evidence: E1 — `git grep` catch pattern
- Impact: Swallowed exception when reading stored locale fallback defaults.
- Fix: Add debugPrint or fallback telemetry for invalid locale decoding.
- Scope: requires-source-edit
- Since: new

## Test Coverage Gaps
| Module | Test files | Coverage |
|--------|------------|----------|
| `core/providers` | 4 test files | High (uniquifier, batch_queue, locale, theme) |
| `core/services` | 7 test files | High (ffmpeg, hardware, history, ai, notification, news, settings) |
| `features/process` | 4 test files | High (smoke tests, stages, log viewer) |
| `features/settings` | 3 test files | High (settings screen, toggle rows, fps selector) |

## Documentation Drift
| Claim | Actual | Recommendation |
|-------|--------|----------------|
| None | All documentation matches current implementation | N/A |

## Prioritized Next Actions
1. Fix P1 empty catch handlers in `FfmpegService` and `UniquifierProvider` to log diagnostic traces.
2. Refactor P2 god-files (`FfmpegService`, `UniquifierProvider`) into focused sub-components.
3. Clean up P3 ignored locale exception handling.

Computed: P0=0 P1=2 P2=3 P3=1 (total 6)
