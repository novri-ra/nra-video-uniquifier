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
import 'storage_service.dart';
import 'wakelock_service.dart';
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
    final buffer = StringBuffer('-y');
    _writeInputOptions(
      buffer,
      inputPath,
      enableHardwareAcceleration,
      enableAutoTrim,
      totalDurationMs,
      thermalThrottle,
      introTrimOffset,
    );
    if (removeMetadata) _writeMetadataTags(buffer);
    _writeFilterAndCodecOptions(
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
      variations: variations,
      targetFps: targetFps,
      saturationLevel: saturationLevel,
      cropZoomScale: cropZoomScale,
      cropAnchor: cropAnchor,
    );
    buffer.write(' "${_escapePath(outputPath)}"');
    return buffer.toString();
  }

  static void _writeInputOptions(
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
    buffer.write(' -i "${_escapePath(inputPath)}"');
  }

  static void _writeMetadataTags(StringBuffer buffer) {
    buffer.write(
      ' -map_metadata -1 -map_chapters -1 -bitexact -fflags +bitexact'
      ' -metadata make="Apple" -metadata model="iPhone 15 Pro Max" -metadata encoder="Apple QuickTime"'
      ' -metadata:s:v:0 handler_name="Core Media Video" -metadata:s:a:0 handler_name="Core Media Audio"',
    );
  }

  static void _writeFilterAndCodecOptions({
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

  /// Cancels any currently running FFmpeg operations.
  static Future<void> cancel() async {
    try {
      await NotificationService.cancelProgressNotification();
      await FFmpegKit.cancel();
    } catch (e, stackTrace) {
      debugPrint(
        '[FfmpegService] Failed to cancel operations: $e\n$stackTrace',
      );
    }
  }

  /// Safely copies an input video to app temp cache before feeding to native FFmpeg.
  static Future<File> stageInputFile(String inputPath) async {
    final inputFile = File(inputPath);
    if (!inputFile.existsSync() || inputFile.lengthSync() == 0) {
      throw Exception(
        'Source video file does not exist or is empty: $inputPath',
      );
    }
    final tempDir = await getTemporaryDirectory();
    final ext = inputPath.contains('.') ? inputPath.split('.').last : 'mp4';
    return await inputFile.copy(
      '${tempDir.path}/staged_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
  }

  /// Extracts 1st-frame thumbnail via lightweight FFmpeg command.
  static Future<String?> extractThumbnail(
    String inputPath, {
    String? targetPath,
  }) async {
    try {
      final inputFile = File(inputPath);
      if (!inputFile.existsSync() || inputFile.lengthSync() == 0) return null;
      final tempDir = await getTemporaryDirectory();
      final thumbPath =
          targetPath ??
          '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final cmd =
          '-y -ss 00:00:00.500 -i "${_escapePath(inputPath)}" -vframes 1 -q:v 2 "${_escapePath(thumbPath)}"';
      final session = await FFmpegKit.execute(cmd);
      if (ReturnCode.isSuccess(await session.getReturnCode()) &&
          File(thumbPath).existsSync()) {
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
        if (!await publicMovies.exists()) {
          await publicMovies.create(recursive: true);
        }
        return publicMovies;
      } catch (_) {
        try {
          final dirs = await getExternalStorageDirectories(
            type: StorageDirectory.movies,
          );
          if (dirs != null && dirs.isNotEmpty) {
            final fallback = Directory('${dirs.first.path}/Uniquifier');
            if (!await fallback.exists()) {
              await fallback.create(recursive: true);
            }
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

  /// Exports rendered video from sandbox cache to target destination.
  static Future<String> _exportStagedFile(
    String stagedPath,
    String destinationPath,
  ) async {
    try {
      final destFile = File(destinationPath);
      if (!destFile.parent.existsSync()) {
        destFile.parent.createSync(recursive: true);
      }
      await File(stagedPath).copy(destinationPath);
      return destinationPath;
    } catch (_) {
      try {
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.movies,
        );
        final fb = (dirs != null && dirs.isNotEmpty)
            ? dirs.first.path
            : (await getApplicationDocumentsDirectory()).path;
        final fallbackDir = Directory('$fb/Movies/Uniquifier')
          ..createSync(recursive: true);
        final fallbackPath =
            '${fallbackDir.path}/${destinationPath.split(RegExp(r"[/\\]")).last}';
        await File(stagedPath).copy(fallbackPath);
        return fallbackPath;
      } catch (_) {
        return stagedPath;
      }
    }
  }

  /// Generates the target output path with collision-free timestamp pattern.
  static Future<String> generateOutputPath(String inputPath) async {
    final fileName = inputPath.split(RegExp(r'[/\\]')).last;
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex != -1
        ? fileName.substring(0, dotIndex)
        : fileName;
    final targetDir = await _resolveTargetDir();
    return '${targetDir.path}/UQ_${baseName}_${DateTime.now().millisecondsSinceEpoch}.mp4';
  }

  static Future<({int durationMs, int width, int height})> _probeMediaMeta(
    String path,
  ) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      if (info != null) {
        final durMs =
            ((double.tryParse(info.getDuration() ?? '') ?? 0.0) * 1000).toInt();
        for (final s in info.getStreams()) {
          if (s.getType() == 'video') {
            return (
              durationMs: durMs,
              width: s.getWidth() ?? 0,
              height: s.getHeight() ?? 0,
            );
          }
        }
        return (durationMs: durMs, width: 0, height: 0);
      }
    } catch (_) {}
    return (durationMs: 0, width: 0, height: 0);
  }

  @visibleForTesting
  static Future<({int durationMs, int width, int height})> probeMediaMeta(
    String path,
  ) => _probeMediaMeta(path);

  /// Executes FFmpeg with input staging, real-time statistics, & cleanup.
  static Future<String> processVideo({
    required String inputPath,
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
    bool thermalThrottle = false,
    void Function(double progress, double speed, int timeMs)? onProgress,
    void Function(String log)? onLog,
    int totalDurationMs = 0,
    int targetFps = 30,
    double? saturationLevel,
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
    double introTrimOffset = 0.5,
  }) async {
    if (!await StorageService.hasEnoughSpace()) {
      throw Exception(
        'Sisa penyimpanan kurang dari 2 GB. Bersihkan ruang penyimpanan.',
      );
    }
    final meta = await _resolveInputMeta(
      inputPath,
      isPortrait,
      totalDurationMs,
    );
    final finalDest = customOutputPath ?? await generateOutputPath(inputPath);
    final tempDir = await getTemporaryDirectory();
    final stagedOut =
        '${tempDir.path}/staged_out_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final command = buildCommand(
      inputPath: meta.effectiveInput,
      outputPath: stagedOut,
      removeMetadata: removeMetadata,
      modifyAudio: modifyAudio,
      modifyVisuals: modifyVisuals,
      upscale1080p: upscale1080p,
      upscale: upscale,
      targetResolution: targetResolution,
      upscaleEngine: upscaleEngine,
      videoCodec: videoCodec,
      enableEnhanceAndDenoise: enableEnhanceAndDenoise,
      enableDeepAntiFingerprint: enableDeepAntiFingerprint,
      enableHorizontalFlip: enableHorizontalFlip,
      enableAggressiveAudio: enableAggressiveAudio,
      enableAutoTrim: enableAutoTrim,
      totalDurationMs: meta.durationMs,
      isPortrait: meta.isPortrait,
      enableHardwareAcceleration: enableHardwareAcceleration,
      enableBlurredCanvas: enableBlurredCanvas,
      canvasScalePercent: canvasScalePercent,
      muteOriginalAudio: muteOriginalAudio,
      enableDynamicZoom: enableDynamicZoom,
      enableMicroOverlay: enableMicroOverlay,
      enableFrameSkip: enableFrameSkip,
      enableChromaShift: enableChromaShift,
      thermalThrottle: thermalThrottle,
      targetFps: targetFps,
      saturationLevel: saturationLevel,
      cropZoomScale: cropZoomScale,
      cropAnchor: cropAnchor,
      introTrimOffset: introTrimOffset,
    );

    _setupCallbacks(
      onProgress: onProgress,
      onLog: onLog,
      resolvedDurationMs: meta.durationMs,
      baseName: inputPath.split(RegExp(r'[/\\]')).last,
    );
    await NotificationService.showProgressNotification(
      id: 101,
      progress: 0,
      title: 'Memproses Video',
      body: 'Memulai rendering...',
      force: true,
    );
    await WakeLockService.acquire();
    try {
      return await _executeAndExport(
        command: command,
        stagedOutputPath: stagedOut,
        effectiveInput: meta.effectiveInput,
        finalDestPath: finalDest,
        suppressCompleteNotification: suppressCompleteNotification,
      );
    } catch (e) {
      if (!suppressCompleteNotification) {
        final lang = await SettingsService.getAppLanguageCode();
        final isCancel = e.toString().toLowerCase().contains('cancel');
        final title = isCancel
            ? (lang == 'en' ? 'Export Canceled' : 'Ekspor Dibatalkan')
            : (lang == 'en' ? 'Export Failed' : 'Ekspor Gagal');
        final body = isCancel
            ? (lang == 'en'
                  ? 'Rendering was canceled'
                  : 'Proses rendering dibatalkan')
            : (lang == 'en'
                  ? 'Rendering failed'
                  : 'Terjadi kesalahan saat rendering');
        await NotificationService.showCompleteNotification(
          title: title,
          body: body,
          success: false,
        );
      }
      rethrow;
    } finally {
      await _cleanupAfterProcess(
        meta: meta,
        stagedOut: stagedOut,
        finalDest: finalDest,
        inputPath: inputPath,
        onProgress: onProgress != null,
        onLog: onLog != null,
      );
    }
  }

  static Future<void> _cleanupAfterProcess({
    required ({
      String effectiveInput,
      File? stagedFile,
      bool isPortrait,
      int durationMs,
    })
    meta,
    required String stagedOut,
    required String finalDest,
    required String inputPath,
    required bool onProgress,
    required bool onLog,
  }) async {
    await WakeLockService.release();
    if (onProgress) FFmpegKitConfig.enableStatisticsCallback(null);
    if (onLog) FFmpegKitConfig.enableLogCallback(null);
    await NotificationService.cancelProgressNotification(101);
    _deletePartialFile(stagedOut, sourcePath: meta.effectiveInput);
    if (meta.stagedFile != null &&
        meta.stagedFile!.existsSync() &&
        meta.stagedFile!.path != finalDest &&
        meta.stagedFile!.path != inputPath) {
      try {
        meta.stagedFile!.deleteSync();
      } catch (_) {}
    }
  }

  static Future<
    ({String effectiveInput, File? stagedFile, bool isPortrait, int durationMs})
  >
  _resolveInputMeta(
    String inputPath,
    bool? isPortrait,
    int totalDurationMs,
  ) async {
    File? stagedFile;
    try {
      stagedFile = await stageInputFile(inputPath);
    } catch (_) {}
    final effectiveInput = stagedFile?.path ?? inputPath;
    final inputFile = File(effectiveInput);
    if (!inputFile.existsSync() || inputFile.lengthSync() == 0) {
      throw Exception(
        'Source video file does not exist or is empty: $inputPath',
      );
    }
    bool resolvedPortrait = isPortrait ?? false;
    int resolvedDuration = totalDurationMs;
    if (isPortrait == null || totalDurationMs <= 0) {
      final meta = await _probeMediaMeta(effectiveInput);
      if (isPortrait == null && meta.width > 0 && meta.height > 0) {
        resolvedPortrait = meta.height > meta.width;
      }
      if (totalDurationMs <= 0 && meta.durationMs > 0) {
        resolvedDuration = meta.durationMs;
      }
    }
    return (
      effectiveInput: effectiveInput,
      stagedFile: stagedFile,
      isPortrait: resolvedPortrait,
      durationMs: resolvedDuration,
    );
  }

  static String _stageDescription(int percent) {
    if (percent < 15) return 'Inisialisasi & filter awal...';
    if (percent < 40) return 'Transformasi visual & anti-fingerprint...';
    if (percent < 80) return 'Encoding video stream & scaling...';
    return percent < 95
        ? 'Muxing audio & normalisasi...'
        : 'Finalisasi ekspor & galeri...';
  }

  static void _setupCallbacks({
    void Function(double progress, double speed, int timeMs)? onProgress,
    void Function(String log)? onLog,
    required int resolvedDurationMs,
    required String baseName,
  }) {
    if (onProgress != null) {
      double maxProgress = 0.0;
      FFmpegKitConfig.enableStatisticsCallback((statistics) {
        final timeMs = statistics.getTime(), speed = statistics.getSpeed();
        final rawProgress = resolvedDurationMs > 0
            ? (timeMs / resolvedDurationMs).clamp(0.0, 1.0)
            : 0.0;
        if (rawProgress > maxProgress) maxProgress = rawProgress;
        onProgress(maxProgress, speed, timeMs);
        final percent = (maxProgress * 100).toInt();
        NotificationService.showProgressNotification(
          id: 101,
          progress: percent,
          title: 'Memproses Video ($percent%)',
          body: _stageDescription(percent),
        );
      });
    }
    if (onLog != null) {
      FFmpegKitConfig.enableLogCallback((log) {
        final msg = log.getMessage();
        if (msg.isNotEmpty) onLog(msg);
      });
    }
  }

  static Future<String> _executeAndExport({
    required String command,
    required String stagedOutputPath,
    required String effectiveInput,
    required String finalDestPath,
    required bool suppressCompleteNotification,
  }) async {
    final stagedRenderedPath = await _executeFFmpeg(
      command,
      stagedOutputPath,
      sourcePath: effectiveInput,
    );
    final diag = await inspectRenderedFile(stagedRenderedPath);
    if (diag != null &&
        (diag.isTruncatedPortrait ||
            diag.width == null ||
            diag.height == null)) {
      _deletePartialFile(stagedRenderedPath, sourcePath: effectiveInput);
      throw RenderIntegrityException(
        'Output failed integrity: truncated or null dimensions (${diag.width}x${diag.height})',
      );
    }
    final exportedPath = await _exportStagedFile(
      stagedRenderedPath,
      finalDestPath,
    );
    await MediaScannerService.scanFile(exportedPath);
    _deletePartialFile(stagedOutputPath, sourcePath: effectiveInput);
    if (!suppressCompleteNotification) {
      final name = exportedPath.split(RegExp(r"[/\\]")).last;
      final lang = await SettingsService.getAppLanguageCode();
      final title = lang == 'en' ? 'Export Successful' : 'Ekspor Berhasil';
      final body = lang == 'en'
          ? 'Video ready in gallery ($name)'
          : 'Video siap di galeri ($name)';
      await NotificationService.showCompleteNotification(
        title: title,
        body: body,
        success: true,
      );
    }
    return exportedPath;
  }

  /// Inspects rendered video using FFprobe to produce diagnostic report.
  static Future<RenderDiagnosticInfo?> inspectRenderedFile(String filePath) =>
      RenderDiagnosticService.inspectRenderedFile(filePath);

  static Future<String> _executeFFmpeg(
    String command,
    String outputPath, {
    String? sourcePath,
  }) async {
    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) return outputPath;
      _deletePartialFile(outputPath, sourcePath: sourcePath);
      if (ReturnCode.isCancel(returnCode)) {
        throw Exception('FFmpeg execution was canceled');
      }

      final logs = await session.getAllLogsAsString();
      final err =
          'FFmpeg failed with code $returnCode${logs != null ? '\n$logs' : ''}';
      debugPrint(err);
      throw Exception(err);
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
