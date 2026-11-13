# Fix Report 94 — Silent Catches in SettingsService

**Date:** 2026-11-08
**Type:** Manual Fix (AUDIT-20261108-017, P3)
**Status:** Complete, with a correction to the finding's description (§1)

## 1. Background and Finding Correction

HANDOFF §10 / `findings.json` describe `AUDIT-20261108-017` as *"3 empty catch blocks hide
SharedPreferences failures on settings write"* at `lib/core/services/settings_service.dart:396`.

The line number is right, the description is not. Line 396 is inside `getTempCacheSize`, and the
three empty catches in this file are **all in the temp-cache helpers**:

- `getTempCacheSize` — 1 (line 396)
- `purgeTempCache` — 2 (lines 416 per-entry, 420 outer)

The settings setters (`setUpscaleResolution`, `setUpscaleEngine`, `setTargetFps`,
`setAppLanguageCode`, `setThemeMode`, `setCustomOutputPath`, and the rest) contain **no `try`/`catch`
at all**. Their writes can therefore throw to the caller; there is nothing silent to log, and adding
`try`/`catch` to them would be a behaviour change that the ponytail rule ("do not add try/catch
around code that has none") forbids. See §5 for the follow-up finding this deserves.

So this fix logs the three handlers that actually exist, with labels derived from their real
enclosing methods rather than the setter names the prompt suggested.

## 2. What Was Done

| Line (pre-fix) | Enclosing method | New log message |
|----------------|------------------|-----------------|
| 396 | `getTempCacheSize` | `[SettingsService] temp cache size failed: ${e.runtimeType}` |
| 416 | `purgeTempCache` (per-entry delete) | `[SettingsService] temp cache entry purge failed: ${e.runtimeType}` |
| 420 | `purgeTempCache` (outer list/walk) | `[SettingsService] temp cache purge failed: ${e.runtimeType}` |

### 2.1 Why the exception type, not `$e`

All three handlers wrap `FileSystemException`-throwing calls (`listSync`, `lengthSync`,
`deleteSync`) or the `getTemporaryDirectory` plugin call. `FileSystemException.toString()` prints
`path = '<absolute sandbox path>'`, and the task's §14 rule for this file explicitly excludes file
paths from log messages. Following report 93's precedent, the handlers log `${e.runtimeType}`, which
still distinguishes the two failure classes that matter here — `MissingPluginException` (no
path_provider implementation, e.g. in tests) versus `FileSystemException` (real disk failure) —
without echoing the path. One comment on the first site records the reason.

No stored value is logged: not the target resolution label, the upscale engine, the language code,
the theme mode, or the custom output path.

### 2.2 Privacy scan of pre-existing logs

A case-insensitive scan for `print(` initially reported 2 hits at lines 300/302; both are
`getDeepAntiFingerprint(` / `setDeepAntiFingerprint(`, i.e. false positives. Case-sensitive scan for
`debugPrint` / `print(` / `developer.log`: **0 real log calls in this file**. Nothing to narrow.

### 2.3 Not changed

- No `rethrow`; no new `try`/`catch`; no setter touched.
- No new API surface: no `isDegraded`, no `lastErrors` (scan: 0 matches).
- `_getBool`, `_setBool`, the key constants, the notifiers, and the enum `fromString` parsers are
  untouched. (`_getString` / `_setString` named in the task do not exist in this file — only
  `_getBool` / `_setBool`.)
- Return values unchanged: `getTempCacheSize` still returns the partial byte sum (0 when the walk
  fails), `purgeTempCache` still skips an undeletable entry and keeps counting.

## 3. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Format (file only) | `dart format --output=none --set-exit-if-changed lib/core/services/settings_service.dart` | exit 0, `0 changed` |
| Target test | `flutter test test/uniquifier_provider_test.dart` | exit 0, `All tests passed!` (21 tests) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Silent-handler grep | `catch (_) {}` / `catchError((_) {})` / `catch (_) { return` | 0 matches |
| New API surface | `isDegraded` / `lastErrors` scan | 0 matches |
| Diff scope | `git diff --stat` | 1 file, 13 insertions, 3 deletions |
| Deletions audit | `git diff` removed lines | 3, all the literal `} catch (_) {}` lines |

## 4. Note for the Next Mapper Run

The mapper should drop `AUDIT-20261108-017` but **fix its description**: it is a temp-cache
diagnostics fix, not a settings-write fix. 28 of the original 85 empty catches remain in `lib/`.
Next: `-018` (3, `storage_service.dart` — same `staged_`/`thumb_` temp-cache pattern),
`translation_service.dart` (3), `article_image_service.dart` (3), then `-016` (`locale_provider.dart`).

## 5. Recommended New Finding (P3)

`SettingsService` setters have **no error handling**, and the ordering is inconsistent:

- `setUpscaleResolution` (line 182) and `setUpscaleEngine` (line 199) write to prefs **before**
  updating their `ValueNotifier`, so a failed write throws to the caller and leaves the notifier
  stale — the UI keeps showing the old value with no in-memory authority.
- `setVideoCodec` (line 155) and `setHardwareAcceleration` (line 354) update the notifier **first**,
  which is the "in-memory value stays authoritative" behaviour the audit's fix hint asks for.

That is a behaviour change (ordering + error handling) and does not belong in a silent-catch pass.
Suggested fix for a future prompt: notify first in the two inconsistent setters, wrap the write in
`try`/`catch` with `[SettingsService] <setting> save failed: ${e.runtimeType}`, and add a test that a
throwing prefs mock still updates the notifier.
