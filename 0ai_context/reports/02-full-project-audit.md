# 02-full-project-audit: Comprehensive Project Audit

## Task Summary
Deep audit of `nra_video_uniquifier` codebase covering:
1. Architecture and layer isolation.
2. Circular dependencies and coupling.
3. Dead code and unreferenced symbols.
4. Line budgets (files > 400 lines, functions > 40 lines).
5. Static analysis and test coverage verification.

## Skills Loaded
- `clean-code`
- `senior-architect`
- `senior-qa`
- `systematic-debugging`

## MCP Evidence
- **Server**: `codebase-memory-mcp`
- **Project**: `C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier`
- **Baseline Nodes**: 712 | **Baseline Edges**: 1,451
- **Status**: Ready (generation: `2026-10-27T15:39:06Z`, watched: true)
- **Queries Executed**:
  1. Circular Dependency Check:
     `MATCH (a:File)-[r:IMPORTS]->(b:File)-[r2:IMPORTS]->(a:File) RETURN a.path, b.path`
     -> Result: 0 rows (clean, no cyclic imports).
  2. Inverted Architecture Boundary Check:
     `MATCH (a:File)-[r:IMPORTS]->(b:File) WHERE (a.path STARTS WITH 'lib/core' AND b.path STARTS WITH 'lib/features') RETURN a.path, b.path`
     -> Result: 0 rows (clean, core never imports features).
  3. Method Reference & Orphan Discovery:
     `MATCH (a)-[r]->(b) WHERE b.name = 'mockSelectFile' RETURN a.path, a.name, type(r)`
     -> Result: 2 rows (DEFINES, DEFINES_METHOD; 0 callers).
  4. Coupling and Inbound Edge Queries across all 14 Dart files in project.

## Architectural & Dependency Findings
- **Layer Boundary Integrity**: UI features (`lib/features/*`) consume state (`lib/core/providers/*`) and design system (`lib/core/theme/*`). The service layer (`lib/core/services/ffmpeg_service.dart`) is fully decoupled from the UI, executing video operations independently in a background isolate.
- **Circular Dependencies**: None detected. Import graph forms an acyclic directed graph (DAG).
- **Coupling Bottlenecks**:
  - `UniquifierProvider`: High fan-in (26 inbound edges across 4 feature screens). All screens bind directly to `UniquifierProvider` instead of sub-scoped state.
  - `TopAppBar`: Reused across 6 screens with zero leakage.

## Dead Code & Unused Asset Audit
- **Source Files**: 0 unreferenced source files in `lib/`. Every file has verified in-degree >= 1.
- **Unreferenced Method**:
  - `UniquifierProvider.mockSelectFile()` (`lib/core/providers/uniquifier_provider.dart:185`): Prototyping artifact with 0 callers. Recommended for removal in upcoming cleanup.
- **Asset / Docs Inspection**:
  - `docs/stitch_offline_video_uniquifier_app/`: Contains HTML design exports and screen PNGs. Keep as design reference, but ensure excluded from production application bundle (already verified absent from `pubspec.yaml` `assets:` section).

## Line Budget & File Health Overview

### Oversized Files (> 400 Lines Budget)
| File Path | LOC | Excess | Primary Factor | Decomposition Strategy |
|-----------|-----|--------|----------------|------------------------|
| `lib/features/process/screens/process_screen.dart` | **582** | +182 | Bundled sub-widgets (`_ProcessBody`, `_SourceFileSection`, `_ModifiersCard`, `_EngineStateStrip`) | Extract sub-widgets to `lib/features/process/widgets/` |
| `lib/features/history/screens/recent_history_screen.dart` | **558** | +158 | File system directory scanner mixed with UI card list and storage bar | Extract scanner to a repository/service; extract `_HistoryItemCard` |
| `lib/features/process/screens/processing_screen.dart` | **471** | +71 | Stage tracker, custom circular progress painter, log stream | Extract `_CircularEnginePainter` and stage widgets |
| `lib/features/settings/screens/advanced_settings_bottom_sheet.dart` | **438** | +38 | 6 setting tile components in single sheet file | Extract individual setting group cards |

### Functions / Methods Exceeding 40-Line Budget Limit
| File | Function / Method | Lines | Length | Primary Factor |
|------|-------------------|-------|--------|----------------|
| `lib/core/theme/app_theme.dart` | `darkTheme` (`ThemeData`) | 40-90 | 51 lines | Verbose theme component decoration definitions |
| `lib/features/process/screens/error_screen.dart` | `_ErrorHeroHeader.build` | 39-81 | 43 lines | Container styling and iconography hierarchy |
| `lib/features/process/screens/success_screen.dart` | `_SuccessHeroCard.build` | 90-131 | 42 lines | Metrics grid layout and action badge layout |
| `lib/features/settings/screens/advanced_settings_bottom_sheet.dart` | `_SheetHeader.build` | 61-101 | 41 lines | Header actions, icon containers, and subtitle |
| `lib/features/process/screens/processing_screen.dart` | `_ModuleHeaderTag.build` | 185-225 | 41 lines | Badge row and dynamic status chip layout |

## Test & Static Analysis Results
- **Static Analysis (`flutter analyze`)**:
  - Result: `No issues found! (ran in 3.0s)`
  - Status: **PASSED** (0 lints, 0 warnings, 0 errors).
- **Test Suite (`flutter test`)**:
  - Result: 7/7 tests passed.
    - `test/ffmpeg_service_test.dart`: 6/6 passed.
    - `test/widget_test.dart`: 1/1 passed.
  - Status: **PASSED**.
- **Coverage Gaps**:
  - `UniquifierProvider`: **0% direct unit test coverage** (presets, duration parsing, byte formatting, toggle flags untested in isolation).
  - `recent_history_screen.dart`: **0% test coverage** for directory parsing and deletion confirmation.

## Actionable Refactoring Roadmap
1. **Priority 1 (Hygiene & Dead Code)**: Remove unused `mockSelectFile()` in `UniquifierProvider` (`lib/core/providers/uniquifier_provider.dart:185`).
2. **Priority 2 (Test Coverage)**: Add unit tests in `test/uniquifier_provider_test.dart` to cover presets, duration parsing, and state toggles.
3. **Priority 3 (Decomposition)**: Extract widgets out of `process_screen.dart` (582 lines) and `recent_history_screen.dart` (558 lines) into dedicated widget subfolders.
