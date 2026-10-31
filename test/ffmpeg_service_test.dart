import 'dart:io';
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
      expect(cmd, contains('highpass=f=60,lowpass=f=16000,equalizer=f=300:t=q:w=1.5:g=1.5,equalizer=f=3000:t=q:w=1.5:g=-1.5'));
      expect(cmd, contains('atempo='));
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
      expect(cmd, contains('equalizer=f=1000:t=q:w=1:g=0.5'));
      expect(cmd, contains('atempo='));
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
      expect(cmd, contains('setpts='));
      expect(cmd, contains('crop='));
      expect(cmd, contains('rotate='));
      expect(cmd, contains('scale=w=1920:h=1080:flags=lanczos+accurate_rnd'));
      // When upscale is enabled, destructive hqdn3d is bypassed to preserve clarity
      expect(cmd, isNot(contains('hqdn3d=1.5:1.5:4:4')));
      expect(cmd, contains('unsharp=3:3:0.6:3:3:0.0'));
      expect(cmd, isNot(contains('curves=preset=vintage')));
      expect(cmd, contains('eq=brightness='));
      expect(cmd, contains('noise=alls='));
      expect(cmd, isNot(contains('scale=trunc(iw/2)*2:trunc(ih/2)*2')));
      expect(cmd, contains('format=yuv420p'));
      expect(cmd, contains('-c:v libx264 -preset fast -crf 22'));
      expect(cmd, contains('-pix_fmt yuv420p'));
      expect(cmd, contains('-movflags +faststart'));
      expect(cmd, contains('-colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv'));
      expect(cmd, contains('-metadata make="Apple"'));
      expect(cmd, contains('-metadata model="iPhone 15 Pro Max"'));
      expect(cmd, contains('-metadata encoder="Apple QuickTime"'));
      expect(cmd, contains('-metadata:s:v:0 handler_name="Core Media Video"'));
      expect(cmd, contains('-metadata:s:a:0 handler_name="Core Media Audio"'));
      expect(cmd, contains('-c:a copy'));
      expect(cmd, contains('-r 29.'));

      // Strict sequential order checks: PTS -> Crop -> Rotate -> Unsharp -> EQ -> Noise -> Scale -> Format
      final ptsIdx = cmd.indexOf('setpts=');
      final cropIdx = cmd.indexOf('crop=');
      final rotIdx = cmd.indexOf('rotate=');
      final unsharpIdx = cmd.indexOf('unsharp=');
      final eqIdx = cmd.indexOf('eq=');
      final noiseIdx = cmd.indexOf('noise=');
      final scaleIdx = cmd.indexOf('scale=w=1920:h=1080:flags=lanczos+accurate_rnd');
      final formatIdx = cmd.indexOf('format=yuv420p');

      expect(ptsIdx, lessThan(cropIdx));
      expect(cropIdx, lessThan(rotIdx));
      expect(rotIdx, lessThan(unsharpIdx));
      expect(unsharpIdx, lessThan(eqIdx));
      expect(eqIdx, lessThan(noiseIdx));
      expect(noiseIdx, lessThan(scaleIdx));
      expect(scaleIdx, lessThan(formatIdx));
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
      expect(cmd, contains('crop=trunc(iw*'));
      expect(cmd, contains('rotate='));
      expect(cmd, contains('scale=w=2560:h=1440:flags=lanczos'));
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
      expect(cmd, contains('scale=w=3840:h=2160:flags=lanczos+accurate_rnd,unsharp=5:5:1.2:5:5:0.5'));
      expect(cmd, isNot(contains('hqdn3d=')));
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
      expect(cmd1080, contains('scale=w=1920:h=1080:flags=lanczos'));

      final cmd2k = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r2k,
        isPortrait: false,
      );
      expect(cmd2k, contains('scale=w=2560:h=1440:flags=lanczos'));

      final cmd4k = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r4k,
        isPortrait: false,
      );
      expect(cmd4k, contains('scale=w=3840:h=2160:flags=lanczos'));
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
      expect(cmd1080, contains('scale=w=1080:h=1920:flags=lanczos'));

      final cmd2k = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r2k,
        isPortrait: true,
      );
      expect(cmd2k, contains('scale=w=1440:h=2560:flags=lanczos'));

      final cmd4k = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale: true,
        targetResolution: TargetResolution.r4k,
        isPortrait: true,
      );
      expect(cmd4k, contains('scale=w=2160:h=3840:flags=lanczos'));
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
      expect(cmd, contains('atempo='));
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
      expect(cmd, contains('setpts='));
      expect(cmd, contains('atempo='));
      expect(cmd, endsWith('"/path/out_unique.mp4"'));
    });

    test('Macroblock parity & black corner defense: rotation enforces inner-box crop with even dimensions', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        upscale1080p: false,
        upscale: false,
        enableDeepAntiFingerprint: true,
      );
      expect(cmd, contains('ow=trunc(iw*0.96/2)*2'));
      expect(cmd, contains('oh=trunc(ih*0.96/2)*2'));
      expect(cmd, contains('c=none'));
      expect(cmd, isNot(contains('fillcolor=black')));
    });

    test('Audio-Visual timing alignment: tempo is pure reciprocal of speedFactor matching PTS without compound drift', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyVisuals: true,
        modifyAudio: true,
        enableDeepAntiFingerprint: true,
      );
      expect(cmd, contains('setpts='));
      expect(cmd, contains('atempo='));
      expect(cmd, isNot(contains('asetrate=')));
      expect(cmd, isNot(contains('aresample=')));
    });

    test('TikTok Evasion Test 1: 10 calls produce 10 different filter strings', () {
      final commands = <String>{};
      for (var i = 0; i < 10; i++) {
        final cmd = FfmpegService.buildCommand(
          inputPath: '/path/input.mp4',
          outputPath: '/path/output.mp4',
          modifyVisuals: true,
          enableDeepAntiFingerprint: true,
        );
        commands.add(cmd);
      }
      expect(commands.length, equals(10));
    });

    test('TikTok Evasion Test 2: A/V sync is exact (Video speed * Audio tempo = 1.0)', () {
      for (var i = 0; i < 20; i++) {
        final vars = VariationGenerator.generate();
        final product = vars.speedFactor * vars.audioTempo;
        expect((product - 1.0).abs(), lessThan(1e-9));
      }
    });

    test('TikTok Evasion Test 3: Color parameters never exceed +-0.01', () {
      final eqRegex = RegExp(r'eq=brightness=([-0-9.]+):contrast=([0-9.]+):saturation=([0-9.]+)');
      for (var i = 0; i < 20; i++) {
        final cmd = FfmpegService.buildCommand(
          inputPath: '/path/input.mp4',
          outputPath: '/path/output.mp4',
          modifyVisuals: true,
          enableDeepAntiFingerprint: true,
        );
        final match = eqRegex.firstMatch(cmd);
        expect(match, isNotNull);
        final brightness = double.parse(match!.group(1)!);
        final contrast = double.parse(match.group(2)!);
        final saturation = double.parse(match.group(3)!);

        expect(brightness, greaterThanOrEqualTo(-0.0101));
        expect(brightness, lessThanOrEqualTo(0.0101));
        expect((contrast - 1.0).abs(), lessThanOrEqualTo(0.0101));
        expect((saturation - 1.0).abs(), lessThanOrEqualTo(0.0101));
      }
    });

    test('TikTok Hardened Evasion Validation: crop >= 7%, rotation >= 0.6 deg, noise >= 3, speed factor <= 0.975, smartphone metadata', () {
      final cropRegex = RegExp(r'crop=trunc\(iw\*([0-9.]+)/2\)\*2:trunc\(ih\*([0-9.]+)/2\)\*2');
      final rotRegex = RegExp(r'rotate=([0-9.]+)\*PI/180');
      final noiseRegex = RegExp(r'noise=alls=([0-9]+):allf=t\+u');
      final ptsRegex = RegExp(r'setpts=([0-9.]+)\*PTS');

      for (var i = 0; i < 20; i++) {
        final vars = VariationGenerator.generate();
        expect(vars.cropPercent, greaterThanOrEqualTo(0.0699));
        expect(vars.cropPercent, lessThanOrEqualTo(0.0901));
        expect(vars.rotateAngle, greaterThanOrEqualTo(0.599));
        expect(vars.rotateAngle, lessThanOrEqualTo(0.901));
        expect(vars.noiseStrength, greaterThanOrEqualTo(3));
        expect(vars.noiseStrength, lessThanOrEqualTo(4));
        expect(vars.speedFactor, greaterThanOrEqualTo(0.9699));
        expect(vars.speedFactor, lessThanOrEqualTo(0.9751));
        expect(vars.outputFps, greaterThanOrEqualTo(29.79));
        expect(vars.outputFps, lessThanOrEqualTo(29.91));

        final cmd = FfmpegService.buildCommand(
          inputPath: '/path/input.mp4',
          outputPath: '/path/output.mp4',
          modifyVisuals: true,
          modifyAudio: true,
          enableDeepAntiFingerprint: true,
          variations: vars,
        );

        final cropMatch = cropRegex.firstMatch(cmd);
        expect(cropMatch, isNotNull);
        final keepRatio = double.parse(cropMatch!.group(1)!);
        expect(keepRatio, lessThanOrEqualTo(0.9301));
        expect(keepRatio, greaterThanOrEqualTo(0.9099));

        final rotMatch = rotRegex.firstMatch(cmd);
        expect(rotMatch, isNotNull);
        final rotAngle = double.parse(rotMatch!.group(1)!);
        expect(rotAngle, greaterThanOrEqualTo(0.599));

        final noiseMatch = noiseRegex.firstMatch(cmd);
        expect(noiseMatch, isNotNull);
        final noiseVal = int.parse(noiseMatch!.group(1)!);
        expect(noiseVal, greaterThanOrEqualTo(3));

        final ptsMatch = ptsRegex.firstMatch(cmd);
        expect(ptsMatch, isNotNull);
        final ptsVal = double.parse(ptsMatch!.group(1)!);
        expect(ptsVal, lessThanOrEqualTo(0.9751));

        expect(cmd, contains('-metadata make="Apple"'));
        expect(cmd, contains('-metadata model="iPhone 15 Pro Max"'));
        expect(cmd, contains('-metadata encoder="Apple QuickTime"'));
        expect(cmd, contains('-metadata:s:v:0 handler_name="Core Media Video"'));
        expect(cmd, contains('-metadata:s:a:0 handler_name="Core Media Audio"'));
        expect(cmd, contains('anoisesrc=d=7200:c=pink:a=0.0015'));
        expect(cmd, contains('-r 29.'));
      }
    });

    test('Blurred canvas frame generates dual-stream background blur and centered foreground overlay', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        enableBlurredCanvas: true,
        canvasScalePercent: 95.0,
        isPortrait: true,
      );
      expect(cmd, contains(r'[0:v]split=2[bg][fg];'));
      expect(cmd, contains(r'[bg]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=luma_radius=min(h\,w)/40:luma_power=2[blurred];'));
      expect(cmd, contains(r'[fg]scale=w=1026:h=1824:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[main];'));
      expect(cmd, contains(r'[blurred][main]overlay=(W-w)/2:(H-h)/2[outv];[outv]'));
      expect(cmd, contains('format=yuv420p'));

      final cmdLandscape = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        enableBlurredCanvas: true,
        canvasScalePercent: 95.0,
        isPortrait: false,
      );
      expect(cmdLandscape, contains(r'[bg]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=luma_radius=min(h\,w)/40:luma_power=2[blurred];'));
      expect(cmdLandscape, contains(r'[fg]scale=w=1824:h=1026:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[main];'));

      // Test 50% scale factor
      final cmd50 = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        enableBlurredCanvas: true,
        canvasScalePercent: 50.0,
        isPortrait: true,
      );
      expect(cmd50, contains(r'[fg]scale=w=540:h=960:force_original_aspect_ratio=decrease'));

      // Test 100% scale factor
      final cmd100 = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        enableBlurredCanvas: true,
        canvasScalePercent: 100.0,
        isPortrait: true,
      );
      expect(cmd100, contains(r'[fg]scale=w=1080:h=1920:force_original_aspect_ratio=decrease'));

      // Test 2K Portrait Canvas scaling
      final cmd2kCanvas = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        enableBlurredCanvas: true,
        targetResolution: TargetResolution.r2k,
        canvasScalePercent: 95.0,
        isPortrait: true,
      );
      expect(cmd2kCanvas, contains(r'[bg]scale=1440:2560:force_original_aspect_ratio=increase,crop=1440:2560,boxblur=luma_radius=min(h\,w)/40:luma_power=2[blurred];'));
      expect(cmd2kCanvas, contains(r'[fg]scale=w=1368:h=2432:force_original_aspect_ratio=decrease'));

      // Test 4K Portrait Canvas scaling
      final cmd4kCanvas = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        enableBlurredCanvas: true,
        targetResolution: TargetResolution.r4k,
        canvasScalePercent: 95.0,
        isPortrait: true,
      );
      expect(cmd4kCanvas, contains(r'[bg]scale=2160:3840:force_original_aspect_ratio=increase,crop=2160:3840,boxblur=luma_radius=min(h\,w)/40:luma_power=2[blurred];'));
      expect(cmd4kCanvas, contains(r'[fg]scale=w=2052:h=3648:force_original_aspect_ratio=decrease'));
    });

    test('Mute original audio ducks volume to near-zero for platform background music overlay', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        modifyAudio: true,
        muteOriginalAudio: true,
      );
      expect(cmd, contains('volume=0.01'));
      expect(cmd, contains('atempo='));
      expect(cmd, contains('-c:a aac -b:a 128k'));
      expect(cmd, isNot(contains('anoisesrc=')));
    });

    test('Advanced evasion: dynamic zoom, frame skip, chroma shift, and micro overlay inject expected filter syntax', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        enableDynamicZoom: true,
        enableFrameSkip: true,
        enableChromaShift: true,
        enableMicroOverlay: true,
        isPortrait: true,
      );
      expect(cmd, contains(r"zoompan=z='if(lte(zoom\,1.0)\,1.08\,max(1.001\,zoom-0.0015))'"));
      expect(cmd, contains('s=1080x1920:fps=30'));
      expect(cmd, contains('decimate=cycle=25'));
      expect(cmd, contains("curves=all='0/0 0.15/0.18 0.5/0.5 0.85/0.82 1/1'"));
      expect(cmd, contains('noise=alls=5:allf=t+u'));
    });

    test('All 15 modifiers enabled combined pipeline validation', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        removeMetadata: true,
        modifyAudio: true,
        modifyVisuals: true,
        upscale1080p: true,
        targetResolution: TargetResolution.r2k,
        videoCodec: VideoCodec.h265,
        enableEnhanceAndDenoise: true,
        enableDeepAntiFingerprint: true,
        enableHorizontalFlip: true,
        enableAggressiveAudio: true,
        enableAutoTrim: true,
        totalDurationMs: 5000,
        enableBlurredCanvas: true,
        muteOriginalAudio: true,
        enableDynamicZoom: true,
        enableMicroOverlay: true,
        enableFrameSkip: true,
        enableChromaShift: true,
        isPortrait: true,
      );

      // Verify presence of all key pipeline components
      expect(cmd, contains('-map_metadata -1')); // 1. removeMetadata
      expect(cmd, contains('-ss 0.5 -t 4.00')); // 2. autoTrim
      expect(cmd, contains(r'[0:v]split=2[bg][fg];')); // 3. blurredCanvas
      expect(cmd, contains(r"zoompan=z='if(lte(zoom\,1.0)\,1.08\,max(1.001\,zoom-0.0015))'")); // 4. dynamicZoom
      expect(cmd, contains('hflip')); // 5. horizontalFlip
      expect(cmd, contains('decimate=cycle=25')); // 6. frameSkip
      // 7. upscale active, so hqdn3d is bypassed to retain crisp textures
      expect(cmd, isNot(contains('hqdn3d=1.5:1.5:4:4')));
      expect(cmd, contains('unsharp=3:3:0.6:3:3:0.0')); // pre-scale edge sharpness
      expect(cmd, contains("curves=all='0/0 0.15/0.18 0.5/0.5 0.85/0.82 1/1'")); // 8. chromaShift
      expect(cmd, contains('noise=alls=')); // 9. modifyVisuals grain
      expect(cmd, contains('noise=alls=5:allf=t+u')); // 10. microOverlay
      expect(cmd, contains('format=yuv420p')); // color parity
      expect(cmd, contains('-c:v libx265')); // videoCodec
      expect(cmd, contains('-tag:v hvc1')); // hvc1 tag
      expect(cmd, contains('volume=0.01')); // 11. muteOriginalAudio / 12. modifyAudio
      expect(cmd, contains('atempo=')); // A/V sync tempo

      // Verify strict filter ordering: canvas -> spatial -> color/curves -> noise -> decimate -> format=yuv420p
      final idxCanvas = cmd.indexOf('overlay=');
      final idxZoom = cmd.indexOf('zoompan=');
      final idxCurves = cmd.indexOf('curves=');
      final idxNoise = cmd.indexOf('noise=alls=5');
      final idxDecimate = cmd.indexOf('decimate=cycle=25');
      final idxFormat = cmd.indexOf('format=yuv420p');

      expect(idxCanvas < idxZoom, isTrue, reason: 'Canvas must precede zoompan');
      expect(idxZoom < idxCurves, isTrue, reason: 'Spatial zoom must precede color curves');
      expect(idxCurves < idxNoise, isTrue, reason: 'Color curves must precede noise');
      expect(idxNoise < idxDecimate, isTrue, reason: 'Noise must precede decimate');
      expect(idxDecimate < idxFormat, isTrue, reason: 'Decimate must precede format=yuv420p');
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

    test('Scoped storage defense: stageInputFile stages file in temporary cache directory', () async {
      final tempDir = Directory.systemTemp.createTempSync('uniquifier_test_stage_');
      final sample = File('${tempDir.path}/test_source.mp4');
      await sample.writeAsString('video-bytes-data');

      final staged = await FfmpegService.stageInputFile(sample.path);
      expect(staged.existsSync(), isTrue);
      expect(staged.path, contains('staged_'));
      expect(staged.lengthSync(), equals(sample.lengthSync()));
    });

    test('D1-01 T1: probeMediaMeta returns zeros on probe failure without throwing', () async {
      final meta = await FfmpegService.probeMediaMeta('/nonexistent_file_path.mp4');
      expect(meta.durationMs, 0);
      expect(meta.width, 0);
      expect(meta.height, 0);
    });

    test('D1-01 T2: buildCommand respects auto-trim when totalDurationMs > 1500', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
        enableAutoTrim: true,
        totalDurationMs: 5000,
      );
      expect(cmd, contains('-ss 0.5 -t 4.00 -i "/input.mp4"'));
    });

    test('D1-02: buildCommand emits -hwaccel auto when enableHardwareAcceleration is true', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
        enableHardwareAcceleration: true,
      );
      expect(cmd, contains('-y -hwaccel auto -i "/input.mp4"'));
    });

    test('D5-01: RenderDiagnosticInfo flags 1216x2160 as truncated portrait and throws RenderIntegrityException', () {
      const diag = RenderDiagnosticInfo(path: '/test.mp4', width: 1216, height: 2160);
      expect(diag.isTruncatedPortrait, isTrue);
      expect(
        () {
          if (diag.isTruncatedPortrait) {
            throw const RenderIntegrityException('Output failed integrity: truncated or null dimensions');
          }
        },
        throwsA(isA<RenderIntegrityException>()),
      );
    });

    test('Evasion-vDNA: Sprint 61 anti-vDNA evasion pipeline enforces micro-trim, hflip, curves, zoompan, and canonical lock', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/sample.mp4',
        outputPath: '/out.mp4',
        enableAutoTrim: true,
        totalDurationMs: 6000,
        enableHorizontalFlip: true,
        enableDynamicZoom: true,
        enableChromaShift: true,
        enableEnhanceAndDenoise: true,
        enableDeepAntiFingerprint: true,
        upscale: true,
        targetResolution: TargetResolution.r1080p,
        isPortrait: true,
      );

      // Micro-trim first 0.5s to break first-frame vDNA hash
      expect(cmd, contains('-ss 0.5 -t 5.00'));
      // Invert geometry via hflip
      expect(cmd, contains('hflip'));
      // Dynamic zoompan
      expect(cmd, contains('zoompan='));
      // Non-linear color curves
      expect(cmd, contains("curves=all='0/0 0.15/0.18 0.5/0.5 0.85/0.82 1/1'"));
      // Terminal canonical scale and format lock
      expect(cmd, contains('scale=w=1080:h=1920:flags=lanczos+accurate_rnd,unsharp=5:5:1.2:5:5:0.5'));
      expect(cmd, contains('format=yuv420p'));
    });
  });
}
