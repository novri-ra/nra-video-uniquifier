# Reports Index

Active and recent reports for this project live under `archive/` by phase.
New reports should still be written directly to `0ai_context/reports/` and are
moved into the current phase folder once that phase closes.

## Archived Phases

| Phase | Folder | Scope |
|---|---|---|
| Phase 1 | `archive/phase1-foundation/` | Foundation work and initial architecture |
| Phase 2 | `archive/phase2-polish-and-v1.0.0/` | Polish leading up to v1.0.0 |
| Phase 3 | `archive/phase3-v1.0.1-to-v1.0.3/` | Releases v1.0.1 – v1.0.3 |
| Phase 4 | `archive/phase4-v1.0.5-fixes/` | Reports 086–120: baseline audit, silent-catch remediation (88–102), privacy fixes (105–112), AUDIT-20261108-030 narrowing (114–116), mapper refreshes (113, 117, 119), streaming hash fix (118), and the stopped temp-cache extraction (120) |

## Phase 4 Highlights (reports 086–120)

- **086–087** — pre-remediation audit and out-of-scope notes.
- **088–102** — 89 empty/silent catch handlers resolved across 23 files, plus
  privacy fixes and the format gate.
- **103** — post-remediation baseline audit at commit `aeb233b`.
- **105–112** — cache-log privacy leak, P3 batch (i18n + exception prefix),
  privacy/ordering batch, native crash flags, blur slider crash, preset
  comment translation, thumbnail silent catch, and filesystem path redaction.
- **113 / 117 / 119** — mapper refreshes: candidates 030–036, numbering
  corrections, and closure of resolved findings.
- **114–116** — AUDIT-20261108-030: 14/14 raw `$e` sites narrowed.
- **118** — streaming SHA-256 in `SuccessScreen.computeFileHash` (+5 tests).
- **120** — temp-cache walk extraction stopped: implementations diverge
  (24-hour age gate, no walk in `ffmpeg_file_helper.dart`).

See `0ai_context/findings.json` for the authoritative finding state and
`0ai_context/index.json` for report→path mappings.
