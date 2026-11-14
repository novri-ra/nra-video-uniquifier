# Report 125 — Fix Navigation Widget Tests (4-tab layout)

**Date:** 2026-11-13
**Status:** Done — full suite green
**Scope:** Align `test/widget_test.dart` with the 4-tab shell delivered in
report 124 (Home=0, Studio=1, History=2, Profile=3, Intel tab removed).

---

## 1. Preflight

- `git status --short` → 6 modified lib files + `pubspec.yaml`, plus untracked
  `0ai_context/reports/124-master-fix-and-lut-setup.md` and `assets/luts/`
  (all from task 124, intentionally left in place).
- `git log --oneline -1` → `fa4323c fix(ffmpeg): force software encoding for ultimate stability`

Six tests were red before this change, all because they encoded the old 5-tab
layout:

| # | Test | Old assumption |
|---|---|---|
| 1-3 | `Renders cleanly on Small Phone / Standard FHD / Tablet` | `createTestWidget` defaulted to `setTabIndex(2)` = Studio |
| 4 | `D2-01: Double-tap on start action button` | explicit `setTabIndex(2)` = Studio |
| 5 | `Sprint 73: 4-slot floating navbar...` | expected a 5th item labelled `Intel` |
| 6 | `Sprint 77: In-app article reader...` | tapped `Intel` to reach the news screen |

---

## 2. Changes in `test/widget_test.dart`

### 2.1 Default fixture index (2 → 1)

```dart
Widget createTestWidget({required Size surfaceSize, int tabIndex = 1}) {
```

Studio moved to index 1, so the responsive smoke tests (320x480, 540x960,
1280x800) now mount the Studio screen again and `NRA VIDEO UNIQUIFIER` /
`SOURCE FILE` render as expected.

### 2.2 D2-01 explicit index (2 → 1)

```dart
final uniquifierProvider = UniquifierProvider()..setTabIndex(1);
```

The double-tap test needs the Studio screen mounted for the start action
button; previously index 2.

### 2.3 Sprint 73 — 4-slot navbar

- Comment updated to "4 destinations in floating navbar" / "Verify 4 navigation
  items: Home, Studio, History, Profile".
- Removed `expect(find.text('Intel'), findsOneWidget)`.
- Removed the `Intel` tap + `MICROSTOCK INTEL & NEWS` assertion.
- The remaining flow (Dashboard mounted → Studio hero icon → History slot →
  Settings back button pops) is unchanged, only renumbered:
  `plus-icon.svg` now targets slot 1.

### 2.4 Sprint 77 — standalone news screen + reader sheet

The reader/translation coverage is preserved; only the entry point changed.

```dart
final navigator = tester.state<NavigatorState>(
  find.byType(Navigator).first,
);
navigator.push(
  MaterialPageRoute<void>(builder: (_) => const MicrostockNewsScreen()),
);
await tester.pumpAndSettle();
```

After the reader sheet is closed the route is popped with the same captured
state:

```dart
navigator.pop();
await tester.pumpAndSettle();
```

Note: the first attempt used
`Navigator.of(tester.element(find.byType(RootNavigationScreen)))`, which threw
`Bad state: No element`. Once an opaque `MaterialPageRoute` covers the shell,
`RootNavigationScreen` is inside an `Offstage` subtree and the default
`skipOffstage: true` finder no longer sees it. Capturing the `NavigatorState`
before the push avoids the finder entirely.

Assertions after the pop:

```dart
expect(provider.currentTabIndex, equals(1)); // was 2
...
expect(provider.currentTabIndex, equals(1)); // preset chip must not kick to Home
```

The preset-chip assertion confirms `TikTok / Reels` still keeps Studio selected
at its new index.

### 2.5 Import

Added `package:nra_video_uniquifier/features/microstock/screens/microstock_news_screen.dart`.

Uppercase on-screen titles (`MICROSTOCK INTEL & NEWS`, `MICROSTOCK INTEL
READER`) are unchanged data under test; the case-sensitive `Intel` gate stays at
0 hits.

---

## 3. Verification

| Check | Expected | Result |
|---|---|---|
| `dart analyze --fatal-infos` | exit 0 | **0** — No issues found |
| `flutter test` | 229/229 | **229/229 passed** (exit 0) |
| `dart format --set-exit-if-changed .` | exit 0, 0 changed | **0** — 127 files, 0 changed |
| `grep -n 'Intel' test/widget_test.dart` | 0 hits | **0 hits** (case-sensitive) |
| `git diff --stat` | 1 test file + 1 new report | `test/widget_test.dart` 39 lines changed (+ report) |

`flutter test test/widget_test.dart` alone: 17/17 pass.

---

## 4. Files Changed

- `test/widget_test.dart` — fixture/D2-01 index 2→1, Sprint 73 4-item
  assertions, Sprint 77 direct `MicrostockNewsScreen` push/pop with index 2→1.
- `0ai_context/reports/125-fix-navigation-tests.md` — this report.

Task-124 changes (lib/, pubspec, assets/luts/, report 124) are untouched and
still uncommitted in the working tree.

## 5. Rollback

```bash
git checkout -- test/widget_test.dart
rm -f 0ai_context/reports/125-fix-navigation-tests.md
```

No commit was made.
