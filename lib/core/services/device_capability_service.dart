import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum DeviceTier {
  entry('Entry Tier', 'Limited RAM / CPU'),
  mid('Mid Tier', 'Balanced Hardware'),
  flagship('Flagship / High-End', 'Full Hardware Acceleration');

  final String label;
  final String description;
  const DeviceTier(this.label, this.description);
}

class DeviceSpecs {
  final int totalRamBytes;
  final int availRamBytes;
  final int cpuCores;
  final String primaryAbi;
  final bool isArm64;
  final bool hasVulkan;
  final bool hasVulkanCompute;
  final DeviceTier tier;

  const DeviceSpecs({
    required this.totalRamBytes,
    required this.availRamBytes,
    required this.cpuCores,
    required this.primaryAbi,
    required this.isArm64,
    required this.hasVulkan,
    required this.hasVulkanCompute,
    required this.tier,
  });

  double get totalRamGb => totalRamBytes / (1024 * 1024 * 1024);
  double get availRamGb => availRamBytes / (1024 * 1024 * 1024);

  static DeviceTier classifyTier({
    required int totalRamBytes,
    required int cpuCores,
    required bool hasVulkanCompute,
  }) {
    final ramGb = totalRamBytes / (1024 * 1024 * 1024);
    if (ramGb >= 11.0 && hasVulkanCompute) return DeviceTier.flagship;
    if (ramGb >= 3.5 && cpuCores >= 6) return DeviceTier.mid;
    return DeviceTier.entry;
  }

  factory DeviceSpecs.fromMap(Map<dynamic, dynamic> map) {
    final totalRam = (map['totalRamBytes'] as num?)?.toInt() ?? 0;
    final availRam = (map['availRamBytes'] as num?)?.toInt() ?? 0;
    final cpuCores = (map['cpuCores'] as num?)?.toInt() ?? 4;
    final primaryAbi = (map['primaryAbi'] as String?) ?? 'unknown';
    final isArm64 = (map['isArm64'] as bool?) ?? false;
    final hasVulkan = (map['hasVulkan'] as bool?) ?? false;
    final hasVulkanCompute = (map['hasVulkanCompute'] as bool?) ?? false;
    final tier = classifyTier(
      totalRamBytes: totalRam,
      cpuCores: cpuCores,
      hasVulkanCompute: hasVulkanCompute,
    );

    return DeviceSpecs(
      totalRamBytes: totalRam,
      availRamBytes: availRam,
      cpuCores: cpuCores,
      primaryAbi: primaryAbi,
      isArm64: isArm64,
      hasVulkan: hasVulkan,
      hasVulkanCompute: hasVulkanCompute,
      tier: tier,
    );
  }

  factory DeviceSpecs.defaultFallback() => DeviceSpecs(
    totalRamBytes: 8 * 1024 * 1024 * 1024,
    availRamBytes: 4 * 1024 * 1024 * 1024,
    cpuCores: 8,
    primaryAbi: 'arm64-v8a',
    isArm64: true,
    hasVulkan: true,
    hasVulkanCompute: true,
    tier: DeviceTier.mid,
  );
}

class DeviceCapabilityService {
  static const MethodChannel _channel = MethodChannel(
    'id.novrira.videouniquifier/device_capability',
  );
  static DeviceSpecs? _cachedSpecs;
  static bool? _testOverride;
  static DeviceSpecs? _testSpecsOverride;

  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;
  @visibleForTesting
  static set testSpecsOverride(DeviceSpecs? specs) =>
      _testSpecsOverride = specs;

  static bool get _canRun => _testOverride ?? Platform.isAndroid;

  static Future<DeviceSpecs> getSpecs() async {
    if (_testSpecsOverride != null) return _testSpecsOverride!;
    if (_cachedSpecs != null) return _cachedSpecs!;

    if (!_canRun) {
      _cachedSpecs = DeviceSpecs.defaultFallback();
      return _cachedSpecs!;
    }

    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getDeviceSpecs',
      );
      if (res != null) {
        _cachedSpecs = DeviceSpecs.fromMap(res);
        return _cachedSpecs!;
      }
    } catch (e) {
      debugPrint(
        '[DeviceCapabilityService] device specs probe failed: '
        '${e.runtimeType}',
      );
    }

    _cachedSpecs = DeviceSpecs.defaultFallback();
    return _cachedSpecs!;
  }

  static String? getResolutionWarning({
    required String targetKey,
    required DeviceTier tier,
  }) {
    if (tier == DeviceTier.flagship) return null;
    if (tier == DeviceTier.entry) {
      if (targetKey == '2k' || targetKey == '4k') {
        return 'RISIKO PANAS / LAMBAT';
      }
    } else if (tier == DeviceTier.mid) {
      if (targetKey == '4k') return 'BEBAN TINGGI';
    }
    return null;
  }
}
