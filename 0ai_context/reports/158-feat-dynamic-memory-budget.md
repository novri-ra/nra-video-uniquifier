# Report 158 — feat: Dynamic Memory Budget & Complexity Scoring System

## Metadata
- **Date**: 2026-11-15
- **Type**: feat
- **Task**: feat-dynamic-memory-budget-158
- **Status**: done
- **Tests**: 229/229 passed
- **Analyze**: 0 issues (clean exit 0)

---

## Summary

Implemented a dynamic complexity scoring system (Mathematical Complexity Scoring) to prevent Out of Memory (OOM) crashes across varying device hardware tiers:

1. **`DeviceCapabilityService.calculateComplexityScore`**:
   - Calculates a mathematical complexity score based on resolution, visual effects, and audio/evasion toggles:
     - Base resolution: 1080p = 10, 2K = 30, 4K = 60.
     - Heavy effects: +15 for `enableBlurredCanvas`, +15 per active visual effect (`activeEffectsCount * 15`).
     - Processing passes: +10 for `enableDeepAntiFingerprint`, +5 for `enableEnhanceAndDenoise`.

2. **`DeviceSpecs.canHandleComplexity` & `maxComplexityScore`**:
   - Evaluates dynamic RAM budget thresholds against `DeviceSpecs.availRamGb`:
     - `< 4GB RAM`: max score 40.
     - `4-6GB RAM`: max score 70.
     - `> 6GB RAM`: max score 100.
   - Exposes `canHandleComplexity(int score)` on `DeviceSpecs` and `DeviceCapabilityService`.

3. **`FfmpegService` Integration**:
   - Replaced the static resolution/tier heuristic in `FfmpegService._isHighOomRisk` with dynamic complexity score evaluation.
   - Computes score in `processVideo` and provides clear diagnostic error messaging when the score exceeds the device RAM budget:
     `"Skor kompleksitas $complexityScore melebihi batas perangkat Anda ($maxScore). Kurangi efek atau resolusi."`

---

## Files Modified

| File | Change |
|------|--------|
| `lib/core/services/device_capability_service.dart` | Added `maxComplexityScore` & `canHandleComplexity` to `DeviceSpecs`; added static `calculateComplexityScore`, `canHandleComplexity`, and `getMaxComplexityScore` to `DeviceCapabilityService`. |
| `lib/core/services/ffmpeg_service.dart` | Updated `processVideo` to compute dynamic complexity score before render; updated `_isHighOomRisk` to validate score against device limit. |

---

## Verification

```bash
dart analyze --fatal-infos
# -> Analyzing nra_video_uniquifier... No issues found!

flutter test
# -> 229/229 passed.

grep -n "calculateComplexityScore" lib/core/services/device_capability_service.dart
# -> line 165
```

---

## Context Mapping Sync
Synchronized: INDEX.md, index.json (next_n=159), STATE.md, HANDOFF.md, SEED.md, findings.json, handoff-diff.json.
