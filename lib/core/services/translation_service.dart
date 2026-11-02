import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Translation service with local persistent cache and simulated offline resilience.
class TranslationService {
  static const String _cacheKeyPrefix = 'nra_trans_cache_';
  static final Map<String, String> _memoryCache = {};

  /// Custom remote translator hook for test mocking or future cloud integrations.
  @visibleForTesting
  static Future<String> Function(String text, String targetLang)? mockTranslator;

  /// Translates text with target language, falling back to cached translation or source text.
  static Future<String> translateText(
    String text, {
    String targetLang = 'id',
    bool isOnline = true,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;

    final cacheKey = '${targetLang}_${trimmed.hashCode}';
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // Try reading persistent SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_cacheKeyPrefix$cacheKey');
      if (cached != null && cached.isNotEmpty) {
        _memoryCache[cacheKey] = cached;
        return cached;
      }
    } catch (_) {}

    // Check offline dictionary baseline before failing
    final dictMatch = _translateFromOfflineDictionary(trimmed, targetLang);
    if (dictMatch != null) {
      await _cacheTranslation(cacheKey, dictMatch);
      return dictMatch;
    }

    if (!isOnline) {
      throw const TranslationOfflineException(
        'Koneksi internet diperlukan untuk menerjemahkan',
      );
    }

    if (mockTranslator != null) {
      final translated = await mockTranslator!(trimmed, targetLang);
      await _cacheTranslation(cacheKey, translated);
      return translated;
    }

    // Simulated reliable translation engine (EN <-> ID)
    final translated = _performRuleBasedTranslation(trimmed, targetLang);
    await _cacheTranslation(cacheKey, translated);
    return translated;
  }

  static Future<void> _cacheTranslation(String key, String translated) async {
    _memoryCache[key] = translated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cacheKeyPrefix$key', translated);
    } catch (_) {}
  }

  static String? _translateFromOfflineDictionary(String text, String targetLang) {
    if (targetLang.toLowerCase() != 'id') return null;
    final Map<String, String> dict = {
      'Adobe Stock Releases 2026 Visual Trend Forecast':
          'Adobe Stock Merilis Prakiraan Tren Visual 2026',
      'Autonomous robotics, clean energy, and authentic cultural celebrations lead creator demand.':
          'Robotika otonom, energi bersih, dan perayaan budaya autentik memimpin permintaan kreator.',
      'Shutterstock Accelerates Editorial Video Requirements':
          'Shutterstock Mempercepat Standar Kebutuhan Video Editorial',
      '4K 60FPS CFR format with clean primary BT.709 color spaces now favored for enterprise licensing.':
          'Format 4K 60FPS CFR dengan ruang warna bersih BT.709 kini diutamakan untuk lisensi korporat.',
      'Freepik Announces Enhanced Contributor Royalty Program':
          'Freepik Mengumumkan Peningkatan Program Royalti Kontributor',
      'High-converting microstock deduplication and cinematic footage unlock bonus revenue tiers.':
          'Deduplikasi microstock berkonversi tinggi dan rekaman sinematik membuka bonus tingkatan pendapatan.',
      'Microstock AI Inspection Guidelines 2026':
          'Panduan Inspeksi Microstock AI 2026',
      'Metadata stripping and sensor fingerprint variation prevent automated duplicate rejections.':
          'Pembersihan metadata dan variasi sidik jari sensor mencegah penolakan duplikat otomatis.',
      'Global Commercial Footage Demand Peaks for Lunar New Year & Ramadan':
          'Permintaan Rekaman Komersial Global Mencapai Puncak untuk Imlek & Ramadan',
      'ProRes and H.264 formats with alpha transparency achieve 3x faster buyer acquisition.':
          'Format ProRes dan H.264 dengan transparansi alpha menghasilkan akuisisi pembeli 3x lebih cepat.',
      'Updated just now': 'Diperbarui baru saja',
      'Offline Cache Mode': 'Mode Cache Offline',
      'Offline Cache Active': 'Cache Offline Aktif',
      'Connected': 'Terhubung',
    };
    return dict[text];
  }

  static String _performRuleBasedTranslation(String text, String targetLang) {
    if (targetLang.toLowerCase() == 'id') {
      return _translateToIndonesian(text);
    } else {
      return text;
    }
  }

  static String _translateToIndonesian(String text) {
    final dictMatch = _translateFromOfflineDictionary(text, 'id');
    if (dictMatch != null) return dictMatch;

    String result = text;
    final Map<String, String> terms = {
      'Autonomous robotics': 'Robotika otonom',
      'clean energy': 'energi bersih',
      'cultural celebrations': 'perayaan budaya',
      'creator demand': 'permintaan kreator',
      'enterprise licensing': 'lisensi korporat',
      'bonus revenue tiers': 'tingkatan pendapatan bonus',
      'Metadata stripping': 'Pembersihan metadata',
      'sensor fingerprint': 'sidik jari sensor',
      'duplicate rejections': 'penolakan duplikat',
      'commercial footage': 'rekaman komersial',
      'buyer acquisition': 'akuisisi pembeli',
      'authentic': 'autentik',
      'demands': 'permintaan',
      'guidelines': 'panduan',
    };

    terms.forEach((en, id) {
      result = result.replaceAll(RegExp(RegExp.escape(en), caseSensitive: false), id);
    });

    return result;
  }
}

/// Thrown when translation is requested offline without pre-existing cache.
class TranslationOfflineException implements Exception {
  final String message;
  const TranslationOfflineException(this.message);

  @override
  String toString() => message;
}
