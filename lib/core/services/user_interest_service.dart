import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'microstock_news_service.dart';

/// Internal data container for decayed affinity scores with timestamps.
class _AffinityRecord {
  final double score;
  final int lastUpdated;

  const _AffinityRecord({required this.score, required this.lastUpdated});

  Map<String, dynamic> toJson() => {'score': score, 'lastUpdated': lastUpdated};

  factory _AffinityRecord.fromJson(Map<String, dynamic> json) {
    return _AffinityRecord(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      lastUpdated:
          (json['lastUpdated'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// Strictly offline-first self-learning user interest engine with exponential half-life decay.
class UserInterestService {
  static const String _affinityKeyV1 = 'nra_keyword_affinity_v1';
  static const String _affinityKeyV2 = 'nra_user_affinity_v2';
  static const String _webhookKey = 'nra_telemetry_webhook_url';

  static const List<String> defaultKeywords = [
    'All',
    '4K Footage',
    'Shutterstock',
    'Adobe Stock',
    'AI Video',
    'Reels Algorithm',
    'Color Grading',
    'Curation Tips',
    'Commercial Rights',
  ];

  static const String defaultWebhookUrl =
      'https://script.google.com/macros/s/AKfycbzy4jEhfXCqt2XJnYETH2UXF5vMo26AguljNl0a20PDDXXKsfX5EOPTUcwadlXCoya-/exec';

  static final Map<String, _AffinityRecord> _affinityMap = {};
  static bool _initialized = false;
  static String? _configuredWebhookUrl;

  @visibleForTesting
  static Future<bool> Function(Map<String, dynamic> payload)? mockDispatcher;

  /// Initializes affinity records from persistent cache.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _loadAffinity();
  }

  /// Sets custom webhook URL for configuration testing.
  static Future<void> setWebhookUrl(String url) async {
    _configuredWebhookUrl = url;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webhookKey, url);
    } catch (e) {
      debugPrint('[UserInterestService] webhook url save failed: $e');
    }
  }

  /// Retrieves active webhook URL from memory or preferences.
  static Future<String> getWebhookUrl() async {
    if (_configuredWebhookUrl != null) return _configuredWebhookUrl!;
    try {
      final prefs = await SharedPreferences.getInstance();
      _configuredWebhookUrl = prefs.getString(_webhookKey) ?? defaultWebhookUrl;
    } catch (_) {
      _configuredWebhookUrl = defaultWebhookUrl;
    }
    return _configuredWebhookUrl ?? defaultWebhookUrl;
  }

  /// Calculates decayed score using 7-day exponential half-life formula:
  /// DecayedScore = Score * 0.5 ^ (daysDiff / 7.0)
  static double _calculateDecayedScore(
    _AffinityRecord record, [
    int? nowMillis,
  ]) {
    final now = nowMillis ?? DateTime.now().millisecondsSinceEpoch;
    final diffMillis = (now - record.lastUpdated).clamp(0, double.infinity);
    final daysDiff = diffMillis / (1000 * 60 * 60 * 24);
    return record.score * math.pow(0.5, daysDiff / 7.0);
  }

  /// Sorts provided categories and tags by user decayed affinity score descending.
  /// Always places 'All' at index 0.
  static List<String> getSortedDynamicCategories(List<String> rawCategories) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final seen = <String>{};
    final uniqueCategories = <String>[];

    for (final raw in rawCategories) {
      final clean = raw.replaceAll('#', '').trim();
      if (clean.isEmpty || clean.toLowerCase() == 'all') continue;
      if (seen.add(clean.toLowerCase())) {
        uniqueCategories.add(clean);
      }
    }

    uniqueCategories.sort((a, b) {
      final recordA = _affinityMap[a.toLowerCase()];
      final recordB = _affinityMap[b.toLowerCase()];
      final scoreA = recordA != null
          ? _calculateDecayedScore(recordA, now)
          : 0.0;
      final scoreB = recordB != null
          ? _calculateDecayedScore(recordB, now)
          : 0.0;
      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA);
      }
      return 0;
    });

