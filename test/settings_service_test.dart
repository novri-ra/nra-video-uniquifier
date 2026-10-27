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
