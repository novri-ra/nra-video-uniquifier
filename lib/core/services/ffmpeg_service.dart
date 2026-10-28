import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'media_scanner_service.dart';
import 'render_diagnostic_service.dart';
import 'settings_service.dart';

export 'render_diagnostic_service.dart';

class FfmpegService {
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
    bool enableEnhanceAndDenoise = true,
    bool enableDeepAntiFingerprint = true,
    bool enableHorizontalFlip = false,
    bool enableAggressiveAudio = false,
    bool enableAutoTrim = false,
    int totalDurationMs = 0,
    bool isPortrait = false,
  }) {
    final buffer = StringBuffer('-y');
    if (enableAutoTrim) {
      buffer.write(' -ss 0.5');
      if (totalDurationMs > 1500) {
        final trimDur = ((totalDurationMs - 1000) / 1000).toStringAsFixed(2);
        buffer.write(' -t $trimDur');
      }
    }
    buffer.write(' -i "$inputPath"');
    if (removeMetadata) {
      buffer.write(' -map_metadata -1 -map_chapters -1 -bitexact');
      buffer.write(' -metadata make="Apple" -metadata model="iPhone 15 Pro" -metadata encoder="Apple QuickTime"');
    }

    final shouldUpscale = upscale ?? upscale1080p;
    final hasVisual = modifyVisuals || shouldUpscale || enableHorizontalFlip;
    buffer.write(_buildVideoFilter(
      hasVisual: hasVisual,
      hasAudio: modifyAudio,
      modifyVisuals: modifyVisuals,
      upscale: shouldUpscale,
      targetResolution: targetResolution,
      enableEnhanceAndDenoise: enableEnhanceAndDenoise,
      enableDeepAntiFingerprint: enableDeepAntiFingerprint,
      enableHorizontalFlip: enableHorizontalFlip,
      isPortrait: isPortrait,
    ));
    buffer.write(_buildAudioFilter(
      hasAudio: modifyAudio,
      hasVisual: hasVisual,
      enableDeepAntiFingerprint: enableDeepAntiFingerprint,
      enableAggressiveAudio: enableAggressiveAudio,
    ));

    if (!hasVisual && !modifyAudio) buffer.write(' -c copy');
    buffer.write(' "$outputPath"');
    return buffer.toString();
  }

  static String _buildVideoFilter({
    required bool hasVisual,
    required bool hasAudio,
    bool modifyVisuals = true,
    bool upscale = false,
    TargetResolution targetResolution = TargetResolution.r1080p,
    bool enableEnhanceAndDenoise = true,
    bool enableDeepAntiFingerprint = true,
    bool enableHorizontalFlip = false,
    bool isPortrait = false,
  }) {
    if (hasVisual) {
      final filters = <String>[
        // 1. Temporal (PTS)
        if (modifyVisuals) 'setpts=0.9852*PTS',

        // 2. Spatial (Crop -> Rotate -> Hflip)
        if (modifyVisuals) ...[
          if (enableDeepAntiFingerprint)
            'crop=trunc(iw*0.95/2)*2:trunc(ih*0.95/2)*2'
          else
            'crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2',
          if (enableDeepAntiFingerprint)
            'rotate=0.4*PI/180:ow=rotw(0.4*PI/180):oh=roth(0.4*PI/180):fillcolor=black',
          if (enableHorizontalFlip) 'hflip',
        ] else if (enableHorizontalFlip) ...[
          'hflip',
        ],

        // 3. Resolution Scaling (Lanczos scale - orientation aware)
        if (upscale) targetResolution.scaleFilter(isPortrait: isPortrait),

        // 4. Enhancements (Denoise -> Unsharp -> Curves/Color EQ)
        if (enableEnhanceAndDenoise) ...[
          'hqdn3d=1.5:1.5:4:4',
          'unsharp=3:3:0.6:3:3:0.0',
        ],
        if (modifyVisuals) ...[
          'curves=preset=vintage',
          'eq=contrast=1.02:brightness=0.01:saturation=1.03:gamma=0.98',
        ],

        // 5. Grain Injection (Noise)
        if (modifyVisuals) 'noise=alls=3:allf=t+u',
      ];
      return ' -vf "${filters.join(',')}" -c:v libx264 -preset fast -crf 19 -b:v 8M -g 60 -keyint_min 30';
    }
    return hasAudio ? ' -c:v copy' : '';
  }

  static String _buildAudioFilter({
    required bool hasAudio,
    required bool hasVisual,
    bool enableDeepAntiFingerprint = true,
    bool enableAggressiveAudio = false,
  }) {
    if (hasAudio) {
      if (enableAggressiveAudio) {
        return ' -af "[in]atempo=1.015,asetrate=48000*1.01,aresample=48000,highpass=f=60,lowpass=f=16000,equalizer=f=1200:t=q:w=1:g=1[a0];anoisesrc=d=7200:c=pink:a=0.003[noise];[a0][noise]amix=inputs=2:duration=first[out]" -c:a aac -b:a 192k';
      }
      if (enableDeepAntiFingerprint) {
        return ' -af "atempo=1.015,asetrate=48000*1.01,aresample=48000,highpass=f=60,lowpass=f=16000,equalizer=f=1200:t=q:w=1:g=1" -c:a aac -b:a 192k';
      }
      return ' -af "atempo=1.015,asetrate=48000*1.01,aresample=48000,equalizer=f=1000:t=q:w=1:g=0.5" -c:a aac -b:a 192k';
    }
    return hasVisual ? ' -c:a copy' : '';
  }

  /// Cancels any currently running FFmpeg operations.
  static Future<void> cancel() async {
    try {
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
      final cmd = '-y -ss 00:00:00.500 -i "$inputPath" -vframes 1 -q:v 2 "$thumbPath"';
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

  /// Pipeline execution alias conforming to architectural execution contract.
  static Future<String> executePipeline({
    required String inputPath,
    bool removeMetadata = true,
    bool modifyAudio = true,
    bool modifyVisuals = true,
    bool upscale1080p = false,
    bool? upscale,
    TargetResolution targetResolution = TargetResolution.r1080p,
    bool enableEnhanceAndDenoise = true,
    bool enableDeepAntiFingerprint = true,
    bool enableHorizontalFlip = false,
    bool enableAggressiveAudio = false,
    bool enableAutoTrim = false,
    bool? isPortrait,
    String? customOutputPath,
    void Function(double progress, double speed, int timeMs)? onProgress,
    int totalDurationMs = 0,
  }) =>
      processVideo(
        inputPath: inputPath,
        removeMetadata: removeMetadata,
        modifyAudio: modifyAudio,
        modifyVisuals: modifyVisuals,
        upscale1080p: upscale1080p,
        upscale: upscale,
        targetResolution: targetResolution,
        enableEnhanceAndDenoise: enableEnhanceAndDenoise,
        enableDeepAntiFingerprint: enableDeepAntiFingerprint,
        enableHorizontalFlip: enableHorizontalFlip,
        enableAggressiveAudio: enableAggressiveAudio,
        enableAutoTrim: enableAutoTrim,
        isPortrait: isPortrait,
        customOutputPath: customOutputPath,
        onProgress: onProgress,
        totalDurationMs: totalDurationMs,
      );

  /// Executes FFmpeg with input staging, real-time statistics, & cleanup.
  static Future<String> processVideo({
    required String inputPath,
    bool removeMetadata = true,
    bool modifyAudio = true,
    bool modifyVisuals = true,
    bool upscale1080p = false,
    bool? upscale,
    TargetResolution targetResolution = TargetResolution.r1080p,
    bool enableEnhanceAndDenoise = true,
    bool enableDeepAntiFingerprint = true,
    bool enableHorizontalFlip = false,
    bool enableAggressiveAudio = false,
    bool enableAutoTrim = false,
    bool? isPortrait,
    String? customOutputPath,
    void Function(double progress, double speed, int timeMs)? onProgress,
    int totalDurationMs = 0,
  }) async {
    File? stagedFile;
    try {
      stagedFile = await stageInputFile(inputPath);
    } catch (_) {
      stagedFile = null;
    }

    final effectiveInput = stagedFile?.path ?? inputPath;
    final inputFile = File(effectiveInput);
    if (!inputFile.existsSync() || inputFile.lengthSync() == 0) {
      throw Exception('Source video file does not exist or is empty: $inputPath');
    }

    bool resolvedIsPortrait = isPortrait ?? false;
    if (isPortrait == null) {
      try {
        final session = await FFprobeKit.getMediaInformation(effectiveInput);
        final info = session.getMediaInformation();
        if (info != null) {
          final streams = info.getStreams();
          for (final s in streams) {
            if (s.getType() == 'video') {
              final w = s.getWidth();
              final h = s.getHeight();
              if (w != null && h != null && h > w) {
                resolvedIsPortrait = true;
              }
              break;
            }
          }
        }
      } catch (_) {}
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
      enableEnhanceAndDenoise: enableEnhanceAndDenoise,
      enableDeepAntiFingerprint: enableDeepAntiFingerprint,
      enableHorizontalFlip: enableHorizontalFlip,
      enableAggressiveAudio: enableAggressiveAudio,
      enableAutoTrim: enableAutoTrim,
      totalDurationMs: totalDurationMs,
      isPortrait: resolvedIsPortrait,
    );

    if (onProgress != null) {
      FFmpegKitConfig.enableStatisticsCallback((statistics) {
        final timeMs = statistics.getTime();
        final speed = statistics.getSpeed();
        final progress = totalDurationMs > 0 ? (timeMs / totalDurationMs).clamp(0.0, 1.0) : 0.0;
        onProgress(progress, speed, timeMs);
      });
    }

    try {
      final finalPath = await _executeFFmpeg(command, outputPath);
      await MediaScannerService.scanFile(finalPath);
      await inspectRenderedFile(finalPath);
      return finalPath;
    } finally {
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback(null);
      }
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

  static Future<String> _executeFFmpeg(String command, String outputPath) async {
    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) return outputPath;

      _deletePartialFile(outputPath);
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
      throw Exception(buffer.toString());
    } catch (_) {
      _deletePartialFile(outputPath);
      rethrow;
    }
  }

  static void _deletePartialFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }
}
