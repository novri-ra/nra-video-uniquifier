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
> Setiap Executor yang berhasil menjalankan prompt ini WAJIB menulis file log di `0ai_context/reports/<next_n>-fix-<title>.md` sebelum menyatakan selesai. Log ini harus berisi Status, What Was Done, dan Result agar Mapper bisa mendeteksinya pada run berikutnya. For this run `<next_n>` is `88`.
>
> **Ground rules:**
> - **Context Recovery**: Jika sesi baru karena limit, baca `0ai_context/CHAT-CONTINUITY.md` DULU.
> - **Mechanical Tasks**: For zero-logic tasks (e.g., `dart format`, import sorting), DO NOT batch 3 files at a time. Whitelist the entire directory (`lib/` or `test/`) and instruct the executor to prove safety using `git diff -w --exit-code` (exits 0 if only whitespace changed).
> - **Execution Logging**: The executor MUST write a summary of the fix to `0ai_context/reports/88-fix-<title>.md` so the Mapper knows the issue is resolved.
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
| Purpose | On-device video re-encoder that rewrites visual, audio, and metadata characteristics so a clip stops matching platform fingerprint hashes |
| Stack | Flutter 3.47.8 / Dart 3.13.7, FFmpegKit, optional ncnn Vulkan super-resolution |
| Size | 422 tracked files, 124 Dart files under `lib/` (23,677 LOC), 25 test files |
| Commit | `6278087bcdd5364538ff2b54de5be7c71e3c82ba` |
| Branch | `development` |
| Generated | `2026-11-08T01:30:00Z` |
| Health | analyze=ok (exit 0) · test=216/216 · format=fail (7 files) |
| Maturity | active — v1.0.5 shipped, no declared next milestone |

## 2. Architecture in 20 lines

```
main.dart → MultiProvider (8 services/providers) → RootNavigationScreen (4-slot navbar)
  services: Settings (shared_preferences) · Storage (space gate, staging, atomic move)
            Connectivity (event-driven offline flag) · Notification (2 channels)
  providers: UniquifierProvider (facade over media/modifiers/progress mixins)
             BatchQueueProvider · ThemeProvider · LocaleProvider
  screens:  Studio → Process → Processing → Success | Batch | History | Settings
                                   │
                                   ▼
                  FfmpegService.processVideo(35 params)
   ├─ StorageService.hasEnoughSpace()        hard gate, aborts early
   ├─ stageInputFile()                       copy to cache, atomic
   ├─ FfmpegCommandBuilder.buildCommand() → FilterBuilders.buildVideoFilter()
   │     ├─ canonicalDimensions (1080p/2K/4K, portrait aware)
   │     ├─ VariationGenerator (device profiles, GOP jitter)
   │     └─ FfmpegMetadataBuilder (EXIF/SEI scrubbing)
   ├─ FFmpegKit.executeAsync → onProgress → UI ticker (<15% until native done)
   └─ inspectRenderedFile() → _executeAndExport() → Movies/Uniquifier
```

## 3. Stack & Commands

| Purpose | Command | Current Result |
|---------|---------|----------------|
| Analyze | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Test | `flutter test` | 216/216 passing (exit 0) |
| Format | `dart format --set-exit-if-changed .` | exit 1, 7 files changed |
| Run | `flutter run` | not exercised in this pass |

Version pins: Dart SDK `>=3.10.0 <4.0.0` (running 3.13.7), app version `1.0.5+5`. No `.tool-versions`, `.nvmrc`, or `rust-toolchain` file exists.

Formatting caveat: `dart format --set-exit-if-changed` **writes** before reporting. Use `--output=none` when you only want the gate result.

## 4. Dependency Graph

Top fan-in (fragile symbols):

| Symbol | Fan-in | Path |
|--------|--------|------|
| `AppColors` | 181 | `lib/core/theme/app_colors.dart` |
| `AppLocalizations.of` | 102 | `lib/l10n/app_localizations.dart` |
| `UniquifierProvider` | 37 | `lib/core/providers/uniquifier_provider.dart` |
| `AppLocalizations` | 29 | `lib/l10n/app_localizations.dart` |
| `TargetResolution` | 26 | `lib/core/services/settings_service.dart` |
| `SettingsService` | 26 | `lib/core/services/settings_service.dart` |
| `UpscaleEngine` | 24 | `lib/core/services/settings_service.dart` |
| `UnifiedVisualEffect` | 22 | `lib/core/models/unified_effect_preset.dart` |
| `UnifiedVisualEffect.none` | 20 | `lib/core/models/unified_effect_preset.dart` |
| `VideoCodec` | 19 | `lib/core/services/settings_service.dart` |

