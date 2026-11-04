import 'package:flutter/material.dart';
import '../services/device_capability_service.dart';
import '../services/settings_service.dart';
import '../utils/formatters.dart';
import 'uniquifier/uniquifier_media_mixin.dart';
import 'uniquifier/uniquifier_modifiers_mixin.dart';
import 'uniquifier/uniquifier_preset_mixin.dart';
import 'uniquifier/uniquifier_progress_mixin.dart';

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
        targetFps: tgtFps,
      );

      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e, stackTrace) {
      if (!_isDisposed) {
        debugPrint('[UniquifierProvider] Inisialisasi gagal: $e\n$stackTrace');
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

  void clearSelection() {
    clearMediaSelection();
    clearProgressAndOutputs();
    notifyListeners();
  }

  static String formatDuration(String? durationStr) =>
      Formatters.formatDuration(durationStr);
  static String formatFileSize(int bytes) => Formatters.formatFileSize(bytes);
}
