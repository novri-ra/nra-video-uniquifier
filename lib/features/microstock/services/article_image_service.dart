import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// DTO parameter for image resizing and WebP encoding in background Isolate.
class ImageProcessDto {
  final Uint8List rawBytes;
  final int targetWidth;
  final int quality;

  const ImageProcessDto({
    required this.rawBytes,
    this.targetWidth = 720,
    this.quality = 80,
  });
}

/// Service for downloading, resizing, and caching article images as WebP via background Isolate.
class ArticleImageService {
  @visibleForTesting
  static Directory? tempDirectoryOverride;

  @visibleForTesting
  static Future<Uint8List?> Function(Uri uri)? customImageDownload;

  /// Pure Dart image processing executed inside a background worker Isolate.
  static Uint8List? processImageInWorker(ImageProcessDto dto) {
    try {
      final decoded = img.decodeImage(dto.rawBytes);
      if (decoded == null) return null;

      img.Image processed = decoded;
      if (processed.width > dto.targetWidth) {
        processed = img.copyResize(processed, width: dto.targetWidth);
      }

      return img.encodeWebP(processed, quality: dto.quality, lossless: false);
    } catch (e) {
      // Bytes, URLs and paths all stay out of the log; only the failure type.
      debugPrint(
        '[ArticleImageService] image isolate worker failed: '
        '${e.runtimeType}',
      );
      return null;
    }
  }

  /// Downloads remote image, processes WebP conversion in Isolate, and saves to cache directory.
  static Future<String?> downloadAndCacheImage(
    String imageUrl,
    String articleId,
  ) async {
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) return null;

    try {
      // 1. Resolve cache directory and ensure news_images subfolder exists
      Directory cacheDir;
      try {
        cacheDir = tempDirectoryOverride ?? await getTemporaryDirectory();
      } catch (e) {
        debugPrint(
          '[ArticleImageService] cache dir probe failed: ${e.runtimeType}',
        );
        cacheDir = Directory.systemTemp;
      }

      final imagesDir = Directory('${cacheDir.path}/news_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final targetFile = File('${imagesDir.path}/${articleId.hashCode}.webp');
      if (await targetFile.exists() && (await targetFile.length()) > 0) {
        return targetFile.path;
      }

      // 2. Fetch raw image bytes with 5-second timeout
      final uri = Uri.parse(imageUrl);
      Uint8List? rawBytes;

      if (customImageDownload != null) {
        rawBytes = await customImageDownload!(uri);
      } else {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 5);
        try {
          final request = await client.getUrl(uri);
          request.headers.set(
            'User-Agent',
            'NRA-Video-Uniquifier/1.0 (Flutter; Mobile)',
          );
          final response = await request.close().timeout(
            const Duration(seconds: 5),
          );

          if (response.statusCode != 200) return null;

          final contentType = response.headers.contentType?.mimeType ?? '';
          if (contentType.isNotEmpty && !contentType.startsWith('image/')) {
            return null;
          }

          final builder = BytesBuilder(copy: false);
          await for (final chunk in response.timeout(
            const Duration(seconds: 5),
          )) {
            builder.add(chunk);
          }
          rawBytes = builder.toBytes();
        } finally {
          client.close();
        }
      }

      if (rawBytes == null || rawBytes.isEmpty) return null;

      // 3. Process resize and WebP conversion inside background Isolate
      final webpBytes = await Isolate.run(
        () => processImageInWorker(
          ImageProcessDto(rawBytes: rawBytes!, targetWidth: 720, quality: 80),
        ),
      );

      if (webpBytes == null || webpBytes.isEmpty) return null;

      // 4. Persist WebP file to local storage
      await targetFile.writeAsBytes(webpBytes, flush: true);

      // 5. Trigger cache quota pruning asynchronously
      unawaited(pruneCacheIfExceedsLimit());

      return targetFile.path;
    } catch (e) {
      debugPrint(
        '[ArticleImageService] image download failed: ${e.runtimeType}',
      );
      return null;
    }
  }

  /// Scans news_images/ folder. If total file size exceeds [maxBytes] (default 50 MB),
  /// deletes oldest files (FIFO by lastModified) until total drops below [targetBytes] (default 40 MB).
  static Future<void> pruneCacheIfExceedsLimit({
    int maxBytes = 50 * 1024 * 1024,
    int targetBytes = 40 * 1024 * 1024,
  }) async {
    try {
      Directory cacheDir;
      try {
        cacheDir = tempDirectoryOverride ?? await getTemporaryDirectory();
      } catch (e) {
        debugPrint(
          '[ArticleImageService] cache dir probe failed: ${e.runtimeType}',
        );
        cacheDir = Directory.systemTemp;
      }

      final imagesDir = Directory('${cacheDir.path}/news_images');
      if (!await imagesDir.exists()) return;

      final entities = await imagesDir.list().toList();
      final files = <File>[];
      int totalBytes = 0;

      for (final entity in entities) {
        if (entity is File) {
          files.add(entity);
          try {
            totalBytes += await entity.length();
          } catch (e) {
            debugPrint(
              '[ArticleImageService] image cache size read failed: '
              '${e.runtimeType}',
            );
          }
        }
      }

      if (totalBytes <= maxBytes) return;

      // Sort oldest files first
      final fileWithStats = <MapEntry<File, DateTime>>[];
      for (final file in files) {
        try {
          final stat = await file.stat();
          fileWithStats.add(MapEntry(file, stat.modified));
        } catch (e) {
          debugPrint(
            '[ArticleImageService] image cache stat failed: ${e.runtimeType}',
          );
          fileWithStats.add(
            MapEntry(file, DateTime.fromMillisecondsSinceEpoch(0)),
          );
        }
      }
      fileWithStats.sort((a, b) => a.value.compareTo(b.value));

      for (final entry in fileWithStats) {
        if (totalBytes <= targetBytes) break;
        try {
          final len = await entry.key.length();
          await entry.key.delete();
          totalBytes -= len;
        } catch (e) {
          debugPrint(
            '[ArticleImageService] image cache prune delete failed: '
            '${e.runtimeType}',
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[ArticleImageService] image cache prune failed: ${e.runtimeType}',
      );
    }
  }
}
