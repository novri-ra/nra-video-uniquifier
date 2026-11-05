import 'package:flutter/material.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/microstock_news_service.dart';
import '../../../core/services/user_interest_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../../settings/screens/settings_screen.dart';
import '../services/user_news_bookmark_service.dart';
import '../widgets/microstock_news_card.dart';
import '../widgets/news_search_and_filter_bar.dart';

/// Screen presenting real-time & cached microstock intelligence, news, and guidelines.
class MicrostockNewsScreen extends StatefulWidget {
  const MicrostockNewsScreen({super.key});

  @override
  State<MicrostockNewsScreen> createState() => _MicrostockNewsScreenState();
}

class _MicrostockNewsScreenState extends State<MicrostockNewsScreen> {
  final ConnectivityService _connectivity = ConnectivityService.instance;
  List<MicrostockNewsArticle> _allArticles = [];
  String _selectedChip = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  String _syncStatusText = 'Syncing...';

  @override
  void initState() {
    super.initState();
    UserInterestService.initialize();
    UserNewsBookmarkService.initialize();
    UserNewsBookmarkService.bookmarkedIdsNotifier.addListener(
      _onBookmarksChanged,
    );
    _connectivity.isOnline.addListener(_onConnectivityChanged);
    _allArticles = MicrostockNewsService.getSeedArticles();
    _isLoading = false;
    _updateSyncStatus();
    Future.microtask(() => _loadNewsFeed(forceRefresh: false));
  }

  @override
  void dispose() {
    UserNewsBookmarkService.bookmarkedIdsNotifier.removeListener(
      _onBookmarksChanged,
    );
    _connectivity.isOnline.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onBookmarksChanged() {
    if (!mounted) return;
    if (_selectedChip == 'Saved') {
      setState(() {});
    }
  }

  void _onConnectivityChanged() {
    if (!mounted) return;
    if (_connectivity.isOnline.value) {
      _loadNewsFeed(forceRefresh: true);
    } else {
      _updateSyncStatus();
    }
  }

  Future<void> _loadNewsFeed({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final list = await MicrostockNewsService.loadNews(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _allArticles = list;
        _isLoading = false;
      });
      _updateSyncStatus();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _updateSyncStatus() {
    if (!mounted) return;
    final online = _connectivity.isOnline.value;
    setState(() {
      _syncStatusText = online ? 'LIVE • Auto-Synced' : 'Offline Cache Mode';
    });
  }

  List<String> get _dynamicCategories {
    final rawSet = <String>{};
    for (final a in _allArticles) {
      for (final t in a.tags) {
        final clean = t.replaceAll('#', '').trim();
        if (clean.toLowerCase().contains('shutter') ||
            clean.toLowerCase().contains('adobe') ||
            clean.toLowerCase().contains('freepik') ||
            clean.toLowerCase().contains('reddit')) {
          rawSet.add(clean);
        }
      }
    }
    for (final a in _allArticles) {
      if (a.category.isNotEmpty) {
        rawSet.add(a.category);
      }
    }
    for (final a in _allArticles) {
      for (final t in a.tags) {
        final cleanTag = t.replaceAll('#', '').trim();
        if (cleanTag.isNotEmpty) {
          rawSet.add(cleanTag);
        }
      }
    }
    return rawSet.toList();
  }

  void _openSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  List<MicrostockNewsArticle> get _filteredArticles {
    final bookmarkedIds = UserNewsBookmarkService.bookmarkedIdsNotifier.value;
    return _allArticles.where((article) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.summary.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.tags.any(
            (t) => t.toLowerCase().contains(_searchQuery.toLowerCase()),
          );

      if (_selectedChip == 'Saved') {
        return matchesSearch && bookmarkedIds.contains(article.id);
      }

      final matchesChip =
          _selectedChip == 'All' ||
          article.tags.any(
            (t) => t.toLowerCase().contains(_selectedChip.toLowerCase()),
          ) ||
          article.source.toLowerCase().contains(_selectedChip.toLowerCase()) ||
          article.category.toLowerCase().contains(
            _selectedChip.toLowerCase(),
          ) ||
          article.title.toLowerCase().contains(_selectedChip.toLowerCase());

      return matchesSearch && matchesChip;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final online = _connectivity.isOnline.value;
    final displayList = _filteredArticles;

    return Scaffold(
      appBar: TopAppBar(
        title: 'MICROSTOCK INTEL & NEWS',
        onSettingsTap: () => _openSettings(context),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNewsFeed(forceRefresh: true),
        color: isDark ? AppColors.mintSage : AppColors.forestDeep,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildSliverHeader(isDark, online),
            _buildSliverBody(isDark, online, displayList),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader(bool isDark, bool online) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeedHeader(
              syncStatusText: _syncStatusText,
              isOnline: online,
              isDark: isDark,
              onRefresh: () => _loadNewsFeed(forceRefresh: true),
            ),
            const SizedBox(height: 12),
            NewsSearchAndFilterBar(
              selectedChip: _selectedChip,
              categories: _dynamicCategories,
              isDark: isDark,
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              onChipSelected: (c) => setState(() => _selectedChip = c),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverBody(
    bool isDark,
    bool online,
    List<MicrostockNewsArticle> displayList,
  ) {
    if (_isLoading && _allArticles.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.mintSage : AppColors.forestDeep,
          ),
        ),
      );
    }
    if (displayList.isEmpty) {
      return _buildEmptyState(isDark);
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => MicrostockNewsCard(
            article: displayList[index],
            isDark: isDark,
            isOnline: online,
          ),
          childCount: displayList.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark
                  ? AppColors.outlineVariant
                  : AppColors.lightOutlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No articles or guides matching current filter',
              style: TextStyle(
                color: isDark
                    ? AppColors.onSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  final String syncStatusText;
  final bool isOnline;
  final bool isDark;
  final VoidCallback onRefresh;

  const _FeedHeader({
    required this.syncStatusText,
    required this.isOnline,
    required this.isDark,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subtitleColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Microstock Intel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  _StatusDot(isOnline: isOnline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      syncStatusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.sync_rounded, size: 20),
          color: isDark ? AppColors.mintSage : AppColors.forestDeep,
          tooltip: 'Sync News Feed',
          onPressed: onRefresh,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool isOnline;
  const _StatusDot({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.mintSage : AppColors.mustardOchre,
        shape: BoxShape.circle,
      ),
    );
  }
}