Top co-change pairs (coupling debt):

| File A | File B | Score |
|--------|--------|-------|
| `lib/core/services/ffmpeg_service.dart` | `lib/core/services/filter_builders.dart` | 0.89 (8 co-changes) |
| `lib/core/providers/uniquifier_provider.dart` | `lib/core/services/ffmpeg_service.dart` | 0.86 |
| `lib/core/services/filter_builders.dart` | `test/ffmpeg_service_test.dart` | 0.80 |
| `lib/core/services/ffmpeg_service.dart` | `lib/features/process/screens/processing_screen.dart` | 1.00 |
| `lib/core/services/history_service.dart` | `lib/features/history/screens/recent_history_screen.dart` | 1.00 |
| `lib/core/services/notification_service.dart` | `test/notification_service_test.dart` | 1.00 |
| `lib/core/providers/uniquifier_provider.dart` | `test/unified_effect_preview_test.dart` | 1.00 |
| `lib/core/services/ffmpeg_service.dart` | `lib/core/utils/variation_generator.dart` | 1.00 |
| `lib/core/services/microstock_news_service.dart` | `lib/features/microstock/widgets/microstock_news_card.dart` | 1.00 |
| `lib/features/process/screens/success_screen.dart` | `lib/features/process/widgets/success/success_manifest_card.dart` | 1.00 |

Reverse dependencies: the graph is a clean `core → features` direction — no `features → core` cycles at import level. The only cycle is a call-graph recursion inside `filter_builders.dart` (`buildVideoFilter` ↔ `_fallbackVideoFilter`).

## 5. Critical Paths

### Path: app bootstrap (`lib/main.dart` → providers)
```
main()
  ├─> FFmpegKitConfig.setSessionHistorySize(3)      [guarded by try/catch + debugPrint]
  ├─> StorageService.pruneStaleFiles()
  ├─> SettingsService.purgeTempCache()
  ├─> NotificationService / ConnectivityService / StorageService / SettingsService
  └─> MultiProvider → MaterialApp → RootNavigationScreen
```

### Path: single video export (`UniquifierProvider` → `FfmpegService`)
```
processVideo(35 params)
  ├─> StorageService.hasEnoughSpace()        [hard gate, aborts early]
  ├─> stageInputFile()                       [copy to app cache, atomic]
  ├─> FfmpegCommandBuilder.buildCommand()
  │     ├─> FilterBuilders.buildVideoFilter()  [visual chain]
  │     ├─> FfmpegMetadataBuilder              [device masquerade]
  │     └─> VariationGenerator                 [GOP jitter, profiles]
  ├─> FFmpegKit.executeAsync → onProgress → UI ticker (capped <15% until native completion)
  ├─> inspectRenderedFile()                   [integrity verification]
  └─> _executeAndExport() → move to /storage/emulated/0/Movies/Uniquifier
```

### Path: live preview (`requestFilteredPreviewDebounced`)
```
slider change
  └─> requestFilteredPreviewDebounced(debounce 300ms)
        ├─> cancel previous timer
        ├─> selectedFilePath null? → clear preview state, return
        └─> _executePreviewRender(1-frame extract)
              └─> FfmpegService.renderFilteredPreviewFrame → cache purge (_cleanupOldPreviews)
```

## 6. Data Models

| Model | Key Fields | Storage |
|-------|-----------|---------|
| `VideoExportItem` | id, originalPath, outputPath, timestamp, size | `shared_preferences` ledger + filesystem |
| `BatchVideoItem` | id, path, status, progress, targetResolution | in-memory only |
| `MicrostockNewsArticle` | id, title, content, publishedAt, category | `shared_preferences` cache (1h TTL) |
| `UnifiedVisualEffect` | id, displayName, description | static enum (9 effects) |
| `DeviceProfile` | make, model, encoder, videoHandler, audioHandler | static const list |
| `DeviceSpecs` / `DeviceTier` | RAM, cores, ABI, Vulkan support, tier | computed at runtime |

## 7. External Integrations

