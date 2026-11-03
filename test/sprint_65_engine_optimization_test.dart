import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/models/batch_video_item.dart';
import 'package:nra_video_uniquifier/core/providers/batch_queue_provider.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';
import 'package:nra_video_uniquifier/core/services/ffmpeg_service.dart';
import 'package:nra_video_uniquifier/core/services/settings_service.dart';
import 'package:nra_video_uniquifier/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Sprint 65 - Engine 100% Load & FastStart Optimizations', () {
    test('buildCommand includes -threads 0 when thermal throttle is false', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: 'in.mp4',
        outputPath: 'out.mp4',
        thermalThrottle: false,
      );
      expect(cmd, contains('-threads 0'));
      expect(cmd, isNot(contains('-threads 4')));
    });

    test('buildCommand includes -threads 4 when thermal throttle is true', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: 'in.mp4',
        outputPath: 'out.mp4',
        thermalThrottle: true,
      );
      expect(cmd, contains('-threads 4'));
    });

    test(
      'buildCommand applies -preset faster for 2K and 4K high-res targets',
      () {
        final cmd2k = FfmpegService.buildCommand(
          inputPath: 'in.mp4',
          outputPath: 'out.mp4',
          upscale: true,
          targetResolution: TargetResolution.r2k,
        );
        expect(cmd2k, contains('-preset faster'));
        expect(cmd2k, contains('-crf 17'));
        expect(cmd2k, contains('-tune film'));

        final cmd4k = FfmpegService.buildCommand(
          inputPath: 'in.mp4',
          outputPath: 'out.mp4',
          upscale: true,
          targetResolution: TargetResolution.r4k,
        );
        expect(cmd4k, contains('-preset faster'));
        expect(cmd4k, contains('-crf 17'));
      },
    );

    test('buildCommand enforces -fps_mode cfr with target fps', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: 'in.mp4',
        outputPath: 'out.mp4',
        modifyVisuals: true,
      );
      expect(cmd, contains('-fps_mode cfr'));
    });

    test('buildCommand includes -movflags +faststart for web playback', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: 'in.mp4',
        outputPath: 'out.mp4',
        modifyVisuals: true,
      );
      expect(cmd, contains('-movflags +faststart'));
    });

    test('buildCommand enforces BT.709 color primaries and range', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: 'in.mp4',
        outputPath: 'out.mp4',
        modifyVisuals: true,
      );
      expect(cmd, contains('-colorspace bt709'));
      expect(cmd, contains('-color_primaries bt709'));
      expect(cmd, contains('-color_trc bt709'));
      expect(cmd, contains('-color_range tv'));
    });

    test(
      'audio pipeline includes aresample, aformat, loudnorm, and 192k stereo',
      () {
        final cmd = FfmpegService.buildCommand(
          inputPath: 'in.mp4',
          outputPath: 'out.mp4',
          modifyAudio: true,
          enableDeepAntiFingerprint: false,
        );
        expect(cmd, contains('aresample=async=1'));
        expect(
          cmd,
          contains(
            'aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo',
          ),
        );
        expect(cmd, contains('loudnorm=I=-16:TP=-1.5:LRA=11'));
        expect(cmd, contains('-c:a aac -b:a 192k -ar 44100 -ac 2'));
      },
    );
  });

  group('Sprint 65 - StorageService & Auto-Pruning', () {
    test(
      'hasEnoughSpace returns true in non-Android or standard environment',
      () async {
        final ok = await StorageService.hasEnoughSpace();
        expect(ok, isTrue);
      },
    );

    test('cleanupPartialFile deletes targeted file safely', () {
      final tempDir = Directory.systemTemp.createTempSync('sprint65_test');
      final testFile = File('${tempDir.path}/partial_test.mp4')
        ..writeAsStringSync('dummy');
      expect(testFile.existsSync(), isTrue);

      StorageService.cleanupPartialFile(testFile.path);
      expect(testFile.existsSync(), isFalse);

      tempDir.deleteSync(recursive: true);
    });
  });

  group('Sprint 65 - Manual Sliders & Settings Persistence', () {
    test(
      'SettingsService persists and loads sharpening level correctly',
      () async {
        await SettingsService.setSharpeningLevel(1.5);
        final val = await SettingsService.getSharpeningLevel();
        expect(val, equals(1.5));
      },
    );

    test(
      'SettingsService persists and loads saturation level correctly',
      () async {
        await SettingsService.setSaturationLevel(1.2);
        final val = await SettingsService.getSaturationLevel();
        expect(val, equals(1.2));
      },
    );

    test(
      'SettingsService persists and loads thermal throttle toggle',
      () async {
        await SettingsService.setThermalThrottle(true);
        final val = await SettingsService.getThermalThrottle();
        expect(val, isTrue);
      },
    );

    test(
      'UniquifierProvider clamps sharpening and saturation sliders to valid ranges',
      () {
        final provider = UniquifierProvider();
        provider.setSharpeningLevel(3.0); // Above 2.0 max
        expect(provider.sharpeningLevel, equals(2.0));

        provider.setSharpeningLevel(0.1); // Below 0.2 min
        expect(provider.sharpeningLevel, equals(0.2));

        provider.setSaturationLevel(2.0); // Above 1.3 max
        expect(provider.saturationLevel, equals(1.3));

        provider.setSaturationLevel(0.5); // Below 0.8 min
        expect(provider.saturationLevel, equals(0.8));
      },
    );
  });

  group('Sprint 65 - Batch Queue Resilience', () {
    test(
      'cancelItem marks targeted item as cancelled without affecting others',
      () {
        final batch = BatchQueueProvider();
        batch.addItems([
          BatchVideoItem(
            id: '1',
            path: '1.mp4',
            name: 'v1.mp4',
            sizeBytes: 100,
          ),
          BatchVideoItem(
            id: '2',
            path: '2.mp4',
            name: 'v2.mp4',
            sizeBytes: 200,
          ),
          BatchVideoItem(
            id: '3',
            path: '3.mp4',
            name: 'v3.mp4',
            sizeBytes: 300,
          ),
        ]);

        expect(batch.items[1].isPending, isTrue);
        batch.cancelItem(1);

        expect(batch.items[0].isPending, isTrue);
        expect(batch.items[1].status, equals(BatchItemStatus.cancelled));
        expect(batch.items[2].isPending, isTrue);
      },
    );
  });
}
