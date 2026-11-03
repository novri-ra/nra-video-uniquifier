# HANDOFF — nra_video_uniquifier

> ## AI INSTRUCTIONS — read before anything else
>
> You are reading a self-contained project briefing. The user pasted this
> into a fresh chat session because they want your strategic help.
>
> **What you have:**
> - Complete project snapshot: stack, health, findings, code snippets
> - No file access — everything you need is embedded below
> - No prior conversation context — this is a fresh session
>
> **What to do first:**
> 1. Read this entire document top to bottom
> 2. Reply with a short "Understanding" paragraph proving you read it
> 3. Reply with a "Mental model" bullet list (5-7 bullets)
> 4. Ask ONE focused question before proposing anything
> 5. Only after the user confirms direction, output an OpenCode prompt
>
> **Output format for OpenCode prompt** (when ready):
> ```
> SKILL LOADING (MANDATORY):
>   skill(name="karpathy-guidelines")
> 
> MANDATORY PREFLIGHT:
>   - tools["codebase-memory-mcp"].index_status()
> 
> === OPENCODE PROMPT — <title> ===
> ## Task
> ## Context
> ## Files to modify (whitelist)
> ## Files NOT to modify
> ## Steps
> ## Verification (mandatory)
> ## Rollback
> ## Report back
> === END PROMPT ===
> ```
>
> Canonical prompt specification: `0ai_context/OPENCODE-PROMPT-SPEC.md`. Follow its 8-section structure, validation rules, and anti-pattern constraints when producing the block above. Setiap prompt yang mengubah file yang di-track Git WAJIB menyertakan verifikasi `git diff -w --exit-code` untuk membuktikan tidak ada logika yang berubah.
>
> ### 3.9 Execution Log (mandatory)
> Setiap Executor yang berhasil menjalankan prompt ini WAJIB menulis file log di `0ai_context/reports/<next_n>-fix-<title>.md` sebelum menyatakan selesai. Log ini harus berisi Status, What Was Done, dan Result agar Mapper bisa mendeteksinya pada run berikutnya.
>
> **Ground rules:**
> - **Context Recovery**: Jika sesi baru karena limit, baca `0ai_context/CHAT-CONTINUITY.md` DULU.
> - **Mechanical Tasks**: For zero-logic tasks (e.g., dart format, import sorting), DO NOT batch 3 files at a time. Whitelist the entire directory (lib/ or test/) and instruct the executor to prove safety using `git diff -w --exit-code` (exits 0 if only whitespace changed).
> - **Execution Logging**: The executor MUST write a summary of the fix to `0ai_context/reports/<next_n>-fix-<title>.md` so the Mapper knows the issue is resolved.
> - Every factual claim must cite a section number from this document
> - Never invent a file path — use only paths shown in section 10 or 11
> - Never assume behavior — read the snippet in section 11
> - Never propose a fix touching more than 3 files without splitting
> - Never propose "refactor everything"
> - Never propose CI/tests/docs as the FIRST action
> - Treat section 14 (Constraints) as inviolable
> - If information is missing, say "HANDOFF lacks <X>, ask user to re-run mapper"
>
> The rest of this document is the project briefing.

## 1. Project DNA

| Field | Value |
|-------|-------|
| Name | `nra_video_uniquifier` |
| Purpose | Offline video obfuscation and metadata mutation to bypass video fingerprinting algorithms |
| Stack | Flutter 3.47.8 / Dart 3.13.7 |
| Size | 320 files, ~25000 LOC |
| Commit | `c1db18f1261bacb0580d8319cdc47413c9598e12` |
| Branch | `development` |
| Generated | `2026-11-04T00:00:00Z` |
| Health | analyze=ok · test=173/173 passed · format=ok |
| Maturity | stable |

## 2. Architecture in 20 lines

```
           +-----------------------------------------------+
           |               Flutter UI Layer                |
           | (Dashboard, Process, Settings, History, News) |
           +-----------------------------------------------+
                                  |
                                  v
           +-----------------------------------------------+
           |               State Management                |
           | (UniquifierProvider, BatchQueueProvider, ...) |
           +-----------------------------------------------+
                                  |
                                  v
           +-----------------------------------------------+
           |            Business & Engine Services         |
           | (FfmpegService, AiSuperResolutionService, ...) |
           +-----------------------------------------------+
                                  |
                                  v
           +-----------------------------------------------+
           |             Native Subsystems / OS            |
           | (FFmpegKit Native, Local Storage, HW Accel)   |
           +-----------------------------------------------+
```

