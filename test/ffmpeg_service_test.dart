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

    test('Audio tweak adds enhanced audio spectrum when deep anti-fingerprint enabled', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        removeMetadata: true,
        modifyAudio: true,
        modifyVisuals: false,
        upscale1080p: false,
        enableDeepAntiFingerprint: true,
      );
      expect(cmd, contains('-c:v copy'));
      expect(cmd, contains('atempo=1.015,asetrate=48000*1.01,aresample=48000,highpass=f=60,lowpass=f=16000,equalizer=f=1200:t=q:w=1:g=1'));
      expect(cmd, contains('-c:a aac -b:a 192k'));
      expect(cmd, contains('-map_metadata -1'));
    });

    test('Audio tweak falls back to standard EQ when deep anti-fingerprint disabled', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        removeMetadata: true,
        modifyAudio: true,
        modifyVisuals: false,
        upscale1080p: false,
        enableDeepAntiFingerprint: false,
      );
      expect(cmd, contains('atempo=1.015,asetrate=48000*1.01,aresample=48000,equalizer=f=1000:t=q:w=1:g=0.5'));
    });

    test('Visual tweak & upscale enforces strict filtergraph pipeline order and 8M bitrate', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        removeMetadata: true,
        modifyAudio: false,
        modifyVisuals: true,
        upscale1080p: true,
        targetResolution: TargetResolution.r1080p,
        enableEnhanceAndDenoise: true,
        enableDeepAntiFingerprint: true,
      );
      // Filter graph presence checks
      expect(cmd, contains('setpts=0.9852*PTS'));
      expect(cmd, contains('crop=trunc(iw*0.95/2)*2:trunc(ih*0.95/2)*2'));
      expect(cmd, contains('rotate=0.4*PI/180:ow=rotw(0.4*PI/180):oh=roth(0.4*PI/180):fillcolor=black'));
      expect(cmd, contains('scale=w=-2:h=1080:flags=lanczos'));
      expect(cmd, contains('hqdn3d=1.5:1.5:4:4'));
      expect(cmd, contains('unsharp=3:3:0.6:3:3:0.0'));
      expect(cmd, contains('eq=contrast=1.02:brightness=0.01:saturation=1.03:gamma=0.98'));
      expect(cmd, contains('noise=alls=2:allf=t+u'));
      expect(cmd, contains('-c:v libx264 -preset veryfast -crf 19 -b:v 8M -g 60 -keyint_min 30'));
      expect(cmd, contains('-c:a copy'));

      // Strict sequential order checks: PTS -> Crop -> Rotate -> Scale -> Denoise -> Unsharp -> EQ -> Noise
      final ptsIdx = cmd.indexOf('setpts=');
      final cropIdx = cmd.indexOf('crop=');
      final rotIdx = cmd.indexOf('rotate=');
      final scaleIdx = cmd.indexOf('scale=');
      final denoiseIdx = cmd.indexOf('hqdn3d=');
      final unsharpIdx = cmd.indexOf('unsharp=');
      final eqIdx = cmd.indexOf('eq=');
      final noiseIdx = cmd.indexOf('noise=');

      expect(ptsIdx, lessThan(cropIdx));
      expect(cropIdx, lessThan(rotIdx));
      expect(rotIdx, lessThan(scaleIdx));
      expect(scaleIdx, lessThan(denoiseIdx));
      expect(denoiseIdx, lessThan(unsharpIdx));
      expect(unsharpIdx, lessThan(eqIdx));
      expect(eqIdx, lessThan(noiseIdx));
    });

    test('Upscale to 2K dynamically maps scale filter to 1440p with deep evasion', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r2k,
        enableDeepAntiFingerprint: true,
      );
      expect(cmd, contains('crop=trunc(iw*0.95/2)*2:trunc(ih*0.95/2)*2'));
      expect(cmd, contains('rotate=0.4*PI/180'));
      expect(cmd, contains('scale=w=-2:h=1440:flags=lanczos'));
    });

    test('Upscale to 4K dynamically maps scale filter to 2160p with standard crop when deep evasion off', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r4k,
        enableDeepAntiFingerprint: false,
        enableEnhanceAndDenoise: false,
      );
      expect(cmd, contains('crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2'));
      expect(cmd, isNot(contains('rotate=')));
      expect(cmd, contains('scale=w=-2:h=2160:flags=lanczos'));
      expect(cmd, isNot(contains('hqdn3d=')));
      expect(cmd, isNot(contains('unsharp=')));
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
