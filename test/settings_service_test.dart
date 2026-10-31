import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsService - SharedPreferences persistence', () {
    test('Default values returned when unset', () async {
      expect(await SettingsService.getHardwareAcceleration(), isTrue);
      expect(await SettingsService.getDefaultPreset(), equals('balanced'));
      expect(await SettingsService.getCustomOutputPath(), isNull);
    });

    test('Updating hardware acceleration persists and broadcasts value', () async {
      await SettingsService.setHardwareAcceleration(false);
      expect(await SettingsService.getHardwareAcceleration(), isFalse);
      expect(SettingsService.hardwareAccelerationNotifier.value, isFalse);
      await SettingsService.setHardwareAcceleration(true);
      expect(await SettingsService.getHardwareAcceleration(), isTrue);
      expect(SettingsService.hardwareAccelerationNotifier.value, isTrue);
    });

    test('Updating default preset persists value', () async {
      await SettingsService.setDefaultPreset('aggressive');
      expect(await SettingsService.getDefaultPreset(), equals('aggressive'));
    });

    test('Updating custom output path persists value', () async {
      await SettingsService.setCustomOutputPath('/custom/movies/dir');
      expect(await SettingsService.getCustomOutputPath(), equals('/custom/movies/dir'));
    });

    test('Upscale resolution defaults to 1080p when unset', () async {
      final res = await SettingsService.getUpscaleResolution();
      expect(res, equals(TargetResolution.r1080p));
      expect(res.label, equals('1080p'));
      expect(res.details, equals('1920x1080'));
      expect(SettingsService.upscaleResolutionNotifier.value, equals(TargetResolution.r1080p));
    });

    test('Upscale resolution persists and broadcasts reactively for 1080p, 2K, and 4K', () async {
      final broadcastLog = <TargetResolution>[];
      void listener() => broadcastLog.add(SettingsService.upscaleResolutionNotifier.value);
      SettingsService.upscaleResolutionNotifier.addListener(listener);

      try {
        // Set to 2K
        await SettingsService.setUpscaleResolution(TargetResolution.r2k);
        expect(await SettingsService.getUpscaleResolution(), equals(TargetResolution.r2k));
        expect(SettingsService.upscaleResolutionNotifier.value, equals(TargetResolution.r2k));
        expect(SettingsService.upscaleResolutionNotifier.value.details, equals('2560x1440'));

        // Set to 4K
        await SettingsService.setUpscaleResolution(TargetResolution.r4k);
        expect(await SettingsService.getUpscaleResolution(), equals(TargetResolution.r4k));
        expect(SettingsService.upscaleResolutionNotifier.value, equals(TargetResolution.r4k));
        expect(SettingsService.upscaleResolutionNotifier.value.details, equals('3840x2160'));

        // Revert to 1080p
        await SettingsService.setUpscaleResolution(TargetResolution.r1080p);
        expect(await SettingsService.getUpscaleResolution(), equals(TargetResolution.r1080p));
        expect(SettingsService.upscaleResolutionNotifier.value, equals(TargetResolution.r1080p));
        expect(SettingsService.upscaleResolutionNotifier.value.details, equals('1920x1080'));

        // Verify broadcast reactive notifications
        expect(broadcastLog, containsAllInOrder([
          TargetResolution.r2k,
          TargetResolution.r4k,
          TargetResolution.r1080p,
        ]));
      } finally {
        SettingsService.upscaleResolutionNotifier.removeListener(listener);
      }
    });

    test('TargetResolution.fromString parses various representations accurately', () {
      expect(TargetResolution.fromString('1080p'), equals(TargetResolution.r1080p));
      expect(TargetResolution.fromString('2k'), equals(TargetResolution.r2k));
      expect(TargetResolution.fromString('1440p'), equals(TargetResolution.r2k));
      expect(TargetResolution.fromString('4k'), equals(TargetResolution.r4k));
      expect(TargetResolution.fromString('2160p'), equals(TargetResolution.r4k));
      expect(TargetResolution.fromString('invalid'), equals(TargetResolution.r1080p));
      expect(TargetResolution.fromString(null), equals(TargetResolution.r1080p));
    });

    test('Enhance & denoise toggle defaults to true and persists changes', () async {
      expect(await SettingsService.getEnhanceAndDenoise(), isTrue);
      await SettingsService.setEnhanceAndDenoise(false);
      expect(await SettingsService.getEnhanceAndDenoise(), isFalse);
    });

    test('Deep anti-fingerprint toggle defaults to true and persists changes', () async {
      expect(await SettingsService.getDeepAntiFingerprint(), isTrue);
      await SettingsService.setDeepAntiFingerprint(false);
      expect(await SettingsService.getDeepAntiFingerprint(), isFalse);
    });

    test('Horizontal flip, aggressive audio, and auto trim default to false and persist changes', () async {
      expect(await SettingsService.getHorizontalFlip(), isFalse);
      await SettingsService.setHorizontalFlip(true);
      expect(await SettingsService.getHorizontalFlip(), isTrue);

      expect(await SettingsService.getAggressiveAudio(), isFalse);
      await SettingsService.setAggressiveAudio(true);
      expect(await SettingsService.getAggressiveAudio(), isTrue);

      expect(await SettingsService.getAutoTrim(), isFalse);
      await SettingsService.setAutoTrim(true);
      expect(await SettingsService.getAutoTrim(), isTrue);

      expect(await SettingsService.getDynamicZoom(), isFalse);
      await SettingsService.setDynamicZoom(true);
      expect(await SettingsService.getDynamicZoom(), isTrue);

      expect(await SettingsService.getMicroOverlay(), isFalse);
      await SettingsService.setMicroOverlay(true);
      expect(await SettingsService.getMicroOverlay(), isTrue);

      expect(await SettingsService.getFrameSkip(), isFalse);
      await SettingsService.setFrameSkip(true);
      expect(await SettingsService.getFrameSkip(), isTrue);

      expect(await SettingsService.getChromaShift(), isFalse);
      await SettingsService.setChromaShift(true);
      expect(await SettingsService.getChromaShift(), isTrue);

      expect(await SettingsService.getCanvasScalePercent(), equals(95.0));
      await SettingsService.setCanvasScalePercent(85.0);
      expect(await SettingsService.getCanvasScalePercent(), equals(85.0));
    });

    test('purgeTempCache deletes staged and thumb files safely', () async {
      final tempDir = Directory.systemTemp.createTempSync('uniquifier_test_');
      final staged = File('${tempDir.path}/staged_dummy.mp4');
      final thumb = File('${tempDir.path}/thumb_dummy.jpg');
      final other = File('${tempDir.path}/keep_dummy.txt');

      await staged.writeAsString('test-video-content');
      await thumb.writeAsString('test-thumb-content');
      await other.writeAsString('keep-this');

      final sizeBefore = await SettingsService.getTempCacheSize(tempDir);
      expect(sizeBefore, greaterThan(0));

      final freed = await SettingsService.purgeTempCache(tempDir);
      expect(freed, equals(sizeBefore));
      expect(staged.existsSync(), isFalse);
      expect(thumb.existsSync(), isFalse);
      expect(other.existsSync(), isTrue);

      final sizeAfter = await SettingsService.getTempCacheSize(tempDir);
      expect(sizeAfter, equals(0));

      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('VideoCodec enum parsing and persistence', () async {
      expect(VideoCodec.fromString('h264'), equals(VideoCodec.h264));
      expect(VideoCodec.fromString('avc'), equals(VideoCodec.h264));
      expect(VideoCodec.fromString('h265'), equals(VideoCodec.h265));
      expect(VideoCodec.fromString('hevc'), equals(VideoCodec.h265));
      expect(VideoCodec.fromString('unknown'), equals(VideoCodec.h264));

      expect(await SettingsService.getVideoCodec(), equals(VideoCodec.h264));
      await SettingsService.setVideoCodec(VideoCodec.h265);
      expect(await SettingsService.getVideoCodec(), equals(VideoCodec.h265));
      expect(SettingsService.videoCodecNotifier.value, equals(VideoCodec.h265));
    });

    test('Notification sound and background processing persistence', () async {
      expect(await SettingsService.getNotificationSound(), isTrue);
      await SettingsService.setNotificationSound(false);
      expect(await SettingsService.getNotificationSound(), isFalse);

      expect(await SettingsService.getBackgroundProcessing(), isTrue);
      await SettingsService.setBackgroundProcessing(false);
      expect(await SettingsService.getBackgroundProcessing(), isFalse);
    });

    test('UpscaleEngine enum parsing and persistence', () async {
      expect(UpscaleEngine.fromString('lanczos'), equals(UpscaleEngine.lanczos));
      expect(UpscaleEngine.fromString('neural_ai'), equals(UpscaleEngine.neuralAi));
      expect(UpscaleEngine.fromString('ai'), equals(UpscaleEngine.neuralAi));
      expect(UpscaleEngine.fromString('realesrgan'), equals(UpscaleEngine.neuralAi));
      expect(UpscaleEngine.fromString('unknown'), equals(UpscaleEngine.lanczos));

      expect(await SettingsService.getUpscaleEngine(), equals(UpscaleEngine.lanczos));
      await SettingsService.setUpscaleEngine(UpscaleEngine.neuralAi);
      expect(await SettingsService.getUpscaleEngine(), equals(UpscaleEngine.neuralAi));
      expect(SettingsService.upscaleEngineNotifier.value, equals(UpscaleEngine.neuralAi));
    });
  });
}
