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
> Canonical prompt specification: `0ai_context/OPENCODE-PROMPT-SPEC.md`. Follow its 8-section structure, validation rules, and anti-pattern constraints when producing the block above.
>
> **Ground rules:**
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
| Purpose | Offline-first mobile and desktop video uniquifier and anti-detection pipeline for content creators and microstock contributors |
| Stack | Flutter 3.47.8 / Dart 3.13.7 (C++, Kotlin, Swift, JavaScript) |
| Size | 318 files, 26,450 LOC |
| Commit | `de2fc36f1994ecdb35df3b0a3d989517554a9630` |
| Branch | `development` |
| Generated | `2026-11-04T01:50:00+07:00` |
| Health | analyze=ok · test=173/173 · format=fail |
| Maturity | active |

## 2. Architecture in 20 lines

```
┌─────────────────────────────────────────────────────────────┐
│ Presentation Layer (Flutter UI, Bento Grid, Navigation)    │
│ - Dashboard, ProcessScreen, BatchQueue, Settings, Reader    │
└──────────────────────────────┬──────────────────────────────┘
                               │ watches / dispatches
┌──────────────────────────────▼──────────────────────────────┐
│ Application State (ChangeNotifier Providers)                │
│ - UniquifierProvider, BatchQueueProvider, LocaleProvider    │
└──────────────────────────────┬──────────────────────────────┘
                               │ invokes orchestration
┌──────────────────────────────▼──────────────────────────────┐
│ Domain & Processing Services                                │
│ - FfmpegService, AiSuperResolutionService, DeviceCapability │
│ - HistoryService, NotificationService, SettingsService      │
└──────────────────────────────┬──────────────────────────────┘
                               │ native bridges / FFI / I/O
┌──────────────────────────────▼──────────────────────────────┐
│ Platform & Infrastructure Layer                             │
│ - ffmpeg-kit-flutter, C++ NCNN Vulkan JNI, Local Storage    │
└─────────────────────────────────────────────────────────────┘
```

## 3. Stack & Commands

| Purpose | Command | Current Result |
|---------|---------|----------------|
| Analyze | `dart analyze --fatal-infos` | exit 0, No issues found! |
| Test | `flutter test` | exit 0, 173/173 passing |
| Format | `dart format --set-exit-if-changed .` | exit 1, 89 files unformatted |
| Run | `flutter run` | Starts Flutter application on connected target device |

Version pins:
- Dart SDK: `>=3.10.0 <4.0.0` (in `pubspec.yaml`)
- Flutter Channel / Revision: `stable` / `9584c6713b324636289d067944a46fd6b49df14b`
- Gradle: `9.3.1` (in `gradle-wrapper.properties`)
- Android Gradle Plugin: `9.1.0` (in `settings.gradle.kts`)
- Kotlin: `2.4.0` (in `settings.gradle.kts`)
- Java Target: `17` (in `app/build.gradle.kts`)

## 4. Dependency Graph

Top fan-in (fragile symbols):

| Symbol | Fan-in | Path |
|--------|--------|------|
| `AppColors` | 169 | `lib/core/theme/app_colors.dart` |
| `AppLocalizations.of` | 98 | `lib/l10n/app_localizations.dart` |
| `SettingsService` | 50 | `lib/core/services/settings_service.dart` |
| `UniquifierProvider` | 31 | `lib/core/providers/uniquifier_provider.dart` |
| `AppLocalizations` | 29 | `lib/l10n/app_localizations.dart` |
| `TargetResolution` | 26 | `lib/core/services/settings_service.dart` |
| `UpscaleEngine` | 23 | `lib/core/services/settings_service.dart` |
| `BatchQueueProvider` | 18 | `lib/core/providers/batch_queue_provider.dart` |
| `VideoCodec` | 18 | `lib/core/services/settings_service.dart` |
| `MicrostockNewsArticle` | 14 | `lib/core/services/microstock_news_service.dart` |

Top co-change pairs (coupling debt):

| File A | File B | Score |
|--------|--------|-------|
| `lib/core/providers/uniquifier_provider.dart` | `test/settings_service_test.dart` | 1.00 |
| `lib/core/services/settings_service.dart` | `test/settings_service_test.dart` | 1.00 |
| `lib/core/providers/uniquifier_provider.dart` | `test/uniquifier_provider_test.dart` | 1.00 |
| `test/ffmpeg_service_test.dart` | `test/uniquifier_provider_test.dart` | 1.00 |
| `lib/core/services/notification_service.dart` | `test/notification_service_test.dart` | 1.00 |
| `android/app/src/main/cpp/ncnn_sr_jni.cpp` | `lib/core/providers/uniquifier_provider.dart` | 1.00 |
| `android/app/src/main/cpp/ncnn_sr_jni.cpp` | `lib/core/services/ffmpeg_service.dart` | 1.00 |
| `android/app/src/main/cpp/ncnn_sr_jni.cpp` | `lib/features/process/screens/processing_screen.dart` | 1.00 |
| `android/app/src/main/cpp/ncnn_sr_jni.cpp` | `lib/core/services/settings_service.dart` | 1.00 |
| `lib/core/services/ffmpeg_service.dart` | `lib/core/utils/variation_generator.dart` | 1.00 |

