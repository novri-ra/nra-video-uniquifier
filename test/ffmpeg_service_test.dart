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
      expect(cmd, contains('atempo=1.0256,highpass=f=60,lowpass=f=16000,equalizer=f=300:t=q:w=1.5:g=1.5,equalizer=f=3000:t=q:w=1.5:g=-1.5'));
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
      expect(cmd, contains('atempo=1.0256,equalizer=f=1000:t=q:w=1:g=0.5'));
    });

    test('Visual tweak & upscale enforces strict filtergraph pipeline order and YUV format', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        removeMetadata: true,
        modifyAudio: false,
        modifyVisuals: true,
        upscale1080p: true,
        targetResolution: TargetResolution.r1080p,
        videoCodec: VideoCodec.h264,
        enableEnhanceAndDenoise: true,
        enableDeepAntiFingerprint: true,
      );
      // Filter graph presence checks
      expect(cmd, contains('setpts=0.975*PTS'));
      expect(cmd, contains('crop=trunc(iw*0.92/2)*2:trunc(ih*0.92/2)*2:trunc(iw*0.04/2)*2:trunc(ih*0.04/2)*2'));
      expect(cmd, contains('rotate=0.8*PI/180:ow=trunc(rotw(0.8*PI/180)/2)*2:oh=trunc(roth(0.8*PI/180)/2)*2:fillcolor=black'));
      expect(cmd, contains('scale=w=-2:h=1080:flags=lanczos'));
      expect(cmd, contains('hqdn3d=1.5:1.5:4:4'));
      expect(cmd, contains('unsharp=3:3:0.6:3:3:0.0'));
      expect(cmd, isNot(contains('curves=preset=vintage')));
      expect(cmd, contains('eq=contrast=1.04:brightness=0.01:saturation=1.05:gamma=0.98'));
      expect(cmd, contains('noise=alls=4:allf=t+u'));
      expect(cmd, contains('format=yuv420p'));
      expect(cmd, contains('-c:v libx264 -preset fast -crf 22'));
      expect(cmd, contains('-pix_fmt yuv420p'));
      expect(cmd, contains('-movflags +faststart'));
      expect(cmd, contains('-colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv'));
      expect(cmd, contains('-metadata make="Apple" -metadata model="iPhone 15 Pro"'));
      expect(cmd, contains('-c:a copy'));

      // Strict sequential order checks: PTS -> Crop -> Rotate -> Scale -> Denoise -> Unsharp -> EQ -> Noise -> Format
      final ptsIdx = cmd.indexOf('setpts=');
      final cropIdx = cmd.indexOf('crop=');
      final rotIdx = cmd.indexOf('rotate=');
      final scaleIdx = cmd.indexOf('scale=');
      final denoiseIdx = cmd.indexOf('hqdn3d=');
      final unsharpIdx = cmd.indexOf('unsharp=');
      final eqIdx = cmd.indexOf('eq=');
      final noiseIdx = cmd.indexOf('noise=');
      final formatIdx = cmd.indexOf('format=yuv420p');

      expect(ptsIdx, lessThan(cropIdx));
      expect(cropIdx, lessThan(rotIdx));
      expect(rotIdx, lessThan(scaleIdx));
      expect(scaleIdx, lessThan(denoiseIdx));
      expect(denoiseIdx, lessThan(unsharpIdx));
      expect(unsharpIdx, lessThan(eqIdx));
      expect(eqIdx, lessThan(noiseIdx));
      expect(noiseIdx, lessThan(formatIdx));
    });

    test('Video codec engine: H.264 outputs libx264 crf 22, H.265 outputs libx265 crf 26 tag hvc1', () {
      final cmdH264 = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        videoCodec: VideoCodec.h264,
      );
      expect(cmdH264, contains('-c:v libx264 -preset fast -crf 22'));
      expect(cmdH264, contains('-pix_fmt yuv420p'));
      expect(cmdH264, contains('-movflags +faststart'));
      expect(cmdH264, contains('-colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv'));
      expect(cmdH264, isNot(contains('curves=preset=vintage')));

      final cmdH265 = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        videoCodec: VideoCodec.h265,
      );
      expect(cmdH265, contains('-c:v libx265 -preset fast -crf 26 -tag:v hvc1'));
      expect(cmdH265, contains('-pix_fmt yuv420p'));
      expect(cmdH265, contains('-movflags +faststart'));
      expect(cmdH265, contains('-colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv'));
      expect(cmdH265, isNot(contains('curves=preset=vintage')));
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
      expect(cmd, contains('crop=trunc(iw*0.92/2)*2:trunc(ih*0.92/2)*2:trunc(iw*0.04/2)*2:trunc(ih*0.04/2)*2'));
      expect(cmd, contains('rotate=0.8*PI/180'));
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

    test('Orientation-aware scaling: Landscape preserves horizontal dimensions', () {
      final cmd1080 = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r1080p,
        isPortrait: false,
      );
      expect(cmd1080, contains('scale=w=-2:h=1080:flags=lanczos'));

      final cmd2k = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r2k,
        isPortrait: false,
      );
      expect(cmd2k, contains('scale=w=-2:h=1440:flags=lanczos'));

      final cmd4k = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r4k,
        isPortrait: false,
      );
      expect(cmd4k, contains('scale=w=-2:h=2160:flags=lanczos'));
    });

    test('Orientation-aware scaling: Portrait enforces true vertical 1080p, 2K, and 4K dimensions', () {
      final cmd1080 = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r1080p,
        isPortrait: true,
      );
      expect(cmd1080, contains('scale=w=1080:h=-2:flags=lanczos'));

      final cmd2k = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r2k,
        isPortrait: true,
      );
      expect(cmd2k, contains('scale=w=1440:h=-2:flags=lanczos'));

      final cmd4k = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r4k,
        isPortrait: true,
      );
      expect(cmd4k, contains('scale=w=2160:h=-2:flags=lanczos'));
    });

    test('RenderDiagnosticInfo correctly evaluates orientation, true 4K, and truncation status', () {
      const portrait4k = RenderDiagnosticInfo(
        path: '/movies/UQ_video.mp4',
        width: 2160,
        height: 3840,
        videoCodec: 'H264',
        videoProfile: 'High',
        videoBitrate: '8000000',
        audioCodec: 'AAC',
        audioSampleRate: '48000',
        audioChannels: 2,
        audioBitrate: '192000',
        durationMs: 5000,
        fileSizeBytes: 5242880,
      );
      expect(portrait4k.isPortrait, isTrue);
      expect(portrait4k.isTrue4kPortrait, isTrue);
      expect(portrait4k.isTruncatedPortrait, isFalse);
      expect(portrait4k.summary, contains('True 4K Portrait (2160x3840)'));

      const truncatedPortrait = RenderDiagnosticInfo(
        path: '/movies/UQ_truncated.mp4',
        width: 1216,
        height: 2160,
      );
      expect(truncatedPortrait.isPortrait, isTrue);
      expect(truncatedPortrait.isTrue4kPortrait, isFalse);
      expect(truncatedPortrait.isTruncatedPortrait, isTrue);
      expect(truncatedPortrait.summary, contains('Truncated Portrait (~1216x2160)'));

      const landscape4k = RenderDiagnosticInfo(
        path: '/movies/UQ_landscape.mp4',
        width: 3840,
        height: 2160,
      );
      expect(landscape4k.isPortrait, isFalse);
      expect(landscape4k.isTrue4kPortrait, isFalse);
      expect(landscape4k.isTruncatedPortrait, isFalse);
    });

    test('Horizontal flip injects hflip in spatial stage', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        enableHorizontalFlip: true,
      );
      expect(cmd, contains('hflip'));
      final rotIdx = cmd.indexOf('rotate=');
      final flipIdx = cmd.indexOf('hflip');
      expect(rotIdx, lessThan(flipIdx));
    });

    test('Aggressive audio masking injects pink noise mixing via amix', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyAudio: true,
        enableAggressiveAudio: true,
      );
      expect(cmd, contains('anoisesrc=d=7200:c=pink:a=0.003[noise]'));
      expect(cmd, contains('[a0][noise]amix=inputs=2:duration=first[out]'));
      expect(cmd, contains('atempo=1.0256'));
      expect(cmd, contains('equalizer=f=300:t=q:w=1.5:g=1.5,equalizer=f=3000:t=q:w=1.5:g=-1.5'));
    });

    test('Auto-trim injects seek and duration limit when totalDurationMs > 1500', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        enableAutoTrim: true,
        totalDurationMs: 5000,
      );
      expect(cmd, contains('-ss 0.5 -t 4.00 -i "/path/input.mp4"'));
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
      expect(cmd, contains('setpts=0.975*PTS'));
      expect(cmd, contains('atempo=1.0256'));
      expect(cmd, endsWith('"/path/out_unique.mp4"'));
    });

    test('Macroblock parity: rotation strictly enforces even dimensions without upscale', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale1080p: false,
        upscale: false,
        enableDeepAntiFingerprint: true,
      );
      expect(cmd, contains('ow=trunc(rotw(0.8*PI/180)/2)*2:oh=trunc(roth(0.8*PI/180)/2)*2'));
    });

    test('Audio-Visual timing alignment: tempo is pure 1.0256 matching 0.975*PTS without compound drift', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        modifyAudio: true,
        enableDeepAntiFingerprint: true,
      );
      expect(cmd, contains('setpts=0.975*PTS'));
      expect(cmd, contains('atempo=1.0256'));
      expect(cmd, isNot(contains('asetrate=')));
      expect(cmd, isNot(contains('aresample=')));
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

    test('SEC-01: command generator escapes double quotes in input and output paths', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/video"with"quotes.mp4',
        outputPath: '/path/out"with"quotes.mp4',
        removeMetadata: false,
        modifyAudio: false,
        modifyVisuals: false,
      );
      expect(cmd, contains(r'-i "/path/video\"with\"quotes.mp4"'));
      expect(cmd, contains(r'"/path/out\"with\"quotes.mp4"'));
    });
  });
}
