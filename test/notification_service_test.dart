import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/services/notification_service.dart';

void main() {
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  TestWidgetsFlutterBinding.ensureInitialized();

  const localNotificationsChannel = MethodChannel('dexterous.com/flutter/local_notifications');
  const permissionChannel = MethodChannel('flutter.baseflow.com/permissions/methods');

  final capturedNotificationsCalls = <MethodCall>[];
  final capturedPermissionCalls = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    NotificationService.testOverride = true;
    NotificationService.initialized = false;
    capturedNotificationsCalls.clear();
    capturedPermissionCalls.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localNotificationsChannel, (MethodCall call) async {
      capturedNotificationsCalls.add(call);
      if (call.method == 'initialize') return true;
      if (call.method == 'show') return null;
      if (call.method == 'cancel') return null;
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (MethodCall call) async {
      capturedPermissionCalls.add(call);
      if (call.method == 'checkPermissionStatus') return 1; // PermissionStatus.granted
      if (call.method == 'requestPermissions') return <int, int>{13: 1};
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    NotificationService.testOverride = null;
    NotificationService.initialized = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localNotificationsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, null);
  });

  group('NotificationService unit tests with real MethodChannel assertions', () {
    test('init invokes initialize on local notifications channel', () async {
      await NotificationService.init();

      expect(capturedNotificationsCalls.any((call) => call.method == 'initialize'), isTrue);
      final initCall = capturedNotificationsCalls.firstWhere((call) => call.method == 'initialize');
      expect(initCall.arguments, isNotNull);
    });

    test('requestPermission invokes checkPermissionStatus on permission channel and returns true', () async {
      final res = await NotificationService.requestPermission();

      expect(res, isTrue);
      expect(capturedPermissionCalls.any((call) => call.method == 'checkPermissionStatus'), isTrue);
    });

    test('showProgressNotification invokes show with ongoing progress payload', () async {
      await NotificationService.showProgressNotification(
        progress: 50,
        title: 'Testing Progress',
        body: '50% complete',
        force: true,
      );

      final showCalls = capturedNotificationsCalls.where((call) => call.method == 'show').toList();
      expect(showCalls.isNotEmpty, isTrue, reason: 'showProgressNotification must invoke show on channel');
      final call = showCalls.first;
      final args = Map<String, dynamic>.from(call.arguments as Map);
      expect(args['id'], equals(NotificationService.progressNotificationId));
      expect(args['title'], equals('Testing Progress'));
      expect(args['body'], equals('50% complete'));
      final specifics = Map<String, dynamic>.from(args['platformSpecifics'] as Map);
      expect(specifics['showProgress'], isTrue);
      expect(specifics['progress'], equals(50));
      expect(specifics['ongoing'], isTrue);
    });

    test('cancelProgressNotification invokes cancel with progressNotificationId', () async {
      await NotificationService.cancelProgressNotification();

      final cancelCalls = capturedNotificationsCalls.where((call) => call.method == 'cancel').toList();
      expect(cancelCalls.isNotEmpty, isTrue, reason: 'cancelProgressNotification must invoke cancel on channel');
      final call = cancelCalls.first;
      if (call.arguments is Map) {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        expect(args['id'], equals(NotificationService.progressNotificationId));
      } else {
        expect(call.arguments, equals(NotificationService.progressNotificationId));
      }
    });

    test('showCompleteNotification cancels ongoing progress and invokes show with high importance', () async {
      await NotificationService.showCompleteNotification(
        title: 'Processing Done',
        body: 'Video exported successfully',
        success: true,
      );

      // Verify cancel was invoked first for ongoing progress
      expect(capturedNotificationsCalls.any((call) => call.method == 'cancel'), isTrue);

      // Verify show was invoked with complete notification payload
      final showCalls = capturedNotificationsCalls.where((call) => call.method == 'show').toList();
      expect(showCalls.isNotEmpty, isTrue);
      final completeCall = showCalls.last;
      final args = Map<String, dynamic>.from(completeCall.arguments as Map);
      expect(args['id'], equals(NotificationService.completeNotificationId));
      expect(args['title'], equals('Processing Done'));
      expect(args['body'], equals('Video exported successfully'));
      final specifics = Map<String, dynamic>.from(args['platformSpecifics'] as Map);
      expect(specifics['playSound'], isTrue);
      expect(specifics['channelId'], equals(NotificationService.completeChannelId));
    });
  });
}
