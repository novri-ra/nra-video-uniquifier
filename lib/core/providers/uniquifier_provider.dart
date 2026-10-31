import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:flutter/material.dart';
import '../services/ffmpeg_service.dart';
import '../services/settings_service.dart';
import '../utils/formatters.dart';

class UniquifierProvider extends ChangeNotifier {
  UniquifierProvider() {
    SettingsService.upscaleResolutionNotifier.addListener(_onResolutionNotifierChanged);
    SettingsService.upscaleEngineNotifier.addListener(_onUpscaleEngineNotifierChanged);
    SettingsService.videoCodecNotifier.addListener(_onCodecNotifierChanged);
    SettingsService.hardwareAccelerationNotifier.addListener(_onHardwareAccelerationNotifierChanged);
    _initResolution();
  }

  @override
  void dispose() {
    SettingsService.upscaleResolutionNotifier.removeListener(_onResolutionNotifierChanged);
    SettingsService.upscaleEngineNotifier.removeListener(_onUpscaleEngineNotifierChanged);
    SettingsService.videoCodecNotifier.removeListener(_onCodecNotifierChanged);
    SettingsService.hardwareAccelerationNotifier.removeListener(_onHardwareAccelerationNotifierChanged);
    super.dispose();
  }

  void _onResolutionNotifierChanged() {
    if (_targetResolution == SettingsService.upscaleResolutionNotifier.value) return;
    _targetResolution = SettingsService.upscaleResolutionNotifier.value;
    notifyListeners();
  }

  void _onUpscaleEngineNotifierChanged() {
    if (_upscaleEngine == SettingsService.upscaleEngineNotifier.value) return;
    _upscaleEngine = SettingsService.upscaleEngineNotifier.value;
    notifyListeners();
  }

  void _onCodecNotifierChanged() {
    if (_videoCodec == SettingsService.videoCodecNotifier.value) return;
    _videoCodec = SettingsService.videoCodecNotifier.value;
    notifyListeners();
  }

  void _onHardwareAccelerationNotifierChanged() {
    if (_hardwareAcceleration == SettingsService.hardwareAccelerationNotifier.value) return;
    _hardwareAcceleration = SettingsService.hardwareAccelerationNotifier.value;
    notifyListeners();
  }

  Future<void> _initResolution() async {
    try {
      _targetResolution = await SettingsService.getUpscaleResolution();
      _upscaleEngine = await SettingsService.getUpscaleEngine();
      _videoCodec = await SettingsService.getVideoCodec();
      _hardwareAcceleration = await SettingsService.getHardwareAcceleration();
      _enableEnhanceAndDenoise = await SettingsService.getEnhanceAndDenoise();
      _enableDeepAntiFingerprint = await SettingsService.getDeepAntiFingerprint();
      _enableHorizontalFlip = await SettingsService.getHorizontalFlip();
      _enableAggressiveAudio = await SettingsService.getAggressiveAudio();
      _enableAutoTrim = await SettingsService.getAutoTrim();
      _enableDynamicZoom = await SettingsService.getDynamicZoom();
      _enableMicroOverlay = await SettingsService.getMicroOverlay();
      _enableFrameSkip = await SettingsService.getFrameSkip();
      _enableChromaShift = await SettingsService.getChromaShift();
      _canvasScalePercent = await SettingsService.getCanvasScalePercent();
      notifyListeners();
    } catch (_) {}
  }
  // Source Video State (initial is null / empty)
  String? _selectedFileName, _selectedFilePath, _thumbnailPath;
  String _fileResolution = '1080×1920', _fileSize = '0 B', _fileCodec = 'H.264', _fps = '30 FPS', _audioInfo = 'AAC 48kHz', _duration = '0:00', _sha256 = '';
  bool _isPortrait = true;
  int _totalDurationMs = 0;

  // Real-time Telemetry
  double _realtimeProgress = 0.0, _renderingSpeed = 1.0;
  String _eta = 'Calculating...';

  // Last processed output & Output thumbnail
  String? _lastProcessedOutputPath, _outputThumbnailPath;
  RenderDiagnosticInfo? _lastDiagnosticInfo;

  // Toggle Settings
  bool _removeMetadata = true;
  bool _modifyAudio = true;
  bool _modifyVisuals = true;
  bool _upscale1080p = false;
  bool _enableEnhanceAndDenoise = true;
  bool _enableDeepAntiFingerprint = true;
  bool _enableHorizontalFlip = false;
  bool _enableAggressiveAudio = false;
  bool _enableAutoTrim = false;
  bool _enableBlurredCanvas = false;
  bool _muteOriginalAudio = false;
  bool _enableDynamicZoom = false;
  bool _enableMicroOverlay = false;
  bool _enableFrameSkip = false;
  bool _enableChromaShift = false;
  double _canvasScalePercent = 95.0;
  String _activePreset = 'TikTok Fast';

  // Advanced Settings
  TargetResolution _targetResolution = TargetResolution.r1080p;
  UpscaleEngine _upscaleEngine = UpscaleEngine.lanczos;
  VideoCodec _videoCodec = VideoCodec.h264;
  bool _hardwareAcceleration = true;

