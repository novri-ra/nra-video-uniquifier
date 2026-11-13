# Report 123 — Ultimate Stability & Quality (Software Encoding Lock)

**Date:** 2026-11-13
**Status:** Implemented
**Scope:** Force software H.264 encoding (libx264, `-preset fast`, `-crf 18`),
strict sequential filter processing, lock H.265 / Hardware Acceleration in the
UI, and close privacy candidate 037.

---

## 1. MCP Preflight (codebase-memory-mcp)

Index was absent at session start (`list_projects` returned 0), so the project
was indexed before any lookup.

| Check | Result |
|---|---|
| `index_repository(repo_path=..., mode=fast)` | `state: succeeded` (16.7 s) |
| `index_status` | `status: ready`, 2908 nodes, 7070 edges, root `.../nra_video_uniquifier`, indexed_at `2026-11-13T14:31:12Z` |
| `search_graph(name_pattern=".*_cleanupOldPreviews.*")` | 1 hit — `FfmpegService._cleanupOldPreviews`, `lib/core/services/ffmpeg_service.dart:249-249` |
| `search_graph(name_pattern=".*buildCommand.*\|.*_executeFFmpeg.*")` | `FfmpegCommandBuilder.buildCommand` `ffmpeg_command_builder.dart:13-49`; `FfmpegService.buildCommand` `ffmpeg_service.dart:38-74`; `FfmpegService._executeFFmpeg` `ffmpeg_service.dart:612-616` |

Line numbers matched the expected state (`_cleanupOldPreviews` at 249,
`buildCommand` at 13). No re-location was needed.

Coverage note: the index reports `parse_partial` only on native runner files
(`linux/*.cc`, `windows/*.cpp`) plus 6 flagged ranges; no Dart files are affected.
`watch.watched=false` because this repo is not the MCP session project, so the
index is a snapshot and was refreshed explicitly.

---

## 2. Forced Software Encode (Sequential Quality)

File: `lib/core/services/ffmpeg/ffmpeg_command_builder.dart`

- **Stability arguments** are added immediately after the input options on
  every command:
  `-filter_threads 1 -filter_complex_threads 1 -max_muxing_queue_size 4096`
  - `-max_muxing_queue_size 4096` was moved from the tail into this block (it
    was already emitted before this change; it now lives with the other
    stability flags, after the input and before the output).
  - `-filter_threads 1` and `-filter_complex_threads 1` force the filtergraph to
    process one frame at a time, eliminating the parallel-buffer OOM / hang
    (`100 buffers queued`) seen with Real-ESRGAN, Blur, and 2K chains.
  - Placement after `-i` is deliberate: two existing regression tests assert
    the exact `-y ... -i "input"` prefix (`Base command with metadata removal
    only`, `D1-02`).
- **Codec override** is appended as the final encoding arguments whenever a
  visual chain is active:
  `-c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -tag:v avc1`
  - `libx264` is the only encoder selected for real output. The block is written
    last, so it overrides any earlier provider-selected encoder arguments
    (H.265/`libx265`, MediaCodec hardware encoders) emitted by `FilterBuilders`.
  - `-tag:v avc1` also overrides a stale `-tag:v hvc1`, which would otherwise be
    invalid on an H.264 stream if a persisted H.265 setting reached the builder.
  - `-pix_fmt yuv420p` guarantees 8-bit 4:2:0 output for universal player
    compatibility.
- The `-c copy` fast path (no visual and no audio processing) is preserved;
  the forced encoder block only runs when `hasVisual` is true.

Rationale: the command builder is the single choke point shared by every
provider path. `libx265`/`h264_mediacodec`/`hevc_mediacodec` selection logic
does not exist in this file; the only codec selection lives in
`FilterBuilders._resolveCodecArgs`, which is outside this task's whitelist, so
the override is applied downstream where it deterministically wins. There are
now **0** `mediacodec` / `libx265` occurrences in the command builder.

---

## 3. UI Locks

### `lib/features/settings/widgets/codec_selector_card.dart`

- H.264 tile: selected by default, description updated to
  `CRF 18 • Preset fast • Studio-grade software encoding engine`.
- H.265 tile: disabled (`onTap: null`), `isSelected: false`, greyed title /
  description / icon via `onTap == null` detection, badge changed to
  `DISABLED (STABILITY PRIORITY)` with the outline color.
