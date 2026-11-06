import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/shared/widgets/app_toast.dart';

void main() {
  testWidgets(
    'AppToast renders floating capsule toast with green accent for normal feedback',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppToast.show(
                    context,
                    message: 'Test notification sent to system tray',
                    isError: false,
                  );
                },
                child: const Text('Show Toast'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump(); // Start animation

      expect(
        find.text('Test notification sent to system tray'),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, equals(SnackBarBehavior.floating));
      expect(snackBar.backgroundColor, equals(const Color(0xFF161B22)));
      expect(snackBar.margin, isNotNull);

      // Verify accent color on icon and border
      final shape = snackBar.shape as RoundedRectangleBorder;
      expect(shape.side.color, equals(const Color(0xFF10B981)));
    },
  );

  testWidgets(
    'AppToast renders floating capsule toast with red accent for error/deletion feedback',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppToast.show(
                    context,
                    message: 'Video permanently deleted from device',
                    isError: true,
                  );
                },
                child: const Text('Show Error Toast'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error Toast'));
      await tester.pump();

      expect(
        find.text('Video permanently deleted from device'),
        findsOneWidget,
      );
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final shape = snackBar.shape as RoundedRectangleBorder;
      expect(shape.side.color, equals(const Color(0xFFEF4444)));
    },
  );
}
