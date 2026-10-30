import '../utils/variation_generator.dart';
import 'settings_service.dart';

/// Pure static builders for FFmpeg video and audio filtergraph chains.
class FilterBuilders {
  static List<String> _buildFiltersList({
    required bool modifyVisuals,
    required bool enableDeepAntiFingerprint,
    required bool enableHorizontalFlip,
    required bool upscale,
    required TargetResolution targetResolution,
    required bool enableEnhanceAndDenoise,
    required bool isPortrait,
    required VideoVariations vars,
  }) {
    final keep = (1.0 - vars.cropPercent).toStringAsFixed(4);
    final off = (vars.cropPercent / 2.0).toStringAsFixed(4);
    final rot = '${vars.rotateAngle.toStringAsFixed(3)}*PI/180';
    return <String>[
      if (modifyVisuals) 'setpts=${vars.speedFactor.toStringAsFixed(4)}*PTS',
      if (modifyVisuals && enableDeepAntiFingerprint) ...[
        'crop=trunc(iw*$keep/2)*2:trunc(ih*$keep/2)*2:trunc(iw*$off/2)*2:trunc(ih*$off/2)*2',
        'rotate=$rot:ow=trunc(rotw($rot)/2)*2:oh=trunc(roth($rot)/2)*2:fillcolor=black',
      ] else if (modifyVisuals)
        'crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2',
      if (enableHorizontalFlip) 'hflip',
      if (upscale) targetResolution.scaleFilter(isPortrait: isPortrait),
      if (enableEnhanceAndDenoise) ...['hqdn3d=1.5:1.5:4:4', 'unsharp=3:3:0.6:3:3:0.0'],
      if (modifyVisuals)
        'eq=brightness=${vars.brightness.toStringAsFixed(4)}:contrast=${vars.contrast.toStringAsFixed(4)}:saturation=${vars.saturation.toStringAsFixed(4)}',
      if (modifyVisuals) 'noise=alls=${vars.noiseStrength}:allf=t+u',
      'scale=trunc(iw/2)*2:trunc(ih/2)*2',
      'format=yuv420p',
    ];
  }

  /// Builds video filtergraph chain (-vf) with PTS, spatial transforms, scaling, enhancements, and grain.
  static String buildVideoFilter({
    required bool hasVisual,
    required bool hasAudio,
    bool modifyVisuals = true,
    bool upscale = false,
    TargetResolution targetResolution = TargetResolution.r1080p,
    VideoCodec videoCodec = VideoCodec.h264,
    bool enableEnhanceAndDenoise = true,
    bool enableDeepAntiFingerprint = true,
    bool enableHorizontalFlip = false,
    bool isPortrait = false,
    VideoVariations? variations,
  }) {
    if (!hasVisual) return hasAudio ? ' -c:v copy' : '';
    try {
      final vars = variations ?? (enableDeepAntiFingerprint ? VariationGenerator.generate() : VideoVariations.fallback);
      final filters = _buildFiltersList(
        modifyVisuals: modifyVisuals,
        enableDeepAntiFingerprint: enableDeepAntiFingerprint,
        enableHorizontalFlip: enableHorizontalFlip,
        upscale: upscale,
        targetResolution: targetResolution,
        enableEnhanceAndDenoise: enableEnhanceAndDenoise,
        isPortrait: isPortrait,
        vars: vars,
      );
      final codecArgs = videoCodec == VideoCodec.h265
          ? '-c:v libx265 -preset fast -crf 26 -tag:v hvc1'
          : '-c:v libx264 -preset fast -crf 22';
      return ' -vf "${filters.join(',')}" $codecArgs -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv -movflags +faststart';
    } catch (_) {
      return buildVideoFilter(
        hasVisual: hasVisual,
        hasAudio: hasAudio,
        modifyVisuals: modifyVisuals,
        upscale: upscale,
        targetResolution: targetResolution,
        videoCodec: videoCodec,
        enableEnhanceAndDenoise: enableEnhanceAndDenoise,
        enableDeepAntiFingerprint: false,
        enableHorizontalFlip: enableHorizontalFlip,
        isPortrait: isPortrait,
        variations: VideoVariations.fallback,
      );
    }
  }

  /// Builds audio filtergraph chain (-af) with tempo, EQ shaping, and optional pink noise masking.
  static String buildAudioFilter({
    required bool hasAudio,
    required bool hasVisual,
    bool enableDeepAntiFingerprint = true,
    bool enableAggressiveAudio = false,
    VideoVariations? variations,
  }) {
    if (!hasAudio) return hasVisual ? ' -c:a copy' : '';
    try {
      final vars = variations ?? (enableDeepAntiFingerprint ? VariationGenerator.generate() : VideoVariations.fallback);
      final tempo = vars.audioTempo.toStringAsFixed(6);
      if (enableAggressiveAudio) {
        return ' -af "[in]atempo=$tempo,highpass=f=60,lowpass=f=16000,equalizer=f=300:t=q:w=1.5:g=1.5,equalizer=f=3000:t=q:w=1.5:g=-1.5[a0];anoisesrc=d=7200:c=pink:a=0.003[noise];[a0][noise]amix=inputs=2:duration=first[out]" -c:a aac -b:a 192k';
      }
      if (enableDeepAntiFingerprint) {
        return ' -af "atempo=$tempo,highpass=f=60,lowpass=f=16000,equalizer=f=300:t=q:w=1.5:g=1.5,equalizer=f=3000:t=q:w=1.5:g=-1.5" -c:a aac -b:a 192k';
      }
      return ' -af "atempo=$tempo,equalizer=f=1000:t=q:w=1:g=0.5" -c:a aac -b:a 192k';
    } catch (_) {
      return ' -af "atempo=1.015228,equalizer=f=1000:t=q:w=1:g=0.5" -c:a aac -b:a 192k';
    }
  }
}
