# Report 126 — Audit & Fix: FFmpeg Stall (`100 buffers queued`)

**Date:** 2026-11-13
**Status:** Done — software decode locked, full command audit log added, suite green
**Base commit:** `1e42095 feat(core): ultimate stability lock, remove intel tab, and setup lut engine`

---

## 1. Preflight

- `git status --short` → clean
- `git log --oneline -1` → `1e42095`

### MCP (codebase-memory-mcp)

Index snapshot `2026-11-13T14:31:12Z` (2908 nodes / 7070 edges, `watch.watched=false`),
so line numbers were cross-checked against the files.

| Query | Result |
|---|---|
| `index_status` | `status: ready`, 2908 nodes, 7070 edges |
| `search_graph(".*buildCommand.*")` | `FfmpegCommandBuilder.buildCommand` (13-49), `FfmpegService.buildCommand` (38-74) |
| `search_graph(".*_executeFFmpeg.*")` | `FfmpegService._executeFFmpeg` (612-616) |
| `search_graph(".*writeInputOptions.*")` | `FfmpegCommandBuilder.writeInputOptions` (127-135) |

---

## 2. Root-cause audit

### 2.1 Where the stall comes from

`100 buffers queued in out_0_0` is a **muxer** back-pressure message: the output
packet queue for stream `0:0` (video) hit its soft limit because the encoder was
not draining frames fast enough. Two things kept that window open:

1. `writeInputOptions` emitted `-hwaccel auto` whenever
   `enableHardwareAcceleration` was true. Android MediaCodec decode of 4K /
   HEVC sources plus a heavy filter chain (`boxblur` + `overlay` + `hqdn3d` +
   `unsharp` + `noise`) can starve because the hardware decode surface pool is
   finite; decoding stalls while filters are still consuming frames.
2. `q=24.0` in the progress line is the **current frame quantizer**, not proof
   of a hardware encoder — so it was not by itself evidence of a codec
   override. It is however consistent with a stalled/slow encoder, which is what
   the muxer complaint reports.

### 2.2 Codec override was already correct

Verified against a real assembled command (see §4): `FilterBuilders` still
appends its provider-selected codec (`-c:v libx265 ...` when H.265 was chosen),
but `FfmpegCommandBuilder.writeFilterAndCodecOptions` appends

```
-c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -tag:v avc1
```

**after** the video filter, the audio filter and `-fps_mode cfr`, and FFmpeg is
last-wins for repeated output options. No `mediacodec`/`libx265` token is emitted
by the command builder itself (0 hits). The only remaining hardware dependency
was the input decoder — which is what this task removes.

---

## 3. Changes

### 3.1 `lib/core/services/ffmpeg/ffmpeg_command_builder.dart`

- `writeInputOptions` no longer takes the `hwAccel` flag and no longer emits
  `-hwaccel auto`; it now **always** writes `-hwaccel none` before `-threads`
  and `-i "input.mp4"`:

  ```dart
  // Software decoding is locked in: MediaCodec / VAAPI hardware decode stalls
  // ("100 buffers queued in out_0_0") when fed heavy filter chains, so the
  // CPU decoder is the only deterministic path.
  buffer.write(' -hwaccel none');
  buffer.write(thermalThrottle ? ' -threads 4' : ' -threads 0');
  ```

- `buildCommand` keeps the public `enableHardwareAcceleration` parameter for API
  compatibility (callers in `ffmpeg_service.dart`, `batch_queue_provider.dart`,
  `processing_screen.dart`), but it is now intentionally ignored and documented
  as such at the call site.

### 3.2 `lib/core/services/ffmpeg_service.dart`

Full command tracing added with a greppable marker:

- `_executeFFmpeg` (main render pipeline):
  ```dart
  debugPrint('[FFmpeg Audit] Executing: $command');
  final session = await FFmpegKit.execute(command);
  ```
  (`_executeFFmpeg` uses `FFmpegKit.execute`, not `executeAsync`; the log sits
  immediately before the call so the exact string is captured.)