Reverse dependencies: 0 core->features layer inversions found in static graph.

## 5. Critical Paths

### Path: Video Transformation Pipeline
```
lib/main.dart (main)
  ├─> UniquifierProvider (state container)
  │     ├─> SettingsService (load saved toggles)
  │     └─> FfmpegService.processVideo
  │           ├─> AiSuperResolutionService.resolvePlan
  │           ├─> VariationGenerator.generate
  │           └─> FFmpegKit.executeAsync
  └─> NotificationService.showProgressNotification
```

### Path: Batch Queue Processing
```
BatchQueueTabScreen (User initiates batch)
  ├─> BatchQueueProvider.startProcessing
  │     ├─> StorageService.hasEnoughSpace
  │     ├─> FfmpegService.processVideo (per queue item)
  │     └─> MediaScannerService.scanFile
  └─> NotificationService.showCompleteNotification
```

### Path: Microstock Intelligence Feed
```
MicrostockNewsScreen (User pulls feed)
  ├─> MicrostockNewsService.loadNews
  │     ├─> ConnectivityService (online check)
  │     ├─> TranslationService.translateText
  │     └─> UserInterestService.recordTopicInterest
  └─> MicrostockArticleSheet (renders bento blocks)
```

## 6. Data Models

| Model | Key Fields | Storage |
|-------|-----------|---------|
| `BatchVideoItem` | id, inputPath, outputPath, status, progress, totalDurationMs | In-memory `BatchQueueProvider` list |
| `VideoExportItem` | file, sizeBytes, modifiedDate, formattedDuration | Scanned local filesystem (`Movies/Uniquifier`) |
| `VideoVariations` | cropPercent, brightness, contrast, noiseStrength, speedMultiplier, rotationDegree | Transient memory (injected into FFmpeg command) |
| `DeviceSpecs` | totalRamMb, availableRamMb, abi, cpuCores, isVulkanSupported | Hardware profiling cache (`DeviceCapabilityService`) |
| `MicrostockNewsArticle` | id, title, summary, source, category, publishedDate, originalTitle | Local `SharedPreferences` cache with static seeds |

## 7. External Integrations

| Integration | Direction | Payload | Optional? | Privacy |
|-------------|-----------|---------|-----------|---------|
| `ffmpeg-kit-flutter` | Bidirectional | Audio-video streams, filtergraphs, logs | No | 100% on-device local isolate |
| `Real-ESRGAN NCNN C++ JNI` | Outbound | Native Vulkan GPU frames, texture buffers | Yes | On-device hardware acceleration |
| `Google Apps Script Webhook` | Outbound | Anonymous topic affinity JSON metadata | Yes | Configurable, no PII collected |
| `RSS2JSON & Reddit Feeds` | Inbound | Public stock photography and trends RSS | Yes | Read-only public web request |
| `Google Translate API` | Inbound | Public terminology dictionary strings | Yes | Read-only snippet translation |

## 8. Health Detail

### Analyze — exit 0
Analyzing nra_video_uniquifier...
No issues found!

### Test — 173/173
All 173 tests passing cleanly across unit, integration, and widget suites.
0 failures, 0 errors, 0 flaky tests recorded.

### Format — exit 1
89 files unformatted. First 10 files needing formatting:
- `lib/core/providers/batch_queue_provider.dart`
- `lib/core/providers/uniquifier_provider.dart`
- `lib/core/services/ai_super_resolution_service.dart`
- `lib/core/services/connectivity_service.dart`
- `lib/core/services/device_capability_service.dart`
- `lib/core/services/ffmpeg_service.dart`
- `lib/core/services/filter_builders.dart`
- `lib/core/services/history_service.dart`
- `lib/core/services/media_scanner_service.dart`
- `lib/core/services/microstock_news_service.dart`

## 9. Git Activity (last 14 days)

Recent commits:
```
de2fc36 2026-11-04 feat(webhook): add Google Sheets webhook deployment guide and Apps Script for telemetry
82a164f 2026-11-03 delete: Remove archived sprint reports and project context documentation
acf834a 2026-11-03 feat: Add sprint reports for sprints 91 to 97 and archive historical reports
b175c20 2026-11-03 fix(history): isolate exports, fix thumbnails, clean workspace, and target arm64 single build
e6b62aa 2026-11-03 fix(process): correct pipeline step label contrast and apply vivid coral accent to active step line
4d35c82 2026-11-03 feat(process): wire real processing stage tracker step index in processing screen
ce0df20 2026-11-03 fix(theme): update pipeline stage step text styling for editorial design language compliance
04ec471 2026-11-03 feat(l10n): add localized strings for processing stage tracker and engine state strip
aa487eb 2026-11-03 test: add unit and widget test suite for processing stage tracker in dark and light modes
0a84d49 2026-11-03 feat(ui): replace static text step tracker with dynamic 5-stage progress indicator
```

