# Report 109 — Blur Slider SIGSEGV: Heavy-Effect Preview Skip + `-cpuflags 0`

- Date: 2026-11-09
- Crash: `SIGSEGV / SEGV_ACCERR` in `libswscale.so` (ARM NEON `hScale`/`yuv2plane*`), triggered by dragging the "Blurred Canvas Scale" slider
- Target files:
  - `lib/core/providers/uniquifier_provider.dart` (owns `requestFilteredPreviewDebounced`)
  - `lib/core/services/ffmpeg_service.dart`
- Status: RESOLVED (static verification only; on-device confirmation pending)
- Findings: FF-NATIVE-002 (preview-path swscale crash)

## 1. Verify-Premise Notes (corrections to the brief)

1. **`requestFilteredPreviewDebounced` is not in a mixin.** MCP `search_graph(name_pattern=".*requestFilteredPreviewDebounced.*")` returns exactly one node: `UniquifierProvider.requestFilteredPreviewDebounced`, `lib/core/providers/uniquifier_provider.dart:244-249` (in-degree 7, out 2). Neither `uniquifier_progress_mixin.dart` nor `uniquifier_media_mixin.dart` contains it, so the whitelist's "the ONE mixin file" had no valid target. Modified `uniquifier_provider.dart` — the only file that actually contains the method — and left both mixins untouched by this batch.
2. **The third heavy-effect condition is redundant.** `selectedVisualEffect` is derived from `activeVisualEffects` (provider lines 183-188: last non-`none` member), so `activeVisualEffects.any(_heavyPreviewEffects.contains)` already implies it. Implemented two checks (`enableBlurredCanvas` OR any heavy effect active) instead of the three listed; behaviour is identical, one less unmodifiable `Set` copy per slider tick.
3. Field names confirmed: `enableBlurredCanvas` getter (`uniquifier_modifiers_mixin.dart:43`), `activeVisualEffects` getter (`uniquifier_provider.dart:181`), enum `UnifiedVisualEffect` (`lib/core/models/unified_effect_preset.dart:2`) with values `none, blurredCanvas, motionEcho, rgbSplit, dreamyBloom, film16mm, dynamicGrain`.
4. **`-cpuflags 0`** disables every SIMD implementation, forcing FFmpeg's C paths — a genuine NEON bypass, but it also slows decoding/scaling measurably. Acceptable for a single preview frame and a single thumbnail; not applied to export (per instruction).
5. Report 108's `-sws_flags bilinear` and `scale=iw-2:ih-2,format=yuvj420p` are still present in `extractThumbnail`; `renderFilteredPreviewFrame` still has `-sws_flags bilinear`.

## 2. Summary of Changes

1. **`requestFilteredPreviewDebounced`** — after `_previewDebounceTimer?.cancel()` and before the `selectedFilePath` null-check: if `_isHeavyPreviewEffect()`, clear `_renderedPreviewFramePath`, set `_isPreviewRendering = false`, `notifyListeners()`, and return. No FFmpeg process is spawned for heavy effects.
2. **`_heavyPreviewEffects` / `_isHeavyPreviewEffect()`** — new private static set + private guard placed directly below the method. Returns true for `blurredCanvas`, `motionEcho`, `rgbSplit`, `dreamyBloom`, `dynamicGrain`, or when `enableBlurredCanvas` is on. `film16mm`, `none`, and the pure slider effects (`cropZoom`, `microRotation`, `sharpening`, `saturation`, `canvasScale`) stay on the FFmpeg path.
3. **`extractThumbnail`** — `-cpuflags 0` inserted right before `-ss` (global option, so it applies to decode and swscale).
4. **`renderFilteredPreviewFrame`** — `-cpuflags 0` inserted right before `-i`; `-preset ultrafast`, `-sws_flags bilinear`, the `-vf`/`-filter_complex` branch logic and the `hasTemporalEffect` branch are unchanged.
5. No new `try/catch` (a native SIGSEGV is not catchable), no refactor of filter builders, `_executeFFmpeg` untouched.

When the guard fires, `renderedPreviewFramePath` becomes `null`, so `interactive_preview_slider.dart:428` falls through to `_buildSimulatedFallback(...)` — the existing Flutter simulation. This was confirmed by reading that widget (it is not modified).

