# Skills & Tools Inventory

## 1. Snapshot Metadata
- Timestamp: 2026-11-04T00:00:00Z
- Detected Skills Count: 34
- Status: Fully enumerated from local runtime

## 2. Installed Skills
- `flutter-expert`: Flutter architecture, widgets, platform channels, state management.
- `clean-code`: Clean code principles, minimal abstractions, pragmatic AI coding standards.
- `karpathy-guidelines`: Surgical code edits, no speculation, goal-driven execution.
- `git-commit-helper`: Conventional commit generator and git history analysis.
- `codebase-memory`: Knowledge graph navigation, symbol queries, trace path.
- `code-reviewer`: In-depth code review, AST static analysis, best practice checks.
- `security-audit`: Vulnerability research, safety checks, pen-test guidelines.
- `senior-qa`: Test plan design, coverage verification, smoke tests.
- `systematic-debugging`: Root cause diagnosis, reproducer testing before fixing.
- `ui-craft`: Modern UI polish, layout composition, anti-slop guidelines.
- `ui-ux-pro-max`: Multi-stack UI design system and token management.
- `ponytail`: Lazy senior dev mode, minimal code changes, YAGNI enforcement.
- `docker-expert`: Multi-stage Docker builds, container optimization.
- `senior-architect`: High-level system design, dependency structure.
- `senior-devops`: CI/CD automation, environment configuration.
- `web-performance-optimization`: Web performance tuning, bundle profiling.

## 3. Built-in Agents
- `main`: Primary orchestration agent for multi-step task execution.
- `explore`: Fast codebase exploration, glob and pattern discovery.
- `reviewer`: Code review, bug inspection, security diagnostics.
- `codebase-memory-scout`: Fast positive knowledge graph lookups.
- `codebase-memory`: Task-directed graph verification with coverage checking.
- `codebase-memory-auditor`: Bounded-scope graph audit.

## 4. Behavior Rules
- Behavior rules are harness constraints, not callable skills. They govern communication style (e.g., Terse Caveman) and coding discipline (Karpathy Guidelines, Ponytail lazy development).

## 5. MCP Servers
- `codebase-memory-mcp`: Knowledge graph server exposing tools `get_graph_schema`, `get_architecture`, `search_graph`, `trace_path`, `query_graph`, `check_index_coverage`, `get_code_snippet`.

## 6. Recommended Skills to Install
- None currently missing for Flutter desktop and mobile workflow.

## 7. Selection Protocol
1. Determine task domain (e.g. Flutter code change -> `flutter-expert`, `clean-code`).
2. Load required skills explicitly via `skill(...)`.
3. Query knowledge graph for structural discovery before editing.
4. Apply surgical edits with unit test verification.
5. Review diff against anti-patterns.

## 8. Permission Surface
- Read filesystem: Unrestricted.
- Write filesystem: Restricted to workspace root and `0ai_context/`.
- Network: Local test suite and offline tools only.

## 9. Archive Policy
- Append-only updates across runs.

## 10. Change Log
- 2026-11-04: Initial baseline skills documentation generated.
