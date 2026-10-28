import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/services/ffmpeg_service.dart';
import 'package:nra_video_uniquifier/core/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  group('FfmpegService command generator', () {
    test('Base command with metadata removal only', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        removeMetadata: true,
        modifyAudio: false,
        modifyVisuals: false,
        upscale1080p: false,
      );
      expect(cmd, contains('-y -i "/path/input.mp4"'));
      expect(cmd, contains('-map_metadata -1 -map_chapters -1 -bitexact'));
      expect(cmd, contains('-c copy'));
      expect(cmd, contains('"/path/output.mp4"'));
    });

    test('Audio tweak adds anti-fingerprint audio filters', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        removeMetadata: true,
        modifyAudio: true,
        modifyVisuals: false,
        upscale1080p: false,
      );
      expect(cmd, contains('-c:v copy'));
      expect(cmd, contains('atempo=1.015,asetrate=48000*1.01,aresample=48000,equalizer=f=1000:t=q:w=1:g=0.5'));
      expect(cmd, contains('-c:a aac -b:a 192k'));
      expect(cmd, contains('-map_metadata -1'));
    });

    test('Visual tweak & upscale adds anti-fingerprint video filters and libx264 veryfast (1080p)', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        removeMetadata: true,
        modifyAudio: false,
        modifyVisuals: true,
        upscale1080p: true,
        targetResolution: TargetResolution.r1080p,
      );
      expect(cmd, contains('setpts=0.9852*PTS'));
      expect(cmd, contains('crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2'));
      expect(cmd, contains('scale=w=-2:h=1080:flags=lanczos'));
      expect(cmd, contains('eq=contrast=1.02:brightness=0.01:saturation=1.03:gamma=0.98'));
      expect(cmd, contains('noise=alls=2:allf=t+u'));
      expect(cmd, contains('-c:v libx264 -preset veryfast -crf 22 -g 60 -keyint_min 30'));
      expect(cmd, contains('-c:a copy'));
    });

    test('Upscale to 2K dynamically maps scale filter to 1440p without clashing with crop', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r2k,
      );
      expect(cmd, contains('crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2'));
      expect(cmd, contains('scale=w=-2:h=1440:flags=lanczos'));
      final cropIdx = cmd.indexOf('crop=');
      final scaleIdx = cmd.indexOf('scale=');
      expect(cropIdx, lessThan(scaleIdx));
    });

    test('Upscale to 4K dynamically maps scale filter to 2160p', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r4k,
      );
      expect(cmd, contains('crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2'));
      expect(cmd, contains('scale=w=-2:h=2160:flags=lanczos'));
    });

    test('Full dynamic options combined', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/in.mov',
        outputPath: '/path/out_unique.mp4',
        removeMetadata: true,
        modifyAudio: true,
        modifyVisuals: true,
        upscale1080p: true,
      );
      expect(cmd, contains('-map_metadata -1 -map_chapters -1 -bitexact'));
      expect(cmd, contains('setpts=0.9852*PTS'));
      expect(cmd, contains('atempo=1.015'));
      expect(cmd, endsWith('"/path/out_unique.mp4"'));
    });

    test('generateOutputPath generates collision-free timestamp pattern in public dir', () async {
      final path1 = await FfmpegService.generateOutputPath('/some/dir/sample.mp4');
      await Future.delayed(const Duration(milliseconds: 5));
      final path2 = await FfmpegService.generateOutputPath('/some/dir/sample.mp4');

      expect(path1, contains('UQ_sample_'));
      expect(path1, endsWith('.mp4'));
      expect(path2, contains('UQ_sample_'));
      expect(path1, isNot(equals(path2)));
    });

    test('Throws exception if input video does not exist', () async {
      expect(
        () => FfmpegService.processVideo(inputPath: '/non/existent/video.mp4'),
        throwsA(isA<Exception>()),
      );
    });

    test('Cancel executes safely without throwing unhandled error', () async {
      await expectLater(FfmpegService.cancel(), completes);
    });
  });
}