Most-changed files:
```
     46 0ai_context/STATE.md
     34 lib/core/services/ffmpeg_service.dart
     32 test/ffmpeg_service_test.dart
     26 0ai_context/reports/INDEX.md
     25 lib/features/process/screens/processing_screen.dart
     25 test/widget_test.dart
     24 lib/core/providers/uniquifier_provider.dart
     20 lib/core/services/settings_service.dart
     18 lib/core/services/filter_builders.dart
     17 lib/features/process/widgets/modifiers_card.dart
```

## 10. Findings Inventory

| ID | Sev | Cat | Location | Impact | Fix | Since |
|----|-----|-----|----------|--------|-----|-------|
| AUDIT-20261104-001 | P1 | quality | `lib/:1` | Code formatting check fails across 89 files in CI pipeline causing test and build gate rejection. | Run dart format lib/ test/ to format all 89 unformatted files according to Flutter standards. | new |
| AUDIT-20261104-002 | P1 | safety | `lib/core/services/ffmpeg_service.dart:149` | Hardcoded external storage path /storage/emulated/0/Movies/Uniquifier fails on multi-user Android profiles and non-standard devices. | Query destination path dynamically via getExternalStorageDirectories or StorageService helper. | new |
| AUDIT-20261104-003 | P1 | safety | `lib/core/services/history_service.dart:46` | Hardcoded /storage/emulated/0/Movies/Uniquifier directory breaks scoped storage compliance on modern Android releases. | Resolve target directories strictly through path_provider StorageDirectory.movies without hardcoded paths. | new |
| AUDIT-20261104-005 | P1 | correctness | `lib/core/services/ffmpeg_service.dart:293` | Silently catching stageInputFile exception hides disk space exhaustion and I/O failures prior to rendering. | Catch specific FileSystemException instances and propagate meaningful staging errors. | new |
| AUDIT-20261104-019 | P1 | quality | `lib/core/services/settings_service.dart:1` | High fan-in of 50 incoming dependencies to static service methods inhibits test mocking and clean architecture. | Abstract SettingsService into an injectable interface or provider service. | new |
| AUDIT-20261104-020 | P1 | quality | `lib/core/providers/uniquifier_provider.dart:1` | High fan-in of 31 incoming references concentrates pipeline, UI settings, and presets into single god-object. | Decompose into dedicated state providers for pipeline execution, video settings, and UI toggles. | new |
| AUDIT-20261104-004 | P2 | correctness | `lib/features/process/screens/success_screen.dart:59` | Fallback string /storage/emulated/0/Movies/Uniquifier produces misleading UI destination path when custom storage is used. | Fallback to StorageService base destination or localized directory label when effectivePath is null. | new |
| AUDIT-20261104-006 | P2 | lifecycle | `lib/core/services/ffmpeg_service.dart:118` | Empty catch block in media probe fallback discards ffprobe metadata inspection errors silently. | Log ffprobe inspection errors to debug log viewer to surface corrupted media headers. | new |
| AUDIT-20261104-007 | P2 | correctness | `lib/core/providers/uniquifier_provider.dart:138` | Empty catch handlers across 15+ toggle mutators silently discard SharedPreferences persistence failures. | Log persistence failures and notify listeners or UI indicators when preferences cannot be committed. | new |
| AUDIT-20261104-008 | P2 | safety | `lib/core/services/storage_service.dart:41` | Swallowing cleanup exceptions during stale file pruning leaves orphaned staging files undetected on low disk space. | Catch FileSystemException explicitly and emit diagnostic warnings when files fail deletion. | new |
| AUDIT-20261104-009 | P2 | correctness | `lib/core/services/history_service.dart:59` | Empty error handler in history loader hides filesystem read permission rejections from users. | Capture filesystem permission exceptions and surface a non-fatal permission warning state. | new |
| AUDIT-20261104-010 | P2 | correctness | `lib/core/services/translation_service.dart:113` | Silent exception handling during JSON translation parsing returns empty strings without error telemetry. | Fallback to raw source text and log parsing exceptions to diagnostics. | new |
| AUDIT-20261104-011 | P2 | lifecycle | `lib/core/services/notification_service.dart:110` | Empty catch block in notification permission check masks initialization faults on Android 13+. | Log notification permission request exceptions to debugPrint for troubleshooting. | new |
| AUDIT-20261104-014 | P2 | quality | `test/ffmpeg_service_test.dart:1` | Monolithic test file of 737 lines mixes unit, integration, and mocking logic, hindering maintainability. | Decompose into separate test suites for filter composition, metadata probing, and process execution. | new |
| AUDIT-20261104-015 | P2 | quality | `test/widget_test.dart:1` | Monolithic widget test file of 575 lines causes high test fragility across disparate UI features. | Split into dedicated widget tests grouped by feature modules under test/features/. | new |
| AUDIT-20261104-017 | P2 | quality | `lib/core/theme/app_colors.dart:1` | High fan-in of 169 incoming dependencies creates extreme styling coupling across entire codebase. | Refactor direct AppColors references to semantic tokens via Theme.of(context).colorScheme. | new |
| AUDIT-20261104-018 | P2 | quality | `lib/l10n/app_localizations.dart:3` | High fan-in of 98 direct call sites to AppLocalizations.of couples widgets directly to global localization state. | Encapsulate localization access through scoped BuildContext extensions. | new |
| AUDIT-20261104-021 | P2 | quality | `lib/core/services/settings_service.dart:26` | High fan-in of 26 dependencies on TargetResolution enum leaks persistence serialization details into UI widgets. | Encapsulate resolution mapping inside domain models rather than static service enums. | new |
| AUDIT-20261104-022 | P2 | quality | `android/app/src/main/cpp/ncnn_sr_jni.cpp:1` | Native JNI implementation and FfmpegService co-change with 1.0 correlation, indicating tight ABI coupling. | Establish formalized native method interface contract to decouple C++ changes from service callers. | new |
| AUDIT-20261104-023 | P2 | quality | `android/app/src/main/cpp/ncnn_sr_jni.cpp:1` | Native C++ upscale engine co-changes directly with UniquifierProvider UI layer (coupling score 1.0). | Isolate native upscale calls strictly behind AISuperResolutionService abstraction. | new |
| AUDIT-20261104-024 | P2 | quality | `lib/core/services/ffmpeg_service.dart:1` | FfmpegService and VariationGenerator exhibit tight 1.0 co-change coupling across pipeline revisions. | Inject variation strategies into filter builder rather than hard-coupling generator to service. | new |
| AUDIT-20261104-012 | P3 | lifecycle | `lib/main.dart:21` | Silent exception handling during FFmpegKit session history setup masks native configuration failures. | Add error logging to capture native binding initialization errors during bootstrap. | new |
| AUDIT-20261104-013 | P3 | lifecycle | `lib/features/process/screens/processing_screen.dart:103` | Empty catch block discards telemetry record dispatching silently during pipeline completion. | Log telemetry recording exceptions to debug logging without blocking UX flow. | new |
| AUDIT-20261104-016 | P3 | quality | `lib/l10n/app_localizations.dart:1` | Monolithic localization wrapper of 489 lines couples all UI screens to a single massive localization contract. | Review localization generation configuration or document split domain dictionaries. | new |

