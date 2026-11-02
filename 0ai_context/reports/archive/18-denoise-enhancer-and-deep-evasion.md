# 18-denoise-enhancer-and-deep-evasion: Modular Video Enhancement (Denoise & Unsharp) and Multi-Layer Evasion Pipeline

## Executive Summary
This session implemented modular video enhancement filters (`hqdn3d` and `unsharp`), expanded anti-fingerprint evasion capabilities (5% deep margin crop, 0.4° spatial rotation tilt, enhanced highpass/lowpass/equalizer audio spectrum), and upgraded video encoding quality to `-crf 19 -b:v 8M` to eliminate TikTok "low quality" flags while maintaining smooth playback. All state toggles (`enableEnhanceAndDenoise`, `enableDeepAntiFingerprint`) were exposed in `SettingsService` and `UniquifierProvider`, bound reactively in `ModifiersCard` without breaking layout or line budgets.

---

## 1. Modular Filter Integration in `FfmpegService`
- **Denoise & Clarity**:
  - High-Quality Denoise: `hqdn3d=1.5:1.5:4:4` (tuned for low CPU overhead and noise suppression on mobile devices).
  - Sharpening Mask: `unsharp=3:3:0.6:3:3:0.0` (preserves fine edge details and clarity).
- **Advanced Evasion Options**:
  - Deep Margin Crop (5%): `crop=trunc(iw*0.95/2)*2:trunc(ih*0.95/2)*2` (macroblock-even parity).
  - Subtle Spatial Tilt (0.4°): `rotate=0.4*PI/180:ow=rotw(0.4*PI/180):oh=roth(0.4*PI/180):fillcolor=black`.
  - Enhanced Audio Spectrum: `highpass=f=60,lowpass=f=16000,equalizer=f=1200:t=q:w=1:g=1` (strips sub-bass rumble, ultrasonic signatures, and adjusts resonant mids).
  - Encoding Bitrate & Quality: Upgraded from `-crf 22` to `-crf 19 -b:v 8M -g 60 -keyint_min 30` to prevent compression artifacts and platform quality downranking.

---

## 2. Filtergraph Execution Safety & Sequential Ordering
Verified strict filtergraph pipeline order in `FfmpegService.buildCommand()`:
```
1. Temporal (PTS):                 setpts=0.9852*PTS
2. Spatial (Crop -> Rotate):       crop=trunc(iw*0.95/2)*2:trunc(ih*0.95/2)*2,rotate=0.4*PI/180...
3. Resolution Scaling (Lanczos):   scale=w=-2:h=TARGET_HEIGHT:flags=lanczos
4. Enhancements (Denoise/Unsharp): hqdn3d=1.5:1.5:4:4,unsharp=3:3:0.6:3:3:0.0,eq=...
5. Grain Injection (Noise):        noise=alls=2:allf=t+u
```
- Crop precedes rotation to avoid edge artifact shearing.
- Resolution scaling precedes enhancement filters to prevent high-frequency detail loss.
- High-fidelity Lanczos scaling enforces macroblock-even width (`w=-2`).
- Zero syntax collisions across all toggle permutations.

---

## 3. State Management & Settings Synchronization
- **`SettingsService` (`lib/core/services/settings_service.dart`)**:
  - Added keys: `app_enhance_denoise` and `app_deep_anti_fingerprint`.
  - Added getters and setters with `SharedPreferences` persistence:
    - `getEnhanceAndDenoise()`, `setEnhanceAndDenoise()` (defaults to `true`).
    - `getDeepAntiFingerprint()`, `setDeepAntiFingerprint()` (defaults to `true`).
- **`UniquifierProvider` (`lib/core/providers/uniquifier_provider.dart`)**:
  - Exposed boolean state: `enableEnhanceAndDenoise` and `enableDeepAntiFingerprint`.
  - Added toggle methods: `toggleEnhanceAndDenoise()`, `toggleDeepAntiFingerprint()`.
  - Integrated into `_initResolution()` with guarded async bootstrap (`try ... catch (_)`) for safe test isolation.
  - Added support in `applyPreset()` for comprehensive preset updates.
- **`ModifiersCard` (`lib/features/process/widgets/modifiers_card.dart`)**:
  - Updated header counter: `6 MODIFIERS`.
  - Added reactive toggle rows:
    - `Denoise & Clarity`: `HQ denoise & unsharp mask` (icon: `Icons.auto_fix_high`).
    - `Deep Evasion`: `5% margin crop & 0.4° tilt` (icon: `Icons.security`).

---

## 4. Verification & Testing
- **Static Analysis (`flutter analyze`)**:
  - Output: `No issues found! (ran in 3.3s)` (0 warnings, 0 errors).
- **Automated Test Suite (`flutter test`)**:
  - Total suites: 7 suites, **53 passing tests** (0 failures).
  - New test coverage:
    - `test/ffmpeg_service_test.dart`: Validated enhanced audio spectrum, fallback audio EQ, strict sequential filter ordering (PTS -> Crop -> Rotate -> Scale -> Denoise -> Unsharp -> EQ -> Noise), 8M bitrate flag, and deep evasion disablement.
    - `test/uniquifier_provider_test.dart`: Validated default toggles, toggle persistence, and notification dispatch.
    - `test/settings_service_test.dart`: Validated SharedPreferences persistence for both flags.
    - `test/widget_test.dart`: Validated ModifiersCard renders new toggle labels cleanly.

---

## 5. Line Budget Audit (Strict <= 400 LOC)
All touched files remain well within the line budget:
- `lib/core/providers/uniquifier_provider.dart`: 335 LOC (Target <= 400)
- `lib/core/services/ffmpeg_service.dart`: 308 LOC (Target <= 400)
- `lib/features/process/screens/processing_screen.dart`: 314 LOC (Target <= 400)
- `lib/features/process/widgets/modifiers_card.dart`: 224 LOC (Target <= 250)
- `lib/core/services/settings_service.dart`: 129 LOC (Target <= 250)

---

## 6. MCP Graph Delta & Commit
- **Baseline Graph**: 1042 nodes, 2473 edges
- **Updated Graph**: 1048 nodes, 2489 edges (Delta: +6 nodes, +16 edges)
- **Commit**: `feat(pipeline): modular denoise, clarity enhancer, and deep evasion filters`
