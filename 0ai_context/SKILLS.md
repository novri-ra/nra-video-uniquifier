# SKILLS.md — Hermes Skills & Tooling Matrix

## 1. Standard Mandatory Skills
Four core engineering skills installed and verified in Hermes:
- `/senior-architect` (`opencode-imported/senior-architect`): System architecture, module decomposition, boundary management, high-level design.
- `/clean-code` (`opencode-imported/clean-code`): Pragmatic refactoring, strict line limits (<= 40 lines/function, <= 400 lines/file), YAGNI, Ponytail simplicity.
- `/systematic-debugging` (`software-development/systematic-debugging`): 4-phase root cause analysis, evidence-backed reproduction, no speculative fixes.
- `/senior-qa` (`opencode-imported/senior-qa`): Test automation, responsive widget testing, multi-resolution verification, edge-case coverage.

*Note*: Hermes skills are defined at `~/.hermes/skills/<name>/SKILL.md` or `.agents/skills/` and exposed directly as slash commands. This document is reference documentation, not the skill executable itself.

## 2. Dynamic Stack-Specific Skill Matrix
Tailored for `nra_video_uniquifier` (Flutter / Dart / FFmpeg):
- **`/flutter-expert`**: Deep Flutter widget lifecycles, InheritedWidget/Provider reactivity, canvas shaders, render tree optimization.
- **`/flutter-state-and-testing`**: Unit testing ChangeNotifier providers, SharedPreferences mocking, MethodChannel verification, Goldens/responsive smoke tests.
- **`/mobile-developer`**: Android NDK/ABI split builds (`armeabi-v7a`, `arm64-v8a`, `x86_64`), scoped storage, MediaScanner permissions, battery optimization.
- **`/codebase-memory-scout`**: Fast graph queries for callers, callees, symbol definitions, and import traces.
- **`/ponytail`**: Lazy senior developer mode: minimum viable diff, native/stdlib rungs, zero unnecessary abstractions.

## 3. MCP Usage Matrix
Task-to-tool routing for `codebase-memory-mcp`:
| Task | MCP Tool | Arguments / Filter | Expected Output |
|---|---|---|---|
| Architecture Mapping | `get_architecture` | `aspects: ["all"]` | System entry points, component tiers |
| Symbol Discovery | `search_graph` | `name_pattern`, `label` | Qualified names, file locations, in/out degrees |
| Dead Code Detection | `search_graph` | `file_pattern: "lib/.*"`, `max_degree: 0` | Symbols with 0 references |
| Dependency / Call Path | `trace_path` | `function_name`, `direction: "both"` | Inbound callers and outbound callees |
| File Outline | `get_file_outline` | `file_path`, `format: "tree"` | Declarations, line spans, methods/classes |
| Impact Analysis | `detect_changes` | Git diff / staging | Affected symbols, cascade risk |
| Graph Inventory | `get_graph_schema` | `diagnostics: "none"` | Counts of node labels and edge types |
| Multi-hop Relationships | `query_graph` | openCypher `MATCH ...` | Custom graph traversals |
