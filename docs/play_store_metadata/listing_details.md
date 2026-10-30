# Google Play Store Listing & Metadata Specification

## 1. Core Listing Assets

### Application Title (Max 30 characters)
`NRA Video Uniquifier`

### Short Description (Max 80 characters)
`Offline video uniquifier, anti-fingerprint evasion, and 4K upscaler.`

### Full Description (Max 4000 characters)
```text
NRA Video Uniquifier is an offline, on-device utility designed for content creators, video editors, and digital marketers seeking total control over video fingerprinting, metadata, and visual uniqueness.

By leveraging a native FFmpeg engine, the app processes your media entirely on your device—zero video data ever leaves your phone or connects to third-party servers.

KEY CAPABILITIES:

1. COMPREHENSIVE ANTI-FINGERPRINT EVASION
- Metadata Scrubbing: Strips EXIF, encoder signatures, QuickTime tags, creation dates, and GPS coordinates.
- Spatial Perturbation: Subtle micro-cropping (0.95x - 0.98x) and sub-degree rotation (0.4°) with macroblock parity protection.
- Temporal Desync Evasion: Precision PTS timing offset (0.9852*PTS) with matching 1.015x audio tempo alignment to ensure zero lip-sync drift.
- Visual Enhancements: Vintage film curve mapping, subtle saturation/contrast EQ, spatial denoise (hqdn3d), unsharp masking, and perceptual grain injection.

2. ADVANCED AUDIO MASKING & SPECTROGRAM DESTRUCTION
- Sub-bass highpass (60Hz) and ultrasonic lowpass (16kHz) filtering.
- Surgical parametric EQ boosting (1.2kHz).
- Synthetic pink noise injection (-50 dBFS) to scramble automated audio fingerprint detection without distorting audible speech.

3. DYNAMIC 4K & ORIENTATION-AWARE UPSCALE
- Orientation Detection: Automatically recognizes true portrait (vertical 9:16) vs landscape (16:9) formats.
- Lanczos Scaling: High-fidelity interpolation to 1080p, 2K (1440p), or true 4K (2160x3840 portrait / 3840x2160 landscape).
- Render Diagnostic Inspection: Integrated FFprobe verification confirming output dimensions, bitrates, and encoding profiles.

4. BATCH PROCESSING & BACKGROUND RESILIENCE
- Multi-File Queue: Select and sequentially process multiple videos in a single batch.
- Foreground Service & Notifications: Live progress bar in Android notification center with battery-friendly wake-lock.
- Sound Alert: Audible chime upon render completion.

PRIVACY & DATA SAFETY:
- 100% Offline Processing: Does not collect, transmit, or monetize your media.
- No Accounts or Telemetry: No tracking SDKs, advertising IDs, or external network requests.

System Requirements:
- Android 7.0 or later (API 24+)
- 2GB RAM minimum; 4GB recommended for 4K processing
- ~200MB free storage per processed video

Compatibility Notes:
- Verified on Android emulator (API 28) with ARM64 native bridge
- Hardware-accelerated codec behavior may vary by chipset
- If hardware acceleration causes issues, disable it in Settings

Privacy:
- All processing happens on-device
- No analytics, no telemetry, no network access required
- Videos never leave your device unless you explicitly share them
```

## 2. Content Rating & Declarations
- **Category**: Video Players & Editors / Tools
- **Content Rating**: Everyone (PEGI 3, USK 0, ESRB Everyone)
- **Target Audience**: 13+
- **Ads**: No Ads
- **App Access**: All functionality available without restrictions
- **Data Safety**:
  - Data collected: None
  - Data shared: None
  - Security practices: All operations executed locally in app sandbox and public Movies directory

## 3. Production Release Keystore Instructions
To generate a production release keystore:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Copy `android/key.properties.example` to `android/key.properties` and fill in your passwords and file paths.

Build an Android App Bundle (AAB) for Play Console upload:
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`
