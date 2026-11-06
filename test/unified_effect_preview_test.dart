import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';
import 'package:nra_video_uniquifier/core/services/ffmpeg_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnifiedVisualEffect & FilterBuilders Tests', () {
    test(
      'verifies all UnifiedVisualEffect enum entries exist with metadata',
      () {
        expect(UnifiedVisualEffect.values.length, 7);
        expect(UnifiedVisualEffect.none.id, 'none');
        expect(UnifiedVisualEffect.blurredCanvas.id, 'blurred_canvas');
        expect(UnifiedVisualEffect.motionEcho.id, 'motion_echo');
        expect(UnifiedVisualEffect.rgbSplit.id, 'rgb_split');
        expect(UnifiedVisualEffect.dreamyBloom.id, 'dreamy_bloom');
        expect(UnifiedVisualEffect.film16mm.id, 'film_16mm');
        expect(UnifiedVisualEffect.dynamicGrain.id, 'dynamic_grain');

        expect(
          UnifiedVisualEffect.fromId('rgb_split'),
          UnifiedVisualEffect.rgbSplit,
        );
        expect(UnifiedVisualEffect.fromId('unknown'), UnifiedVisualEffect.none);
      },
    );

    test('generates valid filter string for Blurred Canvas', () {
      final filter = FilterBuilders.buildBlurredCanvasEffect(
        canvasScalePercent: 90.0,
      );
      expect(filter, contains('split=2'));
      expect(filter, contains('boxblur='));
      expect(filter, contains('scale=iw*0.90'));
      expect(filter, contains('overlay=(W-w)/2:(H-h)/2'));
    });

    test('generates valid filter string for Temporal Motion Echo', () {
      final filter = FilterBuilders.buildMotionEchoEffect(
        delaySeconds: 0.15,
        opacity: 0.35,
      );
      expect(filter, contains('split=2'));
      expect(filter, contains('setpts=PTS+0.150/TB'));
      expect(filter, contains('blend=all_mode=addition:all_opacity=0.35'));
    });

    test('generates valid filter string for RGB Temporal Split', () {
      final filter = FilterBuilders.buildRgbSplitEffect(
        delayGreen: 0.05,
        delayBlue: 0.10,
      );
      expect(filter, contains('split=3'));
      expect(filter, contains('lutrgb=g=0:b=0'));
      expect(filter, contains('setpts=PTS+0.050/TB'));
      expect(filter, contains('setpts=PTS+0.100/TB'));
      expect(filter, contains('blend=all_mode=addition'));
    });

    test('generates valid filter string for Dreamy Bloom', () {
      final filter = FilterBuilders.buildDreamyBloomEffect(
        sigma: 12.0,
        opacity: 0.38,
      );
      expect(filter, contains('split=2'));
      expect(filter, contains('gblur=sigma=12.0:steps=2'));
      expect(filter, contains('blend=all_mode=screen:all_opacity=0.38'));
    });

    test('generates valid filter string for 16mm Nostalgia & Film Tone', () {
      final filter = FilterBuilders.build16mmFilmToneEffect();
      expect(filter, contains('curves=vintage'));
      expect(filter, contains('colorbalance='));
      expect(filter, contains('eq=contrast=1.06:saturation=0.92'));
    });

    test('generates valid filter string for Dynamic Noise / Film Grain', () {
      final filter = FilterBuilders.buildDynamicGrainEffect(strength: 8);
      expect(filter, 'noise=alls=8:allf=t+u');
    });

    test('buildUnifiedEffectFilter maps all enum types correctly', () {
      for (final effect in UnifiedVisualEffect.values) {
        final filter = FilterBuilders.buildUnifiedEffectFilter(effect);
        if (effect == UnifiedVisualEffect.none) {
          expect(filter, isEmpty);
        } else {
          expect(filter, isNotEmpty);
        }
      }
    });

    test('buildPreviewFilterChain composites slider values and effects', () {
      final filter = FilterBuilders.buildPreviewFilterChain(
        cropZoomScale: 1.25,
        cropAnchor: 'top',
        rotateAngle: 1.5,
        saturationLevel: 1.2,
        sharpeningLevel: 1.5,
        effect: UnifiedVisualEffect.film16mm,
      );

      expect(filter, contains('crop=iw/1.25:ih/1.25'));
      expect(filter, contains('rotate='));
      expect(filter, contains('unsharp=3:3:0.90:3:3:0.0'));
      expect(filter, contains('eq=saturation=1.200'));
      expect(filter, contains('curves=vintage'));
    });

    test(
      'orderEffectsByStage sorts effects in strict 4-stage pipeline order',
      () {
        final unordered = {
          UnifiedVisualEffect.dynamicGrain,
          UnifiedVisualEffect.dreamyBloom,
          UnifiedVisualEffect.blurredCanvas,
          UnifiedVisualEffect.motionEcho,
        };
        final ordered = FilterBuilders.orderEffectsByStage(unordered);

        expect(ordered, [
          UnifiedVisualEffect.blurredCanvas, // 1. Spatial
          UnifiedVisualEffect.motionEcho, // 2. Temporal
          UnifiedVisualEffect.dreamyBloom, // 3. Tonal
          UnifiedVisualEffect.dynamicGrain, // 4. Texture
        ]);
      },
    );

    test(
      'buildPreviewFilterChain chains multi-stage effects with valid stream labels',
      () {
        final multiFilter = FilterBuilders.buildPreviewFilterChain(
          cropZoomScale: 1.1,
          activeEffects: {
            UnifiedVisualEffect.blurredCanvas,
            UnifiedVisualEffect.motionEcho,
            UnifiedVisualEffect.dynamicGrain,
          },
        );

        // Stage 0 (transforms): outputs [v0]
        expect(multiFilter, contains('[v0]'));
        // Stage 1 (Blurred Canvas): takes [v0], outputs [v1]
        expect(multiFilter, contains('[v0]split=2'));
        expect(multiFilter, contains('[v1]'));
        // Stage 2 (Motion Echo): takes [v1], outputs [v2]
        expect(multiFilter, contains('[v1]split=2'));
        expect(multiFilter, contains('[v2]'));
        // Stage 3 (Dynamic Grain): takes [v2]
        expect(multiFilter, contains('[v2]noise=alls=8:allf=t+u'));
      },
    );
  });

  group('UniquifierProvider Preview State Tests', () {
    test('initializes with default preview state', () {
      final provider = UniquifierProvider();
      expect(provider.isPreviewRendering, isFalse);
      expect(provider.renderedPreviewFramePath, isNull);
      expect(provider.selectedVisualEffect, UnifiedVisualEffect.none);
      provider.dispose();
    });

    test('setVisualEffect and setSelectedVisualEffect update state', () {
      final provider = UniquifierProvider();
      provider.setVisualEffect(UnifiedVisualEffect.dreamyBloom);
      expect(provider.selectedVisualEffect, UnifiedVisualEffect.dreamyBloom);

      provider.setSelectedVisualEffect(UnifiedVisualEffect.motionEcho);
      expect(provider.selectedVisualEffect, UnifiedVisualEffect.motionEcho);

      provider.setSelectedVisualEffect(UnifiedVisualEffect.blurredCanvas);
      expect(provider.selectedVisualEffect, UnifiedVisualEffect.blurredCanvas);

      provider.setMotionEchoDelay(0.30);
      expect(provider.motionEchoDelay, closeTo(0.30, 0.001));

      provider.dispose();
    });

    test(
      'requestFilteredPreviewDebounced handles empty file path gracefully',
      () {
        final provider = UniquifierProvider();
        provider.requestFilteredPreviewDebounced(immediate: true);
        expect(provider.isPreviewRendering, isFalse);
        expect(provider.renderedPreviewFramePath, isNull);
        provider.dispose();
      },
    );

    test('clearSelection clears preview state', () {
      final provider = UniquifierProvider();
      provider.setVisualEffect(UnifiedVisualEffect.rgbSplit);
      provider.clearSelection();
      expect(provider.renderedPreviewFramePath, isNull);
      expect(provider.isPreviewRendering, isFalse);
      provider.dispose();
    });

    test(
      'toggleVisualEffect supports interactive multi-select and none reset',
      () {
        final provider = UniquifierProvider();
        expect(provider.isEffectActive(UnifiedVisualEffect.none), isTrue);
        expect(provider.activeVisualEffects, {UnifiedVisualEffect.none});

        // Toggle on Blurred Canvas
        provider.toggleVisualEffect(UnifiedVisualEffect.blurredCanvas);
        expect(
          provider.isEffectActive(UnifiedVisualEffect.blurredCanvas),
          isTrue,
        );
        expect(provider.isEffectActive(UnifiedVisualEffect.none), isFalse);

        // Toggle on Motion Echo (now 2 active)
        provider.toggleVisualEffect(UnifiedVisualEffect.motionEcho);
        expect(
          provider.isEffectActive(UnifiedVisualEffect.blurredCanvas),
          isTrue,
        );
        expect(provider.isEffectActive(UnifiedVisualEffect.motionEcho), isTrue);
        expect(provider.activeVisualEffects.length, 2);

        // Toggle off Blurred Canvas (now only Motion Echo)
        provider.toggleVisualEffect(UnifiedVisualEffect.blurredCanvas);
        expect(
          provider.isEffectActive(UnifiedVisualEffect.blurredCanvas),
          isFalse,
        );
        expect(provider.isEffectActive(UnifiedVisualEffect.motionEcho), isTrue);

        // Toggle off Motion Echo (empty -> falls back to none)
        provider.toggleVisualEffect(UnifiedVisualEffect.motionEcho);
        expect(provider.isEffectActive(UnifiedVisualEffect.none), isTrue);
        expect(provider.activeVisualEffects, {UnifiedVisualEffect.none});

        // Multiple active then tap None resets everything to none
        provider.toggleVisualEffect(UnifiedVisualEffect.rgbSplit);
        provider.toggleVisualEffect(UnifiedVisualEffect.film16mm);
        expect(provider.activeVisualEffects.length, 2);
        provider.toggleVisualEffect(UnifiedVisualEffect.none);
        expect(provider.activeVisualEffects, {UnifiedVisualEffect.none});
        expect(provider.isEffectActive(UnifiedVisualEffect.none), isTrue);

        provider.dispose();
      },
    );
  });

  group('FfmpegService Preview Frame Engine Tests', () {
    test(
      'renderFilteredPreviewFrame returns null on non-existent input',
      () async {
        final result = await FfmpegService.renderFilteredPreviewFrame(
          inputPath:
              'non_existent_video_path_${DateTime.now().millisecondsSinceEpoch}.mp4',
          filterComplex: 'noise=alls=8:allf=t+u',
          timestampSeconds: 0.5,
        );
        expect(result, isNull);
      },
    );
  });
}
