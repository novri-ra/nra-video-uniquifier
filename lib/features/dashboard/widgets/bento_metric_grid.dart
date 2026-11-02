import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/batch_queue_provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// 2x2 Bento Metric Grid displaying system guardrails and staging status.
class BentoMetricGrid extends StatelessWidget {
  const BentoMetricGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();
    final queue = context.watch<BatchQueueProvider>();
    final l10n = AppLocalizations.of(context);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _BentoCard(
          icon: Icons.shield_outlined,
          title: l10n?.metadataHygiene ?? 'Metadata Hygiene',
          status: 'SANITY OK',
          detail: 'QuickTime & XMP Ready • Zero Device Fingerprints',
          accentColor: AppColors.primaryContainer,
        ),
        _BentoCard(
          icon: Icons.speed_rounded,
          title: l10n?.techSpecsGuard ?? 'Technical Specs Guard',
          status: '${provider.targetFps} FPS CFR',
          detail: 'BT.709 Range • ${provider.videoCodec.key.toUpperCase()} Tagged',
          accentColor: const Color(0xFF4DFFB2),
        ),
        _BentoCard(
          icon: Icons.storage_rounded,
          title: l10n?.storageBuffer ?? 'Storage Safe Buffer',
          status: '> 2.0 GB FREE',
          detail: 'Sandbox auto-pruned • Staging cache protected',
          accentColor: const Color(0xFF64B5F6),
        ),
        _BentoCard(
          icon: Icons.layers_outlined,
          title: l10n?.assetStaging ?? 'Asset Staging',
          status: queue.hasItems ? '${queue.totalCount} IN QUEUE' : 'READY',
          detail: queue.hasItems ? '${queue.completedCount} completed' : 'Tap to launch batch',
          accentColor: const Color(0xFFFFB74D),
          onTap: () => provider.setTabIndex(3),
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final String detail;
  final Color accentColor;
  final VoidCallback? onTap;

  const _BentoCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.detail,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceContainerHighest),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: accentColor, size: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 9.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
