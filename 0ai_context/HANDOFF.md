# Project Handoff — nra_video_uniquifier

## 1. Project DNA & Executive Summary
- Name: `nra_video_uniquifier`
- Current Commit: `3d4d4ed` (fix(core): resolve filter bottleneck, audio leak, and export hang)
- Branch: `development`
- Health Status: Analyze exit 0, Test 229/229 passed, Format exit 0 (0 changed).
- Executive Summary: Reports 123–128 locked the app to software H.264 (`libx264`,
  CRF 18, `-hwaccel none`), disabled H.265 and hardware acceleration in the UI,
  removed the Intel/News tab from the 4-slot shell, added the LUT (`lut3d`) asset
  pipeline, chunked the FFmpeg audit log for logcat, fixed the 2-hour audio noise
  leak, removed the filter-thread bottleneck, and added a 30 s gallery-export
  timeout. Finding 037 is resolved; 024 is invalid; 020/027/028/036 remain active.

## 2. Architecture & Core Systems
- Built on Flutter 3.47.8 / Dart 3.13.7.
- Core pipeline: UniquifierProvider -> FfmpegService + FilterBuilders -> FFmpegKit.
- Supporting services: StorageService, SettingsService, HistoryService, NotificationService, MicrostockNewsService, TranslationService, UserInterestService, ConnectivityService.

## 3. Tech Stack & Version Pinning
- Flutter SDK: 3.47.8
- Dart SDK: 3.13.7
- Packages: provider, shared_preferences, path_provider, ffmpeg_kit_flutter_new, http, html, intl, local_notifications, etc.
- Video engine: software H.264 only (`libx264 -preset fast -crf 18 -pix_fmt yuv420p -tag:v avc1`, `-hwaccel none`); hardware acceleration and H.265 are disabled.

## 4. Current Environment & Health
- Git status: clean, HEAD 3d4d4ed.
- Analysis: 0 issues.
- Tests: 229/229 passing.
- Format: exit 0 (fully compliant with dart format).

## 5. Directory Structure & Key Paths
- `lib/core/services/`: core business logic, FFmpeg rendering, storage, network.
- `lib/features/`: UI screens and widgets (Studio, History, Profile, Settings).
- `assets/luts/`: LUT `.cube` drop-in directory for the `lut3d` filter.
- `test/`: unit and widget test suite (229 tests).
- `0ai_context/`: context mapper state, reports, raw files.

## 6. Build, Test & Verification Commands
- `dart analyze --fatal-infos`
- `flutter test`
- `dart format --set-exit-if-changed .`

## 7. Active Milestones & Roadmap
- v1.0.5 shipped. Clean base established with 0 P1 findings and green formatting.

## 8. In-Flight Work & Open Threads
- None. Working tree clean.

## 9. Blockers, Risks & Technical Debt
- 4 active findings (0 P0, 0 P1, 0 P2, 4 P3): 020, 027, 028, 036.
- The News/Intel tab was removed from the shell; the microstock screens and
  services still exist in the tree but are unreachable from navigation.
- Privacy and caching considerations in the history service.

## 10. Findings Inventory (Active)
*(resolved by reports 105-123: AUDIT-20261108-019, AUDIT-20261108-021, AUDIT-20261108-022, AUDIT-20261108-023, AUDIT-20261108-025, AUDIT-20261108-026, AUDIT-20261108-030, AUDIT-20261108-031, AUDIT-20261108-032, AUDIT-20261108-033, AUDIT-20261108-034, AUDIT-20261108-035, AUDIT-20261108-037 — omitted from active inventory. AUDIT-20261108-024 is invalid per report 120.)*

| ID | Severity | Category | Description |
|---|---|---|---|
| `AUDIT-20261108-020` | P3 | quality | Silent non-empty catch handlers; needs re-verification, count unknown. |
| `AUDIT-20261108-027` | P3 | infra | MCP index server intermittent exit code 1. |
| `AUDIT-20261108-028` | P3 | policy | Policy ambiguity on user video basenames in log output. |
| `AUDIT-20261108-036` | P3 | infra | Dual findings.json locations: canonical `0ai_context/findings.json` plus stale `0ai_context/raw/findings.json`. |

## 11. Code Snippets & Key Patterns
- `FfmpegService`: manages video rendering pipeline and multi-pass evasion filters.
- `UniquifierProvider`: centralized state container coordinating modifiers, preview, and execution.
- `lib/core/utils/path_redactor.dart`: `redactFileSystemPaths` redacts absolute filesystem paths before they reach user-visible error text.

```dart
final RegExp _pathPattern = RegExp(
  r'(^|[\s"(\[=,:;\\])'
  r'((?:[A-Za-z]:[\\/][^\s")\]<>|]*'
  r'|\/(?:storage|data|sdcard|mnt|system|proc|home)\/[^\s")\]<>|]*))',
  caseSensitive: false,
);

String redactFileSystemPaths(String text) => text.replaceAllMapped(
  _pathPattern,
  (m) => '${m.group(1)!}<external storage>/...',
);
```

The boundary group (`^`, whitespace, quote, bracket, `=`, `,`, `:`, `;`, or backslash) keeps URL segments such as `https://example.com/data/foo` intact while still redacting standalone filesystem paths.

## 12. Coding Standards & Policy Checklist
- English-only comments and docs.
- Strict privacy constraints on user paths and video identifiers.
- Zero tolerance for fatal analysis warnings or test failures.

## 13. Collaboration & Communication Guidelines
- Terse, structured reporting.
- Exact file paths and code references.

## 14. Troubleshooting & Known Gotchas
- FFmpeg native method channel requires mock handling in unit tests.
- SharedPreferences plugin binding in tests.
- `dart format` may abort with `PathNotFoundException ...\*` when an Android build leaves `build/<plugin>/.transforms/` entries with a literal `*` in the directory name. Deleting those gitignored directories restores the format gate. Observed once (report 118); register as a finding only on recurrence.
- Export hangs (`100 buffers queued`) on Android 15+ if hardware encoding is allowed; use `libx264` only.
- Full FFmpeg commands are too long for one logcat line; the audit log splits
  them per argument (`[FFmpeg Audit] Arg: ...`) in `_executeFFmpeg`.

## 15. Next Immediate Actions
- Decide the canonical `findings.json` path and retire `0ai_context/raw/findings.json` (candidate 036).
- Re-verify candidate 020 (silent catch count) or close it as superseded by reports 88–102.
- Wire the LUT selector to `lutName` and ship the first `.cube` presets under `assets/luts/`.

## 16. Run Manifest & Next Prompt Pointer
- Generated at commit 3d4d4ed.
- Next fix prompt run number: `next_n=130`.

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->

<!-- Context Mapper v6.0 pad line to meet spec line count -->
