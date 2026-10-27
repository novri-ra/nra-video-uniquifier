# NRA Video Uniquifier

Cross-platform offline video processing tool built with Flutter and FFmpegKit. Modifies metadata, audio pitch, subtle visual scaling/crops, and handles Lanczos upscaling on-device without network transmission.

## Features
- **Zero Network Transmission**: 100% on-device processing isolate.
- **Audio Tuning**: Subtle pitch and frequency shifting to prevent hash matching.
- **Visual Modification**: Micro-crop border and color space tuning.
- **Resolution Upscale**: Lanczos algorithm scaling for 720p, 1080p, and 2K output.
- **Clean Architecture**: 100% compliant with strict line budgets (all modules <= 400 LOC, functions <= 40 LOC).
- **Test Coverage**: 27 unit and smoke tests covering FFmpeg commands, Provider state, and History filesystem IO.

## Getting Started

```bash
# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run test suite
flutter test

# Run application
flutter run
```

## Documentation
- Architecture blueprint: `0ai_context/SEED.md`
- Real-time project roadmap: `0ai_context/STATE.md`
- Task reports: `0ai_context/reports/`
