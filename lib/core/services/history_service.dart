import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:storage_space/storage_space.dart';
import 'media_scanner_service.dart';

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
      } catch (e) {
        debugPrint('[HistoryService] external dirs probe failed: $e');
      }
    }
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      dirs.add(Directory('${appDocs.path}/Movies/Uniquifier'));
    } catch (e) {
      debugPrint('[HistoryService] app docs dir probe failed: $e');
    }
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
    } catch (e) {
      // FileSystemException echoes the absolute directory path; type only.
      debugPrint('[HistoryService] scan directory failed: ${e.runtimeType}');
    }
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

  /// Returns whether the device is running on Android 11+ (API 30+).
  static bool get isAndroid11OrHigher {
    if (!Platform.isAndroid) return false;
    try {
      final osVersion = Platform.operatingSystemVersion;
      final apiMatch = RegExp(
        r'API\s*(\d+)',
        caseSensitive: false,
      ).firstMatch(osVersion);
      if (apiMatch != null) {
        final api = int.tryParse(apiMatch.group(1) ?? '');
        if (api != null) return api >= 30;
      }
      final verMatch = RegExp(
        r'(?:Android\s*)?(\d+)',
        caseSensitive: false,
      ).firstMatch(osVersion);
      if (verMatch != null) {
        final ver = int.tryParse(verMatch.group(1) ?? '');
        if (ver != null) return ver >= 11;
      }
    } catch (e) {
      debugPrint('[HistoryService] android 11 check failed: $e');
    }
    return true; // Default to true on modern Android
  }

  /// Returns Android SDK int using device_info_plus (fallback to osVersion parse).
  static Future<int> getAndroidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      debugPrint('[HistoryService] device info sdk probe failed: $e');
      try {
        final osVersion = Platform.operatingSystemVersion;
        final apiMatch = RegExp(
          r'API\s*(\d+)',
          caseSensitive: false,
        ).firstMatch(osVersion);
        if (apiMatch != null) {
          return int.tryParse(apiMatch.group(1) ?? '') ?? 30;
        }
      } catch (innerError) {
        debugPrint('[HistoryService] sdk version probe failed: $innerError');
      }
      return 30;
    }
  }

  /// Checks whether storage permissions are granted.
  /// On Android 11+ (API 30+), MANAGE_EXTERNAL_STORAGE is required for deleting
  /// files from public shared storage (/storage/emulated/0/Movies).
  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      if (isAndroid11OrHigher) {
        return await Permission.manageExternalStorage.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    } catch (e) {
      // permission_handler errors may echo the permission name.
      debugPrint(
        '[HistoryService] storage permission check failed: ${e.runtimeType}',
      );
      return true;
    }
  }

  /// Requests storage/media permissions with appropriate Android version handling.
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      if (isAndroid11OrHigher) {
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) return true;
        return await Permission.manageExternalStorage.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (e) {
      debugPrint(
        '[HistoryService] storage permission request failed: '
        '${e.runtimeType}',
      );
      return false;
    }
  }

  static const MethodChannel _storageChannel = MethodChannel(
    'id.novrira.videouniquifier/storage_intent',
  );

  /// Direct intent dispatcher for MANAGE_APP_ALL_FILES_ACCESS_PERMISSION on Android 11+.
  /// Calls native MethodChannel to directly land on app's All Files Access toggle switch.
  static Future<void> requestAllFilesAccessDirectly() async {
    if (!Platform.isAndroid) return;
    try {
      final res = await _storageChannel.invokeMethod<bool>(
        'openAllFilesAccessSettings',
      );
      if (res == true) return;
    } catch (e) {
      debugPrint('[HistoryService] Native storage intent channel failed: $e');
    }

    // Fallback: permission_handler openAppSettings()
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('[HistoryService] Fallback openAppSettings failed: $e');
    }
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
        '[HistoryService] Thumbnail cleanup skipped for '
        '${videoFile.path.split(RegExp(r'[/\\]')).last}: ${e.runtimeType}',
      );
    }
  }

  static Future<bool> deleteItem(File file) async {
    try {
      final target = File(file.path);
      if (await target.exists()) {
        await target.delete();
        // Strict post-delete verification: confirm physical removal from disk
        if (await target.exists()) {
          debugPrint(
            '[HistoryService] Physical delete failed, file still exists: '
            '${file.path.split(RegExp(r'[/\\]')).last}',
          );
          return false;
        }
      }
      // Notify Android MediaStore to remove or update indexed file entry
      await MediaScannerService.scanFile(target.path);
      await _cleanupThumbnail(target);
      return true; // Successfully deleted from disk and verified, or already gone
    } catch (e, stackTrace) {
      debugPrint(
        '[HistoryService] Failed to delete file '
        '${file.path.split(RegExp(r'[/\\]')).last}: ${e.runtimeType}\n'
        '$stackTrace',
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

  /// Deletes a collection of [VideoExportItem] and returns the list of file paths
  /// that were successfully and physically deleted from disk.
  static Future<List<String>> deleteExportItemsDetailed(
    List<VideoExportItem> items,
  ) async {
    final deletedPaths = <String>[];
    for (final item in items) {
      try {
        final f = File(item.file.path);
        if (await f.exists()) {
          await f.delete();
          if (!await f.exists()) {
            deletedPaths.add(item.file.path);
            await MediaScannerService.scanFile(item.file.path);
            await _cleanupThumbnail(f);
          } else {
            debugPrint(
              '[HistoryService] Physical delete failed, file still exists: '
              '${item.file.path.split(RegExp(r'[/\\]')).last}',
            );
          }
        } else {
          // File was already removed from disk
          deletedPaths.add(item.file.path);
        }
      } catch (e) {
        debugPrint(
          '[HistoryService] Failed to delete file '
          '${item.file.path.split(RegExp(r'[/\\]')).last}: ${e.runtimeType}',
        );
      }
    }
    return deletedPaths;
  }

  static Future<StorageSpace?> getDeviceStorage() async {
    try {
      return await getStorageSpace(
        fractionDigits: 1,
        lowOnSpaceThreshold: 1024 * 1024 * 500,
      );
    } catch (e) {
      debugPrint('[HistoryService] device storage probe failed: $e');
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
