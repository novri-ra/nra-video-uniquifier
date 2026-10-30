import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'settings_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static bool? _testOverride;
  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;
  @visibleForTesting
  static set initialized(bool value) => _initialized = value;
  static bool get _canRun => _testOverride ?? Platform.isAndroid;

  static const int progressNotificationId = 8801;
  static const int completeNotificationId = 8802;

  static const String processChannelId = 'video_process_channel';
  static const String completeChannelId = 'video_complete_channel';

  static int _lastProgressPercent = -1;
  static DateTime _lastProgressTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Initializes notification plugin and sets up platform notification channels.
  static Future<void> init() async {
    if (_initialized || !_canRun) return;
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings: initSettings);

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            processChannelId,
            'Video Processing',
            description: 'Ongoing video processing progress',
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
            showBadge: false,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            completeChannelId,
            'Video Processing Complete',
            description: 'Alerts when video processing finishes',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }
      _initialized = true;
    } catch (e) {
      debugPrint('[NotificationService] init error: $e');
    }
  }

  /// Requests notification permission on Android 13+ (POST_NOTIFICATIONS).
  static Future<bool> requestPermission() async {
    try {
      if (_canRun) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          final result = await Permission.notification.request();
          return result.isGranted;
        }
        return true;
      }
    } catch (_) {}
    return true;
  }

  /// Shows or updates ongoing progress notification with progress bar.
  static Future<void> showProgressNotification({
    required int progress,
    required String title,
    required String body,
    bool force = false,
  }) async {
    if (!_canRun) return;
    await init();

    final now = DateTime.now();
    final clamped = progress.clamp(0, 100);

    if (!force && clamped != 0 && clamped != 100) {
      final percentDiff = (clamped - _lastProgressPercent).abs();
      final timeDiff = now.difference(_lastProgressTime).inMilliseconds;
      if (percentDiff < 5 && timeDiff < 1000) {
        return;
      }
    }

    _lastProgressPercent = clamped;
    _lastProgressTime = now;

    final androidDetails = AndroidNotificationDetails(
      processChannelId,
      'Video Processing',
      channelDescription: 'Ongoing video processing progress',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: clamped,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
    );

    try {
      await _plugin.show(
        id: progressNotificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: androidDetails),
      );
    } catch (_) {}
  }

  /// Cancels ongoing progress notification.
  static Future<void> cancelProgressNotification() async {
    _lastProgressPercent = -1;
    _lastProgressTime = DateTime.fromMillisecondsSinceEpoch(0);
    if (!_canRun) return;
    try {
      await _plugin.cancel(id: progressNotificationId);
    } catch (_) {}
  }

  /// Shows high-priority completion notification with sound and vibration alert.
  static Future<void> showCompleteNotification({
    required String title,
    required String body,
    bool success = true,
  }) async {
    if (!_canRun) return;
    await init();
    await cancelProgressNotification();

    bool playSound = true;
    try {
      playSound = await SettingsService.getNotificationSound();
    } catch (_) {}

    final androidDetails = AndroidNotificationDetails(
      completeChannelId,
      'Video Processing Complete',
      channelDescription: 'Alerts when video processing finishes',
      importance: Importance.high,
      priority: Priority.high,
      playSound: playSound,
      enableVibration: true,
      autoCancel: true,
    );

    try {
      await _plugin.show(
        id: completeNotificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: androidDetails),
      );
    } catch (_) {}
  }
}
