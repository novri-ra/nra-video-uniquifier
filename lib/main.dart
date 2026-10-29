import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/batch_queue_provider.dart';
import 'core/providers/uniquifier_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/screens/root_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    FFmpegKitConfig.setSessionHistorySize(3);
  } catch (_) {}
  try {
    SettingsService.purgeTempCache();
  } catch (_) {}
  try {
    NotificationService.init();
    NotificationService.requestPermission();
  } catch (_) {}
  runApp(
    MultiProvider(
      providers: [
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
    return MaterialApp(
      title: 'Video Uniquifier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const RootNavigationScreen(),
    );
  }
}