## 3. Verification

| Gate | Result |
|---|---|
| `dart analyze --fatal-infos` | exit 0, 0 issues |
| `dart format --output=none --set-exit-if-changed` (2 files) | exit 0, 0 changed |
| `flutter test test/uniquifier_provider_test.dart` | 21/21 passed |
| `flutter test test/unified_effect_preview_test.dart` | 17/17 passed |
| `flutter test test/ffmpeg_service_test.dart` | 38/38 passed |
| `flutter test` | **212 passed / 4 failed of 216** |
| `grep -c "cpuflags 0"` in `ffmpeg_service.dart` | 2 (expected 2) |
| `grep -c "_isHeavyPreviewEffect"` in `uniquifier_provider.dart` | 2 (expected 2 — call + declaration) |
| `git diff --stat` | 3 files, +65 / −3 |

The 4 full-suite failures are the same pre-existing Impeller shader failures documented in reports 107/108 §3 (`Asset 'shaders/ink_sparkle.frag' ... (SkSL) ... Found stages: Vulkan`) on this Windows host — `app_toast_test.dart`, `setting_fps_selector_row_test.dart`, `visual_effect_selector_card_test.dart`, `widget_test.dart` (D2-01). They reproduce on a clean tree.

**Working-tree caveat for the diff-scope check:** `git diff --name-only` lists 3 files because `lib/core/providers/uniquifier/uniquifier_media_mixin.dart` still carries the uncommitted report-108 changes (never committed). This batch touched exactly 2 files; the mixin was not edited here.

## 4. Behavior Notes

- Heavy effect selected (or blur canvas on) → slider drags no longer spawn FFmpeg; the overlay shows the Flutter simulation, no SIGSEGV path.
- Light effects and slider-only adjustments still render a real FFmpeg preview, now with SIMD disabled.
- Thumbnail extraction still runs (SIMD disabled) on file pick.
- Export path (`processVideo`/`buildCommand`/`_executeAndExport`/`_executeFFmpeg`) untouched.

## 5. Other swscale-triggering sites (not fixed)

`FFmpegKit.execute` / `executeAsync` occurrences in `ffmpeg_service.dart`: line 144 (`extractThumbnail`, now `-cpuflags 0`), line 220 (`renderFilteredPreviewFrame`, now `-cpuflags 0`), line 618 (`_executeFFmpeg`, main export — deliberately out of scope). No other call sites exist in this file. `MediaProbeHelper`/`FfmpegFileHelper` were not inspected in this batch (out of whitelist); staging is a stream copy, not a scaler.

## 6. Follow-ups

1. **Candidate finding #034** — if a real FFmpeg blur preview is still required, downgrade `ffmpeg_kit_flutter_new` to `^2.0.0` (FFmpeg 6.x) rather than chasing flags.
2. **Candidate finding #035** — a light-effect preview already in flight when the user switches to a heavy effect can still complete and repopulate `renderedPreviewFramePath` (the guard only nulls it at switch time). Harmless visually (one stale frame) but worth cancelling the active preview session if this is observed on device.

## 7. MCP Evidence Appendix

| Tool | Query | Result |
|---|---|---|
| `index_status` | project `nra-video-uniquifier` | status `ready`, 2879 nodes / 7142 edges, generation `2026-11-09T05:27:35Z` (preflight OK, no retry) |
| `search_graph` | `name_pattern=".*requestFilteredPreviewDebounced.*"` | 1 result: `UniquifierProvider.requestFilteredPreviewDebounced`, `lib/core/providers/uniquifier_provider.dart:244-249`, in-degree 7, out 2 |
| `grep` (source fallback) | `get selectedVisualEffect|get activeVisualEffects` across `lib/` | provider lines 181 and 183 |
| `grep` (source fallback) | `enum UnifiedVisualEffect` + values | `lib/core/models/unified_effect_preset.dart:2`, 7 values |
| `grep` (source fallback) | `renderedPreviewFramePath`/`_buildSimulatedFallback` in `interactive_preview_slider.dart` | fallback reached at line 428 when path is null |
| `grep` (source fallback) | `FFmpegKit.execute|executeAsync` in `ffmpeg_service.dart` | 3 sites: 144, 220, 618 |
