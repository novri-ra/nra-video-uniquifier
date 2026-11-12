// IMPORTANT: the boundary group (^|[\s"(\[=,:;\\]) is what keeps URL
// segments intact. Without it, "https://x.com/data/foo" would be
// rewritten to "https://x.com<external storage>/..." because the
// matcher would find "/data/foo" mid-URL. Do not remove the boundary.
final RegExp _pathPattern = RegExp(
  r'(^|[\s"(\[=,:;\\])'
  r'((?:'
  r'[A-Za-z]:[\\/][^\s")\]<>|]*'
  r'|\/(?:storage|data|sdcard|mnt|system|proc|home)\/[^\s")\]<>|]*'
  r'))',
  caseSensitive: false,
);

/// Redacts known absolute filesystem paths from diagnostic strings while
/// leaving URLs intact. Preserves the boundary character before each path
/// so surrounding punctuation and spacing are not disturbed.
String redactFileSystemPaths(String text) {
  if (text.isEmpty) return text;
  return text.replaceAllMapped(
    _pathPattern,
    (m) => '${m.group(1)!}<external storage>/...',
  );
}
