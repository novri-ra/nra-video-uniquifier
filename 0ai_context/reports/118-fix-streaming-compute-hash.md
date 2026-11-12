# Report 118 — Streaming SHA-256 in `SuccessScreen.computeFileHash`

- Date: 2026-11-12
- Finding: AUDIT-20261108-035 (P3, performance/memory)
- File: `lib/features/process/screens/success_screen.dart`
- Status: RESOLVED

## Starting State

`git status --short` was empty at commit `4e90a3c`
(`chore(context): mapper refresh #2 (close 030, register 036)`).

## Change

Before (`computeFileHash` inside `Isolate.run`, lines 26-31):

```dart
final file = File(filePath);
if (!await file.exists()) return '0x0000..0000 (UNAVAILABLE)';
final bytes = await file.readAsBytes();
final digest = sha256.convert(bytes);
final hex = digest.toString().toUpperCase();
```

After:

```dart
final file = File(filePath);
if (!await file.exists()) return '0x0000..0000 (UNAVAILABLE)';
// Stream the file so large exports never sit in memory as one buffer.
final digest = await file.openRead().transform(sha256).first;
final hex = digest.toString().toUpperCase();
```

- `file.openRead()` yields 64 KB chunks, so peak memory is one chunk plus the
  hash state instead of the whole video.
- `sha256` is a `Converter<List<int>, Digest>` which also implements
  `StreamTransformer`, so `.transform(sha256).first` is the idiomatic streaming
  form and needs no new dependency.
- The two return strings (`0x0000..0000 (UNAVAILABLE)` and the `(VERIFIED)`
  form) are unchanged byte-for-byte.

## New Tests — `test/compute_file_hash_test.dart`

Five cases, all on real temp files:

| # | Test | Asserts |
|---|---|---|
| 1 | returns UNAVAILABLE for a nonexistent file | exact `'0x0000..0000 (UNAVAILABLE)'` |
| 2 | returns a VERIFIED short hash for a small file | matches `^0x[0-9A-F]{4}\.\.[0-9A-F]{4} \(VERIFIED\)$` |
| 3 | is deterministic for the same file | two calls return identical strings |
| 4 | differs for two different files | `hashA != hashB` |
| 5 | streaming hash matches the one-shot reference on ~1 MB | full digest cross-check **and** truncated form |

Case 5 is the load-bearing one: it first compares
`file.openRead().transform(sha256).first.toString()` with
`sha256.convert(bytes).toString()` over a 1 MB file (proving the streaming idiom
is bit-identical to one-shot across chunk boundaries), then compares
`SuccessScreen.computeFileHash()` against the reference truncated form.

Temp files are created under `Directory.systemTemp` and removed in `tearDown`.

The test imports `package:crypto/crypto.dart` with the same
`// ignore: depend_on_referenced_packages` comment used by the production file,
because `crypto` is still a transitive dependency (no pubspec change allowed).

## Verification (Gate B)

- `dart analyze --fatal-infos` → exit 0 (`No issues found!`)
- `flutter test` → **229/229 passed**, exit 0 (224 baseline + 5 new)
- `flutter test test/compute_file_hash_test.dart` → 5/5 passed, exit 0
- `dart format --set-exit-if-changed .` → exit 0, 127 files, 0 changed
- `readAsBytes` in `success_screen.dart` → 0 hits
- `openRead().transform(sha256)` in `success_screen.dart` → 1 hit
- `git diff --stat` (code) → 1 modified (`success_screen.dart`, +2/−2) + 1 new test file

## Environment Issues Encountered (documented, not hidden)

1. **Unexpected pubspec modification.** During the run, `pubspec.yaml` and
   `pubspec.lock` changed on their own: `crypto` moved from `transitive` to
   `direct main` (`+ crypto: ^3.0.8`). This was not an edit made by this task —
   the prompt forbids pubspec changes. Both files were reverted with
   `git checkout -- pubspec.yaml pubspec.lock`, and the test file instead
   carries the `depend_on_referenced_packages` ignore comment so analysis stays
   green without touching the manifest. Final `git status` confirms both files
   are clean.
2. **`dart format .` crash on generated Gradle caches.** The Android toolchain
   had left `build/*/.transforms/...` entries with a literal `*` in the
   directory name, and `dart format` aborts on
   `PathNotFoundException ... \*`. These are gitignored build artifacts
   (`.gitignore` lines 29-30). Removing every `build/<plugin>/.transforms`
   directory restored the gate: `Formatted 127 files (0 changed)`.
   This is a recurrence risk after any Android build; it is a tooling/env
   issue, not a source defect, and may deserve its own infra finding if it
   recurs.

## Final `git status --short`

```
 M lib/features/process/screens/success_screen.dart
?? test/compute_file_hash_test.dart
```

## Next

Commit Phase B. Remaining active findings: 020, 024, 027, 028, 036.
