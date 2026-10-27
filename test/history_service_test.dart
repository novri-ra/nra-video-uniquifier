import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/services/history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoExportItem model', () {
    test('formattedSize calculates byte scales accurately', () {
      final file = File('/dummy/test.mp4');
      final now = DateTime.now();

      final bItem = VideoExportItem(file: file, fileName: 'test.mp4', bytes: 500, modified: now);
      expect(bItem.formattedSize, equals('500 B'));

      final kbItem = VideoExportItem(file: file, fileName: 'test.mp4', bytes: 2048, modified: now);
      expect(kbItem.formattedSize, equals('2.0 KB'));

      final mbItem = VideoExportItem(file: file, fileName: 'test.mp4', bytes: 10485760, modified: now);
      expect(mbItem.formattedSize, equals('10.0 MB'));

      final gbItem = VideoExportItem(file: file, fileName: 'test.mp4', bytes: 1610612736, modified: now);
      expect(gbItem.formattedSize, equals('1.5 GB'));
    });

    test('formattedDate distinguishes today from past dates', () {
      final file = File('/dummy/test.mp4');
      final now = DateTime.now();
      final todayItem = VideoExportItem(file: file, fileName: 'test.mp4', bytes: 100, modified: now);
      expect(todayItem.formattedDate, startsWith('Today, '));

      final past = DateTime(2025, 1, 15, 10, 30);
      final pastItem = VideoExportItem(file: file, fileName: 'test.mp4', bytes: 100, modified: past);
      expect(pastItem.formattedDate, equals('2025-01-15 10:30'));
    });
  });

  group('HistoryService logic', () {
    test('formatTotalSize handles empty and scaled collections', () {
      expect(HistoryService.formatTotalSize([]), equals('0.0 KB'));

      final file = File('/dummy/test.mp4');
      final now = DateTime.now();
      final items = [
        VideoExportItem(file: file, fileName: 'a.mp4', bytes: 5242880, modified: now), // 5 MB
        VideoExportItem(file: file, fileName: 'b.mp4', bytes: 5242880, modified: now), // 5 MB
      ];
      expect(HistoryService.formatTotalSize(items), equals('10.0 MB'));
    });

    test('scanDirectory finds and sorts .mp4 files while skipping others', () async {
      final tempDir = await Directory.systemTemp.createTemp('uniquifier_test_');
      try {
        File('${tempDir.path}/video1.mp4').writeAsStringSync('dummy content 1');
        File('${tempDir.path}/video2.MP4').writeAsStringSync('dummy content 2');
        File('${tempDir.path}/notes.txt').writeAsStringSync('text content');

        final seen = <String>{};
        final results = await HistoryService.scanDirectory(tempDir, seen);

        expect(results.length, equals(2));
        final names = results.map((e) => e.fileName).toList();
        expect(names, contains('video1.mp4'));
        expect(names, contains('video2.MP4'));
        expect(names, isNot(contains('notes.txt')));
      } finally {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      }
    });

    test('deleteItem deletes existing file and returns true; false for missing', () async {
      final tempFile = File('${Directory.systemTemp.path}/uniquifier_delete_test.tmp')
        ..writeAsStringSync('temp');
      expect(await tempFile.exists(), isTrue);

      final deleted = await HistoryService.deleteItem(tempFile);
      expect(deleted, isTrue);
      expect(await tempFile.exists(), isFalse);

      final missingDeleted = await HistoryService.deleteItem(tempFile);
      expect(missingDeleted, isFalse);
    });
  });
}
