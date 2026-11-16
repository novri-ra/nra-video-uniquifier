# Report 163 — fix: FFmpeg v7 Complex Filter Graphs, `fifo` Removal & Parameter Deduplication

## Metadata
- **Date**: 2026-11-16
- **Type**: fix
- **Task**: fix-ffmpeg-complex-graphs-163
- **Status**: done
- **Tests**: 229/229 passed
- **Analyze**: 0 issues (`dart analyze --fatal-infos`)

---

## Summary

Refactored the FFmpeg command layer end-to-end to fix three device-level failures reported
on physical hardware running FFmpeg v7.1.1:

1. `No such filter: fifo` — the `fifo` filter was removed from FFmpeg v7, but both video
   filter lists still injected it before `format=yuv420p`.
2. `Multiple -c:v / -pix_fmt / -max_muxing_queue_size` warnings — codec and muxing
   arguments were emitted twice, once by `FilterBuilders` and once by
   `FfmpegCommandBuilder`.
3. Labelled filter graphs (`[outv]`, `[aout]`) were being injected into `-vf` / `-af`,
   which FFmpeg v7 rejects outright.

### Root Causes
- `FilterBuilders.buildVideoFilter` and `buildAudioFilter` returned **complete shell
  fragments** (`-vf "..."`, `-af "..."`, `-c:v ...`, `-c:a ...`) instead of raw graphs.
- `FfmpegCommandBuilder.writeFilterAndCodecOptions` then appended a second codec block and
  a second `-max_muxing_queue_size 20`, producing conflicting flags where the last one won.
- Complex graphs reused the audio input label `[in]` and had no terminal video label, so
  even after switching to `-filter_complex` the mapping was invalid.

---

## Implementation

### 1. `lib/core/services/filter_builders.dart`

- **`fifo` removed** from `_buildFiltersList` and `_buildPostCanvasFilters`.
- **`buildVideoFilter` now returns raw graphs only**, with an explicit contract:
  - `''` → nothing to do, `copy` → stream passthrough,
  - simple → linear chain without labels,
  - complex → self-contained graph starting at `[0:v]` and ending with `[vout]`.
- **`buildAudioFilter` now returns raw graphs only**:
  - complex graphs start at `[0:a]` (was the invalid `[in]`) and end with `[aout]`
    (was the ambiguous `[out]`).
- **New `_buildEffectSegments`**: multi-stage visual effects (Motion Echo, RGB Split, Dreamy
  Bloom, etc.) are emitted as label-isolated segments
  (`[0:v]<base>[v0];<effect>[ve1];...;[vout]`) instead of being concatenated into a comma
  chain, which previously produced unparseable graphs.
- **Blurred Canvas + effects now compose** instead of silently dropping the selected
  effects: the canvas stack parks its output on `[vcanvas]` and the effect stages chain
  after it up to `[vout]`.
- **New `_applyLut`** centralises LUT injection and normalises separators:
  `lut3d='${lutPath.replaceAll('\\', '/')}'` so Android's POSIX path parser accepts LUT
  paths containing spaces (e.g. `.../my lut.cube`).
- **`_resolveCodecArgs` → `resolveVideoCodecArgs`** (public): `FilterBuilders` remains the
  single owner of encoder policy (H.264/H.265, 1080p `fast/crf 22`, 2K/4K
  `faster/crf 17`, `-tag:v avc1` for H.264 and `hvc1` for H.265); the command builder
  decides placement only.

### 2. `lib/core/services/ffmpeg/ffmpeg_command_builder.dart`

- **Removed duplicate arguments**:
  - `-max_muxing_queue_size 20` (the trailing guard) — the single authoritative
    `-max_muxing_queue_size 4096` near the top of the command remains.
  - the trailing hardcoded `-c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -tag:v avc1`.
- **Single `-filter_complex` authority** with deterministic mapping:
  - video + audio processing → `-filter_complex "[0:v]...[vout];[0:a]...[aout]"`
    `-map "[vout]" -map "[aout]" -c:v <policy> -c:a aac`;
  - visual only → `-map "[vout]" -map 0:a? -c:a copy`;
  - audio only → `-map 0:v -map "[aout]" -c:v copy`;
  - simple chains are wrapped as `[0:v]<chain>[vout]` / `[0:a]<chain>[aout]`.
