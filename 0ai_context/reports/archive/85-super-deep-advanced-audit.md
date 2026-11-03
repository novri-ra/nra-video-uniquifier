# Super Deep Advanced Audit Report — Sprint 85

**Project:** NRA Video Uniquifier (v2.0.0+72)  
**Date:** November 3, 2026  
**Audited Branch:** `development`  
**Scope:** Full codebase audit across 6 dimensions (`lib/` modules, services, providers, screens, widgets).  
**Test Suite:** 168/168 tests passed (100%), 0 analyzer issues, **80.72% code coverage** (4,148 / 5,139 lines hit).  
**Overall Codebase Health Score:** **92.0 / 100**

---

## 1. Executive Summary & Health Score

A comprehensive deep audit of **72 hand-written Dart source files** was executed across 6 core dimensions:
1. **Async & State Safety:** Race conditions, unmounted `setState` calls, context leaks after `await`, stream/animation disposal.
2. **Error Handling & Network Resilience:** Unhandled socket/timeout/format exceptions, unbounded cache growth, malformed RSS/JSON recovery.
3. **File System & Storage Integrity:** Permission denial safety, directory traversal & hidden file filtering, orphaned temp files, disk space validation.
4. **UI Responsiveness & Overflow:** RenderFlex risks on 320dp viewports and 1.3x font scaling.
5. **Code Compliance & Architecture:** Strict enforcement of max 400 LOC per file and max 40 lines per function, dead code, unused imports.
6. **Exhaustive Static Analysis & Regression Test:** `flutter analyze --fatal-infos` (0 issues) and `flutter test --coverage` (168/168 passed).

### Health Score Breakdown
- **Static Analysis & Test Suite:** 100 / 100 (0 issues, 168/168 passing, 80.72% coverage)
- **Error Handling & Network:** 94 / 100 (Try-catch throughout, circular buffers, but cache eviction needed)
- **Async & State Safety:** 92 / 100 (Mostly clean; 2 unmounted setState risks in news synchronizer)
- **File System & IO Integrity:** 90 / 100 (Safe atomic export, but dead storage check in `StorageService`)
- **UI Responsiveness & Layout:** 86 / 100 (Multiple RenderFlex overflow hazards identified on 320dp screens)
- **Architecture Limits (LOC):** 90 / 100 (4 files slightly exceed the 400 LOC limit following remote rebase)
- **Overall Codebase Health Score:** **92.0 / 100**

---

## 2. Critical Findings (Bug, Crash Hazard, Memory Leak, Layout Overflow)

### [CRITICAL-1] 4 Files Exceed 400 LOC Architecture Limit
Following recent feature synchronization on `development`, 4 files breached the strict <= 400 LOC ceiling:
1. `lib/features/microstock/widgets/microstock_article_sheet.dart`: **423 LOC** (+23 over)
2. `lib/features/settings/screens/settings_screen.dart`: **408 LOC** (+8 over)
3. `lib/core/services/ffmpeg_service.dart`: **408 LOC** (+8 over)
4. `lib/core/providers/uniquifier_provider.dart`: **403 LOC** (+3 over)

### [CRITICAL-2] `microstock_news_screen.dart:54, 71` — Unmounted `setState` Crash Hazard
- **File:** `lib/features/microstock/screens/microstock_news_screen.dart` (lines 54 & 71)
- **Description:** `_loadNewsFeed` begins with `setState(() => _isLoading = true)` without checking `if (!mounted) return;`. Similarly, `_updateSyncStatus` executes `setState` without checking `mounted`.
- **Risk:** Triggers `setState() called after dispose()` exception if connectivity state toggles while the user navigates away from the news screen.

### [CRITICAL-3] Bento Metric Grid Visual Gauge Vertical Overflow on 320dp
- **File:** `lib/features/dashboard/widgets/bento_cards.dart:116–163` & `273–308`
- **Description:** In `BentoMetricGrid`, `GridView.count` defaults to `childAspectRatio: 1.0`. On a 320dp viewport with padding, each card has only 138dp height (110dp inner height). The visual gauge (78dp circle + 8dp spacing + 13dp label = 98dp), plus top header (20dp) and footer (28dp), requires 147dp. This causes a vertical `RenderFlex overflowed by 37px` error.

