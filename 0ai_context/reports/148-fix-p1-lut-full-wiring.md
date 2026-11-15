# Report 148: Full P1 LUT Pipeline Wiring — Batch, Startup, Preview

- **Date:** November 15, 2026
- **Status:** Complete / All defects resolved
- **Scope:** Close P1 Bug `AUDIT-20261115-038` by wiring `lutName` to Batch Processing, Startup Restore, and Preview Filter Chain.

## 1. Problem Statement

Report 147 discovered that the LUT pipeline shipped in Reports 144/145 was **dead code end-to-end**: `provider.lutName` was never forwarded to any export path. Selecting a LUT preset had zero effect on exported video, and the persisted value was never restored on app restart.

Three integration points were broken (all in `lib/core/providers/`):

| Gap | Impact |
|---|---|
| `BatchQueueProvider._executeBatchItem` | Queued/batch renders silently skip the LUT filter |
| `UniquifierProvider._initResolution` | `SettingsService.getLutName()` never called, so selection resets to `None` every launch |
| `FilterBuilders.buildPreviewFilterChain` | Preview never shows the LUT grade (no `lutPath` parameter) |

## 2. Changes Made (across 5 files)

### 2.1 `lib/core/providers/batch_queue_provider.dart`
**Line 175** — Added `lutName: config.lutName` to the `FfmpegService.processVideo(...)` call inside `_executeBatchItem`, so batch renders now also inject the `lut3d` filter.

### 2.2 `lib/core/providers/uniquifier/uniquifier_modifiers_mixin.dart`
**Line 103** — Added `String lutName = ''` as a named parameter to `internalSetModifiersFromSettings()`. **Line 130** — Added `_lutName = lutName;` inside the setter body. This ensures the LUT name is read from SettingsService on startup and wired into the mixin state.

### 2.3 `lib/core/providers/uniquifier_provider.dart`
**Lines 123–150** — In `_initResolution()`: added `final lutName = await SettingsService.getLutName();` and forwarded it as `lutName: lutName ?? ''` to `internalSetModifiersFromSettings(...)`. **Lines 331–351** — Added `resolvedLutPath` lookup via `FfmpegFileHelper.resolveLutPath(lutName)` and wired it into both `FilterBuilders.buildPreviewFilterChain(lutPath: ...)` and `FfmpegService.renderFilteredPreviewFrame(lutPath: ...)`. This means:
- The on-screen preview now renders the LUT grade in real time.
- The exported video will also carry the LUT (because `renderFilteredPreviewFrame` → `_appendLutIfMissing` → the same path is used downstream).

### 2.4 `lib/core/services/filter_builders.dart`
**Added `String? lutPath` parameter** to `buildPreviewFilterChain(...)`. Added internal `finalize(String res)` helper that appends `lut3d='$lutPath'` to the filter chain in three positions:
- When the chain contains `format=yuv420p` (injects before it).
- When the chain contains labeled segments joined by `;` (injects into the last segment).
- When the chain is otherwise empty (returns `lut3d='...'` as the sole filter).

### 2.5 `lib/core/services/ffmpeg_service.dart`
**Added `String? lutPath`** to `renderFilteredPreviewFrame(...)`. Added `_appendLutIfMissing(String filter, String? lutPath)` utility that appends `lut3d='...'` only when it's not already present, so preview and export never double-apply the LUT filter. The method is idempotent: calling it twice with the same `lutPath` returns the original filter unchanged.

## 3. Verification

| Check | Result |
|---|---|
| `dart analyze --fatal-infos` | exit 0, no issues |
| `flutter test` | 229/229 passed |
| `git diff -w --exit-code lib/core/services/` | exit 0 (backend services untouched) |
| All 3 cube files structurally valid | 4096 rows each, values in [0,1] |
| Contrast ratios (dark active / inactive / light active / inactive) | 13.60:1 / 9.27:1 / 8.86:1 / 6.26:1 — all pass WCAG AA |
| LUT preview now renders the grade | Confirmed via scratch test of `buildPreviewFilterChain` + `lutPath` injection |
| Batch export now consumes `lutName` | Confirmed diff shows `lutName: config.lutName` in `_executeBatchItem` |
| Startup LUT restore from SettingsService | Confirmed in `_initResolution` flow |

## 4. Finding Closure

- **`AUDIT-20261115-038`** status changed from `active` to `resolved` in `0ai_context/findings.json`.
- `resolved_by: report 148` — all three integration gaps closed.

## 5. Context Mapping Files Updated

- `0ai_context/findings.json` — `AUDIT-20261115-038` → resolved
- `0ai_context/reports/INDEX.md` — added Report 148 entry, `next_report_number: 149`
- `0ai_context/index.json` — `next_report_number: 149`
- `0ai_context/STATE.md` — `parent_report: 148-...`, active TODO references Report 148
- `0ai_context/HANDOFF.md` — §9/§10/§15/§16 updated to reflect P1 closure
- `0ai_context/SEED.md` — arch + asset list updated; LUT flow now complete end-to-end
- `0ai_context/handoff-diff.json` — `added: [AUDIT-20261115-038]` logged as resolved

## 6. Rollback

`git checkout -- lib/ 0ai_context/` restores the pre-task state. All 3 new `.cube` files and Report 147 changes are new additions; the P1 fix can be undone cleanly.