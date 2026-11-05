import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/shared/widgets/interactive_preview_slider.dart';

void main() {
  group('InteractivePreviewSlider Tests', () {
    testWidgets('renders parameter name and label correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractivePreviewSlider(
              value: 1.0,
              min: 1.0,
              max: 1.5,
              label: '1.00x',
              parameterName: 'Crop Zoom',
              effect: PreviewEffect.cropZoom,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Crop Zoom'), findsOneWidget);
      expect(find.text('1.00x'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('shows floating preview overlay on drag and hides on release', (
      tester,
    ) async {
      double currentValue = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return InteractivePreviewSlider(
                  value: currentValue,
                  min: 1.0,
                  max: 1.5,
                  label: '${currentValue.toStringAsFixed(2)}x',
                  parameterName: 'Crop Zoom',
                  effect: PreviewEffect.cropZoom,
                  onChanged: (val) {
                    setState(() => currentValue = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Initially no floating overlay (FadeTransition above Material)
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Start drag to trigger overlay
      final gesture = await tester.startGesture(tester.getCenter(slider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Overlay should display the thumbnail placeholder icon
      expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);

      // Move slider
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // Release drag to trigger fade-out
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Overlay should be removed after fade-out
      expect(find.byIcon(Icons.videocam_outlined), findsNothing);
    });

    testWidgets('supports all PreviewEffect variants without error', (
      tester,
    ) async {
      for (final effect in PreviewEffect.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractivePreviewSlider(
                value: 50.0,
                min: 0.0,
                max: 100.0,
                label: '50%',
                parameterName: effect.name,
                effect: effect,
                onChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.text(effect.name), findsOneWidget);
      }
    });

    testWidgets('does not overflow on small 320px viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(8),
              child: InteractivePreviewSlider(
                value: 1.08,
                min: 1.0,
                max: 1.5,
                label: '1.08x',
                parameterName: 'ZOOM & FACE FOCUS (CROP)',
                effect: PreviewEffect.cropZoom,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('wires Micro-Rotation slider and formats angle label on drag', (
      tester,
    ) async {
      double currentAngle = 0.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return InteractivePreviewSlider(
                  value: currentAngle,
                  min: -2.0,
                  max: 2.0,
                  divisions: 40,
                  label:
                      '${currentAngle >= 0 ? '+' : ''}${currentAngle.toStringAsFixed(1)}°',
                  parameterName: 'MICRO-ROTATION / TILT',
                  effect: PreviewEffect.microRotation,
                  onChanged: (v) => setState(() => currentAngle = v),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('MICRO-ROTATION / TILT'), findsOneWidget);
      expect(find.text('+0.0°'), findsOneWidget);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Slider)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);

      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(currentAngle, isNonZero);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets(
      'wires Sharpening, Saturation, and Canvas Scale sliders correctly',
      (tester) async {
        double sharp = 1.0;
        double sat = 1.0;
        double scale = 95.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  InteractivePreviewSlider(
                    value: sharp,
                    min: 0.1,
                    max: 2.0,
                    label: '${sharp.toStringAsFixed(1)}x',
                    parameterName: 'SHARPENING INTENSITY',
                    effect: PreviewEffect.sharpening,
                    onChanged: (v) => sharp = v,
                  ),
                  InteractivePreviewSlider(
                    value: sat,
                    min: 0.8,
                    max: 1.3,
                    label: '${sat.toStringAsFixed(2)}x',
                    parameterName: 'SATURATION / VIBRANCE',
                    effect: PreviewEffect.saturation,
                    onChanged: (v) => sat = v,
                  ),
                  InteractivePreviewSlider(
                    value: scale,
                    min: 70.0,
                    max: 100.0,
                    label: '${scale.toInt()}%',
                    parameterName: 'BLURRED CANVAS SCALE',
                    effect: PreviewEffect.canvasScale,
                    onChanged: (v) => scale = v,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('SHARPENING INTENSITY'), findsOneWidget);
        expect(find.text('SATURATION / VIBRANCE'), findsOneWidget);
        expect(find.text('BLURRED CANVAS SCALE'), findsOneWidget);
      },
    );

    testWidgets(
      'displays rendering indicator badge when isPreviewRendering is true',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractivePreviewSlider(
                value: 1.0,
                min: 0.1,
                max: 2.0,
                label: '1.0x',
                parameterName: 'SHARPENING',
                effect: PreviewEffect.sharpening,
                isPreviewRendering: true,
                onChanged: (_) {},
              ),
            ),
          ),
        );

        // Start drag to display overlay
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Slider)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Rendering preview...'), findsOneWidget);

        await gesture.up();
        await tester.pump(const Duration(milliseconds: 250));
      },
    );
  });
}
