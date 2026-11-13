# Report 120 — Temp-Cache Walk Extraction: STOPPED (Divergent Implementations)

- Date: 2026-11-13
- Finding: AUDIT-20261108-024 (P2, quality)
- Status: **STOPPED — no extraction performed**
- Baseline: commit `5af7085` (`chore(context): close 035 in mapper, bump next_n to 120`)
- Working tree at start: clean

## Outcome

The premise of AUDIT-20261108-024 does not hold as stated. There is no
temp-cache walk in `ffmpeg_file_helper.dart`, and the two real walks are **not**
semantically identical: `StorageService.pruneStaleFiles` applies a 24-hour age
gate that `SettingsService.purgeTempCache` does not. Per the task's inspect-first
rule, extraction was aborted and no source file was modified.

## Step 2 — Inspection Table

| Property | `SettingsService.purgeTempCache` | `StorageService.pruneStaleFiles` | `FfmpegFileHelper` |
|---|---|---|---|
| Location | `settings_service.dart:404-432` (walk at line 409) | `storage_service.dart:35-63` (walk at line 40) | — |
| Walk call | `tempDir.listSync(followLinks: false)` | `tempDir.listSync(followLinks: false)` | **none** |
| Directory | `overrideDir ?? getTemporaryDirectory()` | `getTemporaryDirectory()` only | n/a |
| Filter | `name.startsWith('staged_') \|\| name.startsWith('thumb_')` | same prefix filter **+** `lastModifiedSync().isBefore(now - 24h)` | n/a |
| Age gate | **none** — deletes regardless of mtime | **24 hours** | n/a |
| Entry type guard | `if (entry is File)` | `if (entry is File)` | n/a |
| Sort order | none (`listSync` order) | none (`listSync` order) | n/a |
| Per-entry error handling | `catch (e)` → `debugPrint(... ${e.runtimeType})`, continue | `catch (e)` → `debugPrint(... ${e.runtimeType})`, continue | n/a |
| Outer error handling | `catch (e)` → `debugPrint(... ${e.runtimeType})` | `catch (e)` → `debugPrint(... ${e.runtimeType})` | n/a |
| Return type | `Future<int>` (freed bytes) | `Future<int>` (freed bytes) | n/a |
| Public signature | `purgeTempCache([Directory? overrideDir])` | `pruneStaleFiles()` | n/a |

## Divergences Found

1. **`ffmpeg_file_helper.dart` has no walk.** The file only stages, resolves,
   generates, exports, and deletes single files
   (`stageInputFile`, `resolveTargetDir`, `generateOutputPath`,
   `exportStagedFile`, `deletePartialFile`). `git log -S "listSync" --
   lib/core/services/ffmpeg/ffmpeg_file_helper.dart` returns no commit, so
   there is no removed implementation either. The finding's "three walks"
   count is wrong for this file.

2. **Different deletion semantics.** `purgeTempCache` deletes every
   `staged_*` / `thumb_*` file immediately (manual "purge cache" action, user
   initiated). `pruneStaleFiles` only deletes files older than 24 hours
   (startup hygiene, must not touch in-flight staging). Merging them behind
   one flag would either:
   - make startup pruning delete a staging file written seconds earlier
     (data loss / render failure), or
   - make the explicit purge leave fresh files behind (user-visible no-op).

3. **Different input surface.** `purgeTempCache` takes an optional
   `Directory overrideDir` (used by tests and the settings screen);
   `pruneStaleFiles` resolves the temp dir itself. A shared helper would need
   an override parameter that one caller never uses.

4. **A third walk exists in the same file** — `SettingsService.getTempCacheSize`
   (`settings_service.dart:381-401`, walk at line 386) uses the same prefix
   filter but only sums `lengthSync()` and never deletes. It is a read-only
   variant, so it is a third distinct behavior, not a duplicate of either
   deleter.

5. **A fourth walk exists outside the whitelist** —
   `FfmpegService._cleanupOldPreviews` (`ffmpeg_service.dart:254`) filters
   `preview_*.jpg`, skips the current path, and logs the **absolute path plus
   raw `$e`** (`'[FfmpegService] delete old preview failed for ${entity.path}: $e'`).
   That is both a different filter and a privacy regression pattern already
   banned by HANDOFF §12 and closed elsewhere under AUDIT-20261108-030. It is
   explicitly out of scope here (co-change graph neighbour), but it should be
   tracked separately.

Note: `ffmpeg_service.dart`/`filter_builders.dart` were not touched, consistent
with the co-change-graph warning.

## Decision Rationale

Step 3 of the task says: if ANY of filter, sort order, error handling, or
return type differs materially, STOP. Filter semantics differ (age gate), the
set of participating files differs (three call sites claimed, two exist), and
the operation differs (delete vs sum). Extracting would have required a
`shouldDelete`, `olderThan`, and `dryRun` matrix — i.e. a configurable walker
that is *more* complex than the two 25-line implementations it replaces, with
a real risk of changing deletion behavior silently. That is the opposite of the
finding's intent.

## Consolidation Options for a Future Prompt

Ranked by risk:

1. **Lowest risk — read-only helper only.** Extract a
   `tempCacheFiles(Directory dir)` predicate helper (filter + type guard) and
   have all three real walks use it. Keeps deletion policy at each call site;
   removes the duplicated path-splitting/prefix check. This is genuinely
   identical across all three.
2. **Medium — shared `walk` with explicit policy parameters**, e.g.
   `purgeTempCacheFiles(dir, {Duration? olderThan})`, where
   `pruneStaleFiles` passes `olderThan: 24h` and `purgeTempCache` passes
   `null`. Behavior-preserving if the age comparison stays inside the helper
   and defaults to `null`.
3. **Do not merge the read-only `getTempCacheSize`** into the deleter; call
   the shared enumerator and sum at the caller.

## Verification (Baseline Only — No Code Changed)

- `dart analyze --fatal-infos` → exit 0 (`No issues found!`)
- `flutter test` → 229/229 passed, exit 0 (unchanged baseline)
- `dart format --set-exit-if-changed .` → exit 0, 127 files, 0 changed
- `listSync`/`list(recursive` in the three whitelisted files → 3 hits, unchanged
  (settings 386, settings 409, storage 40) — expected, because no extraction ran
- `temp_cache_walker` imports in the three files → 0 hits
- `git status --short` → empty; no files created or modified except this report

## `git status --short`

```
?? 0ai_context/reports/120-fix-extract-temp-cache-walk.md
```

## Next

- Re-scope AUDIT-20261108-024 as option 1 (read-only predicate/enumerator
  helper) or option 2 (policy-parameterised walker with `olderThan`), then
  retry with a prompt that reflects the real two call sites.
- Register a new finding for `FfmpegService._cleanupOldPreviews` logging
  `${entity.path}` + raw `$e` (privacy, AUDIT-030 pattern) — candidate 037.
