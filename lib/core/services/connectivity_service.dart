import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Lightweight real-time network connectivity monitor.
/// Uses OS-level events instead of polling to save battery (0% idle drain).
class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._internal();
  ConnectivityService._internal();

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _initialized = false;

  /// Starts monitoring network connectivity.
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // 1. Cek status koneksi saat ini (hanya sekali saat inisialisasi)
    _checkInitialConnectivity();

    // 2. Dengarkan perubahan koneksi dari OS (Event-driven, bukan polling)
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (e) => debugPrint('[Connectivity] Error: $e'),
    );
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('[ConnectivityService] check initial connectivity failed: $e');
      isOnline.value = false;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Jika array kosong atau berisi 'none', berarti offline.
    // Jika berisi 'wifi', 'mobile', 'ethernet', dll, berarti online.
    final online = results.any((result) => result != ConnectivityResult.none);

    if (isOnline.value != online) {
      isOnline.value = online;
    }
  }

  /// Sets connectivity state directly (useful for tests).
  void setOnlineForTesting(bool value) {
    isOnline.value = value;
  }

  /// Disposes listener when app shuts down.
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _initialized = false;
  }
}