## 3. Stack & Commands

| Purpose | Command | Current Result |
|---------|---------|----------------|
| Analyze | `dart analyze` | exit 0, 0 issues found |
| Test | `flutter test` | 173/173 passing |
| Format | `dart format --set-exit-if-changed .` | 0 files changed |
| Run | `flutter run` | Native execution on connected target |

Version pins: none detected

## 4. Dependency Graph

Top fan-in (fragile symbols):

| Symbol | Fan-in | Path |
|--------|--------|------|
| `AppColors` | 169 | `lib/core/theme/app_colors.dart` |
| `SettingsService` | 50 | `lib/core/services/settings_service.dart` |
| `AppLocalizations` | 27 | `lib/l10n/app_localizations.dart` |
| `TargetResolution` | 19 | `lib/core/services/settings_service.dart` |
| `_getBool` | 18 | `lib/core/services/settings_service.dart` |
| `_setBool` | 18 | `lib/core/services/settings_service.dart` |
| `UpscaleEngine` | 17 | `lib/core/services/settings_service.dart` |
| `VideoCodec` | 13 | `lib/core/services/settings_service.dart` |
| `FfmpegService` | 12 | `lib/core/services/ffmpeg_service.dart` |
| `NotificationService` | 12 | `lib/core/services/notification_service.dart` |

Top co-change pairs (coupling debt):

| File A | File B | Score |
|--------|--------|-------|
| `lib/core/services/ffmpeg_service.dart` | `lib/core/providers/uniquifier_provider.dart` | 0.85 |
| `lib/features/process/screens/processing_screen.dart` | `lib/core/providers/uniquifier_provider.dart` | 0.78 |
| `lib/core/services/notification_service.dart` | `test/notification_service_test.dart` | 0.72 |

Reverse dependencies: 0 core->features

## 5. Critical Paths

### Path: Video Uniquification Flow
```
lib/main.dart (Entry)
  ├─> lib/features/process/screens/processing_screen.dart (UI trigger)
  │     └─> lib/core/providers/uniquifier_provider.dart (processVideo)
  └─> lib/core/services/ffmpeg_service.dart (execute FFmpeg command pipeline)
```

### Path: Batch Queue Execution
```
lib/features/process/screens/batch_processing_screen.dart
  ├─> lib/core/providers/batch_queue_provider.dart (startBatch)
  │     └─> lib/core/providers/uniquifier_provider.dart (iterate queue items)
  └─> lib/core/services/notification_service.dart (update system tray progress)
```

### Path: Settings & Engine Persistence
```
lib/features/settings/screens/settings_screen.dart
  ├─> lib/core/services/settings_service.dart (save preferences)
  │     └─> SharedPreferences (disk storage)
  └─> lib/core/providers/uniquifier_provider.dart (reactive update)
```

## 6. Data Models

| Model | Key Fields | Storage |
|-------|-----------|---------|
| `BatchVideoItem` | id, path, status, progress, targetResolution | In-memory Provider |
| `VideoExportItem` | id, originalPath, outputPath, timestamp, size | SharedPreferences |
| `MicrostockNewsArticle` | id, title, content, publishedAt, category | SharedPreferences / Cache |
| `DeviceSpecs` | totalRamMb, cpuCores, tier, hasVulkan | Hardware runtime query |
| `RenderDiagnosticInfo` | inputResolution, outputResolution, durationMs | Ephemeral memory |

## 7. External Integrations

| Integration | Direction | Payload | Optional? | Privacy |
|-------------|-----------|---------|-----------|---------|
| FFmpegKit | Outbound/Inbound | Media file streams & filter graphs | No | Strict local processing |
| Flutter Local Notifications | Outbound | Progress percentages & completion status | Yes | Local only, no telemetry |
| Microstock RSS2JSON | Inbound | Public industry trend articles | Yes | Anonymous GET request |

## 8. Health Detail

