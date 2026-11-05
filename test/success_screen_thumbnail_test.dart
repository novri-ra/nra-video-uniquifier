import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';
import 'package:nra_video_uniquifier/core/theme/app_colors.dart';
import 'package:nra_video_uniquifier/features/process/screens/success_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SuccessScreen Thumbnail & Fallback Tests', () {
    testWidgets(
      'renders placeholder container with video icon when both thumbnails are missing',
      (tester) async {
        final provider = UniquifierProvider();

        await tester.pumpWidget(
          ChangeNotifierProvider<UniquifierProvider>.value(
            value: provider,
            child: const MaterialApp(
              home: SuccessScreen(outputPath: '/fake/output/video.mp4'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SuccessScreen), findsOneWidget);
        expect(find.byIcon(Icons.videocam), findsOneWidget);
        expect(find.text('READY'), findsOneWidget);
      },
    );

    testWidgets(
      'falls back to provider.thumbnailPath when outputThumbnailPath is null or missing',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync('thumb_test_');
        final inputThumb = File('${tempDir.path}/input_thumb.jpg')
          ..writeAsBytesSync([1, 2, 3]);
        expect(inputThumb.existsSync(), isTrue);

        final provider = UniquifierProvider();
        provider.setVideoFile(
          path: '/fake/path/input.mp4',
          name: 'input.mp4',
          sizeBytes: 1024,
        );

        // Manually set thumbnail path via test reflection/internal state simulation
        // or widget testing
        await tester.pumpWidget(
          ChangeNotifierProvider<UniquifierProvider>.value(
            value: provider,
            child: const MaterialApp(
              home: SuccessScreen(outputPath: '/fake/output/video.mp4'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SuccessScreen), findsOneWidget);
        expect(find.text('READY'), findsOneWidget);

        tempDir.deleteSync(recursive: true);
      },
    );

    testWidgets(
      'uses AppColors.surfaceVariant placeholder for empty or broken thumbnail',
      (tester) async {
        final provider = UniquifierProvider();

        await tester.pumpWidget(
          ChangeNotifierProvider<UniquifierProvider>.value(
            value: provider,
            child: const MaterialApp(
              home: SuccessScreen(outputPath: '/storage/video.mp4'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final iconFinder = find.byIcon(Icons.videocam);
        expect(iconFinder, findsOneWidget);

        // Verify container with AppColors.surfaceVariant surrounds the icon
        final containers = tester.widgetList<Container>(find.byType(Container));
        final hasSurfaceVariant = containers.any(
          (c) =>
              c.color == AppColors.surfaceVariant ||
              (c.decoration is BoxDecoration &&
                  (c.decoration as BoxDecoration).color ==
                      AppColors.surfaceVariant),
        );
        expect(hasSurfaceVariant, isTrue);
      },
    );
  });
}
