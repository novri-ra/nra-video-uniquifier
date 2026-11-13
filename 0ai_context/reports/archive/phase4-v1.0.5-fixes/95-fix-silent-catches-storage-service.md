# Fix Report 95 — Silent Catches in StorageService

**Date:** 2026-11-08
**Type:** Manual Fix (AUDIT-20261108-018, P3)
**Status:** Complete, with a correction to the finding's description (§1)

## 1. Background and Finding Correction

HANDOFF §10 / `findings.json` describe `AUDIT-20261108-018` as *"3 empty catch blocks swallow
free-space probe and staged-file cleanup failures"* at `lib/core/services/storage_service.dart:49`.

The staged-file-cleanup half is right, the free-space-probe half is not:

- `hasEnoughSpace` (the free-space probe) **already had a non-empty catch** (line 23) that logs and
  falls back to `true`. Nothing was silent there.
- The three empty catches are: `pruneStaleFiles` per-entry delete (line 49), `pruneStaleFiles` outer
  temp-dir walk (line 52), and `cleanupPartialFile` (line 62).

So this fix logs the three handlers that actually exist, with labels taken from their real enclosing
methods.

## 2. What Was Done

### 2.1 The empty `catch (_) {}` blocks (3 of 3 fixed)

| Line (pre-fix) | Enclosing method | New log message |
|----------------|------------------|-----------------|
| 49 | `pruneStaleFiles` (per-entry stat/length/delete) | `[StorageService] stale file prune failed: ${e.runtimeType}` |
| 52 | `pruneStaleFiles` (outer temp-dir walk) | `[StorageService] temp dir read failed: ${e.runtimeType}` |
| 62 | `cleanupPartialFile` | `[StorageService] partial file cleanup failed: ${e.runtimeType}` |

All three wrap `FileSystemException`-throwing calls (`listSync`, `lastModifiedSync`, `lengthSync`,
`deleteSync`) plus the `getTemporaryDirectory` plugin call. `FileSystemException.toString()` prints
`path = '<absolute path>'`, so following reports 93–94 the handlers log `${e.runtimeType}` only. That
still separates `MissingPluginException` (no path_provider, e.g. in tests) from `FileSystemException`
(real disk failure).

### 2.2 Privacy scan of pre-existing logs (2 sites narrowed)

Case-sensitive scan found exactly two `debugPrint` calls in the file, both in `hasEnoughSpace`:

| Line (pre-fix) | Problem | Change |
|----------------|---------|--------|
| 19–21 | Logged free space **and** the required threshold in MB — a file size, excluded by §14 | Narrowed to the gate result: `Free space check: sufficient|insufficient` (no numbers) |
| 24–26 | Logged `$e` from the `storage_space` plugin | Narrowed to `${e.runtimeType}`; the "Falling back to permissive check" wording is kept |

The task's ponytail rule says not to touch `hasEnoughSpace`; only its two **log statements** were
narrowed. Its body, its `getStorageSpace` call, `minRequiredBytes`, and both returns are untouched
(`return freeBytes >= minRequiredBytes;` and `return true;` verbatim).

### 2.3 Not changed

- No `rethrow`; no new `try`/`catch`; no new branch.
- No new API surface: no `isDegraded`, no `lastErrors` (scan: 0 matches).
- No variable renamed, no helper extracted, no import added.
- Return contracts unchanged: `hasEnoughSpace` still returns `true`/`false` deterministically,
  `pruneStaleFiles` still returns the freed-byte count (0 on failure), `cleanupPartialFile` still
  returns `void` and stays best-effort.

## 3. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Format (file only) | `dart format --output=none --set-exit-if-changed lib/core/services/storage_service.dart` | exit 0, `0 changed` |
| Target test | `flutter test test/ffmpeg_service_test.dart` | exit 0, `All tests passed!` (38 tests) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Silent-handler grep | `catch (_) {}` / `catchError((_) {})` / `catch (_) { return` | 0 matches |
| New API surface | `isDegraded` / `lastErrors` scan | 0 matches |
| Diff scope | `git diff --stat` | 1 file, 18 insertions, 5 deletions |
| Deletions audit | `git diff` removed lines | 5: 3 literal `} catch (_) {}`, 2 pre-existing log lines (§2.2) |

`hasEnoughSpace` is also covered directly by
`test/sprint_65_engine_optimization_test.dart:116` ("returns true in non-Android or standard
environment"), which passed as part of the full suite.

## 4. Note for the Next Mapper Run

The mapper should drop `AUDIT-20261108-018` but **fix its description**: it is a
`pruneStaleFiles` / `cleanupPartialFile` diagnostics fix, not a free-space-probe fix (the probe
already logged). 25 of the original 85 empty catches remain in `lib/`. Remaining clusters:
`translation_service.dart` (3), `article_image_service.dart` (3), then `ffmpeg_file_helper.dart` (2),
`uniquifier_media_mixin.dart` (2), `uniquifier_progress_mixin.dart` (2), `theme_provider.dart` (2),
and single-catch files such as `-016` (`locale_provider.dart`).

Two follow-ups worth registering separately:

1. `dart format` gate: 7 files were already unformatted at baseline (HANDOFF §8) — a dedicated
   formatting commit is still pending.
2. This service is one of three copies of the `staged_` / `thumb_` temp-cache walk
   (`settings_service.dart`, `storage_service.dart`, and `ffmpeg_file_helper.dart`); the duplication
   is a pre-existing P2 (`AUDIT-20261108-015`-adjacent) and was left alone here.
