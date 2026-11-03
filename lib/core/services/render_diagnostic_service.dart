import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';

/// Diagnostic summary of rendered video metadata extracted via FFprobe.
class RenderDiagnosticInfo {
  final String path;
  final int? width;
  final int? height;
  final String? videoCodec;
  final String? videoProfile;
  final String? videoBitrate;
  final String? audioCodec;
  final String? audioSampleRate;
  final int? audioChannels;
  final String? audioBitrate;
  final int? durationMs;
  final int? fileSizeBytes;

  const RenderDiagnosticInfo({
    required this.path,
    this.width,
    this.height,
    this.videoCodec,
    this.videoProfile,
    this.videoBitrate,
    this.audioCodec,
    this.audioSampleRate,
    this.audioChannels,
    this.audioBitrate,
    this.durationMs,
    this.fileSizeBytes,
  });

  bool get isPortrait => (height ?? 0) > (width ?? 0);
  bool get isTrue4kPortrait => (width ?? 0) >= 2160 && (height ?? 0) >= 3840;
  bool get isTruncatedPortrait => (height ?? 0) == 2160 && (width ?? 0) < 2160;

  String get summary =>
      '[Render Diagnostic]\n'
      '  Path: $path\n'
      '  Resolution: ${width ?? "?"}x${height ?? "?"} (${isPortrait ? "Portrait" : "Landscape"})\n'
      '  Video: Codec=$videoCodec, Profile=$videoProfile, Bitrate=$videoBitrate\n'
      '  Audio: Codec=$audioCodec, SampleRate=${audioSampleRate}Hz, Channels=$audioChannels, Bitrate=$audioBitrate\n'
      '  Duration: ${durationMs != null ? "${(durationMs! / 1000).toStringAsFixed(2)}s" : "?"}\n'
      '  File Size: ${fileSizeBytes != null ? "${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB" : "?"}\n'
      '  4K Status: ${isTrue4kPortrait ? "True 4K Portrait (2160x3840)" : (isTruncatedPortrait ? "Truncated Portrait (~1216x2160)" : "Standard / Landscape")}';
}

class RenderIntegrityException implements Exception {
  final String message;
  const RenderIntegrityException(this.message);
  @override
  String toString() => 'RenderIntegrityException: $message';
}

/// Service for inspecting rendered video metadata and encoding characteristics.
class RenderDiagnosticService {
  /// Inspects rendered video using FFprobe to produce diagnostic report.
  static Future<RenderDiagnosticInfo?> inspectRenderedFile(
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final sizeBytes = await file.length();

      final session = await FFprobeKit.getMediaInformation(filePath);
      final mediaInfo = session.getMediaInformation();
      if (mediaInfo == null) return null;

      final parsed = _parseStreams(mediaInfo);
      final durationSec = double.tryParse(mediaInfo.getDuration() ?? '') ?? 0.0;
      final info = RenderDiagnosticInfo(
        path: filePath,
        width: parsed.width,
        height: parsed.height,
        videoCodec: parsed.videoCodec,
        videoProfile: parsed.videoProfile,
        videoBitrate: parsed.videoBitrate,
        audioCodec: parsed.audioCodec,
        audioSampleRate: parsed.audioSampleRate,
        audioChannels: parsed.audioChannels,
        audioBitrate: parsed.audioBitrate,
        durationMs: (durationSec * 1000).toInt(),
        fileSizeBytes: sizeBytes,
      );

      debugPrint(info.summary);
      return info;
    } catch (e) {
      debugPrint('[FFprobe Diagnostic] Failed to inspect $filePath: $e');
      return null;
    }
  }

  static ({
    int? width,
    int? height,
    String? videoCodec,
    String? videoProfile,
    String? videoBitrate,
    String? audioCodec,
    String? audioSampleRate,
    int? audioChannels,
    String? audioBitrate,
  })
  _parseStreams(dynamic mediaInfo) {
    int? w, h, aChannels;
    String? vCodec, vProfile, vBitrate, aCodec, aSampleRate, aBitrate;

    for (final s in mediaInfo.getStreams()) {
      if (s.getType() == 'video') {
        w = s.getWidth();
        h = s.getHeight();
        vCodec = s.getCodec()?.toUpperCase();
        vProfile = s.getStringProperty('profile');
        vBitrate = s.getBitrate() ?? mediaInfo.getBitrate();
      } else if (s.getType() == 'audio') {
        aCodec = s.getCodec()?.toUpperCase();
        aSampleRate = s.getSampleRate();
        aChannels = s.getNumberProperty('channels')?.toInt();
        aBitrate = s.getBitrate();
      }
    }
    return (
      width: w,
      height: h,
      videoCodec: vCodec,
      videoProfile: vProfile,
      videoBitrate: vBitrate,
      audioCodec: aCodec,
      audioSampleRate: aSampleRate,
      audioChannels: aChannels,
      audioBitrate: aBitrate,
    );
  }
}
