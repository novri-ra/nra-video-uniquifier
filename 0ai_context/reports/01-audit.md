# Project Audit — Report 01

## Summary
- Revision: `de2fc36f1994ecdb35df3b0a3d989517554a9630`
- Stack: Flutter 3.47.8 / Dart 3.13.7 (C++, Kotlin, Swift, JavaScript)
- Deterministic: analyze=0, test=173/173 passed, format=89 files unformatted (exit 1)
- Findings: P0=0, P1=6, P2=15, P3=3
- Graph checks: run (1671 nodes, 4755 edges, 0 cycles, 0 dead code)

## Deterministic Checks
| Check | Command | Result | Evidence |
|-------|---------|--------|----------|
| Analyze | `dart analyze --fatal-infos` | exit 0, No issues found! | `raw/health/analyze.log` |
| Test | `flutter test` | exit 0, 173/173 passed | `raw/health/test.log` |
| Format | `dart format --set-exit-if-changed .` | exit 1, 89 files unformatted | `raw/health/format.log` |

## Findings

### AUDIT-20261104-001 — P1 — Code formatting gate failure across 89 files
- Category: quality
- Location: `lib/:1`
- Evidence: E1 — `raw/health/format.log` reports 89 unformatted files across lib/ and test/.
- Impact: Code formatting check fails across 89 files in CI pipeline causing test and build gate rejection.
- Fix: Run `dart format lib/ test/` to format all 89 unformatted files according to Flutter standards.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-002 — P1 — Hardcoded external storage path in FfmpegService
- Category: safety
- Location: `lib/core/services/ffmpeg_service.dart:149`
- Evidence: E1 — Pattern scan matches string literal `"/storage/emulated/0/Movies/Uniquifier"`.
- Impact: Hardcoded external storage path /storage/emulated/0/Movies/Uniquifier fails on multi-user Android profiles and non-standard devices.
- Fix: Query destination path dynamically via getExternalStorageDirectories or StorageService helper.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-003 — P1 — Hardcoded external storage path in HistoryService
- Category: safety
- Location: `lib/core/services/history_service.dart:46`
- Evidence: E1 — Pattern scan matches string literal `"/storage/emulated/0/Movies/Uniquifier"`.
- Impact: Hardcoded /storage/emulated/0/Movies/Uniquifier directory breaks scoped storage compliance on modern Android releases.
- Fix: Resolve target directories strictly through path_provider StorageDirectory.movies without hardcoded paths.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-004 — P2 — Fallback string in SuccessScreen displays hardcoded path
- Category: correctness
- Location: `lib/features/process/screens/success_screen.dart:59`
- Evidence: E1 — String literal `"/storage/emulated/0/Movies/Uniquifier"` used as fallback label.
- Impact: Fallback string /storage/emulated/0/Movies/Uniquifier produces misleading UI destination path when custom storage is used.
- Fix: Fallback to StorageService base destination or localized directory label when effectivePath is null.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-005 — P1 — Silent exception swallowing in stageInputFile
- Category: correctness
- Location: `lib/core/services/ffmpeg_service.dart:293`
- Evidence: E1 — Empty `catch (_)` block wraps staging copy and space checks.
- Impact: Silently catching stageInputFile exception hides disk space exhaustion and I/O failures prior to rendering.
- Fix: Catch specific FileSystemException instances and propagate meaningful staging errors.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-006 — P2 — Empty catch handler in media probe fallback
- Category: lifecycle
- Location: `lib/core/services/ffmpeg_service.dart:118`
- Evidence: E1 — Empty `catch (_)` block ignores ffprobe inspection failure.
- Impact: Empty catch block in media probe fallback discards ffprobe metadata inspection errors silently.
- Fix: Log ffprobe inspection errors to debug log viewer to surface corrupted media headers.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-007 — P2 — Unhandled exceptions in UniquifierProvider toggle mutators
- Category: correctness
- Location: `lib/core/providers/uniquifier_provider.dart:138`
- Evidence: E1 — Empty `catch (_)` blocks in toggle persistence methods.
- Impact: Empty catch handlers across 15+ toggle mutators silently discard SharedPreferences persistence failures.
- Fix: Log persistence failures and notify listeners or UI indicators when preferences cannot be committed.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-008 — P2 — Silent exception swallowing during stale file pruning
- Category: safety
- Location: `lib/core/services/storage_service.dart:41`
- Evidence: E1 — Empty `catch (_)` block inside file deletion loop.
- Impact: Swallowing cleanup exceptions during stale file pruning leaves orphaned staging files undetected on low disk space.
- Fix: Catch FileSystemException explicitly and emit diagnostic warnings when files fail deletion.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-009 — P2 — Silent catch block in HistoryService directory scanner
- Category: correctness
- Location: `lib/core/services/history_service.dart:59`
- Evidence: E1 — Empty `catch (_)` block in `scanDirectory` method.
- Impact: Empty error handler in history loader hides filesystem read permission rejections from users.
- Fix: Capture filesystem permission exceptions and surface a non-fatal permission warning state.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-010 — P2 — Unhandled JSON parse exception in TranslationService
- Category: correctness
- Location: `lib/core/services/translation_service.dart:113`
- Evidence: E1 — Empty `catch (_)` block handles JSON decoding errors.
- Impact: Silent exception handling during JSON translation parsing returns empty strings without error telemetry.
- Fix: Fallback to raw source text and log parsing exceptions to diagnostics.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-011 — P2 — Silent exception in notification permission request
- Category: lifecycle
- Location: `lib/core/services/notification_service.dart:110`
- Evidence: E1 — Empty `catch (_)` block wraps method channel call.
- Impact: Empty catch block in notification permission check masks initialization faults on Android 13+.
- Fix: Log notification permission request exceptions to debugPrint for troubleshooting.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-012 — P3 — Silent exception handling in FFmpegKit bootstrap
- Category: lifecycle
- Location: `lib/main.dart:21`
- Evidence: E1 — Empty `catch (_)` block around `FFmpegKitConfig.setSessionHistorySize(3)`.
- Impact: Silent exception handling during FFmpegKit session history setup masks native configuration failures.
- Fix: Add error logging to capture native binding initialization errors during bootstrap.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-013 — P3 — Discarded telemetry exceptions in ProcessingScreen
- Category: lifecycle
- Location: `lib/features/process/screens/processing_screen.dart:103`
- Evidence: E1 — Empty `catch (_)` block around telemetry dispatch.
- Impact: Empty catch block discards telemetry record dispatching silently during pipeline completion.
- Fix: Log telemetry recording exceptions to debug logging without blocking UX flow.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-014 — P2 — Monolithic ffmpeg_service_test test suite
- Category: quality
- Location: `test/ffmpeg_service_test.dart:1`
- Evidence: E1 — File length 737 lines (>400 LOC threshold).
- Impact: Monolithic test file of 737 lines mixes unit, integration, and mocking logic, hindering maintainability.
- Fix: Decompose into separate test suites for filter composition, metadata probing, and process execution.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-015 — P2 — Monolithic widget_test test suite
- Category: quality
- Location: `test/widget_test.dart:1`
- Evidence: E1 — File length 575 lines (>400 LOC threshold).
- Impact: Monolithic widget test file of 575 lines causes high test fragility across disparate UI features.
- Fix: Split into dedicated widget tests grouped by feature modules under test/features/.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-016 — P3 — Monolithic localization wrapper
- Category: quality
- Location: `lib/l10n/app_localizations.dart:1`
- Evidence: E1 — File length 489 lines (>400 LOC threshold).
- Impact: Monolithic localization wrapper of 489 lines couples all UI screens to a single massive localization contract.
- Fix: Review localization generation configuration or document split domain dictionaries.
- Scope: doc-only
- Since: new

