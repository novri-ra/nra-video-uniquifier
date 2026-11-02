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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(6),
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
            _ThumbnailBadge(isDark: isDark),
            const SizedBox(width: 12),
            Expanded(child: _ItemInfoColumn(item: item, isDark: isDark)),
            _ItemActionButtons(onShare: onShare, onDelete: onDelete, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailBadge extends StatelessWidget {
  final bool isDark;
  const _ThumbnailBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final thumbBg = isDark ? AppColors.surfaceContainerLowest : const Color(0xFFF3F4F6);
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final iconColor = isDark ? AppColors.outline : const Color(0xFF6C5CE7);
    final checkColor = isDark ? AppColors.primaryContainer : const Color(0xFF10B981);

    return Container(
      width: 72,
      height: 52,
      decoration: BoxDecoration(
        color: thumbBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Center(child: Icon(Icons.videocam, color: iconColor, size: 24)),
          Positioned(
            top: 3,
            left: 3,
            child: Icon(Icons.check_circle, color: checkColor, size: 13),
          ),
          Positioned(
            bottom: 3,
            right: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceContainerLowest : const Color(0xFF111827)).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text('MP4', style: TextStyle(color: Colors.white, fontSize: 8, fontFamily: 'monospace')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemInfoColumn extends StatelessWidget {
  final VideoExportItem item;
  final bool isDark;
  const _ItemInfoColumn({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final dateColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);
    final readyBg = isDark
        ? AppColors.primaryContainer.withValues(alpha: 0.12)
        : const Color(0xFF10B981).withValues(alpha: 0.12);
    final readyColor = isDark ? AppColors.primaryContainer : const Color(0xFF047857);
    final readyBorder = isDark ? AppColors.primaryContainer : const Color(0xFF10B981);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.fileName,
          style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${item.formattedDate} • ${item.formattedSize}',
          style: TextStyle(color: dateColor, fontSize: 10, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: readyBg,
                border: Border.all(color: readyBorder),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'READY',
                style: TextStyle(
                  color: readyColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'H.264 • MODIFIED',
              style: TextStyle(color: dateColor, fontSize: 9, fontFamily: 'monospace'),
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
  final bool isDark;

  const _ItemActionButtons({
    required this.onShare,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final btnBg = isDark ? AppColors.surfaceContainer : const Color(0xFFF3F4F6);
    final btnBorder = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final shareColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final deleteColor = isDark ? AppColors.error : const Color(0xFFDC2626);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.share, size: 16),
          color: shareColor,
          tooltip: 'Share',
          style: IconButton.styleFrom(
            backgroundColor: btnBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: btnBorder),
            ),
            minimumSize: const Size(48, 48),
            fixedSize: const Size(48, 48),
          ),
          onPressed: onShare,
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 16),
          color: deleteColor,
          tooltip: 'Delete',
          style: IconButton.styleFrom(
            backgroundColor: btnBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: btnBorder),
            ),
            minimumSize: const Size(48, 48),
            fixedSize: const Size(48, 48),
          ),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
