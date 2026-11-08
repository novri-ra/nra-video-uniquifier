# Milestone 39: Top Floating Capsule Toast & Native Notification Delivery Fix

**Status:** Completed  
**Date:** 2026-11-06  
**Type:** Fix / UI Polish / Native Android System Integration  

---

## 1. Executive Summary

Milestone 39 addresses two critical UX and platform integration issues:
1. **Top Floating Capsule Toast (UI Feedback):** Replaced bottom `SnackBar` instances (deletion feedback in `RecentHistoryScreen`, diagnostic alert in `SettingsScreen`, etc.) with a centralized `AppToast` capsule anchored dynamically to the top of the viewport (`bottom: MediaQuery.of(context).size.height - 130`). This prevents toasts from obstructing the Android gesture navigation bar and back/home gestures.
2. **Native Notification Delivery & Icon Alignment:** Verified `ic_notification.png` as valid PNG assets across all 6 Android drawable density buckets (`drawable/`, `drawable-mdpi/`, `drawable-hdpi/`, `drawable-xhdpi/`, `drawable-xxhdpi/`, and `drawable-xxxhdpi/`). Enforced explicit pre-creation of `video_processing_channel` (Importance HIGH, Priority HIGH, sound & vibration enabled, badge enabled) via `AndroidFlutterLocalNotificationsPlugin` immediately prior to posting notifications. Switched notification icon references to pure name `'ic_notification'` and dynamic unique IDs (`DateTime.now().millisecond`).

---

## 2. Technical Implementation Details

### A. Centralized Top Floating Toast (`AppToast`)
Created `lib/shared/widgets/app_toast.dart`:
- Uses `SnackBarBehavior.floating` with dynamic top placement: `bottom: (MediaQuery.of(context).size.height - 130.0).clamp(0.0, double.infinity)`.
- Features dark capsule theme (`Color(0xFF161B22)` background, `12dp` rounded corners).
- Supports distinct semantic styling:
  * **Deletion/Error:** Red accent border and icon (`Color(0xFFEF4444)`, `Icons.delete_outline`).
  * **Success/Diagnostics:** Emerald green accent border and icon (`Color(0xFF10B981)`, `Icons.notifications_active_outlined`).
- Integrated into:
  * `lib/features/history/screens/recent_history_screen.dart` ("Video permanently deleted from device", batch deletion, file opening, and sharing errors).
  * `lib/features/settings/screens/settings_screen.dart` ("Test notification sent to system tray", cache purge feedback).
  * `lib/features/profile/screens/profile_placeholder_screen.dart` ("Test notification sent to system tray").

### B. Android Native Notification Delivery Overhaul
Updated `lib/core/services/notification_service.dart`:
- Verified native small icon `ic_notification.png` exists across:
  * `android/app/src/main/res/drawable/ic_notification.png` (2,221 bytes, valid PNG)
  * `android/app/src/main/res/drawable-mdpi/ic_notification.png` (466 bytes, valid PNG)
  * `android/app/src/main/res/drawable-hdpi/ic_notification.png` (809 bytes, valid PNG)
  * `android/app/src/main/res/drawable-xhdpi/ic_notification.png` (1,200 bytes, valid PNG)
  * `android/app/src/main/res/drawable-xxhdpi/ic_notification.png` (2,221 bytes, valid PNG)
  * `android/app/src/main/res/drawable-xxxhdpi/ic_notification.png` (3,441 bytes, valid PNG)
- Prioritized `'ic_notification'` as primary initialization candidate and icon name in `AndroidNotificationDetails`.
- Enforced explicit channel creation in `showCompleteNotification()` / `showCompletionNotification()` and `showTestNotification()` / `sendTestNotification()`:
  ```dart
  final androidPlatform = _plugin.resolvePlatformSpecificImplementation<
    AndroidFlutterLocalNotificationsPlugin
  >();

  await androidPlatform?.createNotificationChannel(
    const AndroidNotificationChannel(
      'video_processing_channel',
      'Video Processing',
      description: 'Video processing status and completion',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ),
  );
  ```
- Assigned unique notification IDs using `DateTime.now().millisecond` to prevent stale alerts from being suppressed.
- Configured `ticker: 'NRA Video Uniquifier'` for system status bar ticker display.

---

## 3. Quality Assurance & Verification

1. **Dart Code Formatting:**
   `dart format --set-exit-if-changed lib/ test/` -> Formatted 124 files (0 changed, 100% compliant).

2. **Static Analysis:**
   `flutter analyze` -> 0 issues found.

3. **Automated Test Suite:**
   `flutter test` -> 215 / 215 tests passed (100% pass rate). Added `test/app_toast_test.dart` covering floating behavior, styling, and color accents.

4. **Release Compilation & Hardware Deployment:**
   - Compiled release APK: `flutter build apk --release` (Built `app-release.apk`, 232.2MB).
   - Installed to physical Android device `5e599699`:
     ```
     adb -s 5e599699 install -r build/app/outputs/flutter-apk/app-release.apk
     Performing Streamed Install
     Success
     ```
   - Launched MainActivity on physical device.
   - Queried native notification system via `dumpsys notification`:
     ```
     NotificationChannel{mId='video_processing_channel', mName=Video Processing, mImportance=4, mVibrationEnabled=true, mShowBadge=true...}
     ```
     Confirmed `video_processing_channel` is active on device with `mImportance=4` (`IMPORTANCE_HIGH`).
