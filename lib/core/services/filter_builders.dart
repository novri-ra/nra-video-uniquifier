import '../utils/variation_generator.dart';
import 'settings_service.dart';

/// Pure static builders for FFmpeg video and audio filtergraph chains.
class FilterBuilders {
  static String _buildCanvasChain({
    required bool isPortrait,
    double canvasScalePercent = 95.0,
    TargetResolution targetResolution = TargetResolution.r1080p,
    required VideoVariations vars,
    bool modifyVisuals = true,
    bool enableDeepAntiFingerprint = true,
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
  }) {
    final (targetW, targetH) = canonicalDimensions(
      targetResolution,
      isPortrait: isPortrait,
    );
    final bgDim = '$targetW:$targetH';
    final factor = (canvasScalePercent / 100.0).clamp(0.0, 1.0);
    final fgW = ((targetW * factor) / 2).floor() * 2;
    final fgH = ((targetH * factor) / 2).floor() * 2;
    final fgDim = 'w=$fgW:h=$fgH';
    final spatialList = _buildSpatialCrop(
      vars,
      modifyVisuals,
      enableDeepAntiFingerprint,
      cropZoomScale: cropZoomScale,
      cropAnchor: cropAnchor,
    );
    final fgSpatial = spatialList.isNotEmpty ? '${spatialList.join(',')},' : '';
    return '[0:v]split=2[bg][fg];'
        '[bg]scale=$bgDim:force_original_aspect_ratio=increase,crop=$bgDim,boxblur=luma_radius=min(h\\,w)/40:luma_power=2[blurred];'
        '[fg]${fgSpatial}scale=$fgDim:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[main];'
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
    int targetFps = 30,
    double? saturationLevel,
  }) {
    final (targetW, targetH) = canonicalDimensions(
      targetResolution,
      isPortrait: isPortrait,
    );
    final zoomDim = '${targetW}x$targetH';
    final satStr = ((saturationLevel ?? 1.0) * vars.saturation).toStringAsFixed(
      4,
    );
    final isHighRes =
        targetResolution == TargetResolution.r2k ||
        targetResolution == TargetResolution.r4k;
    final allowFrameSkip = enableFrameSkip && !isHighRes;
    return <String>[
      if (modifyVisuals)
        'setpts=(1/${vars.speedFactor.toStringAsFixed(4)})*PTS',
      if (enableHorizontalFlip) 'hflip',
      if (enableDynamicZoom)
        "zoompan=z='1.02+0.015*sin(2*PI*it/12)':d=1:x='(iw-iw/zoom)/2*(1+0.3*sin(2*PI*it/8))':y='(ih-ih/zoom)/2*(1+0.3*cos(2*PI*it/8))':s=$zoomDim:fps=$targetFps",
      if (enableEnhanceAndDenoise && !upscale) 'hqdn3d=1.5:1.5:4:4',
      if (enableEnhanceAndDenoise) 'unsharp=3:3:0.6:3:3:0.0',
      if (enableChromaShift) 'curves=${vars.curves}',
      if (modifyVisuals) 'eq=gamma=1.015:contrast=1.02:saturation=$satStr',
      if (modifyVisuals) 'noise=alls=${vars.noiseStrength}:allf=t+u',
      if (enableMicroOverlay) 'noise=alls=5:allf=t+u',
      if (allowFrameSkip) 'decimate=cycle=25',
      if (upscale)
        buildScaleFilter(
          targetResolution: targetResolution,
          isPortrait: isPortrait,
          upscaleEngine: upscaleEngine,
        )
      else
        'scale=trunc(iw/2)*2:trunc(ih/2)*2',
      'setpts=PTS-STARTPTS',
      'format=yuv420p',
    ];
  }

  /// Determines canonical target resolution bounds (width, height).
  static (int, int) canonicalDimensions(
    TargetResolution res, {
    required bool isPortrait,
  }) {
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
    final (w, h) = canonicalDimensions(
      targetResolution,
      isPortrait: isPortrait,
    );
    return 'scale=w=$w:h=$h:flags=lanczos+accurate_rnd,unsharp=5:5:1.2:5:5:0.5';
  }

  static String _resolveCodecArgs(
    VideoCodec videoCodec,
    TargetResolution targetResolution,
  ) {
    if (targetResolution == TargetResolution.r4k) {
      return videoCodec == VideoCodec.h265
          ? '-c:v libx265 -preset faster -crf 17 -tag:v hvc1 -tune film -maxrate 25M -bufsize 50M'
          : '-c:v libx264 -preset faster -crf 17 -tune film -maxrate 25M -bufsize 50M -x264-params "stitchable=1"';
    }
    if (targetResolution == TargetResolution.r2k) {
      return videoCodec == VideoCodec.h265
          ? '-c:v libx265 -preset faster -crf 17 -tag:v hvc1 -tune film -maxrate 20M -bufsize 40M'
          : '-c:v libx264 -preset faster -crf 17 -tune film -maxrate 20M -bufsize 40M -x264-params "stitchable=1"';
    }
    return videoCodec == VideoCodec.h265
        ? '-c:v libx265 -preset fast -crf 26 -tag:v hvc1'
        : '-c:v libx264 -preset fast -crf 22 -x264-params "stitchable=1"';
  }

  static List<String> _buildSpatialCrop(
    VideoVariations vars,
    bool modifyVisuals,
    bool deep, {
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
  }) {
    if (!modifyVisuals) return const [];
    final List<String> list = [];
    if (cropZoomScale > 1.01) {
      final z = cropZoomScale.toStringAsFixed(2);
      final yExpr = cropAnchor == 'top'
          ? '0'
          : (cropAnchor == 'bottom' ? '(ih-oh)' : '(ih-oh)/2');
      list.add(
        'crop=w=trunc(iw/$z/2)*2:h=trunc(ih/$z/2)*2:x=trunc((iw-ow)/4)*2:y=trunc($yExpr/2)*2',
      );
    }
    if (!deep) {
      if (list.isEmpty) list.add('crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2');
      return list;
    }
    final keep = (1.0 - vars.cropPercent).toStringAsFixed(4);
    final off = (vars.cropPercent / 2.0).toStringAsFixed(4);
    final rot = '${vars.rotateAngle.toStringAsFixed(3)}*PI/180';
    list.addAll([
      'crop=trunc(iw*$keep/2)*2:trunc(ih*$keep/2)*2:trunc(iw*$off/2)*2:trunc(ih*$off/2)*2',
      'rotate=$rot:ow=trunc(iw*0.96/2)*2:oh=trunc(ih*0.96/2)*2:c=none',
    ]);
    return list;
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
    int targetFps = 30,
    double? saturationLevel,
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
  }) {
    final (targetW, targetH) = canonicalDimensions(
      targetResolution,
      isPortrait: isPortrait,
    );
    final zoomDim = '${targetW}x$targetH';
    final satStr = ((saturationLevel ?? 1.0) * vars.saturation).toStringAsFixed(
      4,
    );
    final isHighRes =
        targetResolution == TargetResolution.r2k ||
        targetResolution == TargetResolution.r4k;
    final allowFrameSkip = enableFrameSkip && !isHighRes;
    return <String>[
      if (modifyVisuals)
        'setpts=(1/${vars.speedFactor.toStringAsFixed(4)})*PTS',
      ..._buildSpatialCrop(
        vars,
        modifyVisuals,
        enableDeepAntiFingerprint,
        cropZoomScale: cropZoomScale,
        cropAnchor: cropAnchor,
      ),
      if (enableHorizontalFlip) 'hflip',
      if (enableDynamicZoom)
        "zoompan=z='1.02+0.015*sin(2*PI*it/12)':d=1:x='(iw-iw/zoom)/2*(1+0.3*sin(2*PI*it/8))':y='(ih-ih/zoom)/2*(1+0.3*cos(2*PI*it/8))':s=$zoomDim:fps=$targetFps",
      if (enableEnhanceAndDenoise && !upscale) 'hqdn3d=1.5:1.5:4:4',
      if (enableEnhanceAndDenoise) 'unsharp=3:3:0.6:3:3:0.0',
      if (enableChromaShift) 'curves=${vars.curves}',
      if (modifyVisuals) 'eq=gamma=1.015:contrast=1.02:saturation=$satStr',
      if (modifyVisuals) 'noise=alls=${vars.noiseStrength}:allf=t+u',
      if (enableMicroOverlay) 'noise=alls=5:allf=t+u',
      if (allowFrameSkip) 'decimate=cycle=25',
      if (upscale)
        buildScaleFilter(
          targetResolution: targetResolution,
          isPortrait: isPortrait,
          upscaleEngine: upscaleEngine,
        )
      else
        'scale=trunc(iw/2)*2:trunc(ih/2)*2',
      'setpts=PTS-STARTPTS',
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
    int targetFps = 30,
    double? saturationLevel,
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
      targetFps: targetFps,
      saturationLevel: saturationLevel,
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
    int targetFps = 30,
    double? saturationLevel,
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
  }) {
    if (!hasVisual) return hasAudio ? ' -c:v copy' : '';
    try {
      final vars =
          variations ??
          (enableDeepAntiFingerprint
              ? VariationGenerator.generate()
              : VideoVariations.fallback);
      final vfString = enableBlurredCanvas
          ? '${_buildCanvasChain(isPortrait: isPortrait, canvasScalePercent: canvasScalePercent, targetResolution: targetResolution, vars: vars, modifyVisuals: modifyVisuals, enableDeepAntiFingerprint: enableDeepAntiFingerprint, cropZoomScale: cropZoomScale, cropAnchor: cropAnchor)};[outv]${_buildPostCanvasFilters(modifyVisuals: modifyVisuals, enableHorizontalFlip: enableHorizontalFlip, enableEnhanceAndDenoise: enableEnhanceAndDenoise, enableDynamicZoom: enableDynamicZoom, enableMicroOverlay: enableMicroOverlay, enableFrameSkip: enableFrameSkip, enableChromaShift: enableChromaShift, isPortrait: isPortrait, vars: vars, targetResolution: targetResolution, upscale: upscale, upscaleEngine: upscaleEngine, targetFps: targetFps, saturationLevel: saturationLevel).join(',')}'
          : _buildFiltersList(
              modifyVisuals: modifyVisuals,
              enableDeepAntiFingerprint: enableDeepAntiFingerprint,
              enableHorizontalFlip: enableHorizontalFlip,
              upscale: upscale,
              targetResolution: targetResolution,
              upscaleEngine: upscaleEngine,
              enableEnhanceAndDenoise: enableEnhanceAndDenoise,
              isPortrait: isPortrait,
              enableDynamicZoom: enableDynamicZoom,
              enableMicroOverlay: enableMicroOverlay,
              enableFrameSkip: enableFrameSkip,
              enableChromaShift: enableChromaShift,
              vars: vars,
              targetFps: targetFps,
              saturationLevel: saturationLevel,
              cropZoomScale: cropZoomScale,
              cropAnchor: cropAnchor,
            ).join(',');
      final codecArgs = _resolveCodecArgs(videoCodec, targetResolution);
      return ' -vf "$vfString" $codecArgs -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv -movflags +faststart';
    } catch (_) {
      return _fallbackVideoFilter(
        hasVisual: hasVisual,
        hasAudio: hasAudio,
        modifyVisuals: modifyVisuals,
        upscale: upscale,
        targetResolution: targetResolution,
        upscaleEngine: upscaleEngine,
        videoCodec: videoCodec,
        enableEnhanceAndDenoise: enableEnhanceAndDenoise,
        enableHorizontalFlip: enableHorizontalFlip,
        isPortrait: isPortrait,
        targetFps: targetFps,
        saturationLevel: saturationLevel,
      );
    }
  }

  /// Builds audio filtergraph chain (-af) with tempo, EQ shaping, and optional pink noise masking.
  static String buildAudioFilter({
    required bool hasAudio,
    required bool hasVisual,
    bool modifyAudio = true,
    bool enableDeepAntiFingerprint = true,
    bool enableAggressiveAudio = false,
    bool muteOriginalAudio = false,
    VideoVariations? variations,
  }) {
    if (!hasAudio) return hasVisual ? ' -c:a copy' : '';
    try {
      final vars =
          variations ??
          (enableDeepAntiFingerprint
              ? VariationGenerator.generate()
              : VideoVariations.fallback);
      final tempo = vars.audioTempo.toStringAsFixed(4);
      final pitchStr = vars.pitchFactor.toStringAsFixed(3);
      final pitchChain = 'asetrate=44100*$pitchStr,atempo=1/$pitchStr';
      const phaseChorus = 'chorus=0.5:0.9:50|60:0.4|0.32:0.25|0.4:2|1.2';
      final phaseMod = modifyAudio ? ',$phaseChorus' : '';

      if (muteOriginalAudio) {
        return ' -af "volume=0.01,$pitchChain,atempo=$tempo" -c:a aac -b:a 192k -ar 44100 -ac 2';
      }
      if (enableAggressiveAudio) {
        return ' -af "[in]$pitchChain,atempo=$tempo$phaseMod,highpass=f=60,lowpass=f=16000,equalizer=f=300:t=q:w=1.5:g=1.5,equalizer=f=3000:t=q:w=1.5:g=-1.5[a0];anoisesrc=d=7200:c=pink:a=0.003[noise];[a0][noise]amix=inputs=2:duration=first[out]" -c:a aac -b:a 192k -ar 44100 -ac 2';
      }
      if (enableDeepAntiFingerprint) {
        return ' -af "[in]$pitchChain,atempo=$tempo$phaseMod,highpass=f=60,lowpass=f=16000,equalizer=f=300:t=q:w=1.5:g=1.5,equalizer=f=3000:t=q:w=1.5:g=-1.5[a0];anoisesrc=d=7200:c=pink:a=0.0015[noise];[a0][noise]amix=inputs=2:duration=first[out]" -c:a aac -b:a 192k -ar 44100 -ac 2';
      }
      return ' -af "$pitchChain,atempo=$tempo$phaseMod,aresample=async=1,aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,loudnorm=I=-16:TP=-1.5:LRA=11" -c:a aac -b:a 192k -ar 44100 -ac 2';
    } catch (_) {
      return ' -af "asetrate=44100*1.012,atempo=1/1.012,atempo=1.015,chorus=0.5:0.9:50|60:0.4|0.32:0.25|0.4:2|1.2,aresample=async=1,aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,loudnorm=I=-16:TP=-1.5:LRA=11" -c:a aac -b:a 192k -ar 44100 -ac 2';
    }
  }
}
