# Fix Report 89 — Silent Catches in FfmpegService

**Date:** 2026-11-08
**Type:** Manual Fix (AUDIT-20261108-002, P1)
**Status:** Complete

## 1. Background

HANDOFF §10 finding `AUDIT-20261108-002` reported 5 empty `catch (_) {}` blocks in
`lib/core/services/ffmpeg_service.dart` (first recorded as `AUDIT-20261104-001`). They sat on the
input-staging path, the thumbnail extractor, the preview-session cancel, and two cleanup paths, so
any filesystem or FFmpegKit failure there was discarded without a trace.

## 2. What Was Done

Five empty catches replaced with `debugPrint`. Nothing else changed.

| Line (pre-fix) | Enclosing method | New log message |
|----------------|------------------|-----------------|
| 147 | `extractThumbnail` | `[FfmpegService] thumbnail failed for $inputPath: $e` |
| 168 | `renderFilteredPreviewFrame` (cancel previous session) | `[FfmpegService] preview cancel failed: $e` |
| 254 | `_cleanupOldPreviews` (delete stale `preview_*.jpg`) | `[FfmpegService] delete old preview failed for ${entity.path}: $e` |
| 449 | `_cleanupAfterProcess` (delete staged input) | `[FfmpegService] delete staged file failed for ${meta.stagedFile?.path}: $e` |
| 464 | `_resolveInputMeta` (`stageInputFile`) | `[FfmpegService] stage input failed for $inputPath: $e` |

- Prefix is uniform: `[FfmpegService]`, matching the tag already used by `cancel()` and
  `renderFilteredPreviewFrame`'s outer catch in the same file.
- Paths appear only where a path was already in scope (`inputPath`, `entity.path`,
  `meta.stagedFile`). No variable was introduced to capture one.
- `package:flutter/foundation.dart` was already imported at line 7, so no import change.
- **No `rethrow` and no `throw RenderIntegrityException` was added.** Confirmed in the diff: the
  five hunks only replace the catch header and add a `debugPrint`.

### Why no exception propagation

The audit's suggested fix ("surface via `RenderIntegrityException`") is not safe at these sites:

- `_resolveInputMeta` intentionally falls back to `inputPath` when staging fails
  (`stagedFile?.path ?? inputPath`). Throwing would turn a recoverable cache-copy failure into a
  hard export failure.
- `_cleanupAfterProcess` runs inside the `finally` block of `processVideo`. A throw there would
  replace the real export result with a cleanup error and break the "cleanup never fails the job"
  invariant.
- `extractThumbnail` is declared `Future<String?>` and callers treat `null` as "no thumbnail".
- `_cleanupOldPreviews` is a best-effort cache purge by design.

User-visible staging diagnostics are therefore a **separate** concern and are not covered by this
report.

## 3. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Target test | `flutter test test/ffmpeg_service_test.dart` | exit 0, `All tests passed!` (38 tests) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Empty catches remaining | `Select-String 'catch\s*\(_\)\s*\{\s*\}'` | 0 matches |
| Diff scope | `git diff --stat` | 1 file, 21 insertions, 5 deletions |
| Deletions audit | `git diff` removed lines | 5, all of them the literal `} catch (_) {}` lines |

## 4. Behavior Note

`_resolveInputMeta` still falls back to `inputPath` on staging failure, and `_cleanupAfterProcess`
still swallows cleanup errors inside `finally` — only the logging changed.

## 5. Note for the Next Mapper Run

The mapper should detect this report and drop `AUDIT-20261108-002` from the findings inventory.
58 of the original 85 empty catches remain, in other files (`-003` news service, `-004`
notification service, `-005` history service, `-006` user interest, `-016` locale, `-017`
settings, `-018` storage).
