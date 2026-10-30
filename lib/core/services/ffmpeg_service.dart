import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'media_scanner_service.dart';
import 'notification_service.dart';
import 'render_diagnostic_service.dart';
import 'settings_service.dart';
import 'filter_builders.dart';
import '../utils/variation_generator.dart';

export 'render_diagnostic_service.dart';
export '../utils/variation_generator.dart';

class FfmpegService {
  static String _escapePath(String path) => path.replaceAll('"', r'\"');

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
  }) {
    final safeInput = _escapePath(inputPath);
    final safeOutput = _escapePath(outputPath);
    final buffer = StringBuffer('-y');
    if (enableHardwareAcceleration) {
      buffer.write(' -hwaccel auto');
    }
    if (enableAutoTrim) {
      buffer.write(' -ss 0.5');
      if (totalDurationMs > 1500) {
        final trimDur = ((totalDurationMs - 1000) / 1000).toStringAsFixed(2);
        buffer.write(' -t $trimDur');
      }
    }
    buffer.write(' -i "$safeInput"');
    if (removeMetadata) {
      buffer.write(' -map_metadata -1 -map_chapters -1 -bitexact -fflags +bitexact');
      buffer.write(' -metadata make="Apple" -metadata model="iPhone 15 Pro Max" -metadata encoder="Apple QuickTime"');
      buffer.write(' -metadata:s:v:0 handler_name="Core Media Video" -metadata:s:a:0 handler_name="Core Media Audio"');
    }

    VideoVariations vars;
    try {
      vars = variations ??
          (enableDeepAntiFingerprint
              ? VariationGenerator.generate()
              : VideoVariations.fallback);
    } catch (_) {
      vars = VideoVariations.fallback;
    }

    final shouldUpscale = upscale ?? upscale1080p;
    final hasVisual = modifyVisuals ||
        shouldUpscale ||
        enableHorizontalFlip ||
        enableBlurredCanvas ||
        enableDynamicZoom ||
        enableMicroOverlay ||
        enableFrameSkip ||
        enableChromaShift;
    final hasAudioProcess = modifyAudio || muteOriginalAudio;
    buffer.write(FilterBuilders.buildVideoFilter(
      hasVisual: hasVisual,
      hasAudio: hasAudioProcess,
      modifyVisuals: modifyVisuals,
      upscale: shouldUpscale,
      targetResolution: targetResolution,
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
    ));
    buffer.write(FilterBuilders.buildAudioFilter(
      hasAudio: hasAudioProcess,
      hasVisual: hasVisual,
      enableDeepAntiFingerprint: enableDeepAntiFingerprint,
      enableAggressiveAudio: enableAggressiveAudio,
      muteOriginalAudio: muteOriginalAudio,
      variations: vars,
    ));

    if (hasVisual) {
      buffer.write(' -r ${vars.outputFps.toStringAsFixed(2)}');
    }
    if (!hasVisual && !hasAudioProcess) buffer.write(' -c copy');
    buffer.write(' "$safeOutput"');
    return buffer.toString();
  }

  /// Cancels any currently running FFmpeg operations.
  static Future<void> cancel() async {
    try {
      await NotificationService.cancelProgressNotification();
      await FFmpegKit.cancel();
    } catch (_) {}
  }

  /// Safely copies an input video to app temp cache before feeding to native FFmpeg.
  static Future<File> stageInputFile(String inputPath) async {
    final inputFile = File(inputPath);
    if (!inputFile.existsSync() || inputFile.lengthSync() == 0) {
      throw Exception('Source video file does not exist or is empty: $inputPath');
    }
    final tempDir = await getTemporaryDirectory();
    final ext = inputPath.contains('.') ? inputPath.split('.').last : 'mp4';
    final staged = File('${tempDir.path}/staged_${DateTime.now().millisecondsSinceEpoch}.$ext');
    return await inputFile.copy(staged.path);
  }

  /// Extracts 1st-frame thumbnail via lightweight FFmpeg command.
  static Future<String?> extractThumbnail(String inputPath, {String? targetPath}) async {
    try {
      final inputFile = File(inputPath);
      if (!inputFile.existsSync() || inputFile.lengthSync() == 0) return null;
      final tempDir = await getTemporaryDirectory();
      final thumbPath = targetPath ?? '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final safeInput = _escapePath(inputPath);
      final safeThumb = _escapePath(thumbPath);
      final cmd = '-y -ss 00:00:00.500 -i "$safeInput" -vframes 1 -q:v 2 "$safeThumb"';
      final session = await FFmpegKit.execute(cmd);
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode) && File(thumbPath).existsSync()) {
        return thumbPath;
      }
    } catch (_) {}
    return null;
  }

  /// Resolves the public target directory (/storage/emulated/0/Movies/Uniquifier).
  static Future<Directory> _resolveTargetDir() async {
    if (Platform.isAndroid) {
      final publicMovies = Directory('/storage/emulated/0/Movies/Uniquifier');
      try {
        if (!await publicMovies.exists()) await publicMovies.create(recursive: true);
        return publicMovies;
      } catch (_) {
        try {
          final dirs = await getExternalStorageDirectories(type: StorageDirectory.movies);
          if (dirs != null && dirs.isNotEmpty) {
            final fallback = Directory('${dirs.first.path}/Uniquifier');
            if (!await fallback.exists()) await fallback.create(recursive: true);
            return fallback;
          }
        } catch (_) {}
      }
    }
    final appDocs = await getApplicationDocumentsDirectory();
    final localMovies = Directory('${appDocs.path}/Movies/Uniquifier');
    if (!await localMovies.exists()) await localMovies.create(recursive: true);
    return localMovies;
  }

  /// Generates the target output path with collision-free timestamp pattern.
  static Future<String> generateOutputPath(String inputPath) async {
    final fileName = inputPath.split(RegExp(r'[/\\]')).last;
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex != -1 ? fileName.substring(0, dotIndex) : fileName;
    final targetDir = await _resolveTargetDir();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${targetDir.path}/UQ_${baseName}_$timestamp.mp4';
  }

  static Future<({int durationMs, int width, int height})> _probeMediaMeta(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      if (info != null) {
        final durMs = ((double.tryParse(info.getDuration() ?? '') ?? 0.0) * 1000).toInt();
        for (final s in info.getStreams()) {
          if (s.getType() == 'video') {
            return (durationMs: durMs, width: s.getWidth() ?? 0, height: s.getHeight() ?? 0);
          }
        }
        return (durationMs: durMs, width: 0, height: 0);
      }
    } catch (_) {}
    return (durationMs: 0, width: 0, height: 0);
  }

  @visibleForTesting
  static Future<({int durationMs, int width, int height})> probeMediaMeta(String path) =>
      _probeMediaMeta(path);

  /// Executes FFmpeg with input staging, real-time statistics, & cleanup.
  static Future<String> processVideo({
    required String inputPath,
    bool removeMetadata = true,
    bool modifyAudio = true,
    bool modifyVisuals = true,
    bool upscale1080p = false,
    bool? upscale,
    TargetResolution targetResolution = TargetResolution.r1080p,
    VideoCodec videoCodec = VideoCodec.h264,
    bool enableEnhanceAndDenoise = true,
    bool enableDeepAntiFingerprint = true,
    bool enableHorizontalFlip = false,
    bool enableAggressiveAudio = false,
    bool enableAutoTrim = false,
    bool? isPortrait,
    bool enableHardwareAcceleration = false,
    bool enableBlurredCanvas = false,
    double canvasScalePercent = 95.0,
    bool muteOriginalAudio = false,
    bool enableDynamicZoom = false,
    bool enableMicroOverlay = false,
    bool enableFrameSkip = false,
    bool enableChromaShift = false,
    bool suppressCompleteNotification = false,
    String? customOutputPath,
    void Function(double progress, double speed, int timeMs)? onProgress,
    int totalDurationMs = 0,
  }) async {
    File? stagedFile;
    try { stagedFile = await stageInputFile(inputPath); } catch (_) {}

    final effectiveInput = stagedFile?.path ?? inputPath;
    final inputFile = File(effectiveInput);
    if (!inputFile.existsSync() || inputFile.lengthSync() == 0) {
      throw Exception('Source video file does not exist or is empty: $inputPath');
    }

    bool resolvedIsPortrait = isPortrait ?? false;
    int resolvedDurationMs = totalDurationMs;
    if (isPortrait == null || totalDurationMs <= 0) {
      final meta = await _probeMediaMeta(effectiveInput);
      if (isPortrait == null && meta.width > 0 && meta.height > 0) resolvedIsPortrait = meta.height > meta.width;
      if (totalDurationMs <= 0 && meta.durationMs > 0) resolvedDurationMs = meta.durationMs;
    }

    final outputPath = customOutputPath ?? await generateOutputPath(inputPath);
    final command = buildCommand(
      inputPath: effectiveInput,
      outputPath: outputPath,
      removeMetadata: removeMetadata,
      modifyAudio: modifyAudio,
      modifyVisuals: modifyVisuals,
      upscale1080p: upscale1080p,
      upscale: upscale,
      targetResolution: targetResolution,
      videoCodec: videoCodec,
      enableEnhanceAndDenoise: enableEnhanceAndDenoise,
      enableDeepAntiFingerprint: enableDeepAntiFingerprint,
      enableHorizontalFlip: enableHorizontalFlip,
      enableAggressiveAudio: enableAggressiveAudio,
      enableAutoTrim: enableAutoTrim,
      totalDurationMs: resolvedDurationMs,
      isPortrait: resolvedIsPortrait,
      enableHardwareAcceleration: enableHardwareAcceleration,
      enableBlurredCanvas: enableBlurredCanvas,
      canvasScalePercent: canvasScalePercent,
      muteOriginalAudio: muteOriginalAudio,
      enableDynamicZoom: enableDynamicZoom,
      enableMicroOverlay: enableMicroOverlay,
      enableFrameSkip: enableFrameSkip,
      enableChromaShift: enableChromaShift,
    );

    final baseName = inputPath.split(RegExp(r'[/\\]')).last;
    if (onProgress != null) {
      FFmpegKitConfig.enableStatisticsCallback((statistics) {
        final timeMs = statistics.getTime();
        final speed = statistics.getSpeed();
        final progress = resolvedDurationMs > 0 ? (timeMs / resolvedDurationMs).clamp(0.0, 1.0) : 0.0;
        onProgress(progress, speed, timeMs);
        final percent = (progress * 100).toInt();
        NotificationService.showProgressNotification(
          progress: percent,
          title: 'Uniquifying $baseName',
          body: '$percent% complete (${speed > 0 ? speed.toStringAsFixed(1) : "1.0"}x)',
        );
      });
    }

    try {
      final finalPath = await _executeFFmpeg(command, outputPath, sourcePath: effectiveInput);
      await MediaScannerService.scanFile(finalPath);
      final diag = await inspectRenderedFile(finalPath);
      if (diag != null && (diag.isTruncatedPortrait || diag.width == null || diag.height == null)) {
        _deletePartialFile(finalPath, sourcePath: effectiveInput);
        throw RenderIntegrityException('Output failed integrity: truncated or null dimensions (${diag.width}x${diag.height})');
      }
      if (!suppressCompleteNotification) {
        await NotificationService.showCompleteNotification(
          title: 'Video Processing Complete',
          body: 'Saved to ${outputPath.split(RegExp(r"[/\\]")).last}',
          success: true,
        );
      }
      return finalPath;
    } finally {
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback(null);
      }
      await NotificationService.cancelProgressNotification();
      if (stagedFile != null && stagedFile.existsSync()) {
        try {
          if (stagedFile.path != outputPath && stagedFile.path != inputPath) {
            stagedFile.deleteSync();
          }
        } catch (_) {}
      }
    }
  }

  /// Inspects rendered video using FFprobe to produce diagnostic report.
  static Future<RenderDiagnosticInfo?> inspectRenderedFile(String filePath) =>
      RenderDiagnosticService.inspectRenderedFile(filePath);

  static Future<String> _executeFFmpeg(String command, String outputPath, {String? sourcePath}) async {
    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) return outputPath;

      _deletePartialFile(outputPath, sourcePath: sourcePath);
      if (ReturnCode.isCancel(returnCode)) {
        throw Exception('FFmpeg execution was canceled');
      }

      final logs = await session.getAllLogsAsString();
      final failStackTrace = await session.getFailStackTrace();
      final buffer = StringBuffer('FFmpeg failed with code $returnCode');
      if (failStackTrace != null && failStackTrace.trim().isNotEmpty) {
        buffer.write('\n\nStack trace:\n$failStackTrace');
      }
      if (logs != null && logs.trim().isNotEmpty) {
        buffer.write('\n\nExecution logs:\n$logs');
      }
      debugPrint(buffer.toString());
      throw Exception(buffer.toString());
    } catch (_) {
      _deletePartialFile(outputPath, sourcePath: sourcePath);
      rethrow;
    }
  }

  static void _deletePartialFile(String path, {String? sourcePath}) {
    try {
      if (sourcePath != null && path == sourcePath) return;
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }
}
