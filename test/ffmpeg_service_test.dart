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

    test('Visual tweak & upscale adds anti-fingerprint video filters and libx264 veryfast', () {
      final cmd = FfmpegService.buildCommand(
        inputPath: '/path/input.mp4',
        outputPath: '/path/output.mp4',
        removeMetadata: true,
        modifyAudio: false,
        modifyVisuals: true,
        upscale1080p: true,
      );
      expect(cmd, contains('setpts=0.9852*PTS'));
      expect(cmd, contains('crop=trunc(iw*0.98/2)*2:trunc(ih*0.98/2)*2'));
      expect(cmd, contains('scale=1920:1080:flags=lanczos'));
      expect(cmd, contains('eq=contrast=1.02:brightness=0.01:saturation=1.03:gamma=0.98'));
      expect(cmd, contains('noise=alls=2:allf=t+u'));
      expect(cmd, contains('-c:v libx264 -preset veryfast -crf 22 -g 60 -keyint_min 30'));
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
      expect(cmd, contains('-map_metadata -1 -map_chapters -1 -bitexact'));
      expect(cmd, contains('setpts=0.9852*PTS'));
      expect(cmd, contains('atempo=1.015'));
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
