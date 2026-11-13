# Report 114 — Narrow Raw `$e` in Log-Only Sites (Batch 1/3)

- Date: 2026-11-12
- Finding: AUDIT-20261108-030 (P2, privacy) — batch 1 of 3
- Target files:
  - `lib/main.dart`
  - `lib/features/microstock/services/user_news_bookmark_service.dart`
- Status: RESOLVED

## Starting State

`git status --short` was empty; HEAD `079a04e` (`chore(context): mapper refresh after reports 105-112`).

## Sites Changed

| File | Line | Before | After |
|---|---|---|---|
| `lib/main.dart` | 25 | `debugPrint('[Main] FFmpeg init failed: $e');` | `debugPrint('[Main] FFmpeg init failed: ${e.runtimeType}');` |
| `lib/main.dart` | 32 | `debugPrint('[Main] Cache cleanup failed: $e');` | `debugPrint('[Main] Cache cleanup failed: ${e.runtimeType}');` |
| `lib/main.dart` | 40 | `debugPrint('[Main] Service init failed: $e');` | `debugPrint('[Main] Service init failed: ${e.runtimeType}');` |
| `user_news_bookmark_service.dart` | 28–30 | `debugPrint('[UserNewsBookmarkService] bookmark init failed: $e');` | `debugPrint('[UserNewsBookmarkService] bookmark init failed: ${e.runtimeType}');` |
| `user_news_bookmark_service.dart` | 60–62 | `debugPrint('[UserNewsBookmarkService] bookmark save failed: $e');` | `debugPrint('[UserNewsBookmarkService] bookmark save failed: ${e.runtimeType}');` |

One explanatory comment was added above the first log in each file only:

- `lib/main.dart:24`: `// Raw $e can echo FFmpegKit / plugin channel identifiers on some devices.`
- `user_news_bookmark_service.dart:27`: `// $e from SharedPreferences can carry plugin channel noise.`

The existing `// Offline fallback: keep in-memory set` comment was preserved.

## Exception-Type Assessment

All five sites sit around plugin/platform calls, not filesystem operations that embed user paths:

- `FFmpegKitConfig.setSessionHistorySize` — FFmpegKit platform channel; failures surface as `MissingPluginException` / `PlatformException` with method/channel names.
- `StorageService.pruneStaleFiles` + `SettingsService.purgeTempCache` — both catch their own `FileSystemException` internally (storage_service.dart:25/52/59/71, settings_service.dart:404); the `main.dart` catch is defense-in-depth for unexpected plugin/platform errors.
- `NotificationService.initialize` / `requestPermission` + `ConnectivityService.initialize` — plugin channels; errors can include permission identifiers.
- `SharedPreferences.getInstance` / `setStringList` — platform channel; `MissingPluginException` carries the channel name.

No site legitimately needs the raw `$e` text for debugging beyond what `${e.runtimeType}` plus a stack trace provides, so all five were narrowed.

## Verification

- `dart analyze --fatal-infos` → exit 0 (`No issues found!`)
- `flutter test` → 224/224 passed, exit 0
- `dart format --set-exit-if-changed .` → exit 0, 126 files, 0 changed
- Raw `$e` in `debugPrint` calls (both files) → 0 hits
- `e.runtimeType` in `lib/main.dart` → 3 hits
- `e.runtimeType` in `user_news_bookmark_service.dart` → 2 hits
- `git diff -w --exit-code` → exit 1 (log text changed; output recorded)

Note on the prompt's `$e` grep: the exact regex `\$e(?:[^a-zA-Z]|$)` also matches the two newly added explanatory comments (`// Raw $e ...`, `// $e from SharedPreferences ...`), so it reports 2 hits instead of 0. The meaningful check — raw `$e` inside `debugPrint` — is 0. The comments are mandated by the prompt, so they were kept verbatim.

`git diff --stat`:

```
 lib/features/microstock/services/user_news_bookmark_service.dart | 9 +++++++--
 lib/main.dart                                                    | 7 ++++---
 2 files changed, 11 insertions(+), 5 deletions(-)
```

## Final `git status --short`

```
 M lib/features/microstock/services/user_news_bookmark_service.dart
 M lib/main.dart
?? 0ai_context/reports/114-fix-narrow-log-batch-1.md
```

## Next

Batch 2/3: report 115 — 6 UI-visible `$e` sites in `recent_history_screen.dart`.
