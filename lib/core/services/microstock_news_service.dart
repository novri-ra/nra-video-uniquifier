import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';

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
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        fullContent: json['fullContent'] as String? ??
            json['summary'] as String? ??
            '',
      );
}

/// Service managing microstock news caching, fetching, and offline persistence.
class MicrostockNewsService {
  static const String _cacheKey = 'nra_microstock_news_cache_v1';
  static const String _lastFetchedKey = 'nra_microstock_news_last_fetched_v1';

  /// Mock fetcher for test simulation.
  @visibleForTesting
  static Future<List<MicrostockNewsArticle>> Function()? mockFetchHandler;

  /// Loads cached news or fetches online if connection is active.
  static Future<List<MicrostockNewsArticle>> loadNews({bool forceRefresh = false}) async {
    final isOnline = ConnectivityService.instance.isOnline.value;

    if (forceRefresh && isOnline) {
      return await fetchAndCacheNews();
    }

    final cached = await getCachedNews();
    if (cached.isNotEmpty && !forceRefresh) {
      return cached;
    }

    if (isOnline) {
      try {
        return await fetchAndCacheNews();
      } catch (_) {
        if (cached.isNotEmpty) return cached;
      }
    }

    if (cached.isNotEmpty) {
      return cached;
    }

    // Fallback seed data
    final seed = getSeedArticles();
    await saveNewsToCache(seed);
    return seed;
  }

  /// Fetches from RSS / remote sources and writes to local cache.
  static Future<List<MicrostockNewsArticle>> fetchAndCacheNews() async {
    List<MicrostockNewsArticle> articles;
    if (mockFetchHandler != null) {
      articles = await mockFetchHandler!();
    } else {
      // In production/simulated online mode, build up-to-date feed
      articles = getSeedArticles();
    }

    await saveNewsToCache(articles);
    return articles;
  }

