import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Lightweight real-time network connectivity monitor.
class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._internal();
  ConnectivityService._internal();

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);
  Timer? _pollingTimer;
  bool _initialized = false;

  /// Custom socket ping runner for test mocking.
  @visibleForTesting
  static Future<bool> Function()? mockPingHandler;

  /// Starts monitoring network connectivity.
  void initialize({Duration interval = const Duration(seconds: 10)}) {
    if (_initialized) return;
    _initialized = true;
    checkConnectivity();
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      // In test environment, skip periodic timer to allow clean pumpAndSettle
      return;
    }
    _pollingTimer = Timer.periodic(interval, (_) => checkConnectivity());
  }

  /// One-shot network check.
  Future<bool> checkConnectivity() async {
    if (mockPingHandler != null) {
      final online = await mockPingHandler!();
      if (isOnline.value != online) {
        isOnline.value = online;
      }
      return online;
    }

    bool online = false;
    try {
      final result = await InternetAddress.lookup('dns.google')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        online = true;
      }
    } catch (_) {
      online = false;
    }

    if (isOnline.value != online) {
      isOnline.value = online;
    }
    return online;
  }

  /// Sets connectivity state directly (useful for tests and manual toggles).
  void setOnlineForTesting(bool value) {
    isOnline.value = value;
  }

  /// Disposes polling timer.
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _initialized = false;
  }
}