## 11. Code Snippets

### Snippet 1 — `lib/core/theme/app_colors.dart:4` — Core editorial design tokens consumed across UI hierarchy

```dart
class AppColors {
  static const Color forestDeep = Color(0xFF0E5535);
  static const Color mintSage = Color(0xFFA3EFD5);
  static const Color skyPastel = Color(0xFF7DDCF0);
  static const Color butterYellow = Color(0xFFFFE98C);
  static const Color persimmonOrange = Color(0xFFFF8E3E);
  static const Color obsidianBase = Color(0xFF111817);
  static const Color obsidianDark = Color(0xFF1A2523);
  static const Color mustardOchre = Color(0xFFC2A500);
  static const Color electricIce = Color(0xFF7BD6F3);
  static const Color peachCream = Color(0xFFFEC7A0);
  static const Color vividCoral = Color(0xFFFF4431);
  static const Color surface = Color(0xFF1A2523);
  static const Color surfaceContainerLowest = Color(0xFF111817);
  static const Color surfaceContainerLow = Color(0xFF1A2523);
  static const Color surfaceContainer = Color(0xFF22302D);
  static const Color surfaceContainerHigh = Color(0xFF2D3E3A);
}
```

### Snippet 2 — `lib/core/services/settings_service.dart:125` — Persistent reactive settings notifiers backed by SharedPreferences

```dart
  static final ValueNotifier<bool> hardwareAccelerationNotifier =
      ValueNotifier<bool>(true);
  static final ValueNotifier<VideoCodec> videoCodecNotifier =
      ValueNotifier<VideoCodec>(VideoCodec.h264);
  static Future<VideoCodec> getVideoCodec() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyVideoCodec);
    final codec = VideoCodec.fromString(raw);
    videoCodecNotifier.value = codec;
    return codec;
  }
  static Future<void> setVideoCodec(VideoCodec codec) async {
    videoCodecNotifier.value = codec;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyVideoCodec, codec.key);
  }
  static Future<bool> getNotificationSound() => _getBool(keyNotificationSound, true);
```

