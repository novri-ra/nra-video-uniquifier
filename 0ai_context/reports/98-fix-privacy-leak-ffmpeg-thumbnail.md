# Fix Report 98 — Privacy Leak, `FfmpegService.extractThumbnail` Log

**Date:** 2026-11-08
**Type:** Manual Fix (privacy leak, P3 from report 97 §5)
**Status:** Complete — single-line change, all gates green

## 1. Premise Check

Report 97 §5 said `lib/core/services/ffmpeg_service.dart:148` logs
`'[FfmpegService] thumbnail failed for $inputPath: $e'`. Confirmed exactly as described:

```dart
    } catch (e) {
      debugPrint('[FfmpegService] thumbnail failed for $inputPath: $e');
    }
    return null;
```

- The catch header is `catch (e)` and the catch body was already logging (no silent handler here) —
  the shape from report 89 is correct, only the message was wrong.
- `return null` sits after the `catch`, not inside it; it is unchanged.
- No basename was computed earlier in `extractThumbnail` (lines 133–146 build `inputFile`,
  `tempDir`, `thumbPath`, `cmd`, `session`), so the basename is derived inline rather than reused.

## 2. What Was Done

One statement replaced:

```dart
      debugPrint(
        '[FfmpegService] thumbnail failed for '
        "${inputPath.split(RegExp(r'[/\\]')).last}: ${e.runtimeType}",
      );
```

- **Idiom:** `RegExp(r'[/\\]')`, the precedent from reports 92 and 97. Not `Platform.pathSeparator`,
  which yields mixed-separator partial paths on Windows.
- **Why the type-only half matters:** `cmd` at line 141 embeds both the escaped input path and the
  thumbnail path, and `PlatformException.toString()` on Android echoes the FFmpeg command. So
  dropping `$inputPath` alone would not have closed the leak — `${e.runtimeType}` is required.
- **Quote style:** the formatter prefers a double-quoted second literal here because it contains
  single quotes; verified with `dart format --output=show`, which reproduces exactly this shape.
- **Diff shape:** `4 insertions(+), 1 deletion(-)` rather than the 1/1 the prompt anticipated. The
  replacement is one statement, but a single 130-character line would violate the formatter's width,
  so it wraps onto three lines. The wrapped form is what `dart format` emits, so this change adds no
  new format churn. `ffmpeg_service.dart` remains one of the 7 baseline-unformatted files, but the
  edited region is format-clean.

## 3. Basename Output Check

`dart` probe with the same expression:

| Input | Logged basename |
|-------|-----------------|
| `C:\Users\Administrator\Videos\clip.mp4` | `clip.mp4` |
| `/storage/emulated/0/Movies/Uniquifier/clip.mp4` | `clip.mp4` |
| `clip.mp4` | `clip.mp4` |
| `C:\Users\Administrator\Saved Games\_Project\my.video.mkv` | `my.video.mkv` |

No `Temp/...` partial path, no mixed separators, no leading separator, multi-dot names intact.

## 4. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| FFmpeg suite | `flutter test test/ffmpeg_service_test.dart` | exit 0, `All tests passed!` (38) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Old pattern gone | `Select-String 'thumbnail failed for \$inputPath'` | 0 matches |
| Diff scope | `git diff --name-only` | exactly `lib/core/services/ffmpeg_service.dart` |
| Diff content | `git diff -- lib/core/services/ffmpeg_service.dart` | only the log statement; no catch header, no `return null`, no other `debugPrint` |
| Diff size | `git diff --stat` | `1 file changed, 4 insertions(+), 1 deletion(-)` |

## 5. Note for the Next Mapper Run

The log now carries a filename (basename) plus `${e.runtimeType}`. This prompt explicitly authorizes
the basename, and it matches the normalization precedent of reports 92/95. If §14 is later read
strictly as "no user file identifiers at all", the stricter variant is
`'[FfmpegService] thumbnail failed: ${e.runtimeType}'` — one deletion, no structural change.

Remaining work unchanged: `locale_provider.dart` (`-016`) plus ~10 single-catch files, then the
`dart format` gate cleanup for the 7 baseline files.
