import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';
import 'package:nra_video_uniquifier/features/navigation/screens/root_navigation_screen.dart';
import 'package:nra_video_uniquifier/features/process/widgets/modifiers_card.dart';
import 'package:nra_video_uniquifier/features/process/widgets/processing_log_viewer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  Widget createTestWidget({required Size surfaceSize}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UniquifierProvider()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: const RootNavigationScreen(),
        ),
      ),
    );
  }

  group('Video Uniquifier - Multi-Resolution Responsive Smoke Tests', () {
    testWidgets('Renders cleanly on Small Phone (320x480) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(surfaceSize: const Size(320, 480)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('VIDEO UNIQUIFIER'), findsOneWidget);
      expect(find.text('SOURCE FILE'), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly on Standard FHD (1080x1920) without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(surfaceSize: const Size(540, 960)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('VIDEO UNIQUIFIER'), findsOneWidget);
      expect(find.text('SOURCE FILE'), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly on Tablet / LDPlayer 9 Landscape (1280x800)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(surfaceSize: const Size(1280, 800)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('VIDEO UNIQUIFIER'), findsOneWidget);
      expect(find.text('SOURCE FILE'), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProcessingLogViewer truncates excessively long filename without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: ProcessingLogViewer(
                  fileName: 'VeryLongVideoFileName_2026_Final_Render_Version_Ultra_Special_Export_Sample_Video_Archive.mp4',
                  duration: '01:45:20',
                  executionTime: '01:23s',
                  estimatedRemaining: '00:12s rem',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SOURCE'), findsOneWidget);
      expect(find.text('EXECUTION TIME'), findsOneWidget);
      expect(find.text('SANDBOX STATE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ModifiersCard displays dynamic title and subtitle for resolution state', (tester) async {
      final testProvider = UniquifierProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: testProvider,
          child: MaterialApp(
            home: Scaffold(
              body: ModifiersCard(
                provider: testProvider,
                onOpenAdvanced: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state: 1080p
      expect(find.text('Upscale to 1080p'), findsOneWidget);
      expect(find.text('Lanczos algorithm (1920x1080)'), findsOneWidget);

      // Change to 2K
      testProvider.setUpscaleTarget('2k');
      await tester.pumpAndSettle();
      expect(find.text('Upscale to 2K'), findsOneWidget);
      expect(find.text('Lanczos algorithm (2560x1440)'), findsOneWidget);

      // Change to 4K
      testProvider.setUpscaleTarget('4k');
      await tester.pumpAndSettle();
      expect(find.text('Upscale to 4K'), findsOneWidget);
      expect(find.text('Lanczos algorithm (3840x2160)'), findsOneWidget);
    });
  });
}
