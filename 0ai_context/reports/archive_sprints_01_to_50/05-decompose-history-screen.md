# 05-decompose-history-screen: Modularize History Screen & Extract History Service

## Task Summary
Decomposed monolithic `lib/features/history/screens/recent_history_screen.dart` (558 LOC) into a domain service `lib/core/services/history_service.dart` and modular UI sub-widgets in `lib/features/history/widgets/`.

## Skills Loaded
- `clean-code`
- `flutter-expert`
- `senior-architect`
- `senior-qa`

## MCP Evidence
- **Server**: `codebase-memory-mcp`
- **Project**: `C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier`
- **Baseline (Post-04)**: 799 nodes / 1,685 edges
- **Post-Refactor Re-index**:
  - Command: `tools["codebase-memory-mcp"].index_repository({ repo_path: "...", depth: "full" })`
  - Result: Graph updated to **827 nodes / 1,750 edges** (+28 nodes, +65 edges).
  - Graph Query 1: `MATCH (f:File) WHERE f.path STARTS WITH 'lib/features/history/widgets' RETURN f.path, f.name`
    - Output: 3 distinct widgets (`history_empty_state.dart`, `history_item_card.dart`, `history_storage_bar.dart`).
  - Graph Query 2: `MATCH (f:File) WHERE f.path = 'lib/core/services/history_service.dart' RETURN f.path, f.name`
    - Output: 1 verified service entry.

## Line Budget Delta Table
| Component File | Role | Before (LOC) | After (LOC) | Budget Status |
|----------------|------|--------------|-------------|---------------|
| `recent_history_screen.dart` | Screen Scaffold & Coordinator | **558** | **152** | **PASSED** (< 200 LOC) |
| `history_service.dart` | Filesystem IO, scanner & model | - | **101** | **PASSED** (< 250 LOC) |
| `history_item_card.dart` | Video export card & action buttons | - | **176** | **PASSED** (< 250 LOC) |
| `history_storage_bar.dart` | Queue telemetry & storage usage bar | - | **176** | **PASSED** (< 250 LOC) |
| `history_empty_state.dart` | Empty state placeholder | - | **28** | **PASSED** (< 250 LOC) |

- `recent_history_screen.dart` reduced by **406 lines (-72.8%)**.
- All function lengths in `recent_history_screen.dart` and extracted files are <= 35 lines.

## Changes Made
1. Extracted `lib/core/services/history_service.dart`:
   - Moved `VideoExportItem` model (with `formattedSize` and `formattedDate` formatters).
   - Implemented non-blocking async operations: `getTargetDirectories()`, `scanDirectory()`, `loadHistory()`, `deleteItem()`, and `formatTotalSize()`.
2. Created `lib/features/history/widgets/history_item_card.dart`:
   - Isolated `HistoryItemCard`, `_ThumbnailBadge`, `_ItemInfoColumn`, and `_ItemActionButtons`.
3. Created `lib/features/history/widgets/history_storage_bar.dart`:
   - Isolated `HistoryHeader`, `_HistoryHeaderTitle`, `StorageTelemetryBar`, `_StorageTopRow`, `_StorageProgressBar`, and `_StorageBottomTags`.
4. Created `lib/features/history/widgets/history_empty_state.dart`:
   - Isolated `HistoryEmptyView`.
5. Refactored `lib/features/history/screens/recent_history_screen.dart`:
   - Streamlined into a coordinator widget managing dialog lifecycle, sharing, and pull-to-refresh.
6. Created `test/history_service_test.dart`:
   - Added 5 unit tests covering byte formatting scales, date formatting, storage calculation, filesystem directory scanning, and deletion safety.

## Test & Static Analysis Results
- `flutter analyze`: **0 issues found** (passed in 3.4s).
- `flutter test`: **27/27 tests passed** (+5 new tests, 0 failures, 0 errors).

## Next Recommended Task
Phase 5:
- Decompose oversized `lib/features/process/screens/processing_screen.dart` (471 LOC) by extracting custom radar/render painter and stage progress cards into `lib/features/process/widgets/`.