### Analyze — exit 0
0 issues found

### Test — 173/173
all passing

### Format — exit 0
0 files unformatted

## 9. Git Activity (last 14 days)

Recent commits:
```
c1db18f 2026-11-04 chore(ai): remove 0ai_context completely for fresh bootstrap
eae9ca1 2026-11-04 docs(changelog): record initial baseline and project context initialization
4945417 2026-11-04 docs(context): regenerate context packet and audit report
e231459 2026-11-04 docs(changelog): record initial baseline and project context initialization
cfae1ca 2026-11-04 docs(context): regenerate context packet and audit report
7d997f7 2026-11-04 docs(context): regenerate context packet and audit report
341f2a3 2026-11-04 docs(context): regenerate context packet and audit report
78c3b73 2026-11-04 docs(context): regenerate context packet and audit report
4a53da2 2026-11-04 docs(context): regenerate context packet and audit report
a4a974b 2026-11-04 docs(context): regenerate context packet and audit report
```

Most-changed files:
```
4 OpenCode-Bootstrap-Prompt.txt
3 0ai_context/OPENCODE-PROMPT-SPEC.md
2 test/notification_service_test.dart
2 lib/features/process/screens/processing_screen.dart
2 lib/core/services/notification_service.dart
2 lib/core/services/microstock_news_service.dart
2 lib/core/services/ffmpeg_service.dart
2 lib/core/services/device_capability_service.dart
2 lib/core/providers/uniquifier_provider.dart
2 CHANGELOG.md
```

## 10. Findings Inventory

| ID | Sev | Cat | Location | Impact | Fix | Since |
|----|-----|-----|----------|--------|-----|-------|
| `AUDIT-20261104-001` | P1 | correctness | `lib/core/services/ffmpeg_service.dart:227` | Empty catch block suppresses underlying execution or filesystem errors without telemetry or logging | Add error logging or structured failure propagation to error handler | new |
| `AUDIT-20261104-002` | P1 | correctness | `lib/core/providers/uniquifier_provider.dart:97` | Empty catch block silently ignores provider initialization failures | Log caught exception or set an error state on provider | new |
| `AUDIT-20261104-003` | P2 | quality | `lib/core/services/ffmpeg_service.dart:1` | Large service file exceeding 600 lines creates maintainability and cognitive overhead | Refactor FFmpeg command builders and execution runners into modular helper classes | new |
| `AUDIT-20261104-004` | P2 | quality | `lib/core/providers/uniquifier_provider.dart:1` | God-object provider exceeding 600 lines manages excessive state responsibilities | Split processing workflow state from general configuration state | new |
| `AUDIT-20261104-005` | P2 | quality | `lib/features/process/screens/success_screen.dart:1` | UI screen exceeding 500 lines mixes layout composition with action handlers | Decompose into smaller reusable presentation widgets | new |
| `AUDIT-20261104-006` | P3 | quality | `lib/core/providers/locale_provider.dart:22` | Swallowed exception when reading stored locale fallback defaults | Add debugPrint or fallback telemetry for invalid locale decoding | new |

## 11. Code Snippets

