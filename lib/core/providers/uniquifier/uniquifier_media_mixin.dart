import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:flutter/material.dart';
import '../../services/ffmpeg_service.dart';
import '../../utils/formatters.dart';

/// Mixin managing source media input state, probing metadata, and thumbnail extraction.
mixin UniquifierMediaMixin on ChangeNotifier {
  String? _selectedFileName, _selectedFilePath, _thumbnailPath;
  String _fileResolution = '1080×1920',
      _fileSize = '0 B',
      _fileCodec = 'H.264',
      _fps = '30 FPS',
      _audioInfo = 'AAC 48kHz',
      _duration = '0:00',
      _sha256 = '';
  bool _isPortrait = true;
  int _totalDurationMs = 0;

  String? get selectedFileName => _selectedFileName;
  String? get selectedFilePath => _selectedFilePath;
  String? get thumbnailPath => _thumbnailPath;
  String get fileResolution => _fileResolution;
  String get fileSize => _fileSize;
  String get fileCodec => _fileCodec;
  String get fps => _fps;
  String get audioInfo => _audioInfo;
  String get duration => _duration;
  String get sha256 => _sha256;
  bool get isPortrait => _isPortrait;
  int get totalDurationMs => _totalDurationMs;

  void clearMediaSelection() {
    _selectedFileName = null;
    _selectedFilePath = null;
    _thumbnailPath = null;
  }

  void setVideoFile({
    required String path,
    required String name,
    required int sizeBytes,
  }) {
    _selectedFilePath = path;
    _selectedFileName = name;
    _fileSize = Formatters.formatFileSize(sizeBytes);
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
      if (s.getType() == 'video') _applyVideoStream(s);
      if (s.getType() == 'audio') {
        _audioInfo = Formatters.formatAudioInfo(
          s.getCodec(),
          s.getSampleRate(),
        );
      }
    }
  }

  void _applyVideoStream(dynamic s) {
    final width = s.getWidth(), height = s.getHeight();
    if (width != null && height != null) {
      _fileResolution = '$width×$height';
      _isPortrait = height >= width;
    }
    final codec = s.getCodec();
    if (codec != null) _fileCodec = codec.toUpperCase();
    final rFrameRate = s.getRealFrameRate();
    if (rFrameRate != null && rFrameRate.isNotEmpty) _fps = '$rFrameRate FPS';
  }

  void _applyMediaDuration(String? durationStr) {
    if (durationStr == null) return;
    final sec = double.tryParse(durationStr) ?? 0.0;
    _totalDurationMs = (sec * 1000).toInt();
    _duration = formatDuration(durationStr);
  }

  static String formatDuration(String? durationStr) =>
      Formatters.formatDuration(durationStr);
  static String formatFileSize(int bytes) => Formatters.formatFileSize(bytes);
}
