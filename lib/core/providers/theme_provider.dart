import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// Provider for dynamic application theme mode switching and persistence.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadSavedThemeMode();
  }

  ThemeMode get themeMode => _themeMode;
  String get themeModeString => _themeModeToString(_themeMode);

  Future<void> _loadSavedThemeMode() async {
    try {
      final saved = await SettingsService.getThemeMode();
      _themeMode = _parseThemeMode(saved);
      notifyListeners();
    } catch (e) {
      debugPrint('[ThemeProvider] theme mode load failed: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      await SettingsService.setThemeMode(_themeModeToString(mode));
    } catch (e) {
      debugPrint('[ThemeProvider] theme mode save failed: $e');
    }
  }

  static ThemeMode _parseThemeMode(String val) {
    switch (val.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
