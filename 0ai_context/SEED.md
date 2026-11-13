# Project Seed — nra_video_uniquifier
## 1. Overview
High-performance Flutter video uniquifier and anti-fingerprint suite with advanced FFmpeg integration, a software-locked H.264 rendering pipeline, and robust privacy controls.

## 2. Stack & Versions
- Flutter 3.47.8 / Dart 3.13.7
- App Version: 1.0.5+5
- State Management: Provider / ValueNotifier
- Engine: Software H.264 (libx264) locked for 100% stability

## 6. Module Inventory
- Core Services: FfmpegService, StorageService, SettingsService, HistoryService, NotificationService, MicrostockNewsService, TranslationService, UserInterestService, ConnectivityService
- UI Features: Studio (ModifiersCard, Preview, ProcessingScreen), History, Profile, Settings

## 9. Constraints & Policies
- Strict privacy policy: no user video identifiers / absolute paths in log output (with ongoing basename policy review).
- English-only documentation and comments policy.
- Zero fatal analysis issues and 100% passing unit tests (229/229).
- Hardware Acceleration and H.265 are intentionally disabled to prevent Android 15+ MediaCodec hangs.
