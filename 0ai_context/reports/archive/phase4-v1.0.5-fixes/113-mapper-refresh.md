# Report 113 — Mapper Refresh After Reports 105–112

- Date: 2026-11-12
- Type: mapper refresh (no code changes)
- Baseline: commit `cc05293` (`fix(privacy): expand ErrorScreen path redaction`)
- Status: RESOLVED

## Purpose

Bring the mapper state in line with the fixes shipped in reports 105–112 and register the candidates found during the post-106 source review (030–035).

## Before / After Counts

| Item | Before | After |
|---|---|---|
| `findings.json` entries | 10 | 16 |
| Active findings | 10 (stale list, no `status` field) | 6 |
| Resolved findings | 0 (no `status` field) | 10 |
| Newly registered candidates | 0 | 6 (030–035) |
| `index.json.next_report_number` | 104 | 113 |
| HANDOFF `next_n` | 105 | 113 |
| Test count in HANDOFF | 216/216 | 224/224 |
| `reports/INDEX.md` entries | 4 | 8 |

## `0ai_context/findings.json`

Added explicit `status` (`active` / `resolved`) and `resolved_by` fields.

Active (6): 020, 024, 027, 028, 030, 035.
- 020 description now carries the note "Needs re-verification, count unknown."

Resolved (10):
- 019 → report 106
- 021 → report 107
- 022 → report 105
- 023 → report 107
- 025 → report 106
- 026 → report 106
- 031 → report 111
- 032 → report 112
- 033 → report 113 (not reproducible on dev host)
- 034 → report 110

Candidate 033 was closed as not reproducible: reports 110, 111, and 112 all ran green on this host (216/216, then 224/224) with no `shaders/ink_sparkle.frag (SkSL)` / `Found stages: Vulkan` failures.

## `0ai_context/index.json`

- `next_report_number`: 104 → 113.
- Appended entries for reports 110, 111, 112 (type `fix`) and 113 (type `mapper`).

## `0ai_context/HANDOFF.md`

- §1: HEAD `aeb233b` → `cc05293`; test count 216/216 → 224/224; executive summary updated to reports 105–112.
- §4: HEAD updated; `Tests: 216/216` → `224/224`; exit codes unchanged.
- §5: test suite size 216 → 224.
- §9: active findings 10 (2 P2, 8 P3) → 6 (1 P2, 5 P3).
- §10: stale 10-item bullet list replaced with the resolved-by line (full IDs, so each resolved ID appears exactly once in the file) plus a 6-row active table.
- §11: added a snippet for `lib/core/utils/path_redactor.dart` and a sentence explaining the boundary-group URL preservation.
- §15: next actions now point at candidate 030.
- §16: generated-at commit `cc05293`; `next_n=105` → `next_n=113`.

## `0ai_context/reports/INDEX.md`

Appended entries for reports 110, 111, 112, and 113.

## `0ai_context/handoff-diff-2026-11-12.json`

- `generated_at`: `2026-11-12T21:48:04+07:00`
- `previous_handoff`: `null` (no 2026-11-08 archive exists; only `handoff/archive/HANDOFF-2026-11-04.md` is present, which is not the requested snapshot)
- `resolved`: the 10 IDs listed above
- `added`: 030, 031, 032, 033, 034, 035
- `persisted`: 020, 024, 027, 028
- `health_change`: `test: "216/216 → 224/224"`, `analyze`/`format`: `unchanged`

## Deviations From the Prompt (recorded, not hidden)

1. **`findings.json` location**: the prompt's whitelist and verification reference `0ai_context/findings.json`, but the live mapper previously wrote findings to `0ai_context/raw/findings.json`. Only the root path is whitelisted here, so this run created the canonical `0ai_context/findings.json` and left `raw/findings.json` untouched. A follow-up should either migrate tooling to the root path or explicitly whitelist the raw path.
2. **New-vs-modified count**: because `0ai_context/findings.json` is newly created, `git diff --stat` shows 3 modified files (HANDOFF, index, reports/INDEX) instead of the predicted 4; the total path count is still 6 once report 113 and the delta file are included.
3. **`added` count**: the prompt says "5 IDs" but 030–035 is 6 IDs and 10 existing + 6 new = the required 16 total. The delta file lists all 6.
4. **`AUDIT-20261108-019` grep**: expected 1 hit. The resolved-by line uses full IDs, and 019 appears nowhere else, so the count is 1 as expected.

## Verification

- `python -m json.tool 0ai_context/findings.json` → exit 0
- `python -m json.tool 0ai_context/index.json` → exit 0
- `python -m json.tool 0ai_context/handoff-diff-2026-11-12.json` → exit 0
- `AUDIT-20261108-019` in HANDOFF → 1 hit
- `AUDIT-20261108-030` in HANDOFF → 2 hits (active table + next actions)
- `next_report_number` → 113
- `next_n=113` in HANDOFF → 1 hit
- `git diff -w --exit-code -- 0ai_context/index.json` → exit 1 (content changed; output recorded)

`git diff --stat` at report-writing time:

```
 0ai_context/HANDOFF.md       | 60 ++++++++++++++++++++++++++++----------------
 0ai_context/index.json       | 24 ++++++++++++++++--
 0ai_context/reports/INDEX.md |  4 +++
 3 files changed, 64 insertions(+), 24 deletions(-)
```

## Next

Fix #4: candidate 030 — 14 raw `$e` interpolation sites in the UI layer, next fix report.
