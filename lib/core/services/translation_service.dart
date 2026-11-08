import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Natural paragraph-level translation service with preserved microstock glossary and sanitized entities.
class TranslationService {
  static const String _cacheKeyPrefix = 'nra_trans_natural_v5_';
  static const int maxMemoryEntries = 500;
  static final Map<String, String> _memoryCache = {};

  @visibleForTesting
  static void clearMemoryCache() => _memoryCache.clear();

  @visibleForTesting
  static int get memoryCacheSize => _memoryCache.length;

  static void _putMemoryCache(String key, String value) {
    if (_memoryCache.containsKey(key)) {
      _memoryCache.remove(key);
    } else if (_memoryCache.length >= maxMemoryEntries) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
    _memoryCache[key] = value;
  }

  @visibleForTesting
  static Future<String> Function(String text, String targetLang)?
  mockTranslator;

  @visibleForTesting
  static Future<String> Function(Uri uri)? customHttpGet;

  /// Translates short text with cache fallback, glossary enforcement, and entity cleanup.
  static Future<String> translateText(
    String text, {
    String targetLang = 'id',
    bool isOnline = true,
  }) async {
    final sanitized = _cleanHtmlArtifacts(text.trim());
    if (sanitized.isEmpty) return sanitized;

    final cacheKey = '${targetLang}_${sanitized.hashCode}';
    final cached = await _getCached(cacheKey);
    if (cached != null) return cached;

    final dictMatch = _translateFromOfflineDictionary(sanitized, targetLang);
    if (dictMatch != null) {
      final protected = _protectGlossary(dictMatch);
      await _cacheTranslation(cacheKey, protected);
      return protected;
    }

    if (!isOnline) {
      throw const TranslationOfflineException(
        'Internet connection required for translation',
      );
    }

    final raw = mockTranslator != null
        ? await mockTranslator!(sanitized, targetLang)
        : await _fetchGtxChunk(sanitized, targetLang);

    final res = raw.isNotEmpty
        ? raw
        : _performRuleBasedTranslation(sanitized, targetLang);
    final finalResult = _protectGlossary(_cleanHtmlArtifacts(res));
    await _cacheTranslation(cacheKey, finalResult);
    return finalResult;
  }

  /// Translates complete multi-paragraph articles preserving paragraph bounds and glossary terms.
  static Future<String> translateLongText(
    String fullText, {
    String targetLang = 'id',
    bool isOnline = true,
  }) async {
    final sanitized = _cleanHtmlArtifacts(fullText.trim());
    if (sanitized.isEmpty) return sanitized;

    final cacheKey = '${targetLang}_long_${sanitized.hashCode}';
    final cached = await _getCached(cacheKey);
    if (cached != null) return cached;

    final paragraphs = sanitized.split(RegExp(r'\n{2,}'));
    final translatedChunks = <String>[];

    for (final p in paragraphs) {
      final pTrim = p.trim();
      if (pTrim.isEmpty) continue;
      final t = await translateText(
        pTrim,
        targetLang: targetLang,
        isOnline: isOnline,
      );
      translatedChunks.add(t);
    }

    final combined = translatedChunks.join('\n\n');
    await _cacheTranslation(cacheKey, combined);
    return combined;
  }

  /// Fetches translated paragraph chunk from Google Translate GTX public endpoint.
  static Future<String> _fetchGtxChunk(String chunk, String targetLang) async {
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(chunk)}',
      );
      final raw = customHttpGet != null
          ? await customHttpGet!(uri)
          : await _defaultHttpGet(uri);
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
    } catch (e) {
      // GTX JSON and the request URI both carry article text; log the type only.
      debugPrint(
        '[TranslationService] gtx chunk fetch failed: ${e.runtimeType}',
      );
    }
    return '';
  }

  static Future<String> _defaultHttpGet(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return await res.transform(utf8.decoder).join();
      }
    } catch (e) {
      debugPrint('[TranslationService] HTTP GET failed: ${e.runtimeType}');
    } finally {
      client.close();
    }
    return '';
  }

  static String _cleanHtmlArtifacts(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
  }

  /// Preserves authentic technical microstock terminology.
  static String _protectGlossary(String text) {
    var result = text;
    const technicalGlossary = {
      r'\bStock Footage\b': 'Footage Video Stok',
      r'\bFootage\b': 'Footage',
      r'\bLead Time\b': 'Masa Persiapan (Lead Time)',
      r'\bCFR\b': 'CFR',
      r'\bVFR\b': 'VFR',
      r'\bFrame Rate\b': 'Frame Rate',
      r'\bBitrate\b': 'Bitrate',
      r'\bBT\.709\b': 'BT.709',
      r'\bRec\.709\b': 'Rec.709',
      r'\bCuration\b': 'Kurasi',
      r'\bCurator\b': 'Kurator',
      r'\bCommercial Rights\b': 'Lisensi Komersial',
    };
    technicalGlossary.forEach((pattern, replacement) {
      result = result.replaceAll(
        RegExp(pattern, caseSensitive: false),
        replacement,
      );
    });
    return result;
  }

  static Future<String?> _getCached(String key) async {
    if (_memoryCache.containsKey(key)) {
      final val = _memoryCache.remove(key)!;
      _memoryCache[key] = val;
      return val;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString('$_cacheKeyPrefix$key');
      if (val != null && val.isNotEmpty) {
        _putMemoryCache(key, val);
        return val;
      }
    } catch (e) {
      debugPrint(
        '[TranslationService] translate cache read failed: ${e.runtimeType}',
      );
    }
    return null;
  }

  static Future<void> _cacheTranslation(String key, String translated) async {
    _putMemoryCache(key, translated);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cacheKeyPrefix$key', translated);
    } catch (e) {
      debugPrint(
        '[TranslationService] translate cache persist failed: '
        '${e.runtimeType}',
      );
    }
  }

  static String? _translateFromOfflineDictionary(
    String text,
    String targetLang,
  ) {
    if (targetLang.toLowerCase() != 'id') return null;
    const dict = {
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
          'Deduplikasi microstock berkonversi tinggi dan footage sinematik membuka bonus tingkatan pendapatan.',
      'Microstock AI Inspection Guidelines 2026':
          'Panduan Inspeksi Microstock AI 2026',
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

    var result = text;
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
      'commercial footage': 'footage komersial',
      'buyer acquisition': 'akuisisi pembeli',
      'authentic': 'autentik',
      'demands': 'permintaan',
      'guidelines': 'panduan',
    };
    terms.forEach((en, id) {
      result = result.replaceAll(
        RegExp(RegExp.escape(en), caseSensitive: false),
        id,
      );
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
