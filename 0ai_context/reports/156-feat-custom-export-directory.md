# Report 156 — feat: Custom Export Directory via File Picker

## Metadata
- **Date**: 2026-11-15
- **Type**: feat
- **Task**: feat-custom-export-directory-156
- **Status**: done
- **Tests**: 229/229 passed
- **Analyze**: 0 new issues (4 pre-existing infos in modifiers_card.dart — unchanged from baseline)

---

## Summary

Activated the custom export directory feature end-to-end:

1. **`FfmpegFileHelper.resolveTargetDir()`** now reads `SettingsService.getCustomOutputPath()` at the top of its resolution chain. If a non-empty path is stored, it creates the directory if needed and returns it. Only on `null`/empty or error does it fall through to the original hardcoded `/storage/emulated/0/Movies/Uniquifier` → external storage fallback → app-documents fallback chain.

2. **`SettingsScreen`** gains a new **Export Folder Location** section (above the existing Storage & Cache Maintenance section) containing an `_ExportFolderCard` widget with:
   - **Current path display** row showing the active folder (or the default path label).
   - **Choose Export Folder** tap row — calls `FilePicker.platform.getDirectoryPath()`, persists via `SettingsService.setCustomOutputPath(path)`, updates state, shows `AppToast` confirmation.
   - **Reset to Default Folder** tap row — conditionally visible only when a custom path is set; calls `SettingsService.setCustomOutputPath('')`, clears state, shows `AppToast` confirmation.

---

## Files Modified

| File | Change |
|------|--------|
| `lib/core/services/ffmpeg/ffmpeg_file_helper.dart` | Added `import '../settings_service.dart'`; rewrote `resolveTargetDir()` docstring; prepended custom-path guard block before the existing Android/fallback logic. |
| `lib/features/settings/screens/settings_screen.dart` | Added `import 'package:file_picker/file_picker.dart'`; added `_customOutputPath` state field; extended `_loadSettings()` to read `getCustomOutputPath()`; added `_pickExportFolder()` and `_resetExportFolder()` methods; inserted EXPORT FOLDER LOCATION section into `_buildMaintenanceSection()`; added `_ExportFolderCard` private widget class. |

---

## Implementation Notes

- **Import path**: `SettingsService` is imported via relative path `'../settings_service.dart'` from `lib/core/services/ffmpeg/`, resolving to `lib/core/services/settings_service.dart`. ✅
- **`file_picker`** was already declared in `pubspec.yaml` (Report 149). No new dependency required.
- **Permission**: The app already holds `MANAGE_EXTERNAL_STORAGE` (via `HistoryService`), so `FilePicker.platform.getDirectoryPath()` returns absolute writable paths directly usable by FFmpeg.
- **Mounted guards**: All async UI callbacks check `mounted` before calling `setState` or `AppToast.show`.
- **Reset path**: `setCustomOutputPath('')` stores an empty string; `resolveTargetDir()` treats `null` and empty string equally (falls through to default).

---

## Verification

```
grep -n "getCustomOutputPath" lib/core/services/ffmpeg/ffmpeg_file_helper.dart
# → line 52: final customPath = await SettingsService.getCustomOutputPath();

dart analyze --fatal-infos
# → 4 pre-existing infos in modifiers_card.dart (unchanged from baseline). 0 new issues introduced.

flutter test
# → 229/229 passed.
```

---

## Context Mapping Sync
Synchronized: INDEX.md, index.json (next_n=157), STATE.md, HANDOFF.md, SEED.md, findings.json, handoff-diff.json.
