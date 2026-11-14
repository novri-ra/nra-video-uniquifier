import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'settings_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static bool? _testOverride;
  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;
  @visibleForTesting
  static set initialized(bool value) => _initialized = value;
  static bool get _canRun => _testOverride ?? Platform.isAndroid;

  static const int progressNotificationId = 101;
  static const int completeNotificationId = 8802;
  static const int testNotificationId = 7777;

  static const String mainChannelId = 'nra_uniquifier_channel_v2';
  static const String processChannelId = 'nra_progress_silent_channel';
  static const String legacyProcessChannelId = 'nra_video_processing_channel';
  static const String completeChannelId = 'nra_complete_alert_channel';

  static int _lastProgressPercent = -1;
  static DateTime _lastProgressTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Explicit initialization entry point required on application bootstrap.
  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    await init();
    if (_canRun && _testOverride != true) {
      await _registerSystemChannelPing();
    }
  }

  /// Forces Android OS to register the channel in system settings.
  static Future<void> _registerSystemChannelPing() async {
    const details = AndroidNotificationDetails(
      processChannelId,
      'Video Processing',
      channelDescription: 'Video processing status and completion',
      importance: Importance.low,
      priority: Priority.low,
      icon: 'ic_notification',
      ticker: 'NRA Video Uniquifier',
      playSound: false,
      enableVibration: false,
      ongoing: false,
      autoCancel: true,
    );
    await _safeShow(
      id: 999,
      title: 'NRA Video Uniquifier',
      body: 'NRA Video Uniquifier siap',
      androidDetails: details,
    );
    try {
      await _plugin.cancel(id: 999);
    } catch (e) {
      debugPrint('[NotificationService] cancel ping failed: $e');
    }
  }

  /// Registers official notification channels with Android OS.
  static Future<void> _createNotificationChannels(
    AndroidFlutterLocalNotificationsPlugin plugin,
  ) async {
    // 1. Progress channel (silent, no popup)
    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        processChannelId,
        'Video Processing Progress',
        description: 'Menampilkan progres rendering tanpa suara',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );

    // 2. Complete channel (alerting, popup)
    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        completeChannelId,
        'Video Processing Complete',
        description: 'Pemberitahuan saat video selesai diproses',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Legacy channel (retained for backward compatibility)
    await plugin.createNotificationChannel(
      const AndroidNotificationChannel(
        mainChannelId,
        'NRA Uniquifier Processing',
        description: 'Notifikasi status proses video dan ekspor aset',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  static Future<bool> _tryInitialize(String icon) async {
    try {
      final settings = InitializationSettings(
        android: AndroidInitializationSettings(icon),
      );
      await _plugin.initialize(settings: settings);
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await _createNotificationChannels(androidPlugin);
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] _tryInitialize failed: $e');
      return false;
    }
  }

  /// Initializes notification plugin and sets up platform notification channels.
  @pragma('vm:entry-point')
  static Future<void> init() async {
    if (_initialized || !_canRun) return;
    const candidates = [
      'ic_notification',
      '@mipmap/ic_launcher',
      '@drawable/ic_notification',
      'ic_launcher',
      'notification_icon',
    ];
    for (final icon in candidates) {
      if (await _tryInitialize(icon)) {
        _initialized = true;
        return;
      }
    }
  }

  static Future<void> _ensurePermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('[NotificationService] permission request failed: $e');
    }
  }

  /// Requests notification permission on Android 13+ (POST_NOTIFICATIONS).
  @pragma('vm:entry-point')
  static Future<bool> requestPermission() async {
    try {
      if (_canRun) {
        await _ensurePermission();
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          final result = await Permission.notification.request();
          return result.isGranted;
        }
        return true;
      }
    } catch (e) {
      debugPrint('[NotificationService] requestPermission failed: $e');
    }
    return true;
  }

  /// Explicit runtime permission validation alias for render pipelines.
  @pragma('vm:entry-point')
  static Future<bool> requestNotificationsPermission() => requestPermission();

  static AndroidNotificationDetails _buildProgressDetails({
    required int progress,
    required int maxProgress,
  }) {
    return AndroidNotificationDetails(
      processChannelId,
      'Video Processing Progress',
      channelDescription: 'Menampilkan progres rendering tanpa suara',
      importance: Importance.low, // <-- Ubah ke LOW
      priority: Priority.low, // <-- Ubah ke LOW
      playSound: false, // <-- MATIKAN SUARA
      enableVibration: false, // <-- MATIKAN GETARAN
      icon: 'ic_notification',
      ticker: 'NRA Video Uniquifier',
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
    );
  }

  static Future<void> _safeShow({
    required int id,
    required String title,
    required String body,
    required AndroidNotificationDetails androidDetails,
  }) async {
    if (_canRun && _testOverride != true) {
      await _ensurePermission();
    }
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] show notification failed, trying fallback: $e',
      );
      try {
        final fallback = AndroidNotificationDetails(
          androidDetails.channelId,
          androidDetails.channelName,
          channelDescription: androidDetails.channelDescription,
          importance: androidDetails.importance,
          priority: androidDetails.priority,
          icon: 'ic_notification',
          ticker: 'NRA Video Uniquifier',
          playSound: androidDetails.playSound,
          enableVibration: androidDetails.enableVibration,
          autoCancel: androidDetails.autoCancel,
          ongoing: androidDetails.ongoing,
          showProgress: androidDetails.showProgress,
          maxProgress: androidDetails.maxProgress,
          progress: androidDetails.progress,
          onlyAlertOnce: androidDetails.onlyAlertOnce,
        );
        await _plugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(android: fallback),
        );
      } catch (e) {
        debugPrint('[NotificationService] show fallback failed: $e');
      }
    }
  }

  /// Shows or updates ongoing progress notification with progress bar.
  @pragma('vm:entry-point')
  static Future<void> showProgressNotification({
    int id = progressNotificationId,
    required int progress,
    required String title,
    required String body,
    int maxProgress = 100,
    bool force = false,
  }) async {
    if (!_canRun) return;
    await init();

    final now = DateTime.now();
    final clamped = progress.clamp(0, maxProgress);

    if (!force && clamped != 0 && clamped != maxProgress) {
      final percentDiff = (clamped - _lastProgressPercent).abs();
      final timeDiff = now.difference(_lastProgressTime).inMilliseconds;
      if (percentDiff < 2 && timeDiff < 1000) return;
    }

    _lastProgressPercent = clamped;
    _lastProgressTime = now;

    final androidDetails = _buildProgressDetails(
      progress: clamped,
      maxProgress: maxProgress,
    );
    await _safeShow(
      id: id,
      title: title,
      body: body,
      androidDetails: androidDetails,
    );
  }

  /// Cancels ongoing progress notification.
  @pragma('vm:entry-point')
  static Future<void> cancelProgressNotification([
    int id = progressNotificationId,
  ]) async {
    _lastProgressPercent = -1;
    _lastProgressTime = DateTime.fromMillisecondsSinceEpoch(0);
    if (!_canRun) return;
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('[NotificationService] cancel progress failed: $e');
    }
  }

  /// Shows high-priority completion notification with sound and vibration alert.
  @pragma('vm:entry-point')
  static Future<void> showCompleteNotification({
    int? id,
    required String title,
    required String body,
    bool success = true,
  }) async {
    if (!_canRun) return;
    await init();
    final cancelTargetId = id == null || id == completeNotificationId
        ? progressNotificationId
        : id;
    await cancelProgressNotification(cancelTargetId);

    final androidPlatform = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlatform?.createNotificationChannel(
      const AndroidNotificationChannel(
        completeChannelId, // <-- UBAH INI
        'Video Processing Complete', // <-- UBAH INI
        description:
            'Pemberitahuan saat video selesai diproses', // <-- UBAH INI
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    bool playSound = true;
    try {
      playSound = await SettingsService.getNotificationSound();
    } catch (e) {
      debugPrint('[NotificationService] sound setting read failed: $e');
    }

    final notificationId =
        id ??
        (DateTime.now().millisecond == 0 ? 1 : DateTime.now().millisecond);

    final androidDetails = AndroidNotificationDetails(
      completeChannelId, // <-- UBAH INI
      'Video Processing Complete', // <-- UBAH INI
      channelDescription:
          'Pemberitahuan saat video selesai diproses', // <-- UBAH INI
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      playSound: playSound,
      enableVibration: true,
      ticker: 'NRA Video Uniquifier',
      autoCancel: true,
      ongoing: false,
    );

    await _safeShow(
      id: notificationId,
      title: title,
      body: body,
      androidDetails: androidDetails,
    );
  }

  /// Alias for showCompleteNotification matching prompt convention.
  @pragma('vm:entry-point')
  static Future<void> showCompletionNotification({
    int? id,
    required String title,
    required String body,
    bool success = true,
  }) => showCompleteNotification(
    id: id,
    title: title,
    body: body,
    success: success,
  );

  /// Instant test notification trigger for diagnostics and verification.
  @pragma('vm:entry-point')
  static Future<void> showTestNotification({
    int? id,
    String title = 'NRA Video Uniquifier Test',
    String body = 'Sistem notifikasi dan channel Android aktif sempurna!',
  }) async {
    if (!_canRun) return;
    await init();

    final androidPlatform = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlatform?.createNotificationChannel(
      const AndroidNotificationChannel(
        completeChannelId, // <-- UBAH INI (sebelumnya 'video_processing_channel')
        'Video Processing Complete', // <-- UBAH INI
        description:
            'Pemberitahuan saat video selesai diproses', // <-- UBAH INI
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    final notificationId =
        id ??
        (DateTime.now().millisecond == 0 ? 1 : DateTime.now().millisecond);

    final androidDetails = AndroidNotificationDetails(
      completeChannelId, // <-- UBAH INI (sebelumnya 'video_processing_channel')
      'Video Processing Complete', // <-- UBAH INI
      channelDescription:
          'Pemberitahuan saat video selesai diproses', // <-- UBAH INI
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      playSound: true,
      enableVibration: true,
      ticker: 'NRA Video Uniquifier',
      autoCancel: true,
    );

    await _safeShow(
      id: notificationId,
      title: title,
      body: body,
      androidDetails: androidDetails,
    );
  }

  /// Alias for showTestNotification matching prompt convention.
  @pragma('vm:entry-point')
  static Future<void> sendTestNotification({
    int? id,
    String title = 'NRA Video Uniquifier Test',
    String body = 'Sistem notifikasi dan channel Android aktif sempurna!',
  }) => showTestNotification(id: id, title: title, body: body);
}
