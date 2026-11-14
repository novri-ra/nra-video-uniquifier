# Report 134 — Silent Catch Batch 1 (Pipeline + User-Visible)

**Date:** 2026-11-14
**Status:** Done — batch 1 of AUDIT-20261108-020; suite green
**Finding:** AUDIT-20261108-020 (semantic silent catches)
**Base commit:** `026c196 docs(context): synchronize mapper files with software encoding and LUT architecture`

---

## 1. Preflight

Codebase-memory MCP checks (mandatory preflight):

| Check | Result |
|---|---|
| `index_status` | `ready` |
| Nodes / edges | 2908 / 7070 |
| `indexed_at` | `2026-11-13T14:31:12Z` |
| Watch state | disabled (`not_session_project`) |
| `parse_partial` | 6 files |
| `not_indexed` | 103 files |
| `doc_links` | 584 mentions, status `ok` |

`search_graph` with the mandated OR query returned 0 results (BM25 candidate
window saturated), so all catch sites were re-scanned locally with a
brace-aware Python pass over the three priority files.

Line numbers below are post-edit (the 045 constant and imports shifted the
earlier audit offsets by a few lines).

---

## 2. Scope

Batch 1 covers only pipeline-critical and user-visible catches in:

- `lib/core/services/filter_builders.dart`
- `lib/core/providers/uniquifier_provider.dart`
- `lib/features/process/screens/success_screen.dart`

Low-risk best-effort probes (`wakelock_service`, `media_scanner_service`,
`connectivity_service`, microstock/history UI) were deliberately left for a
later batch.

---

## 3. Changes

| File:line | Before | After |
|---|---|---|
| `filter_builders.dart:414` | `catch (_)` → silent video fallback | `catch (e)` + `debugPrint('[FilterBuilders] Video filtergraph build failed; using fallback: $e')` |
| `filter_builders.dart:469` | `catch (_)` → silent audio fallback | `catch (e)` + `debugPrint('[FilterBuilders] Audio filtergraph build failed; using fallback: $e')` |
| `uniquifier_provider.dart:335` | `catch (_)` → preview flag reset, no log | `catch (e)` + `debugPrint('[UniquifierProvider] Preview frame render failed: $e')` |
| `success_screen.dart:32` | `catch (_)` → `0x0000..0000 (ERROR)` with no log | `catch (e)` + `debugPrint('[SuccessScreen] SHA-256 computation failed: $e')` |
| `success_screen.dart:124` | `catch (e)` + snackbar, no log | added `debugPrint('[SuccessScreen] Share video failed: $e')` |
| `success_screen.dart:150` | `catch (e)` + snackbar, no log | added `debugPrint('[SuccessScreen] Open video failed: $e')` |

`filter_builders.dart` gained `import 'package:flutter/foundation.dart';` for
`debugPrint`. All fallback/return values, UI snackbars, and preview-state resets
are unchanged; only diagnostics were added.

The two success-screen share/open catches already informed the user through a
SnackBar, but they were still classified as silent by the audit because nothing
reached the log. They are now both user-visible and diagnosable.

No catch was converted to `rethrow`: every site is a best-effort path whose
existing fallback is intentional.

---

## 4. Verification

| Command | Result |
|---|---|
| `dart analyze --fatal-infos` | exit 0, no issues |
| `flutter test` | 240/240 passed |
| `dart format --output=none --set-exit-if-changed lib test` | 0 changed |
| Brace-aware scan of the three files | 0 silent / 0 empty catches remain in scope |

### Silent-catch count after batch 1

| Class | Before | After |
|---|---|---|
| Total catch handlers | 156 | 156 |
| `LOGS` | 123 | 129 |
| `SILENT` | 30 | 24 |
| `THROWS` | 2 | 2 |
| `EMPTY` | 1 | 1 |

Remaining 24 silent catches (next-batch candidates):

```
lib/core/providers/batch_queue_provider.dart:126
lib/core/services/connectivity_service.dart:37
lib/core/services/media_scanner_service.dart:18
lib/core/services/media_scanner_service.dart:36
lib/core/services/microstock_news_service.dart:191
lib/core/services/microstock_news_service.dart:770
lib/core/services/notification_service.dart:127
lib/core/services/user_interest_service.dart:79
lib/core/services/wakelock_service.dart:25
lib/core/services/wakelock_service.dart:38
lib/core/services/wakelock_service.dart:48
lib/core/utils/variation_generator.dart:182
lib/features/history/screens/recent_history_screen.dart:215
lib/features/history/screens/recent_history_screen.dart:333
lib/features/history/screens/recent_history_screen.dart:403
lib/features/history/screens/recent_history_screen.dart:419
lib/features/history/screens/recent_history_screen.dart:440
lib/features/microstock/screens/microstock_news_screen.dart:81
lib/features/microstock/services/article_reader_extractor.dart:42
lib/features/microstock/services/article_reader_extractor.dart:89
lib/features/microstock/services/article_reader_extractor.dart:210
lib/features/microstock/widgets/microstock_news_card.dart:64
lib/features/process/screens/processing_screen.dart:98
lib/features/process/screens/process_screen.dart:46
```

The single `EMPTY` handler remains at
`lib/core/services/ffmpeg_service.dart:278`; it is outside this batch's file
whitelist.

No tests were added or changed because the observable behaviour is identical;
the added logging is diagnostics-only.

---

## 5. Residual risk

- Logs use raw `$e`, which may include an absolute path for filesystem/share
  failures. These are debug-only `debugPrint` calls, but a later privacy pass
  could apply `redactFileSystemPaths` if logcat exposure is a concern.
- The `filter_builders` fallbacks are defensive: normal builds should never
  throw. The new logs will make any unexpected throw visible instead of silently
  swapping in the fallback graph.
- The raw `$e` message from FFmpeg/SHA-256 may be multi-line; `debugPrint`
  throttling handles this, but log volume during repeated preview failures is
  higher than before.
