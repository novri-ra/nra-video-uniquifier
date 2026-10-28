import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';
import 'package:nra_video_uniquifier/features/navigation/screens/root_navigation_screen.dart';
import 'package:provider/provider.dart';

void main() {
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
  });
}
