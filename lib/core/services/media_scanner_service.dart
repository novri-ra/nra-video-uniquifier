import 'dart:io';
import 'package:flutter/services.dart';

class MediaScannerService {
  static const MethodChannel _channel = MethodChannel(
    'id.novrira.videouniquifier/media_scanner',
  );

  /// Requests Android MediaScanner to index the file so it shows in Gallery immediately,
  /// or purge the entry from MediaStore if the file has been deleted.
  static Future<bool> scanFile(String filePath) async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod<bool>('scanFile', {
        'path': filePath,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Triggers MediaScanner to refresh index after file creation or deletion.
  static Future<bool> refreshFile(String filePath) async {
    return scanFile(filePath);
  }

  /// Launches default gallery application pointing to video content or specific file.
  static Future<bool> openGallery([String? filePath]) async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('openGallery', {
        'path': filePath,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
