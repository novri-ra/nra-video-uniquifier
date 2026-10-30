import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/services/media_scanner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('id.novrira.videouniquifier/media_scanner');
  final log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      if (methodCall.method == 'scanFile') return true;
      if (methodCall.method == 'openGallery') return true;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('MediaScannerService', () {
    test('scanFile executes method channel or completes safely on non-Android', () async {
      final res = await MediaScannerService.scanFile('/storage/emulated/0/Movies/Uniquifier/test.mp4');
      expect(res, isA<bool>());
    });

    test('openGallery executes method channel or completes safely on non-Android', () async {
      final res = await MediaScannerService.openGallery('/storage/emulated/0/Movies/Uniquifier/test.mp4');
      expect(res, isA<bool>());
    });
  });
}
