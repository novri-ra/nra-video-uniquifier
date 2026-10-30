import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';
import 'package:nra_video_uniquifier/core/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UniquifierProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SettingsService.upscaleResolutionNotifier.value = TargetResolution.r1080p;
    SettingsService.videoCodecNotifier.value = VideoCodec.h264;
    provider = UniquifierProvider();
  });

  tearDown(() {
    provider.dispose();
  });

  group('UniquifierProvider - Initial State', () {
    test('Default toggles match safe baseline', () {
      expect(provider.removeMetadata, isTrue);
      expect(provider.modifyAudio, isTrue);
      expect(provider.modifyVisuals, isTrue);
      expect(provider.upscale1080p, isFalse);
      expect(provider.enableEnhanceAndDenoise, isTrue);
      expect(provider.enableDeepAntiFingerprint, isTrue);
      expect(provider.enableHorizontalFlip, isFalse);
      expect(provider.enableAggressiveAudio, isFalse);
      expect(provider.enableAutoTrim, isFalse);
      expect(provider.selectedUpscaleTarget, equals('1080p'));
      expect(provider.targetResolutionLabel, equals('1080p'));
      expect(provider.targetResolutionDetails, equals('1920x1080'));
      expect(provider.hardwareAcceleration, isTrue);
      expect(provider.currentTabIndex, equals(0));
      expect(provider.lastProcessedOutputPath, isNull);
    });

    test('Default file properties are clean / empty', () {
      expect(provider.selectedFileName, isNull);
      expect(provider.selectedFilePath, isNull);
      expect(provider.thumbnailPath, isNull);
      expect(provider.realtimeProgress, equals(0.0));
      expect(provider.fileResolution, equals('1080×1920'));
      expect(provider.fileSize, equals('0 B'));
      expect(provider.fileCodec, equals('H.264'));
      expect(provider.duration, equals('0:00'));
    });
  });

  group('UniquifierProvider - Preset Application', () {
    test('Aggressive preset updates flags and resets tab index to 0', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.setTabIndex(2);

      provider.applyPreset(
        removeMetadata: true,
        modifyAudio: true,
        modifyVisuals: true,
        upscale1080p: true,
        upscaleTarget: '2k',
      );

      expect(provider.removeMetadata, isTrue);
      expect(provider.modifyAudio, isTrue);
      expect(provider.modifyVisuals, isTrue);
      expect(provider.upscale1080p, isTrue);
      expect(provider.selectedUpscaleTarget, equals('2k'));
      expect(provider.currentTabIndex, equals(0));
      expect(notifyCount, greaterThan(1));
    });

    test('Subtle preset configures minimal alterations', () {
      provider.applyPreset(
        removeMetadata: true,
        modifyAudio: false,
        modifyVisuals: false,
        upscale1080p: false,
        upscaleTarget: '1080p',
      );

      expect(provider.removeMetadata, isTrue);
      expect(provider.modifyAudio, isFalse);
      expect(provider.modifyVisuals, isFalse);
      expect(provider.upscale1080p, isFalse);
      expect(provider.selectedUpscaleTarget, equals('1080p'));
    });
  });

  group('UniquifierProvider - Toggles & Notifications', () {
    test('toggleRemoveMetadata flips flag and notifies listeners', () {
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.toggleRemoveMetadata(false);
      expect(provider.removeMetadata, isFalse);
      expect(notified, isTrue);
    });

    test('toggleModifyAudio flips flag and notifies listeners', () {
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.toggleModifyAudio(false);
      expect(provider.modifyAudio, isFalse);
      expect(notified, isTrue);
    });

    test('toggleModifyVisuals flips flag and notifies listeners', () {
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.toggleModifyVisuals(false);
      expect(provider.modifyVisuals, isFalse);
      expect(notified, isTrue);
    });

    test('toggleUpscale1080p and setUpscaleTarget update correctly', () {
      int notifications = 0;
      provider.addListener(() => notifications++);

      provider.toggleUpscale1080p(true);
      expect(provider.upscale1080p, isTrue);

      provider.setUpscaleTarget('2k');
      expect(provider.selectedUpscaleTarget, equals('2k'));
      expect(provider.targetResolutionLabel, equals('2K'));
      expect(provider.targetResolutionDetails, equals('2560x1440'));

      provider.setUpscaleTarget('4k');
      expect(provider.selectedUpscaleTarget, equals('4k'));
      expect(provider.targetResolutionLabel, equals('4K'));
      expect(provider.targetResolutionDetails, equals('3840x2160'));

      expect(notifications, equals(3));
    });

    test('Reacts immediately when SettingsService broadcasts resolution change', () async {
      await SettingsService.setUpscaleResolution(TargetResolution.r4k);
      expect(provider.selectedUpscaleTarget, equals('4k'));
      expect(provider.targetResolutionLabel, equals('4K'));
      expect(provider.targetResolutionDetails, equals('3840x2160'));
    });

    test('toggleEnhanceAndDenoise flips flag and notifies listeners', () {
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.toggleEnhanceAndDenoise(false);
      expect(provider.enableEnhanceAndDenoise, isFalse);
      expect(notified, isTrue);

      provider.toggleEnhanceAndDenoise(true);
      expect(provider.enableEnhanceAndDenoise, isTrue);
    });

    test('toggleDeepAntiFingerprint flips flag and notifies listeners', () {
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.toggleDeepAntiFingerprint(false);
      expect(provider.enableDeepAntiFingerprint, isFalse);
      expect(notified, isTrue);

      provider.toggleDeepAntiFingerprint(true);
      expect(provider.enableDeepAntiFingerprint, isTrue);
    });

    test('toggleHorizontalFlip, toggleAggressiveAudio, and toggleAutoTrim flip flags and notify listeners', () {
      int notifications = 0;
      provider.addListener(() => notifications++);

      provider.toggleHorizontalFlip(true);
      expect(provider.enableHorizontalFlip, isTrue);

      provider.toggleAggressiveAudio(true);
      expect(provider.enableAggressiveAudio, isTrue);

      provider.toggleAutoTrim(true);
      expect(provider.enableAutoTrim, isTrue);

      provider.toggleBlurredCanvas(true);
      expect(provider.enableBlurredCanvas, isTrue);

      provider.toggleMuteOriginalAudio(true);
      expect(provider.muteOriginalAudio, isTrue);

      expect(notifications, equals(5));
    });

    test('toggleHardwareAcceleration flips mode and syncs bidirectionally with SettingsService', () async {
      provider.toggleHardwareAcceleration(false);
      expect(provider.hardwareAcceleration, isFalse);
      expect(SettingsService.hardwareAccelerationNotifier.value, isFalse);

      await SettingsService.setHardwareAcceleration(true);
      expect(provider.hardwareAcceleration, isTrue);
      expect(SettingsService.hardwareAccelerationNotifier.value, isTrue);
    });

    test('setVideoCodec updates codec and notifies listeners', () {
      expect(provider.videoCodec, equals(VideoCodec.h264));
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setVideoCodec(VideoCodec.h265);
      expect(provider.videoCodec, equals(VideoCodec.h265));
      expect(notifyCount, equals(1));

      // Test reaction to external notification
      SettingsService.videoCodecNotifier.value = VideoCodec.h264;
      expect(provider.videoCodec, equals(VideoCodec.h264));
    });

    test('setTabIndex updates navigation state', () {
      provider.setTabIndex(1);
      expect(provider.currentTabIndex, equals(1));
    });
  });

  group('UniquifierProvider - File Management & Utility Formatting', () {
    test('setVideoFile initializes state from metadata and filename', () {
      provider.setVideoFile(
        path: '/mock/path/sample.mov',
        name: 'sample.mov',
        sizeBytes: 15728640, // 15 MB
      );

      expect(provider.selectedFilePath, equals('/mock/path/sample.mov'));
      expect(provider.selectedFileName, equals('sample.mov'));
      expect(provider.fileSize, equals('15.0 MB'));
      expect(provider.fileCodec, equals('ProRes/H.264'));
      expect(provider.sha256, endsWith('…'));
    });

    test('setLastProcessedResult updates output path', () {
      provider.setLastProcessedResult('/path/output_unique.mp4');
      expect(provider.lastProcessedOutputPath, equals('/path/output_unique.mp4'));
    });

    test('clearSelection resets file references', () {
      provider.clearSelection();
      expect(provider.selectedFileName, isNull);
      expect(provider.selectedFilePath, isNull);
      expect(provider.thumbnailPath, isNull);
    });

    test('updateRealtimeStats updates progress, speed and calculates eta', () {
      provider.updateRealtimeStats(0.45, 1.8, 18000);
      expect(provider.realtimeProgress, equals(0.45));
      expect(provider.renderingSpeed, equals(1.8));
    });

    test('formatDuration formats 0s, seconds-only, and hh:mm:ss spans', () {
      expect(UniquifierProvider.formatDuration(null), equals('0:00'));
      expect(UniquifierProvider.formatDuration('0'), equals('0:00'));
      expect(UniquifierProvider.formatDuration('45'), equals('0:45'));
      expect(UniquifierProvider.formatDuration('125.4'), equals('2:05'));
      expect(UniquifierProvider.formatDuration('3665'), equals('1:01:05'));
    });

    test('formatFileSize formats byte boundaries correctly', () {
      expect(UniquifierProvider.formatFileSize(0), equals('0 B'));
      expect(UniquifierProvider.formatFileSize(-5), equals('0 B'));
      expect(UniquifierProvider.formatFileSize(512), equals('512.0 B'));
      expect(UniquifierProvider.formatFileSize(1024), equals('1.0 KB'));
      expect(UniquifierProvider.formatFileSize(1048576), equals('1.0 MB'));
      expect(UniquifierProvider.formatFileSize(1073741824), equals('1.0 GB'));
    });
  });
}
