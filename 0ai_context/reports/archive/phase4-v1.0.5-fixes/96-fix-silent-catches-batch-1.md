# Fix Report 96 — Silent Catches, Batch 1 (translation, article image, ffmpeg file helper)

**Date:** 2026-11-08
**Type:** Manual Fix (silent-catch cluster, P3/P1 residual)
**Status:** Complete — all three files passed their gates, no rollback needed

## 1. Background and Premise Corrections

The batch named three files with "3 + 3 + 2 empty catches". The literal counts are right, but the
suggested operation labels did not match the code, and each file carried additional silent handlers
on the same path (report 91's rule). Corrections:

| Prompt claim | Reality |
|--------------|---------|
| `translation_service.dart` — `translate memory cache read` / `translate long-text chunk` | The 3 literal empties are `_fetchGtxChunk` (GTX fetch + `jsonDecode`), `_getCached` (prefs read), `_cacheTranslation` (prefs write). There is no long-text chunk catch; `translateLongText` has none. A 4th adjacent empty-body catch sits in `_defaultHttpGet`. |
| `article_image_service.dart` — `image isolate worker`, `image cache write`, `image cache prune` | The 3 literal empties are all in `pruneCacheIfExceedsLimit` (size read, per-file delete, outer). "Cache write" has no catch — `targetFile.writeAsBytes` is inside the big `downloadAndCacheImage` try. Five more silent handlers exist: isolate worker, temp-dir probe ×2, download outer, stat fallback. |
| `ffmpeg_file_helper.dart` — `staged file walk`, `atomic move fallback` | There is no walk in `stageInputFile` (it has no catch at all). The 2 literal empties are `resolveTargetDir` (external dirs) and `deletePartialFile`. Three more silent handlers exist: public-dir probe, export copy, export fallback. |

Since the audit's target is "failures must be traceable", every handler in these three files that
currently produces no log was fixed — 8 literal `catch (_) {}` plus 9 adjacent silent handlers.

## 2. What Was Done

All logs are type-only (`${e.runtimeType}`). Every one of these handlers wraps `jsonDecode`,
`FileSystemException`, `HttpClient`/`SocketException` (whose messages echo the request URI, and the
translation URI carries the article text in `?q=`), or a `path_provider` plugin call. None of them
can safely log `$e` under §14.

### 2.1 `lib/core/services/translation_service.dart` — 4 handlers

| Line (pre-fix) | Enclosing method | Log message |
|----------------|------------------|-------------|
| 124 | `_fetchGtxChunk` (literal empty) | `[TranslationService] gtx chunk fetch failed: ${e.runtimeType}` |
| 136 | `_defaultHttpGet` (adjacent: empty body + `finally`) | `[TranslationService] HTTP GET failed: ${e.runtimeType}` |
| 192 | `_getCached` (literal empty) | `[TranslationService] translate cache read failed: ${e.runtimeType}` |
| 201 | `_cacheTranslation` (literal empty) | `[TranslationService] translate cache persist failed: ${e.runtimeType}` |

The HTTP log deliberately omits the URI: `_fetchGtxChunk` builds `...&q=<encoded chunk>`, i.e. the
source paragraph.

### 2.2 `lib/features/microstock/services/article_image_service.dart` — 8 handlers

| Line (pre-fix) | Enclosing method | Log message |
|----------------|------------------|-------------|
| 42 | `processImageInWorker` (adjacent `return null`) | `[ArticleImageService] image isolate worker failed: …` |
| 59 | `downloadAndCacheImage` temp-dir probe (adjacent fallback) | `… cache dir probe failed: …` |
| 129 | `downloadAndCacheImage` outer (adjacent `return null`) | `… image download failed: …` |
| 144 | `pruneCacheIfExceedsLimit` temp-dir probe (adjacent fallback) | `… cache dir probe failed: …` |
| 160 | `pruneCacheIfExceedsLimit` size read (literal empty) | `… image cache size read failed: …` |
| 172 | `pruneCacheIfExceedsLimit` stat fallback (adjacent) | `… image cache stat failed: …` |
| 186 | `pruneCacheIfExceedsLimit` per-file delete (literal empty) | `… image cache prune delete failed: …` |
| 188 | `pruneCacheIfExceedsLimit` outer (literal empty) | `… image cache prune failed: …` |

`processImageInWorker` runs inside `Isolate.run`; `debugPrint` works there and lands in the same
logcat stream. The stat fallback still inserts the epoch-0 entry (oldest → deleted first), so the
pruning order is unchanged.

### 2.3 `lib/core/services/ffmpeg/ffmpeg_file_helper.dart` — 5 handlers

| Line (pre-fix) | Enclosing method | Log message |
|----------------|------------------|-------------|
| 30 | `resolveTargetDir` public dir probe (adjacent fallback) | `[FfmpegFileHelper] public target dir probe failed: …` |
| 42 | `resolveTargetDir` external dirs probe (literal empty) | `… external dirs probe failed: …` |
| 74 | `exportStagedFile` primary copy (adjacent fallback) | `… export copy failed: …` |
| 88 | `exportStagedFile` fallback copy (adjacent `return stagedPath`) | `… export fallback failed: …` |
| 100 | `deletePartialFile` (literal empty) | `… partial file delete failed: …` |

This file had no `flutter/foundation.dart` import; one import line was added for `debugPrint`. No
other import changed.

### 2.4 Not changed

- No `rethrow`; no new `try`/`catch`; no control-flow change.
- No new API surface: no `isDegraded`, no `lastErrors` (scan: 0 matches across the three files).
- Test hooks untouched: `customHttpGet`, `customImageDownload`, `tempDirectoryOverride`,
  `mockTranslator`, `clearMemoryCache`, `memoryCacheSize`.
- Cache TTL / `maxMemoryEntries` (500) / LRU eviction untouched; `_maxMemoryEntries` named in the
  task does not exist — the constant is `maxMemoryEntries`.
- Return values unchanged: translation still returns source text on failure, image download still
  returns `null`, helper still returns `stagedPath` / best-effort `void`.

## 3. Privacy Scan

Case-sensitive scan for `debugPrint(` / `print(` / `developer.log(` before the fix: **0 in all three
files**. There was nothing pre-existing to narrow. Every log added interpolates only the operation
label and `${e.runtimeType}` — no path, no file size, no image URL, no article text, no translated
string.

## 4. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Format (3 files) | `dart format --output=none --set-exit-if-changed <3 files>` | exit 0, `0 changed` |
| Translation/interest suite | `flutter test test/microstock_news_and_translation_test.dart` | exit 0, `All tests passed!` (18) |
| FFmpeg suite | `flutter test test/ffmpeg_service_test.dart` | exit 0, `All tests passed!` (38) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Silent-handler grep (3 files) | `catch (_) {}` / `catchError((_) {})` / `catch (_) { return` | 0 matches |
| New API surface | `isDegraded` / `lastErrors` scan | 0 matches |
| Diff scope | `git diff --stat` | 3 files, 80 insertions, 17 deletions |
| Deletions audit | `git diff -U0` removed lines | 17, all `} catch (_) {` / `} catch (_) {}` headers |

## 5. Note for the Next Mapper Run

17 of the original 85 empty catches remain in `lib/`. Remaining clusters: `uniquifier_media_mixin.dart`
(2), `uniquifier_progress_mixin.dart` (2), `theme_provider.dart` (2), then single-catch files
including `-016` (`locale_provider.dart`).

Follow-up worth registering (P3, outside this whitelist): `FfmpegFileHelper.stageInputFile` throws
`Exception('Source video file does not exist or is empty: $inputPath')`. That exception string is
logged with `$e` by callers such as `ffmpeg_service.dart`, so a user's absolute source path reaches
logcat through the exception, not through a `debugPrint` in this file. Fixing it means changing the
thrown message, which is a behaviour/contract change and belongs in its own prompt.
