# Skills & Tools Inventory

## 1. Snapshot Metadata
- Timestamp: 2026-11-08T01:20:00Z
- Detected skill directories: **98**
- `SKILL.md` files found: **316** (several bundles ship nested sub-skills)
- Top-level bundles: 34 under `C:\Users\Administrator\.config\opencode\skills`
- Other probed locations: `.opencode/skills` (absent), `~/.opencode/skills` (absent), `~/.local/share/opencode/skills` (absent)
- Status: fully enumerated from local runtime
- Counts are runtime-verified, not carried over from the previous run (the earlier "34" counted bundles only)

## 2. Installed Skills
Grouped by purpose. Each entry is a distinct skill directory that can be loaded with `skill(name="<id>")`.

### 2.1 Flutter / mobile / platform
- `flutter-expert` — Flutter widgets, platform channels, multi-platform deployment.
- `mobile-design` — touch targets, mobile interaction patterns, platform conventions.
- `mobile-native` — web-on-phone polish: 100vh, tap highlight, safe areas.
- `animate-expo` — React Native/Expo motion (Reanimated, Gesture Handler).
- `write-swift` — modern Swift, Swift 6 concurrency, value types.

### 2.2 Code quality and review
- `clean-code` — concise, direct, no over-engineering.
- `karpathy-guidelines` — surgical edits, no speculation, verifiable goals.
- `ponytail` — lazy senior dev mode, smallest change that solves the task.
- `ponytail-review` / `ponytail-audit` / `ponytail-debt` / `ponytail-gain` / `ponytail-help` — change review, repo audit, shortcut ledger, savings, reference.
- `code-reviewer` — multi-language review checklist and static analysis.
- `systematic-debugging` — reproduce before fixing.
- `codebase-memory` — knowledge-graph query protocol.

### 2.3 Security and QA
- `security-audit` — codebase/API security review workflow.
- `senior-security` — threat modeling, crypto, security architecture.
- `vulnerability-scanner` — OWASP 2025, supply-chain, attack surface.
- `senior-qa` — test strategy, automation, coverage.
- `design-qa` — token/a11y/visual-regression gates.

### 2.4 Design and UI craft
- `ui-craft`, `ui-craft-dense-dashboard`, `ui-craft-editorial`, `ui-craft-minimal` — anti-slop UI rules and locked knob presets.
- `ui-ux-pro-max` — 50 styles, palettes, font pairings, stack recipes.
- `design-doctrine`, `design-tokens`, `token-build`, `tokens`, `design-code`, `design-component`, `design-screen`, `design-review` — house rules, token pipeline, component/screen generation.
- `a11y-audit`, `adapt`, `animate`, `bolder`, `quieter`, `polish`, `distill`, `delight`, `colorize`, `typeset`, `harden`, `unhappy`, `clarify`, `critique`, `heuristic`, `audit`, `finalize`, `extract`, `shape`, `brief`, `remember`, `redesign`, `start`, `craft`, `sddesign` — single-purpose UI passes.
- `impeccable`, `taste-skill`, `superdesign`, `frontend-design`, `apply-aesthetic`, `emil-design-eng`, `apple-design` — art direction and craft philosophy.
- `animation-performance`, `animation-vocabulary`, `improve-animations`, `review-animations`, `remove-animations`, `find-animation-opportunities` — motion work.
- `data-dashboard`, `design-system`-adjacent helpers (`migrate-design-system`, `pick-ui-library`, `figma-integration`, `image-to-code`, `prototype`, `scaffold-project`, `brandkit`, `ship`, `gate`, `governance`, `observe`, `leaky`, `friction-log`, `grill-me`) — specialist design workflows.

### 2.5 Engineering and infrastructure
- `senior-architect` — system design, dependency structure, trade-offs.
- `senior-devops` — CI/CD, IaC, monitoring.
- `senior-fullstack` — React/Next/Node/Postgres application building.
- `docker-expert` — multi-stage builds, image hardening.
- `react-best-practices` — React/Next performance rules.
- `supabase-postgres-best-practices` — Postgres schema and query performance.
- `web-performance-optimization`, `performance` — Web Vitals, bundle and runtime performance.