### Snippet 3 — `lib/core/providers/uniquifier_provider.dart:8` — Provider lifecycle and listener binding to settings notifiers

```dart
class UniquifierProvider extends ChangeNotifier {
  UniquifierProvider() {
    SettingsService.upscaleResolutionNotifier.addListener(_onResolutionNotifierChanged);
    SettingsService.upscaleEngineNotifier.addListener(_onUpscaleEngineNotifierChanged);
    SettingsService.videoCodecNotifier.addListener(_onCodecNotifierChanged);
    SettingsService.hardwareAccelerationNotifier.addListener(_onHardwareAccelerationNotifierChanged);
    _initResolution();
  }
  @override
  void dispose() {
    SettingsService.upscaleResolutionNotifier.removeListener(_onResolutionNotifierChanged);
    SettingsService.upscaleEngineNotifier.removeListener(_onUpscaleEngineNotifierChanged);
    SettingsService.videoCodecNotifier.removeListener(_onCodecNotifierChanged);
    SettingsService.hardwareAccelerationNotifier.removeListener(_onHardwareAccelerationNotifierChanged);
    super.dispose();
  }
}
```

### Snippet 4 — `lib/core/providers/batch_queue_provider.dart:7` — Batch video processing queue state and progress tracking

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
    for (final item in _items) sum += item.progress;
    return sum / _items.length;
  }
}
```

### Snippet 5 — `lib/core/services/ffmpeg_service.dart:22` — Master FFmpeg command generator building filterchains and codec parameters

```dart
  static String buildCommand({
    required String inputPath, required String outputPath,
    bool removeMetadata = true, bool modifyAudio = true, bool modifyVisuals = true,
    bool upscale1080p = false, bool? upscale,
    TargetResolution targetResolution = TargetResolution.r1080p,
    UpscaleEngine upscaleEngine = UpscaleEngine.lanczos, VideoCodec videoCodec = VideoCodec.h264,
    bool enableEnhanceAndDenoise = true, bool enableDeepAntiFingerprint = true,
    bool enableHorizontalFlip = false, bool enableAggressiveAudio = false, bool enableAutoTrim = false,
    int totalDurationMs = 0, bool isPortrait = false, bool enableHardwareAcceleration = false,
    bool enableBlurredCanvas = false, double canvasScalePercent = 95.0, bool muteOriginalAudio = false,
    bool enableDynamicZoom = false, bool enableMicroOverlay = false,
    bool enableFrameSkip = false, bool enableChromaShift = false, VideoVariations? variations,
    bool thermalThrottle = false, int? targetFps, double? saturationLevel,
    double cropZoomScale = 1.0, String cropAnchor = 'center', double introTrimOffset = 0.5,
  }) {
    final buffer = StringBuffer('-y');
    _writeInputOptions(buffer, inputPath, enableHardwareAcceleration, enableAutoTrim, totalDurationMs, thermalThrottle, introTrimOffset);
    if (removeMetadata) _writeMetadataTags(buffer);
```

### Snippet 6 — `lib/core/utils/variation_generator.dart:59` — Randomized perceptual anti-detection perturbations generation

```dart
  static VideoVariations generate({math.Random? random}) {
    try {
      final rng = random ?? _random;
      final crop = 0.07 + rng.nextDouble() * 0.02;
      final bright = -0.01 + rng.nextDouble() * 0.02;
      final cont = 0.99 + rng.nextDouble() * 0.02;
      final sat = 0.99 + rng.nextDouble() * 0.02;
      final noise = rng.nextBool() ? 3 : 4;
      final speed = 1.010 + rng.nextDouble() * 0.015;
      final rot = 0.6 + rng.nextDouble() * 0.3;
      final tempo = speed;
      final fps = 29.80 + rng.nextDouble() * 0.10;
      final pitch = 0.985 + rng.nextDouble() * 0.030;
      return VideoVariations(
        cropPercent: crop,
        brightness: bright,
        contrast: cont,
        saturation: sat,
        noiseStrength: noise,
      );
    } catch (_) { return VideoVariations.fallback(); }
  }
```

### Snippet 7 — `lib/features/process/screens/processing_screen.dart:106` — Process screen invoking native FFmpeg execution via provider values

```dart
  Future<String> _processWithNative(UniquifierProvider provider, String inputPath) {
    return FfmpegService.processVideo(
      inputPath: inputPath,
      removeMetadata: provider.removeMetadata,
      modifyAudio: provider.modifyAudio,
      modifyVisuals: provider.modifyVisuals,
      upscale1080p: provider.upscale1080p,
      targetResolution: provider.targetResolution,
      upscaleEngine: provider.upscaleEngine,
      videoCodec: provider.videoCodec,
      enableEnhanceAndDenoise: provider.enableEnhanceAndDenoise,
      enableDeepAntiFingerprint: provider.enableDeepAntiFingerprint,
      enableHorizontalFlip: provider.enableHorizontalFlip,
      enableAggressiveAudio: provider.enableAggressiveAudio,
      enableAutoTrim: provider.enableAutoTrim,
      isPortrait: provider.isPortrait,
      enableHardwareAcceleration: provider.hardwareAcceleration,
      enableBlurredCanvas: provider.enableBlurredCanvas,
      canvasScalePercent: provider.canvasScalePercent,
      muteOriginalAudio: provider.muteOriginalAudio,
    );
  }
```

### Snippet 8 — `lib/core/services/ai_super_resolution_service.dart:89` — Dynamic upscale engine planner with Vulkan checking and Lanczos fallback

```dart
  static Future<AiSuperResolutionPlan> resolvePlan({
    required UpscaleEngine engine,
    required TargetResolution targetResolution,
    required bool isPortrait,
  }) async {
    final targetW = isPortrait ? targetResolution.height : targetResolution.width;
    final targetH = isPortrait ? targetResolution.width : targetResolution.height;
    if (engine == UpscaleEngine.neuralAi) {
      final vulkanAvailable = await isVulkanSupported();
      if (!vulkanAvailable) {
        debugPrint('[AiSuperResolution] Vulkan compute unavailable on this device. Transparent fallback: Real-ESRGAN -> Lanczos3.');
      }
      return AiSuperResolutionPlan(
        engine: engine,
        targetResolution: targetResolution,
        isPortrait: isPortrait,
        targetWidth: targetW,
        targetHeight: targetH,
        isVulkanAccelerated: vulkanAvailable,
        isFallbackEngaged: !vulkanAvailable,
      );
    }
    return AiSuperResolutionPlan(engine: engine, targetResolution: targetResolution, isPortrait: isPortrait, targetWidth: targetW, targetHeight: targetH);
  }
```

### Snippet 9 — `lib/core/services/device_capability_service.dart:88` — Platform channel bridge profiling RAM, ABI, and GPU capabilities

```dart
class DeviceCapabilityService {
  static const MethodChannel _channel = MethodChannel('id.novrira.videouniquifier/device_capability');
  static DeviceSpecs? _cachedSpecs;
  static bool? _testOverride;
  static DeviceSpecs? _testSpecsOverride;
  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;
  @visibleForTesting
  static set testSpecsOverride(DeviceSpecs? specs) => _testSpecsOverride = specs;
  static bool get _canRun => _testOverride ?? Platform.isAndroid;
  static Future<DeviceSpecs> getSpecs() async {
    if (_testSpecsOverride != null) return _testSpecsOverride!;
    if (_cachedSpecs != null) return _cachedSpecs!;
    if (!_canRun) {
      _cachedSpecs = DeviceSpecs.defaultFallback();
      return _cachedSpecs!;
    }
  }
}
```

### Snippet 10 — `lib/core/services/connectivity_service.dart:6` — Network connectivity monitoring singleton with testing bypass

```dart
class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._internal();
  ConnectivityService._internal();
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);
  Timer? _pollingTimer;
  bool _initialized = false;
  @visibleForTesting
  static Future<bool> Function()? mockPingHandler;
  void initialize({Duration interval = const Duration(seconds: 10)}) {
    if (_initialized) return;
    _initialized = true;
    checkConnectivity();
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
  }
}
```

### Snippet 11 — `lib/core/services/history_service.dart:42` — Export directory discovery across Android internal and public external storage

```dart
class HistoryService {
  static Future<List<Directory>> getTargetDirectories() async {
    final dirs = <Directory>[];
    if (Platform.isAndroid) {
      dirs.add(Directory('/storage/emulated/0/Movies/Uniquifier'));
      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.movies);
        if (extDirs != null) {
          for (final dir in extDirs) {
            dirs.add(Directory('${dir.path}/Uniquifier'));
          }
        }
      } catch (_) {}
    }
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      dirs.add(Directory('${appDocs.path}/Movies/Uniquifier'));
    } catch (_) {}
    return dirs;
  }
}
```

### Snippet 12 — `lib/core/services/microstock_news_service.dart:85` — Multitier news loader with network refresh and offline seed fallback

```dart
  static Future<List<MicrostockNewsArticle>> loadNews({bool forceRefresh = false}) async {
    final isOnline = ConnectivityService.instance.isOnline.value;
    if (forceRefresh && isOnline) return await fetchAndCacheNews();
    final cached = await getCachedNews();
    if (cached.isNotEmpty && !forceRefresh) return cached;
    if (isOnline) {
      try {
        final online = await fetchAndCacheNews();
        if (online.isNotEmpty) return online;
      } catch (_) {
        if (cached.isNotEmpty) return cached;
      }
    }
    if (cached.isNotEmpty) return cached;
    final seed = getSeedArticles();
    await saveNewsToCache(seed);
    return seed;
  }
