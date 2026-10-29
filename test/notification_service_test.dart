import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService unit tests', () {
    test('init executes safely without throwing unhandled exceptions', () async {
      await expectLater(NotificationService.init(), completes);
    });

    test('requestPermission returns true or completes safely on non-Android', () async {
      final res = await NotificationService.requestPermission();
      expect(res, isTrue);
    });

    test('showProgressNotification completes safely without throwing on non-Android', () async {
      await expectLater(
        NotificationService.showProgressNotification(
          progress: 50,
          title: 'Testing',
          body: '50% complete',
          force: true,
        ),
        completes,
      );
    });

    test('cancelProgressNotification completes safely without throwing on non-Android', () async {
      await expectLater(
        NotificationService.cancelProgressNotification(),
        completes,
      );
    });

    test('showCompleteNotification completes safely without throwing on non-Android', () async {
      await expectLater(
        NotificationService.showCompleteNotification(
          title: 'Done',
          body: 'Success',
          success: true,
        ),
        completes,
      );
    });
  });
}
