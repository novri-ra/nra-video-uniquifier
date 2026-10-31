import '../utils/variation_generator.dart';
import 'settings_service.dart';

/// Pure static builders for FFmpeg video and audio filtergraph chains.
class FilterBuilders {
  static String _buildCanvasChain({
    required bool isPortrait,
    double canvasScalePercent = 95.0,
    TargetResolution targetResolution = TargetResolution.r1080p,
  }) {
    final (targetW, targetH) = canonicalDimensions(targetResolution, isPortrait: isPortrait);
    final bgDim = '$targetW:$targetH';
    final factor = (canvasScalePercent / 100.0).clamp(0.0, 1.0);
    final fgW = ((targetW * factor) / 2).floor() * 2;
    final fgH = ((targetH * factor) / 2).floor() * 2;
    final fgDim = 'w=$fgW:h=$fgH';
    return '[0:v]split=2[bg][fg];'
        '[bg]scale=$bgDim:force_original_aspect_ratio=increase,crop=$bgDim,boxblur=luma_radius=min(h\\,w)/40:luma_power=2[blurred];'
        '[fg]scale=$fgDim:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[main];'
        '[blurred][main]overlay=(W-w)/2:(H-h)/2[outv]';
  }

  static List<String> _buildPostCanvasFilters({
    required bool modifyVisuals,
    required bool enableHorizontalFlip,
    required bool enableEnhanceAndDenoise,
    bool enableDynamicZoom = false,
    bool enableMicroOverlay = false,
    bool enableFrameSkip = false,
    bool enableChromaShift = false,
    required bool isPortrait,
    required VideoVariations vars,
    TargetResolution targetResolution = TargetResolution.r1080p,
    bool upscale = false,
    UpscaleEngine upscaleEngine = UpscaleEngine.lanczos,
  }) {
    final (targetW, targetH) = canonicalDimensions(targetResolution, isPortrait: isPortrait);
    final zoomDim = '${targetW}x$targetH';
    return <String>[
      if (modifyVisuals) 'setpts=${vars.speedFactor.toStringAsFixed(4)}*PTS',
      if (enableHorizontalFlip) 'hflip',
      if (enableDynamicZoom)
        "zoompan=z='if(lte(zoom\\,1.0)\\,1.08\\,max(1.001\\,zoom-0.0015))':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=$zoomDim:fps=30",
      if (enableEnhanceAndDenoise && !upscale) 'hqdn3d=1.5:1.5:4:4',
      if (enableEnhanceAndDenoise) 'unsharp=3:3:0.6:3:3:0.0',
      if (enableChromaShift) "curves=all='0/0 0.15/0.18 0.5/0.5 0.85/0.82 1/1'",
      if (modifyVisuals)
        'eq=brightness=${vars.brightness.toStringAsFixed(4)}:contrast=${vars.contrast.toStringAsFixed(4)}:saturation=${vars.saturation.toStringAsFixed(4)}',
      if (modifyVisuals) 'noise=alls=${vars.noiseStrength}:allf=t+u',
      if (enableMicroOverlay) 'noise=alls=5:allf=t+u',
      if (enableFrameSkip) 'decimate=cycle=25',
      if (upscale)
        buildScaleFilter(targetResolution: targetResolution, isPortrait: isPortrait, upscaleEngine: upscaleEngine)
      else
        'scale=trunc(iw/2)*2:trunc(ih/2)*2',
      'format=yuv420p',
    ];
  }

  /// Determines canonical target resolution bounds (width, height).
  static (int, int) canonicalDimensions(TargetResolution res, {required bool isPortrait}) {
    switch (res) {
      case TargetResolution.r1080p:
        return isPortrait ? (1080, 1920) : (1920, 1080);
      case TargetResolution.r2k:
        return isPortrait ? (1440, 2560) : (2560, 1440);
      case TargetResolution.r4k:
        return isPortrait ? (2160, 3840) : (3840, 2160);
    }
  }

  /// Builds absolute Lanczos scale filter enforcing exact canonical pixel dimensions.
  static String buildScaleFilter({
    required TargetResolution targetResolution,
    required bool isPortrait,
    UpscaleEngine upscaleEngine = UpscaleEngine.lanczos,
  }) {
    final (w, h) = canonicalDimensions(targetResolution, isPortrait: isPortrait);
    return 'scale=w=$w:h=$h:flags=lanczos+accurate_rnd,unsharp=5:5:1.2:5:5:0.5';
  }

  static String _resolveCodecArgs(VideoCodec videoCodec, TargetResolution targetResolution) {
    final isHighRes = targetResolution == TargetResolution.r2k || targetResolution == TargetResolution.r4k;
    if (isHighRes) {
      return videoCodec == VideoCodec.h265
          ? '-c:v libx265 -preset medium -crf 17 -tag:v hvc1 -tune film'
          : '-c:v libx264 -preset medium -crf 17 -tune film';
    }
    return videoCodec == VideoCodec.h265
        ? '-c:v libx265 -preset fast -crf 26 -tag:v hvc1'
        : '-c:v libx264 -preset fast -crf 22';
  }

