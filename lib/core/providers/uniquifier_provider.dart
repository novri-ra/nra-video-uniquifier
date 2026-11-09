import 'dart:async';
import 'package:flutter/material.dart';
import '../services/device_capability_service.dart';
import '../services/ffmpeg_service.dart';
import '../services/settings_service.dart';
import '../utils/formatters.dart';
import 'uniquifier/uniquifier_media_mixin.dart';
import 'uniquifier/uniquifier_modifiers_mixin.dart';
import 'uniquifier/uniquifier_preset_mixin.dart';
import 'uniquifier/uniquifier_progress_mixin.dart';

export '../models/unified_effect_preset.dart';
export 'uniquifier/uniquifier_media_mixin.dart';
export 'uniquifier/uniquifier_modifiers_mixin.dart';
export 'uniquifier/uniquifier_preset_mixin.dart';
export 'uniquifier/uniquifier_progress_mixin.dart';

/// Primary state orchestrator and facade for video uniquification workflow.
class UniquifierProvider extends ChangeNotifier
    with
        UniquifierMediaMixin,
        UniquifierModifiersMixin,
        UniquifierPresetMixin,
        UniquifierProgressMixin {
  UniquifierProvider() {
    SettingsService.upscaleResolutionNotifier.addListener(
      _onResolutionNotifierChanged,
    );
    SettingsService.upscaleEngineNotifier.addListener(
      _onUpscaleEngineNotifierChanged,
    );
    SettingsService.videoCodecNotifier.addListener(_onCodecNotifierChanged);
    SettingsService.hardwareAccelerationNotifier.addListener(
      _onHardwareAccelerationNotifierChanged,
    );
    _initResolution();
  }

  bool _isDisposed = false;
  DeviceSpecs _deviceSpecs = DeviceSpecs.defaultFallback();

  DeviceSpecs get deviceSpecs => _deviceSpecs;
  DeviceTier get deviceTier => _deviceSpecs.tier;

  @override
  void dispose() {
    _isDisposed = true;
    _previewDebounceTimer?.cancel();
    SettingsService.upscaleResolutionNotifier.removeListener(
      _onResolutionNotifierChanged,
    );
    SettingsService.upscaleEngineNotifier.removeListener(
      _onUpscaleEngineNotifierChanged,
    );
    SettingsService.videoCodecNotifier.removeListener(_onCodecNotifierChanged);
    SettingsService.hardwareAccelerationNotifier.removeListener(
      _onHardwareAccelerationNotifierChanged,
    );
    super.dispose();
  }

  void _onResolutionNotifierChanged() {
    if (targetResolution != SettingsService.upscaleResolutionNotifier.value) {
      internalSetTargetResolution(
        SettingsService.upscaleResolutionNotifier.value,
      );
      notifyListeners();
    }
  }

  void _onUpscaleEngineNotifierChanged() {
    if (upscaleEngine != SettingsService.upscaleEngineNotifier.value) {
      internalSetUpscaleEngine(SettingsService.upscaleEngineNotifier.value);
      notifyListeners();
    }
  }

  void _onCodecNotifierChanged() {
    if (videoCodec != SettingsService.videoCodecNotifier.value) {
      internalSetVideoCodec(SettingsService.videoCodecNotifier.value);
      notifyListeners();
    }
  }

  void _onHardwareAccelerationNotifierChanged() {
    if (hardwareAcceleration !=
        SettingsService.hardwareAccelerationNotifier.value) {
      internalSetHardwareAcceleration(
        SettingsService.hardwareAccelerationNotifier.value,
      );
      notifyListeners();
    }
  }

  Future<void> _initResolution() async {
    try {
      _deviceSpecs = await DeviceCapabilityService.getSpecs();
      final targetRes = await SettingsService.getUpscaleResolution();
      final engine = await SettingsService.getUpscaleEngine();
      final codec = await SettingsService.getVideoCodec();
      final hwAcc = await SettingsService.getHardwareAcceleration();
      final remMeta = await SettingsService.getRemoveMetadata();
      final modVis = await SettingsService.getModifyVisuals();
      final modAud = await SettingsService.getModifyAudio();
      final up1080 = await SettingsService.getUpscale1080p();
      final enhDen = await SettingsService.getEnhanceAndDenoise();
      final deepAnti = await SettingsService.getDeepAntiFingerprint();
      final hFlip = await SettingsService.getHorizontalFlip();
      final aggAud = await SettingsService.getAggressiveAudio();
      final autoTr = await SettingsService.getAutoTrim();
      final dynZoom = await SettingsService.getDynamicZoom();
      final microOver = await SettingsService.getMicroOverlay();
      final frameSk = await SettingsService.getFrameSkip();
      final chromaSh = await SettingsService.getChromaShift();
      final blurCanv = await SettingsService.getBlurredCanvas();
      final muteAud = await SettingsService.getMuteOriginalAudio();
      final canvScale = await SettingsService.getCanvasScalePercent();
      final thermThrot = await SettingsService.getThermalThrottle();
      final sharpLvl = await SettingsService.getSharpeningLevel();
      final satLvl = await SettingsService.getSaturationLevel();
      final rotAngle = await SettingsService.getRotateAngle();
      final tgtFps = await SettingsService.getTargetFps();

      internalSetModifiersFromSettings(
        targetResolution: targetRes,
        upscaleEngine: engine,
        videoCodec: codec,
        hardwareAcceleration: hwAcc,
        removeMetadata: remMeta,
        modifyVisuals: modVis,
        modifyAudio: modAud,
        upscale1080p: up1080,
        enableEnhanceAndDenoise: enhDen,
        enableDeepAntiFingerprint: deepAnti,
        enableHorizontalFlip: hFlip,
        enableAggressiveAudio: aggAud,
        enableAutoTrim: autoTr,
        enableDynamicZoom: dynZoom,
        enableMicroOverlay: microOver,
        enableFrameSkip: frameSk,
        enableChromaShift: chromaSh,
        enableBlurredCanvas: blurCanv,
        muteOriginalAudio: muteAud,
        canvasScalePercent: canvScale,
        thermalThrottle: thermThrot,
        sharpeningLevel: sharpLvl,
        saturationLevel: satLvl,
        rotateAngle: rotAngle,
        targetFps: tgtFps,
      );

      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e, stackTrace) {
      if (!_isDisposed) {
        debugPrint(
          '[UniquifierProvider] Initialization failed: $e\n$stackTrace',
        );
      }
    }
  }

  void updateRealtimeStats(double progress, double speed, int timeMs) {
    updateRealtimeStatsProgress(
      progress: progress,
      speed: speed,
      timeMs: timeMs,
      totalDurationMs: totalDurationMs,
    );
  }

  bool _isPreviewRendering = false;
  String? _renderedPreviewFramePath;
  Timer? _previewDebounceTimer;
  Set<UnifiedVisualEffect> _activeVisualEffects = {UnifiedVisualEffect.none};
  double _motionEchoDelay = 0.15;

  bool get isPreviewRendering => _isPreviewRendering;
  String? get renderedPreviewFramePath => _renderedPreviewFramePath;
  Set<UnifiedVisualEffect> get activeVisualEffects =>
      Set.unmodifiable(_activeVisualEffects);
  UnifiedVisualEffect get selectedVisualEffect {
    final nonNone = _activeVisualEffects.where(
      (e) => e != UnifiedVisualEffect.none,
    );
    return nonNone.isNotEmpty ? nonNone.last : UnifiedVisualEffect.none;
  }

  double get motionEchoDelay => _motionEchoDelay;

  /// Returns true if [effect] is currently active in the multi-select set.
  bool isEffectActive(UnifiedVisualEffect effect) {
    if (effect == UnifiedVisualEffect.none) {
      return _activeVisualEffects.length == 1 &&
          _activeVisualEffects.contains(UnifiedVisualEffect.none);
    }
    return _activeVisualEffects.contains(effect);
  }

  /// Toggles an effect on/off with tap-to-toggle multi-select semantics.
  /// Tapping 'None' clears all active effects and sets only 'None'.
  /// Tapping any other effect toggles it; if empty, falls back to 'None'.
  void toggleVisualEffect(UnifiedVisualEffect effect) {
    if (effect == UnifiedVisualEffect.none) {
      _activeVisualEffects = {UnifiedVisualEffect.none};
    } else {
      _activeVisualEffects.remove(UnifiedVisualEffect.none);
      if (_activeVisualEffects.contains(effect)) {
        _activeVisualEffects.remove(effect);
      } else {
        _activeVisualEffects.add(effect);
      }
      if (_activeVisualEffects.isEmpty) {
        _activeVisualEffects = {UnifiedVisualEffect.none};
      }
    }
    notifyListeners();
    requestFilteredPreviewDebounced(immediate: true);
  }

  void setSelectedVisualEffect(UnifiedVisualEffect effect) {
    if (effect == UnifiedVisualEffect.none) {
      _activeVisualEffects = {UnifiedVisualEffect.none};
    } else {
      _activeVisualEffects = {effect};
    }
    notifyListeners();
    requestFilteredPreviewDebounced(immediate: true);
  }

  void setVisualEffect(UnifiedVisualEffect effect) =>
      setSelectedVisualEffect(effect);

  void setMotionEchoDelay(double value) {
    if ((_motionEchoDelay - value).abs() < 0.001) return;
    _motionEchoDelay = value;
    notifyListeners();
    requestFilteredPreviewDebounced();
  }

  /// Debounced trigger for high-fidelity single frame preview rendering.
  /// When [immediate] is true, triggers execution immediately (e.g. on onChangeEnd).
  void requestFilteredPreviewDebounced({
    Duration debounceDuration = const Duration(milliseconds: 300),
    bool immediate = false,
    double timestampSeconds = 0.5,
    String? customFilter,
  }) {
    _previewDebounceTimer?.cancel();

    if (_isHeavyPreviewEffect()) {
      _renderedPreviewFramePath = null;
      _isPreviewRendering = false;
      notifyListeners();
      return;
    }

    final input = selectedFilePath;
    if (input == null || input.isEmpty) {
      _renderedPreviewFramePath = null;
      _isPreviewRendering = false;
      return;
    }

    if (immediate) {
      _executePreviewRender(
        inputPath: input,
        timestampSeconds: timestampSeconds,
        customFilter: customFilter,
      );
    } else {
      _previewDebounceTimer = Timer(debounceDuration, () {
        _executePreviewRender(
          inputPath: input,
          timestampSeconds: timestampSeconds,
          customFilter: customFilter,
        );
      });
    }
  }

  static const Set<UnifiedVisualEffect> _heavyPreviewEffects = {
    UnifiedVisualEffect.blurredCanvas,
    UnifiedVisualEffect.motionEcho,
    UnifiedVisualEffect.rgbSplit,
    UnifiedVisualEffect.dreamyBloom,
    UnifiedVisualEffect.dynamicGrain,
  };

  /// Heavy filtergraphs crash ARM swscale; let the Flutter simulation render.
  bool _isHeavyPreviewEffect() {
    if (enableBlurredCanvas) return true;
    return activeVisualEffects.any(_heavyPreviewEffects.contains);
  }

  Future<void> _executePreviewRender({
    required String inputPath,
    required double timestampSeconds,
    String? customFilter,
  }) async {
    if (_isDisposed) return;
    _isPreviewRendering = true;
    notifyListeners();

    try {
      final filter =
          customFilter ??
          FilterBuilders.buildPreviewFilterChain(
            cropZoomScale: cropZoomScale,
            cropAnchor: cropAnchor,
            rotateAngle: rotateAngle,
            saturationLevel: saturationLevel,
            sharpeningLevel: sharpeningLevel,
            enableBlurredCanvas: enableBlurredCanvas,
            canvasScalePercent: canvasScalePercent,
            effect: selectedVisualEffect,
            activeEffects: _activeVisualEffects,
            motionEchoDelay: _motionEchoDelay,
          );

      final resultPath = await FfmpegService.renderFilteredPreviewFrame(
        inputPath: inputPath,
        filterComplex: filter,
        timestampSeconds: timestampSeconds,
      );

      if (!_isDisposed) {
        _isPreviewRendering = false;
        if (resultPath != null) {
          _renderedPreviewFramePath = resultPath;
        }
        notifyListeners();
      }
    } catch (_) {
      if (!_isDisposed) {
        _isPreviewRendering = false;
        notifyListeners();
      }
    }
  }

  void clearSelection() {
    clearMediaSelection();
    clearProgressAndOutputs();
    _renderedPreviewFramePath = null;
    _isPreviewRendering = false;
    _previewDebounceTimer?.cancel();
    notifyListeners();
  }

  static String formatDuration(String? durationStr) =>
      Formatters.formatDuration(durationStr);
  static String formatFileSize(int bytes) => Formatters.formatFileSize(bytes);
}
