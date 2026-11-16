import '../../models/unified_effect_preset.dart';
import '../../utils/variation_generator.dart';
import '../filter_builders.dart';
import '../settings_service.dart';
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
    double? sharpeningLevel,
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
    double introTrimOffset = 0.5,
    double? rotateAngle,
    Set<UnifiedVisualEffect>? activeVisualEffects,
    String? lutPath,
  }) {
    final vars =
        variations ??
        (enableDeepAntiFingerprint
            ? VariationGenerator.generate()
            : VideoVariations.fallback);
    final buffer = StringBuffer('-y');
    // `enableHardwareAcceleration` is intentionally ignored: input decoding is
    // always software now (see writeInputOptions) because hardware decoders
    // stall on heavy filter chains.
    writeInputOptions(
      buffer,
      inputPath,
      enableAutoTrim,
      totalDurationMs,
      thermalThrottle,
      introTrimOffset,
    );

    // Stability priority: keep a generous muxing queue so heavy 2K / Blur
    // chains cannot overflow, but leave filter threading at FFmpeg's default.
    // Sequential filter threading starved the encoder on heavy graphs and
    // surfaced as "100 buffers queued in out_0_0".
    buffer.write(' -max_muxing_queue_size 4096');

    // --- METADATA SANITIZATION & SPOOFING LOGIC ---
    if (removeMetadata) {
      // 1. SELALU hapus metadata asli, stream-level, & chapter
      buffer.write(' -map_metadata -1');
      buffer.write(' -map_metadata:s:v -1');
      buffer.write(' -map_metadata:s:a -1');
      buffer.write(' -map_chapters -1');

      // 2. Cegah FFmpeg menulis tag encoder (Lavf...) yang bisa dideteksi AI
      buffer.write(' -fflags +bitexact');
      buffer.write(' -flags:v +bitexact');
      buffer.write(' -flags:a +bitexact');

      // 3. HANYA suntikkan metadata kamera PALSU jika mode Deep Evasion (TikTok) aktif
      if (enableDeepAntiFingerprint) {
        FfmpegMetadataBuilder.writeMetadataTags(buffer, vars.deviceProfile);
      }
    }
    // ----------------------------------------------

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
      activeVisualEffects: activeVisualEffects,
      enableDynamicZoom: enableDynamicZoom,
      enableMicroOverlay: enableMicroOverlay,
      enableFrameSkip: enableFrameSkip,
      enableChromaShift: enableChromaShift,
      modifyAudio: modifyAudio,
      variations: vars,
      targetFps: targetFps,
      saturationLevel: saturationLevel,
      sharpeningLevel: sharpeningLevel,
      cropZoomScale: cropZoomScale,
      cropAnchor: cropAnchor,
      rotateAngle: rotateAngle,
      lutPath: lutPath,
    );

    if (outputPath.toLowerCase().endsWith('.mp4')) {
      buffer.write(' -bsf:v filter_units=remove_types=6');
    }

    buffer.write(' "${escapePath(outputPath)}"');
    return buffer.toString();
  }

  /// Appends input, decoder, and auto-trim arguments.
  static void writeInputOptions(
    StringBuffer buffer,
    String inputPath,
    bool autoTrim,
    int durationMs,
    bool thermalThrottle, [
    double introTrimOffset = 0.5,
  ]) {
    // Software decoding is locked in: MediaCodec / VAAPI hardware decode stalls
    // ("100 buffers queued in out_0_0") when fed heavy filter chains, so the
    // CPU decoder is the only deterministic path.
    buffer.write(' -hwaccel none');
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

  /// Returns `true` when [graph] is a self-contained complex graph that starts
  /// at [inputLabel] (`[0:v]` / `[0:a]`) and therefore must not be wrapped
  /// again. Simple chains never start with a stream label.
  static bool _isComplexGraph(String graph, String inputLabel) =>
      graph.startsWith(inputLabel);

  /// Appends complex filtergraph, video codecs, audio filters, and CFR flags.
  ///
  /// This method is the **single authority** for `-filter_complex` / `-map`,
  /// codec selection, muxing queue depth, pixel format, color space tags, and
  /// container flags. `FilterBuilders` returns raw graph strings only; all
  /// FFmpeg flag decisions live here.
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
    double? sharpeningLevel,
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
    double? rotateAngle,
    Set<UnifiedVisualEffect>? activeVisualEffects,
    String? lutPath,
  }) {
    final vars =
        variations ??
        (enableDeepAntiFingerprint
            ? VariationGenerator.generate()
            : VideoVariations.fallback);
    final hasActiveEffects =
        (activeVisualEffects ?? const <UnifiedVisualEffect>{}).any(
          (effect) => effect != UnifiedVisualEffect.none,
        );
    final hasVisual =
        modifyVisuals ||
        shouldUpscale ||
        enableHorizontalFlip ||
        enableBlurredCanvas ||
        enableDynamicZoom ||
        enableMicroOverlay ||
        enableFrameSkip ||
        enableChromaShift ||
        hasActiveEffects;
    final hasAudioProcess = modifyAudio || muteOriginalAudio;
    final isHighRes =
        targetResolution == TargetResolution.r2k ||
        targetResolution == TargetResolution.r4k;
    final effectiveFps = isHighRes ? 30 : (targetFps ?? 30);

    // --- Obtain raw filter graph strings from FilterBuilders ---------------
    final videoGraph = FilterBuilders.buildVideoFilter(
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
      sharpeningLevel: sharpeningLevel,
      cropZoomScale: cropZoomScale,
      cropAnchor: cropAnchor,
      rotateAngle: rotateAngle,
      activeVisualEffects: activeVisualEffects,
      lutPath: lutPath,
    );

    final audioGraph = FilterBuilders.buildAudioFilter(
      hasAudio: hasAudioProcess,
      hasVisual: hasVisual,
      modifyAudio: modifyAudio,
      enableDeepAntiFingerprint: enableDeepAntiFingerprint,
      enableAggressiveAudio: enableAggressiveAudio,
      muteOriginalAudio: muteOriginalAudio,
      variations: vars,
    );

    // Classify each graph: empty / copy / simple / complex (labeled).
    final videoEmpty = videoGraph.isEmpty;
    final audioEmpty = audioGraph.isEmpty;
    final videoCopy = videoGraph == 'copy';
    final audioCopy = audioGraph == 'copy';
    final videoProcessed = !videoEmpty && !videoCopy;
    final audioProcessed = !audioEmpty && !audioCopy;

    // --- Emit one `-filter_complex` graph with deterministic labels --------
    // FFmpeg v7+ rejects labeled graphs inside `-vf` / `-af`, so every
    // processed stream goes through `-filter_complex` and is mapped back
    // explicitly. `FilterBuilders` guarantees `[0:v]...[vout]` for complex
    // video graphs and `[0:a]...[aout]` for complex audio graphs.
    if (videoProcessed || audioProcessed) {
      final parts = <String>[];
      if (videoProcessed) {
        parts.add(
          _isComplexGraph(videoGraph, '[0:v]')
              ? videoGraph
              : '[0:v]$videoGraph[vout]',
        );
      }
      if (audioProcessed) {
        parts.add(
          _isComplexGraph(audioGraph, '[0:a]')
              ? audioGraph
              : '[0:a]$audioGraph[aout]',
        );
      }
      buffer.write(' -filter_complex "${parts.join(';')}"');

      buffer.write(videoProcessed ? ' -map "[vout]"' : ' -map 0:v');
      if (audioProcessed) {
        buffer.write(' -map "[aout]"');
      } else {
        buffer.write(' -map 0:a?');
      }
    }

    // --- Codec arguments (single authority) ---------------------------------
    if (videoProcessed) {
      // Encoder policy comes from FilterBuilders so H.264/H.265 and the
      // 2K/4K presets stay in one place.
      buffer.write(
        ' ${FilterBuilders.resolveVideoCodecArgs(videoCodec, targetResolution)}',
      );
      buffer.write(' -pix_fmt yuv420p');
      buffer.write(
        ' -colorspace bt709 -color_primaries bt709 -color_trc bt709'
        ' -color_range tv -movflags +faststart',
      );
    } else if (videoCopy || hasVisual) {
      buffer.write(' -c:v copy');
    }

    if (audioProcessed) {
      buffer.write(' -c:a aac -b:a 192k -ar 44100 -ac 2');
    } else if (audioCopy) {
      buffer.write(' -c:a copy');
    }

    // --- Constant Frame Rate ------------------------------------------------
    final fpsStr = isHighRes
        ? '30'
        : (targetFps != null
              ? '$targetFps'
              : vars.outputFps.toStringAsFixed(2));
    if (videoProcessed) buffer.write(' -fps_mode cfr -r $fpsStr');
    if (!hasVisual && !hasAudioProcess) buffer.write(' -c copy');
  }
}
