import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/unified_effect_preset.dart';
import '../utils/variation_generator.dart';
import 'ffmpeg/ffmpeg_command_builder.dart';
import 'ffmpeg/ffmpeg_file_helper.dart';
import 'ffmpeg/media_probe_helper.dart';
import 'media_scanner_service.dart';
import 'notification_service.dart';
import 'render_diagnostic_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';
import 'wakelock_service.dart';

export '../models/unified_effect_preset.dart';
export '../utils/variation_generator.dart';
export 'ffmpeg/ffmpeg_command_builder.dart';
export 'ffmpeg/ffmpeg_file_helper.dart';
export 'ffmpeg/ffmpeg_metadata_builder.dart';
export 'ffmpeg/media_probe_helper.dart';
export 'filter_builders.dart';
export 'render_diagnostic_service.dart';

class FfmpegService {
  static int? _activePreviewSessionId;

  static String _escapePath(String path) =>
      FfmpegCommandBuilder.escapePath(path);

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
    String? lutName,
  }) => FfmpegCommandBuilder.buildCommand(
    inputPath: inputPath,
    outputPath: outputPath,
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
    totalDurationMs: totalDurationMs,
    isPortrait: isPortrait,
    enableHardwareAcceleration: enableHardwareAcceleration,
    enableBlurredCanvas: enableBlurredCanvas,
    canvasScalePercent: canvasScalePercent,
    muteOriginalAudio: muteOriginalAudio,
    enableDynamicZoom: enableDynamicZoom,
    enableMicroOverlay: enableMicroOverlay,
    enableFrameSkip: enableFrameSkip,
    enableChromaShift: enableChromaShift,
    variations: variations,
    thermalThrottle: thermalThrottle,
    targetFps: targetFps,
    saturationLevel: saturationLevel,
    sharpeningLevel: sharpeningLevel,
    cropZoomScale: cropZoomScale,
    cropAnchor: cropAnchor,
    introTrimOffset: introTrimOffset,
    rotateAngle: rotateAngle,
    activeVisualEffects: activeVisualEffects,
    lutName: lutName,
  );

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
  static Future<File> stageInputFile(String inputPath) =>
      FfmpegFileHelper.stageInputFile(inputPath);

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
          '-y -cpuflags 0 -ss 00:00:00.500 -i "${_escapePath(inputPath)}" '
          '-sws_flags bilinear -vf "scale=iw-2:ih-2,format=yuvj420p" '
          '-vframes 1 -q:v 2 "${_escapePath(thumbPath)}"';
      final session = await FFmpegKit.execute(cmd);
      if (ReturnCode.isSuccess(await session.getReturnCode()) &&
          File(thumbPath).existsSync()) {
        return thumbPath;
      }
    } catch (e) {
      debugPrint(
        '[FfmpegService] thumbnail failed for '
        "${inputPath.split(RegExp(r'[/\\]')).last}: ${e.runtimeType}",
      );
    }
    return null;
  }

  /// Renders a single-frame preview using ultra-fast FFmpeg extraction with applied filters.
  /// Automatically cancels any previous in-flight preview session to avoid process queue pileup.
  static Future<String?> renderFilteredPreviewFrame({
    required String inputPath,
    required String filterComplex,
    required double timestampSeconds,
  }) async {
    try {
      final inputFile = File(inputPath);
      if (!inputFile.existsSync() || inputFile.lengthSync() == 0) return null;

      // Cancel previous preview session if currently running
      if (_activePreviewSessionId != null) {
        final prevId = _activePreviewSessionId;
        _activePreviewSessionId = null;
        try {
          await FFmpegKit.cancel(prevId);
        } catch (e) {
          debugPrint('[FfmpegService] preview cancel failed: $e');
        }
      }

      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final cleanFilter = filterComplex.trim();
      final String vfOption;
      if (cleanFilter.contains(';') || cleanFilter.contains('[')) {
        if (cleanFilter.endsWith(']')) {
          final lastBracket = cleanFilter.lastIndexOf('[');
          final outLabel = cleanFilter.substring(lastBracket);
          vfOption = '-filter_complex "$cleanFilter;$outLabel scale=480:-2"';
        } else {
          vfOption = '-filter_complex "$cleanFilter,scale=480:-2"';
        }
      } else if (cleanFilter.isEmpty) {
        vfOption = '-vf "scale=480:-2"';
      } else {
        final trailing = cleanFilter.endsWith(',') ? '' : ',';
        vfOption = '-vf "$cleanFilter${trailing}scale=480:-2"';
      }

      // 🔥 PERBAIKAN: Deteksi efek temporal (Echo, RGB Split, dll)
      final hasTemporalEffect =
          cleanFilter.contains('blend') ||
          cleanFilter.contains('setpts=PTS+') ||
          cleanFilter.contains('tmix');

      // Jika efek temporal, proses 0.2 detik dan timpa gambar terakhir (-update 1).
      // Jika bukan, cukup ambil 1 frame (-vframes 1).
      final String frameArg = hasTemporalEffect
          ? '-t 0.2 -update 1'
          : '-vframes 1';

      final ssParam = timestampSeconds.toStringAsFixed(3);

      // Gunakan frameArg yang sudah dinamis
      final cmd =
          '-ss $ssParam -cpuflags 0 -i "${_escapePath(inputPath)}" $frameArg -preset ultrafast -sws_flags bilinear $vfOption -y "${_escapePath(outputPath)}"';

      final completer = Completer<String?>();
      debugPrint('[FFmpeg Audit] Executing preview: $cmd');
      final session = await FFmpegKit.executeAsync(cmd, (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode) && File(outputPath).existsSync()) {
          if (!completer.isCompleted) completer.complete(outputPath);
        } else {
          if (!completer.isCompleted) completer.complete(null);
        }
      });

      final currentId = session.getSessionId();
      _activePreviewSessionId = currentId;

      final result = await completer.future;
      if (_activePreviewSessionId == currentId) {
        _activePreviewSessionId = null;
      }

      if (result != null) {
        _cleanupOldPreviews(result);
      }

      return result;
    } catch (e) {
      debugPrint('[FfmpegService] renderFilteredPreviewFrame error: $e');
      return null;
    }
  }

  /// Deletes old preview_*.jpg files in the temp directory to prevent cache bloat.
  static void _cleanupOldPreviews(String currentPath) {
    try {
      final dir = File(currentPath).parent;
      if (!dir.existsSync()) return;

      final files = dir.listSync();
      for (final entity in files) {
        if (entity is File) {
          final filePath = entity.absolute.path;
          final fileName = filePath.split(RegExp(r'[/\\]')).last;
          // Cari file yang berawalan 'preview_' dan berekstensi '.jpg'
          if (fileName.startsWith('preview_') && fileName.endsWith('.jpg')) {
            // Jangan hapus file yang baru saja dibuat (currentPath)
            if (filePath != currentPath) {
              try {
                entity.deleteSync();
              } catch (e) {
                debugPrint(
                  '[FfmpegService] delete old preview failed for '
                  '$fileName: ${e.runtimeType}',
                );
              }
            }
          }
        }
      }
    } catch (_) {
      // Abaikan error cleanup agar tidak mengganggu proses rendering utama
    }
  }

  /// Generates the target output path with collision-free timestamp pattern.
  static Future<String> generateOutputPath(String inputPath) =>
      FfmpegFileHelper.generateOutputPath(inputPath);

  @visibleForTesting
  static Future<({int durationMs, int width, int height})> probeMediaMeta(
    String path,
  ) => MediaProbeHelper.probeMediaMeta(path);

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
    double? sharpeningLevel,
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
    double introTrimOffset = 0.5,
    double? rotateAngle,
    Set<UnifiedVisualEffect>? activeVisualEffects,
  }) async {
    if (!await StorageService.hasEnoughSpace()) {
      throw Exception(
        'Insufficient storage space (less than 1.5 GB). Please free up storage.',
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
      sharpeningLevel: sharpeningLevel,
      cropZoomScale: cropZoomScale,
      cropAnchor: cropAnchor,
      introTrimOffset: introTrimOffset,
      rotateAngle: rotateAngle,
      activeVisualEffects: activeVisualEffects,
    );

    _setupCallbacks(
      onProgress: onProgress,
      onLog: onLog,
      resolvedDurationMs: meta.durationMs,
      baseName: inputPath.split(RegExp(r'[/\\]')).last,
    );
    await NotificationService.requestPermission();
    await NotificationService.showProgressNotification(
      id: 101,
      progress: 0,
      title: 'Processing Video',
      body: 'Starting render...',
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
    FfmpegFileHelper.deletePartialFile(
      stagedOut,
      sourcePath: meta.effectiveInput,
    );
    if (meta.stagedFile != null &&
        meta.stagedFile!.existsSync() &&
        meta.stagedFile!.path != finalDest &&
        meta.stagedFile!.path != inputPath) {
      try {
        meta.stagedFile!.deleteSync();
      } catch (e) {
        debugPrint(
          '[FfmpegService] delete staged file failed for '
          "${meta.stagedFile?.path.split(RegExp(r'[/\\]')).last}: "
          '${e.runtimeType}',
        );
      }
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
    } catch (e) {
      debugPrint(
        '[FfmpegService] stage input failed for '
        "${inputPath.split(RegExp(r'[/\\]')).last}: ${e.runtimeType}",
      );
    }
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
      final meta = await MediaProbeHelper.probeMediaMeta(effectiveInput);
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
    if (percent < 15) return 'Initializing & base filters...';
    if (percent < 40) return 'Visual transforms & anti-fingerprint...';
    if (percent < 80) return 'Encoding video stream & scaling...';
    return percent < 95
        ? 'Audio muxing & normalization...'
        : 'Finalizing export & gallery...';
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
          title: 'Processing Video ($percent%)',
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
      FfmpegFileHelper.deletePartialFile(
        stagedRenderedPath,
        sourcePath: effectiveInput,
      );
      throw RenderIntegrityException(
        'Output failed integrity: truncated or null dimensions (${diag.width}x${diag.height})',
      );
    }
    final exportedPath =
        await FfmpegFileHelper.exportStagedFile(
          stagedRenderedPath,
          finalDestPath,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            // Scoped-storage copy can stall; never leave the UI at 99% forever.
            // Fall back to the staged render so the result is not lost.
            debugPrint(
              '[FfmpegService] export copy timed out after 30s; '
              'keeping staged file',
            );
            return stagedRenderedPath;
          },
        );
    await MediaScannerService.scanFile(exportedPath);
    if (exportedPath != stagedOutputPath) {
      FfmpegFileHelper.deletePartialFile(
        stagedOutputPath,
        sourcePath: effectiveInput,
      );
    }
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
      // Split the command on flag boundaries so each argument is its own
      // Logcat line; a single multi-kilobyte line gets truncated by logcat.
      debugPrint('[FFmpeg Audit] Command length: ${command.length}');
      final chunks = command.split(' -');
      for (var i = 0; i < chunks.length; i++) {
        if (i == 0) {
          debugPrint('[FFmpeg Audit] Start: ${chunks[i]}');
        } else {
          debugPrint('[FFmpeg Audit] Arg: -${chunks[i]}');
        }
      }
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) return outputPath;
      FfmpegFileHelper.deletePartialFile(outputPath, sourcePath: sourcePath);
      if (ReturnCode.isCancel(returnCode)) {
        throw Exception('FFmpeg execution was canceled');
      }

      final logs = await session.getAllLogsAsString();
      final err =
          'FFmpeg failed with code $returnCode${logs != null ? '\n$logs' : ''}';
      debugPrint(err);
      throw Exception(err);
    } catch (_) {
      FfmpegFileHelper.deletePartialFile(outputPath, sourcePath: sourcePath);
      rethrow;
    }
  }
}