    return ['All', ...uniqueCategories];
  }

  /// Returns adaptive keywords with 'All' first, followed by dynamically ranked topics.
  static List<String> getAdaptiveKeywords() {
    return getSortedDynamicCategories(defaultKeywords);
  }

  /// Records search query submission (+3.0 weight).
  static Future<void> recordSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    await _addWeight(trimmed, 3.0);
    await _dispatchTelemetry({
      'type': 'user_interest_telemetry',
      'eventType': 'search_submit',
      'query': trimmed,
    });
  }

  /// Records keyword chip selection (+2.0 weight).
  static Future<void> recordChipClick(String keyword) async {
    if (keyword == 'All') return;
    await _addWeight(keyword, 2.0);
    await _dispatchTelemetry({
      'type': 'user_interest_telemetry',
      'eventType': 'chip_click',
      'keyword': keyword,
    });
  }

  /// Records article reader open event (+3.0 category, +1.0 tags).
  static Future<void> recordArticleRead(MicrostockNewsArticle article) async {
    await _addWeight(article.category, 3.0);
    for (final tag in article.tags) {
      await _addWeight(tag.replaceAll('#', ''), 1.0);
    }
    await _dispatchTelemetry({
      'type': 'user_interest_telemetry',
      'eventType': 'article_read',
      'articleTitle': article.title,
      'category': article.category,
    });
  }

  /// Records outbound source link opening (+5.0 category, +2.0 tags).
  static Future<void> recordOpenSourceUrl(MicrostockNewsArticle article) async {
    await _addWeight(article.category, 5.0);
    for (final tag in article.tags) {
      await _addWeight(tag.replaceAll('#', ''), 2.0);
    }
    await _dispatchTelemetry({
      'type': 'user_interest_telemetry',
      'eventType': 'open_source_url',
      'articleTitle': article.title,
      'sourceUrl': article.sourceUrl,
    });
  }

  /// Records article translation toggle (+1.0 category weight).
  static Future<void> recordTranslateToggle(
    MicrostockNewsArticle article,
    String langMode,
  ) async {
    await _addWeight(article.category, 1.0);
    await _dispatchTelemetry({
      'type': 'user_interest_telemetry',
      'eventType': 'translate_toggle',
      'articleTitle': article.title,
      'langMode': langMode,
    });
  }

  /// Dispatches video metadata vault payload to mockDispatcher for test validation.
  static Future<void> dispatchVideoMetadataVault({
    required String title,
    required String description,
    required List<String> keywords,
    required List<String> platforms,
    required String techSpecs,
    required String category,
    String leadWindow = '',
  }) async {
    await _dispatchTelemetry({
      'type': 'video_metadata_vault',
      'title': title,
      'description': description,
      'keywords': keywords,
      'platforms': platforms,
      'techSpecs': techSpecs,
      'category': category,
      'leadWindow': leadWindow,
    });
  }

  static Future<void> _addWeight(String term, double weight) async {
    final key = term.trim().toLowerCase();
    if (key.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = _affinityMap[key];
    final currentDecayed = existing != null
        ? _calculateDecayedScore(existing, now)
        : 0.0;

    _affinityMap[key] = _AffinityRecord(
      score: currentDecayed + weight,
      lastUpdated: now,
    );
    await _saveAffinity();
  }

  static Future<void> _loadAffinity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawV2 = prefs.getString(_affinityKeyV2);
      if (rawV2 != null && rawV2.isNotEmpty) {
        final decoded = jsonDecode(rawV2) as Map<String, dynamic>;
        decoded.forEach((k, v) {
          if (v is Map<String, dynamic>) {
            _affinityMap[k] = _AffinityRecord.fromJson(v);
          }
        });
        return;
      }

      // Backward compatibility: migrate legacy v1 affinity
      final rawV1 = prefs.getString(_affinityKeyV1);
      if (rawV1 != null && rawV1.isNotEmpty) {
        final decoded = jsonDecode(rawV1) as Map<String, dynamic>;
        final now = DateTime.now().millisecondsSinceEpoch;
        decoded.forEach((k, v) {
          _affinityMap[k] = _AffinityRecord(
            score: (v as num).toDouble(),
            lastUpdated: now,
          );
        });
      }
    } catch (e) {
      // FormatException echoes the corrupted JSON, whose keys are user queries.
      debugPrint(
        '[UserInterestService] affinity load failed: ${e.runtimeType}',
      );
    }
  }

  static Future<void> _saveAffinity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        for (final entry in _affinityMap.entries)
          entry.key: entry.value.toJson(),
      };
      await prefs.setString(_affinityKeyV2, jsonEncode(map));
    } catch (e) {
      debugPrint('[UserInterestService] affinity save failed: $e');
    }
  }

  /// Strictly offline-first telemetry dispatch. Invokes mockDispatcher in test environments.
  static Future<void> _dispatchTelemetry(Map<String, dynamic> payload) async {
    if (mockDispatcher != null) {
      await mockDispatcher!(payload);
    }
    // Strictly offline-first: 0 external network requests in production.
  }

  /// Retained for test compatibility; performs no external network calls.
  static Future<void> flushQueue() async {}
}
