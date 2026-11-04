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
    } catch (_) {
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
      } catch (_) {
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
      return targetFile.path;
    } catch (_) {
      return null;
    }
  }
}
