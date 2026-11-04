import 'dart:async';
import 'dart:convert';
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

  /// Browser User-Agent string simulating Chrome Android 14.
  static const String browserUserAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  static final _readMorePattern = RegExp(
    r'\[?\s*Read\s*More\.{0,3}\s*\]?|Continue\s+reading\.{0,3}|…\s*Read\s+more',
    caseSensitive: false,
  );

  /// Extract full article text and og:image from [url].
  /// Returns null if offline, timeout, or parse failure.
  static Future<ExtractedArticleContent?> extract(
    String url, {
    Duration timeout = const Duration(seconds: 8),
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

  /// Fetches HTML, following redirects and decoding Google News articles if necessary.
  static Future<String?> _fetchHtml(Uri uri, Duration timeout) async {
    if (customHttpGet != null) {
      return customHttpGet!(uri);
    }

    Uri targetUri = uri;

    // Check if URL is a Google News redirect/article URL
    if (_isGoogleNewsUrl(targetUri)) {
      final resolved = await _resolveGoogleNewsUrl(targetUri, timeout);
      if (resolved != null) {
        targetUri = resolved;
      }
    }

    final client = HttpClient()
      ..connectionTimeout = timeout
      ..userAgent = browserUserAgent
      ..autoUncompress = true;

    try {
      final request = await client.getUrl(targetUri).timeout(timeout);
      request.maxRedirects = 8;
      request.headers.set(
        HttpHeaders.acceptHeader,
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      );
      final response = await request.close().timeout(timeout);

      // Follow manual redirect if HttpClient didn't automatically catch 301/302
      if (response.isRedirect &&
          response.headers.value(HttpHeaders.locationHeader) != null) {
        final loc = response.headers.value(HttpHeaders.locationHeader)!;
        final redirectUri = targetUri.resolve(loc);
        client.close(force: true);
        return await _fetchHtml(redirectUri, timeout);
      }

      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      return body;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Checks if [uri] is a Google News link.
  static bool _isGoogleNewsUrl(Uri uri) {
    return uri.host.contains('news.google.com') &&
        (uri.path.contains('/articles/') || uri.path.contains('/read/'));
  }

  /// Extracts Google News article ID from the path.
  static String? _extractGoogleNewsArticleId(Uri uri) {
    final segments = uri.pathSegments;
    final idx = segments.indexOf('articles');
    if (idx != -1 && idx + 1 < segments.length) {
      return segments[idx + 1];
    }
    final readIdx = segments.indexOf('read');
    if (readIdx != -1 && readIdx + 1 < segments.length) {
      return segments[readIdx + 1];
    }
    return null;
  }

  /// Resolves Google News encoded URL using Google's batchexecute RPC.
  static Future<Uri?> _resolveGoogleNewsUrl(Uri uri, Duration timeout) async {
    final artId = _extractGoogleNewsArticleId(uri);
    if (artId == null || artId.isEmpty) return null;

    final client = HttpClient()
      ..connectionTimeout = timeout
      ..userAgent = browserUserAgent
      ..autoUncompress = true;

    try {
      // 1. Fetch splash page to extract data-n-a-sg and data-n-a-ts
      final splashUri = Uri.parse(
        'https://news.google.com/rss/articles/$artId?hl=en-US&gl=US&ceid=US:en',
      );
      final req1 = await client.getUrl(splashUri).timeout(timeout);
      req1.maxRedirects = 8;
      final res1 = await req1.close().timeout(timeout);
      if (res1.statusCode != 200) return null;
      final splashHtml = await res1.transform(utf8.decoder).join();

      final sgMatch = RegExp(r'data-n-a-sg="([^"]+)"').firstMatch(splashHtml);
      final tsMatch = RegExp(r'data-n-a-ts="([^"]+)"').firstMatch(splashHtml);

      if (sgMatch == null || tsMatch == null) return null;
      final sig = sgMatch.group(1)!;
      final ts = int.tryParse(tsMatch.group(1)!) ?? 0;

      // 2. Build batchexecute RPC request
      const ctx = [
        [
          'X',
          'X',
          ['X', 'X'],
          null,
          null,
          1,
          1,
          'US:en',
          null,
          1,
          null,
          null,
          null,
          null,
          null,
          0,
          1,
        ],
        'X',
        'X',
        1,
        [1, 1, 1],
        1,
        1,
        null,
        0,
        0,
        null,
        0,
      ];

      final inner = jsonEncode(['garturlreq', ctx, artId, ts, sig]);
      final envelope = [
        ['Fbv4je', inner, null, '1'],
      ];
      final reqBody =
          'f.req=${Uri.encodeQueryComponent(jsonEncode([envelope]))}';

      // 3. POST to batchexecute
      final batchUri = Uri.parse(
        'https://news.google.com/_/DotsSplashUi/data/batchexecute',
      );
      final req2 = await client.postUrl(batchUri).timeout(timeout);
      req2.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      );
      req2.write(reqBody);
      final res2 = await req2.close().timeout(timeout);
      if (res2.statusCode != 200) return null;
      final batchResp = await res2.transform(utf8.decoder).join();

      // 4. Parse decoded publisher URL from response
      // Structure: ["garturlres","https://...",1]
      final urlMatch = RegExp(
        r'\["garturlres",\s*"([^"]+)"',
      ).firstMatch(batchResp);
      if (urlMatch != null && urlMatch.group(1) != null) {
        final decodedUrl = urlMatch.group(1)!;
        return Uri.tryParse(decodedUrl);
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static const _clutterSelectors = [
    'script',
    'style',
    'noscript',
    'iframe',
    'form',
    'aside',
    '.advertisement',
    '.ad',
    '.ad-container',
    '.pixelmeter',
    '.pp-pixelmeter-widget',
    '.banners',
    '.banners-desktop',
    '.banners-below-header',
    '.affiliate-disclosure',
    '.social-share',
    '.sharedaddy',
    '.author-bio',
    '.comments',
    '.related-posts',
    '.post-meta',
    '.post-sharing',
    '.header-overlay-backdrop',
    'header',
    'footer',
    'nav',
  ];

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
    // Prioritize specific CMS containers before falling back to generic containers
    final container =
        document.querySelector('.post-full__text') ??
        document.querySelector('.post-full__content') ??
        document.querySelector('.post-content') ??
        document.querySelector('.entry-content') ??
        document.querySelector('.td-post-content') ??
        document.querySelector('.article-content') ??
        document.querySelector('.story-content') ??
        document.querySelector('article') ??
        document.querySelector('main') ??
        document.body;

    if (container == null) return null;

    // 3. Pre-cleaning: Remove clutter, advertisements, social widgets, and non-content tags
    for (final selector in _clutterSelectors) {
      final elements = container.querySelectorAll(selector);
      for (final el in elements) {
        el.remove();
      }
    }
    // Remove third-party ad scripts like freestar
    for (final el in container.querySelectorAll('script[src*="freestar"]')) {
      el.remove();
    }

    // 4. Extract narrative elements sequentially: p, h2, h3, h4, ul, ol, blockquote
    final narrativeBlocks = <String>[];
    final elements = container.querySelectorAll(
      'p, h2, h3, h4, ul, ol, blockquote',
    );

    for (final el in elements) {
      final tag = el.localName?.toLowerCase();
      if (tag == null) continue;

      if (tag == 'h2') {
        final text = el.text.trim();
        if (text.isNotEmpty) {
          narrativeBlocks.add('### $text');
        }
      } else if (tag == 'h3' || tag == 'h4') {
        final text = el.text.trim();
        if (text.isNotEmpty) {
          narrativeBlocks.add('**$text**');
        }
      } else if (tag == 'p') {
        // Exclude paragraphs that are nested inside blockquote/ul/ol (they are handled by parents)
        if (el.parent?.localName?.toLowerCase() == 'blockquote' ||
            el.parent?.localName?.toLowerCase() == 'li') {
          continue;
        }
        var text = el.text.trim();
        if (text.isEmpty) continue;

        // Clean boilerplate patterns
        text = text.replaceAll(_readMorePattern, '').trim();
        if (text.length > 20 &&
            !text.toLowerCase().contains('sign up for newsletter') &&
            !text.toLowerCase().contains('affiliate disclosure')) {
          narrativeBlocks.add(text);
        }
      } else if (tag == 'ul' || tag == 'ol') {
        final listItems = el.querySelectorAll('li');
        final items = <String>[];
        for (final li in listItems) {
          final liText = li.text.trim();
          if (liText.isNotEmpty) {
            items.add('• $liText');
          }
        }
        if (items.isNotEmpty) {
          narrativeBlocks.add(items.join('\n'));
        }
      } else if (tag == 'blockquote') {
        final quoteText = el.text.trim();
        if (quoteText.isNotEmpty) {
          narrativeBlocks.add('> $quoteText');
        }
      }
    }

    // Fallback: if container yielded no blocks, search entire document for <p>
    if (narrativeBlocks.isEmpty) {
      final paragraphs = document
          .querySelectorAll('p')
          .map((p) => p.text.trim())
          .where((t) => t.length > 20)
          .map((t) => t.replaceAll(_readMorePattern, '').trim())
          .where((t) => t.isNotEmpty)
          .toList();
      narrativeBlocks.addAll(paragraphs);
    }

    if (narrativeBlocks.isEmpty) return null;

    final fullText = narrativeBlocks.join('\n\n');

    return ExtractedArticleContent(paragraphs: fullText, heroImageUrl: ogImage);
  }
}