```

### Snippet 13 — `lib/core/services/user_interest_service.dart:129` — Telemetry dispatcher formatting metadata vault analytics payloads

```dart
  static Future<void> dispatchVideoMetadataVault({
    required String title,
    required String description,
    required List<String> keywords,
    required List<String> platforms,
    required String techSpecs,
    required String category,
    String leadWindow = '',
  }) async {
    await _dispatchTelemetry({
      'type': 'video_metadata_vault',
      'title': title,
      'description': description,
      'keywords': keywords,
      'platforms': platforms,
      'techSpecs': techSpecs,
      'category': category,
      'leadWindow': leadWindow,
    });
  }
```

### Snippet 14 — `lib/core/services/storage_service.dart:4` — Disk space verification threshold before launching video renders

```dart
class StorageService {
  static const int minRequiredBytes = 2 * 1024 * 1024 * 1024; // 2 GB
  static Future<bool> hasEnoughSpace() async {
    try {
      if (!Platform.isAndroid) return true;
      final tempDir = await getTemporaryDirectory();
      final stat = await FileStat.stat(tempDir.path);
      return stat.type != FileSystemEntityType.notFound;
    } catch (_) {
      return true;
    }
  }
}
```

### Snippet 15 — `lib/core/services/filter_builders.dart:66` — Resolution dimension calculation and Lanczos scale filter creation

```dart
  static (int, int) canonicalDimensions(TargetResolution res, {required bool isPortrait}) {
    switch (res) {
      case TargetResolution.r1080p:
        return isPortrait ? (1080, 1920) : (1920, 1080);
      case TargetResolution.r2k:
        return isPortrait ? (1440, 2560) : (2560, 1440);
      case TargetResolution.r4k:
        return isPortrait ? (2160, 3840) : (3840, 2160);
    }
  }
  static String buildScaleFilter({
    required TargetResolution targetResolution,
    required bool isPortrait,
    UpscaleEngine upscaleEngine = UpscaleEngine.lanczos,
  }) {
    final (w, h) = canonicalDimensions(targetResolution, isPortrait: isPortrait);
    return 'scale=w=$w:h=$h:flags=lanczos+accurate_rnd,unsharp=5:5:1.2:5:5:0.5';
  }
