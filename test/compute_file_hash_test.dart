import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nra_video_uniquifier/features/process/screens/success_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nra_hash_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  File writeFile(String name, List<int> bytes) {
    final file = File('${tempDir.path}${Platform.pathSeparator}$name');
    file.writeAsBytesSync(bytes);
    return file;
  }

  String referenceHash(List<int> bytes) {
    final hex = sha256.convert(bytes).toString().toUpperCase();
    return '0x${hex.substring(0, 4)}..${hex.substring(hex.length - 4)} '
        '(VERIFIED)';
  }

  test('returns UNAVAILABLE for a nonexistent file', () async {
    final missing = File(
      '${tempDir.path}${Platform.pathSeparator}does_not_exist.mp4',
    );
    expect(
      await SuccessScreen.computeFileHash(missing.path),
      '0x0000..0000 (UNAVAILABLE)',
    );
  });

  test('returns a VERIFIED short hash for a small file', () async {
    final file = writeFile('small.mp4', utf8.encode('hello nra'));
    final hash = await SuccessScreen.computeFileHash(file.path);
    expect(
      hash,
      matches(RegExp(r'^0x[0-9A-F]{4}\.\.[0-9A-F]{4} \(VERIFIED\)$')),
    );
  });

  test('is deterministic for the same file', () async {
    final file = writeFile('stable.mp4', utf8.encode('stable content'));
    final first = await SuccessScreen.computeFileHash(file.path);
    final second = await SuccessScreen.computeFileHash(file.path);
    expect(first, second);
  });

  test('differs for two different files', () async {
    final a = writeFile('a.mp4', utf8.encode('content a'));
    final b = writeFile('b.mp4', utf8.encode('content b'));
    final hashA = await SuccessScreen.computeFileHash(a.path);
    final hashB = await SuccessScreen.computeFileHash(b.path);
    expect(hashA, isNot(hashB));
  });

  test('streaming hash matches the one-shot reference on ~1 MB', () async {
    final bytes = List<int>.generate(1024 * 1024, (i) => (i * 31 + 7) % 256);
    final file = writeFile('large.mp4', bytes);

    // Full-digest cross-check: the production streaming idiom must equal the
    // one-shot converter over the same bytes.
    final streamedDigest = await file.openRead().transform(sha256).first;
    expect(streamedDigest.toString(), sha256.convert(bytes).toString());

    // And the user-visible (truncated) value must match the reference form.
    final streamed = await SuccessScreen.computeFileHash(file.path);
    expect(streamed, referenceHash(bytes));
  });
}
