# Report 108 — Native Crash Mitigation: swscale sws_flags, Scale Guard, and Dimension Validation

- Date: 2026-11-09
- Crash: `SIGSEGV / SEGV_ACCERR` in `libswscale.so` (`sws_scale`) on ARM64 Android 11, worker thread `pool-5-thread-2`, after picking a video
- Target files:
  - `lib/core/services/ffmpeg_service.dart`
  - `lib/core/providers/uniquifier/uniquifier_media_mixin.dart`
- Status: RESOLVED (static verification only; on-device confirmation pending)
- Findings: new — FF-NATIVE-001 (swscale crash mitigation)

## 1. Verify-Premise Notes (corrections to the brief)

1. **Step 3 does not match the code.** `setVideoFile` does **not** call `FfmpegService.probeMediaMeta`, and there is no synchronous `meta` object to validate. The real flow was:
   `setVideoFile()` → fire-and-forget `_extractThumbnailAsync(path)` → fire-and-forget `_probeMediaInfo(path)`, where `_probeMediaInfo` runs `FFprobeKit.getMediaInformation` and applies dimensions later inside `_applyVideoStream`. A guard placed "immediately after the probe returns" would therefore run *after* the thumbnail FFmpeg call — too late to prevent the crash. Implemented the intent instead: `_probeMediaInfo(path)` now runs first, validates dimensions, and only then kicks `_extractThumbnailAsync(path)`. `setVideoFile` stays `void` (its 2 UI call sites and 3 test call sites are unchanged) and no second probe was added.
2. **Log format**: `${_videoWidth}x${_videoHeight}` is rejected by the mandated gate — `dart analyze --fatal-infos` reports `unnecessary_brace_in_string_interps` (3×) because the formatter splits the message into adjacent literals, leaving `${...}` at a literal boundary. Messages use the file's own convention `'$_videoWidth×$_videoHeight'` instead (same `×` separator as `_fileResolution`). Grep phrases are unchanged.
3. **`-sws_flags bilinear` does not disable the ARM assembly path.** It selects the bilinear scaler, which still routes through the same `yuv2plane*`/`hScale` NEON kernels; only the filter kernel differs from the default bicubic. It is still a reasonable mitigation (different code path, no `swscale_unscaled()` fast path) but it is **not** a guaranteed bypass, and the brief's claim that it "forces the C reference scaler" is inaccurate. The dimension guard and the `iw-2:ih-2` guard are the stronger mitigations.
4. **`scale=iw-2:ih-2` parity**: for even sources the destination stays even; for an **odd** source (e.g. 1081) it becomes odd (1079), and `yuvj420p` 4:2:0 chroma normally wants even dimensions. If odd-dimension thumbnails still fail on device, replace the guard with `scale=trunc((iw-2)/2)*2:trunc((ih-2)/2)*2` (see §5).
5. `extractThumbnail`'s outer try/catch, log prefix (report 98), and `return null` path were not touched.

## 2. Summary of Changes

1. **ffmpeg_service.dart / `extractThumbnail`** — added `-sws_flags bilinear` and `-vf "scale=iw-2:ih-2,format=yuvj420p"` before `-vframes 1`.
2. **ffmpeg_service.dart / `renderFilteredPreviewFrame`** — added `-sws_flags bilinear` between `-preset ultrafast` and `$vfOption`, so it applies to both the `-vf` and `-filter_complex` branches (that branch logic is untouched).
3. **uniquifier_media_mixin.dart** — probe now precedes thumbnail extraction; added `_validateDimensions()` (reject `<= 0`, reject `> 8192`, warn-only on odd) plus `_rejectMedia()` (reuses the existing `clearMediaSelection()` then `notifyListeners()`), and `_videoWidth/_videoHeight` captured in `_applyVideoStream`, reset on every new selection.
4. No new `try/catch` anywhere (native SIGSEGV is not catchable in Dart, as the brief states); no new helper files, no refactor of probe or preview.

## 3. Verification

| Gate | Result |
|---|---|
| `dart analyze --fatal-infos` | exit 0, 0 issues |
| `dart format --output=none --set-exit-if-changed` (2 files) | exit 0, 0 changed |
| `flutter test test/ffmpeg_service_test.dart` | 38/38 passed |
| `flutter test test/uniquifier_provider_test.dart` | 21/21 passed |
| `flutter test` | **212 passed / 4 failed of 216** |
| `grep -c "sws_flags bilinear"` | 2 (expected 2) |
| `grep -c "scale=iw-2:ih-2,format=yuvj420p"` | 1 (expected 1) |
| `grep -c "invalid dimensions"` | 1 (expected 1) |
| `grep -c "dimensions exceed limit"` | 1 (expected 1) |
| `grep -c "odd dimensions"` | 1 (expected 1) |
| `git diff --stat` | 2 files, +44 / −3 (no business-logic deletions) |

The 4 full-suite failures are the same pre-existing, environment-only failures seen on the clean tree in report 107: `app_toast_test.dart`, `setting_fps_selector_row_test.dart`, `visual_effect_selector_card_test.dart`, `widget_test.dart` (D2-01), all from `Asset 'shaders/ink_sparkle.frag' ... (SkSL) ... Found stages: Vulkan` — an Impeller shader-backend mismatch on this Windows host, unrelated to this change.

## 4. Behavior Notes

- Rejected clips (zero/negative dimensions, or > 8192 px) now clear the selection and notify listeners instead of proceeding to FFmpeg.
- A clip whose probe returns no usable video stream never reaches the thumbnail FFmpeg call; the previous code always fired it. This is intentional (that call is the crash path) but means a container FFprobe cannot read no longer yields a thumbnail.
- Main export pipeline (`processVideo` → `buildCommand` → `_executeAndExport` → `_executeFFmpeg`) is untouched.
- Logs contain dimensions (numbers only), never a path or filename.

## 5. Follow-ups (not fixed here)

1. **Candidate finding #032** — other swscale-triggering calls without `-sws_flags`: `_executeFFmpeg` (`ffmpeg_service.dart:618`, the main export) and `_executeAndExport` (`:558`, builds user filtergraph) both invoke swscale on the full-size frame; `buildCommand` output also runs `scale`/`unsharp`. Left alone deliberately (report 107 precedent: main path must not be perturbed). If on-device crashes persist after this batch, add `-sws_flags bilinear` to `_executeFFmpeg`'s command assembly as the next smallest step.
2. **Parity fix for odd sources** — swap the thumbnail guard to `scale=trunc((iw-2)/2)*2:trunc((ih-2)/2)*2,format=yuvj420p` if odd-dimension clips still fail (`yuvj420p` 4:2:0 wants even dimensions). One-line change, same location.

## 6. MCP Evidence Appendix

| Tool | Query | Result |
|---|---|---|
| `index_status` | project `nra-video-uniquifier` | status `ready`, 2870 nodes / 7128 edges, generation `2026-11-09T04:59:13Z` (preflight OK, no retry) |
| `grep` (source fallback) | `FFmpegKit.execute|_executeFFmpeg|_executeAndExport` in `ffmpeg_service.dart` | 7 hits: 144 (`extractThumbnail`), 220 (`renderFilteredPreviewFrame`), 396/558/565/612/618 (main export chain) |
| `grep` (source fallback) | `setVideoFile` across `lib/`, `test/` | 6 hits: definition + 2 UI call sites + 3 test call sites |
| `grep` (source fallback) | `probeMediaMeta`, `sws_flags`, `extractThumbnail`, `renderFilteredPreviewFrame` in `ffmpeg_service.dart` | confirmed no `probeMediaMeta` call inside the mixin and no pre-existing `sws_flags` |
