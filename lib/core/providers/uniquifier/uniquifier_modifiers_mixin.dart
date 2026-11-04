import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

/// Mixin managing 20+ modifier flags, numeric sliders, and persistence sync to SettingsService.
mixin UniquifierModifiersMixin on ChangeNotifier {
  bool _removeMetadata = true, _modifyAudio = true, _modifyVisuals = true;
  bool _upscale1080p = false,
      _enableEnhanceAndDenoise = true,
      _enableDeepAntiFingerprint = true;
  bool _enableHorizontalFlip = false,
      _enableAggressiveAudio = false,
      _enableAutoTrim = false;
  bool _enableBlurredCanvas = false,
      _muteOriginalAudio = false,
      _enableDynamicZoom = false;
  bool _enableMicroOverlay = false,
      _enableFrameSkip = false,
      _enableChromaShift = false;
  double _canvasScalePercent = 95.0,
      _cropZoomScale = 1.08,
      _introTrimOffset = 0.5,
      _sharpeningLevel = 1.0,
      _saturationLevel = 1.0;
  String _cropAnchor = 'top', _activePreset = 'TikTok Fast';
  bool _thermalThrottle = false, _hardwareAcceleration = true;
  int _targetFps = 30, _currentTabIndex = 0;
  TargetResolution _targetResolution = TargetResolution.r1080p;
  UpscaleEngine _upscaleEngine = UpscaleEngine.lanczos;
  VideoCodec _videoCodec = VideoCodec.h264;

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
  double get cropZoomScale => _cropZoomScale;
  String get cropAnchor => _cropAnchor;
  double get introTrimOffset => _introTrimOffset;
  bool get thermalThrottle => _thermalThrottle;
  double get sharpeningLevel => _sharpeningLevel;
  double get saturationLevel => _saturationLevel;
  int get targetFps => _targetFps;
  String get activePreset => _activePreset;
  TargetResolution get targetResolution => _targetResolution;
  UpscaleEngine get upscaleEngine => _upscaleEngine;
  VideoCodec get videoCodec => _videoCodec;
  String get selectedUpscaleTarget => _targetResolution.key;
  String get targetResolutionLabel => _targetResolution.label;
  String get targetResolutionDetails => _targetResolution.details;
  bool get hardwareAcceleration => _hardwareAcceleration;
  int get currentTabIndex => _currentTabIndex;

  void internalSetModifiersFromSettings({
    required TargetResolution targetResolution,
    required UpscaleEngine upscaleEngine,
    required VideoCodec videoCodec,
    required bool hardwareAcceleration,
    required bool removeMetadata,
    required bool modifyVisuals,
    required bool modifyAudio,
    required bool upscale1080p,
    required bool enableEnhanceAndDenoise,
    required bool enableDeepAntiFingerprint,
    required bool enableHorizontalFlip,
    required bool enableAggressiveAudio,
    required bool enableAutoTrim,
    required bool enableDynamicZoom,
    required bool enableMicroOverlay,
    required bool enableFrameSkip,
    required bool enableChromaShift,
    required bool enableBlurredCanvas,
    required bool muteOriginalAudio,
    required double canvasScalePercent,
    required bool thermalThrottle,
    required double sharpeningLevel,
    required double saturationLevel,
    required int targetFps,
  }) {
    _targetResolution = targetResolution;
    _upscaleEngine = upscaleEngine;
    _videoCodec = videoCodec;
    _hardwareAcceleration = hardwareAcceleration;
    _removeMetadata = removeMetadata;
    _modifyVisuals = modifyVisuals;
    _modifyAudio = modifyAudio;
    _upscale1080p = upscale1080p;
    _enableEnhanceAndDenoise = enableEnhanceAndDenoise;
    _enableDeepAntiFingerprint = enableDeepAntiFingerprint;
    _enableHorizontalFlip = enableHorizontalFlip;
    _enableAggressiveAudio = enableAggressiveAudio;
    _enableAutoTrim = enableAutoTrim;
    _enableDynamicZoom = enableDynamicZoom;
    _enableMicroOverlay = enableMicroOverlay;
    _enableFrameSkip = enableFrameSkip;
    _enableChromaShift = enableChromaShift;
    _enableBlurredCanvas = enableBlurredCanvas;
    _muteOriginalAudio = muteOriginalAudio;
    _canvasScalePercent = canvasScalePercent;
    _thermalThrottle = thermalThrottle;
    _sharpeningLevel = sharpeningLevel;
    _saturationLevel = saturationLevel;
    _targetFps = targetFps;
  }

  void internalSetTargetResolution(TargetResolution resolution) {
    _targetResolution = resolution;
  }

  void internalSetUpscaleEngine(UpscaleEngine engine) {
    _upscaleEngine = engine;
  }

  void internalSetVideoCodec(VideoCodec codec) {
    _videoCodec = codec;
  }

  void internalSetHardwareAcceleration(bool val) {
    _hardwareAcceleration = val;
  }

  void setVideoCodec(VideoCodec codec) {
    _videoCodec = codec;
    try {
      SettingsService.setVideoCodec(codec);
    } catch (_) {}
    notifyListeners();
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void toggleRemoveMetadata(bool val) {
    _removeMetadata = val;
    try {
      SettingsService.setRemoveMetadata(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleModifyAudio(bool val) {
    _modifyAudio = val;
    try {
      SettingsService.setModifyAudio(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleModifyVisuals(bool val) {
    _modifyVisuals = val;
    try {
      SettingsService.setModifyVisuals(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleUpscale1080p(bool val) {
    _upscale1080p = val;
    try {
      SettingsService.setUpscale1080p(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleEnhanceAndDenoise(bool val) {
    _enableEnhanceAndDenoise = val;
    try {
      SettingsService.setEnhanceAndDenoise(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleDeepAntiFingerprint(bool val) {
    _enableDeepAntiFingerprint = val;
    try {
      SettingsService.setDeepAntiFingerprint(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleHorizontalFlip(bool val) {
    _enableHorizontalFlip = val;
    try {
      SettingsService.setHorizontalFlip(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleHFlip(bool val) => toggleHorizontalFlip(val);

  void toggleAggressiveAudio(bool val) {
    _enableAggressiveAudio = val;
    try {
      SettingsService.setAggressiveAudio(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleAutoTrim(bool val) {
    _enableAutoTrim = val;
    try {
      SettingsService.setAutoTrim(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleMicroTrim(bool val) => toggleAutoTrim(val);

  void toggleBlurredCanvas(bool val) {
    _enableBlurredCanvas = val;
    try {
      SettingsService.setBlurredCanvas(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleMuteOriginalAudio(bool val) {
    _muteOriginalAudio = val;
    try {
      SettingsService.setMuteOriginalAudio(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleDynamicZoom(bool val) {
    _enableDynamicZoom = val;
    try {
      SettingsService.setDynamicZoom(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleMicroOverlay(bool val) {
    _enableMicroOverlay = val;
    try {
      SettingsService.setMicroOverlay(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleFrameSkip(bool val) {
    _enableFrameSkip = val;
    try {
      SettingsService.setFrameSkip(val);
    } catch (_) {}
    notifyListeners();
  }

  void toggleChromaShift(bool val) {
    _enableChromaShift = val;
    try {
      SettingsService.setChromaShift(val);
    } catch (_) {}
    notifyListeners();
  }

  void setCanvasScalePercent(double val) {
    _canvasScalePercent = val.clamp(0.0, 100.0);
    try {
      SettingsService.setCanvasScalePercent(_canvasScalePercent);
    } catch (_) {}
    notifyListeners();
  }

  void toggleThermalThrottle(bool val) {
    _thermalThrottle = val;
    try {
      SettingsService.setThermalThrottle(val);
    } catch (_) {}
    notifyListeners();
  }

  void setSharpeningLevel(double val) {
    _sharpeningLevel = val.clamp(0.2, 2.0);
    try {
      SettingsService.setSharpeningLevel(_sharpeningLevel);
    } catch (_) {}
    notifyListeners();
  }

  void setSaturationLevel(double val) {
    _saturationLevel = val.clamp(0.8, 1.3);
    try {
      SettingsService.setSaturationLevel(_saturationLevel);
    } catch (_) {}
    notifyListeners();
  }

  void setTargetFps(int fps) {
    _targetFps = fps;
    try {
      SettingsService.setTargetFps(fps);
    } catch (_) {}
    notifyListeners();
  }

  void setCropZoomScale(double val) {
    _cropZoomScale = double.parse(val.clamp(1.0, 1.5).toStringAsFixed(2));
    notifyListeners();
  }

  void setCropAnchor(String anchor) {
    if (['top', 'center', 'bottom'].contains(anchor)) {
      _cropAnchor = anchor;
      notifyListeners();
    }
  }

  void setIntroTrimOffset(double val) {
    _introTrimOffset = double.parse(val.clamp(0.0, 3.0).toStringAsFixed(1));
    notifyListeners();
  }

  void setUpscaleTarget(String target) {
    _targetResolution = TargetResolution.fromString(target);
    try {
      SettingsService.setUpscaleResolution(_targetResolution);
    } catch (_) {}
    notifyListeners();
  }

  void setUpscaleEngine(UpscaleEngine engine) {
    _upscaleEngine = engine;
    try {
      SettingsService.setUpscaleEngine(engine);
    } catch (_) {}
    notifyListeners();
  }

  void toggleHardwareAcceleration(bool val) {
    _hardwareAcceleration = val;
    SettingsService.setHardwareAcceleration(val);
    notifyListeners();
  }

  void applyPresetInternal({
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
    bool enableBlurredCanvas = false,
    double canvasScalePercent = 95.0,
    bool muteOriginalAudio = false,
    int? targetFps,
    String? presetName,
  }) {
    if (presetName != null) {
      _activePreset = presetName;
      try {
        SettingsService.setDefaultPreset(presetName);
      } catch (_) {}
    }
    if (targetFps != null) {
      _targetFps = targetFps;
      try {
        SettingsService.setTargetFps(targetFps);
      } catch (_) {}
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
    _enableBlurredCanvas = enableBlurredCanvas;
    _canvasScalePercent = canvasScalePercent;
    _muteOriginalAudio = muteOriginalAudio;
    try {
      SettingsService.setRemoveMetadata(_removeMetadata);
      SettingsService.setModifyVisuals(_modifyVisuals);
      SettingsService.setModifyAudio(_modifyAudio);
      SettingsService.setUpscale1080p(_upscale1080p);
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
      SettingsService.setBlurredCanvas(_enableBlurredCanvas);
      SettingsService.setCanvasScalePercent(_canvasScalePercent);
      SettingsService.setMuteOriginalAudio(_muteOriginalAudio);
    } catch (_) {}
    notifyListeners();
  }
}
