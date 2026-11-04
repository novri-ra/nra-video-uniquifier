import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/microstock/services/article_image_service.dart';
import '../../features/microstock/utils/html_sanitizer.dart';
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
  final String? imageUrl;
  final String? localImagePath;
  final String? author;
  final DateTime? cachedAt;

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
    this.imageUrl,
    this.localImagePath,
    this.author,
    this.cachedAt,
  });

  MicrostockNewsArticle copyWith({
    String? id,
    String? title,
    String? summary,
    String? source,
    String? category,
    String? publishedDate,
    String? sourceUrl,
    List<String>? tags,
    String? fullContent,
    String? readTime,
    String? keyTakeaways,
    List<String>? technicalSpecs,
    List<String>? contributorChecklist,
    String? imageUrl,
    String? localImagePath,
    String? author,
    DateTime? cachedAt,
  }) => MicrostockNewsArticle(
    id: id ?? this.id,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    source: source ?? this.source,
    category: category ?? this.category,
    publishedDate: publishedDate ?? this.publishedDate,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    tags: tags ?? this.tags,
    fullContent: fullContent ?? this.fullContent,
    readTime: readTime ?? this.readTime,
    keyTakeaways: keyTakeaways ?? this.keyTakeaways,
    technicalSpecs: technicalSpecs ?? this.technicalSpecs,
    contributorChecklist: contributorChecklist ?? this.contributorChecklist,
    imageUrl: imageUrl ?? this.imageUrl,
    localImagePath: localImagePath ?? this.localImagePath,
    author: author ?? this.author,
    cachedAt: cachedAt ?? this.cachedAt,
  );

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
    'imageUrl': imageUrl,
    'localImagePath': localImagePath,
    'author': author,
    'cachedAt': cachedAt?.toIso8601String(),
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
        imageUrl: json['imageUrl'] as String?,
        localImagePath: json['localImagePath'] as String?,
        author: json['author'] as String?,
        cachedAt: json['cachedAt'] != null
            ? DateTime.tryParse(json['cachedAt'] as String)
            : null,
      );
}

/// Service managing microstock hybrid news (Direct Photography RSS + Google News + Shutterstock + Reddit Intel).
class MicrostockNewsService {
  static const String _cacheKey = 'nra_microstock_news_cache_v3';
  static const String _lastFetchedKey = 'nra_microstock_news_last_fetched_v3';
  static const Duration _cacheTtl = Duration(hours: 1);
  static const int _maxCacheEntries = 100;

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
    if (cached.isNotEmpty && !forceRefresh) {
      // Validate 1-hour TTL: auto-refresh in background if expired and online
      final lastSyncStr = await getLastSyncTime();
      if (lastSyncStr != null && isOnline) {
        final lastSync = DateTime.tryParse(lastSyncStr);
        if (lastSync != null &&
            DateTime.now().difference(lastSync) > _cacheTtl) {
          unawaited(
            fetchAndCacheNews().catchError((_) => <MicrostockNewsArticle>[]),
          );
        }
      }
      triggerBackgroundDownload(cached);
      return cached;
    }

    if (isOnline) {
      try {
        final online = await fetchAndCacheNews();
        if (online.isNotEmpty) return online;
      } catch (_) {
        if (cached.isNotEmpty) {
          triggerBackgroundDownload(cached);
          return cached;
        }
      }
    }
    if (cached.isNotEmpty) {
      triggerBackgroundDownload(cached);
      return cached;
    }

