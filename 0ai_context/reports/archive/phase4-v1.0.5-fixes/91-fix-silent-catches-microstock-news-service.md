# Fix Report 91 — Silent Catches in MicrostockNewsService

**Date:** 2026-11-08
**Type:** Manual Fix (AUDIT-20261108-003, P1)
**Status:** Complete

## 1. Background

HANDOFF §10 finding `AUDIT-20261108-003` reported 9 empty `catch (_) {}` blocks in
`lib/core/services/microstock_news_service.dart`. They covered every RSS fetch, the RSS2JSON and
Reddit JSON decoders, the HTML image extractor, and both SharedPreferences cache paths. A feed
could fail completely and the reader would simply show nothing, with no diagnostic trail.

## 2. What Was Done

### 2.1 The 9 `catch (_) {}` blocks

| Line (pre-fix) | Enclosing method | New log message |
|----------------|------------------|-----------------|
| 241 | `fetchHybridNews` | `[MicrostockNewsService] fetch hybrid feeds failed: $e` |
| 256 | `_fetchDirectRss` | `[MicrostockNewsService] fetch RSS $url failed: $e` |
| 270 | `_fetchGoogleNewsRss` | `[MicrostockNewsService] fetch Google News RSS failed: $e` |
| 285 | `_fetchGoogleNewsIndonesiaRss` | `[MicrostockNewsService] fetch Google News ID RSS failed: $e` |
| 487 | `_extractImageUrl` (HTML fragment parse) | `[MicrostockNewsService] parse image url failed: $e` |
| 525 | `_fetchRss2Json` | `[MicrostockNewsService] fetch RSS2JSON failed: $e` |
| 589 | `_fetchReddit` | `[MicrostockNewsService] fetch Reddit r/$sub failed: $e` |
| 676 | `getCachedNews` | `[MicrostockNewsService] cache read failed: $e` |
| 727 | `saveNewsToCache` | `[MicrostockNewsService] cache write failed: $e` |

### 2.2 Two adjacent silent handlers in the same fetch path

The pattern scan matched 9 blocks, but the fetch path had two more handlers that swallowed the
same class of failure. Both were fixed, because leaving them silent would have defeated the
finding: `_defaultHttpGet` swallows the exception and returns `''`, so the caller's new log line
would never fire.

| Line (pre-fix) | Site | New log message |
|----------------|------|-----------------|
| 653 | `_defaultHttpGet` (`catch (_) { } finally { … }`) | `[MicrostockNewsService] HTTP GET $uri failed: $e` |
| 761 | `triggerBackgroundDownload` (`.catchError((_) {})`) | `[MicrostockNewsService] image download failed: $e` |

Both keep the exact previous behavior: `_defaultHttpGet` still returns `''` after the `finally`
closes the client, and the background image download is still fire-and-forget.

### 2.3 Not changed

- No `rethrow` was added anywhere. Every handler still returns the same fallback
  (`[]`, `null`, `''`, or the cached list).
- No new API surface: no `isDegraded` getter, no `lastErrors` field, no new class.
- Cache TTL, `_maxCacheEntries`, the affinity map, and the RSS2JSON URL builder are untouched.
- `getLastSyncTime` (line 754) keeps its `catch (_) { return null; }` — that body is not empty and
  the `null` return is part of the contract.

### 2.4 Privacy

No log message interpolates article `title`, `summary`, `content`, `fullContent`, the user's search
`query`, or any cached JSON. The only dynamic values logged are `$e`, the public feed `url` /
`uri`, and the public subreddit name `$sub`.

## 3. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Target test | `flutter test test/microstock_news_and_translation_test.dart` | exit 0, `All tests passed!` (18 tests) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Empty catches remaining | pattern scan on the file | 0 |
| New API surface | `isDegraded` / `lastErrors` scan | 0 matches |
| Diff scope | `git diff --stat` | 1 file, 36 insertions, 11 deletions |
| Deletions audit | `git diff` removed lines | 11: 9 literal `} catch (_) {}`, 1 empty catch body, 1 `catchError((_) {})` |

The target suite stubs `customHttpGet` and asserts RSS/Reddit/RSS2JSON parsing plus translation, and
it passed unchanged, so fetch-and-parse behavior is identical.

## 4. Behavior Note

The cache fallback is unchanged: `loadNews` still returns cached articles when
`fetchAndCacheNews()` throws, and `fetchHybridNews` still returns the partial list it accumulated
before the failure — the log line is the only difference.

## 5. Note for the Next Mapper Run

The mapper should detect this report and drop `AUDIT-20261108-003` from the findings inventory.
38 of the original 85 empty catches remain in `lib/` (verified by pattern scan after this fix).
Next clusters by size: `AUDIT-20261108-005` (5, `history_service.dart`), then `-017` (3,
`settings_service.dart`), `-018` (3, `storage_service.dart`), `-006` (3,
`user_interest_service.dart`), and single-catch files such as `-016` (`locale_provider.dart`).

A P3 follow-up is worth registering: there is still no user-visible degraded-state signal for the
news reader, so a fully offline first run shows seed articles with no indication that the feeds
failed. That is a behavior change and was deliberately excluded here.