### AUDIT-20261104-017 — P2 — High fan-in on AppColors design tokens
- Category: quality
- Location: `lib/core/theme/app_colors.dart:1`
- Evidence: E2 — Graph query confirms fan-in of 169 incoming dependencies.
- Impact: High fan-in of 169 incoming dependencies creates extreme styling coupling across entire codebase.
- Fix: Refactor direct AppColors references to semantic tokens via Theme.of(context).colorScheme.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-018 — P2 — High fan-in on AppLocalizations.of caller sites
- Category: quality
- Location: `lib/l10n/app_localizations.dart:3`
- Evidence: E2 — Graph query confirms fan-in of 98 direct call sites.
- Impact: High fan-in of 98 direct call sites to AppLocalizations.of couples widgets directly to global localization state.
- Fix: Encapsulate localization access through scoped BuildContext extensions.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-019 — P1 — High fan-in on static SettingsService
- Category: quality
- Location: `lib/core/services/settings_service.dart:1`
- Evidence: E2 — Graph query confirms fan-in of 50 incoming dependencies.
- Impact: High fan-in of 50 incoming dependencies to static service methods inhibits test mocking and clean architecture.
- Fix: Abstract SettingsService into an injectable interface or provider service.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-020 — P1 — God-object coupling in UniquifierProvider
- Category: quality
- Location: `lib/core/providers/uniquifier_provider.dart:1`
- Evidence: E2 — Graph query confirms fan-in of 31 incoming references across screens and services.
- Impact: High fan-in of 31 incoming references concentrates pipeline, UI settings, and presets into single god-object.
- Fix: Decompose into dedicated state providers for pipeline execution, video settings, and UI toggles.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-021 — P2 — High fan-in on TargetResolution enum
- Category: quality
- Location: `lib/core/services/settings_service.dart:26`
- Evidence: E2 — Graph query confirms fan-in of 26 dependencies on TargetResolution.
- Impact: High fan-in of 26 dependencies on TargetResolution enum leaks persistence serialization details into UI widgets.
- Fix: Encapsulate resolution mapping inside domain models rather than static service enums.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-022 — P2 — Co-change coupling between ncnn_sr_jni.cpp and FfmpegService
- Category: quality
- Location: `android/app/src/main/cpp/ncnn_sr_jni.cpp:1`
- Evidence: E2 — Graph co-change query confirms coupling score of 1.0.
- Impact: Native JNI implementation and FfmpegService co-change with 1.0 correlation, indicating tight ABI coupling.
- Fix: Establish formalized native method interface contract to decouple C++ changes from service callers.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-023 — P2 — Co-change coupling between ncnn_sr_jni.cpp and UniquifierProvider
- Category: quality
- Location: `android/app/src/main/cpp/ncnn_sr_jni.cpp:1`
- Evidence: E2 — Graph co-change query confirms coupling score of 1.0.
- Impact: Native C++ upscale engine co-changes directly with UniquifierProvider UI layer (coupling score 1.0).
- Fix: Isolate native upscale calls strictly behind AISuperResolutionService abstraction.
- Scope: requires-source-edit
- Since: new

