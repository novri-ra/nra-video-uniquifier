import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing user bookmarks / read-later list for microstock news.
/// Strictly offline-first and persisted in SharedPreferences.
class UserNewsBookmarkService {
  static const String _bookmarkKey = 'nra_bookmarked_article_ids_v1';
  static final ValueNotifier<Set<String>> bookmarkedIdsNotifier =
      ValueNotifier<Set<String>>({});
  static bool _initialized = false;

  /// In-memory cache for synchronous checks and instant UI response.
  static final Set<String> _cachedIds = {};

  /// Initializes bookmark cache from persistent store.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_bookmarkKey) ?? [];
      _cachedIds.clear();
      _cachedIds.addAll(list);
      bookmarkedIdsNotifier.value = Set.unmodifiable(_cachedIds);
      _initialized = true;
    } catch (_) {
      // Offline fallback: keep in-memory set
      _initialized = true;
    }
  }

  /// Synchronously checks if article ID is bookmarked.
  static bool isBookmarkedSync(String articleId) {
    return _cachedIds.contains(articleId);
  }

  /// Asynchronously checks if an article ID is bookmarked.
  static Future<bool> isBookmarked(String articleId) async {
    await initialize();
    return _cachedIds.contains(articleId);
  }

  /// Toggles bookmark state for an article ID and persists changes.
  static Future<void> toggleBookmark(String articleId) async {
    await initialize();
    if (_cachedIds.contains(articleId)) {
      _cachedIds.remove(articleId);
    } else {
      _cachedIds.add(articleId);
    }
    bookmarkedIdsNotifier.value = Set.unmodifiable(_cachedIds);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_bookmarkKey, _cachedIds.toList());
    } catch (_) {}
  }

  /// Returns list of all bookmarked article IDs.
  static Future<List<String>> getBookmarkedIds() async {
    await initialize();
    return _cachedIds.toList();
  }

  @visibleForTesting
  static void resetForTesting() {
    _cachedIds.clear();
    bookmarkedIdsNotifier.value = {};
    _initialized = false;
  }
}
