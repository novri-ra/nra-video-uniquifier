import '../filter_builders.dart';
import '../settings_service.dart';
import '../../utils/variation_generator.dart';
import 'ffmpeg_metadata_builder.dart';

/// Builder responsible for constructing complete FFmpeg command strings.
class FfmpegCommandBuilder {
  /// Escapes double quotes in file paths for shell safety.
  static String escapePath(String path) => path.replaceAll('"', r'\"');

  /// Builds dynamic FFmpeg command string with full anti-fingerprint filters.
  static String buildCommand({
    required String inputPath,
    required String outputPath,
    bool removeMetadata = true,
    bool modifyAudio = true,
    bool modifyVisuals = true,
    bool upscale1080p = false,
    bool? upscale,
    TargetResolution targetResolution = TargetResolution.r1080p,
    UpscaleEngine upscaleEngine = UpscaleEngine.lanczos,
    VideoCodec videoCodec = VideoCodec.h264,
    bool enableEnhanceAndDenoise = true,
    bool enableDeepAntiFingerprint = true,
    bool enableHorizontalFlip = false,
    bool enableAggressiveAudio = false,
    bool enableAutoTrim = false,
    int totalDurationMs = 0,
    bool isPortrait = false,
    bool enableHardwareAcceleration = false,
    bool enableBlurredCanvas = false,
    double canvasScalePercent = 95.0,
    bool muteOriginalAudio = false,
    bool enableDynamicZoom = false,
    bool enableMicroOverlay = false,
    bool enableFrameSkip = false,
    bool enableChromaShift = false,
    VideoVariations? variations,
    bool thermalThrottle = false,
    int? targetFps,
    double? saturationLevel,
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
    double introTrimOffset = 0.5,
  }) {
    final vars =
        variations ??
        (enableDeepAntiFingerprint
            ? VariationGenerator.generate()
            : VideoVariations.fallback);
    final buffer = StringBuffer('-y');
    writeInputOptions(
      buffer,
      inputPath,
      enableHardwareAcceleration,
      enableAutoTrim,
      totalDurationMs,
      thermalThrottle,
      introTrimOffset,
    );
    if (removeMetadata) {
      FfmpegMetadataBuilder.writeMetadataTags(buffer, vars.deviceProfile);
    }
    writeFilterAndCodecOptions(
      buffer: buffer,
      modifyVisuals: modifyVisuals,
      shouldUpscale: upscale ?? upscale1080p,
      targetResolution: targetResolution,
      upscaleEngine: upscaleEngine,
      videoCodec: videoCodec,
      enableEnhanceAndDenoise: enableEnhanceAndDenoise,
      enableDeepAntiFingerprint: enableDeepAntiFingerprint,
      enableHorizontalFlip: enableHorizontalFlip,
      enableAggressiveAudio: enableAggressiveAudio,
      isPortrait: isPortrait,
      enableBlurredCanvas: enableBlurredCanvas,
      canvasScalePercent: canvasScalePercent,
      muteOriginalAudio: muteOriginalAudio,
      enableDynamicZoom: enableDynamicZoom,
      enableMicroOverlay: enableMicroOverlay,
      enableFrameSkip: enableFrameSkip,
      enableChromaShift: enableChromaShift,
      modifyAudio: modifyAudio,
      variations: vars,
      targetFps: targetFps,
      saturationLevel: saturationLevel,
      cropZoomScale: cropZoomScale,
      cropAnchor: cropAnchor,
    );
    buffer.write(' "${escapePath(outputPath)}"');
    return buffer.toString();
  }

