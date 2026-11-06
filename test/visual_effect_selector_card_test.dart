import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';
import 'package:nra_video_uniquifier/features/process/widgets/visual_effect_selector_card.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget({
    required UniquifierProvider provider,
    Brightness brightness = Brightness.dark,
    Size surfaceSize = const Size(400, 800),
  }) {
    return ChangeNotifierProvider<UniquifierProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: ThemeData(brightness: brightness, fontFamily: 'monospace'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: VisualEffectSelectorCard(provider: provider),
          ),
        ),
      ),
    );
  }

  group('VisualEffectSelectorCard Widget & Interaction Tests', () {
    testWidgets('renders catalog header, subtitle, and default active badge', (
      tester,
    ) async {
      final provider = UniquifierProvider();

      await tester.pumpWidget(buildTestableWidget(provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('VISUAL FILTER CATALOG'), findsOneWidget);
      expect(find.text('Real-time FFmpeg preview presets'), findsOneWidget);
      expect(find.text('ORIGINAL'), findsOneWidget);

      provider.dispose();
    });

    testWidgets('renders all 7 visual preset cards horizontally', (
      tester,
    ) async {
      final provider = UniquifierProvider();

      await tester.pumpWidget(buildTestableWidget(provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('None'), findsOneWidget);
      expect(find.text('Blurred Canvas'), findsOneWidget);
      expect(find.text('Echo Delay'), findsOneWidget);
      expect(find.text('RGB Split'), findsOneWidget);
      expect(find.text('Dreamy Bloom'), findsOneWidget);

      // Scroll horizontal list to verify remaining presets
      await tester.drag(find.text('Dreamy Bloom'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(find.text('16mm Film'), findsOneWidget);
      expect(find.text('Dynamic Grain'), findsOneWidget);

      provider.dispose();
    });

    testWidgets(
      'selecting Blurred Canvas displays scale sub-control and updates provider',
      (tester) async {
        final provider = UniquifierProvider();

        await tester.pumpWidget(buildTestableWidget(provider: provider));
        await tester.pumpAndSettle();

        // Tap Blurred Canvas preset
        await tester.tap(find.text('Blurred Canvas'));
        await tester.pumpAndSettle();

        expect(
          provider.selectedVisualEffect,
          UnifiedVisualEffect.blurredCanvas,
        );
        expect(find.text('CANVAS'), findsOneWidget);
        expect(find.text('BLURRED CANVAS FOREGROUND SCALE'), findsOneWidget);

        provider.dispose();
      },
    );

    testWidgets(
      'selecting Echo Delay displays delay slider and updates echo parameter',
      (tester) async {
        final provider = UniquifierProvider();

        await tester.pumpWidget(buildTestableWidget(provider: provider));
        await tester.pumpAndSettle();

        // Tap Echo Delay preset
        await tester.tap(find.text('Echo Delay'));
        await tester.pumpAndSettle();

        expect(provider.selectedVisualEffect, UnifiedVisualEffect.motionEcho);
        expect(find.text('ECHO'), findsOneWidget);
        expect(find.text('TEMPORAL CLONE DELAY'), findsOneWidget);

        // Adjust delay parameter via provider setter
        provider.setMotionEchoDelay(0.25);
        await tester.pumpAndSettle();

        expect(provider.motionEchoDelay, closeTo(0.25, 0.001));
        expect(find.text('0.25s'), findsOneWidget);

        provider.dispose();
      },
    );

    testWidgets('selecting Dreamy Bloom displays effect description banner', (
      tester,
    ) async {
      final provider = UniquifierProvider();

      await tester.pumpWidget(buildTestableWidget(provider: provider));
      await tester.pumpAndSettle();

      // Tap Dreamy Bloom preset
      await tester.tap(find.text('Dreamy Bloom'));
      await tester.pumpAndSettle();

      expect(provider.selectedVisualEffect, UnifiedVisualEffect.dreamyBloom);
      expect(find.text('BLOOM'), findsOneWidget);
      expect(
        find.text(UnifiedVisualEffect.dreamyBloom.description),
        findsOneWidget,
      );

      // Switching back to None resets state
      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();

      expect(provider.selectedVisualEffect, UnifiedVisualEffect.none);
      expect(find.text('ORIGINAL'), findsOneWidget);

      provider.dispose();
    });

    testWidgets(
      'renders cleanly on 320px constrained viewport without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final provider = UniquifierProvider();

        await tester.pumpWidget(
          buildTestableWidget(
            provider: provider,
            surfaceSize: const Size(320, 640),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('VISUAL FILTER CATALOG'), findsOneWidget);
        expect(find.text('None'), findsOneWidget);
        expect(tester.takeException(), isNull);

        provider.dispose();
      },
    );
  });
}
