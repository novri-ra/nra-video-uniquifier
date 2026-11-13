import '../models/unified_effect_preset.dart';
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
    double? rotateAngle,
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
      rotateAngle: rotateAngle,
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
    double? sharpeningLevel,
  }) {
    final (targetW, targetH) = canonicalDimensions(
      targetResolution,
      isPortrait: isPortrait,
    );
    final zoomDim = '${targetW}x$targetH';
    final satStr = ((saturationLevel ?? 1.0) * vars.saturation).toStringAsFixed(
      4,
    );
    final unsharpLuma = (0.6 * (sharpeningLevel ?? 1.0))
        .clamp(0.1, 2.0)
        .toStringAsFixed(2);
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
      if (enableEnhanceAndDenoise) 'unsharp=3:3:$unsharpLuma:3:3:0.0',
      if (modifyVisuals)
        'colorchannelmixer=rr=0.994:rg=0.003:rb=0.003:gg=0.995:gr=0.003:gb=0.002:bb=0.994:br=0.003:bg=0.003',
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
      'fps=$targetFps',
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
    const x264GopParams =
        '-g 36 -keyint_min 18 -sc_threshold 40 -x264-params "stitchable=1"';
    if (targetResolution == TargetResolution.r4k) {
      return videoCodec == VideoCodec.h265
          ? '-c:v libx265 -preset faster -crf 17 -tag:v hvc1 -tune film -maxrate 25M -bufsize 50M'
          : '-c:v libx264 -preset faster -crf 17 -tune film -maxrate 25M -bufsize 50M $x264GopParams';
    }
    if (targetResolution == TargetResolution.r2k) {
      return videoCodec == VideoCodec.h265
          ? '-c:v libx265 -preset faster -crf 17 -tag:v hvc1 -tune film -maxrate 20M -bufsize 40M'
          : '-c:v libx264 -preset faster -crf 17 -tune film -maxrate 20M -bufsize 40M $x264GopParams';
    }
    return videoCodec == VideoCodec.h265
        ? '-c:v libx265 -preset fast -crf 26 -tag:v hvc1'
        : '-c:v libx264 -preset fast -crf 22 $x264GopParams';
  }

  static List<String> _buildSpatialCrop(
    VideoVariations vars,
    bool modifyVisuals,
    bool deep, {
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
    double? rotateAngle,
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
      if (rotateAngle != null && rotateAngle.abs() > 0.01) {
        final rot = '${rotateAngle.toStringAsFixed(3)}*PI/180';
        list.add(
          'rotate=$rot:ow=trunc(iw*0.96/2)*2:oh=trunc(ih*0.96/2)*2:c=none',
        );
      }
      if (list.isEmpty) list.add('crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2');
      return list;
    }
    final keep = (1.0 - vars.cropPercent).toStringAsFixed(4);
    final off = (vars.cropPercent / 2.0).toStringAsFixed(4);
    final effectiveRot = (rotateAngle != null && rotateAngle.abs() > 0.01)
        ? rotateAngle
        : vars.rotateAngle;
    final rot = '${effectiveRot.toStringAsFixed(3)}*PI/180';
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
    double? sharpeningLevel,
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
    double? rotateAngle,
    Set<UnifiedVisualEffect>? activeVisualEffects,
  }) {
    final (targetW, targetH) = canonicalDimensions(
      targetResolution,
      isPortrait: isPortrait,
    );
    final zoomDim = '${targetW}x$targetH';
    final satStr = ((saturationLevel ?? 1.0) * vars.saturation).toStringAsFixed(
      4,
    );
    final unsharpLuma = (0.6 * (sharpeningLevel ?? 1.0))
        .clamp(0.1, 2.0)
        .toStringAsFixed(2);
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
        rotateAngle: rotateAngle,
      ),
      if (enableHorizontalFlip) 'hflip',
      if (enableDynamicZoom)
        "zoompan=z='1.02+0.015*sin(2*PI*it/12)':d=1:x='(iw-iw/zoom)/2*(1+0.3*sin(2*PI*it/8))':y='(ih-ih/zoom)/2*(1+0.3*cos(2*PI*it/8))':s=$zoomDim:fps=$targetFps",
      if (enableEnhanceAndDenoise && !upscale) 'hqdn3d=1.5:1.5:4:4',
      if (enableEnhanceAndDenoise) 'unsharp=3:3:$unsharpLuma:3:3:0.0',
      if (modifyVisuals)
        'colorchannelmixer=rr=0.994:rg=0.003:rb=0.003:gg=0.995:gr=0.003:gb=0.002:bb=0.994:br=0.003:bg=0.003',
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

      // --- TAMBAHKAN LOGIKA MULTI-SELECT VISUAL EFFECTS DI SINI ---
      if (activeVisualEffects != null)
        ...activeVisualEffects
            .where((effect) => effect != UnifiedVisualEffect.none)
            .map((effect) => buildUnifiedEffectFilter(effect))
            .where((filterStr) => filterStr.isNotEmpty),
      // ------------------------------------------------------------

      // 1. Paksa konversi frame rate (CFR) setelah semua transformasi
      'fps=$targetFps',

      // 2. Reset Timestamp video ke 0 (Sinkronisasi dengan audio)
      'setpts=PTS-STARTPTS',

      // 3. Tambahkan watermark kotak kecil transparan (Anti-crash, tidak butuh font)
      'drawbox=x=iw-20:y=ih-20:w=10:h=10:color=white@0.05:t=fill',
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
    double? sharpeningLevel,
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
      sharpeningLevel: sharpeningLevel,
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
    double? sharpeningLevel,
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
    double? rotateAngle,
    Set<UnifiedVisualEffect>? activeVisualEffects,
    String? lutName,
  }) {
    if (!hasVisual) return hasAudio ? ' -c:v copy' : '';
    try {
      final vars =
          variations ??
          (enableDeepAntiFingerprint
              ? VariationGenerator.generate()
              : VideoVariations.fallback);
      final vfString = enableBlurredCanvas
          ? '${_buildCanvasChain(isPortrait: isPortrait, canvasScalePercent: canvasScalePercent, targetResolution: targetResolution, vars: vars, modifyVisuals: modifyVisuals, enableDeepAntiFingerprint: enableDeepAntiFingerprint, cropZoomScale: cropZoomScale, cropAnchor: cropAnchor, rotateAngle: rotateAngle)};[outv]${_buildPostCanvasFilters(modifyVisuals: modifyVisuals, enableHorizontalFlip: enableHorizontalFlip, enableEnhanceAndDenoise: enableEnhanceAndDenoise, enableDynamicZoom: enableDynamicZoom, enableMicroOverlay: enableMicroOverlay, enableFrameSkip: enableFrameSkip, enableChromaShift: enableChromaShift, isPortrait: isPortrait, vars: vars, targetResolution: targetResolution, upscale: upscale, upscaleEngine: upscaleEngine, targetFps: targetFps, saturationLevel: saturationLevel, sharpeningLevel: sharpeningLevel).join(',')}'
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
              sharpeningLevel: sharpeningLevel,
              cropZoomScale: cropZoomScale,
              cropAnchor: cropAnchor,
              rotateAngle: rotateAngle,
              activeVisualEffects: activeVisualEffects,
            ).join(',');
      // LUT (color grading) is inserted immediately before the final pixel
      // format conversion so it operates on the finished frame.
      final lutFilter = (lutName == null || lutName.isEmpty)
          ? null
          : "lut3d='assets/luts/$lutName.cube'";
      final vfChain = lutFilter == null
          ? vfString
          : vfString.replaceFirst(
              'format=yuv420p',
              '$lutFilter,format=yuv420p',
            );
      final codecArgs = _resolveCodecArgs(videoCodec, targetResolution);
      return ' -vf "$vfChain" $codecArgs -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv -movflags +faststart';
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
        sharpeningLevel: sharpeningLevel,
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
        return ' -af "[in]$pitchChain,atempo=$tempo$phaseMod,highpass=f=60,lowpass=f=16000,equalizer=f=300:t=q:w=1.5:g=1.5,equalizer=f=3000:t=q:w=1.5:g=-1.5[a0];anoisesrc=d=7200:c=pink:a=0.003[noise];aevalsrc=exprs=0.0008*sin(2*PI*24*t)+0.0006*sin(2*PI*18200*t):d=7200:s=44100[subliminal];[noise][subliminal]amix=inputs=2:duration=first:weights=0.5 0.5[dither];[a0][dither]amix=inputs=2:duration=first:weights=1 0.001[out]" -c:a aac -b:a 192k -ar 44100 -ac 2';
      }
      if (enableDeepAntiFingerprint) {
        return ' -af "[in]$pitchChain,atempo=$tempo$phaseMod,highpass=f=60,lowpass=f=16000,equalizer=f=300:t=q:w=1.5:g=1.5,equalizer=f=3000:t=q:w=1.5:g=-1.5[a0];anoisesrc=d=7200:c=pink:a=0.0015[noise];aevalsrc=exprs=0.0005*sin(2*PI*24*t)+0.0004*sin(2*PI*18200*t):d=7200:s=44100[subliminal];[noise][subliminal]amix=inputs=2:duration=first:weights=0.5 0.5[dither];[a0][dither]amix=inputs=2:duration=first:weights=1 0.001[out]" -c:a aac -b:a 192k -ar 44100 -ac 2';
      }
      return ' -af "$pitchChain,atempo=$tempo$phaseMod,aresample=async=1:first_pts=0,aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,loudnorm=I=-16:TP=-1.5:LRA=11" -c:a aac -b:a 192k -ar 44100 -ac 2';
    } catch (_) {
      return ' -af "asetrate=44100*1.012,atempo=1/1.012,atempo=1.015,chorus=0.5:0.9:50|60:0.4|0.32:0.25|0.4:2|1.2,aresample=async=1,aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,loudnorm=I=-16:TP=-1.5:LRA=11" -c:a aac -b:a 192k -ar 44100 -ac 2';
    }
  }

  /// Builds unified visual effect filtergraph according to [effect].
  static String buildUnifiedEffectFilter(
    UnifiedVisualEffect effect, {
    double canvasScalePercent = 95.0,
    double motionEchoDelay = 0.15,
  }) {
    switch (effect) {
      case UnifiedVisualEffect.none:
        return '';
      case UnifiedVisualEffect.blurredCanvas:
        return buildBlurredCanvasEffect(canvasScalePercent: canvasScalePercent);
      case UnifiedVisualEffect.motionEcho:
        return buildMotionEchoEffect(delaySeconds: motionEchoDelay);
      case UnifiedVisualEffect.rgbSplit:
        return buildRgbSplitEffect();
      case UnifiedVisualEffect.dreamyBloom:
        return buildDreamyBloomEffect();
      case UnifiedVisualEffect.film16mm:
        return build16mmFilmToneEffect();
      case UnifiedVisualEffect.dynamicGrain:
        return buildDynamicGrainEffect();
    }
  }

  /// 1. Blurred Canvas / Dynamic Split: Kanvas latar blur dengan skala foreground (70% - 100%).
  static String buildBlurredCanvasEffect({double canvasScalePercent = 95.0}) {
    final scaleFactor = (canvasScalePercent / 100.0)
        .clamp(0.70, 1.00)
        .toStringAsFixed(2);
    return 'split=2[bg][fg];[bg]boxblur=luma_radius=min(h\\,w)/30:luma_power=2[blurred];[fg]scale=iw*$scaleFactor:ih*$scaleFactor:force_original_aspect_ratio=decrease[fg_scaled];[blurred][fg_scaled]overlay=(W-w)/2:(H-h)/2';
  }

  /// 2. Temporal Motion Echo / Clone Delay: Filter split multi-layer waktu (setpts=PTS+offset/TB, overlay/blend).
  static String buildMotionEchoEffect({
    double delaySeconds = 0.15,
    double opacity = 0.35,
  }) {
    final delay = delaySeconds.toStringAsFixed(3);
    final op = opacity.toStringAsFixed(2);
    return 'split=2[orig][delayed];[delayed]setpts=PTS+$delay/TB[echo];[orig][echo]blend=all_mode=addition:all_opacity=$op';
  }

  /// 3. RGB Temporal Split: Pemisahan kanal warna R, G, B dengan delay waktu (lutrgb, blend=addition).
  static String buildRgbSplitEffect({
    double delayGreen = 0.05,
    double delayBlue = 0.10,
  }) {
    final gDelay = delayGreen.toStringAsFixed(3);
    final bDelay = delayBlue.toStringAsFixed(3);
    return 'split=3[r][g][b];[r]lutrgb=g=0:b=0[ro];[g]lutrgb=r=0:b=0,setpts=PTS+$gDelay/TB[go];[b]lutrgb=r=0:g=0,setpts=PTS+$bDelay/TB[bo];[ro][go]blend=all_mode=addition[rg];[rg][bo]blend=all_mode=addition';
  }

  /// 4. Dreamy Bloom / Pro-Mist: Pendaran highlight lembut (gblur, blend=screen).
  static String buildDreamyBloomEffect({
    double sigma = 12.0,
    double opacity = 0.38,
  }) {
    final s = sigma.toStringAsFixed(1);
    final op = opacity.toStringAsFixed(2);
    return 'split=2[orig][glow];[glow]gblur=sigma=$s:steps=2[glow_blurred];[orig][glow_blurred]blend=all_mode=screen:all_opacity=$op';
  }

  /// 5. 16mm Nostalgia & Film Tone: Kurva warm vintage (curves, colorbalance).
  static String build16mmFilmToneEffect() {
    return 'curves=vintage,colorbalance=rs=0.08:gs=-0.04:bs=-0.08:rm=0.06:gm=0.02:bm=-0.06:rh=0.04:gh=0.0:bh=-0.06,eq=contrast=1.06:saturation=0.92';
  }

  /// 6. Dynamic Noise / Film Grain: Injeksi bintik dinamis (noise=alls=8:allf=t+u).
  static String buildDynamicGrainEffect({int strength = 8}) {
    return 'noise=alls=$strength:allf=t+u';
  }

  /// Orders [effects] according to the 4 pipeline stages:
  /// 1. Spatial Stage: Blurred Canvas (skala latar dan foreground).
  /// 2. Temporal Stage: Motion Echo atau RGB Split.
  /// 3. Tonal Stage: Dreamy Bloom atau 16mm Vintage Curve.
  /// 4. Texture Stage: Dynamic Film Grain.
  static List<UnifiedVisualEffect> orderEffectsByStage(
    Iterable<UnifiedVisualEffect> effects,
  ) {
    const stageOrder = [
      UnifiedVisualEffect.blurredCanvas,
      UnifiedVisualEffect.motionEcho,
      UnifiedVisualEffect.rgbSplit,
      UnifiedVisualEffect.dreamyBloom,
      UnifiedVisualEffect.film16mm,
      UnifiedVisualEffect.dynamicGrain,
    ];
    final active = effects.where((e) => e != UnifiedVisualEffect.none).toSet();
    final ordered = <UnifiedVisualEffect>[];
    for (final effect in stageOrder) {
      if (active.contains(effect)) {
        ordered.add(effect);
      }
    }
    return ordered;
  }

  static String _buildStageSegment(
    UnifiedVisualEffect effect, {
    String? inTag,
    String? outTag,
    double canvasScalePercent = 95.0,
    double motionEchoDelay = 0.15,
  }) {
    final inPrefix = (inTag != null && inTag.isNotEmpty) ? inTag : '';
    final outSuffix = (outTag != null && outTag.isNotEmpty) ? outTag : '';

    switch (effect) {
      case UnifiedVisualEffect.none:
        return '';
      case UnifiedVisualEffect.blurredCanvas:
        final scaleFactor = (canvasScalePercent / 100.0)
            .clamp(0.70, 1.00)
            .toStringAsFixed(2);
        return '${inPrefix}split=2[bc_bg][bc_fg];'
            '[bc_bg]boxblur=luma_radius=min(h\\,w)/30:luma_power=2[bc_bl];'
            '[bc_fg]scale=iw*$scaleFactor:ih*$scaleFactor:force_original_aspect_ratio=decrease[bc_sc];'
            '[bc_bl][bc_sc]overlay=(W-w)/2:(H-h)/2$outSuffix';
      case UnifiedVisualEffect.motionEcho:
        final delay = motionEchoDelay.toStringAsFixed(3);
        const op = '0.35';
        return '${inPrefix}split=2[me_orig][me_del];'
            '[me_del]setpts=PTS+$delay/TB[me_ec];'
            '[me_orig][me_ec]blend=all_mode=addition:all_opacity=$op$outSuffix';
      case UnifiedVisualEffect.rgbSplit:
        const gDelay = '0.050';
        const bDelay = '0.100';
        return '${inPrefix}split=3[rs_r][rs_g][rs_b];'
            '[rs_r]lutrgb=g=0:b=0[rs_ro];'
            '[rs_g]lutrgb=r=0:b=0,setpts=PTS+$gDelay/TB[rs_go];'
            '[rs_b]lutrgb=r=0:g=0,setpts=PTS+$bDelay/TB[rs_bo];'
            '[rs_ro][rs_go]blend=all_mode=addition[rs_rg];'
            '[rs_rg][rs_bo]blend=all_mode=addition$outSuffix';
      case UnifiedVisualEffect.dreamyBloom:
        const s = '12.0';
        const op = '0.38';
        return '${inPrefix}split=2[db_orig][db_glow];'
            '[db_glow]gblur=sigma=$s:steps=2[db_bl];'
            '[db_orig][db_bl]blend=all_mode=screen:all_opacity=$op$outSuffix';
      case UnifiedVisualEffect.film16mm:
        return '${inPrefix}curves=vintage,colorbalance=rs=0.08:gs=-0.04:bs=-0.08:rm=0.06:gm=0.02:bm=-0.06:rh=0.04:gh=0.0:bh=-0.06,eq=contrast=1.06:saturation=0.92$outSuffix';
      case UnifiedVisualEffect.dynamicGrain:
        return '${inPrefix}noise=alls=8:allf=t+u$outSuffix';
    }
  }

  /// Builds lightweight preview filter chain combining active parameters.
  static String buildPreviewFilterChain({
    double cropZoomScale = 1.0,
    String cropAnchor = 'center',
    double rotateAngle = 0.0,
    double saturationLevel = 1.0,
    double sharpeningLevel = 1.0,
    bool enableBlurredCanvas = false,
    double canvasScalePercent = 95.0,
    UnifiedVisualEffect effect = UnifiedVisualEffect.none,
    Set<UnifiedVisualEffect>? activeEffects,
    double motionEchoDelay = 0.15,
  }) {
    final filters = <String>[];

    // 1. Spatial Transforms
    if (cropZoomScale > 1.001) {
      final yCrop = cropAnchor == 'top'
          ? '0'
          : cropAnchor == 'bottom'
          ? 'ih-ih/$cropZoomScale'
          : '(ih-ih/$cropZoomScale)/2';
      filters.add(
        'crop=iw/$cropZoomScale:ih/$cropZoomScale:(iw-iw/$cropZoomScale)/2:$yCrop',
      );
    }
    if (rotateAngle.abs() > 0.01) {
      final rad = (rotateAngle * 3.141592653589793 / 180.0).toStringAsFixed(5);
      filters.add('rotate=$rad:ow=rotw($rad):oh=roth($rad):c=none');
    }

    // 2. Color and Detail
    if ((sharpeningLevel - 1.0).abs() > 0.05) {
      final luma = (0.6 * sharpeningLevel).clamp(0.1, 2.0).toStringAsFixed(2);
      filters.add('unsharp=3:3:$luma:3:3:0.0');
    }
    if ((saturationLevel - 1.0).abs() > 0.01) {
      filters.add('eq=saturation=${saturationLevel.toStringAsFixed(3)}');
    }

    // 3. Multi-Stage Effect Suite
    final Set<UnifiedVisualEffect> effectiveSet;
    if (activeEffects != null && activeEffects.isNotEmpty) {
      effectiveSet = activeEffects.toSet();
    } else if (effect != UnifiedVisualEffect.none) {
      effectiveSet = {effect};
    } else if (enableBlurredCanvas) {
      effectiveSet = {UnifiedVisualEffect.blurredCanvas};
    } else {
      effectiveSet = {UnifiedVisualEffect.none};
    }

    final orderedEffects = orderEffectsByStage(effectiveSet);

    if (orderedEffects.isEmpty) {
      return filters.join(',');
    }

    if (orderedEffects.length == 1) {
      final singleEffect = orderedEffects.first;
      final effectFilter = buildUnifiedEffectFilter(
        singleEffect,
        canvasScalePercent: canvasScalePercent,
        motionEchoDelay: motionEchoDelay,
      );
      if (effectFilter.isNotEmpty) {
        if (filters.isEmpty) {
          return effectFilter;
        } else {
          return '${filters.join(',')},$effectFilter';
        }
      }
      return filters.join(',');
    }

    // Multiple active effects: chain stage by stage with distinct stream labels
    final segments = <String>[];
    String? currentTag;

    if (filters.isNotEmpty) {
      segments.add('${filters.join(',')}[v0]');
      currentTag = '[v0]';
    }

    for (int i = 0; i < orderedEffects.length; i++) {
      final isLast = (i == orderedEffects.length - 1);
      final nextTag = isLast
          ? null
          : '[v${filters.isNotEmpty ? i + 1 : i + 1}]';
      final seg = _buildStageSegment(
        orderedEffects[i],
        inTag: currentTag,
        outTag: nextTag,
        canvasScalePercent: canvasScalePercent,
        motionEchoDelay: motionEchoDelay,
      );
      if (seg.isNotEmpty) {
        segments.add(seg);
        currentTag = nextTag;
      }
    }

    return segments.join(';');
  }
}