- Codec flags now come from `FilterBuilders.resolveVideoCodecArgs`, so H.265 selection and
  2K/4K presets are no longer silently overridden.
- `lutPath` is now actually forwarded into `writeFilterAndCodecOptions` (it was dropped
  before reaching the filter builder, so LUTs never applied to exports).
- `hasVisual` now also accounts for non-`none` `activeVisualEffects`, so effect-only runs
  re-encode instead of silently copying.
- Complex-graph detection uses the contract prefix (`[0:v]` / `[0:a]`) instead of a loose
  regex, so bracketed filter arguments (e.g. LUT filenames) can never be mistaken for
  stream labels.

### 3. `lib/core/services/ffmpeg_service.dart`

- `_appendLutIfMissing` (thumbnail/preview path) uses the same backslash normalisation, so
  Android LUT paths with spaces work consistently in previews and exports.

### 4. `test/ffmpeg_service_test.dart`

- Updated the aggressive-audio assertion from `[out]` to `[aout]` to match the new
  filtergraph contract.

---

## Files Modified

| File | Change |
|------|--------|
| `lib/core/services/filter_builders.dart` | Removed `fifo`, raw-graph contract, `[0:a]…[aout]`, effect stage graph, LUT normalisation, public codec resolver. |
| `lib/core/services/ffmpeg/ffmpeg_command_builder.dart` | Removed duplicate muxing/codec flags, single `-filter_complex` + `-map` authority, forwards `lutPath`, policy codec args. |
| `lib/core/services/ffmpeg_service.dart` | LUT path normalisation in `_appendLutIfMissing`. |
| `test/ffmpeg_service_test.dart` | Audio graph terminal label assertion updated to `[aout]`. |

---

## Generated Command Shapes

```text
# Visual + audio
-filter_complex "[0:v]...[vout];[0:a]...[aout]" -map "[vout]" -map "[aout]" \
  -c:v libx264 ... -pix_fmt yuv420p -c:a aac -b:a 192k ...

# Visual only
-filter_complex "[0:v]...[vout]" -map "[vout]" -map 0:a? -c:a copy

# Audio only
-filter_complex "[0:a]...[aout]" -map 0:v -map "[aout]" -c:v copy -c:a aac ...

# Blurred canvas (complex, terminal label included)
[0:v]split=2[bg][fg];...[blurred][main]overlay=...[outv];[outv]<post-filters>[vout]

# Blurred canvas + multi-stage effects (chained, single terminal label)
...overlay=...[outv];[outv]<post-filters>[vcanvas];
[vcanvas]<effect 1>[ve1];[ve1]<effect 2>[vout]
```

---

## Verification

```bash
dart analyze --fatal-infos
# -> Analyzing nra_video_uniquifier... No issues found!

flutter test
# -> 229/229 passed.
```

Additional manual checks:
- Command inspection confirmed a single `-max_muxing_queue_size 4096`, a single codec block,
  no `fifo`, no `-vf` / `-af` for labelled graphs, and `[0:a]`/`[aout]` audio labels.
- LUT output: `lut3d='C:/Users/me/LUTs/my lut.cube'` (spaces preserved, separators normalised).
- Canvas + two effects produced a fully connected graph:
  `...[outv]<post>[vcanvas];[vcanvas]...[ve1];[ve1]...[vout]`.

### Code Review
- The `reviewer` subagent could not run in this environment (`No active credentials for
  provider: openai`, retried once). An equivalent manual review was performed with the
  `code-reviewer` checklist: contract verified for all branches (video-only, audio-only,
  both, neither, canvas, canvas+effects, mute/aggressive/deep audio), no dangling `-map`
  labels, no duplicate flags, and no `fifo` references remain.

---

## Follow-Ups

- Rebuild the APK and re-test on the physical device that produced the `No such filter: fifo`
  log (Task 164).
- Optional hardening: escape `,` and `:` inside LUT paths if custom LUT filenames may contain
  filtergraph metacharacters.
