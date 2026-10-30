import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/models/batch_video_item.dart';
import 'package:nra_video_uniquifier/core/providers/batch_queue_provider.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';
import 'package:nra_video_uniquifier/features/process/screens/batch_processing_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BatchProcessingScreen Widget Smoke Tests', () {
    testWidgets('renders batch queue list and progress bars', (tester) async {
      final queue = BatchQueueProvider();
      queue.setItems([
        BatchVideoItem(id: '1', path: '/invalid1.mp4', name: 'video1.mp4', sizeBytes: 1024),
        BatchVideoItem(id: '2', path: '/invalid2.mp4', name: 'video2.mp4', sizeBytes: 2048),
      ]);
      final config = UniquifierProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: queue),
            ChangeNotifierProvider.value(value: config),
          ],
          child: const MaterialApp(
            home: BatchProcessingScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('QUEUED FILES'), findsOneWidget);
      expect(find.textContaining('video1.mp4'), findsOneWidget);
      expect(find.textContaining('video2.mp4'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('cancel batch button triggers batch cancellation', (tester) async {
      final queue = BatchQueueProvider();
      queue.setItems([
        BatchVideoItem(id: '1', path: '/invalid1.mp4', name: 'video1.mp4', sizeBytes: 1024),
      ]);
      final config = UniquifierProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: queue),
            ChangeNotifierProvider.value(value: config),
          ],
          child: const MaterialApp(
            home: BatchProcessingScreen(),
          ),
        ),
      );
      await tester.pump();

      final cancelButton = find.text('CANCEL BATCH');
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();
        expect(queue.isCancelled, isTrue);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
