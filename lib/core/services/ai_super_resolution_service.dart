import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'settings_service.dart';

/// Execution plan descriptor for neural and mathematical upscaling engines.
class AiSuperResolutionPlan {
  final UpscaleEngine engine;
  final TargetResolution targetResolution;
  final bool isPortrait;
  final int targetWidth;
  final int targetHeight;
  final bool isVulkanAccelerated;
  final bool isFallbackEngaged;
  final String modelName;

  const AiSuperResolutionPlan({
    required this.engine,
    required this.targetResolution,
    required this.isPortrait,
    required this.targetWidth,
    required this.targetHeight,
    required this.isVulkanAccelerated,
    required this.isFallbackEngaged,
    required this.modelName,
  });

  String get summary =>
      '${engine.label} -> ${targetWidth}x$targetHeight ($modelName, Vulkan: $isVulkanAccelerated, Fallback: $isFallbackEngaged)';
}

/// Native bridge and capability manager for NCNN Vulkan Neural Super-Resolution.
class AiSuperResolutionService {
  static const MethodChannel _channel = MethodChannel('id.novrira.videouniquifier/ai_super_res');

  static const String modelRealEsrganAnimeVideoV3 = 'Real-ESRGAN AnimeVideo-v3 Compact (x2/x4 NCNN Vulkan)';
  static const String modelLanczosFallback = 'Lanczos3 Anti-Aliased Mathematical Matrix';

  /// Extracts bundled NCNN model weights from assets to internal storage cache.
  static Future<List<String>> prepareModelAssets() async {
    const modelFiles = [
      'realesr-animevideov3-x2.bin',
      'realesr-animevideov3-x2.param',
      'realesr-animevideov3-x4.bin',
      'realesr-animevideov3-x4.param',
    ];
    final outPaths = <String>[];
    try {
      final tempDir = await getTemporaryDirectory();
      final modelsDir = Directory('${tempDir.path}/models');
      if (!await modelsDir.exists()) await modelsDir.create(recursive: true);
      for (final name in modelFiles) {
        final target = File('${modelsDir.path}/$name');
        if (!await target.exists() || await target.length() == 0) {
          final data = await rootBundle.load('assets/models/$name');
          await target.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
        }
        outPaths.add(target.path);
      }
    } catch (_) {}
    return outPaths;
  }

  /// Queries whether native Vulkan compute is supported on the target GPU.
  static Future<bool> isVulkanSupported() async {
    if (!Platform.isAndroid) return false;
    try {
      final supported = await _channel.invokeMethod<bool>('isVulkanSupported');
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves neural engine information and available models.
  static Future<Map<String, dynamic>> getEngineInfo() async {
    final vulkan = await isVulkanSupported();
    return {
      'engine': 'NCNN Vulkan Neural Super-Resolution',
      'model': modelRealEsrganAnimeVideoV3,
      'vulkanSupported': vulkan,
      'tilingSupport': true,
      'resilienceFallback': 'Hardware-accelerated Lanczos3',
    };
  }

  /// Resolves execution plan between NCNN Vulkan compute and Lanczos fallback.
  static Future<AiSuperResolutionPlan> resolvePlan({
    required UpscaleEngine engine,
    required TargetResolution targetResolution,
    required bool isPortrait,
  }) async {
    final targetW = isPortrait ? targetResolution.height : targetResolution.width;
    final targetH = isPortrait ? targetResolution.width : targetResolution.height;

    if (engine == UpscaleEngine.neuralAi) {
      final vulkanAvailable = await isVulkanSupported();
      if (!vulkanAvailable) {
        debugPrint('[AiSuperResolution] Vulkan compute unavailable on this device. Transparent fallback: Real-ESRGAN -> Lanczos3.');
      }
      return AiSuperResolutionPlan(
        engine: engine,
        targetResolution: targetResolution,
        isPortrait: isPortrait,
        targetWidth: targetW,
        targetHeight: targetH,
        isVulkanAccelerated: vulkanAvailable,
        isFallbackEngaged: !vulkanAvailable,
        modelName: vulkanAvailable
            ? modelRealEsrganAnimeVideoV3
            : '$modelRealEsrganAnimeVideoV3 -> $modelLanczosFallback',
      );
    }

    return AiSuperResolutionPlan(
      engine: engine,
      targetResolution: targetResolution,
      isPortrait: isPortrait,
      targetWidth: targetW,
      targetHeight: targetH,
      isVulkanAccelerated: false,
      isFallbackEngaged: false,
      modelName: modelLanczosFallback,
    );
  }

  /// Generates human-readable pipeline description for telemetry and logs.
  static String describePipeline({
    required UpscaleEngine engine,
    required TargetResolution targetResolution,
    required bool isPortrait,
  }) {
    final targetW = isPortrait ? targetResolution.height : targetResolution.width;
    final targetH = isPortrait ? targetResolution.width : targetResolution.height;
    if (engine == UpscaleEngine.neuralAi) {
      return 'Real-ESRGAN NCNN Vulkan AI ($targetW×$targetH) • Auto-Fallback Lanczos3 Enabled';
    }
    return 'Lanczos3 3-Lobe Anti-Aliasing ($targetW×$targetH)';
  }
}
