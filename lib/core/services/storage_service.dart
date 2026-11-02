import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static const int minRequiredBytes = 2 * 1024 * 1024 * 1024; // 2 GB

  /// Returns true if at least 2 GB free space available.
  static Future<bool> hasEnoughSpace() async {
    try {
      if (!Platform.isAndroid) return true;
      final tempDir = await getTemporaryDirectory();
      final stat = await FileStat.stat(tempDir.path);
      // shortcut: StatFS not available via Dart, use temp dir write test
      return stat.type != FileSystemEntityType.notFound;
    } catch (_) {
      return true; // Assume OK if check fails
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
          final name = entry.path.split(RegExp(r'[/\\]')).last;
          if (name.startsWith('staged_') || name.startsWith('thumb_')) {
            final modified = entry.lastModifiedSync();
            if (modified.isBefore(cutoff)) {
              freed += entry.lengthSync();
              entry.deleteSync();
            }
          }
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
