import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VideoCodec {
  h264('h264', 'H.264 (AVC - TikTok Universal)'),
  h265('h265', 'H.265 (HEVC - High Efficiency)');

  final String key;
  final String label;

  const VideoCodec(this.key, this.label);

  static VideoCodec fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'h265':
      case 'hevc':
        return VideoCodec.h265;
      case 'h264':
      case 'avc':
      default:
        return VideoCodec.h264;
    }
  }
}

enum UpscaleEngine {
  lanczos(
    'lanczos',
    'Lanczos3 (Standard)',
    'Fast mathematical 3-lobe anti-aliased scaling matrix',
  ),
  neuralAi(
    'neural_ai',
    'Real-ESRGAN AI (Neural)',
    'NCNN Vulkan AnimeVideo-v3 / Compact neural upscale',
  );

  final String key;
  final String label;
  final String details;

  const UpscaleEngine(this.key, this.label, this.details);

  static UpscaleEngine fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'neural_ai':
      case 'ai':
      case 'realesrgan':
      case 'neural':
        return UpscaleEngine.neuralAi;
      case 'lanczos':
      default:
        return UpscaleEngine.lanczos;
    }
  }
}

enum TargetResolution {
  r1080p('1080p', '1080p', '1920x1080', 1920, 1080),
  r2k('2k', '2K', '2560x1440', 2560, 1440),
  r4k('4k', '4K', '3840x2160', 3840, 2160);

  final String key;
  final String label;
  final String details;
  final int width;
  final int height;

  const TargetResolution(
    this.key,
    this.label,
    this.details,
    this.width,
    this.height,
  );

  String scaleFilter({bool isPortrait = false}) {
    final targetW = isPortrait ? height : width;
    final targetH = isPortrait ? width : height;
    return 'scale=w=$targetW:h=$targetH:flags=lanczos';
  }

  static TargetResolution fromString(String? val) {
    switch (val?.toLowerCase()) {
      case '2k':
      case '1440p':
        return TargetResolution.r2k;
      case '4k':
      case '2160p':
        return TargetResolution.r4k;
      case '1080p':
      default:
        return TargetResolution.r1080p;
    }
  }
}

class SettingsService {
  static const String keyHardwareAcceleration = 'app_hardware_acceleration';
  static const String keyDefaultPreset = 'app_default_preset';
  static const String keyCustomOutputPath = 'app_output_path';
  static const String keyUpscaleResolution = 'app_upscale_resolution';
  static const String keyUpscaleEngine = 'app_upscale_engine';
  static const String keyEnhanceAndDenoise = 'app_enhance_denoise';
  static const String keyDeepAntiFingerprint = 'app_deep_anti_fingerprint';
  static const String keyHorizontalFlip = 'app_horizontal_flip';
  static const String keyAggressiveAudio = 'app_aggressive_audio';
  static const String keyAutoTrim = 'app_auto_trim';
  static const String keyMicroTrim =
      'app_auto_trim'; // Alias for vDNA micro-head trim
  static const String keyDynamicZoom = 'app_dynamic_zoom';
  static const String keyMicroOverlay = 'app_micro_overlay';
  static const String keyFrameSkip = 'app_frame_skip';
  static const String keyChromaShift = 'app_chroma_shift';
  static const String keyCanvasScalePercent = 'app_canvas_scale_percent';
  static const String keyVideoCodec = 'app_video_codec';
  static const String keyNotificationSound = 'app_notification_sound';
  static const String keyBackgroundProcessing = 'app_background_processing';
  static const String keyRemoveMetadata = 'app_remove_metadata';
  static const String keyModifyVisuals = 'app_modify_visuals';
  static const String keyModifyAudio = 'app_modify_audio';
  static const String keyUpscale1080p = 'app_upscale_1080p';
  static const String keyBlurredCanvas = 'app_blurred_canvas';
  static const String keyMuteOriginalAudio = 'app_mute_original_audio';
  static const String keyThermalThrottle = 'app_thermal_throttle';
  static const String keySharpeningLevel = 'app_sharpening_level';
  static const String keySaturationLevel = 'app_saturation_level';
  static const String keyRotateAngle = 'app_rotate_angle';
  static const String keyTargetFps = 'app_target_fps';
  static const String keyAppLocale = 'app_language_code';
  static const String keyAppTheme = 'app_theme_mode';

  static Future<bool> _getBool(String key, bool fallback) async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? fallback;

