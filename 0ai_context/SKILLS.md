# Tooling & Skills Catalog — nra_video_uniquifier

## 1. Snapshot Metadata
- Generated: 2026-11-04T01:32:00+07:00
- Installed Skills: 34 system skills
- Built-in Subagents: 7 available
- MCP Servers: 2 active (`codebase-memory-mcp`, `antigravity`)
- Behavior Rules: 3 active behavioral directives

## 2. Installed Skills

### flutter-expert
- Purpose: Flutter/Dart development, widget lifecycle, platform channels, rendering performance.
- Invocation: Automatic or prompt reference for Flutter architecture and Dart 3 optimization.

### clean-code
- Purpose: Pragmatic coding standards, concise implementations, no over-engineering or noise.
- Invocation: General coding tasks and refactoring passes.

### code-reviewer
- Purpose: Comprehensive automated code analysis, security scanning, and review checklists.
- Invocation: Pull request evaluations and code audits.

### codebase-memory
- Purpose: Codebase knowledge graph exploration, symbol resolution, and dependency tracing.
- Invocation: Exploring architecture, callers, fan-in/fan-out, and impact analysis.

### security-audit
- Purpose: Vulnerability review, static analysis, secrets detection, and hardening.
- Invocation: Security audits, credential leakage checks, and file permission reviews.

### senior-qa
- Purpose: Test automation strategies, widget smoke tests, and coverage analysis.
- Invocation: Generating test suites and verifying regression baselines.

### ponytail
- Purpose: Lazy senior developer mode enforcing minimum viable diffs and standard libraries.
- Invocation: General coding, refactoring, and dependency evaluation.

### systematic-debugging
- Purpose: Root cause analysis and step-by-step diagnostic loops before proposing code fixes.
- Invocation: Unexpected test failures, exceptions, and runtime bugs.

### git-commit-helper
- Purpose: Conventional and descriptive git commit message generation.
- Invocation: Commit preparation and staged changes review.

### ui-craft
- Purpose: Anti-slop UI design system enforcement, accessibility, and token discipline.
- Invocation: UI component creation, layout polishing, and visual refinement.

## 3. Built-in Agents

### explore / explorer
- Purpose: High-speed read-only codebase exploration, glob search, and keyword discovery.
- When to use: Locating files, manifests, configuration values, and structural overviews.

### reviewer
- Purpose: Bug inspection, security diagnostics, and code quality audits.
- When to use: Reviewing pull requests, scanning for defect markers, and vulnerability audits.

### codebase-memory-scout
- Purpose: Rapid positive provisional lookups in the knowledge graph.
- When to use: Finding symbol definitions, call traces, and structural dependencies.

### codebase-memory-auditor
- Purpose: Comprehensive bounded-scope graph verification and coverage audit.
- When to use: Verifying exhaustiveness, refactor candidates, and dead-code detection.

### general
- Purpose: General-purpose reasoning and execution of multi-step parallel work.
- When to use: Complex operations combining shell execution, file synthesis, and analysis.

## 4. Behavior Rules
*Note: Behavior rules are NOT skills. Skills provide procedural domain knowledge and tool workflows; behavior rules govern agent decision-making, code minimalism, and communication style across all skills.*

- **Andrej Karpathy Coding Guidelines**:
  - Think Before Coding (surface tradeoffs, no speculative assumptions)
  - Simplicity First (minimum necessary code, no unrequested abstractions)
  - Surgical Changes (touch only requested lines, never gratuitously reformat adjacent code)
  - Goal-Driven Execution (define verifiable tests and loop until passing)
- **Lazy Senior Developer (Ponytail)**:
  - Prefer stdlib and native platform features over third-party packages
  - Shortest working diff wins; mark deliberate simplifications with `ponytail:` comments
- **Terse Caveman Mode**:
  - Drops filler, hedging, and pleasantries in chat responses while preserving technical identifiers verbatim

## 5. MCP Servers
*Note: MCP servers are NOT skills. They are external protocol adapters exposing tool APIs to the runtime.*

- **codebase-memory-mcp**:
  - Transport: Local STDIO subprocess (`codebase-memory-mcp.exe`)
  - Tools: `get_graph_schema`, `get_architecture`, `query_graph`, `search_graph`, `trace_path`, `get_code_snippet`, `check_index_coverage`, `detect_changes`
- **antigravity**:
  - Transport: Antigravity runtime internal MCP
  - Tools: `models`, `read_mcp_resource`, `session_move`, `session_rename`, `worktree_create`

## 6. Recommended Skills to Install
- `flutter-test-gen`: Automated golden test generation for responsive multi-screen layouts
- `native-android-expert`: JNI/NDK optimization for C++ Vulkan real-esrgan compute bindings

## 7. Selection Protocol
1. **Identify Problem Domain**: Determine whether task relates to architecture, UI, security, or debugging.
2. **Consult Behavioral Guardrails**: Apply Karpathy guidelines and Ponytail rules to check if code needs to exist at all.
3. **Select Specialized Agent**: Delegate read-only discovery to `explore`, graph queries to `codebase-memory-scout`, and auditing to `reviewer`.
4. **Invoke Minimum Skill Set**: Load only skills directly pertinent to the active phase.
5. **Anti-patterns to Avoid**:
   - Calling multiple overlapping UI skills on backend code
   - Calling security audits on pure documentation tasks
   - Treating behavior rules or MCP servers as invocable skills

## 8. Permission Surface
| Action | Resource | Effect |
|--------|----------|--------|
| Read | Repository files, logs, manifests | Allowed (unrestricted) |
| Write | `0ai_context/**` | Allowed |
| Write | Source files, tests, configs outside `0ai_context/` | Forbidden (locked) |
| Shell | Read-only commands (`git status`, `git log`, read-only linters) | Allowed |
| Shell | Destructive or modifying commands (`git commit`, format write) | Forbidden |

## 9. Archive Policy
This file is append-only for tool and skill history. Installed skills and agent inventories are re-verified dynamically at runtime. Historical capabilities and previous evaluations are retained in section 10.

## 10. Change Log
### 2026-11-04
- Initial enumeration of 34 system skills, 7 built-in agents, 2 MCP servers, and active behavioral rules during context mapping v6.0 run.
