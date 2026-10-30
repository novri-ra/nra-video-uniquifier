import 'dart:math' as math;

/// Parameters for imperceptible dynamic anti-fingerprint video/audio micro-shifts.
class VideoVariations {
  final double cropPercent;
  final double brightness;
  final double contrast;
  final double saturation;
  final int noiseStrength;
  final double speedFactor;
  final double rotateAngle;
  final double audioTempo;

  const VideoVariations({
    required this.cropPercent,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.noiseStrength,
    required this.speedFactor,
    required this.rotateAngle,
    required this.audioTempo,
  });

  /// Safe static fallback within all quality boundaries.
  static const VideoVariations fallback = VideoVariations(
    cropPercent: 0.05,
    brightness: 0.0,
    contrast: 1.0,
    saturation: 1.0,
    noiseStrength: 1,
    speedFactor: 0.985,
    rotateAngle: 0.3,
    audioTempo: 1.0 / 0.985,
  );
}

/// Generates bounded, imperceptible variations to defeat algorithmic fingerprinting.
class VariationGenerator {
  static final math.Random _random = math.Random();

  /// Generates random variations strictly bounded within high visual fidelity limits:
  /// - cropPercent: 0.04 to 0.06 (4% to 6%)
  /// - brightness: -0.01 to 0.01
  /// - contrast: 0.99 to 1.01
  /// - saturation: 0.99 to 1.01
  /// - noiseStrength: 1 to 2
  /// - speedFactor: 0.98 to 0.99
  /// - rotateAngle: 0.2 to 0.4 degrees
  /// - audioTempo: 1.0 / speedFactor (exact A/V lip-sync)
  static VideoVariations generate({math.Random? random}) {
    try {
      final rng = random ?? _random;
      final crop = 0.04 + rng.nextDouble() * 0.02;
      final bright = -0.01 + rng.nextDouble() * 0.02;
      final cont = 0.99 + rng.nextDouble() * 0.02;
      final sat = 0.99 + rng.nextDouble() * 0.02;
      final noise = rng.nextBool() ? 1 : 2;
      final speed = 0.98 + rng.nextDouble() * 0.01;
      final rot = 0.2 + rng.nextDouble() * 0.2;
      final tempo = 1.0 / speed;

      return VideoVariations(
        cropPercent: crop,
        brightness: bright,
        contrast: cont,
        saturation: sat,
        noiseStrength: noise,
        speedFactor: speed,
        rotateAngle: rot,
        audioTempo: tempo,
      );
    } catch (_) {
      return VideoVariations.fallback;
    }
  }
}
