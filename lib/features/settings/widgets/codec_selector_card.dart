import 'package:flutter/material.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Configurable video codec selector card. H.264/AVC is permanently locked as
/// the software stability engine; H.265/HEVC is disabled.
class CodecSelectorCard extends StatelessWidget {
  final VideoCodec currentCodec;
  final ValueChanged<VideoCodec> onSelect;

  const CodecSelectorCard({
    super.key,
    required this.currentCodec,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBadge = isDark
        ? AppColors.primaryContainer
        : AppColors.lightPrimary;

    return Column(
      children: [
        _CodecTile(
          title: 'H.264 / AVC (TikTok Universal)',
          description:
              'CRF 18 • Preset fast • Studio-grade software encoding engine',
          badge: 'STABILITY PRIORITY',
          badgeColor: primaryBadge,
          isSelected: true,
          isDark: isDark,
          onTap: () => onSelect(VideoCodec.h264),
        ),
        const SizedBox(height: 8),
        _CodecTile(
          title: 'H.265 / HEVC (High Efficiency)',
          description: 'Disabled to guarantee 100% stability (software H.264)',
          badge: 'DISABLED (STABILITY PRIORITY)',
          badgeColor: AppColors.outline,
          isSelected: false,
          isDark: isDark,
          onTap: null,
        ),
      ],
    );
  }
}

class _CodecTile extends StatelessWidget {
  final String title, description, badge;
  final Color badgeColor;
  final bool isSelected, isDark;
  final VoidCallback? onTap;

  const _CodecTile({
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark
        ? AppColors.surfaceContainerHigh
        : AppColors.lightSurfaceContainer;
    final inactiveBg = isDark ? AppColors.obsidianDark : AppColors.white;
    final activeBorder = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final inactiveBorder = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;
    final isEnabled = onTap != null;
    final textColor = !isEnabled
        ? AppColors.outline
        : (isDark ? AppColors.onSurface : AppColors.lightOnSurface);
    final descColor = !isEnabled
        ? AppColors.outline
        : (isDark
              ? AppColors.onSurfaceVariant
              : AppColors.lightOnSurfaceVariant);
    final iconColor = !isEnabled
        ? AppColors.outline
        : (isSelected
              ? (isDark ? AppColors.mintSage : AppColors.forestDeep)
              : AppColors.outline);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeBorder : inactiveBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isDark && !isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: descColor, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
