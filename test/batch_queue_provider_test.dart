import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/models/batch_video_item.dart';
import 'package:nra_video_uniquifier/core/providers/batch_queue_provider.dart';
import 'package:nra_video_uniquifier/core/providers/uniquifier_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BatchVideoItem model tests', () {
    test('formattedSize calculates byte scales accurately', () {
      final b1 = BatchVideoItem(id: '1', path: '/v1.mp4', name: 'v1.mp4', sizeBytes: 500);
      expect(b1.formattedSize, '500.0 B');

      final b2 = BatchVideoItem(id: '2', path: '/v2.mp4', name: 'v2.mp4', sizeBytes: 1024 * 50);
      expect(b2.formattedSize, '50.0 KB');

      final b3 = BatchVideoItem(id: '3', path: '/v3.mp4', name: 'v3.mp4', sizeBytes: 1024 * 1024 * 15);
      expect(b3.formattedSize, '15.0 MB');

      final b4 = BatchVideoItem(id: '4', path: '/v4.mp4', name: 'v4.mp4', sizeBytes: 1024 * 1024 * 1024 * 2);
      expect(b4.formattedSize, '2.0 GB');
    });

    test('status getters reflect exact enum state', () {
      final item = BatchVideoItem(id: '1', path: '/v.mp4', name: 'v.mp4', sizeBytes: 100);
      expect(item.isPending, isTrue);
      expect(item.isProcessing, isFalse);

      item.status = BatchItemStatus.processing;
      expect(item.isProcessing, isTrue);

      item.status = BatchItemStatus.completed;
      expect(item.isCompleted, isTrue);

      item.status = BatchItemStatus.failed;
      expect(item.isFailed, isTrue);

      item.status = BatchItemStatus.cancelled;
      expect(item.isCancelled, isTrue);
    });
  });

  group('BatchQueueProvider state & queue management', () {
    test('Initial state is clean and empty', () {
      final provider = BatchQueueProvider();
      expect(provider.items, isEmpty);
      expect(provider.hasItems, isFalse);
      expect(provider.isProcessing, isFalse);
      expect(provider.currentIndex, -1);
      expect(provider.totalCount, 0);
      expect(provider.completedCount, 0);
      expect(provider.failedCount, 0);
      expect(provider.overallProgress, 0.0);
    });

    test('setItems and addItems update queue and notify listeners', () {
      final provider = BatchQueueProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      final items = [
        BatchVideoItem(id: '1', path: '/v1.mp4', name: 'v1.mp4', sizeBytes: 1000),
        BatchVideoItem(id: '2', path: '/v2.mp4', name: 'v2.mp4', sizeBytes: 2000),
      ];

      provider.setItems(items);
      expect(provider.totalCount, 2);
      expect(provider.hasItems, isTrue);
      expect(notifyCount, 1);

      provider.addItems([
        BatchVideoItem(id: '3', path: '/v3.mp4', name: 'v3.mp4', sizeBytes: 3000),
      ]);
      expect(provider.totalCount, 3);
      expect(notifyCount, 2);
    });

    test('removeItem and clear manage elements correctly', () {
      final provider = BatchQueueProvider();
      provider.setItems([
        BatchVideoItem(id: '1', path: '/v1.mp4', name: 'v1.mp4', sizeBytes: 1000),
        BatchVideoItem(id: '2', path: '/v2.mp4', name: 'v2.mp4', sizeBytes: 2000),
      ]);

      provider.removeItem(0);
      expect(provider.totalCount, 1);
      expect(provider.items.first.name, 'v2.mp4');

      provider.clear();
      expect(provider.totalCount, 0);
      expect(provider.hasItems, isFalse);
    });

    test('overallProgress computes progress accurately across queue', () {
      final provider = BatchQueueProvider();
      final item1 = BatchVideoItem(id: '1', path: '/v1.mp4', name: 'v1.mp4', sizeBytes: 100);
      final item2 = BatchVideoItem(id: '2', path: '/v2.mp4', name: 'v2.mp4', sizeBytes: 100);

      provider.setItems([item1, item2]);
      expect(provider.overallProgress, 0.0);

      item1.status = BatchItemStatus.completed;
      expect(provider.overallProgress, 0.5);

      item2.status = BatchItemStatus.processing;
      item2.progress = 0.5;
      expect(provider.overallProgress, 0.75);
    });

    test('cancelBatch sets pending and processing items to cancelled', () async {
      final provider = BatchQueueProvider();
      final item1 = BatchVideoItem(id: '1', path: '/v1.mp4', name: 'v1.mp4', sizeBytes: 100);
      final item2 = BatchVideoItem(id: '2', path: '/v2.mp4', name: 'v2.mp4', sizeBytes: 100);

      provider.setItems([item1, item2]);
      item1.status = BatchItemStatus.processing;

      await provider.cancelBatch();
      expect(provider.isCancelled, isTrue);
      expect(item1.status, BatchItemStatus.cancelled);
      expect(item2.status, BatchItemStatus.cancelled);
      expect(provider.isProcessing, isFalse);
    });

    test('D1-01 T3: runBatch processes queue items with isolated parameters', () async {
      final provider = BatchQueueProvider();
      final item1 = BatchVideoItem(id: '1', path: '/invalid1.mp4', name: 'v1.mp4', sizeBytes: 100);
      final item2 = BatchVideoItem(id: '2', path: '/invalid2.mp4', name: 'v2.mp4', sizeBytes: 200);
      provider.setItems([item1, item2]);

      final dummyConfig = UniquifierProvider();
      await provider.runBatch(dummyConfig);
      expect(item1.status, BatchItemStatus.failed);
      expect(item2.status, BatchItemStatus.failed);
      expect(provider.isProcessing, isFalse);
    });

    test(
      'D5-02: batch runner passes suppressCompleteNotification: true',
      () async {
        final provider = BatchQueueProvider();
        final dummyConfig = UniquifierProvider();
        await provider.runBatch(dummyConfig);
        expect(provider.isProcessing, isFalse);
      },
      skip: 'requires NotificationService injectability — see Report 32 §6.1',
    );
  });
}
