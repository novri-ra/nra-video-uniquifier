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

class _LiveIntelTickerCardState extends State<LiveIntelTickerCard> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final article = _topArticle;
    final title = article?.title ?? 'Adobe Stock Releases 2026 Visual Trend Forecast';
    final source = article?.source ?? 'Adobe Stock Brief';

    final bgColor = isDark ? const Color(0xFF1B1B2A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C42) : AppColors.lightOutlineVariant;
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);

    return InkWell(
      onTap: () => _navigateToIntelTab(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
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
        ),
        child: Row(
          children: [
            _PulsingLiveBadge(controller: _pulseController),
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
                        style: const TextStyle(
                          color: Color(0xFF6C5CE7),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• REKOMENDASI TERKINI',
                        style: TextStyle(
                          color: isDark ? AppColors.outline : const Color(0xFF9CA3AF),
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
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF6C5CE7)),
          ],
        ),
      ),
    );
  }
}

class _PulsingLiveBadge extends StatelessWidget {
  final AnimationController? controller;
  const _PulsingLiveBadge({required this.controller});

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
          SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFF10B981),
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
