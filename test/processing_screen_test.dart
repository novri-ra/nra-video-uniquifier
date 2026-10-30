import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';
import 'package:nra_video_uniquifier/features/process/screens/processing_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProcessingScreen Widget Smoke Tests', () {
    testWidgets('renders progress radar and stage tracker', (tester) async {
      final provider = UniquifierProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: ProcessingScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Processing video...'), findsOneWidget);
      expect(find.text('Cancel Processing'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap cancel button dismisses screen safely', (tester) async {
      final provider = UniquifierProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: ProcessingScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final cancelButton = find.text('Cancel Processing');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