### Snippet 1 — `lib/main.dart:1` — Application entry point initializing core bindings and services
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniquifierApp());
}
```

### Snippet 2 — `lib/core/services/ffmpeg_service.dart:40` — High fan-in media transformation engine
```dart
class FfmpegService {
  Future<void> processVideo(...) async {
    // Core video mutation
  }
}
```

### Snippet 3 — `lib/core/providers/uniquifier_provider.dart:30` — Central state orchestrator for all processing toggles
```dart
class UniquifierProvider extends ChangeNotifier {
  bool _removeMetadata = true;
  bool _modifyAudio = true;
}
```

### Snippet 4 — `lib/core/services/settings_service.dart:20` — Central settings persistence service with high fan-in
```dart
class SettingsService {
  static const String keyTargetResolution = 'target_resolution';
}
```

### Snippet 5 — `lib/core/theme/app_colors.dart:5` — Highest fan-in symbol defining design token palette
```dart
class AppColors {
  static const Color forestDeep = Color(0xFF0F1E19);
  static const Color vividCoral = Color(0xFFFF5252);
}
```

### Snippet 6 — `lib/core/services/notification_service.dart:15` — Handles system-level notifications for background video processing
```dart
class NotificationService {
  Future<void> showProgressNotification(...) async {}
}
```

### Snippet 7 — `lib/core/services/device_capability_service.dart:10` — Hardware profiling for performance tiering
```dart
class DeviceCapabilityService {
  static DeviceTier classifyTier(...) { return DeviceTier.mid; }
}
```

### Snippet 8 — `lib/core/services/history_service.dart:15` — Local storage history tracker for processed videos
```dart
class HistoryService {
  Future<List<VideoExportItem>> scanDirectory(...) async {}
}
```

### Snippet 9 — `lib/core/services/ai_super_resolution_service.dart:12` — AI upscaling service with transparent Vulkan to Lanczos3 fallback
```dart
class AiSuperResolutionService {
  Future<bool> isVulkanSupported() async {}
}
```

### Snippet 10 — `lib/core/providers/batch_queue_provider.dart:15` — Batch queue management provider for bulk processing
```dart
class BatchQueueProvider extends ChangeNotifier {
  final List<BatchVideoItem> _queue = [];
}
```

### Snippet 11 — `lib/features/process/screens/processing_screen.dart:20` — Primary processing view displaying live radar and pipeline tracker
```dart
class ProcessingScreen extends StatefulWidget {
  @override
  _ProcessingScreenState createState() => _ProcessingScreenState();
}
```

### Snippet 12 — `lib/features/process/widgets/modifiers_card.dart:18` — Key UI widget rendering processing modification switches
```dart
class ModifiersCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) { return Card(); }
}
```

## 12. Open Questions

1. Which priority should be addressed first: fixing P1 empty error catches or refactoring P2 god-classes?
2. Should empty catch blocks in `FfmpegService` log to standard debugPrint or write to an on-device error buffer?
3. Does `UniquifierProvider` require splitting into distinct processing vs configuration providers in this iteration?
4. Are there plans to expand `BatchVideoItem` status states beyond pending, processing, completed, and cancelled?
5. Should `DeviceCapabilityService` fallback threshold for Vulkan support be configurable via developer options?
6. Is Lanczos3 upscaling considered acceptable for entry-tier hardware when Real-ESRGAN is unavailable?
7. Should historical processed videos be purged automatically after a configurable retention period?
8. Does the floating bottom navbar require additional tab slots for future feature extensions?
9. Can `AppColors` tokens be aligned further with DTCG standard design tokens in future sprints?
10. Are additional unit tests required for the empty catch edge cases highlighted in finding `AUDIT-20261104-001`?

## 13. Decision Log
N/A — No ADR directory present in repository. Architectural rules defined in SEED.md and STATE.md.

## 14. Constraints (inviolable)

- Zero network dependency for core video transformations and rendering.
- Offline-first operation: Network failure must never disrupt local processing workflows.
- No external telemetry: Video metadata and user paths remain strictly confidential on device.
- Input video files must never be modified in-place or mutated destructively.

## 15. Glossary

| Term | Definition |
|------|-----------|
| vDNA | Video digital fingerprint hash generated by social media platforms to detect duplicate uploads |
| Evasion | Algorithmic micro-modifications (crop, audio shift, hue curve) to alter hash signatures |
| Lanczos3 | Mathematical interpolation algorithm used as fallback when GPU AI acceleration is absent |
| Real-ESRGAN | Deep learning neural network model for super-resolution video upscaling |
| Fan-in | Number of incoming call or usage dependencies directed at a symbol |
| Scoped Storage | Sandboxed filesystem constraints imposed by modern mobile operating systems |

## 16. Run Manifest

| Field | Value |
|-------|-------|
| Generated | `2026-11-04T00:00:00Z` |
| Mapper version | 6.0 |
| Graph project | `C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier` |
| Graph revision | `c1db18f1261bacb0580d8319cdc47413c9598e12` |
| Nodes / edges | 1660 / 4607 |
| Bundle lines | 720 |
| Bundle tokens (est) | 18000 |
| Scope locked | `0ai_context/` only |
| Source edits | none |
| MCP status | ready |
| Languages | dart, flutter, c++, c, swift |
| Tier | small |
