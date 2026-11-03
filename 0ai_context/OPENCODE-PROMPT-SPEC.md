# OpenCode Prompt Specification

Canonical spec for `=== OPENCODE PROMPT ===` blocks produced by AI chat
(Gemini / DeepSeek / Claude) after reading `0ai_context/HANDOFF.md`.

Referenced by:
- `HANDOFF.md` §AI INSTRUCTIONS (inline, abbreviated)
- `OpenCode-Bootstrap-Prompt.txt` Phase 11 (embed reference)
- Any executor prompt (validates incoming prompt against this spec)

Status: STABLE · Version 1.0 · Generated 2026-11-04

## 1. Purpose

An OpenCode prompt is a machine-readable instruction produced by an AI chat
assistant to be consumed by an OpenCode executor agent. It must be:

- Self-contained: everything the executor needs is in the block
- Safe: whitelist prevents scope creep; verification prevents silent regression
- Verifiable: every section is checkable by a script
- Reversible: rollback path is explicit

Non-goals: the prompt is NOT a discussion. It is NOT a plan. It is a single
atomic action with measurable success criteria.

## 2. Required Structure

Eight sections, in this exact order, delimited by markers:

```
=== OPENCODE PROMPT — <title> ===

## Task
## Context
## Files to modify (whitelist)
## Files NOT to modify
## Steps
## Verification (mandatory)
## Rollback
## Report back

=== END PROMPT ===
```

Opening and closing delimiters are exact. The `—` is em-dash, not hyphen.
Title is a short noun phrase ≤60 chars, kebab-case preferred.

## 3. Section Requirements

### 3.1 `## Task` — MANDATORY
One paragraph ≤4 sentences. Must answer: what to do (action verb), why (link to
a specific finding ID from HANDOFF §10), how success is measured.

### 3.2 `## Context` — MANDATORY
3–5 bullets. Each bullet traceable to a HANDOFF section. No new facts.

### 3.3 `## Files to modify (whitelist)` — MANDATORY
Exhaustive list of writable files. One path per line, `- ` prefix. Special
value `none` for investigation-only tasks.

### 3.4 `## Files NOT to modify` — MANDATORY
Defensive statement. Preferred value: `everything else` with 1–2 specific
exclusions if applicable.

### 3.5 `## Steps` — MANDATORY
3–7 numbered atomic actions. No "while you're at it" implicit scope.

### 3.6 `## Verification (mandatory)` — MANDATORY
Exact commands. Each must include: command, expected result, source (HANDOFF §3).

### 3.7 `## Rollback` — MANDATORY
Single-line instruction. Safe to execute without judgment. `git checkout -- <file>`
is canonical. NO "fix forward".

### 3.8 `## Report back` — MANDATORY
What the executor must return. Structured format that enables before/after
comparison. WAJIB mencetak `git status --short` di terminal agar user tahu file yang berubah. AI Chat WAJIB menginstruksikan Executor untuk mengembalikan output dalam format key-value (status, report, task_status, tests_status, git_status, next). Dilarang menggunakan teks paragraf bebas.

## 4. Validation Rules (for executors)

Before editing, validate the incoming prompt:

FAIL conditions (refuse to execute):
1. Missing `=== OPENCODE PROMPT —` or `=== END PROMPT ===` delimiter
2. Any of the 8 sections missing or empty
3. `## Files to modify` section does not exist
4. `## Verification` contains no commands (no backticks)
5. `## Rollback` missing or contains "fix forward"
6. `## Task` references >1 finding ID

WARN conditions (execute but note):
1. More than 7 steps
2. Whitelist contains a directory instead of a file
3. Verification commands not present in HANDOFF §3
4. Context bullets not traceable to a HANDOFF section

## 5. Anti-Patterns

| Anti-pattern | Why it fails |
|---|---|
| "Refactor the whole module" | Unverifiable, no rollback, unbounded |
| "Fix all P2 findings" | Multiple findings = no isolated failure |
| Whitelist = `lib/**` | Executor can touch anything |
| Verification = "run tests" | No expected exit code |
| Rollback = "fix forward" | Doubles risk if original was wrong |
| Task references 5 sections | Executor must re-read; snippet missing |
| Report back = "summarize" | No structure, no comparison |

## 6. Reference Example (Full)

```
=== OPENCODE PROMPT — fix-silent-catch-ffmpeg-stage-input ===

## Task
Fix AUDIT-20261104-005 (P1, silent catch in `stageInputFile`). Replace the
empty `catch (_)` block at `lib/core/services/ffmpeg_service.dart:293` with
targeted `FileSystemException` handling that logs and rethrows.

## Context
- Finding: AUDIT-20261104-005 at `lib/core/services/ffmpeg_service.dart:293`
- Snippet: HANDOFF §11 Snippet 5
- Existing pattern: line 118 area uses debugPrint with [FfmpegService] prefix
- Constraint: HANDOFF §14 — offline-first

## Files to modify (whitelist)
- lib/core/services/ffmpeg_service.dart

## Files NOT to modify
Everything else. Do not touch test/ffmpeg_service_test.dart.

## Steps
1. Read lines 280–310 of ffmpeg_service.dart.
2. Replace `catch (_) {}` with `catch (e) { debugPrint('[FfmpegService] staging failed: $e'); rethrow; }`.
3. Confirm rethrow propagates to processVideo.
4. Run verification.

## Verification (mandatory)
- `dart analyze --fatal-infos` — expected exit 0 (HANDOFF §3)
- `flutter test test/ffmpeg_service_test.dart` — expected "All tests passed!" (HANDOFF §3)
- `grep -c 'catch (_) {}' lib/core/services/ffmpeg_service.dart` — expected 0

## Rollback
`git checkout -- lib/core/services/ffmpeg_service.dart`, report failure, stop.

## Report back
Bahasa Indonesia: diff summary, verification exit codes (before vs after),
whether empty catch at 293 is gone, unexpected output.

=== END PROMPT ===
```

## 7. Integration Points

| Consumer | Usage |
|---|---|
| `HANDOFF.md` §AI INSTRUCTIONS | Abbreviated — this file is canonical |
| AI chat | Should follow this spec when producing prompts |
| OpenCode executor | Validates against §4 before editing |
| `OpenCode-Bootstrap-Prompt.txt` Phase 11 | References this spec |
| `OpenCode-Bootstrap-Prompt.txt` Phase 12 | Validates HANDOFF references this spec |

## 8. Version History

- **1.0** (2026-11-04) — Initial spec. 8 mandatory sections, 6 FAIL rules,
  7 anti-patterns.

## 9. Chat Continuity (For AI Chat)
Setiap AI Chat menghasilkan prompt, WAJIB menyertakan blok `### CONTINUITY UPDATE` berisi ringkasan fokus dan next action.
