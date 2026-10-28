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
      expect(await SettingsService.getEngineMode(), equals('software'));
      expect(await SettingsService.getDefaultPreset(), equals('balanced'));
      expect(await SettingsService.getCustomOutputPath(), isNull);
    });

    test('Updating engine mode persists value', () async {
      await SettingsService.setEngineMode('hardware');
      expect(await SettingsService.getEngineMode(), equals('hardware'));
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
    });

    test('purgeTempCache deletes staged and thumb files safely', () async {
      final tempDir = Directory.systemTemp.createTempSync('uniquifier_test_');
      final staged = File('${tempDir.path}/staged_dummy.mp4');
      final thumb = File('${tempDir.path}/thumb_dummy.jpg');
      final other = File('${tempDir.path}/keep_dummy.txt');

      await staged.writeAsString('test-video-content');
      await thumb.writeAsString('test-thumb-content');
      await other.writeAsString('keep-this');

      final freed = await SettingsService.purgeTempCache(tempDir);
      expect(freed, greaterThan(0));
      expect(staged.existsSync(), isFalse);
      expect(thumb.existsSync(), isFalse);
      expect(other.existsSync(), isTrue);

      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });
  });
}
