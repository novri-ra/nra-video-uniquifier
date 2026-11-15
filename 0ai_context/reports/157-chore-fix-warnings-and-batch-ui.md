# Report 157 — chore: Fix BuildContext Async Warnings & Add Batch LUT Indicator

## Metadata
- **Date**: 2026-11-15
- **Type**: chore
- **Task**: chore-fix-warnings-and-batch-ui-157
- **Status**: done
- **Tests**: 229/229 passed
- **Analyze**: 0 issues (clean exit 0)

---

## Summary

1. **Remediated 4 `use_build_context_synchronously` info warnings** in `lib/features/process/widgets/modifiers_card.dart`:
   - Added `if (!context.mounted) return;` guards after async `FilePicker.platform.pickFiles`, `File(absPath).length()`, `File(absPath).readAsBytes()`, `File(absPath).copy()`, and in the `catch (e)` block prior to invoking `ScaffoldMessenger.of(context)`.
   - Result: `dart analyze --fatal-infos` dropped from 4 issues to **0 issues** (clean analysis).

2. **Added Active LUT Indicator Chip** in `lib/features/process/screens/batch_processing_screen.dart`:
   - Extracted LUT name formatting via `_formatLutName()` (normalizes paths and strips directory separators).
   - Read active LUT via `context.watch<UniquifierProvider>().lutName`.
   - Rendered a compact indicator chip below the app bar with `AppColors.mintSage` / `AppColors.forestDeep` styling and `Icons.color_lens_outlined`, displaying `'LUT: <lutName>'` when active.

---

## Files Modified

| File | Change |
|------|--------|
| `lib/features/process/widgets/modifiers_card.dart` | Added `if (!context.mounted) return;` guards across all async boundaries before `ScaffoldMessenger.of(context)`. |
| `lib/features/process/screens/batch_processing_screen.dart` | Added `_formatLutName()` helper and active LUT indicator chip reading `UniquifierProvider.lutName`. |

---

## Verification

```bash
dart analyze --fatal-infos
# -> Analyzing nra_video_uniquifier... No issues found!

flutter test
# -> 229/229 passed.

grep -n "context.mounted" lib/features/process/widgets/modifiers_card.dart
# -> lines 724, 730, 744, 763, 770
```

---

## Context Mapping Sync
Synchronized: INDEX.md, index.json (next_n=158), STATE.md, HANDOFF.md, SEED.md, findings.json, handoff-diff.json.
