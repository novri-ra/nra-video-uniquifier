import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:flutter/material.dart';
import '../services/ffmpeg_service.dart';

class UniquifierProvider extends ChangeNotifier {
  // Source Video State (initial is null / empty)
  String? _selectedFileName;
  String? _selectedFilePath;
  String? _thumbnailPath;
  String _fileResolution = '1080×1920';
  String _fileSize = '0 B';
  String _fileCodec = 'H.264';
  String _fps = '30 FPS';
  String _audioInfo = 'AAC 48kHz';
  String _duration = '0:00';
  String _sha256 = '';
  int _totalDurationMs = 0;

  // Real-time Telemetry
  double _realtimeProgress = 0.0;
  double _renderingSpeed = 1.0;
  String _eta = 'Calculating...';

  // Last processed output & Output thumbnail
  String? _lastProcessedOutputPath;
  String? _outputThumbnailPath;

  // Toggle Settings
  bool _removeMetadata = true;
  bool _modifyAudio = true;
  bool _modifyVisuals = true;
  bool _upscale1080p = false;

  // Advanced Settings
  String _selectedUpscaleTarget = '1080p'; // '720p', '1080p', '2k'
  bool _hardwareAcceleration = true;

  // Navigation
  int _currentTabIndex = 0;

  // Getters
  String? get selectedFileName => _selectedFileName;
  String? get selectedFilePath => _selectedFilePath;
  String? get thumbnailPath => _thumbnailPath;
  String? get lastProcessedOutputPath => _lastProcessedOutputPath;
  String? get outputThumbnailPath => _outputThumbnailPath;
  String get fileResolution => _fileResolution;
  String get fileSize => _fileSize;
  String get fileCodec => _fileCodec;
  String get fps => _fps;
  String get audioInfo => _audioInfo;
  String get duration => _duration;
  String get sha256 => _sha256;
  int get totalDurationMs => _totalDurationMs;

  double get realtimeProgress => _realtimeProgress;
  double get renderingSpeed => _renderingSpeed;
  String get eta => _eta;

  bool get removeMetadata => _removeMetadata;
  bool get modifyAudio => _modifyAudio;
  bool get modifyVisuals => _modifyVisuals;
  bool get upscale1080p => _upscale1080p;

  String get selectedUpscaleTarget => _selectedUpscaleTarget;
  bool get hardwareAcceleration => _hardwareAcceleration;
  int get currentTabIndex => _currentTabIndex;

  // Actions
  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void toggleRemoveMetadata(bool val) {
    _removeMetadata = val;
    notifyListeners();
  }

  void toggleModifyAudio(bool val) {
    _modifyAudio = val;
    notifyListeners();
  }

  void toggleModifyVisuals(bool val) {
    _modifyVisuals = val;
    notifyListeners();
  }

  void toggleUpscale1080p(bool val) {
    _upscale1080p = val;
    notifyListeners();
  }

  void setUpscaleTarget(String target) {
    _selectedUpscaleTarget = target;
    notifyListeners();
  }

  void toggleHardwareAcceleration(bool val) {
    _hardwareAcceleration = val;
    notifyListeners();
  }

  void updateRealtimeStats(double progress, double speed, int timeMs) {
    _realtimeProgress = progress;
    _renderingSpeed = speed > 0 ? speed : 1.0;
    if (_totalDurationMs > 0 && timeMs > 0) {
      final remMs = (_totalDurationMs - timeMs).clamp(0, 3600000);
      final remSec = (remMs / (_renderingSpeed * 1000)).ceil();
      _eta = '${(remSec ~/ 60).toString().padLeft(2, '0')}:${(remSec % 60).toString().padLeft(2, '0')}s rem';
    }
    notifyListeners();
  }

  void applyPreset({
    required bool removeMetadata,
    required bool modifyAudio,
    required bool modifyVisuals,
    required bool upscale1080p,
    String upscaleTarget = '1080p',
  }) {
    _removeMetadata = removeMetadata;
    _modifyAudio = modifyAudio;
    _modifyVisuals = modifyVisuals;
    _upscale1080p = upscale1080p;
    _selectedUpscaleTarget = upscaleTarget;
    _currentTabIndex = 0;
    notifyListeners();
  }

