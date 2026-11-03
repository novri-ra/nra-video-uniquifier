import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
import 'microstock_seed_data.dart';

/// News article model for Microstock Intel & Trends feed.
class MicrostockNewsArticle {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String category;
  final String publishedDate;
  final String sourceUrl;
  final List<String> tags;
  final String fullContent;
  final String readTime;
  final String keyTakeaways;
  final List<String> technicalSpecs;
  final List<String> contributorChecklist;

  const MicrostockNewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.category,
    required this.publishedDate,
    required this.sourceUrl,
    required this.tags,
    this.fullContent = '',
    this.readTime = '3 min read',
    this.keyTakeaways = '',
    this.technicalSpecs = const [],
    this.contributorChecklist = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'source': source,
    'category': category,
    'publishedDate': publishedDate,
    'sourceUrl': sourceUrl,
    'tags': tags,
    'fullContent': fullContent,
    'readTime': readTime,
    'keyTakeaways': keyTakeaways,
    'technicalSpecs': technicalSpecs,
    'contributorChecklist': contributorChecklist,
  };

  factory MicrostockNewsArticle.fromJson(Map<String, dynamic> json) =>
      MicrostockNewsArticle(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        source: json['source'] as String? ?? '',
        category: json['category'] as String? ?? '',
        publishedDate: json['publishedDate'] as String? ?? '',
        sourceUrl: json['sourceUrl'] as String? ?? '',
        tags:
            (json['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        fullContent:
            json['fullContent'] as String? ?? json['summary'] as String? ?? '',
        readTime: json['readTime'] as String? ?? '3 min read',
        keyTakeaways: json['keyTakeaways'] as String? ?? '',
        technicalSpecs:
            (json['technicalSpecs'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        contributorChecklist:
            (json['contributorChecklist'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

/// Service managing microstock hybrid news (RSS-to-JSON + Reddit Intel).
class MicrostockNewsService {
  static const String _cacheKey = 'nra_microstock_news_cache_v3';
  static const String _lastFetchedKey = 'nra_microstock_news_last_fetched_v3';

  @visibleForTesting
  static Future<List<MicrostockNewsArticle>> Function()? mockFetchHandler;

  @visibleForTesting
  static Future<String> Function(Uri uri)? customHttpGet;

  /// Loads cached news or fetches online if connection is active.
  static Future<List<MicrostockNewsArticle>> loadNews({
    bool forceRefresh = false,
  }) async {
    final isOnline = ConnectivityService.instance.isOnline.value;
    if (forceRefresh && isOnline) return await fetchAndCacheNews();

    final cached = await getCachedNews();
    if (cached.isNotEmpty && !forceRefresh) return cached;

    if (isOnline) {
      try {
        final online = await fetchAndCacheNews();
        if (online.isNotEmpty) return online;
      } catch (_) {
        if (cached.isNotEmpty) return cached;
      }
    }
    if (cached.isNotEmpty) return cached;

    final seed = getSeedArticles();
    await saveNewsToCache(seed);
    return seed;
  }

  /// Fetches from hybrid remote sources and writes to local cache.
  static Future<List<MicrostockNewsArticle>> fetchAndCacheNews() async {
    if (mockFetchHandler != null) {
      final mocked = await mockFetchHandler!();
      await saveNewsToCache(mocked);
      return mocked;
    }

    final hybrid = await fetchHybridNews();
    final articles = hybrid.isNotEmpty ? hybrid : getSeedArticles();
    await saveNewsToCache(articles);
    return articles;
  }

  /// Fetches from RSS-to-JSON endpoint and Reddit Public API in parallel.
  static Future<List<MicrostockNewsArticle>> fetchHybridNews() async {
    final results = <MicrostockNewsArticle>[];
    try {
      final futures = await Future.wait([
        _fetchGoogleNewsRss(),
        _fetchRss2Json(),
        _fetchReddit('microstock'),
        _fetchReddit('stockphotography'),
      ]);
      for (final list in futures) {
        results.addAll(list);
      }
      results.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
    } catch (_) {}
    return results;
  }

  static Future<List<MicrostockNewsArticle>> _fetchGoogleNewsRss() async {
    try {
      final uri = Uri.parse(
        'https://news.google.com/rss/search?q=microstock+contributor+OR+shutterstock+contributor&hl=en-US&gl=US&ceid=US:en',
      );
      final raw = customHttpGet != null
          ? await customHttpGet!(uri)
          : await _defaultHttpGet(uri);
      if (raw.isEmpty) return [];
      return parseRssXmlFeed(raw);
    } catch (_) {}
    return [];
  }

  /// Parses standard RSS 2.0 XML channel items into MicrostockNewsArticle models.
  static List<MicrostockNewsArticle> parseRssXmlFeed(String xml) {
    final articles = <MicrostockNewsArticle>[];
    final itemRegex = RegExp(
      r'<item>(.*?)<\/item>',
      dotAll: true,
      caseSensitive: false,
    );
    final titleRegex = RegExp(
      r'<title>(.*?)<\/title>',
      dotAll: true,
      caseSensitive: false,
    );
    final linkRegex = RegExp(
      r'<link>(.*?)<\/link>',
      dotAll: true,
      caseSensitive: false,
    );
    final descRegex = RegExp(
      r'<description>(.*?)<\/description>',
      dotAll: true,
      caseSensitive: false,
    );
    final pubRegex = RegExp(
      r'<pubDate>(.*?)<\/pubDate>',
      dotAll: true,
      caseSensitive: false,
    );
    final sourceRegex = RegExp(
      r'<source[^>]*>(.*?)<\/source>',
      dotAll: true,
      caseSensitive: false,
    );

    for (final match in itemRegex.allMatches(xml)) {
      final itemBlock = match.group(1) ?? '';
      final titleMatch = titleRegex.firstMatch(itemBlock);
      final linkMatch = linkRegex.firstMatch(itemBlock);
      final descMatch = descRegex.firstMatch(itemBlock);
      final pubMatch = pubRegex.firstMatch(itemBlock);
      final sourceMatch = sourceRegex.firstMatch(itemBlock);

      final title = parseRssContent(titleMatch?.group(1) ?? '');
      if (title.isEmpty) continue;
      final link = (linkMatch?.group(1) ?? '').trim();
      final desc = parseRssContent(descMatch?.group(1) ?? '');
      final pubRaw = (pubMatch?.group(1) ?? '').trim();
      final source = (sourceMatch?.group(1) ?? 'Google News Intel').trim();

      articles.add(
        MicrostockNewsArticle(
          id: 'gn-${title.hashCode}',
          title: title,
          summary: desc.length > 150 ? '${desc.substring(0, 150)}...' : desc,
          source: source,
          category: 'MARKET INTEL',
          publishedDate: pubRaw.isNotEmpty ? pubRaw : '2026-11-03',
          sourceUrl: link.isNotEmpty ? link : 'https://news.google.com',
          tags: ['#Microstock', '#MarketIntel', '#$source'],
          readTime: '3 min read',
          keyTakeaways:
              'Market trend movement, contributor payout policies, and platform guidelines.',
          technicalSpecs: const [
            'Resolution: 4K UHD & 1080p',
            'Cadence: 30 / 60 FPS CFR',
            'Color: Rec.709 compliant',
          ],
          contributorChecklist: const [
            'Adhere to commercial stock standards.',
            'Maintain pristine metadata tagging.',
          ],
          fullContent: desc.isNotEmpty ? desc : title,
        ),
      );
    }
    return articles;
  }

  static Future<List<MicrostockNewsArticle>> _fetchRss2Json() async {
    try {
      final uri = Uri.parse(
        'https://api.rss2json.com/v1/api.json?rss_url=https://blog.shutterstock.com/feed/',
      );
      final raw = customHttpGet != null
          ? await customHttpGet!(uri)
          : await _defaultHttpGet(uri);
      if (raw.isEmpty) return [];
      final data = jsonDecode(raw);
      if (data['status'] == 'ok' && data['items'] is List) {
        return (data['items'] as List)
            .map((i) => _parseRssJsonItem(i as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static MicrostockNewsArticle _parseRssJsonItem(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'Untitled Agency Brief';
    final desc = parseRssContent(item['description'] as String? ?? '');
    final content = parseRssContent(item['content'] as String? ?? desc);
    final pub = (item['pubDate'] as String? ?? '').split(' ').first;
    final cats =
        (item['categories'] as List<dynamic>?)?.map((c) => '#$c').toList() ??
        ['#Shutterstock'];

    return MicrostockNewsArticle(
      id: 'rss-${title.hashCode}',
      title: title,
      summary: desc.length > 150 ? '${desc.substring(0, 150)}...' : desc,
      source: 'Shutterstock Official',
      category: 'REQUIREMENTS',
      publishedDate: pub.isNotEmpty ? pub : '2026-10-28',
      sourceUrl: item['link'] as String? ?? 'https://shutterstock.com/blog',
      tags: cats,
      readTime: '3 min read',
      keyTakeaways:
          'Strict 4K/FHD requirements, CFR cadence, and clean Rec.709 color curve compliance.',
      technicalSpecs: const [
        'Resolution: 4K UHD (3840x2160) & 1080p',
        'Frame Rate: CFR 30.00 / 60.00 FPS',
        'Encoding: H.264/H.265 with faststart',
      ],
      contributorChecklist: const [
        'Verify Constant Frame Rate mode.',
        'Sanitize metadata and remove trademark brands.',
      ],
      fullContent: content.isNotEmpty ? content : desc,
    );
  }

  static Future<List<MicrostockNewsArticle>> _fetchReddit(String sub) async {
    try {
      final uri = Uri.parse('https://www.reddit.com/r/$sub/hot.json?limit=5');
      final raw = customHttpGet != null
          ? await customHttpGet!(uri)
          : await _defaultHttpGet(uri);
      if (raw.isEmpty) return [];
      final data = jsonDecode(raw);
      final children = data['data']?['children'] as List<dynamic>?;
      if (children != null) {
        return children
            .map(
              (c) => _parseRedditPost(c['data'] as Map<String, dynamic>, sub),
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static MicrostockNewsArticle _parseRedditPost(
    Map<String, dynamic> data,
    String sub,
  ) {
    final title = data['title'] as String? ?? '';
    final selftext = data['selftext'] as String? ?? '';
    final permalink = data['permalink'] as String? ?? '';
    final createdUtc = (data['created_utc'] as num? ?? 0).toInt();
    final dateStr = DateTime.fromMillisecondsSinceEpoch(
      createdUtc * 1000,
    ).toIso8601String().split('T').first;

    return MicrostockNewsArticle(
      id: 'reddit-${data['id'] ?? title.hashCode}',
      title: title,
      summary: selftext.length > 150
          ? '${selftext.substring(0, 150)}...'
          : (selftext.isNotEmpty ? selftext : title),
      source: 'Reddit Community Discussion',
      category: 'COMMUNITY',
      publishedDate: dateStr,
      sourceUrl: 'https://reddit.com$permalink',
      tags: ['#Reddit', '#MicrostockCommunity', '#$sub'],
      readTime: '4 min read',
      keyTakeaways:
          'Community real-world experiences, rejection patterns, and evasion guidelines.',
      technicalSpecs: const [
        'Micro-Crop: 2% - 5% subtle crop',
        'Noise Dither: Temporal Gaussian noise',
        'Framerate: Clean 30 FPS CFR sync',
      ],
      contributorChecklist: const [
        'Strip GPS and camera device signatures.',
        'Test sample clip before mass portfolio upload.',
      ],
      fullContent: selftext.isNotEmpty ? selftext : title,
    );
  }

  static Future<String> _defaultHttpGet(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final req = await client.getUrl(uri);
      req.headers.set(
        'User-Agent',
        'NRA-Video-Uniquifier/1.0 (Flutter; Mobile)',
      );
      final res = await req.close().timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return await res.transform(utf8.decoder).join();
      }
    } catch (_) {
    } finally {
      client.close();
    }
    return '';
  }

  /// Parses RSS/Atom entry content, extracting clean markdown text from CDATA or HTML.
  static String parseRssContent(String rawXml) {
    if (rawXml.isEmpty) return '';
    final contentRegex = RegExp(
      r'<content(?::encoded)?>(?:<!\\[CDATA\\[)?(.*?)(?:\\]\\]>)?<\\/content(?::encoded)?>',
      dotAll: true,
      caseSensitive: false,
    );
    final match = contentRegex.firstMatch(rawXml);
    final rawText = match != null ? match.group(1) ?? '' : rawXml;
    return rawText
        .replaceAll(RegExp(r'<br\\s*\\/?>', caseSensitive: false), '\\n')
        .replaceAll(RegExp(r'<\\/p>', caseSensitive: false), '\\n\\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .trim();
  }

  /// Retrieves articles from local SharedPreferences cache.
  static Future<List<MicrostockNewsArticle>> getCachedNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded
            .map(
              (e) => MicrostockNewsArticle.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Writes articles to local persistent cache.
  static Future<void> saveNewsToCache(
    List<MicrostockNewsArticle> articles,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(articles.map((a) => a.toJson()).toList());
      await prefs.setString(_cacheKey, encoded);
      await prefs.setString(_lastFetchedKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  /// Gets timestamp of last successful news synchronization.
  static Future<String?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastFetchedKey);
    } catch (_) {
      return null;
    }
  }

  /// Baseline seed articles.
  static List<MicrostockNewsArticle> getSeedArticles() =>
      MicrostockSeedData.getSeedArticles();
}
