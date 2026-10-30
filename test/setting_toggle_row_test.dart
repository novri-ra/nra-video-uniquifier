import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/shared/widgets/setting_toggle_row.dart';

void main() {
  testWidgets('SettingToggleRow renders titles, subtitles, and responds to switch and subtitle taps', (tester) async {
    bool switchVal = false;
    bool subtitleTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SettingToggleRow(
                icon: Icons.fingerprint,
                title: 'Test Toggle Title',
                subtitle: 'Test Monospace Subtitle',
                value: switchVal,
                onChanged: (val) {
                  setState(() => switchVal = val);
                },
                onTapSubtitle: () {
                  subtitleTapped = true;
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    expect(find.text('Test Toggle Title'), findsOneWidget);
    expect(find.text('Test Monospace Subtitle'), findsOneWidget);

    // Toggle switch
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(switchVal, isTrue);

    // Tap subtitle
    await tester.tap(find.text('Test Monospace Subtitle'));
    await tester.pumpAndSettle();
    expect(subtitleTapped, isTrue);
  });
}
