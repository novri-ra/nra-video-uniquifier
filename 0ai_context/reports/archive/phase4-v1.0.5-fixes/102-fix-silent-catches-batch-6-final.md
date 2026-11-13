# Fix Report 102 — Silent Catches, Final Batch (processing screen, history service)

**Date:** 2026-11-08
**Type:** Manual Fix (final silent-catch batch, closes the audit started in report 88)
**Status:** Complete — both files passed their gates, no rollback needed

## 1. Background and Premise Corrections

| File | Scan line | Verified reality |
|------|-----------|------------------|
| `processing_screen.dart` | 125 | empty `catch (_) {}` inside **`_dispatchTelemetryVault()`** — not `_runEngine` |
| `history_service.dart` | 142 | empty `catch (_) {}` inside `isAndroid11OrHigher` — confirmed |

Three corrections:

1. **Wrong enclosing method in `processing_screen.dart`.** The prompt guessed `_runEngine` /
   navigation. `_runEngine` has no empty catch — its `catch (e)` at line 98 already pushes
   `ErrorScreen(errorDetails: e.toString())`. Line 125 is the telemetry side-effect dispatch that
   builds a payload from `provider.selectedFileName`, preset, keywords and tech specs.
2. **Wrong exception surface in `isAndroid11OrHigher`.** The prompt described a `device_info_plus`
   method channel. That plugin is only used by `getAndroidSdkVersion()` (line 150). `isAndroid11OrHigher`
   touches nothing but `dart:io`'s `Platform.operatingSystemVersion` and two regexes plus
   `int.tryParse` — no channel, no path, no user data, so `$e` is safe there.
3. **Two adjacent silent handlers in `history_service.dart`.** Lines 181 and 198 were
   `catch (_) { return true; }` / `catch (_) { return false; }` in `hasStoragePermission()` and
   `requestStoragePermission()`. Report 92's prompt explicitly forbade touching them; this batch's
   adjacent-handler rule brings them in scope, so both were fixed and are itemized below.

## 2. What Was Done

### 2.1 `lib/features/process/screens/processing_screen.dart` — 1 handler

| Line (pre-fix) | Enclosing method | Log message | Value choice |
|----------------|------------------|-------------|--------------|
| 125 | `_dispatchTelemetryVault` | `[ProcessingScreen] telemetry dispatch failed: ${e.runtimeType}` | The payload carries the user's video title, description and keywords; a JSON/HTTP failure can echo them. Type-only. |

### 2.2 `lib/core/services/history_service.dart` — 3 handlers

| Line (pre-fix) | Enclosing method | Log message | Value choice |
|----------------|------------------|-------------|--------------|
| 142 | `isAndroid11OrHigher` | `[HistoryService] android 11 check failed: $e` | `dart:io` string parsing only — no channel, no path, no user data |
| 181 | `hasStoragePermission` (adjacent: `return true` fallback) | `[HistoryService] storage permission check failed: ${e.runtimeType}` | `permission_handler` `PlatformException` may echo the permission name |
| 198 | `requestStoragePermission` (adjacent: `return false` fallback) | `[HistoryService] storage permission request failed: ${e.runtimeType}` | same surface |

Label note: `sdk version probe failed` already exists at line 164 for the `device_info_plus` path, so
line 142 uses `android 11 check failed` (derived from the method name) instead of duplicating the
label and making the two sites indistinguishable in logcat.

### 2.3 Privacy narrowing in the same file

| Line | Before | After | Why |
|------|--------|-------|-----|
| 104 | `'[HistoryService] scan directory failed: $e'` | `'… failed: ${e.runtimeType}'` | `dir.list()` / `entry.stat()` throw `FileSystemException`, whose `toString()` prints `path = '<absolute path>'` — a user export directory |