### [CRITICAL-4] Article Checklists & Technical Headings Horizontal Overflow
- **File:** `lib/features/microstock/widgets/microstock_article_content_blocks.dart:213–227` & `100–114`
- **Description:** Unconstrained `Row` contains long text headers (`CHECKLIST KONTRIBUTOR (100% LOLOS KURASI)` and `KEY TAKEAWAYS / REKOMENDASI CEPAT`) without `Flexible`, `Expanded`, or `TextOverflow.ellipsis`. On 320dp devices, text requires ~308dp against 252dp available width, causing horizontal RenderFlex overflow.

### [CRITICAL-5] History Item Info Row Inside Constrained 320dp Card
- **File:** `lib/features/history/widgets/history_item_card.dart:131–157`
- **Description:** `_ItemInfoColumn` has only 76dp available space after the 84dp thumbnail and two 48dp action buttons. A `Row` holding the `READY` badge (~40dp) and `H.264 • MODIFIED` (~88dp) requires 134dp, triggering horizontal overflow.

### [CRITICAL-6] History Header Title & Stats Row Space Contention
- **File:** `lib/features/history/widgets/history_storage_bar.dart:22–43` & `58–83`
- **Description:** `HistoryHeader` places title (~193dp) and file count text + refresh button (~146dp) in a single `Row` with `MainAxisAlignment.spaceBetween`. Total width of 339dp exceeds 288dp available screen width on 320dp viewports.

### [CRITICAL-7] Settings App Info Row Overflow
- **File:** `lib/features/settings/screens/settings_screen.dart:377–406`
- **Description:** `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)` holds unconstrained column on left (195dp) and badge on right (132dp). Total 327dp exceeds 260dp card interior on 320dp screens.

### [CRITICAL-8] Upscale Resolution & Engine Option Rows Overflow
- **Files:** `lib/features/settings/widgets/upscale_resolution_card.dart:153–168` & `upscale_engine_card.dart:100–116`
- **Description:** In option tiles, unconstrained `Text` and `_WarningBadge` / `Icon(Icons.bolt)` in a `Row` exceed available tile width when warning tags are visible.

### [CRITICAL-9] Source File Replace Footer Row Overflow
- **File:** `lib/features/process/widgets/source_file_section.dart:266–285`
- **Description:** `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)` contains unconstrained left prompt and right SHA-256 string, exceeding the 268dp container width on narrow screens.

---

## 3. Medium Findings (Layout Edge Cases, Cache & Storage Integrity)

### [MEDIUM-1] `TranslationService._memoryCache` & SharedPreferences Unbounded Growth
- **File:** `lib/core/services/translation_service.dart:9, 148, 161`
- **Description:** `_memoryCache` (`Map<String, String>`) accumulates entries indefinitely without an LRU eviction policy or cap. SharedPreferences cache keys (`nra_trans_natural_v5_*`) are similarly never purged.

### [MEDIUM-2] `StorageService.hasEnoughSpace` Dead Safety Gate
- **File:** `lib/core/services/storage_service.dart:8–18`
- **Description:** The `minRequiredBytes = 2 GB` constant is dead code. The method only verifies that the temporary directory exists via `FileStat`, never checking actual free storage bytes.

### [MEDIUM-3] Cache Deletion Loops Aborted by Locked Files
- **Files:** `lib/core/services/storage_service.dart:30–34` & `settings_service.dart:358–362`
- **Description:** `entry.deleteSync()` is executed in a loop without individual `try-catch` wrappers. If a single file is locked by the OS or another process, the loop terminates prematurely and leaves remaining stale files unpruned.

### [MEDIUM-4] User Interest Service Anonymous Closure Listener
- **File:** `lib/core/services/user_interest_service.dart:41`
- **Description:** Anonymous closure added to `ConnectivityService.instance.isOnline` cannot be un-registered. Harmless during normal singleton lifetime, but prevents listener garbage collection.

### [MEDIUM-5] Monospace Badges & Action Buttons at 1.3x Font Scale
- **Files:** `seasonal_hero_card.dart:79`, `microstock_inspiration_feed.dart:22`, `history_storage_bar.dart:207`
- **Description:** Fixed-size monospace strings (`🔥 SEASONAL WINDOW • 60-90 DAYS LEAD`, `V-SANDBOX ISOLATION: ACTIVE`) overflow under system font scale >= 1.3x if not wrapped in `FittedBox` or `Flexible`.

