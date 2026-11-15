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
| Phase 4 | `archive/phase4-v1.0.5-fixes/` | Reports 086–120: baseline audit, silent-catch remediation, privacy fixes |
| Phase 5 | `archive/phase5-v1.0.5-audit/` | Reports 123–138: stability and quality, LUT setup, navigation tests, FFmpeg stall audit, filter bottlenecks, audio leaks, mapper refreshes, and context migration |
| Phase 6 | `archive/phase6-ffmpeg-fixes/` | Reports 139–140: Deep system audit, FFmpeg buffer queue overflow fix, muxer queue depth guard, CFR enforcement, dead code cleanup |
| Phase 7 | `archive/phase7-preview-audit/` | Reports 141–142: Popup Preview lifecycle audit, effect stacking stress test, dead-code inventory, and OOM adaptive resource safeguards |

## Phase 8 Highlights (Report 143)

- **Deep System Audit & Context Synchronization**: Complete repository hygiene pass, archival of reports 123–142, creation of Report 143, and 100% synchronization of all 8 Context Mapping Files.

## Active Reports

- **144** — LUT (Color Grading) Feature End-to-End Wiring (`reports/144-feat-lut-wiring.md`).
- **145** — Fix LUT Absolute Path Resolution & Asset Extraction (`reports/145-fix-lut-absolute-path.md`).
- **146** — Hygiene Cleanup: Findings 020 & 036 Closure (`reports/146-chore-hygiene-cleanup.md`).
- **147** — LUT Preset Expansion & ModifiersCard UI Selector (`reports/147-feat-lut-preset-expansion.md`).
- **148** — LUT Full P1 Wiring for Batch, Startup, and Preview Filter Chain (`reports/148-fix-lut-wiring-p1.md`).
- **149** — Custom LUT Import Feature & Absolute Path Resolution (`reports/149-feat-custom-lut-import.md`).
- **150** — Hardening Custom LUT Import Feature (`reports/150-chore-harden-custom-lut-import.md`).
- **151** — Resolve Final P3 Findings & Achieve Zero Active Findings (`reports/151-chore-resolve-final-p3-findings.md`).
- **152** — UI Polish - Active LUT Indicator on ProcessingScreen and SuccessManifestCard (`reports/152-feat-ui-lut-indicator-and-manifest.md`).
- **153** — Google Sheets Telemetry Integration via HTTP POST (`reports/153-feat-enable-google-sheets-telemetry.md`).
- **154** — Auto-Dispatch Video Metadata Vault Telemetry (`reports/154-feat-auto-dispatch-video-metadata-vault.md`).
- **155** — LUT Selector & Custom Import Accessibility Polish (`reports/155-feat-a11y-lut-selector-polish.md`).

See `0ai_context/findings.json` for the authoritative finding state and
`0ai_context/index.json` for report→path mappings.
