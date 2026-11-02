import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
import 'microstock_news_service.dart';

/// Self-learning user interest engine and Google Sheets telemetry dispatcher.
class UserInterestService {
  static const String _affinityKey = 'nra_keyword_affinity_v1';
  static const String _webhookKey = 'nra_telemetry_webhook_url';
  static const String _queueKey = 'nra_telemetry_queue_v1';

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

  static final Map<String, int> _affinityMap = {};
  static bool _initialized = false;
  static String? _configuredWebhookUrl;

  @visibleForTesting
  static Future<bool> Function(Map<String, dynamic> payload)? mockDispatcher;

  /// Initializes affinity weights and registers connectivity listener for offline queue flushing.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _loadAffinity();
    ConnectivityService.instance.isOnline.addListener(() {
      if (ConnectivityService.instance.isOnline.value) {
        flushQueue();
      }
    });
  }

  /// Sets custom webhook URL.
  static Future<void> setWebhookUrl(String url) async {
    _configuredWebhookUrl = url;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webhookKey, url);
    } catch (_) {}
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

  /// Returns adaptive keywords with 'All' first, followed by dynamically ranked topics.
  static List<String> getAdaptiveKeywords() {
    final list = List<String>.from(defaultKeywords.where((k) => k != 'All'));
    list.sort((a, b) {
      final scoreA = _affinityMap[a.toLowerCase()] ?? 0;
      final scoreB = _affinityMap[b.toLowerCase()] ?? 0;
      return scoreB.compareTo(scoreA);
    });
    return ['All', ...list];
  }

  /// Records search query submission (+3 weight).
  static Future<void> recordSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    await _addWeight(trimmed, 3);
    await _dispatchTelemetry({
      'type': 'user_interest_telemetry',
      'eventType': 'search_submit',
      'query': trimmed,
    });
  }

  /// Records keyword chip selection (+2 weight).
  static Future<void> recordChipClick(String keyword) async {
    if (keyword == 'All') return;
    await _addWeight(keyword, 2);
    await _dispatchTelemetry({
      'type': 'user_interest_telemetry',
      'eventType': 'chip_click',
      'keyword': keyword,
    });
  }

  /// Records article reader open event (+2 weight).
  static Future<void> recordArticleRead(MicrostockNewsArticle article) async {
    await _addWeight(article.category, 2);
    for (final tag in article.tags) {
      await _addWeight(tag.replaceAll('#', ''), 1);
    }
    await _dispatchTelemetry({
      'type': 'user_interest_telemetry',
      'eventType': 'article_read',
      'articleTitle': article.title,
      'category': article.category,
    });
  }

  /// Records article translation toggle (+1 weight).
  static Future<void> recordTranslateToggle(MicrostockNewsArticle article, String langMode) async {
    await _addWeight(article.category, 1);
    await _dispatchTelemetry({
      'type': 'user_interest_telemetry',
      'eventType': 'translate_toggle',
      'articleTitle': article.title,
      'langMode': langMode,
    });
  }

  /// Dispatches video metadata vault payload asynchronously.
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

  static Future<void> _addWeight(String term, int weight) async {
    final key = term.toLowerCase();
    _affinityMap[key] = (_affinityMap[key] ?? 0) + weight;
    await _saveAffinity();
  }

  static Future<void> _loadAffinity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_affinityKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((k, v) => _affinityMap[k] = (v as num).toInt());
      }
    } catch (_) {}
  }

  static Future<void> _saveAffinity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_affinityKey, jsonEncode(_affinityMap));
    } catch (_) {}
  }

  static Future<void> _dispatchTelemetry(Map<String, dynamic> payload) async {
    if (mockDispatcher != null) {
      await mockDispatcher!(payload);
      return;
    }

    final isOnline = ConnectivityService.instance.isOnline.value;
    final url = await getWebhookUrl();
    if (!isOnline || url.isEmpty) {
      await _enqueuePayload(payload);
      return;
    }

    final success = await _postPayload(url, payload);
    if (!success) await _enqueuePayload(payload);
  }

  static Future<bool> _postPayload(String url, Map<String, dynamic> payload) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.parse(url);
      final req = await client.postUrl(uri);
      req.followRedirects = true;
      req.headers.set('Content-Type', 'application/json; charset=UTF-8');
      req.write(jsonEncode(payload));
      final res = await req.close().timeout(const Duration(seconds: 5));
      // Google Apps Script Web App responds with 200 OK or 302 Found redirect on success
      return res.statusCode >= 200 && res.statusCode <= 302;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  static Future<void> _enqueuePayload(Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_queueKey) ?? [];
      list.add(jsonEncode(payload));
      if (list.length > 50) list.removeAt(0); // circular buffer cap
      await prefs.setStringList(_queueKey, list);
    } catch (_) {}
  }

  /// Flushes buffered telemetry queue when connection is restored.
  static Future<void> flushQueue() async {
    final url = await getWebhookUrl();
    if (url.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_queueKey) ?? [];
      if (list.isEmpty) return;

      final remaining = <String>[];
      for (final item in list) {
        final payload = jsonDecode(item) as Map<String, dynamic>;
        final sent = mockDispatcher != null ? await mockDispatcher!(payload) : await _postPayload(url, payload);
        if (!sent) remaining.add(item);
      }
      await prefs.setStringList(_queueKey, remaining);
    } catch (_) {}
  }
}
