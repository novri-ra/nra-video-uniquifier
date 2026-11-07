# Fix Report 92 — Silent Catches in HistoryService

**Date:** 2026-11-08
**Type:** Manual Fix (AUDIT-20261108-005, P1)
**Status:** Complete (1 catch deliberately excluded, see §2.3)

## 1. Background

HANDOFF §10 finding `AUDIT-20261108-005` reported 5 empty `catch (_) {}` blocks in
`lib/core/services/history_service.dart`. They covered the target-directory probes, the directory
listing in `scanDirectory`, the SDK-version fallback, and the device-storage probe. A user whose
export ledger came back empty had no way to tell "no exports yet" from "the directory probe threw".

## 2. What Was Done

### 2.1 The empty `catch (_) {}` blocks (4 of 5 fixed)

| Line (pre-fix) | Enclosing method | New log message |
|----------------|------------------|-----------------|
| 62 | `getTargetDirectories` (external storage dirs) | `[HistoryService] external dirs probe failed: $e` |
| 67 | `getTargetDirectories` (app documents dir) | `[HistoryService] app docs dir probe failed: $e` |
| 99 | `scanDirectory` (directory listing) | `[HistoryService] scan directory failed: $e` |
| 156 | `getAndroidSdkVersion` (inner regex fallback) | `[HistoryService] sdk version probe failed: $innerError` |

### 2.2 Other silent handlers on the same call path (2 fixed)

Per the lesson from report 91, the literal pattern is not the whole story:

| Line (pre-fix) | Site | New log message |
|----------------|------|-----------------|
| 146 | `getAndroidSdkVersion` outer catch (swallowed the `device_info_plus` failure, then fell back to regex) | `[HistoryService] device info sdk probe failed: $e` |
| 312 | `getDeviceStorage` (`catch (_) { return null; }`) | `[HistoryService] device storage probe failed: $e` |

The outer SDK catch matters: it is the handler that actually fires when `device_info_plus` is
unavailable, so logging only the inner regex catch (which is near-unreachable) would have produced
a log line that never appears in practice. The inner catch variable was named `innerError` to avoid
shadowing the outer `e`; the body is otherwise untouched.

`MediaStore sync` needed no separate handler: `MediaScannerService.scanFile` is called inside the
existing `try` blocks of `deleteItem` / `deleteExportItemsDetailed`, so a scan failure already
surfaces through those catches. No new `try`/`catch` was added anywhere.

### 2.3 Deliberately not changed

| Line | Site | Reason |
|------|------|--------|
| 142 | `isAndroid11OrHigher` (`catch (_) {}`) | Explicitly excluded by the task ("do not touch `isAndroid11OrHigher`"). Its `return true` safe default is unchanged. |
| 181 | `hasStoragePermission` (`catch (_) { return true; }`) | Storage-permission helper — explicitly excluded by the task. |
| 198 | `requestStoragePermission` (`catch (_) { return false; }`) | Storage-permission helper — explicitly excluded by the task. |

Consequence: the `grep -nE 'catch \(_\) \{\}|...'` gate returns **1 match (line 142)**, not 0. That is
the excluded getter, not a missed site. The three exclusions are the only remaining silent handlers
in the file; see §5 for the follow-up prompt suggestion.

### 2.4 Privacy normalisation of the pre-existing delete logs (5 sites)

Five handlers already logged, but interpolated the **full** file path. The task's privacy rule
(basename only, never `originalPath` / `outputPath`) is violated by those messages, so they were
narrowed to the basename:

| Line (pre-fix) | Site | Change |
|----------------|------|--------|
| 230 | `_cleanupThumbnail` | `Thumbnail cleanup skipped for <full path>` → `<basename>` |
| 243 | `deleteItem` (physical delete failed) | full path → basename |
| 254 | `deleteItem` (catch) | full path → basename; stack trace kept |
| 292 | `deleteExportItemsDetailed` (physical delete failed) | full path → basename |
| 300 | `deleteExportItemsDetailed` (catch) | full path → basename; prefix normalised from bare `Failed to delete file:` to `[HistoryService] Failed to delete file <basename>: $e` |

Basename is computed with the idiom already used twice in this file
(`path.split(RegExp(r'[/\\]')).last`, lines 84 and 231) rather than
`split(Platform.pathSeparator)`. The first attempt used `Platform.pathSeparator`; the target test
output showed `Temp/uniquifier_delete_test.tmp` (mixed `/` and `\` on Windows), which is a partial
path, not a basename. The `RegExp` variant yields a clean `batch_del_1.tmp`, confirmed by the test
run in §3.

### 2.5 Not changed

- No `rethrow` anywhere. Return values are identical: `null` (`getDeviceStorage`), `false`
  (`deleteItem`), `[]` (`scanDirectory`), `30` (`getAndroidSdkVersion`), `dirs` / `results` as before.
- No new API surface: no `isDegraded` getter, no `lastErrors` field (scan: 0 matches).
- `formatTotalSize`, `formatFileSize`, `isAndroid11OrHigher`, `hasStoragePermission`,
  `requestStoragePermission`, `VideoExportItem`, and the `_storageChannel` constant are untouched.

## 3. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Target test | `flutter test test/history_service_test.dart` | exit 0, `All tests passed!` (6 tests) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Silent-handler grep | `catch (_) {}` / `catchError((_) {})` / `catch (_) { return` | 1 match — line 142, `isAndroid11OrHigher`, excluded by constraint (§2.3) |
| New API surface | `isDegraded` / `lastErrors` scan | 0 matches |
| Diff scope | `git diff --stat` | 1 file, 28 insertions, 11 deletions |
| Deletions audit | `git diff` removed lines | 11: 4 literal `} catch (_) {}`, 2 `} catch (_) {` headers, 5 full-path log lines |

The target suite exercises `scanDirectory`, `deleteItem` (present and missing file), `deleteItems`,
and `deleteExportItems`, and it passed unchanged, so delete semantics are identical. Its output now
shows `[HistoryService] Thumbnail cleanup skipped for batch_del_1.tmp: MissingPluginException(...)`
— the intended new diagnostic, with a basename only.

## 4. Note for the Next Mapper Run

The mapper should detect this report and drop `AUDIT-20261108-005` from the findings inventory, with
the caveat that `isAndroid11OrHigher` (line 142) still has an empty catch by explicit instruction.
34 of the original 85 empty catches remain in `lib/` (verified by pattern scan after this fix).
Next clusters by size: `-017` (3, `settings_service.dart`), `-018` (3, `storage_service.dart`),
`-006` (3, `user_interest_service.dart`), `translation_service.dart` (3),
`article_image_service.dart` (3), then single-catch files such as `-016` (`locale_provider.dart`).

Two P3 follow-ups worth registering separately:

1. `isAndroid11OrHigher` still swallows its parse failure and defaults to `true`; it needs its own
   prompt, since this one forbade touching it.
2. `history_service.dart` has no user-visible degraded signal — a failed directory probe looks
   exactly like an empty ledger on `RecentHistoryScreen`. Behaviour change, out of scope here.
