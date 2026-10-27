import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

class FfmpegService {
  /// Builds dynamic FFmpeg command string with enhanced anti-fingerprint filters.
  static String buildCommand({
    required String inputPath,
    required String outputPath,
    bool removeMetadata = true,
    bool modifyAudio = true,
    bool modifyVisuals = true,
    bool upscale1080p = false,
  }) {
    final buffer = StringBuffer('-y -i "$inputPath"');
    if (removeMetadata) buffer.write(' -map_metadata -1 -map_chapters -1 -bitexact');

    final hasVisual = modifyVisuals || upscale1080p;
    buffer.write(_buildVideoFilter(
      hasVisual: hasVisual,
      hasAudio: modifyAudio,
      upscale1080p: upscale1080p,
    ));
    buffer.write(_buildAudioFilter(hasAudio: modifyAudio, hasVisual: hasVisual));

    if (!hasVisual && !modifyAudio) buffer.write(' -c copy');
    buffer.write(' "$outputPath"');
    return buffer.toString();
  }

  static String _buildVideoFilter({
    required bool hasVisual,
    required bool hasAudio,
    bool upscale1080p = false,
  }) {
    if (hasVisual) {
      final filters = <String>[
        'setpts=0.9852*PTS',
        'crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2',
        if (upscale1080p) 'scale=1920:1080:flags=lanczos',
        'eq=contrast=1.02:brightness=0.01:saturation=1.03:gamma=0.98',
        'noise=alls=2:allf=t+u',
      ];
      return ' -vf "${filters.join(',')}" -c:v libx264 -preset veryfast -crf 22 -g 60 -keyint_min 30';
    }
    return hasAudio ? ' -c:v copy' : '';
  }

  static String _buildAudioFilter({required bool hasAudio, required bool hasVisual}) {
    if (hasAudio) {
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
  static Future<String?> extractThumbnail(String inputPath) async {
    try {
      final inputFile = File(inputPath);
      if (!inputFile.existsSync() || inputFile.lengthSync() == 0) return null;
      final tempDir = await getTemporaryDirectory();
      final thumbPath = '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final cmd = '-y -ss 00:00:00.500 -i "$inputPath" -vframes 1 -q:v 2 "$thumbPath"';
      final session = await FFmpegKit.execute(cmd);
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode) && File(thumbPath).existsSync()) {
        return thumbPath;
      }
    } catch (_) {}
    return null;
  }

  /// Resolves the target directory, prioritizing public Movies on Android.
  static Future<Directory> _resolveTargetDir() async {
    if (Platform.isAndroid) {
      final publicMovies = Directory('/storage/emulated/0/Movies/VideoUniquifier');
      try {
        if (!await publicMovies.exists()) await publicMovies.create(recursive: true);
        return publicMovies;
      } catch (_) {
        try {
          final dirs = await getExternalStorageDirectories(type: StorageDirectory.movies);
          if (dirs != null && dirs.isNotEmpty) {
            return Directory('${dirs.first.path}/VideoUniquifier');
          }
        } catch (_) {}
      }
    }
    final appDocs = await getApplicationDocumentsDirectory();
    return Directory('${appDocs.path}/Movies/VideoUniquifier');
  }

  /// Generates the target output path under /Movies/VideoUniquifier/
  static Future<String> generateOutputPath(String inputPath) async {
    final fileName = inputPath.split(RegExp(r'[/\\]')).last;
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex != -1 ? fileName.substring(0, dotIndex) : fileName;
    final targetDir = await _resolveTargetDir();

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return '${targetDir.path}/${baseName}_unique.mp4';
  }

  /// Executes FFmpeg with input staging, real-time statistics, & cleanup.
  static Future<String> processVideo({
    required String inputPath,
    bool removeMetadata = true,
    bool modifyAudio = true,
    bool modifyVisuals = true,
    bool upscale1080p = false,
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

    final outputPath = customOutputPath ?? await generateOutputPath(inputPath);
    final command = buildCommand(
      inputPath: effectiveInput,
      outputPath: outputPath,
      removeMetadata: removeMetadata,
      modifyAudio: modifyAudio,
      modifyVisuals: modifyVisuals,
      upscale1080p: upscale1080p,
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
      return await _executeFFmpeg(command, outputPath);
    } finally {
      if (onProgress != null) {
        FFmpegKitConfig.enableStatisticsCallback(null);
      }
      if (stagedFile != null && stagedFile.existsSync()) {
        try {
          stagedFile.deleteSync();
        } catch (_) {}
      }
    }
  }

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
      throw Exception('FFmpeg failed with code $returnCode: $logs $failStackTrace');
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
