import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/services/connectivity_service.dart';
import 'package:nra_video_uniquifier/core/services/microstock_news_service.dart';
import 'package:nra_video_uniquifier/core/services/translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConnectivityService.mockPingHandler = null;
    TranslationService.mockTranslator = null;
    MicrostockNewsService.mockFetchHandler = null;
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

    test('translateText throws TranslationOfflineException when offline without cache', () async {
      expect(
        () => TranslationService.translateText(
          'Completely Unknown String 998877',
          targetLang: 'id',
          isOnline: false,
        ),
        throwsA(isA<TranslationOfflineException>()),
      );
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

    test('MicrostockNewsArticle fullContent roundtrip serialization', () {
      const article = MicrostockNewsArticle(
        id: 'test-id',
        title: 'Title Test',
        summary: 'Summary Test',
        source: 'Test Source',
        category: 'TRENDS',
        publishedDate: '2026-11-03',
        sourceUrl: 'https://test.com',
        tags: ['#Test'],
        fullContent: 'Full article body content here.',
      );
      final json = article.toJson();
      expect(json['fullContent'], equals('Full article body content here.'));

      final parsed = MicrostockNewsArticle.fromJson(json);
      expect(parsed.fullContent, equals('Full article body content here.'));
      expect(parsed.title, equals('Title Test'));
    });
  });
}
