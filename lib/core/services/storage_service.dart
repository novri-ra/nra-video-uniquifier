import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storage_space/storage_space.dart';

class StorageService {
  static const int minRequiredBytes =
      (1500 * 1024 * 1024); // 1.5 GB minimum threshold

  /// Returns true if at least 1.5 GB free disk space is available.
  static Future<bool> hasEnoughSpace() async {
    try {
      if (!Platform.isAndroid) return true;
      final space = await getStorageSpace(
        lowOnSpaceThreshold: minRequiredBytes,
        fractionDigits: 1,
      );
      final freeBytes = space.free;
      debugPrint(
        '[StorageService] Free disk space: ${(freeBytes / (1024 * 1024)).toStringAsFixed(1)} MB (required: ${(minRequiredBytes / (1024 * 1024)).toStringAsFixed(1)} MB)',
      );
      return freeBytes >= minRequiredBytes;
    } catch (e) {
      debugPrint(
        '[StorageService] Error checking storage space: $e. Falling back to permissive check.',
      );
      return true; // Fallback to permissive on error
    }
  }

  /// Prune stale staged files older than 24 hours.
  static Future<int> pruneStaleFiles() async {
    int freed = 0;
    try {
      final tempDir = await getTemporaryDirectory();
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      for (final entry in tempDir.listSync(followLinks: false)) {
        if (entry is File) {
          try {
            final name = entry.path.split(RegExp(r'[/\\]')).last;
            if (name.startsWith('staged_') || name.startsWith('thumb_')) {
              final modified = entry.lastModifiedSync();
              if (modified.isBefore(cutoff)) {
                final len = entry.lengthSync();
                entry.deleteSync();
                freed += len;
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return freed;
  }

  /// Delete a partial/failed output file safely.
  static void cleanupPartialFile(String? path) {
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }
}