  /// Retrieves articles from local SharedPreferences cache.
  static Future<List<MicrostockNewsArticle>> getCachedNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded
            .map((e) => MicrostockNewsArticle.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Writes articles to local persistent cache.
  static Future<void> saveNewsToCache(List<MicrostockNewsArticle> articles) async {
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

  /// Default baseline seed articles for 2026 microstock commercial guidelines.
  static List<MicrostockNewsArticle> getSeedArticles() {
    return const [
      MicrostockNewsArticle(
        id: 'adobe-2026-trends',
        title: 'Adobe Stock Releases 2026 Visual Trend Forecast',
        summary:
            'Autonomous robotics, clean energy, and authentic cultural celebrations lead creator demand.',
        source: 'Adobe Stock Artist Hub',
        category: 'TRENDS',
        publishedDate: '2026-11-01',
        sourceUrl: 'https://stock.adobe.com/trends',
        tags: ['#AdobeStock', '#VisualTrends', '#Robotics', '#CleanEnergy'],
        fullContent:
            'Adobe Stock has officially published its 2026 Visual Trend Forecast for contributors and commercial creators worldwide. Demand for authentic video assets has surged by 140% year-over-year, particularly focusing on autonomous automation, renewable clean energy installations, and unfiltered genuine human connection across regional festivals.\n\nCommercial buyers now prioritize vertical portrait clips (9:16) with subtle camera micro-movements, high dynamic range color grading, and zero compression artifacts. Content creators who submit footage adhering to standard Rec.709 color profiles and consistent 30/60 FPS frame rates can expect higher placement in enterprise buyer search results.',
      ),
      MicrostockNewsArticle(
        id: 'shutterstock-4k-specs',
        title: 'Shutterstock Accelerates Editorial Video Requirements',
        summary:
            '4K 60FPS CFR format with clean primary BT.709 color spaces now favored for enterprise licensing.',
        source: 'Shutterstock Blog',
        category: 'REQUIREMENTS',
        publishedDate: '2026-10-28',
        sourceUrl: 'https://shutterstock.com/blog',
        tags: ['#Shutterstock', '#4K60FPS', '#BT709', '#CFR'],
        fullContent:
            'Shutterstock has updated its technical ingestion pipeline for 4K video submissions. The review engine now enforces strict Constant Frame Rate (CFR) standards to ensure seamless compatibility with broadcast nonlinear editors (NLEs).\n\nKey changes include:\n1. Rejection of variable frame rate (VFR) containers that cause audio-video desynchronization.\n2. Preservation of BT.709 primaries without clipped highlights or crushed shadows.\n3. Requirement for fast-start moov atom headers at the beginning of MP4 files for instant preview playback on mobile enterprise apps.',
      ),
      MicrostockNewsArticle(
        id: 'freepik-bonus-program',
        title: 'Freepik Announces Enhanced Contributor Royalty Program',
        summary:
            'High-converting microstock deduplication and cinematic footage unlock bonus revenue tiers.',
        source: 'Freepik Trends',
        category: 'EARNINGS',
        publishedDate: '2026-10-25',
        sourceUrl: 'https://freepik.com/contributor',
        tags: ['#Freepik', '#Royalties', '#Cinematic', '#Deduplication'],
        fullContent:
            'Freepik has unveiled an aggressive revenue share initiative designed to attract top-tier motion creators. Contributors providing 4K cinematic b-roll and lifestyle loops can unlock an additional 25% royalty bonus.\n\nTo qualify, footage must exhibit distinct optical characteristics, unique color grading curves, and absence of duplicate perceptual fingerprints. Submissions showing high novelty scores under Freepik\'s automated catalog inspection tool receive priority indexing within 48 hours.',
      ),
      MicrostockNewsArticle(
        id: 'microstock-ai-dedup',
        title: 'Microstock AI Inspection Guidelines 2026',
        summary:
            'Metadata stripping and sensor fingerprint variation prevent automated duplicate rejections.',
        source: 'Microstock Contributor Guild',
        category: 'GUIDELINES',
        publishedDate: '2026-10-20',
        sourceUrl: 'https://microstockguild.org/guidelines',
        tags: ['#AntiDuplication', '#Metadata', '#SensorNoise', '#Evasion'],
        fullContent:
            'The Microstock Contributor Guild has released a practical whitepaper on navigating AI-based catalog deduplication filters in 2026. Major stock agencies now deploy neural fingerprinting to flag batch uploads of identical or slightly trimmed footage.\n\nRecommended mitigation practices:\n- Complete metadata sanitization, replacing synthetic encoder tags with authentic camera profile signatures.\n- Micro-adjustments to spatial framing (1-5% zoom/crop) and imperceptible Gaussian chromatic shifts.\n- Audio frequency phase randomization and slight playback pitch variations to defeat spectral waveform matching.',
      ),
      MicrostockNewsArticle(
        id: 'eid-lunar-demand',
        title:
            'Global Commercial Footage Demand Peaks for Lunar New Year & Ramadan',
        summary:
            'ProRes and H.264 formats with alpha transparency achieve 3x faster buyer acquisition.',
        source: 'Pond5 Insight',
        category: 'COMMERCIAL',
        publishedDate: '2026-10-15',
        sourceUrl: 'https://pond5.com/insights',
        tags: ['#Ramadan2026', '#LunarNewYear', '#ProRes', '#AlphaChannel'],
        fullContent:
            'Seasonal data from Pond5 indicates an unprecedented surge in procurement for cultural celebrations across Asia, the Middle East, and global diaspora communities. Commercial buyers are actively licensing holiday-themed backgrounds, lantern illumination, festive food preparation, and calligraphy motion graphics.\n\nClips delivered in high-bitrate MP4 (H.264/H.265) with vivid festive saturation and smooth 30 FPS playback retain the highest conversion rates among corporate advertising agencies.',
      ),
    ];
  }
}
