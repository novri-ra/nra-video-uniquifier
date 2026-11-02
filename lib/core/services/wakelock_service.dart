import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WakeLockService {
  static const MethodChannel _channel = MethodChannel('id.novrira.videouniquifier/wakelock');
  static bool? _testOverride;
  static bool _simulatedHeld = false;

  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;

  static bool get _canRun => _testOverride ?? Platform.isAndroid;

  static Future<bool> acquire() async {
    if (!_canRun) {
      _simulatedHeld = true;
      return true;
    }
    try {
      final res = await _channel.invokeMethod<bool>('acquireWakeLock');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> release() async {
    if (!_canRun) {
      _simulatedHeld = false;
      return true;
    }
    try {
      final res = await _channel.invokeMethod<bool>('releaseWakeLock');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isHeld() async {
    if (!_canRun) return _simulatedHeld;
    try {
      final res = await _channel.invokeMethod<bool>('isWakeLockHeld');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
