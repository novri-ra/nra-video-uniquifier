# Report 124 — Master Fix: Stability + Intel Tab Removal + LUT Engine

**Date:** 2026-11-13
**Status:** Implemented; test gate blocked by 6 stale navigation tests
**Scope:** Software encoding stability lock, H.265/HA UI locks, privacy fix,
Intel tab removal, and LUT (`lut3d`) engine foundation.

---

## 1. Preflight

### Git

- `git status --short` → clean
- `git log --oneline -1` → `fa4323c fix(ffmpeg): force software encoding for ultimate stability`

### MCP (codebase-memory-mcp)

Index was a snapshot from `2026-11-13T14:31:12Z`, so results were treated as
best-effort and cross-checked against the files.

| Query | Result |
|---|---|
| `index_status` | `status: ready`, 2908 nodes, 7070 edges, `watch.watched=false` |
| `search_graph(".*_cleanupOldPreviews.*")` | `FfmpegService._cleanupOldPreviews`, `ffmpeg_service.dart:249` |
| `search_graph(".*buildCommand.*\|.*_executeFFmpeg.*")` | `FfmpegCommandBuilder.buildCommand` (13-49), `FfmpegService.buildCommand` (38-74), `_executeFFmpeg` (612-616) |
| `search_graph(".*FloatingCapsuleNavBar.*")` | `FloatingCapsuleNavBar`, `floating_capsule_nav_bar.dart:8-88` |
| `search_graph(".*RootNavigationScreen.*")` | widget (12-17) + state (19-61) |
| `search_graph(".*FilterBuilders.*")` | `FilterBuilders`, `filter_builders.dart:6-691` |

### Memory

`Architecture-Updates` (type `Project`) created with observations:
"Forced libx264 for 100% stability", "Removed Intel tab", "Added LUT engine support".

> Note: the requested `memory-integration.add_entity` tool does not exist in this
> server; `create_entities` + `add_observations` is the available equivalent.

> Note: skill `flutter-architect` is not installed in this environment
> (`Unable to load skill flutter-architect`). `karpathy-guidelines` was loaded.

---

## 2. Stability, UI Locks, Privacy (already in `fa4323c`)

These four items were delivered in the previous commit and re-verified here; no
new changes were needed:

