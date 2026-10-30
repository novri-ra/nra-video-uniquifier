import 'package:flutter/material.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Configurable video codec selector card supporting H.264/AVC and H.265/HEVC rendering profiles.
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
    return Column(
      children: [
        _CodecTile(
          title: 'H.264 / AVC (TikTok Universal)',
          description: 'CRF 22 • Maximum compatibility across TikTok, Reels, & MediaCodec',
          badge: 'TIKTOK UNIVERSAL',
          badgeColor: AppColors.primaryContainer,
          isSelected: currentCodec == VideoCodec.h264,
          onTap: () => onSelect(VideoCodec.h264),
        ),
        const SizedBox(height: 8),
        _CodecTile(
          title: 'H.265 / HEVC (High Efficiency)',
          description: 'CRF 26 • ~40% higher compression efficiency with -tag:v hvc1',
          badge: 'HIGH EFFICIENCY',
          badgeColor: AppColors.secondary,
          isSelected: currentCodec == VideoCodec.h265,
          onTap: () => onSelect(VideoCodec.h265),
        ),
      ],
    );
  }
}

class _CodecTile extends StatelessWidget {
  final String title, description, badge;
  final Color badgeColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _CodecTile({
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHighest,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryContainer : AppColors.outline,
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
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
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