  // Navigation
  int _currentTabIndex = 0;

  // Getters
  String? get selectedFileName => _selectedFileName;
  String? get selectedFilePath => _selectedFilePath;
  String? get thumbnailPath => _thumbnailPath;
  String? get lastProcessedOutputPath => _lastProcessedOutputPath;
  String? get outputThumbnailPath => _outputThumbnailPath;
  RenderDiagnosticInfo? get lastDiagnosticInfo => _lastDiagnosticInfo;
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
  bool get enableEnhanceAndDenoise => _enableEnhanceAndDenoise;
  bool get enableDeepAntiFingerprint => _enableDeepAntiFingerprint;
  bool get enableHorizontalFlip => _enableHorizontalFlip;
  bool get enableAggressiveAudio => _enableAggressiveAudio;
  bool get enableAutoTrim => _enableAutoTrim;
  bool get enableMicroTrim => _enableAutoTrim;
  bool get enableHFlip => _enableHorizontalFlip;
  bool get enableBlurredCanvas => _enableBlurredCanvas;
  bool get muteOriginalAudio => _muteOriginalAudio;
  bool get enableDynamicZoom => _enableDynamicZoom;
  bool get enableMicroOverlay => _enableMicroOverlay;
  bool get enableFrameSkip => _enableFrameSkip;
  bool get enableChromaShift => _enableChromaShift;
  double get canvasScalePercent => _canvasScalePercent;
  String get activePreset => _activePreset;
  bool get isPortrait => _isPortrait;

  TargetResolution get targetResolution => _targetResolution;
  UpscaleEngine get upscaleEngine => _upscaleEngine;
  VideoCodec get videoCodec => _videoCodec;
  String get selectedUpscaleTarget => _targetResolution.key;
  String get targetResolutionLabel => _targetResolution.label;
  String get targetResolutionDetails => _targetResolution.details;
  bool get hardwareAcceleration => _hardwareAcceleration;
  int get currentTabIndex => _currentTabIndex;

  // Actions
  void setVideoCodec(VideoCodec codec) {
    _videoCodec = codec;
    try { SettingsService.setVideoCodec(codec); } catch (_) {}
    notifyListeners();
  }

  void setTabIndex(int index) { _currentTabIndex = index; notifyListeners(); }
  void toggleRemoveMetadata(bool val) { _removeMetadata = val; notifyListeners(); }
  void toggleModifyAudio(bool val) { _modifyAudio = val; notifyListeners(); }
  void toggleModifyVisuals(bool val) { _modifyVisuals = val; notifyListeners(); }
  void toggleUpscale1080p(bool val) { _upscale1080p = val; notifyListeners(); }
  void toggleEnhanceAndDenoise(bool val) { _enableEnhanceAndDenoise = val; try { SettingsService.setEnhanceAndDenoise(val); } catch (_) {} notifyListeners(); }
  void toggleDeepAntiFingerprint(bool val) { _enableDeepAntiFingerprint = val; try { SettingsService.setDeepAntiFingerprint(val); } catch (_) {} notifyListeners(); }
  void toggleHorizontalFlip(bool val) { _enableHorizontalFlip = val; try { SettingsService.setHorizontalFlip(val); } catch (_) {} notifyListeners(); }
  void toggleHFlip(bool val) => toggleHorizontalFlip(val);
  void toggleAggressiveAudio(bool val) { _enableAggressiveAudio = val; try { SettingsService.setAggressiveAudio(val); } catch (_) {} notifyListeners(); }
  void toggleAutoTrim(bool val) { _enableAutoTrim = val; try { SettingsService.setAutoTrim(val); } catch (_) {} notifyListeners(); }
  void toggleMicroTrim(bool val) => toggleAutoTrim(val);
  void toggleBlurredCanvas(bool val) { _enableBlurredCanvas = val; notifyListeners(); }
  void toggleMuteOriginalAudio(bool val) { _muteOriginalAudio = val; notifyListeners(); }
  void toggleDynamicZoom(bool val) { _enableDynamicZoom = val; try { SettingsService.setDynamicZoom(val); } catch (_) {} notifyListeners(); }
  void toggleMicroOverlay(bool val) { _enableMicroOverlay = val; try { SettingsService.setMicroOverlay(val); } catch (_) {} notifyListeners(); }
  void toggleFrameSkip(bool val) { _enableFrameSkip = val; try { SettingsService.setFrameSkip(val); } catch (_) {} notifyListeners(); }
  void toggleChromaShift(bool val) { _enableChromaShift = val; try { SettingsService.setChromaShift(val); } catch (_) {} notifyListeners(); }
  void setCanvasScalePercent(double val) {
    _canvasScalePercent = val.clamp(0.0, 100.0);
    try { SettingsService.setCanvasScalePercent(_canvasScalePercent); } catch (_) {}
    notifyListeners();
  }