  static List<String> _buildSpatialCrop(VideoVariations vars, bool modifyVisuals, bool deep) {
    if (!modifyVisuals) return const [];
    if (!deep) return ['crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2'];
    final keep = (1.0 - vars.cropPercent).toStringAsFixed(4);
    final off = (vars.cropPercent / 2.0).toStringAsFixed(4);
    final rot = '${vars.rotateAngle.toStringAsFixed(3)}*PI/180';
    return [
      'crop=trunc(iw*$keep/2)*2:trunc(ih*$keep/2)*2:trunc(iw*$off/2)*2:trunc(ih*$off/2)*2',
      'rotate=$rot:ow=trunc(iw*0.96/2)*2:oh=trunc(ih*0.96/2)*2:c=none',
    ];
  }

  static List<String> _buildFiltersList({
    required bool modifyVisuals,
    required bool enableDeepAntiFingerprint,
    required bool enableHorizontalFlip,
    required bool upscale,
    required TargetResolution targetResolution,
    UpscaleEngine upscaleEngine = UpscaleEngine.lanczos,
    required bool enableEnhanceAndDenoise,
    required bool isPortrait,
    bool enableDynamicZoom = false,
    bool enableMicroOverlay = false,
    bool enableFrameSkip = false,
    bool enableChromaShift = false,
    required VideoVariations vars,
  }) {
    final (targetW, targetH) = canonicalDimensions(targetResolution, isPortrait: isPortrait);
    final zoomDim = '${targetW}x$targetH';
    return <String>[
      if (modifyVisuals) 'setpts=${vars.speedFactor.toStringAsFixed(4)}*PTS',
      ..._buildSpatialCrop(vars, modifyVisuals, enableDeepAntiFingerprint),
      if (enableHorizontalFlip) 'hflip',
      if (enableDynamicZoom)
        "zoompan=z='if(lte(zoom\\,1.0)\\,1.08\\,max(1.001\\,zoom-0.0015))':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=$zoomDim:fps=30",
      if (enableEnhanceAndDenoise && !upscale) 'hqdn3d=1.5:1.5:4:4',
      if (enableEnhanceAndDenoise) 'unsharp=3:3:0.6:3:3:0.0',
      if (enableChromaShift) "curves=all='0/0 0.15/0.18 0.5/0.5 0.85/0.82 1/1'",
      if (modifyVisuals)
        'eq=brightness=${vars.brightness.toStringAsFixed(4)}:contrast=${vars.contrast.toStringAsFixed(4)}:saturation=${vars.saturation.toStringAsFixed(4)}',
      if (modifyVisuals) 'noise=alls=${vars.noiseStrength}:allf=t+u',
      if (enableMicroOverlay) 'noise=alls=5:allf=t+u',
      if (enableFrameSkip) 'decimate=cycle=25',
      if (upscale)
        buildScaleFilter(targetResolution: targetResolution, isPortrait: isPortrait, upscaleEngine: upscaleEngine)
      else
        'scale=trunc(iw/2)*2:trunc(ih/2)*2',
      'format=yuv420p',
    ];
  }

  static String _fallbackVideoFilter({
    required bool hasVisual,
    required bool hasAudio,
    required bool modifyVisuals,
    required bool upscale,
    required TargetResolution targetResolution,
    required UpscaleEngine upscaleEngine,
    required VideoCodec videoCodec,
    required bool enableEnhanceAndDenoise,
    required bool enableHorizontalFlip,
    required bool isPortrait,
  }) {
    return buildVideoFilter(
      hasVisual: hasVisual,
      hasAudio: hasAudio,
      modifyVisuals: modifyVisuals,
      upscale: upscale,
      targetResolution: targetResolution,
      upscaleEngine: upscaleEngine,
      videoCodec: videoCodec,
      enableEnhanceAndDenoise: enableEnhanceAndDenoise,
      enableDeepAntiFingerprint: false,
      enableHorizontalFlip: enableHorizontalFlip,
      isPortrait: isPortrait,
      enableBlurredCanvas: false,
      enableDynamicZoom: false,
      enableMicroOverlay: false,
      enableFrameSkip: false,
      enableChromaShift: false,
      variations: VideoVariations.fallback,
    );
  }

