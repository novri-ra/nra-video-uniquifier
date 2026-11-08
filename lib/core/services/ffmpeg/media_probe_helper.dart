import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:flutter/foundation.dart';

/// Probes media stream properties such as duration, resolution, and orientation.
class MediaProbeHelper {
  /// Probes video duration, width, and height using FFprobeKit.
  ///
  /// Returns zeros for all dimensions upon probe failure or missing streams.
  static Future<({int durationMs, int width, int height})> probeMediaMeta(
    String path,
  ) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      if (info != null) {
        final durMs =
            ((double.tryParse(info.getDuration() ?? '') ?? 0.0) * 1000).toInt();
        for (final s in info.getStreams()) {
          if (s.getType() == 'video') {
            return (
              durationMs: durMs,
              width: s.getWidth() ?? 0,
              height: s.getHeight() ?? 0,
            );
          }
        }
        return (durationMs: durMs, width: 0, height: 0);
      }
    } catch (e) {
      // FFprobe errors echo the media path; log the type only.
      debugPrint('[MediaProbeHelper] media probe failed: ${e.runtimeType}');
    }
    return (durationMs: 0, width: 0, height: 0);
  }
}
