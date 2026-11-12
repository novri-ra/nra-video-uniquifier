import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/core/utils/path_redactor.dart';

void main() {
  group('redactFileSystemPaths', () {
    test('redacts Android public storage paths', () {
      expect(
        redactFileSystemPaths('/storage/emulated/0/Movies/out.mp4'),
        '<external storage>/...',
      );
    });

    test('redacts /data paths while keeping the preceding text', () {
      expect(
        redactFileSystemPaths('cache=/data/user/0/pkg/cache/thumb.jpg'),
        'cache=<external storage>/...',
      );
    });

    test('redacts /sdcard paths and keeps trailing text', () {
      expect(
        redactFileSystemPaths('see /sdcard/DCIM/v.mp4 now'),
        'see <external storage>/... now',
      );
    });

    test('redacts Windows drive paths', () {
      expect(
        redactFileSystemPaths(r'C:\Users\Admin\v.mp4'),
        '<external storage>/...',
      );
    });

    test('leaves plain URLs unchanged', () {
      expect(
        redactFileSystemPaths('https://news.google.com/articles/abc'),
        'https://news.google.com/articles/abc',
      );
    });

    test('leaves URL segments that look like paths unchanged', () {
      expect(
        redactFileSystemPaths('https://example.com/data/foo'),
        'https://example.com/data/foo',
      );
    });

    test('redacts a path after a colon boundary', () {
      expect(
        redactFileSystemPaths('error: /data/local/tmp/ffmpeg exited'),
        'error: <external storage>/... exited',
      );
    });

    test('does not double-redact already redacted output', () {
      expect(
        redactFileSystemPaths('<external storage>/...'),
        '<external storage>/...',
      );
    });
  });
}
