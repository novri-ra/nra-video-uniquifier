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
| Phase 6 | `archive/phase6-ffmpeg-fixes/` | Report 140: FFmpeg buffer queue overflow fix, muxer queue depth guard, CFR enforcement, dead code cleanup |
| Phase 7 | `archive/phase7-preview-audit/` | Report 141: Popup Preview lifecycle audit, effect stacking stress test, and dead-code inventory |

## Phase 6 Highlights (Report 140)

- **Buffer Overflow Fix**: `fifo` drain node inserted in filtergraph; `-max_muxing_queue_size 20` added.
- **Frame Rate Lock**: CFR enforcement (`-fps_mode cfr -r 30`) to stabilize PTS timing.
- **Dead Code Cleanup**: Removed `MicrostockAiScreen` reference, duplicate `cropZoomScale` parameter, stale `crop` fallback.

## Phase 7 Highlights (Report 141)

- **Popup Preview Lifecycle**: `_previewDebounceTimer` properly disposed in `dispose()`, `requestFilteredPreviewDebounced()`, and `clearSelection()`. `_isDisposed` guard checked before all timer/render actions.
- **Effect Stacking Stress Test**: All 10 visual/audio effects + 4K upscale enabled simultaneously tested. Buffer overflow prevented via `-max_muxing_queue_size 20` and `fifo` drain node. CFR mode (`-fps_mode cfr -r 30`) stabilizes PTS. No deadlocks or overflow errors observed.
- **Dead Code Inventory**: `cropZoomScale` parameter identified as dead weight (passed but never applied). Duplicate `crop` fallback already removed in Report 140. `MicrostockAiScreen` reference cleaned in prior phases.

## Active Reports

- **139** — Deep System Audit (`reports/139-deep-system-audit.md`).
- **140** — FFmpeg Buffer Queue & Dead Code Fix (`reports/140-fix-ffmpeg-buffer-queue-and-dead-code.md`).
- **141** — Popup Preview & Effect Stacking Audit (`reports/141-popup-preview-and-effect-stacking-audit.md`).

See `0ai_context/findings.json` for the authoritative finding state and
`0ai_context/index.json` for report→path mappings.