import 'settings_service.dart';

/// Pure static builders for FFmpeg video and audio filtergraph chains.
class FilterBuilders {
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
  }) {
    if (hasVisual) {
      final filters = <String>[
        // 1. Temporal (PTS)
        if (modifyVisuals) 'setpts=0.975*PTS',

        // 2. Spatial (Crop -> Rotate -> Hflip)
        if (modifyVisuals) ...[
          if (enableDeepAntiFingerprint)
            'crop=trunc(iw*0.92/2)*2:trunc(ih*0.92/2)*2:trunc(iw*0.04/2)*2:trunc(ih*0.04/2)*2'
          else
            'crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2',
          if (enableDeepAntiFingerprint)
            'rotate=0.8*PI/180:ow=trunc(rotw(0.8*PI/180)/2)*2:oh=trunc(roth(0.8*PI/180)/2)*2:fillcolor=black',
          if (enableHorizontalFlip) 'hflip',
        ] else if (enableHorizontalFlip) ...[
          'hflip',
        ],

        // 3. Resolution Scaling (Lanczos scale - orientation aware)
        if (upscale) targetResolution.scaleFilter(isPortrait: isPortrait),

        // 4. Enhancements (Denoise -> Unsharp -> Micro-contrast/saturation EQ)
        if (enableEnhanceAndDenoise) ...[
          'hqdn3d=1.5:1.5:4:4',
          'unsharp=3:3:0.6:3:3:0.0',
        ],
        if (modifyVisuals) 'eq=contrast=1.04:brightness=0.01:saturation=1.05:gamma=0.98',

        // 5. Grain Injection (Noise)
        if (modifyVisuals) 'noise=alls=4:allf=t+u',

        // 6. Explicit Termination with YUV 4:2:0 planar
        'format=yuv420p',
      ];
      final codecArgs = videoCodec == VideoCodec.h265
          ? '-c:v libx265 -preset fast -crf 26 -tag:v hvc1'
          : '-c:v libx264 -preset fast -crf 22';
      return ' -vf "${filters.join(',')}" $codecArgs -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv -movflags +faststart';
    }
    return hasAudio ? ' -c:v copy' : '';
  }

  /// Builds audio filtergraph chain (-af) with tempo, EQ shaping, and optional pink noise masking.
  static String buildAudioFilter({
    required bool hasAudio,
    required bool hasVisual,
    bool enableDeepAntiFingerprint = true,
    bool enableAggressiveAudio = false,
  }) {
    if (hasAudio) {
      if (enableAggressiveAudio) {
        return ' -af "[in]atempo=1.0256,highpass=f=60,lowpass=f=16000,equalizer=f=300:t=q:w=1.5:g=1.5,equalizer=f=3000:t=q:w=1.5:g=-1.5[a0];anoisesrc=d=7200:c=pink:a=0.003[noise];[a0][noise]amix=inputs=2:duration=first[out]" -c:a aac -b:a 192k';
      }
      if (enableDeepAntiFingerprint) {
        return ' -af "atempo=1.0256,highpass=f=60,lowpass=f=16000,equalizer=f=300:t=q:w=1.5:g=1.5,equalizer=f=3000:t=q:w=1.5:g=-1.5" -c:a aac -b:a 192k';
      }
      return ' -af "atempo=1.0256,equalizer=f=1000:t=q:w=1:g=0.5" -c:a aac -b:a 192k';
    }
    return hasVisual ? ' -c:a copy' : '';
  }
}
