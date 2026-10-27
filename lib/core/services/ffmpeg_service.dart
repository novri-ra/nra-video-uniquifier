import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

class FfmpegService {
  /// Builds dynamic FFmpeg command string based on applied toggles.
  static String buildCommand({
    required String inputPath,
    required String outputPath,
    bool removeMetadata = true,
    bool modifyAudio = true,
    bool modifyVisuals = true,
    bool upscale1080p = false,
  }) {
    final buffer = StringBuffer('-y -i "$inputPath"');
    if (removeMetadata) buffer.write(' -map_metadata -1');

    final hasVisual = modifyVisuals || upscale1080p;
    buffer.write(_buildVideoFilter(hasVisual: hasVisual, hasAudio: modifyAudio));
    buffer.write(_buildAudioFilter(hasAudio: modifyAudio, hasVisual: hasVisual));

    if (!hasVisual && !modifyAudio) buffer.write(' -c copy');
    buffer.write(' "$outputPath"');
    return buffer.toString();
  }

  static String _buildVideoFilter({required bool hasVisual, required bool hasAudio}) {
    if (hasVisual) {
      return ' -vf "crop=iw-4:ih-4,scale=1920:1080:flags=lanczos" -c:v libx264 -crf 23';
    }
    return hasAudio ? ' -c:v copy' : '';
  }

  static String _buildAudioFilter({required bool hasAudio, required bool hasVisual}) {
    if (hasAudio) {
      return ' -af "asetrate=44100*1.005,aresample=44100" -c:a aac';
    }
    return hasVisual ? ' -c:a copy' : '';
  }

  /// Cancels any currently running FFmpeg operations.
  static Future<void> cancel() async {
    try {
      await FFmpegKit.cancel();
    } catch (_) {}
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

  /// Executes FFmpeg inside Isolate with input validation & partial file cleanup.
  static Future<String> processVideo({
    required String inputPath,
    bool removeMetadata = true,
    bool modifyAudio = true,
    bool modifyVisuals = true,
    bool upscale1080p = false,
    String? customOutputPath,
  }) async {
    final inputFile = File(inputPath);
    if (!inputFile.existsSync() || inputFile.lengthSync() == 0) {
      throw Exception('Source video file does not exist or is empty: $inputPath');
    }

    final outputPath = customOutputPath ?? await generateOutputPath(inputPath);
    final command = buildCommand(
      inputPath: inputPath,
      outputPath: outputPath,
      removeMetadata: removeMetadata,
      modifyAudio: modifyAudio,
      modifyVisuals: modifyVisuals,
      upscale1080p: upscale1080p,
    );

    return await _executeFFmpeg(command, outputPath);
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
