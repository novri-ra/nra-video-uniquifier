# Out-of-Scope Drift — Report 87

Items observed during the 2026-11-08 mapping run that live outside the mapper's write scope (`0ai_context/**`). None were fixed.

## Registered Items

### 1. README claims zero network, code performs HTTP
- Path: `README.md:7`
- Claim: "**Zero Network Transmission**: 100% on-device processing isolate with zero external telemetry or cloud upload."
- Actual: `lib/core/services/microstock_news_service.dart:229-230` issues HTTP GET requests to `https://petapixel.com/feed/` and `https://fstoppers.com/feed`. The video pipeline itself never uses the network, but the app as a whole does.
- Recommendation: change the bullet to "Zero network transmission for video processing" and add a line stating the Microstock news reader fetches public RSS feeds.
- Date: 2026-11-08

### 2. pubspec description is still the Flutter template placeholder
- Path: `pubspec.yaml:2`
- Claim: `description: "A new Flutter project."`
- Actual: a shipped v1.0.5 application with a documented feature set in README.
- Recommendation: `description: "Offline video uniquifier: on-device FFmpeg anti-fingerprint processing, visual effect catalog, and 1080p/2K/4K upscaling."`
- Date: 2026-11-08

### 3. CHANGELOG still carries an Unreleased block after the v1.0.5 bump
- Path: `CHANGELOG.md:3`
- Claim: `## [Unreleased]` section holds the TikTok evasion hardening and foreground-service entries.
- Actual: HEAD commit `6278087` is `chore(release): bump version to v1.0.5`, so those entries shipped.
- Recommendation: rename the block to `## [1.0.5] - 2026-11-08` and open a new empty `[Unreleased]`.
- Date: 2026-11-08

### 4. Six working-tree changes are uncommitted at HEAD
- Path: `OpenCode-Bootstrap-Prompt.txt` (deleted), `lib/core/services/ffmpeg/ffmpeg_command_builder.dart`, `lib/features/process/widgets/modifiers_card.dart`, `macos/Flutter/GeneratedPluginRegistrant.swift`, `windows/flutter/generated_plugin_registrant.cc`, `windows/flutter/generated_plugins.cmake`
- Claim: HEAD `6278087` represents the repository state.
- Actual: the working tree carries an in-progress command-builder extraction plus regenerated platform registrants.
- Recommendation: commit the command-builder work separately from the generated platform files, then regenerate registrants in their own commit.
- Date: 2026-11-08

### 5. Report 37 filename violates the naming rule
- Path: `0ai_context/reports/37-release-v1.0.4-universal-compatibility-and-effect-catalog.md`
- Claim: the numbering rule requires `NN-<kebab-slug>.md` with no dots.
- Actual: the slug contains `v1.0.4`, so the filename carries dots. It is committed (331f9b2) and linked from `reports/INDEX.md:41`.
- Recommendation: leave the historical file untouched; apply the rule to new reports only.
- Date: 2026-11-08

### 6. Mapper-side formatting write to a source file
- Path: `lib/features/process/widgets/modifiers_card.dart:1`
- Claim: the mapper writes only inside `0ai_context/**`.
- Actual: the Phase 2 format probe (`dart format --set-exit-if-changed .`) rewrites files before reporting its exit code. Six files that were clean at run start were restored with `git checkout --`. `modifiers_card.dart` already had uncommitted user edits, so restoring it would have destroyed that work; it therefore keeps the formatter's rewrapping (whitespace-only change on top of the user's edits).
- Recommendation: run the format probe as `dart format --output=none --set-exit-if-changed .` in future runs, which reports without writing.
- Date: 2026-11-08