### AUDIT-20261104-024 — P2 — Co-change coupling between FfmpegService and VariationGenerator
- Category: quality
- Location: `lib/core/services/ffmpeg_service.dart:1`
- Evidence: E2 — Graph co-change query confirms coupling score of 1.0.
- Impact: FfmpegService and VariationGenerator exhibit tight 1.0 co-change coupling across pipeline revisions.
- Fix: Inject variation strategies into filter builder rather than hard-coupling generator to service.
- Scope: requires-source-edit
- Since: new

## Test Coverage Gaps
| Module | Test files | Coverage |
|--------|------------|----------|
| `core/models` | `test/history_service_test.dart` (model tests) | High (models covered in service tests) |
| `core/providers` | `uniquifier_provider_test.dart`, `batch_queue_provider_test.dart`, `locale_provider_test.dart` | Comprehensive (100% provider coverage) |
| `core/services` | `ffmpeg_service_test.dart`, `ai_super_resolution_test.dart`, `settings_service_test.dart`, etc. | Comprehensive (8 dedicated test files) |
| `core/theme` | `widget_test.dart` | Indirect (covered via widget smoke tests) |
| `features/process` | `processing_screen_test.dart`, `batch_processing_screen_test.dart`, `processing_stage_tracker_test.dart` | High (dedicated widget tests) |
| `features/settings` | `settings_screen_test.dart`, `setting_toggle_row_test.dart` | High (dedicated widget tests) |
| `features/dashboard` | `widget_test.dart` | Moderate (integrated into multi-resolution smoke tests) |
| `features/history` | `widget_test.dart`, `history_service_test.dart` | High |
| `features/microstock` | `microstock_news_and_translation_test.dart` | High |

## Documentation Drift
| Claim | Actual | Recommendation |
|-------|--------|----------------|
| `README.md:36` claims 118 passing tests | 173 tests pass in full test suite | Update README to state 173 passing tests |
| `README.md:33` claims export to `Movies/VideoUniquifier/` | Exports to `/storage/emulated/0/Movies/Uniquifier` | Synchronize path documentation |
| `docs/privacy_policy.md` claims "100% offline, zero network" | Declares INTERNET permission, Google Apps Script webhook, and RSS feeds | Scope offline guarantee to video processing core and disclose network features |
| `docs/play_store_metadata/release_notes_en_US.txt` says v1.0.0 | pubspec.yaml defines 2.0.0+72 | Update release notes version header |

## Prioritized Next Actions
1. **Fix CI Formatting Failure (P1)**: Run `dart format lib/ test/` to resolve the 89 unformatted files.
2. **Refactor Hardcoded Storage Paths (P1)**: Replace hardcoded `/storage/emulated/0/Movies/Uniquifier` in `ffmpeg_service.dart` and `history_service.dart` with dynamic `StorageDirectory.movies` lookups.
3. **Propagate Staging Exceptions (P1)**: Stop swallowing exceptions in `stageInputFile` inside `ffmpeg_service.dart:293`.
4. **Decouple SettingsService & UniquifierProvider (P1)**: Break up god-object dependencies and high fan-in call sites through modular state providers.
5. **Harmonize Documentation (P2/P3)**: Align README test counts, export directories, and privacy policy disclosures with actual implementation.