  /// Appends input, hardware acceleration, and auto-trim arguments.
  static void writeInputOptions(
    StringBuffer buffer,
    String inputPath,
    bool hwAccel,
    bool autoTrim,
    int durationMs,
    bool thermalThrottle, [
    double introTrimOffset = 0.5,
  ]) {
    if (hwAccel) buffer.write(' -hwaccel auto');
    buffer.write(thermalThrottle ? ' -threads 4' : ' -threads 0');
    if (autoTrim) {
      final ss = introTrimOffset.clamp(0.0, 3.0);
      final ssFormatted = ss == 0.5 ? '0.5' : ss.toStringAsFixed(2);
      buffer.write(' -ss $ssFormatted');
      final trimTotalMs = ((ss + 0.5) * 1000).toInt();
      if (durationMs > trimTotalMs) {
        buffer.write(
          ' -t ${((durationMs - trimTotalMs) / 1000).toStringAsFixed(2)}',
        );
      }
    }
    buffer.write(' -i "${escapePath(inputPath)}"');
  }

  /// Appends complex filtergraph, video codecs, audio filters, and CFR flags.
  static void writeFilterAndCodecOptions({
    required StringBuffer buffer,
    required bool modifyVisuals,
    required bool shouldUpscale,
    required TargetResolution targetResolution,
    required UpscaleEngine upscaleEngine,
    required VideoCodec videoCodec,
    required bool enableEnhanceAndDenoise,
    required bool enableDeepAntiFingerprint,
    required bool enableHorizontalFlip,
    required bool enableAggressiveAudio,
    required bool isPortrait,
    required bool enableBlurredCanvas,
    required double canvasScalePercent,
    required bool muteOriginalAudio,
    required bool enableDynamicZoom,
    required bool enableMicroOverlay,
    required bool enableFrameSkip,
    required bool enableChromaShift,
    required bool modifyAudio,
    VideoVariations? variations,
    int? targetFps,
    double? saturationLevel,
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
  }) {
    final vars =
        variations ??
        (enableDeepAntiFingerprint
            ? VariationGenerator.generate()
            : VideoVariations.fallback);
    final hasVisual =
        modifyVisuals ||
        shouldUpscale ||
        enableHorizontalFlip ||
        enableBlurredCanvas ||
        enableDynamicZoom ||
        enableMicroOverlay ||
        enableFrameSkip ||
        enableChromaShift;
    final hasAudioProcess = modifyAudio || muteOriginalAudio;
    final isHighRes =
        targetResolution == TargetResolution.r2k ||
        targetResolution == TargetResolution.r4k;
    final effectiveFps = isHighRes ? 30 : (targetFps ?? 30);

    buffer.write(
      FilterBuilders.buildVideoFilter(
        hasVisual: hasVisual,
        hasAudio: hasAudioProcess,
        modifyVisuals: modifyVisuals,
        upscale: shouldUpscale,
        targetResolution: targetResolution,
        upscaleEngine: upscaleEngine,
        videoCodec: videoCodec,
        enableEnhanceAndDenoise: enableEnhanceAndDenoise,
        enableDeepAntiFingerprint: enableDeepAntiFingerprint,
        enableHorizontalFlip: enableHorizontalFlip,
        isPortrait: isPortrait,
        enableBlurredCanvas: enableBlurredCanvas,
        canvasScalePercent: canvasScalePercent,
        enableDynamicZoom: enableDynamicZoom,
        enableMicroOverlay: enableMicroOverlay,
        enableFrameSkip: enableFrameSkip,
        enableChromaShift: enableChromaShift,
        variations: vars,
        targetFps: effectiveFps,
        saturationLevel: saturationLevel,
        cropZoomScale: cropZoomScale,
        cropAnchor: cropAnchor,
      ),
    );
    buffer.write(
      FilterBuilders.buildAudioFilter(
        hasAudio: hasAudioProcess,
        hasVisual: hasVisual,
        modifyAudio: modifyAudio,
        enableDeepAntiFingerprint: enableDeepAntiFingerprint,
        enableAggressiveAudio: enableAggressiveAudio,
        muteOriginalAudio: muteOriginalAudio,
        variations: vars,
      ),
    );
    final fpsStr = isHighRes
        ? '30'
        : (targetFps != null
              ? '$targetFps'
              : vars.outputFps.toStringAsFixed(2));
    if (hasVisual) buffer.write(' -fps_mode cfr -r $fpsStr');
    if (!hasVisual && !hasAudioProcess) buffer.write(' -c copy');
  }
}
