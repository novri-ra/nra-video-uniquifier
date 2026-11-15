# Report 147: LUT Preset Expansion & ModifiersCard UI Selector

- **Date:** November 15, 2026
- **Status:** Complete (with one P1 defect found and partially fixed — see §4)
- **Scope:** Generate 3 new 3D LUT presets, build the LUT selector UI inside `FRAMING & TEXTURE`, and re-synchronize the Context Mapping Files.

---

## 1. Executive Summary

Three new 16×16×16 3D LUT presets were generated and wired into a horizontal chip selector inside the `FRAMING & TEXTURE` accordion of `modifiers_card.dart`.

**However, while verifying the "preview debounce is triggered" requirement, a P1 correctness defect was discovered:** the LUT pipeline shipped in Reports 144/145 was **dead code end-to-end**. `provider.lutName` was never forwarded to `FfmpegService.processVideo`, so selecting a preset had **zero effect on exported video**. The UI added in this report was therefore the *first* code that could ever set the value, and it would still have produced nothing.

The single-export path is now fixed (one added argument). Two integration points remain open and are registered as active finding `AUDIT-20261115-038` (§4).

---

## 2. New LUT Presets (`assets/luts/`)

All four files are `LUT_3D_SIZE 16` with `DOMAIN_MIN`/`DOMAIN_MAX` headers, 4096 RGB triplets, red-index-fastest ordering (the FFmpeg `.cube` convention).

| File | Bytes | Intent |
|---|---|---|
| `cinematic_warm.cube` | 110,717 | pre-existing (Report 144) |
| `moody_teal.cube` | ~110,700 | teal shadows, warm highlights, mild S-curve |
| `vintage_film.cube` | ~110,700 | warm golden cast, lifted blacks, soft highlight rolloff |
| `high_contrast_bw.cube` | ~110,700 | Rec.601 luma + S-curve contrast, neutral gray output |

### Numeric validation (measured, not asserted)

Sampled endpoint/midpoint values read back out of the generated files:

| Preset | black (0,0,0) | mid (0.5 gray) | white (1,1,1) | Character |
|---|---|---|---|---|
| `cinematic_warm` | `(0.000, 0.000, 0.033)` | `(0.537, 0.535, 0.532)` | `(1.000, 1.000, 0.945)` | warm highlight, slight blue lift |
| `moody_teal` | `(0.000, 0.012, 0.045)` | `(0.538, 0.538, 0.538)` | `(1.000, 1.000, 0.940)` | black point preserved, teal shadow cast |
| `vintage_film` | `(0.065, 0.049, 0.028)` | `(0.561, 0.517, 0.399)` | `(0.993, 0.926, 0.724)` | lifted black, strong warm cast |
| `high_contrast_bw` | `(0.000, 0.000, 0.000)` | `(0.553, 0.553, 0.553)` | `(1.000, 1.000, 1.000)` | true neutral, contrast-bent |

Additional measured checks:
- All 4 files: `4096/4096` data rows, every component within `[0.0, 1.0]`.
- `high_contrast_bw`: every row satisfies `r == g == b` exactly (fully desaturated).
- `moody_teal`: at 0.05 gray → `(0.014, 0.067, 0.094)` (blue > red, i.e. teal shadows); at 0.90 gray → `(0.979, 0.954, 0.899)` (red ≥ blue, i.e. warm highlights).
- `vintage_film`: black is lifted (all channels > 0) and mid-gray has `r > b` (warm).

### Note on a corrected first attempt

The first `moody_teal` draft lifted the black point to `(0.000, 0.025, 0.100)` — a visible blue haze on true blacks, which is not a "moody" grade but a broken black level. It was regenerated with a shadow term that decays to zero at `luma = 0`, giving `(0.000, 0.012, 0.045)`.

---

## 3. UI Implementation (`modifiers_card.dart`)

New private widget `_LutSelectorRow`, inserted in the `FRAMING & TEXTURE` accordion after "Micro-Noise Overlay":

- Header: `Icons.color_lens_outlined` + "Color Grading LUT" / "3D LUT color filter preset (.cube)".
- Body: horizontally scrollable row of `_PresetChip`s — `None`, `Cinematic Warm`, `Moody Teal`, `Vintage Film`, `High Contrast B&W`.
- Selection writes `provider.lutName = key` (which persists via `SettingsService.setLutName`) and immediately calls `provider.requestFilteredPreviewDebounced(immediate: true)`.
- `textureActive` now counts an active LUT (`provider.lutName.isNotEmpty`) and the accordion `totalCount` was raised `5 → 6`.

