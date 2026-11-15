# Report 160 — release: v1.1.0+6 Final Release & Production APK Build

## Metadata
- **Date**: 2026-11-15
- **Type**: release
- **Version**: 1.1.0+6
- **Status**: done
- **Target APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **Tests**: 229/229 passed
- **Analyze**: 0 issues (clean exit 0)
- **Active Findings**: 0 (Zero Active Findings maintained)

---

## Release Highlights (v1.0.5 -> v1.1.0)

Since the v1.0.5 release, 16 consecutive sprint reports (Reports 144–159) have completed the major v1.1.0 milestone:

### 1. Color Grading & 3D LUT Engine
- Full 3D LUT filterchain integration (`lut3d`) supporting bundled presets (`cinematic_warm.cube`) and custom user imports.
- Asset extraction helper (`FfmpegFileHelper.resolveLutPath`) extracting bundled assets to sandbox storage.
- Custom LUT file importer with strict validation (5MB size ceiling, `.cube` header checks `LUT_3D_SIZE`/`TITLE`).
- Active LUT visual indicators integrated into `ProcessingScreen`, `SuccessManifestCard`, and `BatchProcessingScreen`.

### 2. Enterprise Telemetry & Vault Dispatch
- Real-time HTTP POST telemetry integration dispatching diagnostic metrics to Google Sheets Webhook.
- Auto-dispatch of Video Metadata Vault specifications (`width`, `height`, `videoCodec`, `durationMs`, `platforms`, `keywords`) on successful render.
- Battery-friendly zero-drain online guard using event-driven `ConnectivityService` with silent offline fallback.

### 3. Storage & Export Flexibility
- Custom Export Directory feature powered by `FilePicker.platform.getDirectoryPath()` with Android `MANAGE_EXTERNAL_STORAGE` support.
- Prioritized resolution in `FfmpegFileHelper.resolveTargetDir()`, falling back cleanly to `/storage/emulated/0/Movies/Uniquifier`.
- Dedicated UI management card in `SettingsScreen` with one-tap "Reset to Default" action.

### 4. Dynamic Memory Budget & OOM Safeguard
- Mathematical Complexity Scoring (`DeviceCapabilityService.calculateComplexityScore`) dynamically assessing resolution, visual effects, and audio load.
- RAM tier safety budget thresholds (<4GB RAM: 40, 4-6GB RAM: 70, >6GB RAM: 100).
- Replaced static OOM heuristics with dynamic budget evaluation and informative user feedback.

### 5. Custom User Presets
- Full JSON configuration persistence in `SettingsService` for custom user presets.
- Snapshot and restore logic in `UniquifierPresetMixin` capturing 20+ modifier settings.
- Dynamic preset chip row and accessible "+ Save Preset" dialog workflow in `ModifiersCard`.

### 6. Accessibility & Hygiene
- Minimum 48x48dp touch targets and Semantics labels across all interactive chips and buttons.
- Clean remediation of all `use_build_context_synchronously` warnings.
- Maintained 0 Active Findings across the entire repository.

---

## Files Modified in Release Task

| File | Change |
|------|--------|
| `pubspec.yaml` | Upgraded `version: 1.0.5+5` -> `version: 1.1.0+6`. |
| `CHANGELOG.md` | Documented v1.1.0+6 additions, improvements, and fixes. |
| `0ai_context/*` | Synchronized all 8 Context Mapping files to Phase 8 milestone closure. |

---

## Artifact Details
- **Build Command**: `flutter build apk --release`
- **Output Artifact**: `build/app/outputs/flutter-apk/app-release.apk`
