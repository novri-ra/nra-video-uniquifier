# Fix Report 97 — Silent Catches, Batch 2 (media mixin, progress mixin, theme provider)

**Date:** 2026-11-08
**Type:** Manual Fix (silent-catch cluster, final mixin/provider batch)
**Status:** Complete — all three files passed their gates, no rollback needed

## 1. Background and Premise Corrections

The batch named three files with "~2 empty catches" each. The literal counts were right (2 + 2 + 2 = 6
`catch (_) {}`), and there were no sibling silent handlers on any of these call paths — no
`.catchError((_) {})`, no `catch (_) { return X; }`, no empty body + `finally`. What did not match was
the suggested operation labels:

| Prompt claim | Reality |
|--------------|---------|
| `uniquifier_media_mixin.dart` — `video file probe`, `thumbnail extract`, `preview frame render`, `preview cache cleanup` | Only two handlers exist: `_extractThumbnailAsync` (calls `FfmpegService.extractThumbnail`) and `_probeMediaInfo` (calls `FFprobeKit.getMediaInformation`). There is no preview-frame render and no preview-cache cleanup in this file — those live outside the whitelist. |
| `uniquifier_progress_mixin.dart` — `duration probe`, `progress update`, `render stats persist` | Only two handlers exist, both in the post-render path: `_inspectOutputDiagnosticsAsync` and `_extractOutputThumbnailAsync`. There is no duration probe (`updateRealtimeStatsProgress` has no try/catch), no progress-update catch, and nothing persists render stats to prefs. |
| `theme_provider.dart` — `theme mode load`, `theme mode save` | Exact match. Also verified the exception surface: `SettingsService.getThemeMode` / `setThemeMode` do nothing but `SharedPreferences.getInstance()` + `getString`/`setString`, so the only throwables are `MissingPluginException` / `PlatformException`. `$e` is safe here. |

So the work was the 6 literal empties and nothing adjacent. No premise correction was needed for
`theme_provider.dart`; the two mixin labels were corrected as above.

## 2. What Was Done

### 2.1 `lib/core/providers/uniquifier/uniquifier_media_mixin.dart` — 2 handlers

| Line (pre-fix) | Enclosing method | Log message | Why type-only |
|----------------|------------------|-------------|---------------|
| 65 | `_extractThumbnailAsync` | `[UniquifierMediaMixin] thumbnail extract failed: ${e.runtimeType}` | The call lands in `FfmpegService.extractThumbnail`, which builds an FFmpeg command containing the absolute source path and thumbnail path; FFmpegKit/`PlatformException` messages echo the command. |
| 77 | `_probeMediaInfo` | `[UniquifierMediaMixin] media info probe failed: ${e.runtimeType}` | `FFprobeKit.getMediaInformation` receives the same absolute path; probe errors carry it in the message. |

No import change: `package:flutter/material.dart` already re-exports `foundation`, which provides
`debugPrint` (same precedent as `uniquifier_modifiers_mixin.dart`).

### 2.2 `lib/core/providers/uniquifier/uniquifier_progress_mixin.dart` — 2 handlers

| Line (pre-fix) | Enclosing method | Log message | Why type-only |
|----------------|------------------|-------------|---------------|
| 56 | `_inspectOutputDiagnosticsAsync` | `[UniquifierProgressMixin] output diagnostics probe failed: ${e.runtimeType}` | Delegates to `RenderDiagnosticService.inspectRenderedFile(outputPath)`; the rendered-output path would appear in the exception text. |
| 66 | `_extractOutputThumbnailAsync` | `[UniquifierProgressMixin] output thumbnail extract failed: ${e.runtimeType}` | Same `FfmpegService.extractThumbnail` path as above. |

### 2.3 `lib/core/providers/theme_provider.dart` — 2 handlers

| Line (pre-fix) | Enclosing method | Log message | Why `$e` |
|----------------|------------------|-------------|----------|
| 20 | `_loadSavedThemeMode` | `[ThemeProvider] theme mode load failed: $e` | Only `shared_preferences` is involved; `MissingPluginException` / `PlatformException` carry the method channel name and the preference **key**, never the stored value. |
| 29 | `setThemeMode` | `[ThemeProvider] theme mode save failed: $e` | Same — `prefs.setString` failures do not echo the value being written. |

### 2.4 Not changed

- No `rethrow`; no new `try`/`catch`; no control-flow change.
- No new API surface: `isDegraded` / `lastErrors` scan = 0 matches across the three files.
- `notifyListeners()` ordering untouched: `setThemeMode` still notifies **before** the persistence
  attempt (optimistic UI), `_loadSavedThemeMode` still notifies after the assignment, and both mixins
  still notify only inside their `if (… == path)` guards.
- Return values unchanged: `_extractThumbnailAsync` / `_probeMediaInfo` /
  `_inspectOutputDiagnosticsAsync` / `_extractOutputThumbnailAsync` still `Future<void>`,
  `setThemeMode` still `Future<void>`, and `setThemeMode`'s early `return` when the mode is unchanged
  is untouched.
- Mixin composition (`on ChangeNotifier`), the theme notifier, and `uniquifier_provider.dart`
  untouched.

## 3. Privacy Scan

Case-sensitive scan for `debugPrint(` / `print(` / `developer.log(` **before** the fix: 0 in all three
files — nothing pre-existing to narrow. After the fix there are exactly 6 log calls, and each
interpolates only the operation label plus either `${e.runtimeType}` or `$e` (prefs-only). No path, no
selected-file basename, no preview/output frame path, no file size, no theme value.

## 4. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Format (3 files) | `dart format --output=none --set-exit-if-changed <3 files>` | exit 0, `0 changed` |
| Provider suite | `flutter test test/uniquifier_provider_test.dart` | exit 0, `All tests passed!` (21) |
| Preview suite | `flutter test test/unified_effect_preview_test.dart` | exit 0, `All tests passed!` (17) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Silent-handler grep (3 files) | `catch (_) {}` / `catchError((_) {})` / `catch (_) { return` | 0 matches |
| New API surface | `isDegraded` / `lastErrors` scan | 0 matches |
| Diff scope | `git diff --name-only` | exactly the 3 whitelisted files |
| Diff shape | `git diff --stat` | 3 files, 30 insertions, 6 deletions |
| Deletions audit | `git diff -U0` removed lines | 6, all `} catch (_) {}` |

Empty `catch (_) {}` count in `lib/` is now **11** (was 17 after batch 1, 85 at mapper time).

## 5. Note for the Next Mapper Run

Remaining after this batch: `locale_provider.dart` (`-016`) plus ~10 single-catch files, then the
`dart format` gate cleanup for the 7 baseline-unformatted files.

Follow-up worth registering (P3, outside this whitelist): `FfmpegService.extractThumbnail`
(`lib/core/services/ffmpeg_service.dart:148`) logs
`'[FfmpegService] thumbnail failed for $inputPath: $e'` — a pre-existing absolute-path leak. The two
mixin handlers fixed here are the *callers* of that method, so even with type-only logging the path
still reaches logcat from inside `FfmpegService`. Fixing it means editing that file, which this
prompt's whitelist forbids.
