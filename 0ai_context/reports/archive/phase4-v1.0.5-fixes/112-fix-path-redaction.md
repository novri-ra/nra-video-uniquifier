# Report 112 — Expand Filesystem Path Redaction in `ErrorScreen`

- Date: 2026-11-12
- Finding: AUDIT-20261108-032 (P3, privacy)
- Target files:
  - `lib/core/utils/path_redactor.dart` (new)
  - `lib/features/process/screens/error_screen.dart` (modified)
  - `test/path_redactor_test.dart` (new)
- Status: RESOLVED

## Starting State

`git status --short` was empty (clean tree at commit `4dfbf33`).

## Old vs New Matcher

Old (private method in `_TelemetryLogBox`):

```dart
RegExp(r'/storage/emulated/0/[^\s]+')
```

New (top-level utility in `lib/core/utils/path_redactor.dart`):

```dart
final RegExp _pathPattern = RegExp(
  r'(^|[\s"(\[=,:;\\])'
  r'((?:'
  r'[A-Za-z]:[\\/][^\s")\]<>|]*'
  r'|\/(?:storage|data|sdcard|mnt|system|proc|home)\/[^\s")\]<>|]*'
  r'))',
  caseSensitive: false,
);

String redactFileSystemPaths(String text) {
  if (text.isEmpty) return text;
  return text.replaceAllMapped(
    _pathPattern,
    (m) => '${m.group(1)!}<external storage>/...',
  );
}
```

Covered roots: `/storage/`, `/data/`, `/sdcard/`, `/mnt/`, `/system/`, `/proc/`, `/home/`, plus Windows drive-letter paths (`C:\...`, `C:/...`). The replacement string remains `<external storage>/...` so D6-02 is unaffected.

The boundary group `(^|[\s"(\[=,:;\\])` is the key to URL safety: a path-looking segment is only redacted when it starts a string, follows whitespace, or follows one of `" ( [ = , : ; \`. A segment preceded by an alphanumeric character (for example `/data/` inside `example.com/data/foo`) is left alone.

## Widget Rewiring

- Added `import '../../../core/utils/path_redactor.dart';`.
- Removed the six-line `_redactPath` method from `_TelemetryLogBox`.
- Replaced the single call site: `_redactPath(raw)` → `redactFileSystemPaths(raw)`.
- Widget tree, styling, and layout are byte-identical; the only other diff lines are the import and the removed method.

## Tests Added

`test/path_redactor_test.dart` — 8 tests under `group('redactFileSystemPaths', ...)`:

1. `/storage/emulated/0/Movies/out.mp4` → `<external storage>/...`
2. `cache=/data/user/0/pkg/cache/thumb.jpg` → `cache=<external storage>/...`
3. `see /sdcard/DCIM/v.mp4 now` → `see <external storage>/... now`
4. `C:\Users\Admin\v.mp4` → `<external storage>/...`
5. `https://news.google.com/articles/abc` → unchanged
6. `https://example.com/data/foo` → unchanged
7. `error: /data/local/tmp/ffmpeg exited` → `error: <external storage>/... exited`
8. `<external storage>/...` → unchanged (no double redaction)

URL-preservation results:

- `https://news.google.com/articles/abc` → `https://news.google.com/articles/abc` (passed)
- `https://example.com/data/foo` → `https://example.com/data/foo` (passed)

## Verification

- `dart analyze --fatal-infos` → exit 0 (`No issues found!`)
- `flutter test` → 224/224 passed, exit 0
- `flutter test test/path_redactor_test.dart` → 8/8 passed, exit 0
- `dart format --set-exit-if-changed .` → exit 0, 126 files, 0 changed
- `storage/emulated/0` in `error_screen.dart` → 0 hits
- `redactFileSystemPaths` in `error_screen.dart` → 1 hit (call site). The prompt expected 2 hits, but the import line spells the *file* name `path_redactor.dart`, not the function name; the import is present at line 3. Verified separately with a `path_redactor` grep.
- `redactFileSystemPaths` in `path_redactor.dart` → 1 hit (definition)
- D6-02 `ErrorScreen redacts absolute user paths from rendered summary` → passed, with the replacement string untouched.

`git diff --stat` (tracked file only):

```
 lib/features/process/screens/error_screen.dart | 10 ++--------
 1 file changed, 2 insertions(+), 8 deletions(-)
```

The two new files are untracked, so they do not appear in `git diff --stat` until staged.

## Final `git status --short`

```
 M lib/features/process/screens/error_screen.dart
?? 0ai_context/reports/112-fix-path-redaction.md
?? lib/core/utils/path_redactor.dart
?? test/path_redactor_test.dart
```

## Next

Fix #4: AUDIT candidate 030 — 14 raw `$e` interpolation sites in the UI layer, report 113.
