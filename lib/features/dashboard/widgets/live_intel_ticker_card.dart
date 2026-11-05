import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/services/microstock_news_service.dart';
import '../../../core/theme/app_colors.dart';

/// Live microstock industry intel ticker displaying today's top headline with a pulsing live indicator.
class LiveIntelTickerCard extends StatefulWidget {
  final bool animate;
  const LiveIntelTickerCard({super.key, this.animate = true});

  @override
  State<LiveIntelTickerCard> createState() => _LiveIntelTickerCardState();
}

class _LiveIntelTickerCardState extends State<LiveIntelTickerCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  MicrostockNewsArticle? _topArticle;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..forward();
    }
    _loadHeadline();
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  Future<void> _loadHeadline() async {
    try {
      final cached = await MicrostockNewsService.getCachedNews();
      if (!mounted) return;
      if (cached.isNotEmpty) {
        setState(() => _topArticle = cached.first);
      } else {
        final seed = MicrostockNewsService.getSeedArticles();
        if (mounted && seed.isNotEmpty) {
          setState(() => _topArticle = seed.first);
        }
      }
    } catch (_) {}
  }

  void _navigateToIntelTab(BuildContext context) {
    context.read<UniquifierProvider>().setTabIndex(1);
  }

  BoxDecoration _cardDecoration(bool isDark, Color bgColor, Color borderColor) {
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: borderColor),
      boxShadow: [
        if (!isDark)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
      ],
    );
  }

  Widget _buildContent(
    String source,
    String title,
    Color accentColor,
    Color titleColor,
    bool isDark,
  ) {
    return Row(
      children: [
        _PulsingLiveBadge(controller: _pulseController, isDark: isDark),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    source.toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '• LATEST RECOMMENDATIONS',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.outline
                          : AppColors.lightOnSurfaceVariant,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: accentColor),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final article = _topArticle;
    final title =
        article?.title ?? 'Adobe Stock Releases 2026 Visual Trend Forecast';
    final source = article?.source ?? 'Adobe Stock Brief';

    final bgColor = isDark ? AppColors.obsidianDark : Colors.white;
    final borderColor = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;
    final titleColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final accentColor = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return InkWell(
      onTap: () => _navigateToIntelTab(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: _cardDecoration(isDark, bgColor, borderColor),
        child: _buildContent(source, title, accentColor, titleColor, isDark),
      ),
    );
  }
}

class _PulsingLiveBadge extends StatelessWidget {
  final AnimationController? controller;
  final bool isDark;
  const _PulsingLiveBadge({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mintSage.withValues(alpha: isDark ? 0.15 : 0.22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.mintSage.withValues(alpha: 0.50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.mintSage),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: isDark ? AppColors.mintSage : AppColors.forestDeep,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );

    if (controller != null) {
      return FadeTransition(
        opacity: Tween<double>(begin: 0.5, end: 1.0).animate(controller!),
        child: badge,
      );
    }
    return badge;
  }
}
