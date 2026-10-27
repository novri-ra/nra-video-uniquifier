import 'dart:io';
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
    final isToday = now.year == modified.year &&
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
      dirs.add(Directory('/storage/emulated/0/Movies/VideoUniquifier'));
      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.movies);
        if (extDirs != null) {
          for (final dir in extDirs) {
            dirs.add(Directory('${dir.path}/VideoUniquifier'));
          }
        }
      } catch (_) {}
    }
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      dirs.add(Directory('${appDocs.path}/Movies/VideoUniquifier'));
    } catch (_) {}
    return dirs;
  }

  static Future<List<VideoExportItem>> scanDirectory(Directory dir, Set<String> seenPaths) async {
    final results = <VideoExportItem>[];
    if (!await dir.exists()) return results;
    try {
      await for (final entry in dir.list(followLinks: false)) {
        if (entry is File && entry.path.toLowerCase().endsWith('.mp4')) {
          if (seenPaths.add(entry.path)) {
            final stat = await entry.stat();
            results.add(VideoExportItem(
              file: entry,
              fileName: entry.path.split(RegExp(r'[/\\]')).last,
              bytes: stat.size,
              modified: stat.modified,
            ));
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

  static Future<bool> deleteItem(File file) async {
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
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
