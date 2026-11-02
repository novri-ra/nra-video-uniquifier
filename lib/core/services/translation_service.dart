import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Translation service with persistent multi-paragraph chunking and offline resilience.
class TranslationService {
  static const String _cacheKeyPrefix = 'nra_trans_cache_';
  static final Map<String, String> _memoryCache = {};

  @visibleForTesting
  static Future<String> Function(String text, String targetLang)? mockTranslator;

  @visibleForTesting
  static Future<String> Function(Uri uri)? customHttpGet;

  /// Translates short text with cache fallback and offline dictionary support.
  static Future<String> translateText(
    String text, {
    String targetLang = 'id',
    bool isOnline = true,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;

    final cacheKey = '${targetLang}_${trimmed.hashCode}';
    final cached = await _getCached(cacheKey);
    if (cached != null) return cached;

    final dictMatch = _translateFromOfflineDictionary(trimmed, targetLang);
    if (dictMatch != null) {
      await _cacheTranslation(cacheKey, dictMatch);
      return dictMatch;
    }

    if (!isOnline) {
      throw const TranslationOfflineException('Koneksi internet diperlukan untuk menerjemahkan');
    }

    if (mockTranslator != null) {
      final res = await mockTranslator!(trimmed, targetLang);
      await _cacheTranslation(cacheKey, res);
      return res;
    }

    final fetched = await _fetchGtxChunk(trimmed, targetLang);
    final result = fetched.isNotEmpty ? fetched : _performRuleBasedTranslation(trimmed, targetLang);
    await _cacheTranslation(cacheKey, result);
    return result;
  }

  /// Translates long multi-paragraph articles by chunking paragraphs and reassembling.
  static Future<String> translateLongText(
    String fullText, {
    String targetLang = 'id',
    bool isOnline = true,
  }) async {
    final trimmed = fullText.trim();
    if (trimmed.isEmpty) return trimmed;

    final cacheKey = '${targetLang}_long_${trimmed.hashCode}';
    final cached = await _getCached(cacheKey);
    if (cached != null) return cached;

    final paragraphs = trimmed.split('\n\n');
    final translatedChunks = <String>[];

    for (final p in paragraphs) {
      final pTrim = p.trim();
      if (pTrim.isEmpty) continue;
      final t = await translateText(pTrim, targetLang: targetLang, isOnline: isOnline);
      translatedChunks.add(t);
    }

    final combined = translatedChunks.join('\n\n');
    await _cacheTranslation(cacheKey, combined);
    return combined;
  }

  /// Helper to fetch one translated chunk from Google Translate public endpoint.
  static Future<String> _fetchGtxChunk(String chunk, String targetLang) async {
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(chunk)}',
      );
      final raw = customHttpGet != null ? await customHttpGet!(uri) : await _defaultHttpGet(uri);
      if (raw.isEmpty) return '';
      final decoded = jsonDecode(raw);
      if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
        final buf = StringBuffer();
        for (final item in decoded[0]) {
          if (item is List && item.isNotEmpty && item[0] != null) {
            buf.write(item[0]);
          }
        }
        return buf.toString();
      }
    } catch (_) {}
    return '';
  }

  static Future<String> _defaultHttpGet(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) return await res.transform(utf8.decoder).join();
    } catch (_) {
    } finally {
      client.close();
    }
    return '';
  }

  static Future<String?> _getCached(String key) async {
    if (_memoryCache.containsKey(key)) return _memoryCache[key];
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString('$_cacheKeyPrefix$key');
      if (val != null && val.isNotEmpty) {
        _memoryCache[key] = val;
        return val;
      }
    } catch (_) {}
    return null;
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
    const dict = {
      'Adobe Stock Releases 2026 Visual Trend Forecast': 'Adobe Stock Merilis Prakiraan Tren Visual 2026',
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
      'Microstock AI Inspection Guidelines 2026': 'Panduan Inspeksi Microstock AI 2026',
      'Metadata stripping and sensor fingerprint variation prevent automated duplicate rejections.':
          'Pembersihan metadata dan variasi sidik jari sensor mencegah penolakan duplikat otomatis.',
      'Community Discussion: AI Duplicate Detection on Cross-Agency Uploads':
          'Diskusi Komunitas: Deteksi Duplikat AI pada Unggahan Lintas Agensi',
      'Updated just now': 'Diperbarui baru saja',
      'Offline Cache Mode': 'Mode Cache Offline',
      'Offline Cache Active': 'Cache Offline Aktif',
      'Connected': 'Terhubung',
    };
    return dict[text];
  }

  static String _performRuleBasedTranslation(String text, String targetLang) {
    if (targetLang.toLowerCase() != 'id') return text;
    final dictMatch = _translateFromOfflineDictionary(text, 'id');
    if (dictMatch != null) return dictMatch;

    String result = text;
    const terms = {
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
