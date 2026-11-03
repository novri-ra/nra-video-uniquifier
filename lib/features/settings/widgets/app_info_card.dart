import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AppInfoCard extends StatelessWidget {
  const AppInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceContainerLowest : Colors.white;
    final borderColor = isDark
        ? AppColors.surfaceContainerHighest
        : AppColors.lightOutlineVariant;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(flex: 3, child: _AppInfoTitleColumn(isDark: isDark)),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: _AppInfoPrivacyBadge(
              isDark: isDark,
              borderColor: borderColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppInfoTitleColumn extends StatelessWidget {
  final bool isDark;
  const _AppInfoTitleColumn({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark
        ? AppColors.outline
        : AppColors.lightOnSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'NRA Video Uniquifier v2.0.0',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: titleColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Anti-Fingerprint Evasion Engine',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: subColor,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _AppInfoPrivacyBadge extends StatelessWidget {
  final bool isDark;
  final Color borderColor;
  const _AppInfoPrivacyBadge({required this.isDark, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final badgeBg = isDark
        ? AppColors.surfaceContainer
        : AppColors.hairlineBorder;
    final badgeColor = isDark ? AppColors.mintSage : AppColors.forestDeep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user, color: badgeColor, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'OFFLINE PRIVACY',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
