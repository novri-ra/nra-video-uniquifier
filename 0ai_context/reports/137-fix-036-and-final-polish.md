# Report 137: Close AUDIT-20261108-036 & Final Polish for Release Readiness

## Overview
Closed AUDIT-20261108-036 (dual findings.json locations) by retiring `0ai_context/raw/findings.json` and making `0ai_context/findings.json` the single canonical source. Updated all documentation to reflect that the only remaining active findings are 027 and 028.

## 036 Closure Actions
1. **Marked AUDIT-20261108-036 as resolved** in `0ai_context/findings.json` via report 137. Status changed from `active` to `resolved`, resolved_by: `report 137`.
2. **Retired `0ai_context/raw/findings.json`** — this stale pre-113 snapshot is now obsolete; the canonical source is `0ai_context/findings.json` (confirmed deleted, directory no longer contains findings.json).
3. **Updated `0ai_context/HANDOFF.md` §9–§10**: Active findings reduced to 2 P3 items (027, 028). 020 and 036 marked resolved via reports 134–137.
4. **Updated `0ai_context/STATE.md` §10, §13, §15**: MCP flakiness (027), basename policy (028) are the only remaining active findings. 036 canonicalization completed.
5. **Updated `0ai_context/index.json`**: next_report_number bumped to 138; report 137 registered.

## Release Readiness
- `dart analyze --fatal-infos`: 0 issues found.
- `flutter test`: 240/240 tests passing.
- Version confirmed: pubspec.yaml 1.0.5+5 matches installed device.
- Release APK successfully built and installed on RMX1851 (5e599699), dumpsys confirmed versionName=1.0.5 versionCode=5.

## Documentation Consistency
- `CHANGELOG.md`: reviewed; no changes required for reports 131–136 (already captured in prior changelog entries).
- `pubspec.yaml`: version confirmed as 1.0.5+5, no bump needed.