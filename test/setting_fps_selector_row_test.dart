import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/shared/widgets/setting_fps_selector_row.dart';

void main() {
  testWidgets('SettingFpsSelectorRow renders labels and handles tap', (
    tester,
  ) async {
    int currentFps = 30;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SettingFpsSelectorRow(
                selectedFps: currentFps,
                onChanged: (newFps) => setState(() => currentFps = newFps),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Framerate Video (FPS)'), findsOneWidget);
    expect(find.text('24 FPS'), findsOneWidget);
    expect(find.text('30 FPS'), findsOneWidget);
    expect(find.text('60 FPS'), findsOneWidget);

    await tester.tap(find.text('60 FPS'));
    await tester.pumpAndSettle();
    expect(currentFps, equals(60));

    await tester.tap(find.text('24 FPS'));
    await tester.pumpAndSettle();
    expect(currentFps, equals(24));
  });
}
