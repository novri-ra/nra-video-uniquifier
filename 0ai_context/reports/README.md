# Session Reports

This folder holds reports generated during development sessions.

## Naming Policy
- Active reports must be named sequentially with a zero-padded 2-digit number prefix:
  - `01-bootstrap.md`
  - `02-auth-fix.md`
  - `03-export-pipeline.md`
  - `10-refactor-history.md`
- **Do NOT use dates** in filenames (e.g. `2026-10-27-report.md` is forbidden). Numerical ordering ensures deterministic sorting across all OS platforms and tools.
- Archive old or superseded reports into version subfolders (e.g. `archive/v1.0/`) when completing major milestones.

## Report Requirements
Every report must document:
1. Skills loaded during the task.
2. Exact files changed or inspected.
3. Verification results (`flutter analyze`, `flutter test`).
4. An **MCP Evidence** appendix listing MCP tools invoked, queries executed, and raw result metrics.
