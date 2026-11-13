# Fix Report 100 — Silent Catches, Batch 4 (locale provider, bento grid, live ticker)

**Date:** 2026-11-08
**Type:** Manual Fix (silent-catch remediation, batch 4)
**Status:** Complete — all three files passed their gates, no rollback needed

## 1. Background and Premise Corrections

| File | Scan line | Verified reality |
|------|-----------|------------------|
| `locale_provider.dart` | 34 | empty `catch (_) {}` — but **inside `changeLanguage`** (the save path), not `_loadSavedLocale` |
| `bento_metric_grid.dart` | 48 | empty `catch (_) {}` inside `_BentoMetricGridState._loadStorageMetrics()` |
| `live_intel_ticker_card.dart` | 51 | empty `catch (_) {}` inside `_LiveIntelTickerCardState._loadHeadline()` |

**Correction (finding `-016`):** the prompt described the catch as living in `_loadSavedLocale` or
equivalent. `_loadSavedLocale` was already non-silent — it catches `(e, stackTrace)` and logs at line
23. The only empty catch in the file is the **persistence** half of `changeLanguage`, so the label is
`locale save failed`, not `locale load failed`.

A second, structural observation: `HistoryService.getDeviceStorage()` and
`MicrostockNewsService.getCachedNews()` already swallow their own exceptions and return `null` / `[]`.
The two widget catches are therefore defensive — they only fire on `setState` races or a future
change in those services — but they were silent, so they are fixed here.

Sibling scan: each of the three files has exactly one catch; no `.catchError((_) {})` and no
`catch (_) { return X; }` anywhere in them.

## 2. What Was Done

### 2.1 `lib/core/providers/locale_provider.dart` — 1 handler

| Line (pre-fix) | Enclosing method | Log message | Value choice |
|----------------|------------------|-------------|--------------|
| 34 | `changeLanguage` | `[LocaleProvider] locale save failed: $e` | `$e` — `SettingsService.setAppLanguageCode` is `SharedPreferences.getInstance()` + `setString` only, so the surface is `MissingPluginException` / `PlatformException` (channel name + key name, never the locale value) |

### 2.2 `lib/features/dashboard/widgets/bento_metric_grid.dart` — 1 handler

| Line (pre-fix) | Enclosing method | Log message | Value choice |
|----------------|------------------|-------------|--------------|
| 48 | `_loadStorageMetrics` | `[BentoMetricGrid] storage metrics load failed: ${e.runtimeType}` | `${e.runtimeType}` — `HistoryService` already swallows the `storage_space` plugin error, so the residual surface is `setState` / `FlutterError`, whose `toString()` prints a multi-line creation stack. Type-only keeps the log short and path-free. |

Prefix: the catch lives in the private `_BentoMetricGridState`, but the class identity of the file is
the public widget `BentoMetricGrid`; the prefix uses the public name (same reasoning for the ticker
below).

### 2.3 `lib/features/dashboard/widgets/live_intel_ticker_card.dart` — 1 handler

| Line (pre-fix) | Enclosing method | Log message | Value choice |
|----------------|------------------|-------------|--------------|
| 51 | `_loadHeadline` | `[LiveIntelTickerCard] headline load failed: ${e.runtimeType}` | `${e.runtimeType}` — `getCachedNews` decodes JSON from prefs; a `FormatException` echoes the JSON prefix, which contains article titles and summaries (report 93 precedent) |

### 2.4 Not changed

- No `rethrow`; no new `try`/`catch`; no control-flow change.
- No new API surface: `isDegraded` / `lastErrors` scan = 0 matches.
- Fallbacks intact: locale stays `const Locale('en')` until a valid `en`/`id` code loads,
  `_freeGigabytes` / `_freeFraction` stay at `48.0` / `0.75` on failure, and the ticker keeps its
  seed article path (`getSeedArticles().first`) plus the hard-coded Adobe fallback in `build`.
- Widget trees, `setState` calls, `mounted` guards, and `notifyListeners()` ordering untouched.

## 3. Privacy Scan

One pre-existing log exists in these files: `locale_provider.dart:23`,
`'[LocaleProvider] Failed to load locale: $e\n$stackTrace'`. It was **not** narrowed — the surface is
prefs-only, so it carries no path, hardware spec, article text, or locale value; the stack trace is
verbose but not sensitive. `bento_metric_grid.dart` and `live_intel_ticker_card.dart` had no
pre-existing logs. The three new logs interpolate only the operation label plus `$e` (prefs) or
`${e.runtimeType}`.

## 4. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Format (3 files) | `dart format --output=none --set-exit-if-changed <3 files>` | exit 0, `0 changed` |
| Widget suite | `flutter test test/widget_test.dart` | exit 0, `All tests passed!` (17) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Silent-handler grep (3 files) | `catch (_) {}` / `catchError((_) {})` / `catch (_) { return` | 0 matches |
| New API surface | `isDegraded` / `lastErrors` scan | 0 matches |
| Diff scope | `git diff --name-only` | exactly the 3 whitelisted files |
| Diff shape | `git diff --stat` | 3 files, 16 insertions, 3 deletions |
| Deletions audit | `git diff -U0` removed lines | 3 catch headers only |

## 5. Note for the Next Mapper Run

Five empty catches remain in `lib/`:

| File | Line | Note |
|------|------|------|
| `lib/features/history/screens/recent_history_screen.dart` | 63 | batch 5 |
| `lib/features/microstock/services/user_news_bookmark_service.dart` | 55 | batch 5 |
| `lib/features/microstock/widgets/microstock_article_sheet.dart` | 250 | batch 5 |
| `lib/features/process/screens/processing_screen.dart` | 125 | **not in the planned batch 5** — needs its own prompt |
| `lib/core/services/history_service.dart` | 142 | `isAndroid11OrHigher`, left by explicit instruction |

Follow-up worth registering (P3, outside this whitelist): `microstock_news_service.dart` logs
`'[MicrostockNewsService] cache read failed: $e'`, and `$e` on `jsonDecode` echoes the cached JSON —
i.e. article titles and summaries — which is the exact leak this batch avoided in the widget. The
service needs the same type-only treatment.