  void clearSelection() {
    _selectedFileName = null;
    _selectedFilePath = null;
    _thumbnailPath = null;
    _realtimeProgress = 0.0;
    _outputThumbnailPath = null;
    notifyListeners();
  }

  void setLastProcessedResult(String outputPath) {
    _lastProcessedOutputPath = outputPath;
    notifyListeners();
    _extractOutputThumbnailAsync(outputPath);
  }

  void setOutputThumbnail(String? thumbPath) {
    _outputThumbnailPath = thumbPath;
    notifyListeners();
  }

  Future<void> _extractOutputThumbnailAsync(String outputPath) async {
    try {
      final thumb = await FfmpegService.extractThumbnail(outputPath);
      if (thumb != null && _lastProcessedOutputPath == outputPath) {
        _outputThumbnailPath = thumb;
        notifyListeners();
      }
    } catch (_) {}
  }

  void setVideoFile({
    required String path,
    required String name,
    required int sizeBytes,
  }) {
    _selectedFilePath = path;
    _selectedFileName = name;
    _fileSize = _formatBytes(sizeBytes);
    _fileResolution = '1080×1920';
    _fileCodec = name.toLowerCase().endsWith('.mov') ? 'ProRes/H.264' : 'H.264';
    _fps = '30 FPS';
    _audioInfo = 'AAC 48kHz';
    _duration = '0:00';
    _sha256 = '${name.hashCode.toRadixString(16).padLeft(8, '0')}…';
    notifyListeners();

    _extractThumbnailAsync(path);
    _probeMediaInfo(path);
  }

  Future<void> _extractThumbnailAsync(String path) async {
    try {
      final thumb = await FfmpegService.extractThumbnail(path);
      if (thumb != null && _selectedFilePath == path) {
        _thumbnailPath = thumb;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _probeMediaInfo(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final mediaInfo = session.getMediaInformation();
      if (mediaInfo != null) {
        _applyMediaStreams(mediaInfo.getStreams());
        _applyMediaDuration(mediaInfo.getDuration());
        notifyListeners();
      }
    } catch (_) {}
  }

  void _applyMediaStreams(dynamic streams) {
    for (final s in streams) {
      if (s.getType() == 'video') {
        _applyVideoStream(s);
      } else if (s.getType() == 'audio') {
        _applyAudioStream(s);
      }
    }
  }

  void _applyVideoStream(dynamic s) {
    final width = s.getWidth();
    final height = s.getHeight();
    if (width != null && height != null) _fileResolution = '$width×$height';
    final codec = s.getCodec();
    if (codec != null) _fileCodec = codec.toUpperCase();
    final rFrameRate = s.getRealFrameRate();
    if (rFrameRate != null && rFrameRate.isNotEmpty) _fps = '$rFrameRate FPS';
  }

  void _applyAudioStream(dynamic s) {
    final sampleRate = s.getSampleRate();
    final audioCodec = s.getCodec()?.toUpperCase() ?? 'AAC';
    final sampleKhz = sampleRate != null && int.tryParse(sampleRate) != null
        ? '${(int.parse(sampleRate) / 1000).toStringAsFixed(0)}kHz'
        : '48kHz';
    _audioInfo = '$audioCodec $sampleKhz';
  }

  void _applyMediaDuration(String? durationStr) {
    if (durationStr == null) return;
    final sec = double.tryParse(durationStr) ?? 0.0;
    _totalDurationMs = (sec * 1000).toInt();
    _duration = formatDuration(durationStr);
  }

  /// Formats raw seconds or duration strings to mm:ss or hh:mm:ss display.
  static String formatDuration(String? durationStr) {
    if (durationStr == null) return '0:00';
    final sec = double.tryParse(durationStr)?.toInt() ?? 0;
    if (sec <= 0) return '0:00';
    final minutes = sec ~/ 60;
    final remainingSec = sec % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remMin = minutes % 60;
      return '$hours:${remMin.toString().padLeft(2, '0')}:${remainingSec.toString().padLeft(2, '0')}';
    }
    return '$minutes:${remainingSec.toString().padLeft(2, '0')}';
  }

  /// Formats byte count into human-readable string (B, KB, MB, GB).
  static String formatFileSize(int bytes) => _formatBytes(bytes);
  static String formatBytes(int bytes) => _formatBytes(bytes);

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
