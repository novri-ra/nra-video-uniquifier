import 'dart:math' as math;

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
  );
}

/// Generates bounded, hardened variations to defeat algorithmic vDNA fingerprinting.
class VariationGenerator {
  static final math.Random _random = math.Random();

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
  /// - pitchFactor: 0.985 to 1.015 (audio spectral modulation)
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
      final pitch = 0.985 + rng.nextDouble() * 0.030;

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
      );
    } catch (_) {
      return VideoVariations.fallback;
    }
  }
}