Line 238 (report 101's P3) was **not** touched: it is not inside `isAndroid11OrHigher`, which is the
prompt's stated condition.

### 2.4 Not changed

- No `rethrow`; no new `try`/`catch`; no control-flow change.
- `isAndroid11OrHigher` still ends with `return true; // Default to true on modern Android`.
- `processing_screen.dart` still navigates to `ErrorScreen` from its own `catch (e)` at line 98; the
  telemetry catch remains fire-and-forget.
- No new API surface: `isDegraded` / `lastErrors` scan = 0 matches.

## 3. Privacy Scan

Pre-existing logs in `processing_screen.dart`: one, at line 74, a static message
(`Invalid or empty input video path.`) with no interpolated value — nothing to narrow.

Pre-existing logs in `history_service.dart`, reviewed one by one:

| Line | Message | Verdict |
|------|---------|---------|
| 63, 70 | external dirs / app docs dir probe | `path_provider` channel errors — channel name only, no path |
| 104 | scan directory failed | **narrowed** (see §2.3) |
| 153, 164 | device info sdk / sdk version probe | SDK integer, no user data |
| 217, 224 | storage intent channel / openAppSettings | `PlatformException` with channel name |
| 238, 264, 274, 322 | basename + `$e` (+ stack trace in two) | **left alone** — 238 is explicitly carved out by this prompt; the other three are the same family and belong in their own prompt (see §5) |
| 339 | device storage probe | `storage_space` plugin error |

## 4. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Format (2 files) | `dart format --output=none --set-exit-if-changed <2 files>` | exit 0, `0 changed` |
| Processing suite | `flutter test test/processing_screen_test.dart` | exit 0, `All tests passed!` (2) |
| History suite | `flutter test test/history_service_test.dart` | exit 0, `All tests passed!` (6) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Repo-wide literal empties | `Get-ChildItem lib -Recurse -Filter *.dart \| Select-String 'catch\s*\(\s*_\s*\)\s*\{\s*\}'` | **0** |
| Empty `catchError` | repo-wide scan | 0 |
| `catch (_) { return …` | repo-wide scan | 0 |
| New API surface | `isDegraded` / `lastErrors` scan | 0 matches |
| Diff scope | `git diff --name-only` | exactly the 2 whitelisted files |
| Diff shape | `git diff --stat` | 2 files, 21 insertions, 5 deletions |
| Deletions audit | `git diff -U0` removed lines | 4 catch headers + the narrowed log line |

## 5. Milestone Note

The empty-catch audit that began in report 88 is **closed**: `lib/` contains zero literal
`catch (_) {}` blocks, down from 85 at mapper time, and zero empty `.catchError` handlers. This batch
fixed the last 2 targets plus 2 adjacent silent fallbacks in `history_service.dart`, and narrowed one
path-bearing log.

What this does **not** mean: 23 `catch (_) <body>` sites remain in `lib/`, and most produce no log —
for example `connectivity_service.dart:37`, `media_scanner_service.dart:18/36`,
`wakelock_service.dart:25/38/48`, `article_reader_extractor.dart:42/89/210`,
`filter_builders.dart:383/435`, `variation_generator.dart:182`, `success_screen.dart:32`,
`ffmpeg_service.dart:271/624`, `notification_service.dart:127/225`,
`microstock_news_service.dart:191/754`, `user_interest_service.dart:79`,
`uniquifier_provider.dart:314`, `history_item_card.dart:150`, `microstock_news_screen.dart:81`. They
are outside the "empty catch" definition this audit used and were never in scope; a follow-up audit
should triage them on the same "failure must be traceable" standard.

Also still open from earlier reports:

- `history_service.dart:238/264/274/322` — basename + `$e` (+ stack trace) in the delete/cleanup path.
- `microstock_news_service.dart` — `cache read failed: $e` echoes cached article JSON.

Recommended next steps: (1) `dart format` gate cleanup for the 7 baseline-unformatted files
(`ffmpeg_service.dart`, `filter_builders.dart`, `notification_service.dart`,
`variation_generator.dart`, `modifiers_card.dart`, and the two test files), then (2) a Mapper run to
regenerate the findings inventory against the now-quieter codebase.
