import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UniquifierProvider provider;

  setUp(() {
    provider = UniquifierProvider();
  });

  group('UniquifierProvider - Initial State', () {
    test('Default toggles match safe baseline', () {
      expect(provider.removeMetadata, isTrue);
      expect(provider.modifyAudio, isTrue);
      expect(provider.modifyVisuals, isTrue);
      expect(provider.upscale1080p, isFalse);
      expect(provider.selectedUpscaleTarget, equals('1080p'));
      expect(provider.hardwareAcceleration, isTrue);
      expect(provider.currentTabIndex, equals(0));
      expect(provider.lastProcessedOutputPath, isNull);
    });

    test('Default file properties are populated', () {
      expect(provider.selectedFileName, equals('video_01.mp4'));
      expect(provider.selectedFilePath, isNull);
      expect(provider.fileResolution, equals('1080×1920'));
      expect(provider.fileSize, equals('24.8 MB'));
      expect(provider.fileCodec, equals('H.264'));
      expect(provider.fps, equals('60 FPS'));
      expect(provider.audioInfo, equals('AAC 48kHz'));
      expect(provider.duration, equals('0:15'));
      expect(provider.sha256, isNotEmpty);
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

      provider.setUpscaleTarget('720p');
      expect(provider.selectedUpscaleTarget, equals('720p'));

      expect(notifications, equals(2));
    });

    test('toggleHardwareAcceleration flips mode', () {
      provider.toggleHardwareAcceleration(false);
      expect(provider.hardwareAcceleration, isFalse);
      provider.toggleHardwareAcceleration(true);
      expect(provider.hardwareAcceleration, isTrue);
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
