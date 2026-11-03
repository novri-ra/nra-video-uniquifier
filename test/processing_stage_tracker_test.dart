import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/theme/app_colors.dart';
import 'package:nra_video_uniquifier/features/process/widgets/processing_stage_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProcessingStageTracker Tests (Sprint 96)', () {
    testWidgets('renders all 5 pipeline stage labels with correct typography', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProcessingStageTracker(currentStep: 1),
          ),
        ),
      );

      expect(find.text('METADATA'), findsOneWidget);
      expect(find.text('TRANSFORM'), findsOneWidget);
      expect(find.text('FILTERGRAPH'), findsOneWidget);
      expect(find.text('ENCODE'), findsOneWidget);
      expect(find.text('EXPORT'), findsOneWidget);
    });

    testWidgets('Light Mode: active step line uses vividCoral and text uses forestDeep', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: ProcessingStageTracker(currentStep: 2),
          ),
        ),
      );

      // Step 2 is active: TRANSFORM
      final transformText = tester.widget<Text>(find.text('TRANSFORM'));
      expect(transformText.style?.color, equals(AppColors.forestDeep));
      expect(transformText.style?.fontWeight, equals(FontWeight.w800));

      // Step 1 is completed: METADATA
      final metadataText = tester.widget<Text>(find.text('METADATA'));
      expect(metadataText.style?.color, equals(AppColors.forestDeep));
      expect(metadataText.style?.fontWeight, equals(FontWeight.w800));

      // Step 3 is pending: FILTERGRAPH
      final filterText = tester.widget<Text>(find.text('FILTERGRAPH'));
      expect(filterText.style?.color, equals(AppColors.textDark.withValues(alpha: 0.40)));
      expect(filterText.style?.fontWeight, equals(FontWeight.w600));

      // Check active step line container decoration color
      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      final lineContainers = containers.where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && (c.constraints?.maxHeight == 3.0 || c.constraints?.minHeight == 3.0);
      }).toList();

      expect(lineContainers.length, equals(5));
      // First is completed (forestDeep)
      expect((lineContainers[0].decoration as BoxDecoration).color, equals(AppColors.forestDeep));
      // Second is active (vividCoral)
      expect((lineContainers[1].decoration as BoxDecoration).color, equals(AppColors.vividCoral));
      // Third is pending (hairlineBorder)
      expect((lineContainers[2].decoration as BoxDecoration).color, equals(AppColors.hairlineBorder));
    });

    testWidgets('Dark Mode: active step line uses vividCoral and active text uses mintSage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ProcessingStageTracker(currentStep: 3),
          ),
        ),
      );

      // Step 3 is active: FILTERGRAPH
      final filterText = tester.widget<Text>(find.text('FILTERGRAPH'));
      expect(filterText.style?.color, equals(AppColors.mintSage));
      expect(filterText.style?.fontWeight, equals(FontWeight.w800));

      // Step 1 & 2 completed: METADATA & TRANSFORM
      final metaText = tester.widget<Text>(find.text('METADATA'));
      expect(metaText.style?.color, equals(AppColors.mintSage));

      // Step 4 pending: ENCODE
      final encodeText = tester.widget<Text>(find.text('ENCODE'));
      expect(encodeText.style?.color, equals(AppColors.textLight.withValues(alpha: 0.40)));

      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      final lineContainers = containers.where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && (c.constraints?.maxHeight == 3.0 || c.constraints?.minHeight == 3.0);
      }).toList();

      expect(lineContainers.length, equals(5));
      // Step 1, 2 completed (mintSage)
      expect((lineContainers[0].decoration as BoxDecoration).color, equals(AppColors.mintSage));
      expect((lineContainers[1].decoration as BoxDecoration).color, equals(AppColors.mintSage));
      // Step 3 active (vividCoral)
      expect((lineContainers[2].decoration as BoxDecoration).color, equals(AppColors.vividCoral));
      // Step 4 pending (obsidianDark)
      expect((lineContainers[3].decoration as BoxDecoration).color, equals(AppColors.obsidianDark));
    });
  });
}