| Integration | Direction | Payload | Optional? | Privacy |
|-------------|-----------|---------|-----------|---------|
| FFmpegKit | outbound subprocess | video frames, filter graph | no | on-device only |
| `/storage/emulated/0/Movies/Uniquifier` | bidirectional | exported mp4 | no | user-visible folder |
| `shared_preferences` | bidirectional | settings, history, affinity | no | app-private |
| `flutter_local_notifications` | outbound | progress/completion alerts | yes (permission) | local only |
| `connectivity_plus` | inbound | online/offline events | yes | no payload |
| Microstock RSS (`petapixel.com`, `fstoppers.com`) | inbound HTTP GET | public article HTML | yes | the only outbound network path |
| ncnn Vulkan library | in-process | frames for super-resolution | yes (device tier) | on-device only |

## 8. Health Detail

### Analyze — exit 0
`Analyzing nra_video_uniquifier... No issues found!` with `--fatal-infos`, so no info-level lints either.

### Test — 216/216
All passing. 25 test files. Newest suites cover multi-resolution smoke tests (320x480 with textScaleFactor 2.0), touch-target sizing, error-screen path redaction, and 4-slot navbar routing.

### Format — exit 1
7 files unformatted:
```
lib/core/services/ffmpeg_service.dart
lib/core/services/filter_builders.dart
lib/core/services/notification_service.dart
lib/core/utils/variation_generator.dart
lib/features/process/widgets/modifiers_card.dart
test/ffmpeg_service_test.dart
test/notification_service_test.dart
```
The probe rewrites files as a side effect. Six of them were clean at run start and were restored; `modifiers_card.dart` already had uncommitted user edits and kept the formatter's rewrapping.

## 9. Git Activity (last 14 days)

Recent commits:
```
6278087 2026-11-08 chore(release): bump version to v1.0.5
e020826 2026-11-07 fix(notifications): sync test expectations and showTestNotification with new separated channels
ad5509e 2026-11-07 docs: update changelog and readme with latest performance and evasion fixes
f691b04 2026-11-07 perf: optimize battery, enhance TikTok evasion filters, fix FFmpeg preview crash, and update tests
e3bc546 2026-11-06 docs(README): update feature descriptions and enhance clarity on visual effects and testing
7fdb3bb 2026-11-06 test(ffmpeg): add unit tests for activeVisualEffects and rotateAngle wiring
d1c29da 2026-11-06 fix(android): add mediaProcessing foreground service type for Android 14+ compliance
53a786f 2026-11-06 fix(ffmpeg): auto-purge old preview cache files to prevent storage bloat
015c987 2026-11-06 fix(batch): forward rotateAngle and activeVisualEffects to processVideo pipeline
e5ec30f 2026-11-06 fix(ffmpeg): wire multi-select activeVisualEffects from UI to export pipeline
db764d3 2026-11-06 feat(reports): add deep system audit and health check report (v1.0.4+)
d692bf9 2026-11-06 chore(cleanup): purge root staged media, categorize report archives, and update index
9f88ab0 2026-11-06 fix(ui): implement top floating capsule toast and resolve native notification delivery
331f9b2 2026-11-06 docs(reports): add report 37 (release v1.0.4 universal compatibility and effect catalog)
c5ddb4e 2026-11-06 chore(release): bump version to 1.0.4+5 with universal android compatibility and visual effect catalog
41d5e25 2026-11-06 feat(preview): implement high-fidelity debounced preview rendering and unified effect suite
d4c3dd5 2026-11-05 chore(release): bump version to 1.0.3+4
175e985 2026-11-05 feat(process): wire interactive preview sliders and fix success screen thumbnail fallback
7a525a7 2026-11-05 fix(i18n): standardize entire UI and localization strings to English default
04eb3ce 2026-11-05 docs(reports): add report 34 for v1.0.2 android 14 storage fix release
9c4dc6d 2026-11-05 chore(release): bump version to 1.0.2+3
56540c5 2026-11-05 feat(storage): wire device_info_plus and lifecycle permission observer for Android 14
b9f85de 2026-11-05 docs(reports): add report 33 for v1.0.1 production release
76fcee4 2026-11-05 chore(release): bump version to 1.0.1+2
0fd98a7 2026-11-05 feat: complete phase 4 and 5 wcag contrast, english i18n, and real data bindings
d870a79 2026-11-05 feat(storage): implement MANAGE_EXTERNAL_STORAGE permission for Android 11+ to enhance file management capabilities
1bf8031 2026-11-05 feat(evasion): implement dynamic GOP jittering, color matrix shifting, SEI leak sanitization, and 4-tier storage intent
dfe8360 2026-11-05 fix(engine): resolve critical P1 audio amix drop, sub-perceptual pitch, dynamic sharpening, real storage check, and fake file elimination
377ca59 2026-11-05 docs(reports): add report 29 super power deep audit and system evaluation
53ccaea 2026-11-05 docs(reports): add report 28 for production release v1.0.0
```