```

### Snippet 16 — `lib/main.dart:17` — Application bootstrap, service initialization, and multi-provider registration

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    FFmpegKitConfig.setSessionHistorySize(3);
  } catch (_) {}
  try {
    await StorageService.pruneStaleFiles();
    await SettingsService.purgeTempCache();
  } catch (_) {}
  try {
    await NotificationService.initialize();
    await NotificationService.requestPermission();
    ConnectivityService.instance.initialize();
  } catch (_) {}
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => UniquifierProvider()),
      ],
    ),
  );
}
```

### Snippet 17 — `lib/features/navigation/screens/root_navigation_screen.dart:19` — Lazy indexed page stack managed by UniquifierProvider active tab

```dart
class _RootNavigationScreenState extends State<RootNavigationScreen> {
  final List<bool> _initializedTabs = [true, false, false, false, false];
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();
    final currentIndex = provider.currentTabIndex.clamp(0, 4);
    _initializedTabs[currentIndex] = true;
    final pages = [
      _initializedTabs[0] ? const DashboardScreen() : const SizedBox.shrink(),
      _initializedTabs[1] ? const MicrostockNewsScreen() : const SizedBox.shrink(),
      _initializedTabs[2] ? const ProcessScreen() : const SizedBox.shrink(),
      _initializedTabs[3] ? const RecentHistoryScreen() : const SizedBox.shrink(),
      _initializedTabs[4] ? const ProfilePlaceholderScreen() : const SizedBox.shrink(),
    ];
    return Scaffold(extendBody: true, body: Stack(children: [IndexedStack(index: currentIndex, children: pages)]));
  }
}
```

### Snippet 18 — `lib/features/process/widgets/modifiers_card.dart:139` — Modifier counts aggregator across core, visual, and texture categories

```dart
class ModifiersCard extends StatelessWidget {
  final UniquifierProvider provider;
  final VoidCallback onOpenAdvanced;
  const ModifiersCard({super.key, required this.provider, required this.onOpenAdvanced});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final coreActive = (provider.removeMetadata ? 1 : 0) +
            (provider.enableDeepAntiFingerprint ? 1 : 0) +
            (provider.enableAutoTrim ? 1 : 0);
        final visualActive = (provider.modifyVisuals ? 1 : 0) +
            (provider.upscale1080p ? 1 : 0) +
            (provider.enableEnhanceAndDenoise ? 1 : 0);
        return Card(child: Text('Active: ${coreActive + visualActive}'));
      },
    );
  }
}
```

### Snippet 19 — `lib/features/process/widgets/processing_stage_tracker.dart:4` — Sequential 5-stage pipeline transformation step indicator

