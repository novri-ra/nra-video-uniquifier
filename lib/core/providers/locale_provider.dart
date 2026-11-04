import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// Provider for dynamic application language switching and persistence.
class LocaleProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  LocaleProvider() {
    _loadSavedLocale();
  }

  Locale get currentLocale => _currentLocale;
  String get languageCode => _currentLocale.languageCode;

  Future<void> _loadSavedLocale() async {
    try {
      final code = await SettingsService.getAppLanguageCode();
      if (code == 'en' || code == 'id') {
        _currentLocale = Locale(code);
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('[LocaleProvider] Gagal memuat locale: $e\n$stackTrace');
    }
  }

  Future<void> changeLanguage(String code) async {
    if (code != 'id' && code != 'en') return;
    if (_currentLocale.languageCode == code) return;
    _currentLocale = Locale(code);
    notifyListeners();
    try {
      await SettingsService.setAppLanguageCode(code);
    } catch (_) {}
  }
}