### [MEDIUM-6] Functions Exceeding 40 Lines (Declarative & State Trees)
- `ModifiersCard.build()`: 227 lines (`modifiers_card.dart:149`)
- `StudioCustomSlidersCard.build()`: 142 lines (`studio_custom_sliders_card.dart:12`)
- `_MicrostockNewsCardState.build()`: 100 lines (`microstock_news_card.dart:75`)
- `_PresetTile.build()`: 89 lines (`preset_profile_card.dart:115`)
- `_CodecTile.build()`: 89 lines (`codec_selector_card.dart:64`)
- `_EngineOptionTile.build()`: 89 lines (`upscale_engine_card.dart:64`)
- `_MicrostockNewsScreenState.build()`: 89 lines (`microstock_news_screen.dart:100`)
- `_GreetingHeaderSection.build()`: 85 lines (`dashboard_screen.dart:55`)
- `_TrendCard.build()`: 89 lines (`microstock_inspiration_feed.dart:82`)
- `UniquifierProvider.applyPreset()`: 67 lines (`uniquifier_provider.dart:228`)

---

## 4. Low/Style Improvements & Localization Gaps

### [LOW-1] Hardcoded Strings Needing Localization (`AppLocalizations`)
- `bento_metric_grid.dart`: `'SIAP ANTREAN'`, `'Selesai • Buka'`, `'Siap Unggah • Ketuk +'`
- `bento_cards.dart`: `'ACTIVE'`, `'EXIF CLEAN'`, `'Zero Digital Fingerprint'`, `'Original Raw Exif'`, `'SANDBOX'`, `'AVAILABLE'`
- `live_intel_ticker_card.dart`: `'• REKOMENDASI TERKINI'`
- `seasonal_hero_card.dart`: `'🔥 SEASONAL WINDOW • 60-90 DAYS LEAD'`, `'LAUNCH STUDIO DEDUPLICATION'`
- `microstock_article_content_blocks.dart`: Section header titles
- `settings_screen.dart`: `'OFFLINE PRIVACY'`, `'Anti-Fingerprint Evasion Engine'`

### [LOW-2] String Path Concatenation vs `path.join`
- Across `ffmpeg_service.dart`, `history_service.dart`, and `ai_super_resolution_service.dart`. String interpolation (`'${dir.path}/name'`) works uniformly across Android/iOS but should use `path.join()` for Windows/Desktop portability.

---

## 5. Remediation Plan (Prioritized Roadmap)

### Phase 1 — Sprint 86 (Architecture & Critical Crash Fixes)
1. **Enforce <= 400 LOC Limit:**
   - Split `microstock_article_sheet.dart` (423 -> extract `_ActionToolbar` and `_HeaderBar` to widgets folder).
   - Split `settings_screen.dart` (408 -> extract `_AppInfoCard` and purge dialog into separate widget files).
   - Split `ffmpeg_service.dart` (408 -> extract thumbnail and media info probing to a dedicated probe service).
   - Split `uniquifier_provider.dart` (403 -> extract preset definitions to a separate helper class).
2. **Fix Unmounted `setState`:**
   - Add `if (!mounted) return;` at top of `_loadNewsFeed` and `_updateSyncStatus` in `microstock_news_screen.dart`.
3. **Resolve 320dp RenderFlex Overflows:**
   - Change `GridView.count` in `BentoMetricGrid` to specify `childAspectRatio: 0.85` or scale gauge circles to 62dp on narrow screens.
   - Wrap long `Text` widgets in `Flexible`/`Expanded` with `overflow: TextOverflow.ellipsis` in:
     * `microstock_article_content_blocks.dart` (headers)
     * `history_item_card.dart` (`_ItemInfoColumn`)
     * `history_storage_bar.dart` (`HistoryHeader`)
     * `settings_screen.dart` (`_AppInfoCard`)
     * `upscale_resolution_card.dart` & `upscale_engine_card.dart` (option titles)
     * `source_file_section.dart` (replace footer)

### Phase 2 — Sprint 87 (Memory, Storage & Robustness)
1. Implement real disk free-space query in `StorageService.hasEnoughSpace()` using `storage_space` package data.
2. Add LRU 500-item cap to `TranslationService._memoryCache`.
3. Wrap individual `entry.deleteSync()` in `try-catch` inside `StorageService` and `SettingsService` cleanup loops.

### Phase 3 — Sprint 88 (Localization & Clean Code)
1. Migrate remaining hardcoded UI strings to `app_localizations.dart`.
2. Refactor oversized declarative `build` methods exceeding 40 lines into dedicated child widgets.
