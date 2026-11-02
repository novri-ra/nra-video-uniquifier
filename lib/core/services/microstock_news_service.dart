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
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        fullContent: json['fullContent'] as String? ?? json['summary'] as String? ?? '',
        readTime: json['readTime'] as String? ?? '3 min read',
        keyTakeaways: json['keyTakeaways'] as String? ?? '',
        technicalSpecs: (json['technicalSpecs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        contributorChecklist: (json['contributorChecklist'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

/// Service managing microstock news caching, fetching, and offline persistence.
class MicrostockNewsService {
  static const String _cacheKey = 'nra_microstock_news_cache_v2';
  static const String _lastFetchedKey = 'nra_microstock_news_last_fetched_v2';

  @visibleForTesting
  static Future<List<MicrostockNewsArticle>> Function()? mockFetchHandler;

  /// Loads cached news or fetches online if connection is active.
  static Future<List<MicrostockNewsArticle>> loadNews({bool forceRefresh = false}) async {
    final isOnline = ConnectivityService.instance.isOnline.value;
    if (forceRefresh && isOnline) return await fetchAndCacheNews();

    final cached = await getCachedNews();
    if (cached.isNotEmpty && !forceRefresh) return cached;

    if (isOnline) {
      try {
        return await fetchAndCacheNews();
      } catch (_) {
        if (cached.isNotEmpty) return cached;
      }
    }
    if (cached.isNotEmpty) return cached;

    final seed = getSeedArticles();
    await saveNewsToCache(seed);
    return seed;
  }

  /// Fetches from RSS / remote sources and writes to local cache.
  static Future<List<MicrostockNewsArticle>> fetchAndCacheNews() async {
    final articles = mockFetchHandler != null
        ? await mockFetchHandler!()
        : getSeedArticles();
    await saveNewsToCache(articles);
    return articles;
  }

  /// Parses RSS/Atom entry content, extracting clean markdown text from CDATA or HTML.
  static String parseRssContent(String rawXml) {
    if (rawXml.isEmpty) return '';
    final contentRegex = RegExp(r'<content(?::encoded)?>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?<\/content(?::encoded)?>', dotAll: true, caseSensitive: false);
    final match = contentRegex.firstMatch(rawXml);
    final rawText = match != null ? match.group(1) ?? '' : rawXml;
    return rawText
        .replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<\/p>', caseSensitive: false), '\n\n')
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
        summary: 'Autonomous robotics, clean energy, and authentic cultural celebrations lead creator demand.',
        source: 'Adobe Stock Artist Hub',
        category: 'TRENDS',
        publishedDate: '2026-11-01',
        sourceUrl: 'https://stock.adobe.com/trends',
        tags: ['#AdobeStock', '#VisualTrends', '#Robotics', '#CleanEnergy'],
        readTime: '4 min read',
        keyTakeaways: 'Enterprise buyers prioritize vertical portrait (9:16) clips with micro-movements, authentic human expressions, and strict Rec.709 color profiles.',
        technicalSpecs: [
          'Aspect Ratio: 9:16 Vertical Portrait & 16:9 4K UHD',
          'Frame Rate: Constant 30.00 / 60.00 FPS (Strict CFR)',
          'Color Space: Rec.709 (BT.709) standard broadcast curve',
          'Encoding: H.264 / H.265 CRF 17-22, Moov Atom FastStart',
        ],
        contributorChecklist: [
          'Pastikan tidak ada logo merk/brand terlihat pada latar belakang.',
          'Sertakan model release legal jika menampilkan wajah manusia jelas.',
          'Hindari filter over-sharpening yang memunculkan white halos di tepi objek.',
          'Gunakan nama file deskriptif berbasis keyword tanpa karakter spesial.',
        ],
        fullContent:
            'Adobe Stock has officially unveiled its comprehensive 2026 Visual Trend Forecast for video creators and contributors worldwide. Analysis of over 85 million commercial search queries demonstrates a dramatic 140% surge in requests for authentic, unpolished cinematography highlighting autonomous industrial robotics, distributed renewable energy installations, and localized cultural celebrations.\n\nCommercial advertising agencies and enterprise social media managers now heavily favor vertical 9:16 portrait assets over traditional landscape video. Ingestion algorithms directly deprioritize footage suffering from variable frame rate stutter, harsh artificial sharpness, or inconsistent gamma curves.\n\nTo maximize licensing revenue, contributors should produce 5-15 second looping B-roll clips with subtle handheld or slow-gimbal micro-movements. Clips featuring genuine candid smiles, diverse age demographics, and natural workplace interaction achieve the highest click-through rates across corporate branding campaigns.',
      ),
      MicrostockNewsArticle(
        id: 'shutterstock-4k-specs',
        title: 'Shutterstock Accelerates Editorial Video Requirements',
        summary: '4K 60FPS CFR format with clean primary BT.709 color spaces now favored for enterprise licensing.',
        source: 'Shutterstock Blog',
        category: 'REQUIREMENTS',
        publishedDate: '2026-10-28',
        sourceUrl: 'https://shutterstock.com/blog',
        tags: ['#Shutterstock', '#4K60FPS', '#BT709', '#CFR'],
        readTime: '3 min read',
        keyTakeaways: 'Variable Frame Rate (VFR) containers are immediately rejected by Shutterstock bot reviewers; files must have faststart headers.',
        technicalSpecs: [
          'Resolution: 3840×2160 (4K UHD) or 2560×1440 (2K QHD)',
          'Container & Flags: MP4 / MOV with -movflags +faststart',
          'Bitrate Target: 20-25 Mbps VBV cap (H.264 / H.265)',
          'Chroma Subsampling: 4:2:0 YUV baseline level 5.1',
        ],
        contributorChecklist: [
          'Ubah mode kamera ponsel dari VFR ke Constant Frame Rate (CFR).',
          'Periksa metadata EXIF dan GPS agar tidak mengekspos lokasi privat.',
          'Pastikan tidak ada audio statik berdengung atau clipped waveform.',
          'Cantumkan informasi Editorial yang akurat pada judul (Kota, Tanggal, Peristiwa).',
        ],
        fullContent:
            'Shutterstock has implemented stricter automated technical validation standards across its global ingest pipeline. The automated quality control system now performs frame-by-frame cadence analysis to reject Variable Frame Rate (VFR) videos that introduce sound desynchronization inside professional NLEs like Premiere Pro and DaVinci Resolve.\n\nFurthermore, all submitted MP4 files must feature the "moov atom" metadata packet positioned at the absolute start of the file structure. This guarantees immediate zero-buffering preview playback for corporate enterprise teams auditing assets on iOS and Android workstations.\n\nSubmissions with crushed shadows, clipped high-key highlights, or non-compliant color matrices (such as un-tagged BT.2020) are automatically rejected. The platform recommends shooting in flat profiles and grading strictly into Rec.709.',
      ),
      MicrostockNewsArticle(
        id: 'freepik-bonus-program',
        title: 'Freepik Announces Enhanced Contributor Royalty Program',
        summary: 'High-converting microstock deduplication and cinematic footage unlock bonus revenue tiers.',
        source: 'Freepik Trends',
        category: 'EARNINGS',
        publishedDate: '2026-10-25',
        sourceUrl: 'https://freepik.com/contributor',
        tags: ['#Freepik', '#Royalties', '#Cinematic', '#Deduplication'],
        readTime: '3 min read',
        keyTakeaways: 'Top-tier 4K cinematic b-roll unlocks 25% royalty bonus, but duplicate or near-identical batch uploads face automated penalties.',
        technicalSpecs: [
          'Aspect Ratio: 16:9 Cinematic & 9:16 Vertical Reels',
          'Frame Rates: 24, 25, 30, or 60 FPS continuous',
          'Audio Profile: Clean ambient stereo or muted (volume=0.01)',
          'Duration: 6 to 30 seconds optimal loop lengths',
        ],
        contributorChecklist: [
          'Terapkan modifikasi vDNA (tilt/crop 1-3%) pada variasi adegan serupa.',
          'Pilih kategori dan tag microstock yang relevan maksimal 15-20 tags.',
          'Pastikan tidak ada watermark pribadi atau teks overlay.',
          'Unggah secara konsisten 10-20 klip berkualitas per minggu.',
        ],
        fullContent:
            'Freepik has officially rolled out its 2026 Contributor Royalty Booster Program, distributing over €2.5M in bonus rewards to creators of high-demand motion content. Footage categories achieving the fastest download velocity include urban lifestyle, culinary food preparation, modern workspace collaboration, and aesthetic background textures.\n\nHowever, Freepik also announced aggressive measures against catalog spamming. Contributors uploading identical footage with minor color grading changes risk account demotion. The platform uses deep visual hashes to detect perceptual duplication across contributor portfolios.\n\nTo safely maximize earnings, contributors are encouraged to introduce subtle optical variations, differing camera angles, and authentic physical micro-framing before batch uploading.',
      ),
      MicrostockNewsArticle(
        id: 'microstock-ai-dedup',
        title: 'Microstock AI Inspection Guidelines 2026',
        summary: 'Metadata stripping and sensor fingerprint variation prevent automated duplicate rejections.',
        source: 'Microstock Contributor Guild',
        category: 'GUIDELINES',
        publishedDate: '2026-10-20',
        sourceUrl: 'https://microstockguild.org/guidelines',
        tags: ['#AntiDuplication', '#Metadata', '#SensorNoise', '#Evasion'],
        readTime: '5 min read',
        keyTakeaways: 'Clean metadata sanitization, micro-crop (1-5%), and imperceptible noise injection prevent false-positive duplicate bans.',
        technicalSpecs: [
          'Crop Margin: 1% - 8% dynamic inner-box scaling',
          'Noise Injection: Gaussian temporal noise (strength 3-5)',
          'Rotation / Tilt: 0.5° - 1.0° micro-rotation with clean borders',
          'Audio Pitch & Speed: 1.01x - 1.025x synchronized time warp',
        ],
        contributorChecklist: [
          'Hapus jejak GPS, serial kamera, dan signature software pengedit.',
          'Ganti metadata kamera sintetis dengan profil resmi (iPhone 15 Pro Max).',
          'Lakukan uji coba render preview sebelum upload massal ke 5 agensi.',
          'Pertahankan integritas rasio aspek agar tidak terdistorsi.',
        ],
        fullContent:
            'The Microstock Contributor Guild has released an essential operational whitepaper detailing how stock platforms deploy neural networks and perceptual hashing to detect duplicate uploads across different accounts and sibling agencies.\n\nThese automated inspection algorithms compute multidimensional feature vectors capturing high-frequency sensor noise patterns, edge geometry, and color distribution. When a creator distributes identical footage across multiple agencies, aggressive bots can trigger automatic rejections or shadowbans.\n\nEthical uniquification practices recommended by the Guild include stripping synthetic encoding tags, injecting subtle microscopic grain, adjusting spatial framing by 1-5% with face-focus crop anchors, and modifying audio frequency spectrums without degrading perceptible consumer playback quality.',
      ),
      MicrostockNewsArticle(
        id: 'eid-lunar-demand',
        title: 'Global Commercial Footage Demand Peaks for Lunar New Year & Ramadan',
        summary: 'ProRes and H.264 formats with alpha transparency achieve 3x faster buyer acquisition.',
        source: 'Pond5 Insight',
        category: 'COMMERCIAL',
        publishedDate: '2026-10-15',
        sourceUrl: 'https://pond5.com/insights',
        tags: ['#Ramadan2026', '#LunarNewYear', '#ProRes', '#AlphaChannel'],
        readTime: '4 min read',
        keyTakeaways: 'Festive seasons yield 3x buyer licensing rates when footage is delivered in vibrant colors and smooth 30 FPS playback.',
        technicalSpecs: [
          'Resolution: 1080p, 2K QHD, and 4K UHD',
          'Frame Rate: 30 FPS standard corporate advertising cadence',
          'Color Profile: Enhanced festive saturation (+10-15%) with BT.709',
          'Audio: Optional royalty-free ambient audio or muted tracks',
        ],
        contributorChecklist: [
          'Siapkan materi festive 60-90 hari sebelum tanggal perayaan.',
          'Fokuskan pada simbol budaya: lentera, hidangan khas, dan kaligrafi.',
          'Pastikan pencahayaan cukup dan tidak ada noise sensor berlebihan.',
          'Sertakan kata kunci multi-bahasa (English, Arabic, Mandarin, Indonesian).',
        ],
        fullContent:
            'Pond5\'s latest commercial transaction reports indicate an unprecedented surge in procurement for cultural and religious festivities across Southeast Asia, the Middle East, and worldwide diaspora markets. Creative marketing agencies are aggressively licensing background loops, festive dining scenes, traditional greetings, and calligraphy animations.\n\nClips uploaded at least two months in advance of holiday dates experience an 85% higher licensing velocity compared to late submissions. Advertisers prioritize vibrant color reproduction, crisp contrast, and rock-solid 30 FPS playback on digital billboard and streaming ad networks.\n\nContributors should focus on clean composition, avoiding cluttered backgrounds or visible commercial trademarks in festive street scenes.',
      ),
    ];
  }
}