  /// Builds video filtergraph chain (-vf) with PTS, spatial transforms, scaling, enhancements, and grain.
  static String buildVideoFilter({
    required bool hasVisual,
    required bool hasAudio,
    bool modifyVisuals = true,
    bool upscale = false,
    TargetResolution targetResolution = TargetResolution.r1080p,
    UpscaleEngine upscaleEngine = UpscaleEngine.lanczos,
    VideoCodec videoCodec = VideoCodec.h264,
    bool enableEnhanceAndDenoise = true,
    bool enableDeepAntiFingerprint = true,
    bool enableHorizontalFlip = false,
    bool isPortrait = false,
    bool enableBlurredCanvas = false,
    double canvasScalePercent = 95.0,
    bool enableDynamicZoom = false,
    bool enableMicroOverlay = false,
    bool enableFrameSkip = false,
    bool enableChromaShift = false,
    VideoVariations? variations,
  }) {
    if (!hasVisual) return hasAudio ? ' -c:v copy' : '';
    try {
      final vars = variations ?? (enableDeepAntiFingerprint ? VariationGenerator.generate() : VideoVariations.fallback);
      final vfString = enableBlurredCanvas
          ? '${_buildCanvasChain(isPortrait: isPortrait, canvasScalePercent: canvasScalePercent, targetResolution: targetResolution)};[outv]${_buildPostCanvasFilters(modifyVisuals: modifyVisuals, enableHorizontalFlip: enableHorizontalFlip, enableEnhanceAndDenoise: enableEnhanceAndDenoise, enableDynamicZoom: enableDynamicZoom, enableMicroOverlay: enableMicroOverlay, enableFrameSkip: enableFrameSkip, enableChromaShift: enableChromaShift, isPortrait: isPortrait, vars: vars, targetResolution: targetResolution, upscale: upscale, upscaleEngine: upscaleEngine).join(',')}'
          : _buildFiltersList(modifyVisuals: modifyVisuals, enableDeepAntiFingerprint: enableDeepAntiFingerprint, enableHorizontalFlip: enableHorizontalFlip, upscale: upscale, targetResolution: targetResolution, upscaleEngine: upscaleEngine, enableEnhanceAndDenoise: enableEnhanceAndDenoise, isPortrait: isPortrait, enableDynamicZoom: enableDynamicZoom, enableMicroOverlay: enableMicroOverlay, enableFrameSkip: enableFrameSkip, enableChromaShift: enableChromaShift, vars: vars).join(',');
      final codecArgs = _resolveCodecArgs(videoCodec, targetResolution);
      return ' -vf "$vfString" $codecArgs -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv -movflags +faststart';
    } catch (_) {
      return _fallbackVideoFilter(hasVisual: hasVisual, hasAudio: hasAudio, modifyVisuals: modifyVisuals, upscale: upscale, targetResolution: targetResolution, upscaleEngine: upscaleEngine, videoCodec: videoCodec, enableEnhanceAndDenoise: enableEnhanceAndDenoise, enableHorizontalFlip: enableHorizontalFlip, isPortrait: isPortrait);
    }
  }

  /// Builds audio filtergraph chain (-af) with tempo, EQ shaping, and optional pink noise masking.
  static String buildAudioFilter({
    required bool hasAudio,
    required bool hasVisual,
    bool enableDeepAntiFingerprint = true,
    bool enableAggressiveAudio = false,
    bool muteOriginalAudio = false,
    VideoVariations? variations,
  }) {
    if (!hasAudio) return hasVisual ? ' -c:a copy' : '';
    try {
      final vars = variations ?? (enableDeepAntiFingerprint ? VariationGenerator.generate() : VideoVariations.fallback);
      final tempo = vars.audioTempo.toStringAsFixed(6);
      if (muteOriginalAudio) {
        return ' -af "volume=0.01,atempo=$tempo" -c:a aac -b:a 128k';
      }
      if (enableAggressiveAudio) {
        return ' -af "[in]atempo=$tempo,highpass=f=60,lowpass=f=16000,equalizer=f=300:t=q:w=1.5:g=1.5,equalizer=f=3000:t=q:w=1.5:g=-1.5[a0];anoisesrc=d=7200:c=pink:a=0.003[noise];[a0][noise]amix=inputs=2:duration=first[out]" -c:a aac -b:a 192k';
      }
      if (enableDeepAntiFingerprint) {
        return ' -af "[in]atempo=$tempo,highpass=f=60,lowpass=f=16000,equalizer=f=300:t=q:w=1.5:g=1.5,equalizer=f=3000:t=q:w=1.5:g=-1.5[a0];anoisesrc=d=7200:c=pink:a=0.0015[noise];[a0][noise]amix=inputs=2:duration=first[out]" -c:a aac -b:a 192k';
      }
      return ' -af "atempo=$tempo,equalizer=f=1000:t=q:w=1:g=0.5" -c:a aac -b:a 192k';
    } catch (_) {
      return ' -af "atempo=1.025641,equalizer=f=1000:t=q:w=1:g=0.5" -c:a aac -b:a 192k';
    }
  }
}
