import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/services/ffmpeg_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      expect(cmd, contains('-map_metadata -1'));
      expect(cmd, contains('-c copy'));
      expect(cmd, contains('"/path/output.mp4"'));
    });

    test('Audio tweak adds audio filter and encodes to aac', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        removeMetadata: true,
        modifyAudio: true,
        modifyVisuals: false,
        upscale1080p: false,
      );
      expect(cmd, contains('-c:v copy'));
      expect(cmd, contains('-af "asetrate=44100*1.005,aresample=44100" -c:a aac'));
      expect(cmd, contains('-map_metadata -1'));
    });

    test('Visual tweak & upscale adds video filter and libx264', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        removeMetadata: true,
        modifyAudio: false,
        modifyVisuals: true,
        upscale1080p: true,
      );
      expect(
        cmd,
        contains('-vf "crop=iw-4:ih-4,scale=1920:1080:flags=lanczos" -c:v libx264 -crf 23'),
      );
      expect(cmd, contains('-c:a copy'));
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
      expect(cmd, contains('-map_metadata -1'));
      expect(
        cmd,
        contains('-vf "crop=iw-4:ih-4,scale=1920:1080:flags=lanczos" -c:v libx264 -crf 23'),
      );
      expect(cmd, contains('-af "asetrate=44100*1.005,aresample=44100" -c:a aac'));
      expect(cmd, endsWith('"/path/out_unique.mp4"'));
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
