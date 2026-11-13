# Report 127 — Chunked FFmpeg Audit Logging (Logcat-safe)

**Date:** 2026-11-14
**Status:** Done — audit command split into per-argument lines; suite green
**Base commit:** `108b937 fix(ffmpeg): force software decoding and add command audit log`

---

## 1. Preflight

- `git status --short` → clean
- `git log --oneline -1` → `108b937 fix(ffmpeg): force software decoding and add command audit log`

---

## 2. Problem

`_executeFFmpeg` logged the whole command in one call:

```dart
debugPrint('[FFmpeg Audit] Executing: $command');
```

A real render command is ~3–5 KB (filtergraph alone can exceed 2 KB). Two
failure modes explain why it never showed up in `adb logcat`:

1. **Line length** — logcat truncates very long payloads; the tail (which holds
   the critical `-c:v libx264 -preset fast -crf 18` block) is exactly what gets
   cut off.
2. **`debugPrint` throttling** — `debugPrint` is rate-limited
   (`debugPrintThrottled`). A single huge message is buffered, and if the
   process then blocks in the native FFmpeg call, buffered output can be lost.

---

## 3. Change (`lib/core/services/ffmpeg_service.dart`)

`_executeFFmpeg` (now line 616) logs the command in pieces, split on flag
boundaries (` -`), so every token lands on its own short logcat line:

```dart
// Split the command on flag boundaries so each argument is its own
// Logcat line; a single multi-kilobyte line gets truncated by logcat.
debugPrint('[FFmpeg Audit] Command length: ${command.length}');
final chunks = command.split(' -');
for (var i = 0; i < chunks.length; i++) {
  if (i == 0) {
    debugPrint('[FFmpeg Audit] Start: ${chunks[i]}');
  } else {
    debugPrint('[FFmpeg Audit] Arg: -${chunks[i]}');
  }
}
final session = await FFmpegKit.execute(command);
```

- `Start:` carries the executable prefix (`-y -hwaccel none -threads 0 -i ...`).
- `Arg:` carries one flag group per line, so ordering is preserved and the last
  `-c:v` line is visible — which is what proves the libx264 override wins.
- `Command length:` is a cheap sanity check: compare it with the summed `Arg:`
  payload to confirm nothing was dropped.
- The preview path log (`renderFilteredPreviewFrame`, line 222) was left as is;
  its command is short.

---

## 4. How to read it on device

```bash
adb logcat -c
adb logcat -s flutter | Select-String 'FFmpeg Audit'
```

Expected shape:

```
I/flutter: [FFmpeg Audit] Command length: 3421
I/flutter: [FFmpeg Audit] Start: -y -hwaccel none -threads 0 -i "/data/.../input.mp4"
I/flutter: [FFmpeg Audit] Arg: -filter_threads 1 -filter_complex_threads 1 -max_muxing_queue_size 4096
I/flutter: [FFmpeg Audit] Arg: -map_metadata -1
...
I/flutter: [FFmpeg Audit] Arg: -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -tag:v avc1
I/flutter: [FFmpeg Audit] Arg: -bsf:v filter_units=remove_types=6 "/data/.../output.mp4"
```

Checks to run against the captured log:

1. `-hwaccel none` present before `-i` and **no** `-hwaccel` after it.
2. The final `Arg: -c:v ...` is `libx264` with `-crf 18`; no `-c:v` line after it.
3. Absence of `mediacodec` / `libx265` in every `Arg:` line.
4. `Command length` equals the total characters of all `Arg:` lines (roughly,
   accounting for the `Start`/`Arg` prefixes) — otherwise logcat still dropped
   something, and the next step is `print()` (unthrottled) or writing the
   command to a file in app cache.

---

## 5. Verification

| Check | Expected | Result |
|---|---|---|
| `dart analyze --fatal-infos` | exit 0 | **0** — No issues found |
| `flutter test` | 229/229 | **229/229 passed** |
| `dart format --set-exit-if-changed .` | exit 0, 0 changed | **0** — 127 files, 0 changed |
| `FFmpeg Audit` in `ffmpeg_service.dart` | ≥ 3 | **4** (lines 222, 624, 628, 630) |
| `git diff --stat` | 1 file | **1 file**, +11 / −1 |

---

## 6. Files Changed

- `lib/core/services/ffmpeg_service.dart`
- `0ai_context/reports/127-fix-audit-logging.md` (this report)

## 7. Rollback

```bash
git checkout -- lib/core/services/ffmpeg_service.dart
rm -f 0ai_context/reports/127-fix-audit-logging.md
```

No commit was made.
