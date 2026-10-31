import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/services/ai_super_resolution_service.dart';
import 'package:nra_video_uniquifier/core/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('id.novrira.videouniquifier/ai_super_res');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'isVulkanSupported':
          return true;
        case 'getModelInfo':
          return {
            'model': 'Real-ESRGAN AnimeVideo-v3 Compact (x2/x4 NCNN Vulkan)',
            'tilingSupport': true,
            'fallbackEngine': 'Hardware-accelerated Lanczos3',
          };
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AiSuperResolutionService Tests', () {
    test('isVulkanSupported queries platform channel safely', () async {
      final supported = await AiSuperResolutionService.isVulkanSupported();
      expect(supported, isA<bool>());
    });

    test('getEngineInfo provides metadata and fallback information', () async {
      final info = await AiSuperResolutionService.getEngineInfo();
      expect(info['engine'], contains('NCNN Vulkan'));
      expect(info['model'], contains('Real-ESRGAN AnimeVideo-v3'));
      expect(info['tilingSupport'], isTrue);
      expect(info['resilienceFallback'], contains('Lanczos3'));
    });

    test('resolvePlan for Lanczos3 mathematical engine', () async {
      final planPortrait = await AiSuperResolutionService.resolvePlan(
        engine: UpscaleEngine.lanczos,
        targetResolution: TargetResolution.r1080p,
        isPortrait: true,
      );
      expect(planPortrait.engine, equals(UpscaleEngine.lanczos));
      expect(planPortrait.targetWidth, equals(1080));
      expect(planPortrait.targetHeight, equals(1920));
      expect(planPortrait.isVulkanAccelerated, isFalse);
      expect(planPortrait.isFallbackEngaged, isFalse);
      expect(planPortrait.summary, contains('1080x1920'));

      final planLandscape = await AiSuperResolutionService.resolvePlan(
        engine: UpscaleEngine.lanczos,
        targetResolution: TargetResolution.r4k,
        isPortrait: false,
      );
      expect(planLandscape.targetWidth, equals(3840));
      expect(planLandscape.targetHeight, equals(2160));
    });

    test('resolvePlan for Real-ESRGAN Neural AI engine with Vulkan acceleration', () async {
      final plan = await AiSuperResolutionService.resolvePlan(
        engine: UpscaleEngine.neuralAi,
        targetResolution: TargetResolution.r2k,
        isPortrait: true,
      );
      expect(plan.engine, equals(UpscaleEngine.neuralAi));
      expect(plan.targetWidth, equals(1440));
      expect(plan.targetHeight, equals(2560));
      expect(plan.summary, contains('Real-ESRGAN'));
    });

    test('describePipeline generates clean human-readable summaries', () {
      final descLanczos = AiSuperResolutionService.describePipeline(
        engine: UpscaleEngine.lanczos,
        targetResolution: TargetResolution.r1080p,
        isPortrait: false,
      );
      expect(descLanczos, contains('Lanczos3'));
      expect(descLanczos, contains('1920×1080'));

      final descAi = AiSuperResolutionService.describePipeline(
        engine: UpscaleEngine.neuralAi,
        targetResolution: TargetResolution.r4k,
        isPortrait: true,
      );
      expect(descAi, contains('Real-ESRGAN NCNN Vulkan AI'));
      expect(descAi, contains('2160×3840'));
      expect(descAi, contains('Auto-Fallback Lanczos3 Enabled'));
    });

    test('prepareModelAssets safely extracts or returns asset model paths', () async {
      final paths = await AiSuperResolutionService.prepareModelAssets();
      expect(paths, isA<List<String>>());
    });
  });
}
