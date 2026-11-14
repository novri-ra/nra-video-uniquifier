---
generator: prompt-pemetaan-v3.1
schema_version: 3.1
mode_created: MIGRATE-LEGACY
mode_last_update: MIGRATE-LEGACY
generated_at: 2026-11-15T00:00:00Z
evidence_map_version: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
parent_report: null
---

# Skills & MCP Usage Matrix

## Mandatory Skills
1. `senior-architect`
2. `clean-code`
3. `systematic-debugging`
4. `senior-qa`

## Per-Stack Skills
- Flutter / Dart development standards and best practices.

## MCP Usage Matrix
| Task | Primary | Fallback |
|---|---|---|
| Mapping | `file_outline`, `search_symbols` | path:line reads |
| Dead-code | `find_references`, `incoming_edges` | grep + manual confirm |
| Dependency | `get_dependency_graph` | `get_graph_schema` |
| Impact analysis | `find_references` | reverse grep |
