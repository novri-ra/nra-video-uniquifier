# Skills & MCP Matrix

## 1. Standard Available Skills
- `flutter-expert`: Dart 3 & Flutter cross-platform architecture, widget lifecycle, and rendering.
- `clean-code`: Concise, direct, DRY/KISS, no over-engineering, single-responsibility principle.
- `systematic-debugging`: Root-cause investigation before fixing, hypothesis testing, regression prevention.
- `senior-qa`: Automated testing strategy, unit test coverage, smoke testing.
- `mobile-design`: Mobile-first UX/UI touch ergonomics, performance patterns, platform idioms.
- `senior-architect`: High-level system design, module boundary enforcement, dependency analysis.

## 2. Dynamic Stack Matrix (Flutter + FFmpeg Video Processing)

| Development Domain | Recommended Skill | When to Activate |
|--------------------|-------------------|-------------------|
| **Flutter Widgets / State** | `flutter-expert` | Building or refactoring UI components, Providers, AnimatedBuilders, modal sheets. |
| **FFmpeg Service / Codecs** | `senior-architect` | Modifying FFmpeg CLI parameters, Lanczos filters, audio pitch shifts, platform channels. |
| **Bug Fixing / Regressions**| `systematic-debugging` | Video processing failures, memory leaks, platform crashes, file picker bugs. |
| **Refactoring & Modularity**| `clean-code` | Splitting oversized screens (`process_screen.dart`, `recent_history_screen.dart`). |
| **Test Suites** | `senior-qa` | Writing widget tests, provider mocks, FFmpeg argument regression tests. |
| **Theme / Design Polish** | `mobile-design` | Adapting Obsidian/Mint precision tokens, bottom sheets, responsive layouts. |

## 3. MCP Usage Matrix (`codebase-memory-mcp`)

| Task Type | MCP Tool | Example Command / Query |
|-----------|----------|-------------------------|
| **Project Readiness** | `index_status` | `tools["codebase-memory-mcp"].index_status({ project: "<project>" })` |
| **High-Level Overview** | `get_architecture` | `tools["codebase-memory-mcp"].get_architecture({ project: "<project>", format: "json" })` |
| **Symbol Search** | `search_graph` | `tools["codebase-memory-mcp"].search_graph({ project: "<project>", name_pattern: "Ffmpeg.*" })` |
| **Trace Callers / Callees** | `trace_path` | `tools["codebase-memory-mcp"].trace_path({ project: "<project>", function_name: "buildCommand", direction: "inbound" })` |
| **Dead Code Detection** | `query_graph` | `MATCH (a)-[r]->(b) WHERE b.path = '<file>' AND a.path <> '<file>' RETURN a.path, type(r), b.name` |
| **Dependency Graph** | `query_graph` | `MATCH (a:File)-[r:IMPORTS]->(b) RETURN a.path, b.name, b.path` |
| **Source Snippet Inspection**| `get_code_snippet` | `tools["codebase-memory-mcp"].get_code_snippet({ project: "<project>", qualified_name: "<symbol>" })` |
| **Coverage Gaps** | `check_index_coverage` | `tools["codebase-memory-mcp"].check_index_coverage({ project: "<project>", paths: ["lib/main.dart"] })` |
