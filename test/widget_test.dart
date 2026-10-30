import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/providers/batch_queue_provider.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';
import 'package:nra_video_uniquifier/features/navigation/screens/root_navigation_screen.dart';
import 'package:nra_video_uniquifier/features/process/widgets/modifiers_card.dart';
import 'package:nra_video_uniquifier/features/process/widgets/processing_log_viewer.dart';
import 'package:nra_video_uniquifier/features/process/screens/processing_screen.dart';
import 'package:nra_video_uniquifier/features/process/widgets/processing_radar_indicator.dart';
import 'package:nra_video_uniquifier/features/settings/screens/settings_screen.dart';
import 'package:nra_video_uniquifier/shared/widgets/top_app_bar.dart';
import 'package:nra_video_uniquifier/features/history/widgets/history_item_card.dart';
import 'package:nra_video_uniquifier/core/services/history_service.dart';
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
        ChangeNotifierProvider(create: (_) => BatchQueueProvider()),
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
      expect(find.text('Denoise & Clarity'), findsOneWidget);
      expect(find.text('Deep Evasion'), findsOneWidget);
      expect(find.text('Horizontal Flip'), findsOneWidget);
      expect(find.text('Audio Masking'), findsOneWidget);
      expect(find.text('Auto-Trim'), findsOneWidget);

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

    testWidgets('D2-01: Double-tap on start action button triggers exactly one route push', (tester) async {
      final uniquifierProvider = UniquifierProvider();
      final batchQueueProvider = BatchQueueProvider();

      uniquifierProvider.setVideoFile(
        path: '/dummy/path/video.mp4',
        name: 'video.mp4',
        sizeBytes: 1024,
      );

      int pushCount = 0;
      final observer = _TestNavigatorObserver(onPushed: () => pushCount++);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: uniquifierProvider),
            ChangeNotifierProvider.value(value: batchQueueProvider),
          ],
          child: MaterialApp(
            navigatorObservers: [observer],
            home: const RootNavigationScreen(),
          ),
        ),
      );
      await tester.pump();

      final button = find.text('START UNIQUIFYING');
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);

      // Tap twice rapidly
      await tester.tap(button, warnIfMissed: false);
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();

      // Observer records 1 for initial route + 1 for ProcessingScreen push = 2 total pushes
      expect(pushCount, equals(2));
    });

    testWidgets('D3-02: Preset profile chips update provider toggles per preset definition', (tester) async {
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

      // Tap TikTok Fast
      final tikTokChip = find.text('TikTok Fast');
      expect(tikTokChip, findsOneWidget);
      await tester.tap(tikTokChip);
      await tester.pumpAndSettle();
      expect(provider.modifyVisuals, isTrue);
      expect(provider.enableEnhanceAndDenoise, isFalse);
      expect(provider.enableAutoTrim, isTrue);

      // Tap Maximum Anti-Fingerprint
      final maxChip = find.text('Maximum Anti-Fingerprint');
      expect(maxChip, findsOneWidget);
      await tester.tap(maxChip);
      await tester.pumpAndSettle();
      expect(provider.upscale1080p, isTrue);
      expect(provider.selectedUpscaleTarget, equals('2k'));
      expect(provider.enableHorizontalFlip, isTrue);
      expect(provider.enableAggressiveAudio, isTrue);

      // Tap Lossless Stealth
      final stealthChip = find.text('Lossless Stealth');
      expect(stealthChip, findsOneWidget);
      await tester.tap(stealthChip);
      await tester.pumpAndSettle();
      expect(provider.modifyAudio, isFalse);
      expect(provider.modifyVisuals, isFalse);
      expect(provider.enableDeepAntiFingerprint, isFalse);
    });

    testWidgets('D4-02: Purge cache confirmation dialog cancels or confirms purge', (tester) async {
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

      final purgeButton = find.text('Purge Cache');
      expect(purgeButton, findsOneWidget);
      await tester.ensureVisible(purgeButton);

      // Tap Purge -> Dialog opens
      await tester.tap(purgeButton);
      await tester.pumpAndSettle();
      expect(find.text('Purge cache?'), findsOneWidget);

      // Tap Cancel -> Dialog closes
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Purge cache?'), findsNothing);

      // Tap Purge -> Dialog opens again
      await tester.tap(purgeButton);
      await tester.pumpAndSettle();
      expect(find.text('Purge cache?'), findsOneWidget);

      // Tap Purge button in dialog -> Confirms
      final confirmButton = find.widgetWithText(TextButton, 'Purge');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
      expect(find.text('Purge cache?'), findsNothing);
    });

    testWidgets('D4-01: Touch target sizes for TopAppBar and HistoryItemCard meet >= 48x48dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: TopAppBar(
              title: 'TEST',
              onSettingsTap: () {},
            ),
            body: HistoryItemCard(
              item: VideoExportItem(
                file: File('/dummy.mp4'),
                fileName: 'dummy.mp4',
                bytes: 1024,
                modified: DateTime.now(),
              ),
              onTap: () {},
              onShare: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final settingsTarget = tester.getSize(find.byTooltip('Settings'));
      expect(settingsTarget.width, greaterThanOrEqualTo(48.0));
      expect(settingsTarget.height, greaterThanOrEqualTo(48.0));

      final shareTarget = tester.getSize(find.byTooltip('Share'));
      expect(shareTarget.width, greaterThanOrEqualTo(48.0));
      expect(shareTarget.height, greaterThanOrEqualTo(48.0));

      final deleteTarget = tester.getSize(find.byTooltip('Delete'));
      expect(deleteTarget.width, greaterThanOrEqualTo(48.0));
      expect(deleteTarget.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('D4-03: SettingsScreen renders cleanly on 320x480 with textScaleFactor 2.0 without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = UniquifierProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(320, 480), textScaler: TextScaler.linear(2.0)),
              child: SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('D2-02: ProcessingScreen ticker caps progress <= 15% before native completion', (tester) async {
      final provider = UniquifierProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: ProcessingScreen(),
          ),
        ),
      );
      // Advance 2 seconds into 4-second ticker
      await tester.pump(const Duration(seconds: 2));

      final radar = tester.widget<ProcessingRadarIndicator>(find.byType(ProcessingRadarIndicator));
      expect(radar.progress, lessThanOrEqualTo(0.15));

      // Settle delayed mock engine timer
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });
  });
}

class _TestNavigatorObserver extends NavigatorObserver {
  final VoidCallback onPushed;
  _TestNavigatorObserver({required this.onPushed});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    onPushed();
  }
}