- `renderFilteredPreviewFrame` (the only `executeAsync` command path):
  ```dart
  debugPrint('[FFmpeg Audit] Executing preview: $cmd');
  ```

### 3.3 One-time real-command verification

A throwaway `flutter test` harness (created, run, deleted — no repo change)
printed the assembled string with `VideoCodec.h265` + `enableHardwareAcceleration: true`:

```
-y -hwaccel none -threads 0 -i "/in.mp4"
   -filter_threads 1 -filter_complex_threads 1 -max_muxing_queue_size 4096
   ... -vf "...lut3d...,format=yuv420p"
   -c:v libx265 -preset fast -crf 26 -tag:v hvc1 -pix_fmt yuv420p ...
   -af "..." -c:a aac -b:a 192k -ar 44100 -ac 2
   -fps_mode cfr -r 29.59
   -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -tag:v avc1
   -bsf:v filter_units=remove_types=6 "/out.mp4"
```

Both requirements confirmed: `-hwaccel none` is the decoder flag, and
`-c:v libx264 -preset fast -crf 18` is the **last** `-c:v` in the string.

### 3.4 Pre-existing observations (not changed)

- `-map_metadata -1`, `-map_chapters -1` and `-fflags +bitexact` are emitted
  twice (builder + `FfmpegMetadataBuilder`). Harmless duplicates.
- `-r 29.59` (variation fps) is emitted while the filter chain pins `fps=30`.
  Cosmetic inconsistency for CFR; out of scope for this task.

---

## 4. Whitelist deviation (explicit)

The mandatory `flutter test` = 229/229 gate could not hold without touching two
stale assertions in `test/ffmpeg_service_test.dart` that encoded the old
behaviour (`-hwaccel auto`). The task whitelist listed only the two lib files,
so this is called out explicitly:

| Test | Old | New |
|---|---|---|
| `Base command with metadata removal only` (line 39) | `-y -threads 0 -i "/path/input.mp4"` | `-y -hwaccel none -threads 0 -i "/path/input.mp4"` |
| `D1-02` (line ~1012) | asserts `-hwaccel auto` when `enableHardwareAcceleration: true` | asserts `-hwaccel none` and `isNot(contains('-hwaccel auto'))` |

No behaviour was changed to make tests pass; the tests were updated to describe
the newly locked contract.

---

## 5. Verification

| Check | Expected | Result |
|---|---|---|
| `dart analyze --fatal-infos` | exit 0 | **0** — No issues found |
| `flutter test` | 229/229 | **229/229 passed** |
| `dart format --set-exit-if-changed .` | exit 0, 0 changed | **0** — 127 files, 0 changed |
| `hwaccel none` in command builder | ≥ 1 | **1** |
| `hwaccel auto` in command builder | 0 | **0** |
| `FFmpeg Audit` in `ffmpeg_service.dart` | ≥ 1 | **2** (lines 222, 622) |
| `git diff --stat` | 2 files | 3 files: 2 lib + 1 test (see §4) |

---

## 6. Files Changed

- `lib/core/services/ffmpeg/ffmpeg_command_builder.dart`
- `lib/core/services/ffmpeg_service.dart`
- `test/ffmpeg_service_test.dart` (whitelist deviation, §4)
- `0ai_context/reports/126-audit-ffmpeg-stall.md` (this report)

## 7. Rollback

```bash
git checkout -- lib/core/services/ffmpeg/ffmpeg_command_builder.dart \
                lib/core/services/ffmpeg_service.dart \
                test/ffmpeg_service_test.dart
rm -f 0ai_context/reports/126-audit-ffmpeg-stall.md
```

No commit was made.

## 8. Next diagnostic step (if the stall ever recurs)

Run one render and capture logcat:

```bash
adb logcat -s flutter | Select-String 'FFmpeg Audit'
```

The logged command is the ground truth: confirm `-hwaccel none`, a single
trailing `-c:v libx264`, and that no provider-level flags follow it. If the
muxer message still appears with a CPU decoder, the bottleneck is encoder
throughput (preset/CRF), not decode/encoder selection.