  static Future<void> _setBool(String key, bool value) async =>
      (await SharedPreferences.getInstance()).setBool(key, value);

  static final ValueNotifier<bool> hardwareAccelerationNotifier =
      ValueNotifier<bool>(true);

  static final ValueNotifier<VideoCodec> videoCodecNotifier =
      ValueNotifier<VideoCodec>(VideoCodec.h264);

  static Future<VideoCodec> getVideoCodec() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyVideoCodec);
    final codec = VideoCodec.fromString(raw);
    videoCodecNotifier.value = codec;
    return codec;
  }

  static Future<void> setVideoCodec(VideoCodec codec) async {
    videoCodecNotifier.value = codec;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyVideoCodec, codec.key);
  }

  static Future<bool> getNotificationSound() =>
      _getBool(keyNotificationSound, true);
  static Future<void> setNotificationSound(bool enabled) =>
      _setBool(keyNotificationSound, enabled);

  static Future<bool> getBackgroundProcessing() =>
      _getBool(keyBackgroundProcessing, true);
  static Future<void> setBackgroundProcessing(bool enabled) =>
      _setBool(keyBackgroundProcessing, enabled);

  static final ValueNotifier<TargetResolution> upscaleResolutionNotifier =
      ValueNotifier<TargetResolution>(TargetResolution.r1080p);

  static Future<TargetResolution> getUpscaleResolution() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyUpscaleResolution);
    final resolution = TargetResolution.fromString(raw);
    upscaleResolutionNotifier.value = resolution;
    return resolution;
  }

  static Future<void> setUpscaleResolution(TargetResolution resolution) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUpscaleResolution, resolution.key);
    upscaleResolutionNotifier.value = resolution;
  }

  static final ValueNotifier<UpscaleEngine> upscaleEngineNotifier =
      ValueNotifier<UpscaleEngine>(UpscaleEngine.lanczos);

  static Future<UpscaleEngine> getUpscaleEngine() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyUpscaleEngine);
    final engine = UpscaleEngine.fromString(raw);
    upscaleEngineNotifier.value = engine;
    return engine;
  }

  static Future<void> setUpscaleEngine(UpscaleEngine engine) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUpscaleEngine, engine.key);
    upscaleEngineNotifier.value = engine;
  }

  static Future<bool> getRemoveMetadata() => _getBool(keyRemoveMetadata, true);
  static Future<void> setRemoveMetadata(bool enabled) =>
      _setBool(keyRemoveMetadata, enabled);

  static Future<bool> getModifyVisuals() => _getBool(keyModifyVisuals, true);
  static Future<void> setModifyVisuals(bool enabled) =>
      _setBool(keyModifyVisuals, enabled);

  static Future<bool> getModifyAudio() => _getBool(keyModifyAudio, true);
  static Future<void> setModifyAudio(bool enabled) =>
      _setBool(keyModifyAudio, enabled);

  static Future<bool> getUpscale1080p() => _getBool(keyUpscale1080p, false);
  static Future<void> setUpscale1080p(bool enabled) =>
      _setBool(keyUpscale1080p, enabled);

  static Future<bool> getBlurredCanvas() => _getBool(keyBlurredCanvas, false);
  static Future<void> setBlurredCanvas(bool enabled) =>
      _setBool(keyBlurredCanvas, enabled);

  static Future<bool> getMuteOriginalAudio() =>
      _getBool(keyMuteOriginalAudio, false);
  static Future<void> setMuteOriginalAudio(bool enabled) =>
      _setBool(keyMuteOriginalAudio, enabled);

  static Future<bool> getThermalThrottle() =>
      _getBool(keyThermalThrottle, false);
  static Future<void> setThermalThrottle(bool enabled) =>
      _setBool(keyThermalThrottle, enabled);

  static Future<double> getSharpeningLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(keySharpeningLevel) ?? 1.0;
  }

  static Future<void> setSharpeningLevel(double val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keySharpeningLevel, val);
  }

  static Future<double> getSaturationLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(keySaturationLevel) ?? 1.0;
  }

  static Future<void> setSaturationLevel(double val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keySaturationLevel, val);
  }

  static Future<double> getRotateAngle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(keyRotateAngle) ?? 0.0;
  }

  static Future<void> setRotateAngle(double val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyRotateAngle, val);
  }

  static Future<int> getTargetFps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyTargetFps) ?? 30;
  }

  static Future<void> setTargetFps(int fps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyTargetFps, fps);
  }

  static Future<String> getAppLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAppLocale) ?? 'en';
  }

  static Future<void> setAppLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAppLocale, code);
  }

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAppTheme) ?? 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAppTheme, mode);
  }

  static Future<bool> getEnhanceAndDenoise() =>
      _getBool(keyEnhanceAndDenoise, true);
  static Future<void> setEnhanceAndDenoise(bool enabled) =>
      _setBool(keyEnhanceAndDenoise, enabled);

  static Future<bool> getDeepAntiFingerprint() =>
      _getBool(keyDeepAntiFingerprint, true);
  static Future<void> setDeepAntiFingerprint(bool enabled) =>
      _setBool(keyDeepAntiFingerprint, enabled);

  static Future<bool> getHorizontalFlip() => _getBool(keyHorizontalFlip, false);
  static Future<void> setHorizontalFlip(bool enabled) =>
      _setBool(keyHorizontalFlip, enabled);

  static Future<bool> getAggressiveAudio() =>
      _getBool(keyAggressiveAudio, false);
  static Future<void> setAggressiveAudio(bool enabled) =>
      _setBool(keyAggressiveAudio, enabled);

  static Future<bool> getAutoTrim() => _getBool(keyAutoTrim, false);
  static Future<void> setAutoTrim(bool enabled) =>
      _setBool(keyAutoTrim, enabled);

  static Future<bool> getMicroTrim() => getAutoTrim();
  static Future<void> setMicroTrim(bool enabled) => setAutoTrim(enabled);

  static Future<bool> getDynamicZoom() => _getBool(keyDynamicZoom, false);
  static Future<void> setDynamicZoom(bool enabled) =>
      _setBool(keyDynamicZoom, enabled);

  static Future<bool> getMicroOverlay() => _getBool(keyMicroOverlay, false);
  static Future<void> setMicroOverlay(bool enabled) =>
      _setBool(keyMicroOverlay, enabled);

  static Future<bool> getFrameSkip() => _getBool(keyFrameSkip, false);
  static Future<void> setFrameSkip(bool enabled) =>
      _setBool(keyFrameSkip, enabled);

  static Future<bool> getChromaShift() => _getBool(keyChromaShift, false);
  static Future<void> setChromaShift(bool enabled) =>
      _setBool(keyChromaShift, enabled);

  static Future<double> getCanvasScalePercent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(keyCanvasScalePercent) ?? 95.0;
  }

  static Future<void> setCanvasScalePercent(double percent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyCanvasScalePercent, percent);
  }

  static Future<bool> getHardwareAcceleration() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(keyHardwareAcceleration) ?? true;
    hardwareAccelerationNotifier.value = enabled;
    return enabled;
  }

  static Future<void> setHardwareAcceleration(bool enabled) async {
    hardwareAccelerationNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyHardwareAcceleration, enabled);
  }

  static Future<String> getDefaultPreset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyDefaultPreset) ?? 'balanced';
  }

  static Future<void> setDefaultPreset(String preset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyDefaultPreset, preset);
  }

  static Future<String?> getCustomOutputPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyCustomOutputPath);
  }

  static Future<void> setCustomOutputPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCustomOutputPath, path);
  }

  /// Gets total size of temporary staged videos and thumbnails.
  static Future<int> getTempCacheSize([Directory? overrideDir]) async {
    int totalBytes = 0;
    try {
      final tempDir = overrideDir ?? await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final entries = tempDir.listSync(followLinks: false);
        for (final entry in entries) {
          if (entry is File) {
            final name = entry.path.split(RegExp(r'[/\\]')).last;
            if (name.startsWith('staged_') || name.startsWith('thumb_')) {
              totalBytes += entry.lengthSync();
            }
          }
        }
      }
    } catch (_) {}
    return totalBytes;
  }

  /// Purges temporary staged videos and thumbnails from sandbox cache.
  static Future<int> purgeTempCache([Directory? overrideDir]) async {
    int freedBytes = 0;
    try {
      final tempDir = overrideDir ?? await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final entries = tempDir.listSync(followLinks: false);
        for (final entry in entries) {
          if (entry is File) {
            try {
              final name = entry.path.split(RegExp(r'[/\\]')).last;
              if (name.startsWith('staged_') || name.startsWith('thumb_')) {
                final len = entry.lengthSync();
                entry.deleteSync();
                freedBytes += len;
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return freedBytes;
  }
}