Styling reuses the existing `_PresetChip` (already theme-aware via `mintSage`/`forestDeep`, `obsidianDark`/`hairlineBorder`) rather than introducing a new visual language — no new colors, no new spacing scale.

**Preview caveat (honest):** `requestFilteredPreviewDebounced` renders through `FilterBuilders.buildPreviewFilterChain`, which has **no `lutPath` parameter**. So the debounce fires and the frame re-renders, but the preview image will **not** show the LUT. Only the final export applies it. This is a pre-existing limitation of the preview chain, not something this report introduced.

---

## 4. P1 Defect Found — LUT Pipeline Was Dead Code

### How it was found

The task required proving that selecting an option "updates `lutName` and triggers preview debounce". Tracing that call graph end-to-end surfaced this:

1. `provider.lutName` is set by the new UI — **first and only writer**.
2. `FfmpegService.processVideo({... String? lutName ...})` accepts it and calls `FfmpegFileHelper.resolveLutPath(lutName)` → `buildCommand(lutPath: ...)` → `FilterBuilders` `lut3d='...'`. The plumbing downstream is correct.
3. **But no caller ever passed `lutName`.** A repo-wide scan for the named argument `lutName:` returned **zero** matches in `lib/`. Both export entry points — `ProcessingScreen._processWithNative` and `BatchQueueProvider._executeBatchItem` — omitted it, so `lutName` was always `null`, `resolveLutPath` always returned `null`, and no `lut3d` filter was ever emitted.
4. `SettingsService.getLutName()` also had **zero call sites**, so even the *persisted* value was never read back into the provider on startup — the selection would not survive an app restart.

Net effect before this report: Reports 144 and 145 shipped a fully-built pipeline that could never execute. Selecting any preset changed a stored string that nothing consumed.

### What was fixed (minimal, in scope)

`lib/features/process/screens/processing_screen.dart` — one argument added to the existing `processVideo` call:

```dart
activeVisualEffects: provider.activeVisualEffects,
lutName: provider.lutName,          // <-- added
onProgress: ...
```

The single-video export path now applies the selected LUT.

### What is **not** fixed (deliberately, out of whitelist)

Both remaining gaps live in files this task explicitly forbids touching (`lib/core/providers/`), plus `processing_screen.dart`'s sibling:

| Gap | Location | Impact |
|---|---|---|
| Batch export ignores the LUT | `lib/core/providers/batch_queue_provider.dart:141-177` (`_executeBatchItem`) — no `lutName:` argument | Queued/batch renders silently skip color grading |
| Selection not restored on restart | `UniquifierProvider._initResolution` never calls `SettingsService.getLutName()` | LUT resets to `''` (None) every app launch, so persisted state is write-only |

Registered as **`AUDIT-20261115-038`** (P1, correctness) with status `active` and an explicit `remaining_work` field. It is deliberately **not** marked resolved.

---

## 5. Verification

| Check | Command | Result |
|---|---|---|
| Static analysis | `dart analyze --fatal-infos` | **exit 0**, "No issues found!" |
| Test suite | `flutter test` | **229/229 passed** |
| LUT asset count | `ls assets/luts/` | 4 `.cube` files + `.gitkeep` |
| Cube structural validity | script over all 4 files | `4096/4096` rows, all values in `[0,1]` |
| Backend untouched | `git diff -w --exit-code lib/core/services/` | **exit 0** |
| Providers untouched | `git diff -w --stat -- lib/core/providers/` | empty |
| Formatting | `dart format` on `modifiers_card.dart` | reformatted, then re-verified analyze/test |

Note: `modifiers_card.dart` initially failed `dart format --set-exit-if-changed`. It was reformatted before the final analyze/test run, so the green results above correspond to the committed formatting.

---

## 6. Files Touched

**Added**
- `assets/luts/moody_teal.cube`
- `assets/luts/vintage_film.cube`
- `assets/luts/high_contrast_bw.cube`
- `0ai_context/reports/147-feat-lut-preset-expansion.md`

**Modified**
- `lib/features/process/widgets/modifiers_card.dart` — `_LutSelectorRow`, `textureActive`, `totalCount 5→6`
- `lib/features/process/screens/processing_screen.dart` — `lutName: provider.lutName` (the P1 fix)
- `0ai_context/findings.json` — added `AUDIT-20261115-038` (active)
- `0ai_context/reports/INDEX.md`, `0ai_context/index.json` (`next_report_number = 148`)
- `0ai_context/STATE.md`, `0ai_context/HANDOFF.md`, `0ai_context/SEED.md`, `0ai_context/handoff-diff.json`

**Not modified** (per task constraints): anything under `lib/core/services/`, `lib/core/providers/`, or `test/`.
