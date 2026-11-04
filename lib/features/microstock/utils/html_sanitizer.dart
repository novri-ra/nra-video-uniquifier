/// Utility for sanitizing HTML entities, stripping raw HTML tags, and removing feed remnants.
class HtmlSanitizer {
  /// Cleans raw HTML tags, decodes HTML entities, and strips residual feed URLs.
  static String clean(String input) {
    if (input.isEmpty) return '';

    // 1. If wrapped in CDATA or <content:encoded>, extract inner content first
    final contentRegex = RegExp(
      r'<content(?::encoded)?>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?<\/content(?::encoded)?>',
      dotAll: true,
      caseSensitive: false,
    );
    final match = contentRegex.firstMatch(input);
    var text = match != null ? match.group(1) ?? '' : input;

    // 2. Normalize structural break tags into newlines
    text = text
        .replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<\/p>', caseSensitive: false), '\n\n')
        .replaceAll(
          RegExp(r'<\/(?:div|li|tr|h[1-6])>', caseSensitive: false),
          '\n',
        );

    // 3. First decode pass for HTML entities (converts &lt;a href=...&gt; into <a href=...>)
    text = _decodeEntities(text);

    // 4. Strip all HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // 5. Second decode pass in case of nested/double-encoded entities (e.g. &amp;quot;)
    text = _decodeEntities(text);

    // 6. Strip Google News RSS link remnants and boilerplate
    text = text
        .replaceAll(
          RegExp(
            r'https?:\/\/(?:news\.google\.com|www\.google\.com)\S*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'View Full [Cc]overage on Google News', caseSensitive: false),
          '',
        );

    // 7. Clean up whitespace: normalize spaces & tabs, cap consecutive newlines at 2
    text = text
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n[ \t]+'), '\n')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return text;
  }

  static String _decodeEntities(String text) {
    var result = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', '/')
        .replaceAll('&#47;', '/')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '…')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®');

    // Decode numeric decimal entities: &#123;
    result = result.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1)!);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });

    // Decode numeric hex entities: &#x1f;
    result = result.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
      final code = int.tryParse(m.group(1)!, radix: 16);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });

    return result;
  }
}