### 2.6 Process and tooling
- `git-commit-helper` — conventional commit messages from diffs.
- `report` — collect diagnostics and publish an OpenCode issue.
- `opencode` — OpenCode itself: config, agents, skills, MCP, SDK.

## 3. Built-in Agents
- `main` — orchestrator for multi-phase work.
- `explore` / `explorer` — fast read-only codebase discovery.
- `reviewer` — code review, bug and security inspection.
- `codebase-memory-scout` — fast provisional graph lookups.
- `codebase-memory` — task-directed graph verification with coverage checks.
- `codebase-memory-auditor` — bounded-scope graph audit.
- `general` — multi-step task execution.

## 4. Behavior Rules
Behavior rules are harness constraints, not callable skills:
- `AGENTS.md` at `~/.config/opencode/AGENTS.md` carries the codebase-memory protocol and the Karpathy coding guidelines.
- The chat language rule (Indonesian chat, English artifacts) is a prompt-level rule from the master prompt, not a skill.
- They cannot be invoked with `skill(...)`; they apply automatically to every turn.

## 5. MCP Servers
- `codebase-memory-mcp` — local stdio server at `C:/Users/Administrator/.local/bin/codebase-memory-mcp.exe`, enabled.
- Tools: `list_projects`, `index_status`, `index_repository`, `get_graph_schema`, `get_architecture`, `search_graph`, `trace_path`, `query_graph`, `get_code_snippet`, `get_file_outline`, `search_code`, `check_index_coverage`, `detect_changes`, `compare_graphs`, `ingest_traces`, `manage_adr`, `delete_project`.
- This is infrastructure, not a skill: it has no `SKILL.md` and is loaded by the harness.

## 6. Recommended Skills to Install
- A Dart/Flutter-specific static-analysis skill beyond `flutter-expert`: current bundles cover architecture, not `dart analyze` rule tuning.
- An FFmpeg command-construction reference skill: the highest-risk code in this repo (`filter_builders.dart`, 691 lines) has no skill guidance.
- A dedicated mobile-release skill (Play Store foreground-service, scoped storage, signing): release work currently borrows `senior-devops`.

## 7. Selection Protocol
1. Read the task; name the domain (Flutter UI, FFmpeg engine, release, audit).
2. Load at most 2 skills: one domain skill plus `karpathy-guidelines` for edit discipline.
3. Query `codebase-memory-mcp` before editing — `search_graph` for symbols, `trace_path` for callers.
4. Apply the smallest diff that satisfies the task; run `dart analyze --fatal-infos` and `flutter test`.
5. Verify with `git diff -w --exit-code` when the change is meant to be formatting-only.

Anti-patterns:
- Loading a design skill for a Dart engine change.
- Treating a behavior rule or MCP server as a skill.
- Loading five overlapping UI skills in one turn.

## 8. Permission Surface
| Action | Resource | Effect |
|--------|----------|--------|
| Read | anywhere | allowed |
| Write | `0ai_context/**` | allowed for the mapper |
| Write | `lib/`, `test/`, `android/`, manifests | requires an explicit executor prompt with a whitelist |
| Shell | `git` read-only, `dart`/`flutter` diagnostics | allowed |
| Shell | `git push`, destructive resets | forbidden |
| Network | video pipeline | forbidden by design |
| Network | RSS news reader | allowed at runtime, inbound only |

## 9. Archive Policy
- Append-only across runs; previous snapshots are superseded in place, never deleted.

## 10. Change Log
- 2026-11-04: initial baseline skills documentation (34 bundles counted).
- 2026-11-08: re-enumerated at runtime — 98 skill directories, 316 `SKILL.md` files, 34 bundles; corrected the previous count, added MCP tool list and permission table.
