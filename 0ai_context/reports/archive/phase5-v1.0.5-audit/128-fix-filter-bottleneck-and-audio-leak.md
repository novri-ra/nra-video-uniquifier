# Report 128 — Filter Thread Bottleneck, Audio Leak, Export Timeout

**Date:** 2026-11-14
**Status:** Done — stall causes removed; suite green
**Base commit:** `fbeb09f fix(audit): chunk ffmpeg log to prevent logcat truncation`

---

## 1. Preflight

- `git status --short` → clean
- `git log --oneline -1` → `fbeb09f`

Path note: the whitelist listed `lib/core/services/ffmpeg/filter_builders.dart`,
which does not exist. The real file is `lib/core/services/filter_builders.dart`
(`FfmpegCommandBuilder` imports it as `../filter_builders.dart`). That is the
file modified.

---

## 2. Root causes addressed

### 2.1 `-filter_threads 1` starved the encoder

`writeInputOptions` was followed by a stability block that forced the entire
filtergraph onto a single thread:

```
-filter_threads 1 -filter_complex_threads 1 -max_muxing_queue_size 4096
```

With a 2K background-blur chain (`split` → `boxblur` → `overlay` → `hqdn3d` →
`unsharp` → `noise`), one filter thread cannot feed libx264 fast enough. The
muxer's video queue (`out_0_0`) then hits its soft limit and FFmpeg prints
`100 buffers queued in out_0_0` — exactly the observed symptom.

### 2.2 The audio graph generated 2 hours of noise per render

Both audio paths built the dither/subliminal layer with hardcoded 2-hour sources:

```
anoisesrc=d=7200:c=pink:a=0.003[noise]
aevalsrc=exprs=...:d=7200:s=44100[subliminal]
```

`7200 s = 2 h` of 44.1 kHz stereo samples per render (4 such literals across the
aggressive + deep-evasion branches). For a 21-second clip that is ~340× more
audio than needed and a large transient memory cost on top of the video filters.

### 2.3 Export could hang at 99% ("Syncing to gallery")

`_executeAndExport` awaited `FfmpegFileHelper.exportStagedFile(...)` with no
bound. On scoped-storage devices `File.copy` into the gallery target can block
indefinitely, leaving the UI pinned at 99%.

Secondary bug found while fixing it: the helper itself returns the **staged**
path when its own fallback fails, yet `_executeAndExport` then unconditionally
called `deletePartialFile(stagedOutputPath)` — i.e. it could delete the only
remaining render and return a path to a deleted file.

---

## 3. Changes

### 3.1 `lib/core/services/ffmpeg/ffmpeg_command_builder.dart`

```dart
// Stability priority: keep a generous muxing queue so heavy 2K / Blur
// chains cannot overflow, but leave filter threading at FFmpeg's default.
// Sequential filter threading starved the encoder on heavy graphs and
// surfaced as "100 buffers queued in out_0_0".
buffer.write(' -max_muxing_queue_size 4096');
```

`-filter_threads` / `-filter_complex_threads` are gone (0 hits for both);
FFmpeg now uses its default filter worker pool, while the muxing queue stays
generous.

### 3.2 `lib/core/services/filter_builders.dart`

`d=7200` → `d=60` in all four literals (aggressive audio and deep-evasion
branches, each with `anoisesrc` + `aevalsrc`). `amix=duration=first` still
takes the real audio length from `[a0]`, so the dither/subliminal bed only needs
to be at least as long as the clip; 60 s keeps normal short-form videos covered
while cutting the generated audio from 2 h to 1 min.

### 3.3 `lib/core/services/ffmpeg_service.dart`

```dart
final exportedPath =
    await FfmpegFileHelper.exportStagedFile(
      stagedRenderedPath,
      finalDestPath,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        // Scoped-storage copy can stall; never leave the UI at 99% forever.
        // Fall back to the staged render so the result is not lost.
        debugPrint(
          '[FfmpegService] export copy timed out after 30s; '
          'keeping staged file',
        );
        return stagedRenderedPath;
      },
    );
await MediaScannerService.scanFile(exportedPath);
if (exportedPath != stagedOutputPath) {
  FfmpegFileHelper.deletePartialFile(
    stagedOutputPath,
    sourcePath: effectiveInput,
  );
}
```

- Hard 30 s cap on the gallery copy.
- Timeout falls back to the staged render (no data loss) instead of throwing.
- Cleanup is skipped when the fallback path *is* the staged file, closing the
  "delete the result we just returned" bug.

---

## 4. Whitelist deviation (explicit)

The mandatory `flutter test` = 229/229 gate required updating two stale
assertions in `test/ffmpeg_service_test.dart` that hardcoded the old 2-hour
audio leak:

| Line | Old | New |
|---|---|---|
| 437 | `anoisesrc=d=7200:c=pink:a=0.003[noise]` | `anoisesrc=d=60:...` |
| 659 | `anoisesrc=d=7200:c=pink:a=0.0015` | `anoisesrc=d=60:...` |

No production behaviour was altered to satisfy tests; the tests were updated to
match the intended fix.

---

## 5. Verification

| Check | Expected | Result |
|---|---|---|
| `dart analyze --fatal-infos` | exit 0 | **0** — No issues found |
| `flutter test` | 229/229 | **229/229 passed** |
| `dart format --set-exit-if-changed .` | exit 0, 0 changed | **0** — 127 files, 0 changed |
| `filter_threads 1` in command builder | 0 | **0** |
| `d=7200` in `filter_builders.dart` | 0 | **0** |
| `git diff --stat` | 2–3 files | 4 files: 3 lib + 1 test (§4) |

Resulting command prefix (from the audit string):

```
-y -hwaccel none -threads 0 -i "input.mp4"
   -max_muxing_queue_size 4096 ... -c:v libx264 -preset fast -crf 18
```

---

## 6. Files Changed

- `lib/core/services/ffmpeg/ffmpeg_command_builder.dart`
- `lib/core/services/filter_builders.dart`
- `lib/core/services/ffmpeg_service.dart`
- `test/ffmpeg_service_test.dart` (whitelist deviation, §4)
- `0ai_context/reports/128-fix-filter-bottleneck-and-audio-leak.md` (this report)

## 7. Rollback

```bash
git checkout -- lib/core/services/ffmpeg/ffmpeg_command_builder.dart \
                lib/core/services/filter_builders.dart \
                lib/core/services/ffmpeg_service.dart \
                test/ffmpeg_service_test.dart
rm -f 0ai_context/reports/128-fix-filter-bottleneck-and-audio-leak.md
```

No commit was made.
