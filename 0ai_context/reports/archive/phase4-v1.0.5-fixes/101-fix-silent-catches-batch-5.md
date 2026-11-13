# Fix Report 101 — Silent Catches, Batch 5 (history screen, bookmark service, article sheet)

**Date:** 2026-11-08
**Type:** Manual Fix (silent-catch remediation, batch 5)
**Status:** Complete — all three files passed their gates, no rollback needed

## 1. Background and Premise Corrections

| File | Scan line | Verified reality |
|------|-----------|------------------|
| `recent_history_screen.dart` | 63 | empty `catch (_) {}` inside `_verifyStoragePermissionOnResume()` — wraps `Permission.manageExternalStorage.isGranted` |
| `user_news_bookmark_service.dart` | 55 | empty `catch (_) {}` inside **`toggleBookmark()`** (save path) |
| `microstock_article_sheet.dart` | 250 | empty `catch (_) {}` inside `_launchUrl()` — wraps `launchUrl(uri, externalApplication)` |

Two corrections:

1. **Bookmark catch is on the save path, not the load path.** The prompt described it as
   `initialize()` / `_loadBookmarks` reading prefs. `initialize()` has its own catch (line 25, see
   below); the literal empty catch at 55 is the `setStringList` persistence half of
   `toggleBookmark`. Same shape as the `-016` correction in report 100. `$e` is still safe there —
   the exception carries the key name, never the bookmark value.
2. **Three adjacent silent handlers existed**, one per file, that the scan did not list. Each had a
   non-empty but log-free body (a comment only, a fallback assignment, or a UI reset). Per the
   report 91/96 rule ("every handler that produces no log"), all three were fixed and are itemized
   below as adjacent sites.

Sibling scan for `.catchError((_) {})` / `catch (_) { return X; }`: none in any of the three files.

## 2. What Was Done

### 2.1 `lib/features/history/screens/recent_history_screen.dart` — 2 handlers

| Line (pre-fix) | Enclosing method | Log message | Value choice |
|----------------|------------------|-------------|--------------|
| 63 | `_verifyStoragePermissionOnResume` (target) | `[RecentHistoryScreen] storage permission check failed: ${e.runtimeType}` | `permission_handler` `PlatformException` may echo the permission name |
| 80 | `_checkStoragePermissionOnMount` (adjacent: comment-only body) | `[RecentHistoryScreen] storage permission prompt failed: $e` | `SharedPreferences.getInstance()` + `getBool`/`setBool` only — channel + key, no value |

### 2.2 `lib/features/microstock/services/user_news_bookmark_service.dart` — 2 handlers

| Line (pre-fix) | Enclosing method | Log message | Value choice |
|----------------|------------------|-------------|--------------|
| 25 | `initialize` (adjacent: `_initialized = true` fallback) | `[UserNewsBookmarkService] bookmark init failed: $e` | prefs read only |
| 55 | `toggleBookmark` (target) | `[UserNewsBookmarkService] bookmark save failed: $e` | prefs write only — carries key, not the ID list |

### 2.3 `lib/features/microstock/widgets/microstock_article_sheet.dart` — 2 handlers

| Line (pre-fix) | Enclosing method | Log message | Value choice |
|----------------|------------------|-------------|--------------|
| 189 | `_toggleTranslation` (adjacent: `setState` reset only) | `[MicrostockArticleSheet] translation toggle failed: ${e.runtimeType}` | translation failures echo article text in the request URI / JSON |
| 250 | `_launchUrl` (target) | `[MicrostockArticleSheet] launch url failed: ${e.runtimeType}` | `url_launcher` `PlatformException` echoes the publisher URI, including tracking query strings |

### 2.4 Not changed

- No `rethrow`; no new `try`/`catch`; no control-flow change.
- No new API surface: `isDegraded` / `lastErrors` scan = 0 matches.
- Fallbacks intact: history still renders its empty/error state (`_items` unchanged on failure),
  bookmarks still fall back to the in-memory set, and a failed URL launch stays silent to the user.
- The 901-line `microstock_article_sheet.dart` layout was not touched — only the two catch bodies.
  `AUDIT-20261108-008` (P2) remains open.
- `setState` calls, `mounted` guards, and `notifyListeners`/`ValueNotifier` ordering untouched.

## 3. Privacy Scan

Case-sensitive scan for `debugPrint(` / `print(` / `developer.log(` **before** the fix: 0 in all
three files. Nothing to narrow.

`recent_history_screen.dart` does pass `$e` into user-facing `AppToast` messages (delete/share/open
errors). Those are UI toasts, not log messages, and changing them would alter visible behaviour, so
they were left alone — outside the scope of §14's log constraint.

## 4. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Format (3 files) | `dart format --output=none --set-exit-if-changed <3 files>` | exit 0, `0 changed` (one wrap corrected after the first run flagged it) |
| History suite | `flutter test test/history_service_test.dart` | exit 0, `All tests passed!` (6) |
| Microstock suite | `flutter test test/microstock_news_and_translation_test.dart` | exit 0, `All tests passed!` (18) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Silent-handler grep (3 files) | `catch (_) {}` / `catchError((_) {})` / `catch (_) { return` | 0 matches |
| New API surface | `isDegraded` / `lastErrors` scan | 0 matches |
| Diff scope | `git diff --name-only` | exactly the 3 whitelisted files |
| Diff shape | `git diff --stat` | 3 files, 26 insertions, 6 deletions |
| Deletions audit | `git diff -U0` removed lines | 6 catch headers only |

## 5. Note for the Next Mapper Run

Two empty catches remain in `lib/`:

| File | Line | Note |
|------|------|------|
| `lib/features/process/screens/processing_screen.dart` | 125 | not covered by batch 5 — needs its own prompt |
| `lib/core/services/history_service.dart` | 142 | `isAndroid11OrHigher`, left by explicit instruction |

Then the `dart format` gate cleanup for the 7 baseline-unformatted files.

Follow-up worth registering (P3, outside this whitelist): `history_service.dart:237` logs
`'[HistoryService] Thumbnail cleanup skipped for ' '${videoFile.path.split(RegExp(r'[/\\]')).last}: $e'`
— the basename of a user export plus the raw exception. Visible in the history suite output today.
The basename half matches the sanctioned pattern, but `$e` still echoes the plugin failure verbatim;
that file is excluded from this batch.
