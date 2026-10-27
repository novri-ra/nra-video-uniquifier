import 'package:flutter/material.dart';
import '../../../../core/services/history_service.dart';
import '../../../../core/theme/app_theme.dart';

class HistoryItemCard extends StatelessWidget {
  final VideoExportItem item;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const HistoryItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.surfaceContainerHighest),
        ),
        child: Row(
          children: [
            const _ThumbnailBadge(),
            const SizedBox(width: 12),
            Expanded(child: _ItemInfoColumn(item: item)),
            _ItemActionButtons(onShare: onShare, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailBadge extends StatelessWidget {
  const _ThumbnailBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Stack(
        children: [
          const Center(child: Icon(Icons.videocam, color: AppColors.outline, size: 24)),
          Positioned(
            top: 3,
            left: 3,
            child: Icon(
              Icons.check_circle,
              color: AppColors.primaryContainer.withValues(alpha: 0.9),
              size: 13,
            ),
          ),
          Positioned(
            bottom: 3,
            right: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
                border: Border.all(color: AppColors.surfaceContainerHighest),
              ),
              child: const Text('MP4', style: TextStyle(color: AppColors.onSurface, fontSize: 8, fontFamily: 'monospace')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemInfoColumn extends StatelessWidget {
  final VideoExportItem item;
  const _ItemInfoColumn({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.fileName,
          style: const TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${item.formattedDate} • ${item.formattedSize}',
          style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.primaryContainer),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                'READY',
                style: TextStyle(
                  color: AppColors.primaryContainer,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'H.264 • MODIFIED',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 9, fontFamily: 'monospace'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ItemActionButtons extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _ItemActionButtons({required this.onShare, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.share, size: 16),
          color: AppColors.onSurface,
          tooltip: 'Share',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: AppColors.surfaceContainerHighest),
            ),
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            fixedSize: const Size(32, 32),
          ),
          onPressed: onShare,
        ),
        const SizedBox(width: 6),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 16),
          color: AppColors.error,
          tooltip: 'Delete',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: AppColors.surfaceContainerHighest),
            ),
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            fixedSize: const Size(32, 32),
          ),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
