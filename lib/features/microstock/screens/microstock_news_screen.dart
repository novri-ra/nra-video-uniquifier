import 'package:flutter/material.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/microstock_news_service.dart';
import '../../../core/services/user_interest_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../../settings/screens/settings_screen.dart';
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
    _connectivity.isOnline.addListener(_onConnectivityChanged);
    _allArticles = MicrostockNewsService.getSeedArticles();
    _isLoading = false;
    _updateSyncStatus();
    Future.microtask(() => _loadNewsFeed(forceRefresh: false));
  }

  @override
  void dispose() {
    _connectivity.isOnline.removeListener(_onConnectivityChanged);
    super.dispose();
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
    setState(() => _isLoading = true);
    try {
      final list = await MicrostockNewsService.loadNews(forceRefresh: forceRefresh);
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
    final online = _connectivity.isOnline.value;
    setState(() {
      _syncStatusText = online ? 'Updated just now' : 'Offline Cache Mode';
    });
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  List<MicrostockNewsArticle> get _filteredArticles {
    return _allArticles.where((article) {
      final matchesSearch = _searchQuery.isEmpty ||
          article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.summary.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesChip = _selectedChip == 'All' ||
          article.tags.any((t) => t.toLowerCase().contains(_selectedChip.toLowerCase())) ||
          article.source.toLowerCase().contains(_selectedChip.toLowerCase()) ||
          article.category.toLowerCase().contains(_selectedChip.toLowerCase()) ||
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
        color: const Color(0xFF6C5CE7),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
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
                      isDark: isDark,
                      onSearchChanged: (q) => setState(() => _searchQuery = q),
                      onChipSelected: (c) => setState(() => _selectedChip = c),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading && _allArticles.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                ),
              )
            else if (displayList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada berita atau panduan sesuai filter',
                        style: TextStyle(
                          color: isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return MicrostockNewsCard(
                        article: displayList[index],
                        isDark: isDark,
                        isOnline: online,
                      );
                    },
                    childCount: displayList.length,
                  ),
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
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final subtitleColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF6B7280);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Microstock Intel',
              style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                _StatusDot(isOnline: isOnline),
                const SizedBox(width: 6),
                Text(
                  syncStatusText,
                  style: TextStyle(color: subtitleColor, fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.sync_rounded, size: 20),
          color: const Color(0xFF6C5CE7),
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
        color: isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        shape: BoxShape.circle,
      ),
    );
  }
}
