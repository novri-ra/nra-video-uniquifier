# OPENCODE-TEMPLATE.md

```markdown
[file name]: SKILL LOADING (MANDATORY).txt
[file content begin]
SKILL LOADING (MANDATORY):
Before starting, invoke the skill tool for each relevant domain:
  skill(name="flutter-expert")
  skill(name="clean-code")
  skill(name="systematic-debugging")
  skill(name="senior-qa")

MCP INITIALIZATION (MANDATORY):
  Initialize and verify the `codebase-memory-mcp` server BEFORE any scan or modification.
  - Enumerate available MCP tools and record their exact names in the report.
  - Check project index status with `tools["codebase-memory-mcp"].index_status`.
  - Run a smoke-test query (`search_graph` or `query_graph`) to confirm the index is queryable.
  - If the MCP server is unavailable, STOP and report the blocker. Do NOT silently degrade to grep-only mapping.
  - If an MCP tool call fails, record the tool name, arguments, and error before falling back to `path:line` reads.

Confirm skills and MCP status in the "Skills Loaded" and "MCP Evidence" sections of the report.

Working directory: current directory
Branch: main (or local)

TASK: [Concise description of the task to be performed]

============================================================
CONTEXT (evidence we already have)
============================================================
[State known facts, previous findings, or references to 0ai_context/SEED.md and STATE.md]

============================================================
OUTPUT ARTIFACT (MANDATORY)
============================================================
Create/update relevant files and log the final report at:
`0ai_context/reports/NN-[task-slug].md` (zero-padded 2-digit sequential number, e.g. 01-init.md, 02-export-fix.md). Never use dates.

============================================================
PHASE 0: MCP INITIALIZATION & BASELINE CHECK
============================================================
1. Check `tools["codebase-memory-mcp"].index_status({ project: "<project_name>" })`.
2. Run smoke-test query.
3. Establish MCP evidence block.

============================================================
PHASES (PHASE 1..N): EXECUTION
============================================================
1. Diagnose before fixing: trace call paths via `trace_path` or `query_graph`.
2. Implement smallest viable change complying with clean-code standards.
3. Validate each step against existing tests.

============================================================
SELF-CHECK & TESTS
============================================================
Run:
  flutter analyze
  flutter test

============================================================
MANUAL TEST
============================================================
Verify UI interactions or command line outputs on target platform.

============================================================
COMMON PATTERNS LEARNED
============================================================
1. Evidence-first (no speculation).
2. Diagnose before fixing (find root cause first).
3. Strict Numerical Report Naming: `0ai_context/reports/NN-[task-slug].md` (e.g., `01-bootstrap.md`, `02-auth-fix.md`). Never use dates.
4. Strict line budgets: functions max 40 lines, files max 400 lines where practical.
5. Never trust AI memory; trust the `0ai_context/`.
6. MCP-first evidence: every architectural claim must cite a `codebase-memory-mcp` query result or a `path:line`. If neither exists, mark the claim as "unverified".

============================================================
REPORT FORMAT
============================================================
Report must be placed at `0ai_context/reports/NN-[task-slug].md` with:
- Task Summary
- Skills Loaded
- MCP Evidence (tools used, queries run, results)
- Root Cause / Architectural Findings
- Changes Made (exact file paths)
- Verification & Test Results
- Next Steps

============================================================
CHAT OUTPUT (max 10 lines)
============================================================
  status: done | failed
  report: 0ai_context/reports/NN-[task-slug].md
  summary: <one-line summary>
  mcp_evidence: <summary of MCP calls>
  tests: <pass/fail counts>
  next: <next recommended task>
[file content end]
```
