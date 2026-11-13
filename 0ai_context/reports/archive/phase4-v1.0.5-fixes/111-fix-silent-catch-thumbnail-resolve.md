# Report 111 — Fix Silent Catch in `_ThumbnailBadgeState._resolveThumbnail`

- Date: 2026-11-12
- Finding: AUDIT-20261108-031 (P3, quality)
- Target file: `lib/features/history/widgets/history_item_card.dart`
- Method: `_ThumbnailBadgeState._resolveThumbnail`
- Status: RESOLVED

## Starting State

`git status --short` before the change:

```
 M lib/features/process/widgets/modifiers_card.dart
?? 0ai_context/reports/110-fix-i18n-modifiers-card.md
```

These are the uncommitted results of report 110; they were left untouched.

## Change

Before:

```dart
    } catch (_) {
    } finally {
      _isExtracting = false;
    }
```

After:

```dart
    } catch (e) {
      debugPrint(
        '[HistoryItemCard] thumbnail resolve failed: ${e.runtimeType}',
      );
    } finally {
      _isExtracting = false;
    }
```

- The empty catch no longer swallows failures silently.
- `debugPrint` was already available via the existing `package:flutter/material.dart` import; no new imports.
- The `finally { _isExtracting = false; }` clause is unchanged.

## Privacy

The log statement contains only a static tag (`[HistoryItemCard]`), a static message, and `${e.runtimeType}`. It does not include `e.toString()`, file paths, basenames, or any user identifier, matching the pattern endorsed in report 107 §4.

## Formatting Note

The `debugPrint(...)` call is 82 columns when written on one line, so `dart format` wrapped it across three lines as instructed. The resulting diff is +4/−1 rather than +2/−1; all added lines belong to the single log statement.

## Verification

- `dart analyze --fatal-infos` → exit 0 (`No issues found!`)
- `flutter test` → 216/216 passed, exit 0 (no Impeller/SkSL failures)
- `dart format --set-exit-if-changed .` → exit 0, 124 files, 0 changed
- `catch (_)` grep → 0 hits
- `thumbnail resolve failed` grep → 1 hit
- Non-comment hunk lines from `git diff` → exactly:
  ```
  -    } catch (_) {
  +    } catch (e) {
  +      debugPrint(
  +        '[HistoryItemCard] thumbnail resolve failed: ${e.runtimeType}',
  +      );
  ```
  No other code lines changed.
- Scoped diff stat (`-- lib/features/history/widgets/history_item_card.dart`) → 1 file changed, 4 insertions(+), 1 deletion(-)

## Final `git status --short`

```
 M lib/features/history/widgets/history_item_card.dart
 M lib/features/process/widgets/modifiers_card.dart
?? 0ai_context/reports/110-fix-i18n-modifiers-card.md
?? 0ai_context/reports/111-fix-silent-catch-thumbnail-resolve.md
```

`modifiers_card.dart` and report 110 are the still-uncommitted output of report 110, not part of this fix.

## Next

Fix #3: AUDIT candidate 032 — path redaction in `ErrorScreen` (`lib/features/error/error_screen.dart`), report 112.