```dart
class ProcessingStageTracker extends StatelessWidget {
  final int currentStep;
  const ProcessingStageTracker({super.key, required this.currentStep});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StageStep(
          label: 'METADATA',
          isCompleted: currentStep > 1,
          isActive: currentStep == 1,
        ),
        const SizedBox(width: 4),
        _StageStep(
          label: 'TRANSFORM',
          isCompleted: currentStep > 2,
          isActive: currentStep == 2,
        ),
      ],
    );
  }
}
```

## 12. Open Questions

1. In section 3, formatting check fails across 89 files; should `dart format lib/ test/` be executed immediately as a preliminary cleanup step?
2. In section 10 (AUDIT-20261104-002), how should `/storage/emulated/0/Movies/Uniquifier` in `ffmpeg_service.dart` be refactored to support non-standard Android devices and desktop platforms?
3. In section 11 (Snippet 8), what fallback behavior is engaged when `UpscaleEngine.neuralAi` is selected but Vulkan compute is unavailable?
4. In section 10 (AUDIT-20261104-005), what risk is introduced by silently catching exceptions in `stageInputFile` during video processing?
5. In section 4, what architectural risk is posed by `SettingsService` having a fan-in of 50 incoming dependencies?
6. In section 11 (Snippet 14), why does `StorageService.hasEnoughSpace` use a file stat existence check rather than native StatFS on Android?
7. In section 11 (Snippet 6), what parameter bounds are generated by `VariationGenerator` for video crop, speed, and rotation to bypass fingerprinting?
8. In section 7, which external endpoints are queried over network by `MicrostockNewsService` and `UserInterestService`?
9. In section 11 (Snippet 4), how does `BatchQueueProvider` calculate aggregate batch completion progress across all queued items?
10. In section 10 (AUDIT-20261104-020), what modular state providers should replace `UniquifierProvider` to eliminate god-object coupling?

## 13. Decision Log
- Sprint 96: Dynamic 5-stage progress indicator replaces legacy static text status.
- Sprint 89: Editorial Architecture Design Tokens adopted across all UI elements (`AppColors.forestDeep`, `AppColors.vividCoral`).
- Sprint 65: FastStart (`-movflags +faststart`) and constant frame rate (`-fps_mode cfr`) enforced on all FFmpeg exports.
- Sprint 62: Real-ESRGAN NCNN C++ Vulkan neural super-resolution integration on Android with Lanczos3 mathematical fallback.
- Architecture: Provider pattern retained for reactive UI updates without third-party BLoC or Riverpod runtime overhead.

## 14. Constraints (inviolable)

- Offline-first media pipeline: Video transcoding, audio alterations, and anti-fingerprint filters must execute 100% locally on-device.
- Zero mandatory network dependency: The application must remain fully functional with all video features operational when offline.
- Output directory isolation: All exported media must be saved to user-accessible `Movies/Uniquifier` storage without polluting app sandbox directories.
- Platform support: Primary Android deployment (API 24+) with desktop runner support for Linux and Windows development.

## 15. Glossary

| Term | Definition |
|------|-----------|
| Uniquifier | Audio-visual transformation process altering video bitstreams to prevent perceptual hashing matches |
| Anti-Fingerprint | Randomized micro-perturbations (crop, speed warp, EQ tweak) defeating platform VDNA duplicate detection |
| FastStart | FFmpeg `-movflags +faststart` flag moving the moov atom to the beginning of MP4 files for instant playback |
| Lanczos3 | High-quality mathematical sinc interpolation filter algorithm used for video upscaling |
| Real-ESRGAN | Deep convolutional neural network model used for AI-based super-resolution video upscaling |
| NCNN | High-performance neural network inference computing framework optimized for mobile GPU/Vulkan execution |
| Vulkan | Low-overhead cross-platform 3D graphics and compute API utilized by NCNN for on-device AI tensor processing |
| Scoped Storage | Android storage model isolating app storage and requiring MediaStore / public folder APIs for exports |
| Stage Tracker | 5-phase visual progress indicator (Metadata, Transform, Denoise, Upscale, Export) displaying pipeline state |
| Bento Grid | Modular dashboard layout structure composed of varied-size rectangular cards displaying live metrics |

## 16. Run Manifest

| Field | Value |
|-------|-------|
| Generated | `2026-11-04T01:50:00+07:00` |
| Mapper version | 6.0 |
| Graph project | `C-Users-Administrator-Saved-Games-_Project-nra_video_uniquifier` |
| Graph revision | `de2fc36f1994ecdb35df3b0a3d989517554a9630` |
| Nodes / edges | 1671 / 4755 |
| Bundle lines | 714 |
| Bundle tokens (est) | 17850 |
| Scope locked | `0ai_context/` only |
| Source edits | none |
| MCP status | ready |
| Languages | Dart, C++, Kotlin, Swift, JavaScript |
| Tier | small |
