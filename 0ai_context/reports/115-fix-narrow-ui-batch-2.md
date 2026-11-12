# Report 115 — Narrow Raw `$e` in UI Sites (Batch 2/3)

- Date: 2026-11-12
- Finding: AUDIT-20261108-030 (P2, privacy) — batch 2 of 3
- Target file: `lib/features/history/screens/recent_history_screen.dart`
- Status: RESOLVED

## Starting State

`git status --short` was empty; HEAD `6b0f98f` (`fix(privacy): narrow log $e to runtimeType (batch 1/3)`).

## Sites Changed

| # | Function | Line | Before | After |
|---|---|---|---|---|
| 1 | `_checkStoragePermissionOnMount` | 88–91 | `debugPrint('[RecentHistoryScreen] storage permission prompt failed: $e');` | `debugPrint('<same prefix> ${e.runtimeType}');` (wrapped by formatter) |
| 2 | `_loadHistory` | 218 | `_error = e.toString();` | `_error = '${e.runtimeType}';` |
| 3 | `_deleteSelectedItems` | 337 | `message: 'Error deleting videos: $e',` | `message: 'Unexpected error while deleting videos.',` |
| 4 | `_deleteItem` | 407 | `message: 'Error deleting video: $e',` | `message: 'Unexpected error while deleting video.',` |
| 5 | `_shareItem` | 420–424 | `AppToast.show(context, message: 'Share error: $e', isError: true);` | `AppToast.show(context, message: 'Failed to share video.', isError: true);` |
| 6 | `_openItem` | 442 | `AppToast.show(context, message: 'Open error: $e', isError: true);` | `AppToast.show(context, message: 'Failed to open video.', isError: true);` |

Site 1 keeps the pre-existing `// Fallback: If SharedPreferences fails, do not spam dialog` comment.

## Design Notes

- **Site 2 (`_loadHistory`)**: the renderer at line 506 already prefixes with `'Error loading history: '`, so the final UI string is `Error loading history: FileSystemException` — informative without duplicating the prefix or leaking an absolute path. This matches the intent of the prompt while avoiding a second hard-coded prefix.
- **Sites 3 and 4**: `HistoryService.deleteExportItemsDetailed` / `deleteItem` already return bool/list for normal permission failures (report 107 §2), so these `catch` clauses fire only on unexpected exceptions. Copy therefore reads "Unexpected error while deleting…", not a permission hint (the permission hint already lives in the success-branch fallbacks).
- **Sites 5 and 6**: share/open failures now show generic copy. Note that `_openItem` still contains `'Unable to open: ${res.message}'` inside the success-branch failure handler; that string comes from an `OpenFilex` result object, not from a raw `$e`, so it is out of scope for this batch and left untouched.

## `_verifyStoragePermissionOnResume` — Untouched

Confirmed unchanged and still uses `${e.runtimeType}` (line 67).

## Verification

- `dart analyze --fatal-infos` → exit 0 (`No issues found!`)
- `flutter test` → 224/224 passed, exit 0
- `dart format --set-exit-if-changed .` → exit 0, 126 files, 0 changed
- Raw `$e` in `debugPrint` → 0 hits
- Raw `$e` in `AppToast` → 0 hits
- `_error = e.toString` → 0 hits
- `e.runtimeType` → 3 hits (lines 67, 90, 218)
- `git diff -w --exit-code` → exit 1 (log/UI text changed, not whitespace-only)

`git diff --stat`:

```
 lib/features/history/screens/recent_history_screen.dart | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)
```

The `+13/−6` count (instead of the estimated `+6/−6`) reflects `dart format` re-wrapping three long single-line calls into multi-line form (site 1, site 5, and the site 6 line stays single but site 5 expands). Only the six intended replacements are present — verified line-by-line with `git diff | grep -E '^[+-][^+-]'`.

## Final `git status --short`

```
 M lib/features/history/screens/recent_history_screen.dart
?? 0ai_context/reports/115-fix-narrow-ui-batch-2.md
```

## Next

Batch 3/3: report 116 — `process_screen.dart` (1 site) + `success_screen.dart` (2 sites).
