# HERMES-WORKFLOW.md — Hermes Native Engineering Protocols

## 1. Hermes Native Preflight
Run mandatory preflight checks before modifying or scanning codebase:
1. `hermes doctor`: Verify environment, Python runtime, SQLite WAL status, and tool integrity.
2. `hermes skills list`: Verify availability of standard engineering skills.
3. `hermes mcp test codebase-memory-mcp`: Verify MCP transport readiness and discovered tools.

## 2. Skill Management & Declarative Loading Convention
Before executing tasks, invoke skills via slash commands (`/senior-architect`, `/clean-code`, `/systematic-debugging`, `/senior-qa`, `/flutter-expert`, `/mobile-developer`, `/ponytail`) or declare loaded skills explicitly at turn start:
```
SKILL LOADING (MANDATORY):
  skill(name="ponytail")
  skill(name="flutter-expert")
  skill(name="mobile-developer")
  skill(name="clean-code")
  skill(name="systematic-debugging")
  skill(name="senior-qa")
```
- **Auto-Loading**: Preload baseline skills via `~/.hermes/config.yaml` under `skills.auto_load`:
```yaml
skills:
  auto_load:
    - senior-architect
    - clean-code
    - systematic-debugging
    - senior-qa
```
- **Cache Invariance**: Avoid adding or deleting skills mid-session to keep LLM KV cache valid.

## 3. MCP Initialization & Graph Verification Convention
Verify codebase memory index and project constraints prior to code edits:
```
MCP INITIALIZATION & GRAPH VERIFICATION (MANDATORY):
  - Check project index status with tools["codebase-memory-mcp"].index_status.
  - Ensure graph queryability and zero broken references across all modules.
  - Verify strict line budget across the entire repository (every file in lib/ must be <= 400 lines).
```

## 4. MCP Lifecycle
- **Add**: `hermes mcp add codebase-memory-mcp --command <cmd> --args <args>` (args trailing).
- **Test**: `hermes mcp test codebase-memory-mcp` (validates connection and schemas).
- **Configure**: `hermes mcp configure codebase-memory-mcp` (select active tools).
- **Reload**: Use `/reload-mcp` or start fresh session to apply configuration changes.
- **Trust Tier**: Set `trust: full` for fully trusted local servers to avoid approval prompts caused by SDK camelCase/snake_case `read_only_hint` discrepancies.

## 5. Evidence-First Rule
- Never speculate about code behavior, file counts, or dependencies.
- Primary evidence: `codebase-memory-mcp` query results.
- Secondary evidence: exact `path:line` citations.
- Unverified statements must be explicitly labeled as "unverified".

## 6. Sequential Reports Policy
- All session logs are stored under `0ai_context/reports/`.
- File naming: `NN-[task-slug].md` (zero-padded 2 digits: `01-...`, `02-...`, `23-...`).
- No dates in report filenames.
- Every report must conclude with a mandatory "MCP Evidence" appendix listing tool names, queries, and exact counts.

## 7. Strict Code Ceiling
- Functions: <= 40 lines.
- Files: <= 400 lines (strictly enforced for source code; documentation exempt when specified).
- Decompose files exceeding 400 lines into cohesive sub-widgets or helper services.

## 8. Context Tiering
- **Root Context**: `AGENTS.md` is auto-injected by Hermes into the cached context tier.
- **Subdirectory Context**: `frontend/AGENTS.md` or `backend/AGENTS.md` loaded progressively when touching those trees.
- **Deep Reference**: `0ai_context/SEED.md` and `0ai_context/STATE.md` provide full structural depth.
- **Task Prompts**: Keep per-turn task prompts concise. Do not paste bootstrap prompts into regular task turns.

## 9. Eight Core Engineering Patterns
1. **Evidence-first, no speculation**: Every technical claim must have a query or file citation.
2. **Diagnosis before modification**: Identify root cause before altering any source code.
3. **Numbered reports, not dated**: Maintain chronological ordering via zero-padded prefixes.
4. **Line limits enforced**: Keep codebase modular, maintainable, and readable.
5. **Trust the packet, not AI memory**: Rely on durable context in files, not volatile memory.
6. **MCP-first verification**: Query the symbol graph before searching plain text.
7. **Respect trust tiers**: Be mindful of read-only hints and tool approval policies.
8. **Never re-paste bootstrap**: Use `AGENTS.md` as the single authoritative anchor.
