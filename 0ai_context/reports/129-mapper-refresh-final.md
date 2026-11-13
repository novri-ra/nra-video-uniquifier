# Report 129 — Mapper Refresh (Final Sync, Reports 123–128)

**Date:** 2026-11-14
**Type:** mapper
**Status:** Done — context files synchronized; no code touched
**Base commit:** `3d4d4ed fix(core): resolve filter bottleneck, audio leak, and export hang`

---

## 1. Preflight

- `git status --short` → clean
- `git log --oneline -1` → `3d4d4ed`
- `index_status` → `nra_video_uniquifier`, status ready, 2908 nodes / 7070 edges,
  snapshot `2026-11-13T14:31:12Z`, `watch.watched=false`

---

## 2. `0ai_context/findings.json`

| ID | Change |
|---|---|
| `AUDIT-20261108-037` | **Added** (it was missing from the file) and marked `resolved`, `resolved_by: "report 123"`. P2 / privacy: `_cleanupOldPreviews` logged the absolute preview path and raw `$e`. |
| `AUDIT-20261108-024` | `active` → `invalid`, `resolved_by: "report 120 (premise invalid)"`. The three temp-cache walks diverge, so the duplication premise does not hold. |
| 019/021/022/023/025/026/030–035 | unchanged, `resolved` |
| 020, 027, 028, 036 | unchanged, `active` |

Final state: **13 resolved, 1 invalid, 4 active**.

---

## 3. `0ai_context/index.json`

- `next_report_number`: `121` → **`130`**.
- Appended entries:

| # | Type | Path |
|---|---|---|
| 123 | fix | `reports/123-ultimate-stability-and-quality.md` |
| 124 | fix | `reports/124-master-fix-and-lut-setup.md` |
| 125 | fix | `reports/125-fix-navigation-tests.md` |
| 126 | audit | `reports/126-audit-ffmpeg-stall.md` |
| 127 | fix | `reports/127-fix-audit-logging.md` |
| 128 | fix | `reports/128-fix-filter-bottleneck-and-audio-leak.md` |
| 129 | mapper | `reports/129-mapper-refresh-final.md` |

Reports 123–125 were already on disk but absent from the index; they were added
here so the index is complete (see §7, deviation 2).

---

## 4. `0ai_context/SEED.md`

- §1 Overview: dropped the "microstock news reader" wording (the tab is gone).
- §2 Stack: added
  `- Engine: Software H.264 (libx264) locked for 100% stability`.
- §6 Module Inventory: UI Features is now
  `Studio (ModifiersCard, Preview, ProcessingScreen), History, Profile, Settings`
  — "Microstock News & Reader" removed. `MicrostockNewsService` stays listed
  because the service file still exists.
- §9 Constraints: added
  `Hardware Acceleration and H.265 are intentionally disabled to prevent Android 15+ MediaCodec hangs.`
  and refreshed the test gate to `229/229`.

---

## 5. `0ai_context/STATE.md`

- §1: engine line added (`libx264`, `-preset fast -crf 18`, `-hwaccel none`).
- §2: head `aeb233b` → `3d4d4ed`, clean tree.
- §3: git history snapshot refreshed (3d4d4ed / fbeb09f / 108b937 / 1e42095).
- §4: tests `216/216` → **`229/229`**.
- §5: index health refreshed to 2908 nodes / 7070 edges.
- §6–§8: milestone, completed work (reports 123–128).
- §12 Structural Debt: records that the News/Intel tab is removed (4 tabs:
  Home, Studio, History, Profile) and that the microstock screen/services remain
  but are unreachable; active findings corrected to 4 (020, 027, 028, 036).
- §13 security risks: 022 resolved, 024 invalid, 037 resolved.
- §15/§16: next actions and run manifest at `3d4d4ed`.

---

## 6. `0ai_context/HANDOFF.md`

| Section | Update |
|---|---|
| §1 | commit `2e92723` → `3d4d4ed`; executive summary rewritten for reports 123–128 |
| §3 | video-engine bullet: `libx264 ... -hwaccel none`, HW accel + H.265 disabled |
| §4 | HEAD `3d4d4ed`; tests `229/229` |
| §5 | features → Studio, History, Profile, Settings; `assets/luts/` added; no Microstock |
| §9 | 5 → 4 active findings (0 P2); News tab removal note |
| §10 | 024 row removed; footnote now lists 037 resolved and 024 invalid |
| §14 | gotcha: `100 buffers queued` on Android 15+ if hardware encoding is allowed → `libx264` only; plus the per-argument audit log note |
| §15 | added LUT selector/`lutName` wiring as the next post-pivot step |
| §16 | `next_n=120` → **`next_n=130`** |

---

## 7. Whitelist deviations (explicit)

1. **`0ai_context/run.md` does not exist.** The live mapper run log is
   `0ai_context/raw/run.md` (previously from 2026-11-08, commit `aeb233b`), so
   that file was updated with the report-129 summary instead of creating a
   duplicate run log at a new path.
2. **`index.json` also lacked 123–125.** Only 126–129 were requested, but those
   three reports exist on disk and were missing from the index; all seven were
   added. No report is now unindexed.
3. **`AUDIT-20261108-037` had no existing entry.** It was created with
   severity P2 / category privacy (matching report 123 §4) and marked resolved,
   rather than only flipping a status that did not exist.
4. **`SEED.md` §1** was edited in addition to §2/§6/§9, because the Overview still
   said "microstock news reader" and would have failed the mandatory
   `grep -in 'microstock news'` = 0 gate.

No file outside `0ai_context/` was touched; `lib/`, `test/`, `pubspec.yaml`, and
existing reports are unchanged.

---

## 8. Verification

| Check | Expected | Result |
|---|---|---|
| `python -m json.tool 0ai_context/findings.json` | exit 0 | **0** |
| `python -m json.tool 0ai_context/index.json` | exit 0 | **0** |
| `"status": "resolved"` count | 13 | **13** |
| `"status": "invalid"` count | 1 | **1** |
| `"next_report_number"` | 130 | **130** (line 2) |
| `next_n=130` in HANDOFF | 1 hit | **1** (line 111) |
| `microstock news` in SEED + HANDOFF | 0 hits | **0** |
| `git diff --stat` | 6–7 files under `0ai_context/` | 6 files (§7 notes) |

> Note: PowerShell maps `> NUL` to an unsupported device; the JSON gate was run
> as `python -m json.tool <file> | Out-Null` (same validation, exit 0).

---

## 9. Files Changed

- `0ai_context/findings.json`
- `0ai_context/index.json`
- `0ai_context/SEED.md`
- `0ai_context/STATE.md`
- `0ai_context/HANDOFF.md`
- `0ai_context/raw/run.md` (see §7.1)
- `0ai_context/reports/129-mapper-refresh-final.md` (this report)

## 10. Rollback

```bash
git checkout -- 0ai_context/SEED.md 0ai_context/STATE.md 0ai_context/HANDOFF.md \
               0ai_context/findings.json 0ai_context/index.json \
               0ai_context/raw/run.md
rm -f 0ai_context/reports/129-mapper-refresh-final.md
```

No commit was made.
