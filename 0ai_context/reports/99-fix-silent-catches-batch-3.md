# Fix Report 99 — Silent Catches, Batch 3 (AI super-resolution, device capability, media probe)

**Date:** 2026-11-08
**Type:** Manual Fix (silent-catch cluster, final core-services batch)
**Status:** Complete — all three files passed their gates, no rollback needed

## 1. Background and Premise Corrections

The scan listed three files with one empty catch each. All three line numbers were still exact:

| File | Scan line | Verified |
|------|-----------|----------|
| `ai_super_resolution_service.dart` | 68 | empty `catch (_) {}` inside `prepareModelAssets()` |
| `device_capability_service.dart` | 121 | empty `catch (_) {}` inside `DeviceCapabilityService.getSpecs()` |
| `ffmpeg/media_probe_helper.dart` | 28 | empty `catch (_) {}` inside `MediaProbeHelper.probeMediaMeta()` |

Two corrections:

1. **Enclosing method in the AI file.** The prompt's example suggested `isVulkanSupported()` /
   `_resolveAiPlan()`. There is no `_resolveAiPlan`; the literal empty catch at line 68 is in
   `prepareModelAssets()` (asset extraction via `rootBundle.load` + cache writes). The method was
   derived from the code, not from the example.
2. **Sibling handler found.** The scan reported "none", but `isVulkanSupported()` at line 78 carried
   `catch (_) { return false; }` — a silent handler on the same call path (`getEngineInfo` and
   `resolvePlan` both call it). Per the sibling-scan rule it was fixed as a fourth site. That is the
   only sibling in the three files; no `.catchError((_) {})` anywhere.

## 2. What Was Done

All four logs are type-only. Each handler wraps `MethodChannel.invokeMethod` (`PlatformException` /
`MissingPluginException`), `rootBundle.load` (the message quotes the asset key), a cache file write
(`FileSystemException` with an absolute path), or `FFprobeKit.getMediaInformation` (echoes the media
path). None of them can safely log `$e` under §14.

### 2.1 `lib/core/services/ai_super_resolution_service.dart` — 2 handlers

| Line (pre-fix) | Enclosing method | Log message |
|----------------|------------------|-------------|
| 68 | `prepareModelAssets` (literal empty) | `[AiSuperResolutionService] model asset prepare failed: ${e.runtimeType}` |
| 78 | `isVulkanSupported` (sibling `catch (_) { return false; }`) | `[AiSuperResolutionService] vulkan probe failed: ${e.runtimeType}` |

The file already had one pre-existing log at line 120 using the prefix `[AiSuperResolution]` (no
`Service` suffix). It was left untouched: it carries no path, hardware spec, or device identifier
(only Vulkan availability and model names), and renaming it is outside this batch's scope. The two
new logs follow the prompt's `[<ClassName>]` rule, so this file now has two prefixes — cosmetic only.

### 2.2 `lib/core/services/device_capability_service.dart` — 1 handler

| Line (pre-fix) | Enclosing method | Log message |
|----------------|------------------|-------------|
| 121 | `getSpecs` | `[DeviceCapabilityService] device specs probe failed: ${e.runtimeType}` |

The fallback path is unchanged: on a null result or a thrown error the method still assigns
`DeviceSpecs.defaultFallback()` and returns the cached instance. `DeviceTier` detection and
`getResolutionWarning` are untouched.

### 2.3 `lib/core/services/ffmpeg/media_probe_helper.dart` — 1 handler

| Line (pre-fix) | Enclosing method | Log message |
|----------------|------------------|-------------|
| 28 | `probeMediaMeta` | `[MediaProbeHelper] media probe failed: ${e.runtimeType}` |

One import line was added (`package:flutter/foundation.dart`) because this file previously imported
only `ffprobe_kit`. The zero-record return `(durationMs: 0, width: 0, height: 0)` is unchanged.

### 2.4 Not changed

- No `rethrow`; no new `try`/`catch`; no control-flow change.
- No new API surface: `isDegraded` / `lastErrors` scan = 0 matches across the three files.
- Return values unchanged: `prepareModelAssets` still returns the partial `outPaths` list,
  `isVulkanSupported` still `false`, `getSpecs` still the cached fallback, `probeMediaMeta` still the
  zero record. Public method signatures and test hooks (`testOverride`, `testSpecsOverride`,
  `_cachedSpecs`) untouched.

## 3. Privacy Scan

Pre-existing `debugPrint` / `print(` / `developer.log(` in these files: 1, in
`ai_super_resolution_service.dart` line 120. It interpolates nothing — no path, no hardware spec, no
device identifier — so nothing was narrowed. `device_capability_service.dart` and
`media_probe_helper.dart` had no pre-existing logs. The four new logs interpolate only the operation
label and `${e.runtimeType}`.

## 4. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Format (3 files) | `dart format --output=none --set-exit-if-changed <3 files>` | exit 0, `0 changed` |
| AI suite | `flutter test test/ai_super_resolution_test.dart` | exit 0, `All tests passed!` (6) |
| FFmpeg suite | `flutter test test/ffmpeg_service_test.dart` | exit 0, `All tests passed!` (38) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Silent-handler grep (3 files) | `catch (_) {}` / `catchError((_) {})` / `catch (_) { return` | 0 matches |
| New API surface | `isDegraded` / `lastErrors` scan | 0 matches |
| Diff scope | `git diff --name-only` | exactly the 3 whitelisted files |
| Diff shape | `git diff --stat` | 3 files, 22 insertions, 4 deletions |
| Deletions audit | `git diff -U0` removed lines | 4 catch headers only |

The new log actually fired during the AI suite:
`[AiSuperResolutionService] model asset prepare failed: MissingPluginException` — the handler is now
traceable, and the message carries no path.

## 5. Note for the Next Mapper Run

All `core/services/` empty catches are now gone. Remaining work: `locale_provider.dart` (`-016`) plus
~10 single-catch files outside core services, then the `dart format` gate cleanup for the 7
baseline-unformatted files (`ffmpeg_service.dart`, `filter_builders.dart`,
`notification_service.dart`, `variation_generator.dart`, `modifiers_card.dart`, and the two test
files).

Follow-up worth registering (P3, cosmetic): `ai_super_resolution_service.dart` now logs under both
`[AiSuperResolution]` and `[AiSuperResolutionService]`; aligning the old line is a one-word edit in
its own prompt.