- `_CodecTile.onTap` is now nullable; the badge is wrapped in `Flexible` with
  ellipsis so the longer "DISABLED (STABILITY PRIORITY)" label cannot overflow
  on narrow layouts.

### `lib/features/settings/widgets/hardware_acceleration_card.dart`

- Toggle permanently locked: `Switch(value: false, onChanged: null)`.
- Subtitle changed to
  `Permanently Disabled (Software Engine Active for 100% Quality)`.
- The shared `SettingToggleRow` requires a non-null `onChanged`, so the row was
  rebuilt locally inside this card (same container styling, icon, spacing) to
  keep the lock while respecting the file whitelist and leaving the shared
  widget untouched.
- The public `enabled` / `onToggle` constructor parameters are retained so the
  settings screen call site compiles unchanged; their values are intentionally
  ignored.

---

## 4. Privacy Fix (Candidate 037) — CLOSED

File: `lib/core/services/ffmpeg_service.dart` → `_cleanupOldPreviews`

Before:

```dart
debugPrint(
  '[FfmpegService] delete old preview failed for '
  '${entity.path}: $e',
);
```

After:

```dart
final filePath = entity.absolute.path;
final fileName = filePath.split(RegExp(r'[/\\]')).last;
...
debugPrint(
  '[FfmpegService] delete old preview failed for '
  '$fileName: ${e.runtimeType}',
);
```

- Only the base file name is logged — never the absolute path.
- The raw exception object is no longer interpolated; only `e.runtimeType`
  (e.g. `FileSystemException`) is emitted, so no OS paths or messages leak.
- `entity.path` is no longer referenced anywhere in the file (0 grep hits).

---

## 5. Verification

| Check | Expected | Result |
|---|---|---|
| `dart analyze --fatal-infos` | exit 0 | exit 0 — "No issues found!" |
| `flutter test` | 229/229 | **229/229 passed** |
| `dart format --set-exit-if-changed .` | exit 0, 0 changed | exit 0, 0 changed |
| `grep -n 'max_muxing_queue_size 4096' ffmpeg_command_builder.dart` | ≥1 | 1 hit (line 70) |
| `grep -n 'filter_threads 1' ffmpeg_command_builder.dart` | ≥1 | 1 hit (line 69) |
| `grep -n 'libx264' ffmpeg_command_builder.dart` | ≥1 | 1 hit (line 260) |
| `grep -n 'crf 18' ffmpeg_command_builder.dart` | ≥1 | 1 hit (line 260) |
| `grep -n 'preset fast' ffmpeg_command_builder.dart` | ≥1 | 1 hit (line 260) |
| `grep -nE 'mediacodec\|libx265' ffmpeg_command_builder.dart` | 0 | 0 hits |
| `grep -n 'entity.path' ffmpeg_service.dart` | 0 | 0 hits |
| `git diff --stat` | 4 modified + 1 new | 4 modified, report added below |

### Note on retained decode flag

`writeInputOptions` still emits `-hwaccel auto` when its `hwAccel` argument is
true. That flag only requests hardware-accelerated **decoding**; it never
selects a hardware encoder, because the forced `-c:v libx264` block is always
last. The existing `D1-02` regression test asserts this flag, and the UI lock
means the setting can no longer be enabled from the app. Encoder-level
stability (the source of `100 buffers queued`) is fully controlled by
`-filter_threads 1` + software `libx264`.

---

## 6. Files Changed

- `lib/core/services/ffmpeg/ffmpeg_command_builder.dart` — global stability
  flags + forced libx264/CRF 18/preset fast/yuv420p encoder block.
- `lib/core/services/ffmpeg_service.dart` — privacy-safe preview cleanup log.
- `lib/features/settings/widgets/codec_selector_card.dart` — H.265 disabled.
- `lib/features/settings/widgets/hardware_acceleration_card.dart` — toggle
  permanently disabled.
- `0ai_context/reports/123-ultimate-stability-and-quality.md` — this report.

## 7. Rollback

```bash
git checkout -- lib/core/services/ffmpeg/ffmpeg_command_builder.dart \
  lib/core/services/ffmpeg_service.dart \
  lib/features/settings/widgets/codec_selector_card.dart \
  lib/features/settings/widgets/hardware_acceleration_card.dart
rm -f 0ai_context/reports/123-ultimate-stability-and-quality.md
```
