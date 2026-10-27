import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String keyEngineMode = 'app_engine_mode';
  static const String keyDefaultPreset = 'app_default_preset';
  static const String keyCustomOutputPath = 'app_output_path';

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
