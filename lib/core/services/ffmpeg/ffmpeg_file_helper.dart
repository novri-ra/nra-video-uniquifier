import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Helper responsible for FFmpeg file staging, target directory resolution, and export.
class FfmpegFileHelper {
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

  /// Resolves the public target directory (/storage/emulated/0/Movies/Uniquifier).
  static Future<Directory> resolveTargetDir() async {
    if (Platform.isAndroid) {
      final publicMovies = Directory('/storage/emulated/0/Movies/Uniquifier');
      try {
        if (!await publicMovies.exists()) {
          await publicMovies.create(recursive: true);
        }
        return publicMovies;
      } catch (e) {
        debugPrint(
          '[FfmpegFileHelper] public target dir probe failed: '
          '${e.runtimeType}',
        );
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
        } catch (e) {
          debugPrint(
            '[FfmpegFileHelper] external dirs probe failed: ${e.runtimeType}',
          );
        }
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
    final baseName = dotIndex != -1
        ? fileName.substring(0, dotIndex)
        : fileName;
    final targetDir = await resolveTargetDir();
    return '${targetDir.path}/UQ_${baseName}_${DateTime.now().millisecondsSinceEpoch}.mp4';
  }

  /// Exports rendered video from sandbox cache to target destination.
  static Future<String> exportStagedFile(
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
    } catch (e) {
      debugPrint('[FfmpegFileHelper] export copy failed: ${e.runtimeType}');
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
      } catch (e) {
        debugPrint(
          '[FfmpegFileHelper] export fallback failed: ${e.runtimeType}',
        );
        return stagedPath;
      }
    }
  }

  /// Deletes partial or aborted files, guarding against deleting source media.
  static void deletePartialFile(String path, {String? sourcePath}) {
    try {
      if (sourcePath != null && path == sourcePath) return;
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (e) {
      debugPrint(
        '[FfmpegFileHelper] partial file delete failed: ${e.runtimeType}',
      );
    }
  }
}
