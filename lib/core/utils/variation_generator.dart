import 'dart:math' as math;

/// Hardware metadata profile to obfuscate container signatures and defeat device clustering.
class DeviceProfile {
  final String make;
  final String model;
  final String encoder;
  final String videoHandler;
  final String audioHandler;

  const DeviceProfile({
    required this.make,
    required this.model,
    required this.encoder,
    this.videoHandler = 'Core Media Video',
    this.audioHandler = 'Core Media Audio',
  });

  static const DeviceProfile defaultProfile = DeviceProfile(
    make: 'Apple',
    model: 'iPhone 15 Pro Max',
    encoder: 'Apple QuickTime',
    videoHandler: 'Core Media Video',
    audioHandler: 'Core Media Audio',
  );

  static const List<DeviceProfile> profiles = [
    DeviceProfile(
      make: 'Apple',
      model: 'iPhone 15 Pro Max',
      encoder: 'Apple QuickTime',
      videoHandler: 'Core Media Video',
      audioHandler: 'Core Media Audio',
    ),
    DeviceProfile(
      make: 'Apple',
      model: 'iPhone 16 Pro',
      encoder: 'Apple QuickTime',
      videoHandler: 'Core Media Video',
      audioHandler: 'Core Media Audio',
    ),
    DeviceProfile(
      make: 'Samsung',
      model: 'Galaxy S24 Ultra',
      encoder: 'Samsung Camera',
      videoHandler: 'VideoHandle',
      audioHandler: 'SoundHandle',
    ),
    DeviceProfile(
      make: 'Google',
      model: 'Pixel 8 Pro',
      encoder: 'Google Camera',
      videoHandler: 'VideoHandler',
      audioHandler: 'SoundHandler',
    ),
    DeviceProfile(
      make: 'Google',
      model: 'Pixel 9 Pro',
      encoder: 'Google Camera',
      videoHandler: 'VideoHandler',
      audioHandler: 'SoundHandler',
    ),
  ];
}

/// Parameters for hardened dynamic anti-fingerprint video/audio micro-shifts.
class VideoVariations {
  final double cropPercent;
  final double brightness;
  final double contrast;
  final double saturation;
  final int noiseStrength;
  final double speedFactor;
  final double rotateAngle;
  final double audioTempo;
  final double outputFps;
  final double pitchFactor;
  final String curves;
  final DeviceProfile deviceProfile;

  const VideoVariations({
    required this.cropPercent,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.noiseStrength,
    required this.speedFactor,
    required this.rotateAngle,
    required this.audioTempo,
    required this.outputFps,
    this.pitchFactor = 1.012,
    this.curves =
        "r='0/0 0.15/0.1800 0.5/0.5000 0.85/0.8200 1/1':g='0/0 0.15/0.1800 0.5/0.5000 0.85/0.8200 1/1':b='0/0 0.15/0.1800 0.5/0.5000 0.85/0.8200 1/1'",
    this.deviceProfile = DeviceProfile.defaultProfile,
  });

  /// Hardened static fallback matching Sprint 69 anti-detection baseline.
  static const VideoVariations fallback = VideoVariations(
    cropPercent: 0.08,
    brightness: 0.0,
    contrast: 1.0,
    saturation: 1.0,
    noiseStrength: 4,
    speedFactor: 1.015,
    rotateAngle: 0.8,
    audioTempo: 1.015,
    outputFps: 29.85,
    pitchFactor: 1.012,
    curves:
        "r='0/0 0.15/0.1800 0.5/0.5000 0.85/0.8200 1/1':g='0/0 0.15/0.1800 0.5/0.5000 0.85/0.8200 1/1':b='0/0 0.15/0.1800 0.5/0.5000 0.85/0.8200 1/1'",
    deviceProfile: DeviceProfile.defaultProfile,
  );
}

/// Generates bounded, hardened variations to defeat algorithmic vDNA fingerprinting.
class VariationGenerator {
  static final math.Random _random = math.Random();

  /// Generates dynamic multi-channel non-linear RGB curves with safe bounded perturbation (±0.02).
  static String generateRgbCurves({math.Random? random}) {
    final rng = random ?? _random;
    String channelCurve() {
      final y1 = (0.18 + (rng.nextDouble() * 0.04 - 0.02)).toStringAsFixed(4);
      final y2 = (0.50 + (rng.nextDouble() * 0.04 - 0.02)).toStringAsFixed(4);
      final y3 = (0.82 + (rng.nextDouble() * 0.04 - 0.02)).toStringAsFixed(4);
      return '0/0 0.15/$y1 0.5/$y2 0.85/$y3 1/1';
    }

    return "r='${channelCurve()}':g='${channelCurve()}':b='${channelCurve()}'";
  }

  /// Generates random variations strictly bounded within hardened limits:
  /// - cropPercent: 0.07 to 0.09 (7% to 9% asymmetric crop)
  /// - brightness: -0.01 to 0.01
  /// - contrast: 0.99 to 1.01
  /// - saturation: 0.99 to 1.01
  /// - noiseStrength: 3 to 4 (survives mobile transcoder compression)
  /// - speedFactor: 1.010 to 1.025 (micro-speed shift / speed warp)
  /// - rotateAngle: 0.6 to 0.9 degrees
  /// - audioTempo: matches speedFactor for exact A/V sync
  /// - outputFps: 29.80 to 29.90 (breaks uniform frame-cadence indexing)
  /// - pitchFactor: 0.960 to 1.040 (±4.0% audio spectral modulation)
  /// - curves: dynamic multi-channel cubic RGB curves with ±0.02 shift
  /// - deviceProfile: realistic smartphone metadata pool
  static VideoVariations generate({math.Random? random}) {
    try {
      final rng = random ?? _random;
      final crop = 0.07 + rng.nextDouble() * 0.02;
      final bright = -0.01 + rng.nextDouble() * 0.02;
      final cont = 0.99 + rng.nextDouble() * 0.02;
      final sat = 0.99 + rng.nextDouble() * 0.02;
      final noise = rng.nextBool() ? 3 : 4;
      final speed = 1.010 + rng.nextDouble() * 0.015;
      final rot = 0.6 + rng.nextDouble() * 0.3;
      final tempo = speed;
      final fps = 29.80 + rng.nextDouble() * 0.10;
      final pitch = 0.960 + rng.nextDouble() * 0.080;
      final curves = generateRgbCurves(random: rng);
      final profile =
          DeviceProfile.profiles[rng.nextInt(DeviceProfile.profiles.length)];

      return VideoVariations(
        cropPercent: crop,
        brightness: bright,
        contrast: cont,
        saturation: sat,
        noiseStrength: noise,
        speedFactor: speed,
        rotateAngle: rot,
        audioTempo: tempo,
        outputFps: fps,
        pitchFactor: pitch,
        curves: curves,
        deviceProfile: profile,
      );
    } catch (_) {
      return VideoVariations.fallback;
    }
  }
}
