# HERMES-LEARNING-PROTOCOL.md — Skill Growth as First-Class Workflow

## 1. Principle

Hermes autonomously patches and creates skills at the end of every turn
via self-improvement review. Prompt-level prohibitions have failed three
times. This is platform behavior, not model disobedience. Reframe: skill
growth is a feature to be directed, not suppressed.

## 2. The One-Sprint-Delayed Loop

Because the patch happens AFTER the assistant's response is finalized,
in-turn verification is impossible. The workflow is:

- Sprint N preflight: **verify what Sprint N-1 learned**.
- Sprint N directive: **declare what Sprint N should learn**.
- Sprint N+1 preflight: **verify Sprint N's learning landed**.

This delay is acceptable. It produces a clean audit trail without
attempting to observe a mutation while it is being written.

## 3. Mandatory Preflight Blocks (every sprint)

### Block L1 — Skill Delta Audit (read-only)
```
stat -c '%y %s %n' "C:/Users/Administrator/AppData/Local/hermes/skills/devops/*/SKILL.md"
sha256sum "C:/Users/Administrator/AppData/Local/hermes/skills/devops/*/SKILL.md"
```
Compare against the fingerprint captured at end of the previous sprint
(see Block L4). Report:
- Which skill files changed (mtime, size, hash delta).
- Which skill files are new.
- Verdict: `delta matches Sprint N-1 directive` | `unexpected delta` |
  `no delta`.

### Block L2 — Learning Readback (read-only)
Read the tail of every skill file that changed in L1. Report:
- Any new section, rule, or example added.
- Whether the addition captures the CORRECTION or the MISTAKE from the
  prior sprint.
Verdict: `learning correct` | `learned wrong lesson — prune directive
required` | `unclear`.

### Block L3 — Skill Inventory
```
hermes skills list
```
Confirm the skill inventory against `0ai_context/SKILLS.md`. If new
skills appeared, list them and their target area.

### Block L4 — Pre-Sprint Fingerprint (closes the loop)
Capture the CURRENT skill fingerprints (stat + sha256) and record them
in the sprint report. This becomes the reference for Block L1 of the
NEXT sprint.

## 4. Mandatory Learning Directive Block (every sprint)

Immediately after the SKILL LOADING block, add:

```
LEARNING DIRECTIVE (MANDATORY):
  Acquire:
    - <pattern-name>: <one-line description of what to learn>
    - <pattern-name>: <one-line description>
  Do NOT acquire:
    - <anti-pattern observed last sprint>
    - <anti-pattern that may appear this sprint>
  Prune:
    - <skill-file:section that is now inaccurate>
  Preserve:
    - <existing pattern still valuable — do not modify>
```

The directive is declarative, not imperative. It tells Hermes what the
sprint is a good lesson FOR. Hermes decides HOW to encode it.

## 5. Rules for Correct Learning

1. **Corrections win.** If a sprint fixes a bug, the skill must record
   the corrected pattern, not the buggy one. The directive's "Acquire"
   block is the mechanism.
2. **Blocked items do not become patterns.** If a sprint marks an item
   BLOCKED (e.g., P2-L), do not learn the blocker as a solution. The
   "Do NOT acquire" block explicitly prevents this.
3. **Rolled-back work is not a pattern.** If a fix was reverted, do not
   learn the reverted approach.
4. **Skipped tests are not patterns.** If a test was skipped with a
   misleading title (as in Sprint 3), do not learn the skip-with-title
   pattern. Learn the "remove false green" pattern instead.
5. **One directive, one pattern.** Do not bundle multiple learning goals
   in one sprint. Skills grow by accretion, not bulk writes.

## 6. Post-Sprint Reports

Every sprint report must include a new section:

## Skill Delta (this sprint)
- Files changed: <list with mtime>
- Files created: <list>
- Pre-sprint fingerprint: <hash list>
- Directive issued: <verbatim>
- Expected next-sprint verification: <what Sprint N+1 will check>

## 7. When to Prune

Pruning is required when Block L2 returns `learned wrong lesson`. The
prune directive in the next sprint's LEARNING DIRECTIVE block must name
the specific skill section. The only file writes allowed to skill
locations are Hermes's own patch mechanism; pruning is a directive that
Hermes encodes by revising the skill on its next patch cycle.
