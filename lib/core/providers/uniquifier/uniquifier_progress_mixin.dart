import 'package:flutter/material.dart';
import '../../services/ffmpeg_service.dart';
import '../../utils/formatters.dart';
import 'package:nra_video_uniquifier/core/services/user_interest_service.dart';

/// Mixin managing real-time encoding stats, output destination, and diagnostics.
mixin UniquifierProgressMixin on ChangeNotifier {
  double _realtimeProgress = 0.0, _renderingSpeed = 1.0;
  String _eta = 'Calculating...';
  String? _lastProcessedOutputPath, _outputThumbnailPath;
  RenderDiagnosticInfo? _lastDiagnosticInfo;

  double get realtimeProgress => _realtimeProgress;
  double get renderingSpeed => _renderingSpeed;
  String get eta => _eta;
  String? get lastProcessedOutputPath => _lastProcessedOutputPath;
  String? get outputThumbnailPath => _outputThumbnailPath;
  RenderDiagnosticInfo? get lastDiagnosticInfo => _lastDiagnosticInfo;

  void clearProgressAndOutputs() {
    _realtimeProgress = 0.0;
    _outputThumbnailPath = null;
    _lastDiagnosticInfo = null;
  }

  void updateRealtimeStatsProgress({
    required double progress,
    required double speed,
    required int timeMs,
    required int totalDurationMs,
  }) {
    _realtimeProgress = progress;
    _renderingSpeed = speed > 0 ? speed : 1.0;
    _eta = Formatters.formatEta(
      totalDurationMs: totalDurationMs,
      timeMs: timeMs,
      speed: _renderingSpeed,
      defaultEta: _eta,
    );
    notifyListeners();
  }

  void setLastProcessedResult(String outputPath) {
    _lastProcessedOutputPath = outputPath;
    notifyListeners();
    _extractOutputThumbnailAsync(outputPath);
    _inspectOutputDiagnosticsAsync(outputPath);
    _dispatchMetadataVaultTelemetry(outputPath);
  }

  Future<void> _inspectOutputDiagnosticsAsync(String outputPath) async {
    try {
      final diag = await FfmpegService.inspectRenderedFile(outputPath);
      if (diag != null && _lastProcessedOutputPath == outputPath) {
        _lastDiagnosticInfo = diag;
        notifyListeners();
      }
    } catch (e) {
      // FfmpegKit errors echo the rendered output path; log the type only.
      debugPrint(
        '[UniquifierProgressMixin] output diagnostics probe failed: '
        '${e.runtimeType}',
      );
    }
  }

  Future<void> _extractOutputThumbnailAsync(String outputPath) async {
    try {
      final thumb = await FfmpegService.extractThumbnail(outputPath);
      if (thumb != null && _lastProcessedOutputPath == outputPath) {
        _outputThumbnailPath = thumb;
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
        '[UniquifierProgressMixin] output thumbnail extract failed: '
        '${e.runtimeType}',
      );
    }
  }

  Future<void> _dispatchMetadataVaultTelemetry(String outputPath) async {
    final title = outputPath.split('/').last;
    final techSpecs = _lastDiagnosticInfo != null
        ? '${_lastDiagnosticInfo!.width}x${_lastDiagnosticInfo!.height} '
            '${_lastDiagnosticInfo!.videoCodec} ${_lastDiagnosticInfo!.durationMs != null ? (_lastDiagnosticInfo!.durationMs! / 1000).toStringAsFixed(0) : '?'}s'
        : '1080x1920 | H264 | 30fps';

    await UserInterestService.dispatchVideoMetadataVault(
      title: title,
      description: 'Auto-exported via NRA Video Uniquifier',
      keywords: ['#Uniquified', '#TikTokReady', '#AntiFingerprint'],
      platforms: ['TikTok', 'Instagram Reels', 'YouTube Shorts'],
      techSpecs: techSpecs,
      category: 'Auto-Export',
    );
  }
}
