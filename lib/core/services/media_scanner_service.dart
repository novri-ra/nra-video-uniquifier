import 'dart:io';
import 'package:flutter/services.dart';

class MediaScannerService {
  static const MethodChannel _channel = MethodChannel('com.example.nra_video_uniquifier/media_scanner');

  /// Requests Android MediaScanner to index the file so it shows in Gallery immediately.
  static Future<bool> scanFile(String filePath) async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod<bool>('scanFile', {'path': filePath});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Launches default gallery application pointing to video content or specific file.
  static Future<bool> openGallery([String? filePath]) async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('openGallery', {'path': filePath});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
