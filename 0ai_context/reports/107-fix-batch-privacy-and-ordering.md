# Report 107 — Fix P3 Batch: Caller Log Path Leak, History Exception Narrowing, and Notify-First Setters

- Date: 2026-11-09
- Findings: AUDIT-20261108-029 (P3), AUDIT-20261108-021 (P3), AUDIT-20261108-023 (P3)
- Target files:
  - `lib/core/services/ffmpeg_service.dart` (Finding 029)
  - `lib/core/services/history_service.dart` (Finding 021)
  - `lib/core/services/settings_service.dart` (Finding 023)
- Status: RESOLVED (all 3 findings closed; no rollback needed)

## 1. Verify-Premise Notes (corrections to the brief)

1. **029 line number**: the caller log is at `ffmpeg_service.dart:483`, not `:464`. Line 464 of the pre-change file is the *other* catch in `_cleanupAfterProcess` (see §2). The finding itself (absolute `$inputPath` + `$e` interpolation) was present exactly as described.
2. **021 site count**: only **3** of the 4 listed sites actually interpolate `$e`. The sites at old lines ~264 and ~322 (`'Physical delete failed, file still exists: <basename>'`) carry **no** exception interpolation, so there was nothing to narrow. Changed sites: old 251 (`_cleanupThumbnail` catch), old 277 (`deleteItem` catch), old 326 (`deleteExportItemsDetailed` catch). Current lines: 251, 277, 327 (the `deleteItem` message was wrapped onto two lines, shifting the last site by one).
3. **023 shape**: both setters were write-before-notify as described. However, the literal prescribed end-state (`notifier.value = value` **before** `SharedPreferences.getInstance()`) is not deliverable: it breaks the pre-existing test `uniquifier_provider_test.dart` → *"Reacts immediately when SettingsService broadcasts resolution change"* (expected `4k`, actual `1080p`). Root cause: `UniquifierProvider()` starts an async `_initResolution()` read at construction; with the notifier updated before the first `await`, that in-flight read completes *after* the notify and clobbers it with the stale persisted value. Delivered ordering is **prefs acquire → notifier → prefs write**, which still satisfies the finding (a failing prefs write can no longer leave a stale notifier) and keeps `setUpscaleResolution` winning over the init read. No try/catch added; the throw is preserved.
4. **023 adjacent scan**: no third inconsistent setter exists. Only 4 `ValueNotifier`s are declared in `SettingsService` (`hardwareAcceleration`, `videoCodec`, `upscaleResolution`, `upscaleEngine`); the other 14 setters persist scalars with no notifier at all, so they are not of this shape.

## 2. Summary of Changes

