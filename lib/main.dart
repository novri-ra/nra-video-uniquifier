import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/providers/batch_queue_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/uniquifier_provider.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/screens/root_navigation_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    FFmpegKitConfig.setSessionHistorySize(3);
  } catch (e) {
    debugPrint('[Main] FFmpeg init failed: $e');
  }

  try {
    await StorageService.pruneStaleFiles();
    await SettingsService.purgeTempCache();
  } catch (e) {
    debugPrint('[Main] Cache cleanup failed: $e');
  }

  try {
    await NotificationService.initialize();
    await NotificationService.requestPermission();
    ConnectivityService.instance.initialize();
  } catch (e) {
    debugPrint('[Main] Service init failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => UniquifierProvider()),
        ChangeNotifierProvider(create: (_) => BatchQueueProvider()),
      ],
      child: const VideoUniquifierApp(),
    ),
  );
}

class VideoUniquifierApp extends StatelessWidget {
  const VideoUniquifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'NRA Video Uniquifier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      locale: localeProvider.currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootNavigationScreen(),
    );
  }
}
