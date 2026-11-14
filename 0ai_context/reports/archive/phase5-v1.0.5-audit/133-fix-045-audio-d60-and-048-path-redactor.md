# Report 133 — Audio `d=60` Truncation and Path-Redactor Gaps

**Date:** 2026-11-14
**Status:** Done — both findings fixed; suite green
**Base commit:** `026c196 docs(context): synchronize mapper files with software encoding and LUT architecture`
**Findings:** AUDIT-20261114-045, AUDIT-20261114-048

---

## 1. Preflight

Codebase-memory MCP checks (mandatory preflight):

| Check | Result |
|---|---|
| `index_status` | `ready` |
| Nodes / edges | 2908 / 7070 |
| `indexed_at` | `2026-11-13T14:31:12Z` |
| Watch state | disabled (`not_session_project`) |
| `parse_partial` | 6 files |
| `not_indexed` | 103 files |
| `filter_builders.dart` coverage | `metadata_changed` |
| `path_redactor.dart` coverage | `metadata_match` |

`search_graph` for the mandated OR query returned only generic file nodes, so
all line-level evidence below was re-verified locally with `read` / `rg`.

Working tree note: `ffmpeg_service.dart`, `filter_builders.dart`,
`render_diagnostic_service.dart`, and `test/ffmpeg_service_test.dart` already
carried the uncommitted 131/132 fixes (040, 041, 044, 039). This task only adds
the 045/048 deltas on top.

---

## 2. Findings

### 2.1 AUDIT-20261114-045 — audio mask stops at 60 s

The aggressive and deep anti-fingerprint audio graphs generated their noise and
subliminal sources with a hardcoded 60-second duration:

```
anoisesrc=d=60:c=pink:a=0.003[noise]
aevalsrc=exprs=...:d=60:s=44100[subliminal]
```

`amix` used `duration=first`, so the final `[out]` was still bounded by the real
clip (the earlier 2-hour source cost could not return). However, the dither and
subliminal layers stopped at 60 s while the main audio (`a0`) continued. Any
clip longer than 60 s therefore lost the mask after the first minute, which is
exactly the content most likely to be fingerprinted.

### 2.2 AUDIT-20261114-048 — path redactor truncates and misses roots

`_pathPattern` in `lib/core/utils/path_redactor.dart`:

- used `[^\s")\]<>|]*` as the path body, so a path containing a space was
  redacted only up to the first space; the remainder (often a user name or file
  name) leaked into UI/error text;
- only recognised `/storage`, `/data`, `/sdcard`, `/mnt`, `/system`, `/proc`,
  and `/home`, missing `/tmp`, `/var`, `/Users`, and `/private`.

---

## 3. Changes

### 3.1 `lib/core/services/filter_builders.dart` (045)

Added one documented constant:

```dart
/// Duration (seconds) for the generated pink-noise / subliminal sources.
///
/// These sources are mixed with `amix=duration=first`, so the final audio is
/// still bounded by the real clip; the source only needs to outlast it. A
/// fixed 60 s cap silently truncated the dither layer on longer clips, so use
/// a value larger than any expected input instead (4 hours).
static const String _audioMaskMaxSeconds = '14400';
```

Both audio branches now emit `d=$_audioMaskMaxSeconds` for `anoisesrc` and
`aevalsrc`. `weights=...` and both `amix=...:duration=first` stages are
unchanged, so output length remains the real clip length and the 2-hour leak
from report 128 cannot return.

Why an upper bound instead of the real media duration: `buildAudioFilter` is
called from `ffmpeg/ffmpeg_command_builder.dart`, which is outside this task's
whitelist and does not pass a duration into the builder. The constant is the
compliant fix; threading the probed duration through the command builder is a
separate change.

### 3.2 `lib/core/utils/path_redactor.dart` (048)

- Root list extended to
  `storage|data|sdcard|mnt|system|proc|home|tmp|var|Users|private`
  (`caseSensitive: false`, so `/users` is covered too). Windows drive paths
  (`[A-Za-z]:[\\/]`) already covered every Windows root, including
  `C:\Users`, `C:\Program Files`, and `C:\Windows`.
- Each root now has three body alternatives:
  1. **extension-terminated**: may include spaces, stops after a
     `.[A-Za-z0-9]{1,8}` extension. Handles
     `/Users/John Doe/Movies/clip.mp4 now` without swallowing `now`.
  2. **quoted/bracketed**: may include spaces, stops at `" ) ] < > |`.
     Handles `"/tmp/my folder"`.
  3. **compact**: no spaces, preserving the existing
     `see /sdcard/DCIM/v.mp4 now` behaviour.
- A delimiter lookahead after each root prevents `/datastore` from matching
  `/data`.
- The URL boundary group `(^|[\s"(\[=,:;\\])` is untouched, so
  `https://example.com/tmp/data/foo` and similar URLs remain unchanged.

---

## 4. Tests

`test/path_redactor_test.dart` grew from 8 to 13 tests (+5):

- POSIX path with spaces (`/Users/John Doe/Movies/clip.mp4`).
- Embedded path with spaces plus trailing prose.
- Windows path with spaces (`C:\Users\John Doe\...`, `C:\Program Files\...`).
- `/tmp`, `/var`, `/private/var`, `/Users/Shared` roots.
- Quoted directory with spaces and no extension.
- URLs containing `tmp` / `var` / `private` remain untouched.

`test/ffmpeg_service_test.dart`:

- Aggressive branch now asserts
  `anoisesrc=d=14400:c=pink:a=0.003[noise]` and
  `aevalsrc=...:d=14400:s=44100[subliminal]`.
- Deep branch asserts `anoisesrc=d=14400:c=pink:a=0.0015`.
- Both assert `isNot(contains('d=60'))` and
  `contains('amix=inputs=2:duration=first')`.

No production `d=60` remains (`rg -n "d=60" lib --glob '*.dart'` → exit 1).

---

## 5. Verification

| Command | Result |
|---|---|
| `dart analyze --fatal-infos` | exit 0, no issues |
| `flutter test` | 240/240 passed |
| `dart format --output=none --set-exit-if-changed lib test` | 0 changed |
| `git status --short` | only whitelisted files |
| `rg -n "d=60" lib --glob '*.dart'` | no matches |

---

## 6. Residual risk

- FFmpeg graph validity is still verified statically (string assertions); no
  system FFmpeg binary or device was available to render a >60 s clip.
- The 4-hour mask source is generated lazily and mixed with
  `duration=first`; FFmpeg should stop pulling from it when the real audio ends.
  The bound is intentionally larger than any expected input, so very long
  renders do not truncate.
- The redactor's unquoted, extension-less directory paths that contain spaces
  and are followed by prose (e.g. `/tmp/my folder is gone`) still stop at the
  first space. Paths with a file extension, quoted paths, and bracketed paths
  are fully redacted. Callers that already know a value is an absolute path
  (`RenderDiagnosticInfo._diagnosticPath`) replace the whole value instead of
  relying on the regex.
