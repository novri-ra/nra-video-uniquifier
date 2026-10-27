# 07-decompose-settings-sheet: Modularize Advanced Settings Sheet

## Task Summary
Decomposed `lib/features/settings/screens/advanced_settings_bottom_sheet.dart` (438 LOC) into modular setting group widgets under `lib/features/settings/widgets/`.
This completes the codebase-wide line budget objective: **0 files exceeding 400 LOC in `lib/`**.

## Skills Loaded
- `clean-code`
- `flutter-expert`
- `senior-architect`
- `senior-qa`

## MCP Evidence
- **Server**: `codebase-memory-mcp`
- **Project**: `C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier`
- **Baseline (Post-06)**: 847 nodes / 1,805 edges
- **Post-Refactor Re-index**:
  - Command: `tools["codebase-memory-mcp"].index_repository({ repo_path: "...", depth: "full" })`
  - Result: Graph updated to **866 nodes / 1,848 edges** (+19 nodes, +43 edges).
  - Graph Query: `MATCH (f:File) WHERE f.path STARTS WITH 'lib/features/settings/widgets' RETURN f.path, f.name`
  - Output: 3 distinct setting widget files verified in knowledge graph.

## Line Budget Delta Table
| Component File | Role | Before (LOC) | After (LOC) | Budget Status |
|----------------|------|--------------|-------------|---------------|
| `advanced_settings_bottom_sheet.dart` | Modal Scaffold Coordinator | **438** | **158** | **PASSED** (< 180 LOC) |
| `upscale_resolution_card.dart` | Output target resolution selectors & badges | - | **220** | **PASSED** (< 250 LOC) |
| `audio_visual_tuning_card.dart` | Audio pitch & crop tuning slider card | - | **120** | **PASSED** (< 180 LOC) |
| `hardware_acceleration_card.dart` | GPU accelerator switch & shader telemetry | - | **107** | **PASSED** (< 180 LOC) |

- `advanced_settings_bottom_sheet.dart` reduced by **280 lines (-63.9%)**.
- All function lengths in `advanced_settings_bottom_sheet.dart` and the extracted widgets are <= 35 lines.

## Codebase-wide Line Budget Summary (All Files <= 400 LOC)
| Rank | File Path | LOC | Budget (< 400) |
|------|-----------|-----|----------------|
| 1 | `lib/features/navigation/screens/root_navigation_screen.dart` | 309 | **PASSED** |
| 2 | `lib/features/process/widgets/source_file_section.dart` | 272 | **PASSED** |
| 3 | `lib/features/process/screens/processing_screen.dart` | 272 | **PASSED** |
| 4 | `lib/features/process/screens/success_screen.dart` | 271 | **PASSED** |
| 5 | `lib/features/settings/widgets/upscale_resolution_card.dart` | 220 | **PASSED** |
| 6 | `lib/features/process/screens/error_screen.dart` | 220 | **PASSED** |
| 7 | `lib/core/providers/uniquifier_provider.dart` | 185 | **PASSED** |
| 8 | `lib/features/history/widgets/history_item_card.dart` | 176 | **PASSED** |
| 9 | `lib/features/history/widgets/history_storage_bar.dart` | 176 | **PASSED** |
| 10 | `lib/features/process/widgets/modifiers_card.dart` | 176 | **PASSED** |
| 11 | `lib/features/settings/screens/advanced_settings_bottom_sheet.dart` | 158 | **PASSED** |
| 12 | `lib/features/history/screens/recent_history_screen.dart` | 152 | **PASSED** |
| 13 | `lib/features/process/screens/process_screen.dart` | 144 | **PASSED** |
| 14 | `lib/features/process/widgets/processing_log_viewer.dart` | 135 | **PASSED** |
| 15 | `lib/core/services/ffmpeg_service.dart` | 128 | **PASSED** |
| 16 | `lib/features/settings/widgets/audio_visual_tuning_card.dart` | 120 | **PASSED** |
| 17 | `lib/core/theme/app_theme.dart` | 118 | **PASSED** |
| 18 | `lib/features/settings/widgets/hardware_acceleration_card.dart` | 107 | **PASSED** |
| 19 | `lib/core/services/history_service.dart` | 101 | **PASSED** |
| 20 | `lib/shared/widgets/top_app_bar.dart` | 97 | **PASSED** |
| 21 | `lib/features/process/widgets/processing_radar_indicator.dart` | 79 | **PASSED** |
| 22 | `lib/features/process/widgets/engine_state_strip.dart` | 71 | **PASSED** |
| 23 | `lib/features/process/widgets/processing_stage_tracker.dart` | 58 | **PASSED** |
| 24 | `lib/main.dart` | 28 | **PASSED** |
| 25 | `lib/features/history/widgets/history_empty_state.dart` | 28 | **PASSED** |

**Total Production Files**: 25  
**Files Exceeding 400 LOC**: **0 (100% compliance)**

## Test & Static Analysis Results
- `flutter analyze`: **0 issues found** (passed in 3.5s).
- `flutter test`: **27/27 tests passed** (0 failures, 0 errors).

## Next Recommended Task
- Project architecture verification and final cleanup wrap-up.