    final seed = getSeedArticles();
    await saveNewsToCache(seed);
    return seed;
  }

  /// Fetches from hybrid remote sources and writes to local cache.
  static Future<List<MicrostockNewsArticle>> fetchAndCacheNews() async {
    if (mockFetchHandler != null) {
      final mocked = await mockFetchHandler!();
      await saveNewsToCache(mocked);
      triggerBackgroundDownload(mocked);
      return mocked;
    }

    final hybrid = await fetchHybridNews();
    final articles = hybrid.isNotEmpty ? hybrid : getSeedArticles();
    await saveNewsToCache(articles);
    triggerBackgroundDownload(articles);
    return articles;
  }

  /// Fetches from direct RSS feeds, Google News RSS, RSS-to-JSON endpoint, and Reddit in parallel.
  static Future<List<MicrostockNewsArticle>> fetchHybridNews() async {
    final results = <MicrostockNewsArticle>[];
    try {
      final futures = await Future.wait([
        _fetchDirectRss('https://petapixel.com/feed/', 'PetaPixel'),
        _fetchDirectRss('https://fstoppers.com/feed', 'Fstoppers'),
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

  static Future<List<MicrostockNewsArticle>> _fetchDirectRss(
    String url,
    String defaultSource,
  ) async {
    try {
      final uri = Uri.parse(url);
      final raw = customHttpGet != null
          ? await customHttpGet!(uri)
          : await _defaultHttpGet(uri);
      if (raw.isEmpty) return [];
      return parseRssXmlFeed(raw, defaultSource: defaultSource);
    } catch (_) {}
    return [];
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
      return parseRssXmlFeed(raw, defaultSource: 'Google News Intel');
    } catch (_) {}
    return [];
  }

  /// Parses standard RSS 2.0 XML channel items into MicrostockNewsArticle models.
  static List<MicrostockNewsArticle> parseRssXmlFeed(
    String xml, {
    String defaultSource = 'Photography Intel',
  }) {
    if (xml.isEmpty) return [];
    final articles = <MicrostockNewsArticle>[];

    final itemRegex = RegExp(
      r'<item\b[^>]*>(.*?)<\/item>',
      dotAll: true,
      caseSensitive: false,
    );

    for (final match in itemRegex.allMatches(xml)) {
      final itemBlock = match.group(1) ?? '';
      final article = _parseRssItemBlock(itemBlock, defaultSource);
      if (article != null) {
        articles.add(article);
      }
    }
    return articles;
  }

  static MicrostockNewsArticle? _parseRssItemBlock(
    String itemBlock,
    String defaultSource,
  ) {
    // 1. Title
    final rawTitle = _extractXmlTag(itemBlock, r'title');
    final title = HtmlSanitizer.clean(rawTitle);
    if (title.isEmpty) return null;

    // 2. Link
    final link = _extractLink(itemBlock);

    // 3. Author (<dc:creator> or <author>)
    final authorRaw = _extractXmlTag(itemBlock, r'(?:dc:creator|author)');
    final author = HtmlSanitizer.clean(authorRaw);

    // 4. Publication date (<pubDate> or <dc:date>)
    final pubRaw = _extractXmlTag(itemBlock, r'(?:pubDate|dc:date)').trim();

    // 5. Source (<source>)
    final sourceMatch = _extractXmlTag(itemBlock, r'source');
    final source = sourceMatch.isNotEmpty
        ? HtmlSanitizer.clean(sourceMatch)
        : defaultSource;

    // 6. Categories (<category>)
    final categoryRegex = RegExp(
      r'<category\b[^>]*>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?<\/category>',
      dotAll: true,
      caseSensitive: false,
    );
    final rawCategories = categoryRegex
        .allMatches(itemBlock)
        .map((m) => HtmlSanitizer.clean(m.group(1) ?? ''))
        .where((c) => c.isNotEmpty)
        .toList();

    final category = rawCategories.isNotEmpty
        ? rawCategories.first.toUpperCase()
        : 'MARKET INTEL';
    final tags = rawCategories.isNotEmpty
        ? rawCategories
              .take(5)
              .map((c) => '#${c.replaceAll(RegExp(r'\s+'), '')}')
              .toList()
        : ['#Microstock', '#MarketIntel', '#$source'];

    // 7. Content & Summary (<content:encoded> or <description>)
    final rawContent = _extractXmlTag(
      itemBlock,
      r'(?:content:encoded|encoded)',
    );
    final rawDesc = _extractXmlTag(itemBlock, r'description');

    final cleanContent = HtmlSanitizer.clean(rawContent);
    final cleanDesc = HtmlSanitizer.clean(rawDesc);

    final fullContent = cleanContent.isNotEmpty
        ? cleanContent
        : (cleanDesc.isNotEmpty ? cleanDesc : title);

    final summaryBase = cleanDesc.isNotEmpty ? cleanDesc : fullContent;
    final summary = _truncateSummary(summaryBase);

    // 8. Image URL (<media:content>, <enclosure>, or <img> in content)
    final imageUrl = _extractImageUrl(
      itemBlock,
      rawContent.isNotEmpty ? rawContent : rawDesc,
    );

    return MicrostockNewsArticle(
      id: 'rss-${title.hashCode.abs()}',
      title: title,
      summary: summary,
      source: source,
      category: category,
      publishedDate: pubRaw.isNotEmpty ? pubRaw : '2026-11-03',
      sourceUrl: link.isNotEmpty ? link : 'https://news.google.com',
      tags: tags,
      readTime: _calculateReadTime(fullContent),
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
      fullContent: fullContent,
      imageUrl: imageUrl,
      author: author.isNotEmpty ? author : null,
      cachedAt: DateTime.now(),
    );
  }

  static String _extractXmlTag(String xml, String tagName) {
    final regex = RegExp(
      '<$tagName\\b[^>]*>(?:<!\\[CDATA\\[)?(.*?)(?:\\]\\]>)?<\\/$tagName>',
      dotAll: true,
      caseSensitive: false,
    );
    final match = regex.firstMatch(xml);
    return match?.group(1) ?? '';
  }

  static String _extractLink(String xml) {
    final linkRegex = RegExp(
      r'<link\b[^>]*>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?<\/link>',
      dotAll: true,
      caseSensitive: false,
    );
    final match = linkRegex.firstMatch(xml);
    final textLink = match?.group(1)?.trim();
    if (textLink != null && textLink.isNotEmpty) return textLink;

    final hrefRegex = RegExp(
      r'<link[^>]+href=["'
      "'"
      r']([^"'
      "'"
      r']+)["'
      "'"
      r']',
      caseSensitive: false,
    );
    final hrefMatch = hrefRegex.firstMatch(xml);
    return hrefMatch?.group(1)?.trim() ?? '';
  }

  static String? _extractImageUrl(String xml, String htmlContent) {
    final mediaMatch = RegExp(
      r'<media:(?:content|thumbnail)[^>]+url=["'
      "'"
      r']([^"'
      "'"
      r']+)["'
      "'"
      r']',
      caseSensitive: false,
    ).firstMatch(xml);
    if (mediaMatch != null) return mediaMatch.group(1);

    final enclosureMatch = RegExp(
      r'<enclosure[^>]+url=["'
      "'"
      r']([^"'
      "'"
      r']+)["'
      "'"
      r']',
      caseSensitive: false,
    ).firstMatch(xml);
    if (enclosureMatch != null) return enclosureMatch.group(1);

    if (htmlContent.isNotEmpty) {
      try {
        final frag = html_parser.parseFragment(htmlContent);
        final src = frag.querySelector('img')?.attributes['src'];
        if (src != null && src.isNotEmpty) return src;
      } catch (_) {}
    }
    return null;
  }

  static String _truncateSummary(String text, {int maxLength = 150}) {
    if (text.length <= maxLength) return text;
    final truncated = text.substring(0, maxLength);
    final lastSpace = truncated.lastIndexOf(' ');
    return lastSpace > 100
        ? '${truncated.substring(0, lastSpace)}...'
        : '$truncated...';
  }

  static String _calculateReadTime(String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final minutes = (words / 200).ceil().clamp(1, 15);
    return '$minutes min read';
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
    final author = item['author'] as String?;
    final imageUrl =
        item['thumbnail'] as String? ??
        (item['enclosure'] is Map
            ? (item['enclosure'] as Map)['link'] as String?
            : null);

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
      imageUrl: imageUrl,
      author: author,
      cachedAt: DateTime.now(),
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
    final author = data['author'] as String?;
    final thumbnail = data['thumbnail'] as String?;
    final imageUrl = (thumbnail != null && thumbnail.startsWith('http'))
        ? thumbnail
        : null;

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
      author: author,
      imageUrl: imageUrl,
      cachedAt: DateTime.now(),
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
  static String parseRssContent(String rawXml) => HtmlSanitizer.clean(rawXml);

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

  /// Writes articles to local persistent cache using append-merge deduplication.
  static Future<void> saveNewsToCache(
    List<MicrostockNewsArticle> articles,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Read existing cached articles for append-merge
      final existing = await getCachedNews();

      final mergedMap = <String, MicrostockNewsArticle>{};

      // 1. Seed with existing cached items
      for (final a in existing) {
        final key = a.sourceUrl.isNotEmpty ? a.sourceUrl : a.id;
        if (key.isNotEmpty) {
          mergedMap[key] = a;
        }
      }

      // 2. Overlay / append incoming articles
      for (final a in articles) {
        final key = a.sourceUrl.isNotEmpty ? a.sourceUrl : a.id;
        if (key.isNotEmpty) {
          final existingArticle = mergedMap[key];
          var updated = a.cachedAt == null ? a.copyWith(cachedAt: now) : a;
          if (updated.localImagePath == null &&
              existingArticle?.localImagePath != null) {
            updated = updated.copyWith(
              localImagePath: existingArticle!.localImagePath,
            );
          }
          mergedMap[key] = updated;
        }
      }

      // 3. Sort by publishedDate descending
      final sortedList = mergedMap.values.toList()
        ..sort((a, b) => b.publishedDate.compareTo(a.publishedDate));

      // 4. Cap at 100 most recent articles
      final cappedList = sortedList.take(_maxCacheEntries).toList();

      final encoded = jsonEncode(cappedList.map((a) => a.toJson()).toList());
      await prefs.setString(_cacheKey, encoded);
      await prefs.setString(_lastFetchedKey, now.toIso8601String());
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

  /// Triggers non-blocking background image download and WebP conversion for articles with remote image URLs.
  static void triggerBackgroundDownload(List<MicrostockNewsArticle> articles) {
    unawaited(_downloadImagesForArticles(articles).catchError((_) {}));
  }

  static Future<void> _downloadImagesForArticles(
    List<MicrostockNewsArticle> articles,
  ) async {
    final targets = articles
        .where(
          (a) =>
              a.imageUrl != null &&
              a.imageUrl!.startsWith('http') &&
              (a.localImagePath == null || a.localImagePath!.isEmpty),
        )
        .toList();

    if (targets.isEmpty) return;

    bool anyUpdated = false;
    final cached = await getCachedNews();
    final cacheMap = {
      for (final a in cached) (a.sourceUrl.isNotEmpty ? a.sourceUrl : a.id): a,
    };

    for (final article in targets) {
      final key = article.sourceUrl.isNotEmpty ? article.sourceUrl : article.id;
      final current = cacheMap[key] ?? article;
      if (current.localImagePath != null &&
          current.localImagePath!.isNotEmpty) {
        continue;
      }

      final localPath = await ArticleImageService.downloadAndCacheImage(
        current.imageUrl!,
        current.id,
      );
      if (localPath != null && localPath.isNotEmpty) {
        cacheMap[key] = current.copyWith(localImagePath: localPath);
        anyUpdated = true;
      }
    }

    if (anyUpdated) {
      await saveNewsToCache(cacheMap.values.toList());
    }
  }

  /// Baseline seed articles.
  static List<MicrostockNewsArticle> getSeedArticles() =>
      MicrostockSeedData.getSeedArticles();
}
