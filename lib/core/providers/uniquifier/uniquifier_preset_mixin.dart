import 'package:flutter/material.dart';
import '../../services/settings_service.dart';
import 'uniquifier_modifiers_mixin.dart';

/// Mixin managing presets application and bulk configuration updates.
mixin UniquifierPresetMixin on ChangeNotifier, UniquifierModifiersMixin {
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
    bool enableBlurredCanvas = false,
    double canvasScalePercent = 95.0,
    bool muteOriginalAudio = false,
    int? targetFps,
    String? presetName,
  }) {
    applyPresetInternal(
      removeMetadata: removeMetadata,
      modifyAudio: modifyAudio,
      modifyVisuals: modifyVisuals,
      upscale1080p: upscale1080p,
      upscaleTarget: upscaleTarget,
      enableEnhanceAndDenoise: enableEnhanceAndDenoise,
      enableDeepAntiFingerprint: enableDeepAntiFingerprint,
      enableHorizontalFlip: enableHorizontalFlip,
      enableAggressiveAudio: enableAggressiveAudio,
      enableAutoTrim: enableAutoTrim,
      enableDynamicZoom: enableDynamicZoom,
      enableMicroOverlay: enableMicroOverlay,
      enableFrameSkip: enableFrameSkip,
      enableChromaShift: enableChromaShift,
      enableBlurredCanvas: enableBlurredCanvas,
      canvasScalePercent: canvasScalePercent,
      muteOriginalAudio: muteOriginalAudio,
      targetFps: targetFps,
      presetName: presetName,
    );
  }

  /// Captures all current modifier states and persists them as a custom user preset.
  Future<void> saveCurrentAsPreset(String name) async {
    final config = <String, dynamic>{
      'removeMetadata': removeMetadata,
      'modifyAudio': modifyAudio,
      'modifyVisuals': modifyVisuals,
      'upscale1080p': upscale1080p,
      'targetResolution': targetResolution.key,
      'upscaleEngine': upscaleEngine.key,
      'videoCodec': videoCodec.key,
      'enableEnhanceAndDenoise': enableEnhanceAndDenoise,
      'enableDeepAntiFingerprint': enableDeepAntiFingerprint,
      'enableHorizontalFlip': enableHorizontalFlip,
      'enableAggressiveAudio': enableAggressiveAudio,
      'enableAutoTrim': enableAutoTrim,
      'enableDynamicZoom': enableDynamicZoom,
      'enableMicroOverlay': enableMicroOverlay,
      'enableFrameSkip': enableFrameSkip,
      'enableChromaShift': enableChromaShift,
      'enableBlurredCanvas': enableBlurredCanvas,
      'muteOriginalAudio': muteOriginalAudio,
      'canvasScalePercent': canvasScalePercent,
      'thermalThrottle': thermalThrottle,
      'sharpeningLevel': sharpeningLevel,
      'saturationLevel': saturationLevel,
      'rotateAngle': rotateAngle,
      'targetFps': targetFps,
      'lutName': lutName,
    };
    await SettingsService.saveCustomPreset(name, config);
    notifyListeners();
  }

  /// Loads and applies a stored custom preset by name.
  Future<void> loadCustomPreset(String name) async {
    final presets = await SettingsService.getCustomPresets();
    final match = presets.firstWhere(
      (item) => item['name'] == name,
      orElse: () => <String, dynamic>{},
    );
    if (match.isEmpty) return;

    final config = match['config'] is Map
        ? Map<String, dynamic>.from(match['config'] as Map)
        : match;

    if (config['removeMetadata'] != null) {
      toggleRemoveMetadata(config['removeMetadata'] as bool);
    }
    if (config['modifyAudio'] != null) {
      toggleModifyAudio(config['modifyAudio'] as bool);
    }
    if (config['modifyVisuals'] != null) {
      toggleModifyVisuals(config['modifyVisuals'] as bool);
    }
    if (config['upscale1080p'] != null) {
      toggleUpscale1080p(config['upscale1080p'] as bool);
    }
    if (config['targetResolution'] != null) {
      setUpscaleTarget(config['targetResolution'] as String);
    }
    if (config['upscaleEngine'] != null) {
      setUpscaleEngine(
        UpscaleEngine.fromString(config['upscaleEngine'] as String),
      );
    }
    if (config['videoCodec'] != null) {
      setVideoCodec(VideoCodec.fromString(config['videoCodec'] as String));
    }
    if (config['enableEnhanceAndDenoise'] != null) {
      toggleEnhanceAndDenoise(config['enableEnhanceAndDenoise'] as bool);
    }
    if (config['enableDeepAntiFingerprint'] != null) {
      toggleDeepAntiFingerprint(config['enableDeepAntiFingerprint'] as bool);
    }
    if (config['enableHorizontalFlip'] != null) {
      toggleHorizontalFlip(config['enableHorizontalFlip'] as bool);
    }
    if (config['enableAggressiveAudio'] != null) {
      toggleAggressiveAudio(config['enableAggressiveAudio'] as bool);
    }
    if (config['enableAutoTrim'] != null) {
      toggleAutoTrim(config['enableAutoTrim'] as bool);
    }
    if (config['enableDynamicZoom'] != null) {
      toggleDynamicZoom(config['enableDynamicZoom'] as bool);
    }
    if (config['enableMicroOverlay'] != null) {
      toggleMicroOverlay(config['enableMicroOverlay'] as bool);
    }
    if (config['enableFrameSkip'] != null) {
      toggleFrameSkip(config['enableFrameSkip'] as bool);
    }
    if (config['enableChromaShift'] != null) {
      toggleChromaShift(config['enableChromaShift'] as bool);
    }
    if (config['enableBlurredCanvas'] != null) {
      toggleBlurredCanvas(config['enableBlurredCanvas'] as bool);
    }
    if (config['muteOriginalAudio'] != null) {
      toggleMuteOriginalAudio(config['muteOriginalAudio'] as bool);
    }
    if (config['canvasScalePercent'] != null) {
      setCanvasScalePercent((config['canvasScalePercent'] as num).toDouble());
    }
    if (config['thermalThrottle'] != null) {
      toggleThermalThrottle(config['thermalThrottle'] as bool);
    }
    if (config['sharpeningLevel'] != null) {
      setSharpeningLevel((config['sharpeningLevel'] as num).toDouble());
    }
    if (config['saturationLevel'] != null) {
      setSaturationLevel((config['saturationLevel'] as num).toDouble());
    }
    if (config['rotateAngle'] != null) {
      setRotateAngle((config['rotateAngle'] as num).toDouble());
    }
    if (config['targetFps'] != null) {
      setTargetFps((config['targetFps'] as num).toInt());
    }
    if (config['lutName'] != null) {
      lutName = config['lutName'] as String;
    }

    applyPresetInternal(
      removeMetadata: config['removeMetadata'] as bool? ?? removeMetadata,
      modifyAudio: config['modifyAudio'] as bool? ?? modifyAudio,
      modifyVisuals: config['modifyVisuals'] as bool? ?? modifyVisuals,
      upscale1080p: config['upscale1080p'] as bool? ?? upscale1080p,
      upscaleTarget:
          config['targetResolution'] as String? ?? targetResolution.key,
      enableEnhanceAndDenoise:
          config['enableEnhanceAndDenoise'] as bool? ??
          enableEnhanceAndDenoise,
      enableDeepAntiFingerprint:
          config['enableDeepAntiFingerprint'] as bool? ??
          enableDeepAntiFingerprint,
      enableHorizontalFlip:
          config['enableHorizontalFlip'] as bool? ?? enableHorizontalFlip,
      enableAggressiveAudio:
          config['enableAggressiveAudio'] as bool? ?? enableAggressiveAudio,
      enableAutoTrim: config['enableAutoTrim'] as bool? ?? enableAutoTrim,
      enableDynamicZoom:
          config['enableDynamicZoom'] as bool? ?? enableDynamicZoom,
      enableMicroOverlay:
          config['enableMicroOverlay'] as bool? ?? enableMicroOverlay,
      enableFrameSkip: config['enableFrameSkip'] as bool? ?? enableFrameSkip,
      enableChromaShift:
          config['enableChromaShift'] as bool? ?? enableChromaShift,
      enableBlurredCanvas:
          config['enableBlurredCanvas'] as bool? ?? enableBlurredCanvas,
      canvasScalePercent:
          (config['canvasScalePercent'] as num?)?.toDouble() ??
          canvasScalePercent,
      muteOriginalAudio:
          config['muteOriginalAudio'] as bool? ?? muteOriginalAudio,
      targetFps: (config['targetFps'] as num?)?.toInt() ?? targetFps,
      presetName: name,
    );

    notifyListeners();
  }
}
