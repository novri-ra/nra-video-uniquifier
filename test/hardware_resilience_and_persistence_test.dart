import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';
import 'package:nra_video_uniquifier/core/services/device_capability_service.dart';
import 'package:nra_video_uniquifier/core/services/settings_service.dart';
import 'package:nra_video_uniquifier/core/services/wakelock_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceCapabilityService & Hardware Profiling Tests', () {
    test('classifyTier accurately categorizes entry, mid, and flagship hardware', () {
      final entry = DeviceSpecs.classifyTier(
        totalRamBytes: 3 * 1024 * 1024 * 1024,
        cpuCores: 4,
        hasVulkanCompute: false,
      );
      expect(entry, equals(DeviceTier.entry));

      final mid = DeviceSpecs.classifyTier(
        totalRamBytes: 6 * 1024 * 1024 * 1024,
        cpuCores: 8,
        hasVulkanCompute: true,
      );
      expect(mid, equals(DeviceTier.mid));

      final flagship = DeviceSpecs.classifyTier(
        totalRamBytes: 12 * 1024 * 1024 * 1024,
        cpuCores: 8,
        hasVulkanCompute: true,
      );
      expect(flagship, equals(DeviceTier.flagship));
    });

    test('getResolutionWarning suppresses warning on Flagship, tags 4K on Mid, tags 2K/4K on Entry', () {
      expect(DeviceCapabilityService.getResolutionWarning(targetKey: '4k', tier: DeviceTier.flagship), isNull);
      expect(DeviceCapabilityService.getResolutionWarning(targetKey: '2k', tier: DeviceTier.flagship), isNull);

      expect(DeviceCapabilityService.getResolutionWarning(targetKey: '4k', tier: DeviceTier.mid), equals('BEBAN TINGGI'));
      expect(DeviceCapabilityService.getResolutionWarning(targetKey: '2k', tier: DeviceTier.mid), isNull);

      expect(DeviceCapabilityService.getResolutionWarning(targetKey: '4k', tier: DeviceTier.entry), equals('RISIKO PANAS / LAMBAT'));
      expect(DeviceCapabilityService.getResolutionWarning(targetKey: '2k', tier: DeviceTier.entry), equals('RISIKO PANAS / LAMBAT'));
    });
  });

  group('WakeLockService Resilience Tests', () {
    test('acquire, isHeld, and release operate deterministically in test mode', () async {
      WakeLockService.testOverride = false;
      expect(await WakeLockService.isHeld(), isFalse);

      await WakeLockService.acquire();
      expect(await WakeLockService.isHeld(), isTrue);

      await WakeLockService.release();
      expect(await WakeLockService.isHeld(), isFalse);
    });
  });

  group('Settings Persistence Round-Trip Tests', () {
    test('All toggles, sliders, and target resolutions persist across provider recreation', () async {
      SharedPreferences.setMockInitialValues({});

      // 1. First provider: modify all values and verify saving to SharedPreferences
      final provider1 = UniquifierProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      provider1.toggleRemoveMetadata(false);
      provider1.toggleModifyVisuals(false);
      provider1.toggleModifyAudio(false);
      provider1.toggleUpscale1080p(true);
      provider1.toggleEnhanceAndDenoise(false);
      provider1.toggleDeepAntiFingerprint(false);
      provider1.toggleHorizontalFlip(true);
      provider1.toggleAggressiveAudio(true);
      provider1.toggleAutoTrim(true);
      provider1.toggleBlurredCanvas(true);
      provider1.toggleMuteOriginalAudio(true);
      provider1.toggleDynamicZoom(true);
      provider1.toggleMicroOverlay(true);
      provider1.toggleFrameSkip(true);
      provider1.toggleChromaShift(true);
      provider1.setCanvasScalePercent(88.0);
      provider1.setUpscaleTarget('4k');
      provider1.setVideoCodec(VideoCodec.h265);
      provider1.setUpscaleEngine(UpscaleEngine.neuralAi);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 2. Second provider: instantiate fresh and verify all settings restored
      final provider2 = UniquifierProvider();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(provider2.removeMetadata, isFalse);
      expect(provider2.modifyVisuals, isFalse);
      expect(provider2.modifyAudio, isFalse);
      expect(provider2.upscale1080p, isTrue);
      expect(provider2.enableEnhanceAndDenoise, isFalse);
      expect(provider2.enableDeepAntiFingerprint, isFalse);
      expect(provider2.enableHorizontalFlip, isTrue);
      expect(provider2.enableAggressiveAudio, isTrue);
      expect(provider2.enableAutoTrim, isTrue);
      expect(provider2.enableBlurredCanvas, isTrue);
      expect(provider2.muteOriginalAudio, isTrue);
      expect(provider2.enableDynamicZoom, isTrue);
      expect(provider2.enableMicroOverlay, isTrue);
      expect(provider2.enableFrameSkip, isTrue);
      expect(provider2.enableChromaShift, isTrue);
      expect(provider2.canvasScalePercent, equals(88.0));
      expect(provider2.selectedUpscaleTarget, equals('4k'));
      expect(provider2.videoCodec, equals(VideoCodec.h265));
      expect(provider2.upscaleEngine, equals(UpscaleEngine.neuralAi));

      provider1.dispose();
      provider2.dispose();
    });
  });
}
