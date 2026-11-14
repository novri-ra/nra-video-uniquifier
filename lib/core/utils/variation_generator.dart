import 'dart:math' as math;
import 'package:flutter/foundation.dart';

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

  /// Hardened static fallback matching the new aggressive baseline.
  static const VideoVariations fallback = VideoVariations(
    cropPercent: 0.10, // <-- Ubah ke 10%
    brightness: 0.0,
    contrast: 1.0,
    saturation: 1.0,
    noiseStrength: 6, // <-- Ubah ke 6
    speedFactor: 1.03, // <-- Ubah ke 1.03
    rotateAngle: 1.0, // <-- Ubah ke 1.0
    audioTempo: 1.03, // <-- Samakan dengan speedFactor
    outputFps: 29.7, // <-- Variasi FPS
    pitchFactor: 0.99, // <-- Pitch shift lebih kuat
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
  /// - pitchFactor: 0.985 to 1.015 (±1.5% sub-perceptual audio spectral modulation)
  /// - curves: dynamic multi-channel cubic RGB curves with ±0.02 shift
  /// - deviceProfile: realistic smartphone metadata pool
  static VideoVariations generate({math.Random? random}) {
    try {
      final rng = random ?? _random;
      // 1. Perkuat Crop: 8% hingga 12%
      final crop = 0.08 + rng.nextDouble() * 0.04;
      final bright = -0.01 + rng.nextDouble() * 0.02;
      final cont = 0.99 + rng.nextDouble() * 0.02;
      final sat = 0.99 + rng.nextDouble() * 0.02;
      // 2. Perkuat Noise: 4 hingga 8
      final noise = 4 + rng.nextInt(5);
      // 3. Perkuat Speed Warp: 1.02 hingga 1.05 (2-5% lebih cepat)
      final speed = 1.02 + rng.nextDouble() * 0.03;
      // 4. Perkuat Rotasi: 0.8 hingga 1.5 derajat
      final rot = 0.8 + rng.nextDouble() * 0.7;
      final tempo = speed; // Sinkron dengan speed
      // 5. FPS lebih bervariasi
      final fps = 29.50 + rng.nextDouble() * 0.8;
      // 6. Perkuat Pitch Shift: 0.98 hingga 1.02 (±2%)
      final pitch = 0.98 + rng.nextDouble() * 0.04;
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
    } catch (e) {
      debugPrint('[VariationGenerator] generate failed: $e');
      return VideoVariations.fallback;
    }
  }
}
