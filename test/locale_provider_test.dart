import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/providers/locale_provider.dart';
import 'package:nra_video_uniquifier/core/services/settings_service.dart';
import 'package:nra_video_uniquifier/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleProvider and i18n Localization Tests', () {
    test('Default language code is en and persists to SharedPreferences', () async {
      final provider = LocaleProvider();
      expect(provider.languageCode, equals('en'));
      expect(provider.currentLocale.languageCode, equals('en'));

      await provider.changeLanguage('id');
      expect(provider.languageCode, equals('id'));
      expect(await SettingsService.getAppLanguageCode(), equals('id'));

      await provider.changeLanguage('en');
      expect(provider.languageCode, equals('en'));
      expect(await SettingsService.getAppLanguageCode(), equals('en'));
    });

    test('Invalid language code is ignored', () async {
      final provider = LocaleProvider();
      await provider.changeLanguage('fr');
      expect(provider.languageCode, equals('en'));
    });

    testWidgets('AppTitle remains static NRA Video Uniquifier in both ID and EN', (tester) async {
      final localeProvider = LocaleProvider();

      Widget buildLocalizedApp() {
        return ChangeNotifierProvider.value(
          value: localeProvider,
          child: Consumer<LocaleProvider>(
            builder: (context, provider, _) {
              return MaterialApp(
                locale: provider.currentLocale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Scaffold(
                      body: Column(
                        children: [
                          Text(l10n.appTitle, key: const Key('app_title')),
                          Text(l10n.navProcess, key: const Key('nav_process')),
                          Text(l10n.settingsTitle, key: const Key('settings_title')),
                          Text(l10n.greetingMorning, key: const Key('greeting_morning')),
                          Text(l10n.engineHardwareActive, key: const Key('engine_hw')),
                          Text(l10n.exportShareVideo, key: const Key('export_share')),
                          Text(l10n.openGallery, key: const Key('open_gallery')),
                          Text(l10n.uniquifyAnother, key: const Key('uniquify_another')),
                          Text(l10n.storageAvailable, key: const Key('storage_available')),
                          Text(l10n.exifClean, key: const Key('exif_clean')),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      }

      await tester.pumpWidget(buildLocalizedApp());
      await tester.pumpAndSettle();

      // Switch to ID first to test Indonesian strings
      await localeProvider.changeLanguage('id');
      await tester.pumpAndSettle();

      // ID Assertions
      expect(find.byKey(const Key('app_title')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('app_title'))).data, equals('NRA Video Uniquifier'));
      expect(tester.widget<Text>(find.byKey(const Key('nav_process'))).data, equals('Proses'));
      expect(tester.widget<Text>(find.byKey(const Key('settings_title'))).data, equals('Pengaturan'));
      expect(tester.widget<Text>(find.byKey(const Key('greeting_morning'))).data, equals('Selamat Pagi, Kreator'));
      expect(tester.widget<Text>(find.byKey(const Key('engine_hw'))).data, equals('Akselerasi Perangkat Aktif'));
      expect(tester.widget<Text>(find.byKey(const Key('export_share'))).data, equals('Ekspor & Bagikan Video'));
      expect(tester.widget<Text>(find.byKey(const Key('open_gallery'))).data, equals('Buka Galeri'));
      expect(tester.widget<Text>(find.byKey(const Key('uniquify_another'))).data, equals('Proses Video Lainnya'));
      expect(tester.widget<Text>(find.byKey(const Key('storage_available'))).data, equals('TERSEDIA'));
      expect(tester.widget<Text>(find.byKey(const Key('exif_clean'))).data, equals('BERSIH DARI EXIF'));

      // Switch to EN
      await localeProvider.changeLanguage('en');
      await tester.pumpAndSettle();

      // EN Assertions - AppTitle MUST remain unchanged
      expect(tester.widget<Text>(find.byKey(const Key('app_title'))).data, equals('NRA Video Uniquifier'));
      expect(tester.widget<Text>(find.byKey(const Key('nav_process'))).data, equals('Process'));
      expect(tester.widget<Text>(find.byKey(const Key('settings_title'))).data, equals('Settings'));
      expect(tester.widget<Text>(find.byKey(const Key('greeting_morning'))).data, equals('Good Morning, Creator'));
      expect(tester.widget<Text>(find.byKey(const Key('engine_hw'))).data, equals('Hardware Engine Active'));
      expect(tester.widget<Text>(find.byKey(const Key('export_share'))).data, equals('Export & Share Video'));
      expect(tester.widget<Text>(find.byKey(const Key('open_gallery'))).data, equals('Open Gallery'));
      expect(tester.widget<Text>(find.byKey(const Key('uniquify_another'))).data, equals('Uniquify Another Video'));
      expect(tester.widget<Text>(find.byKey(const Key('storage_available'))).data, equals('AVAILABLE'));
      expect(tester.widget<Text>(find.byKey(const Key('exif_clean'))).data, equals('EXIF CLEAN'));
    });
  });
}
