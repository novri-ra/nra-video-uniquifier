import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/uniquifier_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/screens/root_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UniquifierProvider()),
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
