import 'package:flutter/material.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/microstock_news_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/microstock_news_card.dart';

/// Screen presenting real-time & cached microstock intelligence, news, and guidelines.
class MicrostockNewsScreen extends StatefulWidget {
  const MicrostockNewsScreen({super.key});

  @override
  State<MicrostockNewsScreen> createState() => _MicrostockNewsScreenState();
}

class _MicrostockNewsScreenState extends State<MicrostockNewsScreen> {
  final ConnectivityService _connectivity = ConnectivityService.instance;
  List<MicrostockNewsArticle> _articles = [];
  bool _isLoading = true;
  String _syncStatusText = 'Syncing...';

  @override
  void initState() {
    super.initState();
    _connectivity.isOnline.addListener(_onConnectivityChanged);
    _articles = MicrostockNewsService.getSeedArticles();
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
        _articles = list;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final online = _connectivity.isOnline.value;

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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _FeedHeader(
                  syncStatusText: _syncStatusText,
                  isOnline: online,
                  isDark: isDark,
                  onRefresh: () => _loadNewsFeed(forceRefresh: true),
                ),
              ),
            ),
            if (_isLoading && _articles.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return MicrostockNewsCard(
                        article: _articles[index],
                        isDark: isDark,
                        isOnline: online,
                      );
                    },
                    childCount: _articles.length,
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
    final statusColor = isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.surfaceContainerHighest
              : AppColors.lightOutlineVariant,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMMERCIAL PLATFORM FEED',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        syncStatusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: const Color(0xFF6C5CE7),
            tooltip: 'Reload Feed',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}
