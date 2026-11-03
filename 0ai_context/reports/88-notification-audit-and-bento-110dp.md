# Sprint 88 Technical Report: Notification System Tray Audit & 110dp Bento Visuals

## 1. Executive Summary
Sprint 88 conducts a forensic native audit of notification delivery drops on Android 13+ (API 33+), implements platform runtime permission validation and channel ID migration (`nra_uniquifier_channel_v2`), scales Bento metric card center visuals and gauges to 110dp with preserved typography and no clipping, optimizes grid aspect ratio for small viewports (320x480), and verifies all architectural constraints (files in `lib/` $\le 400$ LOC, functions $\le 40$ lines, 0 analyzer issues, 170/170 tests passing).

---

## 2. Forensic native Root Cause Analysis
- **Dumpsys Inspection**:
  - `adb shell dumpsys package id.novrira.videouniquifier`: `android.permission.POST_NOTIFICATIONS` was declared in the manifest, but not yet explicitly granted in runtime permissions on modern Android versions.
  - `adb shell dumpsys notification --noredact`: Notifications dispatched to Android `NotificationManagerService` on prior channel ID (`nra_uniquifier_channel`) were dropped without system tray presentation due to ungranted runtime POST_NOTIFICATIONS status and stale channel state.
- **Root Cause**:
  - Starting with Android 13 (Tiramisu / API 33), notifications cannot appear in the notification drawer without explicit user consent via runtime dialog (`POST_NOTIFICATIONS`). Dispatches without prior permission verification silently fail.
- **Resolution**:
  - Migrated notification channel to `nra_uniquifier_channel_v2` with `Importance.max` and `Priority.high`.
  - Registered channel in `MainActivity.kt` via native `NotificationChannel` with `NotificationManager.IMPORTANCE_HIGH`.
  - Added proactive permission checks in `NotificationService._ensurePermission()` and `requestPermission()` using `AndroidFlutterLocalNotificationsPlugin.areNotificationsEnabled()` and `requestNotificationsPermission()`.

---

## 3. Remediation & Implementation Details
- **`lib/core/services/notification_service.dart`** (283 LOC, $\le 400$):
  - Updated channel identifiers:
    ```dart
    static const String mainChannelId = 'nra_uniquifier_channel_v2';
    static const String completeChannelId = 'nra_uniquifier_channel_v2';
    ```
  - Added `_ensurePermission()` to check `areNotificationsEnabled()` and prompt `requestNotificationsPermission()` prior to `_safeShow()` and in `requestPermission()`.
- **`android/app/src/main/kotlin/id/novrira/videouniquifier/MainActivity.kt`**:
  - Registered `nra_uniquifier_channel_v2` with `NotificationManager.IMPORTANCE_HIGH` and vibration enabled on app launch.
- **`lib/features/dashboard/widgets/bento_cards.dart`** (381 LOC, $\le 400$):
  - Scaled `_BentoGaugeRing` container to `110.0dp x 110.0dp`.
  - Configured `strokeWidth: 4.5` on `CircularProgressIndicator` wrapped in `SizedBox.expand`.
  - Maintained text styling with `fontSize: 16.5`, `FontWeight.w900`, `FittedBox(fit: BoxFit.scaleDown)`, and `padding: EdgeInsets.symmetric(horizontal: 12)` ensuring ample clearance from gauge strokes.
- **`lib/features/dashboard/widgets/bento_engine_card.dart`** (185 LOC, $\le 400$):
  - Scaled equalizer wave bars: heights 24dp to 52dp (`_WaveBar(height: 24, 40, 52, 34, 46)`), bar width 8dp.
  - Adjusted visual container height to 54dp; extracted `_cardDecoration` to keep `build` $\le 40$ lines.
- **`lib/features/dashboard/widgets/bento_metric_grid.dart`** (280 LOC, $\le 400$):
  - Scaled `_BentoQueueCard` container to `110dp x 46dp`, icon size 22, text font size 20.
  - Tuned `childAspectRatio: 0.71` to guarantee zero RenderFlex overflow across narrow viewports down to 320x480.
- **`test/notification_service_test.dart`**:
  - Added explicit test expectations asserting `NotificationService.mainChannelId == 'nra_uniquifier_channel_v2'` and `completeChannelId == 'nra_uniquifier_channel_v2'`.

---

## 4. Quality Gates Verification

| Quality Gate | Requirement | Measured Result | Verdict |
|---|---|---|---|
| Hand-written `lib/` files | $\le 400$ LOC | `notification_service.dart`: 283 LOC<br>`bento_cards.dart`: 381 LOC<br>`bento_engine_card.dart`: 185 LOC<br>`bento_metric_grid.dart`: 280 LOC | PASS |
| Function Length | $\le 40$ lines | All functions $\le 40$ lines | PASS |
| Static Analysis | 0 issues (`--fatal-infos`) | `flutter analyze --fatal-infos` (0 issues) | PASS |
| Unit & Smoke Tests | 100% passing | `flutter test` (170/170 tests passed) | PASS |
| Small Viewport (320x480) | Zero RenderFlex overflow | Multi-resolution responsive smoke test passed | PASS |
| Knowledge Graph | Ready & synchronized | `tools["codebase-memory-mcp"].index_status` ready | PASS |

---

## 5. MCP Evidence Appendix
- **E1**: `index_status()`: 2861 nodes, 7456 edges, status `ready`.
- **E2**: Dumpsys forensics: verified absence of granted `POST_NOTIFICATIONS` runtime status, resolving system tray suppression.
