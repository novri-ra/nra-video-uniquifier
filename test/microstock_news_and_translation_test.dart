import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/services/connectivity_service.dart';
import 'package:nra_video_uniquifier/core/services/microstock_news_service.dart';
import 'package:nra_video_uniquifier/core/services/translation_service.dart';
import 'package:nra_video_uniquifier/core/services/user_interest_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConnectivityService.mockPingHandler = null;
    TranslationService.mockTranslator = null;
    TranslationService.customHttpGet = null;
    MicrostockNewsService.mockFetchHandler = null;
    MicrostockNewsService.customHttpGet = null;
    UserInterestService.mockDispatcher = null;
  });

  tearDown(() {
    ConnectivityService.instance.dispose();
  });

  group('Sprint 76: ConnectivityService Unit Tests', () {
    test('checkConnectivity returns mocked state without socket connection', () async {
      final connectivity = ConnectivityService.instance;
      ConnectivityService.mockPingHandler = () async => true;

      final isOnline = await connectivity.checkConnectivity();
      expect(isOnline, isTrue);
      expect(connectivity.isOnline.value, isTrue);

      ConnectivityService.mockPingHandler = () async => false;
      final isOffline = await connectivity.checkConnectivity();
      expect(isOffline, isFalse);
      expect(connectivity.isOnline.value, isFalse);
    });

    test('setOnlineForTesting directly toggles ValueNotifier state', () {
      final connectivity = ConnectivityService.instance;
      connectivity.setOnlineForTesting(true);
      expect(connectivity.isOnline.value, isTrue);

      connectivity.setOnlineForTesting(false);
      expect(connectivity.isOnline.value, isFalse);
    });
  });

  group('Sprint 76: TranslationService Unit Tests', () {
    test('translateText handles known terms offline with local dict', () async {
      final translated = await TranslationService.translateText(
        'Adobe Stock Releases 2026 Visual Trend Forecast',
        targetLang: 'id',
        isOnline: false,
      );
      expect(translated, equals('Adobe Stock Merilis Prakiraan Tren Visual 2026'));
    });

    test('translateText caches translated output in SharedPreferences', () async {
      TranslationService.mockTranslator = (text, lang) async => 'Terjemahan Khusus';

      final res1 = await TranslationService.translateText(
        'Special Custom Query',
        targetLang: 'id',
        isOnline: true,
      );
      expect(res1, equals('Terjemahan Khusus'));

      // Invalidate mock to confirm cache hit
      TranslationService.mockTranslator = null;
      final resCached = await TranslationService.translateText(
        'Special Custom Query',
        targetLang: 'id',
        isOnline: false,
      );
      expect(resCached, equals('Terjemahan Khusus'));
    });

    test('translateLongText chunks multi-paragraph text and reassembles correctly', () async {
      TranslationService.mockTranslator = (text, lang) async => 'Terjemahan: $text';

      const multiPara = 'First paragraph content.\n\nSecond paragraph content.';
      final result = await TranslationService.translateLongText(multiPara, targetLang: 'id');

      expect(result, contains('Terjemahan: First paragraph content.'));
      expect(result, contains('Terjemahan: Second paragraph content.'));
      expect(result.contains('\n\n'), isTrue);

      // Verify persistent cache hit
      TranslationService.mockTranslator = null;
      final cached = await TranslationService.translateLongText(multiPara, targetLang: 'id');
      expect(cached, equals(result));
    });
  });

  group('Sprint 79: Hybrid Feed Integration (RSS2JSON + Reddit Intel)', () {
    test('fetchHybridNews correctly parses and sorts RSS2JSON and Reddit posts', () async {
      MicrostockNewsService.customHttpGet = (uri) async {
        if (uri.toString().contains('rss2json.com')) {
          return '''
          {
            "status": "ok",
            "items": [
              {
                "title": "Agency 4K Guideline Update",
                "pubDate": "2026-10-30 10:00:00",
                "link": "https://agency.com/news",
                "description": "<p>Agency video description</p>",
                "content": "<p>Agency full article text</p>",
                "categories": ["Video", "Specs"]
              }
            ]
          }
          ''';
        } else if (uri.toString().contains('microstock/hot.json')) {
          return '''
          {
            "data": {
              "children": [
                {
                  "data": {
                    "id": "reddit_01",
                    "title": "Reddit Hot Discussion on Dupes",
                    "selftext": "Community discussion body on perceptual hashing.",
                    "permalink": "/r/microstock/comments/123/dupes/",
                    "created_utc": 1730400000,
                    "subreddit": "microstock"
                  }
                }
              ]
            }
          }
          ''';
        } else {
          return '{"data": {"children": []}}';
        }
      };

      final items = await MicrostockNewsService.fetchHybridNews();
      expect(items.length, equals(2));

      final rssItem = items.firstWhere((i) => i.source == 'Shutterstock Official');
      expect(rssItem.title, equals('Agency 4K Guideline Update'));
      expect(rssItem.summary, contains('Agency video description'));

      final redditItem = items.firstWhere((i) => i.source == 'Reddit Community Discussion');
      expect(redditItem.title, equals('Reddit Hot Discussion on Dupes'));
      expect(redditItem.category, equals('COMMUNITY'));
      expect(redditItem.sourceUrl, contains('reddit.com/r/microstock'));
    });
  });

  group('Sprint 76: MicrostockNewsService Unit Tests', () {
    test('loadNews returns seed articles on first run and saves cache', () async {
      final articles = await MicrostockNewsService.loadNews();
      expect(articles, isNotEmpty);
      expect(articles.length, greaterThanOrEqualTo(5));

      final cached = await MicrostockNewsService.getCachedNews();
      expect(cached.length, equals(articles.length));
    });

    test('loadNews returns cached articles when offline', () async {
      ConnectivityService.instance.setOnlineForTesting(false);
      final articles = await MicrostockNewsService.loadNews(forceRefresh: true);
      expect(articles, isNotEmpty);
    });

    test('getLastSyncTime updates after saving articles', () async {
      final seed = MicrostockNewsService.getSeedArticles();
      await MicrostockNewsService.saveNewsToCache(seed);

      final syncTime = await MicrostockNewsService.getLastSyncTime();
      expect(syncTime, isNotNull);
      expect(syncTime!.contains('202'), isTrue);
    });

    test('MicrostockNewsArticle rich fields roundtrip serialization', () {
      const article = MicrostockNewsArticle(
        id: 'test-id',
        title: 'Title Test',
        summary: 'Summary Test',
        source: 'Test Source',
        category: 'TRENDS',
        publishedDate: '2026-11-03',
        sourceUrl: 'https://test.com',
        tags: ['#Test'],
        fullContent: 'Full article body content here.\n\nParagraph 2 here.',
        readTime: '5 min read',
        keyTakeaways: 'Key points to remember',
        technicalSpecs: ['4K UHD', 'Rec.709'],
        contributorChecklist: ['Check lighting', 'Strip GPS'],
      );
      final json = article.toJson();
      expect(json['fullContent'], equals('Full article body content here.\n\nParagraph 2 here.'));
      expect(json['readTime'], equals('5 min read'));
      expect(json['keyTakeaways'], equals('Key points to remember'));
      expect(json['technicalSpecs'], equals(['4K UHD', 'Rec.709']));
      expect(json['contributorChecklist'], equals(['Check lighting', 'Strip GPS']));

      final parsed = MicrostockNewsArticle.fromJson(json);
      expect(parsed.fullContent, equals(article.fullContent));
      expect(parsed.readTime, equals('5 min read'));
      expect(parsed.keyTakeaways, equals('Key points to remember'));
      expect(parsed.technicalSpecs, equals(['4K UHD', 'Rec.709']));
      expect(parsed.contributorChecklist, equals(['Check lighting', 'Strip GPS']));
    });

    test('parseRssContent strips HTML tags and decodes entities properly', () {
      const xmlWithCdata = '<item><title>Foo</title><content:encoded><![CDATA[<p>Paragraph 1</p><p>Paragraph 2 with <b>bold</b> and &amp; &quot;quotes&quot;</p>]]></content:encoded></item>';
      final parsed = MicrostockNewsService.parseRssContent(xmlWithCdata);
      expect(parsed, contains('Paragraph 1'));
      expect(parsed, contains('Paragraph 2 with bold and & "quotes"'));
      expect(parsed.contains('<p>'), isFalse);
      expect(parsed.contains('<b>'), isFalse);
    });

    test('Seed articles contain comprehensive in-depth structured content', () {
      final seeds = MicrostockNewsService.getSeedArticles();
      expect(seeds.length, greaterThanOrEqualTo(5));
      for (final seed in seeds) {
        expect(seed.fullContent.split(RegExp(r'\n{1,2}')).length, greaterThanOrEqualTo(3));
        expect(seed.readTime, isNotEmpty);
        expect(seed.keyTakeaways, isNotEmpty);
        expect(seed.technicalSpecs, isNotEmpty);
        expect(seed.contributorChecklist, isNotEmpty);
      }
    });
  });

  group('Sprint 80: UserInterestService Unit Tests', () {
    test('Self-learning affinity engine ranks interacted topics higher', () async {
      await UserInterestService.initialize();
      final initialKeywords = UserInterestService.getAdaptiveKeywords();
      expect(initialKeywords.first, equals('All'));

      // Record 3 searches for 'AI Video' (+9 weight)
      await UserInterestService.recordSearch('AI Video');
      await UserInterestService.recordSearch('AI Video');
      await UserInterestService.recordSearch('AI Video');

      // Record 1 chip click for 'Reels Algorithm' (+2 weight)
      await UserInterestService.recordChipClick('Reels Algorithm');

      final adaptive = UserInterestService.getAdaptiveKeywords();
      expect(adaptive.first, equals('All'));
      expect(adaptive[1], equals('AI Video'));
      expect(adaptive[2], equals('Reels Algorithm'));
    });

    test('Telemetry dispatcher queues payloads when offline and flushes when online', () async {
      final dispatched = <Map<String, dynamic>>[];
      UserInterestService.mockDispatcher = (payload) async {
        dispatched.add(payload);
        return true;
      };

      await UserInterestService.recordSearch('4K Cinematic');
      expect(dispatched.length, equals(1));
      expect(dispatched.first['type'], equals('user_interest_telemetry'));
      expect(dispatched.first['query'], equals('4K Cinematic'));

      await UserInterestService.dispatchVideoMetadataVault(
        title: 'Cinematic Sunset 4K',
        description: 'B-roll sunset',
        keywords: ['sunset', 'golden hour'],
        platforms: ['Shutterstock', 'Adobe Stock'],
        techSpecs: '3840x2160 60FPS',
        category: 'NATURE',
      );

      expect(dispatched.length, equals(2));
      expect(dispatched[1]['type'], equals('video_metadata_vault'));
      expect(dispatched[1]['title'], equals('Cinematic Sunset 4K'));
    });
  });
}
