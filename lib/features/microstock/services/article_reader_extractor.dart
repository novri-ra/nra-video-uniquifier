import 'dart:async';
import 'dart:io';
import 'package:html/parser.dart' as html_parser;

/// Extracted article content from on-demand web scraping.
class ExtractedArticleContent {
  final String paragraphs;
  final String? heroImageUrl;

  const ExtractedArticleContent({required this.paragraphs, this.heroImageUrl});
}

/// On-demand article content extractor using package:html DOM parsing.
/// Offline-first: returns null on timeout, network error, or invalid URL.
class ArticleReaderExtractor {
  /// Testability hook — override to inject mock HTML responses.
  static Future<String?> Function(Uri uri)? customHttpGet;

  static final _readMorePattern = RegExp(
    r'\[?\s*Read\s*More\.{0,3}\s*\]?|Continue\s+reading\.{0,3}|…\s*Read\s+more',
    caseSensitive: false,
  );

  /// Extract full article text and og:image from [url].
  /// Returns null if offline, timeout, or parse failure.
  static Future<ExtractedArticleContent?> extract(
    String url, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return null;

    try {
      final html = await _fetchHtml(uri, timeout);
      if (html == null || html.isEmpty) return null;
      return _parseHtml(html);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _fetchHtml(Uri uri, Duration timeout) async {
    if (customHttpGet != null) {
      return customHttpGet!(uri);
    }
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..userAgent =
          'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 Chrome/120.0';
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != 200) return null;
      final body = await response.transform(SystemEncoding().decoder).join();
      return body;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static ExtractedArticleContent? _parseHtml(String html) {
    final document = html_parser.parse(html);

    // 1. Extract og:image or twitter:image
    final ogImage =
        document
            .querySelector('meta[property="og:image"]')
            ?.attributes['content'] ??
        document
            .querySelector('meta[name="twitter:image"]')
            ?.attributes['content'];

    // 2. Find main content container
    final container =
        document.querySelector('article') ??
        document.querySelector('.entry-content') ??
        document.querySelector('.post-content') ??
        document.querySelector('.article-content') ??
        document.querySelector('main') ??
        document.body;

    if (container == null) return null;

    // 3. Extract meaningful paragraphs (> 25 chars)
    final paragraphs = container
        .querySelectorAll('p')
        .map((p) => p.text.trim())
        .where((t) => t.length > 25)
        .map((t) => t.replaceAll(_readMorePattern, '').trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) return null;

    final fullText = paragraphs.join('\n\n');

    return ExtractedArticleContent(paragraphs: fullText, heroImageUrl: ogImage);
  }
}
