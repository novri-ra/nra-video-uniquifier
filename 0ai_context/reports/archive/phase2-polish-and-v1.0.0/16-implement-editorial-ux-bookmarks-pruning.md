# Execution Report: Microstock Editorial UX (Read Time, Bookmarks, Reader Progress & Quota Pruning)

- Status: Resolved
- Task: Editorial & Kenyamanan Pembaca Microstock Intel (Opsi 1)
- Date: 2026-11-04

## What Was Done

1. **Dynamic Read Time Calculation (`MicrostockNewsService`)**:
   - Implemented public static helper `MicrostockNewsService.calculateReadTime(String text)`.
   - Computes word count by whitespace tokens (`\s+`) against an average reading speed of 200 words per minute.
   - Uses formula `(words / 200).ceil().clamp(1, 60)` formatted as `"$minutes min read"`.
   - Populated across all parsed articles (direct RSS, Shutterstock RSS2JSON, Reddit Community posts, and JSON serialization fallback).

2. **Offline-First Bookmark / Read Later Service (`UserNewsBookmarkService`)**:
   - Created `lib/features/microstock/services/user_news_bookmark_service.dart`.
   - Backed by local persistent `SharedPreferences` (`nra_bookmarked_article_ids_v1`) without any remote analytics.
   - Provides reactive `bookmarkedIdsNotifier` (`ValueNotifier<Set<String>>`) for synchronous state checks and instant UI toggles.
   - Exposes `isBookmarked(id)`, `toggleBookmark(id)`, `getBookmarkedIds()`, and `resetForTesting()`.

3. **Storage Quota & Auto-Pruning Engine (`ArticleImageService`)**:
   - Implemented `pruneCacheIfExceedsLimit({int maxBytes = 50MB, int targetBytes = 40MB})`.
   - Scans `news_images/` directory, checks cumulative file size.
   - If size > 50 MB, sorts cache files by `lastModified` timestamp ascending (FIFO) and deletes oldest entries until size drops below 40 MB.
   - Automatically executed via unawaited background future after every successful WebP image save.

4. **UI Card & Screen Integrations**:
   - `MicrostockNewsCard`:
     - Added `_ReadTimeBadge` (e.g. `3 min read`) next to the source badge.
     - Added `_BookmarkButton` toggle in top-right action area with reactive state.
   - `NewsSearchAndFilterBar` & `MicrostockNewsScreen`:
     - Added "Saved" chip with bookmark icon as the second item right after "All".
     - Tapping "Saved" filters the list to strictly bookmarked article IDs.
     - Listens to bookmark changes to instantly refresh the filtered view.

5. **Enhanced Reader Controls (`MicrostockArticleSheet`)**:
   - Added font size stepper (`A-` / `A+`) in modal header adjusting `_fontSizeMultiplier` (0.85x to 1.35x baseline).
   - Added bookmark toggle button directly inside reader header.
   - Attached scroll listener to `ScrollController` to compute reading percentage (`offset / maxScrollExtent`).
   - Rendered 2.5dp `LinearProgressIndicator` directly beneath reader drag handle.

## Result

- Deterministic Analysis (`dart analyze`): exit 0, 0 issues found.
- Test Suite (`flutter test`): exit 0, 174/174 passed.
- Formatting (`dart format --set-exit-if-changed`): 7 files formatted, 0 unformatted files.
