import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storage_space/storage_space.dart';

class VideoExportItem {
  final File file;
  final String fileName;
  final int bytes;
  final DateTime modified;

  const VideoExportItem({
    required this.file,
    required this.fileName,
    required this.bytes,
    required this.modified,
  });

  String get formattedSize {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  String get formattedDate {
    final now = DateTime.now();
    final isToday =
        now.year == modified.year &&
        now.month == modified.month &&
        now.day == modified.day;
    final hour = modified.hour.toString().padLeft(2, '0');
    final minute = modified.minute.toString().padLeft(2, '0');

    if (isToday) return 'Today, $hour:$minute';
    return '${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')} $hour:$minute';
  }
}

class HistoryService {
  static Future<List<Directory>> getTargetDirectories() async {
    final dirs = <Directory>[];
    if (Platform.isAndroid) {
      dirs.add(Directory('/storage/emulated/0/Movies/Uniquifier'));
      try {
        final extDirs = await getExternalStorageDirectories(
          type: StorageDirectory.movies,
        );
        if (extDirs != null) {
          for (final dir in extDirs) {
            dirs.add(Directory('${dir.path}/Uniquifier'));
          }
        }
      } catch (_) {}
    }
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      dirs.add(Directory('${appDocs.path}/Movies/Uniquifier'));
    } catch (_) {}
    return dirs;
  }

  static Future<List<VideoExportItem>> scanDirectory(
    Directory dir,
    Set<String> seenPaths,
  ) async {
    final results = <VideoExportItem>[];
    if (!await dir.exists()) return results;
    try {
      await for (final entry in dir.list(followLinks: false)) {
        if (entry is File) {
          final name = entry.path.split(RegExp(r'[/\\]')).last;
          if (name.startsWith('.') || name.contains('.trashed-')) continue;
          final lower = name.toLowerCase();
          final isVideo = lower.endsWith('.mp4') || lower.endsWith('.mov');
          if (isVideo && seenPaths.add(entry.path)) {
            final stat = await entry.stat();
            if (stat.size > 0) {
              results.add(
                VideoExportItem(
                  file: entry,
                  fileName: name,
                  bytes: stat.size,
                  modified: stat.modified,
                ),
              );
            }
          }
        }
      }
    } catch (_) {}
    return results;
  }

  static Future<List<VideoExportItem>> loadHistory() async {
    final dirs = await getTargetDirectories();
    final foundFiles = <VideoExportItem>[];
    final seenPaths = <String>{};

    for (final dir in dirs) {
      foundFiles.addAll(await scanDirectory(dir, seenPaths));
    }
    foundFiles.sort((a, b) => b.modified.compareTo(a.modified));
    return foundFiles;
  }

  static Future<void> _cleanupThumbnail(File videoFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final name = videoFile.path.split(RegExp(r'[/\\]')).last;
      final baseName = name.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final thumbFile = File('${tempDir.path}/thumbnails/thumb_$baseName.jpg');
      if (await thumbFile.exists()) {
        await thumbFile.delete();
      }
    } catch (e) {
      debugPrint(
        '[HistoryService] Thumbnail cleanup skipped for ${videoFile.path}: $e',
      );
    }
  }

  static Future<bool> deleteItem(File file) async {
    try {
      final target = File(file.path);
      if (await target.exists()) {
        await target.delete();
      }
      await _cleanupThumbnail(target);
      return true; // Already gone or successfully deleted from disk
    } catch (e, stackTrace) {
      debugPrint(
        '[HistoryService] Failed to delete file ${file.path}: $e\n$stackTrace',
      );
      return false;
    }
  }

  static Future<int> deleteItems(List<File> files) async {
    int deletedCount = 0;
    for (final file in files) {
      final success = await deleteItem(file);
      if (success) {
        deletedCount++;
      }
    }
    return deletedCount;
  }

  static Future<int> deleteExportItems(List<VideoExportItem> items) async {
    return deleteItems(items.map((i) => i.file).toList());
  }

  static Future<StorageSpace?> getDeviceStorage() async {
    try {
      return await getStorageSpace(
        fractionDigits: 1,
        lowOnSpaceThreshold: 1024 * 1024 * 500,
      );
    } catch (_) {
      return null;
    }
  }

  static String formatTotalSize(List<VideoExportItem> items) {
    final totalBytes = items.fold<int>(0, (sum, item) => sum + item.bytes);
    if (totalBytes >= 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (totalBytes >= 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
  }
}