Most-changed files:
```
34 0ai_context/reports/INDEX.md
26 CHANGELOG.md
14 lib/core/services/ffmpeg_service.dart
10 lib/core/services/filter_builders.dart
10 pubspec.yaml
 9 lib/features/microstock/widgets/microstock_article_sheet.dart
 9 lib/features/history/screens/recent_history_screen.dart
 9 lib/core/providers/uniquifier_provider.dart
 8 lib/core/services/history_service.dart
 8 lib/core/services/microstock_news_service.dart
```

## 10. Findings Inventory

| ID | Sev | Cat | Location | Impact | Fix | Since |
|----|-----|-----|----------|--------|-----|-------|
| AUDIT-20261108-001 | P1 | correctness | `lib/core/providers/uniquifier/uniquifier_modifiers_mixin.dart:142` | 27 empty catches swallow settings persistence and preview failures. | Log the key and exception, or propagate a typed failure. | new |
| AUDIT-20261108-002 | P1 | correctness | `lib/core/services/ffmpeg_service.dart:147` | Empty catches in staging/cleanup hide filesystem failures. | Log with path context, surface via RenderIntegrityException. | AUDIT-20261104-001 |
| AUDIT-20261108-003 | P1 | correctness | `lib/core/services/microstock_news_service.dart:241` | 9 empty catches hide RSS fetch/parse failures. | Record feed URL and error, expose degraded state. | new |
| AUDIT-20261108-004 | P1 | correctness | `lib/core/services/notification_service.dart:65` | 6 empty catches hide permission and delivery failures. | Log and fall back to in-app toast. | new |
| AUDIT-20261108-005 | P1 | correctness | `lib/core/services/history_service.dart:62` | 5 empty catches can silently lose the export ledger. | Log and mark store degraded. | new |
| AUDIT-20261108-006 | P1 | correctness | `lib/core/services/user_interest_service.dart:262` | Affinity migration decode error swallowed, weights lost. | Catch FormatException, log, reset deterministically. | new |
| AUDIT-20261108-007 | P2 | quality | `lib/core/services/filter_builders.dart:323` | 691-line builder plus a call cycle. | Extract per-effect segments, remove recursion. | new |
| AUDIT-20261108-008 | P2 | quality | `lib/features/microstock/widgets/microstock_article_sheet.dart:1` | 901-line widget mixes render, bookmark, share. | Split into header/body/action widgets. | new |
| AUDIT-20261108-009 | P2 | quality | `lib/core/services/microstock_news_service.dart:1` | 791-line service mixes transport, parsing, cache. | Extract transport and parser. | new |
| AUDIT-20261108-010 | P2 | quality | `lib/core/services/ffmpeg_service.dart:1` | 610 lines of orchestration, staging, probing, verification. | Move probe/export/verify into ffmpeg helpers. | AUDIT-20261104-003 |
| AUDIT-20261108-011 | P2 | quality | `lib/core/services/ffmpeg_service.dart:274` | 35-parameter processVideo, 0.89 co-change with filter builder. | Introduce ProcessVideoOptions value object. | new |
| AUDIT-20261108-012 | P2 | quality | `lib/features/microstock/screens/microstock_ai_screen.dart:6` | Zero graph edges: unreachable screen. | Confirm, then delete screen and route. | new |
| AUDIT-20261108-013 | P2 | quality | `test/ffmpeg_service_test.dart:1` | 1147-line test file obscures failures. | Split by concern. | new |
| AUDIT-20261108-014 | P2 | documentation | `README.md:7` | Zero-network claim contradicts RSS fetches. | Scope the claim, document the feed path. | new |
| AUDIT-20261108-015 | P2 | safety | `lib/core/services/ffmpeg/ffmpeg_file_helper.dart:24` | Android storage path duplicated in 4 files. | Centralize in one constants file. | new |
| AUDIT-20261108-016 | P3 | quality | `lib/core/providers/locale_provider.dart:34` | Empty catch hides corrupt locale values. | debugPrint the value. | AUDIT-20261104-006 |
| AUDIT-20261108-017 | P3 | quality | `lib/core/services/settings_service.dart:396` | 3 empty catches hide settings write failures. | Log, keep in-memory value authoritative. | new |
| AUDIT-20261108-018 | P3 | quality | `lib/core/services/storage_service.dart:49` | 3 empty catches hide free-space probe failures. | Log, use conservative estimate. | new |
| AUDIT-20261108-019 | P3 | documentation | `lib/core/services/notification_service.dart:24` | Indonesian comments after English-only i18n policy. | Translate comments. | new |
| AUDIT-20261108-020 | P3 | quality | `lib/features/process/widgets/modifiers_card.dart:1` | Format gate fails on 7 files. | Whitespace-only `dart format` commit. | new |

