# Out-of-Scope Drift — Report 02

## Registered Items

### 1. Stale Test Suite Count in README
- Path: `README.md:36`
- Claim: "118 unit and widget smoke tests passing (0 failures, 0 warnings)"
- Actual: 173 tests passing in full test suite (`flutter test` passes 173/173).
- Recommendation: Update test claim to 173 passing tests.
- Date: 2026-11-04

### 2. Dead Links to Deleted Sprint Reports Directory
- Path: `README.md:128`
- Claim: Links to `0ai_context/reports/REPORTS_INDEX.md` and `60-project-cleanup-and-report-archival.md`.
- Actual: Historical sprint reports were archived/removed in commit `82a164f`.
- Recommendation: Update Documentation Index to point to active files (`SEED.md`, `STATE.md`, `CHANGELOG-map.md`).
- Date: 2026-11-04

### 3. Public Export Folder Mismatch in README
- Path: `README.md:33`
- Claim: "safe atomic export to public Movies/VideoUniquifier/ via MediaScannerService"
- Actual: Code exports to `/storage/emulated/0/Movies/Uniquifier` (`ffmpeg_service.dart:149`).
- Recommendation: Align documentation to `Movies/Uniquifier/`.
- Date: 2026-11-04

### 4. Stale Webhook Script Filename Reference
- Path: `webhook/README_SHEETS_WEBHOOK.md:11`
- Claim: "replace it with the code from google_sheets_webhook.js"
- Actual: File in repository is `webhook/code.gs`.
- Recommendation: Update guide reference to `webhook/code.gs`.
- Date: 2026-11-04

### 5. Outdated Icon Generation Guide Instructions
- Path: `docs/icon_generation_guide.md:46`
- Claim: Instructs adding `flutter_launcher_icons` and specifies `icon_1024.png` and `ic_launcher.png`.
- Actual: `pubspec.yaml` already configures `flutter_launcher_icons` using `assets/icon-128.png` and outputting `launcher_icon.png`.
- Recommendation: Update guide to reflect current `pubspec.yaml` settings.
- Date: 2026-11-04

### 6. Keystore Specification Drift in Store Listing Docs
- Path: `docs/play_store_metadata/listing_details.md:78`
- Claim: Instructs creating `android/app/upload-keystore.jks` with alias `upload`.
- Actual: Repository provisions `android/release-keystore.jks` with alias `nra-release`.
- Recommendation: Update docs to reference `android/release-keystore.jks`.
- Date: 2026-11-04

### 7. Play Store Release Notes Version Drift
- Path: `docs/play_store_metadata/release_notes_en_US.txt:1`
- Claim: `v1.0.0 — Initial Release`
- Actual: `pubspec.yaml` defines `version: 2.0.0+72`.
- Recommendation: Update title to `v2.0.0 (Build 72) — Production Release`.
- Date: 2026-11-04

### 8. Offline Claim Conflict with Network Telemetry & RSS Endpoints
- Path: `README.md:9`, `docs/privacy_policy.md:10`, `docs/play_store_metadata/listing_details.md:41`
- Claim: "Zero Network Transmission: 100% on-device processing isolate with zero external telemetry or cloud upload"
- Actual: Video rendering is 100% offline, but `UserInterestService` dispatches telemetry to Google Apps Script webhook and `MicrostockNewsService` fetches RSS feeds.
- Recommendation: Scope offline guarantee specifically to video media processing and disclose telemetry/RSS features under Data Safety.
- Date: 2026-11-04

### 9. Privacy Policy Omits Declared Android Permissions
- Path: `docs/privacy_policy.md:24`
- Claim: Permissions list only Storage, Notifications, Foreground service.
- Actual: `AndroidManifest.xml` also declares `INTERNET`, `ACCESS_NETWORK_STATE`, and `MANAGE_EXTERNAL_STORAGE`.
- Recommendation: Disclose network permissions and Scoped Storage details in policy documentation.
- Date: 2026-11-04
