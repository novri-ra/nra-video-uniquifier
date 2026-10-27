# 0ai_context

The `0ai_context/` directory provides persistent, structured documentation and project memory for AI-assisted development.

## Why the `0` Prefix?
Files and directories sort lexicographically in file explorers, IDE sidebars, terminal listings, and tool outputs. A leading `0` guarantees that `0ai_context/` is pinned to the very top of the repository tree. This replaces older `_`-prefix conventions, which many linters, shell tools, git utilities, and GitHub interfaces treat inconsistently or ignore as private/hidden.

## Workflow
1. When starting a new AI session, provide `0ai_context/SEED.md` as context.
2. Read `0ai_context/STATE.md` to see current work, open TODOs, and project health.
3. Use `0ai_context/OPENCODE-TEMPLATE.md` to structure execution tasks.
4. Log session results in `0ai_context/reports/` using strict numerical ordering (`01-bootstrap.md`, `02-feature.md`).
5. Every report must end with an **MCP Evidence** appendix listing tools, queries, and result counts.

## Directory Layout
- `SEED.md`: Fast-reading architecture, dependency map, and cheat sheet (<= 400 lines).
- `STATE.md`: Real-time operational state, module health, and active TODOs.
- `OPENCODE-TEMPLATE.md`: Standard prompt skeleton for executing complex tasks.
- `SKILLS.md`: Dynamic matrix matching available skills and MCP tools to this stack.
- `reports/`: Sequentially numbered session reports (`NN-[task-slug].md`).
