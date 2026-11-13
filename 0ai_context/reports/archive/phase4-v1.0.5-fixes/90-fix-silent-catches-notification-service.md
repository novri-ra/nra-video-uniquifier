# Fix Report 90 — Silent Catches in NotificationService

**Date:** 2026-11-08
**Type:** Manual Fix (AUDIT-20261108-004, P1)
**Status:** Complete

## 1. Background

HANDOFF §10 finding `AUDIT-20261108-004` reported 6 empty `catch (_) {}` blocks in
`lib/core/services/notification_service.dart`. They covered permission requests, the plugin
fallback path, progress-notification cancellation, and a settings read, so a user whose
completion alerts stopped arriving had no diagnostic trail at all.

## 2. What Was Done

Six empty catches replaced with `debugPrint`. Nothing else changed.

| Line (pre-fix) | Enclosing method | New log message |
|----------------|------------------|-----------------|
| 65 | `_registerSystemChannelPing` | `[NotificationService] cancel ping failed: $e` |
| 156 | `_ensurePermission` | `[NotificationService] permission request failed: $e` |
| 172 | `requestPermission` | `[NotificationService] requestPermission failed: $e` |
| 244 | `_safeShow` (inner fallback attempt) | `[NotificationService] show fallback failed: $e` |
| 295 | `cancelProgressNotification` | `[NotificationService] cancel progress failed: $e` |
| 333 | `showCompleteNotification` (sound setting read) | `[NotificationService] sound setting read failed: $e` |

- Prefix is uniform: `[NotificationService]`, matching reports 88 and 89.
- No `rethrow` and no new `try`/`catch`. The diff replaces 6 catch headers and adds 6 log lines.
- `_canRun`, `_testOverride`, `_initialized`, `testOverride`, `initialized`, all notification IDs
  and all channel ID constants are untouched.
- `package:flutter/foundation.dart` was already imported at line 3.

### Privacy

No log message interpolates `title`, `body`, `id`, or any filesystem path. Only the operation
label and `$e` are logged, so notification content and user paths never reach logcat.

## 3. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Target test | `flutter test test/notification_service_test.dart` | exit 0, `All tests passed!` (11 tests) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Empty catches remaining | pattern scan on the file | 0 |
| Diff scope | `git diff --stat` | 1 file, 18 insertions, 6 deletions |
| Deletions audit | `git diff` removed lines | 6, all of them the literal `} catch (_) {}` lines |

The target test file asserts specific `MethodChannel` calls (`show`, `cancel`,
`createNotificationChannel`), and it passed unchanged, so delivery behavior is identical. Its
output now also shows `[NotificationService] sound setting read failed: MissingPluginException(...)`,
which is the intended new diagnostic in the test environment where `shared_preferences` has no
platform implementation.

## 4. Note for the Next Mapper Run

The mapper should detect this report and drop `AUDIT-20261108-004` from the findings inventory.
47 of the original 85 empty catches remain in `lib/` (verified by pattern scan after this fix).
Next clusters by size: `AUDIT-20261108-003` (9, news service), `-005` (5, history service),
`-018` (3, storage), `-017` (3, settings), then single-catch files such as `-006` (user interest)
and `-016` (locale).
