# Report 116 — Narrow Raw `$e` in UI Sites (Batch 3/3)

- Date: 2026-11-12
- Finding: AUDIT-20261108-030 (P2, privacy) — batch 3 of 3
- Target files:
  - `lib/features/process/screens/process_screen.dart`
  - `lib/features/process/screens/success_screen.dart`
- Status: RESOLVED — AUDIT-20261108-030 is now fully closed (14/14 sites)

## Starting State

`git status --short` was empty; HEAD `af5a7c6` (`fix(privacy): narrow UI $e to generic copy (batch 2/3)`).

## Sites Changed

| # | File | Function | Line | Before | After |
|---|---|---|---|---|---|
| 1 | `process_screen.dart` | `_pickVideo` | 50 | `content: Text('Error selecting file: $e'),` | `content: const Text('Failed to open file picker.'),` |
| 2 | `success_screen.dart` | `_shareVideo` | 127 | `content: Text('Share error: $e'),` | `content: const Text('Failed to share video.'),` |
| 3 | `success_screen.dart` | `_openGallery` | 152 | `content: Text('Open error: $e'),` | `content: const Text('Failed to open video.'),` |

No other lines changed. Surrounding `ScaffoldMessenger.of(context).showSnackBar(...)` calls and `backgroundColor` arguments were left exactly as-is.

## Design Notes

- **Site 1** is worded differently on purpose: `_pickVideo` wraps `FilePicker.platform.pickFiles()`, so a thrown error means the picker could not be opened — not that a selected file failed. Copy is therefore `'Failed to open file picker.'`.
- **Sites 2 and 3** reuse the exact strings established in batch 2 (report 115) — `'Failed to share video.'` and `'Failed to open video.'` — so the same failure has identical wording across `recent_history_screen.dart` and `success_screen.dart`.
- `const` was applied to all three `Text(...)` widgets; the strings are now literals, so this is valid and `dart analyze --fatal-infos` reports no new `prefer_const_constructors` warnings.
- `'Unable to open: ${res.message}'` at `success_screen.dart:143` was left untouched — it comes from an `OpenFilex` result object, not from a raw `$e`.
- Confirmed there are no duplicate share/open catch blocks in `success_screen.dart`; lines 127 and 152 were the only two.

## AUDIT-20261108-030 Closure

| Batch | Report | Sites | Location |
|---|---|---|---|
| 1 | 114 | 5 | `main.dart` (3 `debugPrint`), `user_news_bookmark_service.dart` (2 `debugPrint`) |
| 2 | 115 | 6 | `recent_history_screen.dart` (1 `debugPrint`, 1 `_error`, 4 `AppToast`) |
| 3 | 116 | 3 | `process_screen.dart` (1 SnackBar), `success_screen.dart` (2 SnackBars) |
| **Total** | | **14/14** | |

## Verification

- `dart analyze --fatal-infos` → exit 0 (`No issues found!`). The first attempt exceeded a 300 s tool timeout without producing output; a retry with a larger timeout completed cleanly with exit 0.
- `flutter test` → 224/224 passed, exit 0
- `dart format --set-exit-if-changed .` → exit 0, 126 files, 0 changed
- Raw `$e` in either target file → 0 hits
- `'Failed to open file picker'` in `process_screen.dart` → 1 hit (line 50)
- `'Failed to share video'` in `success_screen.dart` → 1 hit (line 127)
- `'Failed to open video'` in `success_screen.dart` → 1 hit (line 152)
- `git diff -w --exit-code` → exit 1 (UI text changed, not whitespace-only)

### Repo-wide close check (5 files)

Pattern: `\$e[^a-zA-Z{]|_error = e\.toString`

Result: **2 hits**, both of which are the explanatory comments mandated by batch 1:

```
main.dart:24:                                // Raw $e can echo FFmpegKit / plugin channel identifiers on some devices.
user_news_bookmark_service.dart:27:          // $e from SharedPreferences can carry plugin channel noise.
```

There are **zero** raw `$e` interpolation sites remaining. The prompt expected 0 hits; the two comment lines match the regex because the prompt itself required that literal `$e` text be written into the comments in report 114. This is the same known discrepancy recorded in report 114, documented rather than hidden. If a literally-empty grep is required later, the comments should be reworded (e.g. "raw exception text" instead of `$e`).

`git diff --stat`:

```
 lib/features/process/screens/process_screen.dart | 2 +-
 lib/features/process/screens/success_screen.dart | 4 ++--
 2 files changed, 3 insertions(+), 3 deletions(-)
```

## Final `git status --short`

```
 M lib/features/process/screens/process_screen.dart
 M lib/features/process/screens/success_screen.dart
?? 0ai_context/reports/116-fix-narrow-ui-batch-3.md
```

## Next

- Mark `AUDIT-20261108-030` resolved in `0ai_context/findings.json` (`resolved_by: "reports 114-116"`) and refresh HANDOFF §10/§9 (§11) accordingly.
- Remaining active findings after this: 020, 024, 027, 028, 035.
