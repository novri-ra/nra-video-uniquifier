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
  });

  /// Hardened static fallback matching Report 30/41 proven baseline.
  static const VideoVariations fallback = VideoVariations(
    cropPercent: 0.08,
    brightness: 0.0,
    contrast: 1.0,
    saturation: 1.0,
    noiseStrength: 4,
    speedFactor: 0.975,
    rotateAngle: 0.8,
    audioTempo: 1.0 / 0.975,
    outputFps: 29.85,
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
  /// - speedFactor: 0.970 to 0.975 (2.5% to 3.0% speedup, exceeds DTW threshold)
  /// - rotateAngle: 0.6 to 0.9 degrees
  /// - audioTempo: 1.0 / speedFactor (exact A/V lip-sync)
  /// - outputFps: 29.80 to 29.90 (breaks uniform frame-cadence indexing)
  static VideoVariations generate({math.Random? random}) {
    try {
      final rng = random ?? _random;
      final crop = 0.07 + rng.nextDouble() * 0.02;
      final bright = -0.01 + rng.nextDouble() * 0.02;
      final cont = 0.99 + rng.nextDouble() * 0.02;
      final sat = 0.99 + rng.nextDouble() * 0.02;
      final noise = rng.nextBool() ? 3 : 4;
      final speed = 0.970 + rng.nextDouble() * 0.005;
      final rot = 0.6 + rng.nextDouble() * 0.3;
      final tempo = 1.0 / speed;
      final fps = 29.80 + rng.nextDouble() * 0.10;

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
      );
    } catch (_) {
      return VideoVariations.fallback;
    }
  }
}
