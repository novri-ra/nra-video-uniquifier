---
generator: prompt-pemetaan-v3.1
schema_version: 3.1
mode_created: MIGRATE-LEGACY
mode_last_update: MIGRATE-LEGACY
generated_at: 2026-11-15T00:00:00Z
evidence_map_version: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
parent_report: null
---

# OpenCode Template & Workflow

## Pipeline Skeleton
SKILL -> MCP -> TASK -> CONTEXT -> OUTPUT -> PHASE -1 -> -0.5 -> 0..8 -> SELF-CHECK -> MANUAL TEST -> REPORT FORMAT -> CHAT OUTPUT -> CONSTRAINTS -> SUCCESS CRITERIA.

## Common Patterns Learned (6 points)
1. **Evidence-first**: Always verify via MCP codebase memory or grep before asserting facts.
2. **Diagnose before fixing**: Follow systematic debugging (investigate root cause before proposing fixes).
3. **NN-slug.md naming**: Use zero-padded integers without dates (e.g., `138-migrate-legacy.md`).
4. **Budgets**: Functions <=40 lines, files <=400 lines where practical.
5. **Trust 0ai_context/**: Rely on context files and MCP indices rather than raw model memory.
6. **MCP-first evidence**: Use MCP tools for mapping, dead code analysis, and dependency graphs; mark unverified otherwise.