  void setUpscaleTarget(String target) {
    _targetResolution = TargetResolution.fromString(target);
    try { SettingsService.setUpscaleResolution(_targetResolution); } catch (_) {}
    notifyListeners();
  }

  void setUpscaleEngine(UpscaleEngine engine) {
    _upscaleEngine = engine;
    try { SettingsService.setUpscaleEngine(engine); } catch (_) {}
    notifyListeners();
  }

  void toggleHardwareAcceleration(bool val) {
    _hardwareAcceleration = val;
    SettingsService.setHardwareAcceleration(val);
    notifyListeners();
  }

  void updateRealtimeStats(double progress, double speed, int timeMs) {
    _realtimeProgress = progress;
    _renderingSpeed = speed > 0 ? speed : 1.0;
    _eta = Formatters.formatEta(
      totalDurationMs: _totalDurationMs,
      timeMs: timeMs,
      speed: _renderingSpeed,
      defaultEta: _eta,
    );
    notifyListeners();
  }

  void applyPreset({
    required bool removeMetadata,
    required bool modifyAudio,
    required bool modifyVisuals,
    required bool upscale1080p,
    String upscaleTarget = '1080p',
    bool enableEnhanceAndDenoise = true,
    bool enableDeepAntiFingerprint = true,
    bool enableHorizontalFlip = false,
    bool enableAggressiveAudio = false,
    bool enableAutoTrim = false,
    bool enableDynamicZoom = false,
    bool enableMicroOverlay = false,
    bool enableFrameSkip = false,
    bool enableChromaShift = false,
    String? presetName,
  }) {
    if (presetName != null) {
      _activePreset = presetName;
      try { SettingsService.setDefaultPreset(presetName); } catch (_) {}
    }
    _removeMetadata = removeMetadata;
    _modifyAudio = modifyAudio;
    _modifyVisuals = modifyVisuals;
    _upscale1080p = upscale1080p;
    _targetResolution = TargetResolution.fromString(upscaleTarget);
    _enableEnhanceAndDenoise = enableEnhanceAndDenoise;
    _enableDeepAntiFingerprint = enableDeepAntiFingerprint;
    _enableHorizontalFlip = enableHorizontalFlip;
    _enableAggressiveAudio = enableAggressiveAudio;
    _enableAutoTrim = enableAutoTrim;
    _enableDynamicZoom = enableDynamicZoom;
    _enableMicroOverlay = enableMicroOverlay;
    _enableFrameSkip = enableFrameSkip;
    _enableChromaShift = enableChromaShift;
    try {
      SettingsService.setUpscaleResolution(_targetResolution);
      SettingsService.setEnhanceAndDenoise(_enableEnhanceAndDenoise);
      SettingsService.setDeepAntiFingerprint(_enableDeepAntiFingerprint);
      SettingsService.setHorizontalFlip(_enableHorizontalFlip);
      SettingsService.setAggressiveAudio(_enableAggressiveAudio);
      SettingsService.setAutoTrim(_enableAutoTrim);
      SettingsService.setDynamicZoom(_enableDynamicZoom);
      SettingsService.setMicroOverlay(_enableMicroOverlay);
      SettingsService.setFrameSkip(_enableFrameSkip);
      SettingsService.setChromaShift(_enableChromaShift);
    } catch (_) {}
    _currentTabIndex = 0;
    notifyListeners();
  }

  void clearSelection() {
    _selectedFileName = null;
    _selectedFilePath = null;
    _thumbnailPath = null;
    _realtimeProgress = 0.0;
    _outputThumbnailPath = null;
    _lastDiagnosticInfo = null;
    notifyListeners();
  }

  void setLastProcessedResult(String outputPath) {
    _lastProcessedOutputPath = outputPath;
    notifyListeners();
    _extractOutputThumbnailAsync(outputPath);
    _inspectOutputDiagnosticsAsync(outputPath);
  }

  Future<void> _inspectOutputDiagnosticsAsync(String outputPath) async {
    try {
      final diag = await FfmpegService.inspectRenderedFile(outputPath);
      if (diag != null && _lastProcessedOutputPath == outputPath) {
        _lastDiagnosticInfo = diag;
        notifyListeners();
      }
    } catch (_) {}
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
      if (s.getType() == 'video') {
        _applyVideoStream(s);
      } else if (s.getType() == 'audio') {
        _applyAudioStream(s);
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

  void _applyAudioStream(dynamic s) {
    _audioInfo = Formatters.formatAudioInfo(s.getCodec(), s.getSampleRate());
  }

  void _applyMediaDuration(String? durationStr) {
    if (durationStr == null) return;
    final sec = double.tryParse(durationStr) ?? 0.0;
    _totalDurationMs = (sec * 1000).toInt();
    _duration = formatDuration(durationStr);
  }

  /// Formats raw seconds or duration strings to mm:ss or hh:mm:ss display.
  static String formatDuration(String? durationStr) => Formatters.formatDuration(durationStr);

  /// Formats byte count into human-readable string (B, KB, MB, GB).
  static String formatFileSize(int bytes) => Formatters.formatFileSize(bytes);
}
