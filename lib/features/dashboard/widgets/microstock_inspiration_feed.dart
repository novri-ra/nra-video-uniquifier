import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../helpers/seasonal_event_helper.dart';

/// Horizontal scroll feed for commercial microstock trends with interactive clipboard chips.
class MicrostockInspirationFeed extends StatelessWidget {
  const MicrostockInspirationFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = SeasonalEventHelper.getSeasonalWindowInfo();
    final headerColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);
    final subColor = isDark ? AppColors.outline : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              (l10n?.inspirationTitle ?? '${info.quarterLabel} COMMERCIAL TRENDS').toUpperCase(),
              style: TextStyle(
                color: headerColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              'TAP CHIP TO COPY TAG',
              style: TextStyle(
                color: subColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: info.upcomingTrends.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _TrendCard(
              trend: info.upcomingTrends[i],
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  final TrendTopic trend;
  final bool isDark;
  const _TrendCard({required this.trend, required this.isDark});

  void _copyTag(BuildContext context, String tag) {
    Clipboard.setData(ClipboardData(text: tag));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $tag to clipboard'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final descColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);
    const accentColor = Color(0xFF6C5CE7);

    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                trend.category,
                style: const TextStyle(
                  color: accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trend.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                trend.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: descColor,
                  fontSize: 9.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: trend.chips.map((chip) {
                return _InteractiveKeywordChip(
                  tag: chip,
                  isDark: isDark,
                  onTap: () => _copyTag(context, chip),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveKeywordChip extends StatelessWidget {
  final String tag;
  final bool isDark;
  final VoidCallback onTap;

  const _InteractiveKeywordChip({
    required this.tag,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipBg = isDark ? AppColors.surfaceContainer : const Color(0xFFF3F4F6);
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final textColor = isDark ? AppColors.primaryContainer : const Color(0xFF6C5CE7);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: chipBg,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tag,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.copy_rounded, size: 9, color: textColor.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