Resolved since the previous mapping run (2026-11-04): `AUDIT-20261104-004` (UniquifierProvider god-object — now 3 mixins) and `AUDIT-20261104-005` (SuccessScreen >500 lines — now 211 lines).

## 11. Code Snippets

### Snippet 1 — `lib/main.dart:17` — application entry point; registers 8 services and prunes stale state

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    FFmpegKitConfig.setSessionHistorySize(3);
  } catch (e) {
    debugPrint('[Main] FFmpeg init failed: $e');
  }

  try {
    await StorageService.pruneStaleFiles();
    await SettingsService.purgeTempCache();
  } catch (e) {
```

### Snippet 2 — `lib/core/providers/uniquifier_provider.dart:244` — highest fan-in UI orchestrator; debounced preview entry

```dart
  void requestFilteredPreviewDebounced({
    Duration debounceDuration = const Duration(milliseconds: 300),
    bool immediate = false,
    double timestampSeconds = 0.5,
    String? customFilter,
  }) {
    _previewDebounceTimer?.cancel();

    final input = selectedFilePath;
    if (input == null || input.isEmpty) {
      _renderedPreviewFramePath = null;
      _isPreviewRendering = false;
      return;
    }

    if (immediate) {
      _executePreviewRender(
        inputPath: input,
        timestampSeconds: timestampSeconds,
        customFilter: customFilter,
```

### Snippet 3 — `lib/core/services/ffmpeg_service.dart:274` — export entry point with 35+ parameters

```dart
  static Future<String> processVideo({
    required String inputPath,
    bool removeMetadata = true,
    bool modifyAudio = true,
    bool modifyVisuals = true,
    bool upscale1080p = false,
    bool? upscale,
    TargetResolution targetResolution = TargetResolution.r1080p,
    UpscaleEngine upscaleEngine = UpscaleEngine.lanczos,
    VideoCodec videoCodec = VideoCodec.h264,
    bool enableEnhanceAndDenoise = true,
    bool enableDeepAntiFingerprint = true,
    bool enableHorizontalFlip = false,
    bool enableAggressiveAudio = false,
    bool enableAutoTrim = false,
    bool? isPortrait,
    bool enableHardwareAcceleration = false,
    bool enableBlurredCanvas = false,
    double canvasScalePercent = 95.0,
    bool muteOriginalAudio = false,
```

### Snippet 4 — `lib/core/services/filter_builders.dart:104` — canonical output dimensions, the one place resolution is decided

```dart
  static (int, int) canonicalDimensions(
    TargetResolution res, {
    required bool isPortrait,
  }) {
    switch (res) {
      case TargetResolution.r1080p:
        return isPortrait ? (1080, 1920) : (1920, 1080);
      case TargetResolution.r2k:
        return isPortrait ? (1440, 2560) : (2560, 1440);
      case TargetResolution.r4k:
        return isPortrait ? (2160, 3840) : (3840, 2160);
    }
  }
```

### Snippet 5 — `lib/core/services/filter_builders.dart:323` — 691-line filter builder, one half of the only call cycle

```dart
  static String buildVideoFilter({
    required bool hasVisual,
    required bool hasAudio,
    bool modifyVisuals = true,
    bool upscale = false,
    TargetResolution targetResolution = TargetResolution.r1080p,
    UpscaleEngine upscaleEngine = UpscaleEngine.lanczos,
    VideoCodec videoCodec = VideoCodec.h264,
    bool enableEnhanceAndDenoise = true,
    bool enableDeepAntiFingerprint = true,
    bool enableHorizontalFlip = false,
    bool isPortrait = false,
    bool enableBlurredCanvas = false,
    double canvasScalePercent = 95.0,
    bool enableDynamicZoom = false,
    bool enableMicroOverlay = false,
    bool enableFrameSkip = false,
    bool enableChromaShift = false,
    VideoVariations? variations,
    int targetFps = 30,
```

### Snippet 6 — `lib/core/models/unified_effect_preset.dart:2` — the effect catalog that drives every filter decision

```dart
enum UnifiedVisualEffect {
  none(
    id: 'none',
    displayName: 'Original / None',
    description: 'No visual modification applied',
  ),
  blurredCanvas(
    id: 'blurred_canvas',
    displayName: 'Blurred Canvas / Dynamic Split',
    description: 'Blurred background canvas with scaled foreground (70%-100%)',
  ),
  motionEcho(
    id: 'motion_echo',
    displayName: 'Temporal Motion Echo',
    description: 'Multi-layer temporal clone delay echo',
  ),
  rgbSplit(
    id: 'rgb_split',
    displayName: 'RGB Temporal Split',
    description: 'Separation of R, G, B channels with temporal delay',
```

### Snippet 7 — `lib/core/providers/batch_queue_provider.dart:8` — batch state; subject of the parameter-drop fix in report 42

```dart
class BatchQueueProvider extends ChangeNotifier {
  final List<BatchVideoItem> _items = [];
  bool _isProcessing = false;
  int _currentIndex = -1;
  bool _isCancelled = false;

  List<BatchVideoItem> get items => List.unmodifiable(_items);
  bool get isProcessing => _isProcessing;
  int get currentIndex => _currentIndex;
  bool get isCancelled => _isCancelled;

  int get totalCount => _items.length;
  int get completedCount => _items.where((e) => e.isCompleted).length;
  int get failedCount => _items.where((e) => e.isFailed).length;
  bool get hasItems => _items.isNotEmpty;

  double get overallProgress {
    if (_items.isEmpty) return 0.0;
    double sum = 0.0;
    for (final item in _items) {
```

### Snippet 8 — `lib/core/services/notification_service.dart:9` — split channels; 6 empty catches and Indonesian comments

```dart
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static bool? _testOverride;
  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;
  @visibleForTesting
  static set initialized(bool value) => _initialized = value;
  static bool get _canRun => _testOverride ?? Platform.isAndroid;

  static const int progressNotificationId = 101;
  static const int completeNotificationId = 8802;
  static const int testNotificationId = 7777;

  static const String mainChannelId = 'nra_uniquifier_channel_v2';
  static const String processChannelId = 'nra_progress_silent_channel';
  static const String legacyProcessChannelId = 'nra_video_processing_channel';
  static const String completeChannelId = 'nra_complete_alert_channel';
```

### Snippet 9 — `lib/features/microstock/utils/html_sanitizer.dart:6` — the only sanitization boundary for untrusted RSS HTML

```dart
  static String clean(String input) {
    if (input.isEmpty) return '';

    // 1. If wrapped in CDATA or <content:encoded>, extract inner content first
    final contentRegex = RegExp(
      r'<content(?::encoded)?>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?<\/content(?::encoded)?>',
      dotAll: true,
      caseSensitive: false,
    );
    final match = contentRegex.firstMatch(input);
    var text = match != null ? match.group(1) ?? '' : input;

    // Strip raw CDATA markers
    text = text.replaceAll('<![CDATA[', '').replaceAll(']]>', '');

    // 2. Normalize structural break tags into newlines before DOM parsing
    text = text
        .replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<\/p>', caseSensitive: false), '\n\n')
```

### Snippet 10 — `lib/shared/widgets/top_app_bar.dart:7` — shared app bar with the offline indicator

```dart
class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool? isOffline;
  final VoidCallback? onSettingsTap;
  final bool showSettingsAction;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  const TopAppBar({
    super.key,
    this.title = 'NRA VIDEO UNIQUIFIER',
    this.isOffline,
    this.onSettingsTap,
    this.showSettingsAction = true,
    this.showBackButton = false,
    this.onBackTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);
```

### Snippet 11 — `lib/core/theme/app_colors.dart:4` — highest fan-in symbol in the project (181 inbound edges)

```dart
class AppColors {
  // Editorial Architecture Tokens (Sprint 89)
  static const Color forestDeep = Color(
    0xFF0E5535,
  );
  static const Color mintSage = Color(
    0xFFA3EFD5,
  );
  static const Color skyPastel = Color(
    0xFF7DDCF0,
  );
  static const Color butterYellow = Color(
    0xFFFFE98C,
  );
  static const Color persimmonOrange = Color(
    0xFFFF8E3E,
  );
  static const Color obsidianBase = Color(
    0xFF111817,
```

### Snippet 12 — `lib/core/utils/variation_generator.dart:3` — device masquerade profiles used by the metadata builder

```dart
class DeviceProfile {
  final String make;
  final String model;
  final String encoder;
  final String videoHandler;
  final String audioHandler;

  const DeviceProfile({
    required this.make,
    required this.model,
    required this.encoder,
    this.videoHandler = 'Core Media Video',
    this.audioHandler = 'Core Media Audio',
  });

  static const DeviceProfile defaultProfile = DeviceProfile(
    make: 'Apple',
    model: 'iPhone 15 Pro Max',
    encoder: 'Apple QuickTime',
    videoHandler: 'Core Media Video',
```

### Snippet 13 — `lib/core/services/device_capability_service.dart:5` — hardware tier gate for upscale engine selection

```dart
enum DeviceTier {
  entry('Entry Tier', 'Limited RAM / CPU'),
  mid('Mid Tier', 'Balanced Hardware'),
  flagship('Flagship / High-End', 'Full Hardware Acceleration');

  final String label;
  final String description;
  const DeviceTier(this.label, this.description);
}

class DeviceSpecs {
  final int totalRamBytes;
  final int availRamBytes;
  final int cpuCores;
  final String primaryAbi;
  final bool isArm64;
  final bool hasVulkan;
  final bool hasVulkanCompute;
  final DeviceTier tier;
```

### Snippet 14 — `lib/core/services/user_interest_service.dart:262` — offline telemetry boundary; the swallowed migration

```dart
      final rawV1 = prefs.getString(_affinityKeyV1);
      if (rawV1 != null && rawV1.isNotEmpty) {
        final decoded = jsonDecode(rawV1) as Map<String, dynamic>;
        final now = DateTime.now().millisecondsSinceEpoch;
        decoded.forEach((k, v) {
          _affinityMap[k] = _AffinityRecord(
            score: (v as num).toDouble(),
            lastUpdated: now,
          );
        });
      }
    } catch (_) {}
  }

  static Future<void> _saveAffinity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        for (final entry in _affinityMap.entries)
          entry.key: entry.value.toJson(),
```

### Snippet 15 — `lib/core/services/ffmpeg/ffmpeg_command_builder.dart:1` — in-flight extraction target, modified in the working tree

```dart
import '../../models/unified_effect_preset.dart';
import '../../utils/variation_generator.dart';
import '../filter_builders.dart';
import '../settings_service.dart';
import 'ffmpeg_metadata_builder.dart';

/// Builder responsible for constructing complete FFmpeg command strings.
class FfmpegCommandBuilder {
  /// Escapes double quotes in file paths for shell safety.
  static String escapePath(String path) => path.replaceAll('"', r'\"');

  /// Builds dynamic FFmpeg command string with full anti-fingerprint filters.
  static String buildCommand({
    required String inputPath,
    required String outputPath,
    bool removeMetadata = true,
    bool modifyAudio = true,
    bool modifyVisuals = true,
    bool upscale1080p = false,
    bool? upscale,
```

## 12. Open Questions

1. Which module owns the 85 empty catch blocks: does `FfmpegService` expose one logging hook that every service should call, or does each service log independently?
2. `processVideo` takes 35+ parameters and co-changes with `filter_builders.dart` at 0.89 — is a `ProcessVideoOptions` value object acceptable, or is the project intentionally keeping flat parameters for test readability?
3. `MicrostockAiScreen` has zero graph edges and no textual reference — is it a removed feature awaiting deletion, or a screen waiting to be wired?
4. The README claims zero network transmission while `MicrostockNewsService` fetches RSS — is the news reader a supported feature that should stay, or a candidate for removal?
5. `filter_builders.dart` is 691 lines with a call cycle — which effects are load-bearing for platform evasion and which are cosmetic experiments?
6. Format gate fails on 7 files — is a whitespace-only commit acceptable in this repo, given that `dart format` rewrites files before reporting?
7. `test/ffmpeg_service_test.dart` is 1147 lines — does the team want one test file per service, or per behaviour cluster?
8. The Android storage path literal appears in 4 files — is there a platform-channel reason not to centralize it in Dart constants?
9. `DeviceTier` gates the upscale engine — is the ncnn Vulkan path shipped to users today, or still behind a flag?
10. No ADR exists in the repository (`manage_adr` reports none) — where are architectural decisions recorded besides the numbered reports?

## 13. Decision Log

No ADR file exists in the repository. Decisions are recorded inside numbered reports:

| Decision | Source | Consequence |
|----------|--------|-------------|
| Split `UniquifierProvider` into a facade plus domain mixins | Report 19 (archived) | Provider dropped from 614 to 334 lines; `uniquifier_progress_mixin`, `uniquifier_media_mixin`, `uniquifier_modifiers_mixin` now own the state |
| Decompose `SuccessScreen` into presentation widgets | Report 18 (archived) | Screen is now 211 lines |
| Separate silent progress channel from alerting completion channel | Report 39, commit `e020826` | Users are not pinged for every progress tick |
| Declare `dataSync|mediaProcessing` foreground service type | Report 44, commit `d1c29da` | Android 14+ Play policy compliance |
| Keep telemetry offline: `_dispatchTelemetry` performs no network call | `user_interest_service.dart` docstring | Interest affinity never leaves the device |
| Auto-purge preview cache during processing | Report 43, commit `53a786f` | Bounded preview cache growth |

## 14. Constraints (inviolable)

- Video processing performs zero network I/O. The RSS news reader is the only outbound path and must stay isolated from the pipeline.
- Original input files are never mutated. Export is stage → verify → atomic move.
- No user video, absolute path, or device identifier is transmitted anywhere.
- Supported Android range: 7.0 (API 24) through 16 (API 36); foreground service must keep `dataSync|mediaProcessing`.
- All UI copy and localization default to English.
- Public export destination is `/storage/emulated/0/Movies/Uniquifier`.
- Mapper scope: writes are allowed only under `0ai_context/**`; source edits require an explicit executor prompt with a whitelist.

## 15. Glossary

| Term | Definition |
|------|-----------|
| Uniquifier | The product's name for the pipeline that rewrites a clip's characteristics so platform fingerprinting cannot match it |
| Fingerprint hash | Perceptual/visual hash (e.g. pHash) a platform computes to detect duplicate uploads |
| SEI | H.264/H.265 Supplementary Enhancement Information NAL units; may leak encoder identity, so they are stripped |
| GOP jitter | Randomized keyframe interval so encoded frame structure stops matching a known pattern |
| `amix` | FFmpeg audio filter used to mix the original track with masking noise |
| `zoompan` | FFmpeg filter producing continuous zoom; used for the "dynamic zoom" modifier |
| Blurred canvas | Composition where a blurred, target-scaled copy fills the frame behind a scaled foreground |
| Canvas scale percent | Foreground size relative to the blurred background (70–100%) |
| Device masquerade | Rewriting container metadata to claim a different camera/encoder (e.g. iPhone 15 Pro Max) |
| Scoped storage | Android 10+ storage model; the app uses a multi-tier intent dispatcher plus `MANAGE_EXTERNAL_STORAGE` |

## 16. Run Manifest

| Field | Value |
|-------|-------|
| Generated | `2026-11-08T01:30:00Z` |
| Mapper version | 6.0 |
| Run mode | RESUME (Phase 0 complete in the prior manifest; resumed at Phase 1) |
| Graph project | `C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier` |
| Graph revision | indexed `2026-11-07T18:01:14Z`, watch mode on |
| Nodes / edges | 2571 / 6819 |
| Bundle lines | 729 |
| Bundle tokens (est) | ≈18500 |
| Scope locked | `0ai_context/` only |
| Source edits | none by intent; one formatter side effect retained on `modifiers_card.dart` (report 87, item 5) |
| MCP status | ready |
| Languages | Dart (124 files), C++ (9), C (8), HTML (8), Swift (7), YAML (5), Kotlin (1) |
| Tier | small |
| Snippets | 15 |
| Findings | 20 (P0=0, P1=6, P2=9, P3=5) |
