# Report 117 — Mapper Refresh #2 (Close 030, Register 036, Fix Numbering Drift)

- Date: 2026-11-12
- Type: mapper refresh (no code changes)
- Baseline: commit `4dec917` (`fix(privacy): narrow UI $e to generic copy (batch 3/3)`)
- Status: RESOLVED

## Purpose

Bring the mapper state in line with reports 114–116 (AUDIT-20261108-030 fully
closed), register the dual-`findings.json` infrastructure issue found while
writing report 113, and correct the report-number drift that refresh #1 left
behind.

## Before / After Counts

| Item | Before | After |
|---|---|---|
| `findings.json` entries | 16 | 17 |
| Active findings | 6 (020, 024, 027, 028, 030, 035) | 6 (020, 024, 027, 028, 035, 036) |
| Resolved findings | 10 | 11 |
| `index.json.next_report_number` | 113 | 118 |
| HANDOFF `next_n` | 113 | 118 |
| `index.json` report entries | 5 | 10 |
| `reports/INDEX.md` entries | 8 | 13 |
| `handoff-diff.resolved` | 10 | 11 |
| `handoff-diff.added` | 6 | 7 |
| `handoff-diff.persisted` | 4 | 5 |

## Numbering Drift Correction

Refresh #1 (report 113) set `next_report_number: 113` and `next_n=113`, but 113
was the number of refresh #1 itself. The next available number therefore was
114 — and by the time of this refresh, 114, 115, and 116 already existed on
disk. Both counters now point at **118**, the next unused number (117 = this
report, 118 = the streaming-hash fix).

## `0ai_context/findings.json`

- `AUDIT-20261108-030`: `status` `active` → `resolved`,
  `resolved_by: "reports 114-116"`.
  - Batch 1 (report 114): 5 log-only sites in `main.dart` and
    `user_news_bookmark_service.dart`.
  - Batch 2 (report 115): 6 UI-visible sites in `recent_history_screen.dart`.
  - Batch 3 (report 116): 3 SnackBar sites in `process_screen.dart` and
    `success_screen.dart`.
  - Total: 14/14 sites narrowed.
- New entry `AUDIT-20261108-036` (P3, infra, active):

  > Dual findings.json locations: 0ai_context/findings.json (canonical,
  > created report 113) and 0ai_context/raw/findings.json (stale pre-113
  > snapshot). Mapper tooling must pick one path.

  Registered active until the tooling decision is made. `0ai_context/raw/findings.json`
  was deliberately left untouched.

## `0ai_context/index.json`

- `next_report_number`: 113 → 118.
- Appended entries: 114 (`fix`), 115 (`fix`), 116 (`fix`), 117 (`mapper`),
  118 (`fix`).

## `0ai_context/HANDOFF.md`

- §1: HEAD `cc05293` → `4dec917`; executive summary now covers reports 114–116
  and the 036 registration.
- §4: HEAD refreshed; test count stays 224/224, exit codes 0.
- §9: unchanged in substance — still 6 active findings (0 P0, 0 P1, 1 P2,
  5 P3), because resolving P3 030 and adding P3 036 cancel out.
- §10: 030 removed from the active table, 036 added; the resolved-by line now
  covers reports 105-116 and includes `AUDIT-20261108-030`.
- §15: next actions point at report 118 (finding 035) and the 036 decision.
- §16: generated at `4dec917`; `next_n=113` → `next_n=118`.

## `0ai_context/reports/INDEX.md`

Appended 114, 115, 116, 117, and 118 entries (117 and 118 are pre-registered so
the index is complete after both phases of this run).

## `0ai_context/handoff-diff-2026-11-12.json`

- `generated_at`: refreshed to `2026-11-12T23:10:00+07:00`.
- `resolved`: 10 → 11 (added `AUDIT-20261108-030`).
- `added`: 6 → 7 (added `AUDIT-20261108-036`).
- `persisted`: now `[020, 024, 027, 028, 035]`.
- `health_change`: unchanged (analyze/format unchanged, test `216/216 → 224/224`).

## Verification (Gate A)

- `python -m json.tool 0ai_context/findings.json` → exit 0
- `python -m json.tool 0ai_context/index.json` → exit 0
- `python -m json.tool 0ai_context/handoff-diff-2026-11-12.json` → exit 0
- `"status": "resolved"` count → 11
- `"status": "active"` count → 6
- `AUDIT-20261108-036` in HANDOFF → ≥ 1 hit
- `next_report_number` → 118
- `next_n=118` in HANDOFF → 1 hit

## Next

Phase B of this run: report 118 — replace `File.readAsBytes()` with
`file.openRead().transform(sha256).first` in `SuccessScreen.computeFileHash`
(AUDIT-20261108-035), plus 5 new tests in `test/compute_file_hash_test.dart`.
