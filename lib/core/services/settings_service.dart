import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TargetResolution {
  r1080p('1080p', '1080p', '1920x1080', 1920, 1080),
  r2k('2k', '2K', '2560x1440', 2560, 1440),
  r4k('4k', '4K', '3840x2160', 3840, 2160);

  final String key;
  final String label;
  final String details;
  final int width;
  final int height;

  const TargetResolution(this.key, this.label, this.details, this.width, this.height);

  int targetWidth({bool isPortrait = false}) => isPortrait ? height : width;
  int targetHeight({bool isPortrait = false}) => isPortrait ? width : height;

  String scaleFilter({bool isPortrait = false}) =>
      isPortrait ? 'scale=w=$height:h=-2:flags=lanczos' : 'scale=w=-2:h=$height:flags=lanczos';

  static TargetResolution fromString(String? val) {
    switch (val?.toLowerCase()) {
      case '2k':
      case '1440p':
        return TargetResolution.r2k;
      case '4k':
      case '2160p':
        return TargetResolution.r4k;
      case '1080p':
      default:
        return TargetResolution.r1080p;
    }
  }
}

class SettingsService {
  static const String keyEngineMode = 'app_engine_mode';
  static const String keyDefaultPreset = 'app_default_preset';
  static const String keyCustomOutputPath = 'app_output_path';
  static const String keyUpscaleResolution = 'app_upscale_resolution';
  static const String keyEnhanceAndDenoise = 'app_enhance_denoise';
  static const String keyDeepAntiFingerprint = 'app_deep_anti_fingerprint';
  static const String keyHorizontalFlip = 'app_horizontal_flip';
  static const String keyAggressiveAudio = 'app_aggressive_audio';
  static const String keyAutoTrim = 'app_auto_trim';

  static final ValueNotifier<TargetResolution> upscaleResolutionNotifier =
      ValueNotifier<TargetResolution>(TargetResolution.r1080p);

  static Future<TargetResolution> getUpscaleResolution() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyUpscaleResolution);
    final resolution = TargetResolution.fromString(raw);
    upscaleResolutionNotifier.value = resolution;
    return resolution;
  }

  static Future<void> setUpscaleResolution(TargetResolution resolution) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUpscaleResolution, resolution.key);
    upscaleResolutionNotifier.value = resolution;
  }

  static Future<bool> getEnhanceAndDenoise() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyEnhanceAndDenoise) ?? true;
  }

  static Future<void> setEnhanceAndDenoise(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyEnhanceAndDenoise, enabled);
  }

  static Future<bool> getDeepAntiFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyDeepAntiFingerprint) ?? true;
  }

  static Future<void> setDeepAntiFingerprint(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyDeepAntiFingerprint, enabled);
  }

  static Future<bool> getHorizontalFlip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyHorizontalFlip) ?? false;
  }

  static Future<void> setHorizontalFlip(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyHorizontalFlip, enabled);
  }

  static Future<bool> getAggressiveAudio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyAggressiveAudio) ?? false;
  }

  static Future<void> setAggressiveAudio(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyAggressiveAudio, enabled);
  }

  static Future<bool> getAutoTrim() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyAutoTrim) ?? false;
  }

  static Future<void> setAutoTrim(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyAutoTrim, enabled);
  }

  static Future<String> getEngineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyEngineMode) ?? 'software';
  }

  static Future<void> setEngineMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyEngineMode, mode);
  }

  static Future<String> getDefaultPreset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyDefaultPreset) ?? 'balanced';
  }

  static Future<void> setDefaultPreset(String preset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyDefaultPreset, preset);
  }

  static Future<String?> getCustomOutputPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyCustomOutputPath);
  }

  static Future<void> setCustomOutputPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCustomOutputPath, path);
  }

  /// Purges temporary staged videos and thumbnails from sandbox cache.
  static Future<int> purgeTempCache([Directory? overrideDir]) async {
    int freedBytes = 0;
    try {
      final tempDir = overrideDir ?? await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final entries = tempDir.listSync(followLinks: false);
        for (final entry in entries) {
          if (entry is File) {
            final name = entry.path.split(RegExp(r'[/\\]')).last;
            if (name.startsWith('staged_') || name.startsWith('thumb_')) {
              freedBytes += entry.lengthSync();
              entry.deleteSync();
            }
          }
        }
      }
    } catch (_) {}
    return freedBytes;
  }
}