- `ffmpeg_command_builder.dart`: after the input, every command emits
  `-filter_threads 1 -filter_complex_threads 1 -max_muxing_queue_size 4096`,
  and every visual chain ends with
  `-c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -tag:v avc1`
  (last wins over FilterBuilders' codec args). 0 `mediacodec`/`libx265` hits.
- `codec_selector_card.dart`: H.265 disabled (`onTap: null`, grey, badge
  `DISABLED (STABILITY PRIORITY)`).
- `hardware_acceleration_card.dart`: switch locked (`onChanged: null`), subtitle
  `Permanently Disabled (Software Engine Active for 100% Quality)`.
- `_cleanupOldPreviews`: logs only `fileName` + `e.runtimeType`. `fileName` is
  the precomputed basename of `entity.absolute.path` split on `[/\\]`, so no
  absolute path is emitted and the earlier `entity.path` zero-hit gate holds.
  Functionally identical to the requested
  `entity.path.split(Platform.pathSeparator).last` with no regression.

### Command shape (verified)

```
-y -hwaccel auto -threads 0 -i "input.mp4"
   -filter_threads 1 -filter_complex_threads 1 -max_muxing_queue_size 4096
   ... -vf "...lut3d='assets/luts/<name>.cube',format=yuv420p" ...
   -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -tag:v avc1 "output.mp4"
```

Flags sit after the input, not immediately after `-y`, because two existing
tests assert the exact `-y ... -i "input"` prefix. FFmpeg treats them the same.

---

## 3. Intel (News) Tab Removal

### `lib/shared/widgets/floating_capsule_nav_bar.dart`

- Removed the `Intel` / `analytics-icon.svg` item entirely (0 `Intel` hits).
- New indices: Home 0, Studio 1 (hero action), History 2, Profile 3.
- Doc comment updated from 5-slot to 4-slot.

### `lib/features/navigation/screens/root_navigation_screen.dart`

- Removed `microstock_news_screen.dart` import.
- `_initializedTabs` → `[true, false, false, false]` (4 entries).
- `currentIndex = provider.currentTabIndex.clamp(0, 3)`.
- `IndexedStack` children → Dashboard, Process, RecentHistory, Profile.
- `MicrostockNewsScreen` file is untouched and still exists.

---

## 4. LUT (Color Grading) Engine Foundation

### `assets/luts/.gitkeep`

Directory created with a short placeholder note. Ready for `.cube` files.

### `pubspec.yaml`

```yaml
  assets:
    - assets/
    - assets/models/
    - assets/luts/
```

### `lib/core/services/filter_builders.dart`

- `buildVideoFilter(...)` accepts `String? lutName`.
- When non-null/non-empty, the filter chain is rewritten as:
  `lut3d='assets/luts/$lutName.cube',format=yuv420p`
  (injected immediately before the final format conversion, on both the normal
  and blurred-canvas paths since both end in `format=yuv420p`).

### Plumbing (so the engine is usable end-to-end)

`String? lutName` is forwarded through:

`FfmpegService.buildCommand` → `FfmpegCommandBuilder.buildCommand` →
`writeFilterAndCodecOptions` → `FilterBuilders.buildVideoFilter`.

No UI selector was added (per scope). Runtime note: FFmpeg reads files from the
native filesystem, so a future LUT loader must extract the bundled asset to a
real path (or pass an absolute path); the requested `assets/luts/<name>.cube`
literal is implemented as specified.

---

## 5. Verification

| Check | Expected | Result |
|---|---|---|
| `dart analyze --fatal-infos` | exit 0 | **0** — No issues found |
| `flutter test` | 229/229 | **223/229 — 6 failures, all stale navigation tests** |
| `dart format --set-exit-if-changed .` | exit 0, 0 changed | **0** — 127 files, 0 changed |
| `max_muxing_queue_size 4096` in command builder | ≥1 | 1 hit (line 71) |
| `filter_threads 1` in command builder | ≥1 | 1 hit (line 70) |
| `crf 18` in command builder | ≥1 | 1 hit (line 263) |
| `mediacodec\|libx265` in command builder | 0 | 0 hits |
| `lut3d` in filter_builders | ≥1 | 1 hit (line 386) |
| `Intel` in nav bar | 0 | 0 hits |
| `assets/luts/` exists | yes | yes (`.gitkeep`, 171 B) |

### The 6 failing tests (pre-existing tests, not modified)

All failures are the test suite still asserting the removed 5-tab layout:

1-3. `Renders cleanly on Small Phone / Standard FHD / Tablet` — fixture
   `createTestWidget` defaults to `setTabIndex(2)`, which used to mean Studio
   and now means History, so `NRA VIDEO UNIQUIFIER` / `SOURCE FILE` are absent
   (`test/widget_test.dart:31-32`, assertions at 63/82/102).
4. `D2-01: Double-tap on start action button` — explicit `setTabIndex(2)`
   expecting Studio (`test/widget_test.dart:188`).
5. `Sprint 73: 4-slot floating navbar...` — expects `find.text('Intel')` in the
   navbar (`test/widget_test.dart:468`).
6. `Sprint 77: In-app article reader...` — taps `find.text('Intel')` to reach the
   news screen (`test/widget_test.dart:560`).

Removing the tab and renumbering indices makes these assertions invalid by
definition. The task whitelist forbids editing test files, so they were left
untouched; the tests must be updated (indices 2 → 1, drop Intel slot checks,
navigate to `MicrostockNewsScreen` directly for the reader test) in a follow-up
change that is allowed to touch `test/`.

---

## 6. Files Changed in This Task

- `lib/shared/widgets/floating_capsule_nav_bar.dart` — 4-slot nav.
- `lib/features/navigation/screens/root_navigation_screen.dart` — Intel removed.
- `lib/core/services/filter_builders.dart` — `lutName` + `lut3d` injection.
- `lib/core/services/ffmpeg/ffmpeg_command_builder.dart` — `lutName` plumbing.
- `lib/core/services/ffmpeg_service.dart` — `lutName` plumbing.
- `pubspec.yaml` — `assets/luts/`.
- `assets/luts/.gitkeep` — new asset directory.
- `0ai_context/reports/124-master-fix-and-lut-setup.md` — this report.

## 7. Rollback

```bash
git checkout -- lib/ pubspec.yaml
rm -rf assets/luts/ 0ai_context/reports/124-master-fix-and-lut-setup.md
```
