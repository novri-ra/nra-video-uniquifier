import 'package:flutter/material.dart';
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
}