1. **ffmpeg_service.dart (029)**: `stage input failed` log now interpolates basename + `${e.runtimeType}` instead of `$inputPath` + `$e` (matching the report 98 `extractThumbnail` precedent).
2. **ffmpeg_service.dart (029, adjacent)**: `delete staged file failed for ${meta.stagedFile?.path}: $e` in `_cleanupAfterProcess` (line 463) leaked an absolute path through `${...path}` in the same file, same category, around a `FileSystemException`-throwing `deleteSync()`. Narrowed to basename + `${e.runtimeType}` per §14 (no absolute paths in log messages). `renderFilteredPreviewFrame` and `extractThumbnail` were left untouched, as instructed.
3. **history_service.dart (021)**: 3 delete/cleanup logs narrowed from `$e` to `${e.runtimeType}`; basenames and the `\n$stackTrace` in `deleteItem` left unchanged (report 101 §3: stack traces are verbose but not path-bearing).
4. **settings_service.dart (023)**: `setUpscaleResolution` and `setUpscaleEngine` now assign their `ValueNotifier` before the prefs **write** (after prefs acquisition, see §1.3). Consistent with `setVideoCodec` and `setHardwareAcceleration`. No try/catch added; a prefs failure still throws, so `UniquifierModifiersMixin`'s `debugPrint(... setUpscaleTarget persist failed: $e')` still fires.

## 3. Verification

| Gate | Command | Result |
|---|---|---|
| Analyze | `dart analyze --fatal-infos` | exit 0, 0 issues |
| Format | `dart format --output=none --set-exit-if-changed` (3 files) | exit 0, 0 changed |
| Focused | `flutter test test/ffmpeg_service_test.dart` | 38/38 passed |
| Focused | `flutter test test/history_service_test.dart` | 6/6 passed |
| Focused | `flutter test test/uniquifier_provider_test.dart` | 21/21 passed (fails with the literal 023 shape — see §1.3) |
| Full | `flutter test` | **212 passed / 4 failed of 216** |
| Diff scope | `git diff --name-only` | exactly the 3 whitelisted files |

**Full-suite failures are pre-existing and environmental, not regressions.** The 4 failures (`app_toast_test.dart`, `setting_fps_selector_row_test.dart`, `visual_effect_selector_card_test.dart`, `widget_test.dart` D2-01) reproduce identically on the clean tree with all 3 files stashed, and share one cause:

```
Exception: Asset 'shaders/ink_sparkle.frag' does not contain appropriate runtime stage data for
current backend (SkSL). Found stages: Vulkan
```

That is an Impeller shader-backend mismatch on this Windows host, unrelated to logging or setter ordering. Baseline and post-change results are identical (212/4), so this batch adds zero test regressions and the reported `216/216` HANDOFF figure is not reproducible on this machine for either revision.

Implementation note: the log-format change is observable in test output, e.g. `[HistoryService] Thumbnail cleanup skipped for batch_del_1.tmp: MissingPluginException` — basename kept, runtime type only, no absolute path.

## 4. Behavior / Privacy Notes

- No `try/catch` was added anywhere; the only added lines are log formatting and two moved statements.
- Exception messages are no longer interpolated into any of the 8 touched log sites; absolute paths are gone from those lines (basenames retained per report 98/100 policy).
- Observable ordering change is limited to: a failed prefs write now leaves the in-memory notifier **new** rather than **stale**, while the exception still propagates to the caller.

## 5. Follow-ups (not fixed here)

1. **Candidate finding #030** — none for the 023 category: no third write-before-notify setter exists (§1.4).
2. **Candidate finding #031** — `ffmpeg_service.dart:263` (`renderFilteredPreviewFrame` cleanup) still logs `'delete old preview failed for ${entity.path}: $e'`, i.e. an absolute path plus the raw exception in the same file/category as 029. Explicitly out of scope for this batch (report 96 fixed only the outer error log of that method); worth a follow-up P3 so §14 holds for the whole file.
3. Pre-existing on this host: 4 widget tests fail from the Impeller SkSL/Vulkan shader mismatch (§3); needs a device/CI environment check before the HANDOFF `216/216` figure can be trusted here.

## 6. MCP Evidence Appendix

| Tool | Query | Result |
|---|---|---|
| `index_status` | project `nra-video-uniquifier` | status `ready`, 2861 nodes / 7111 edges, generation `2026-11-09T04:46:30Z` (preflight OK, no retry) |
| `search_graph` | `.*(setUpscaleResolution\|setUpscaleEngine\|setVideoCodec\|setHardwareAcceleration).*` | 4 nodes in `settings_service.dart`, lines 155 / 182 / 199 / 354; in-degree 5 / 3 / 4 / 4 |
| `search_graph` | `.*(deleteItem\|_cleanupThumbnail\|deleteExportItemsDetailed\|_resolveInputMeta).*` | 7 results; `HistoryService._cleanupThumbnail` at `history_service.dart:239` |
| `get_file_outline` | `lib/core/services/settings_service.dart` | 83 declarations; 4 `ValueNotifier` fields at lines 141 / 144 / 171 / 188 |
| `check_index_coverage` | 3 edited files + provider, mixin, provider test | 6/6 `no_recorded_issue`, no gap ranges; edited files flagged `metadata_changed` → source read directly (Tier 2), which is what every claim above cites |
