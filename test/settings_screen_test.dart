import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';
import 'package:nra_video_uniquifier/features/settings/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsScreen Widget Smoke Tests', () {
    testWidgets('renders all major setting sections cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = UniquifierProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('PRESET PROFILES'), findsOneWidget);
      expect(find.text('VIDEO ENCODING CODEC'), findsOneWidget);
      expect(find.text('DEFAULT RESOLUTION UPSCALE'), findsOneWidget);
      expect(find.text('HARDWARE ACCELERATION'), findsOneWidget);
      expect(find.text('BACKGROUND & ALERTS'), findsOneWidget);
      expect(find.text('STORAGE & CACHE MAINTENANCE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('toggles background and sound switches without error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = UniquifierProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      expect(switches, findsWidgets);
      for (final sw in switches.evaluate()) {
        await tester.tap(find.byWidget(sw.widget).first);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
