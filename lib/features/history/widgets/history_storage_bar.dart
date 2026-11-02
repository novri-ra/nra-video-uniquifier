import 'package:flutter/material.dart';
import 'package:storage_space/storage_space.dart';
import '../../../../core/theme/app_theme.dart';

class HistoryHeader extends StatelessWidget {
  final int itemCount;
  final String totalSize;
  final VoidCallback onRefresh;

  const HistoryHeader({
    super.key,
    required this.itemCount,
    required this.totalSize,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metaColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _HistoryHeaderTitle(),
        Row(
          children: [
            Text(
              '$itemCount Files • $totalSize',
              style: TextStyle(color: metaColor, fontSize: 11, fontFamily: 'monospace'),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              color: metaColor,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onRefresh,
            ),
          ],
        ),
      ],
    );
  }
}

class _HistoryHeaderTitle extends StatelessWidget {
  const _HistoryHeaderTitle();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final badgeBg = isDark ? AppColors.surfaceContainerHigh : const Color(0xFFF3F4F6);
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final badgeText = isDark ? AppColors.primaryContainer : const Color(0xFF6C5CE7);

    return Row(
      children: [
        Text(
          'Recent Exports',
          style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: badgeBg,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'QUEUE LOG',
            style: TextStyle(
              color: badgeText,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

class StorageTelemetryBar extends StatelessWidget {
  final String totalSize;
  final bool hasItems;
  final StorageSpace? deviceStorage;

  const StorageTelemetryBar({
    super.key,
    required this.totalSize,
    required this.hasItems,
    this.deviceStorage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceContainerLow : const Color(0xFFF1F5F9);
    final borderColor = isDark ? AppColors.surfaceContainerHighest : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _StorageTopRow(totalSize: totalSize, deviceStorage: deviceStorage, isDark: isDark),
          const SizedBox(height: 8),
          _StorageProgressBar(
            hasItems: hasItems,
            usageFraction: deviceStorage?.usageValue,
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _StorageBottomTags(isDark: isDark),
        ],
      ),
    );
  }
}

class _StorageTopRow extends StatelessWidget {
  final String totalSize;
  final StorageSpace? deviceStorage;
  final bool isDark;
  const _StorageTopRow({required this.totalSize, this.deviceStorage, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final usedColor = isDark ? AppColors.primaryContainer : const Color(0xFF047857);
    final freeColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);
    final iconColor = isDark ? AppColors.outline : const Color(0xFF6C5CE7);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.storage, color: iconColor, size: 14),
            const SizedBox(width: 6),
            Text('Sandbox: ', style: TextStyle(color: titleColor, fontSize: 11)),
            Text(
              '$totalSize used',
              style: TextStyle(
                color: usedColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        Text(
          deviceStorage != null ? '${deviceStorage!.freeSize} FREE' : 'DEVICE STORAGE',
          style: TextStyle(color: freeColor, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StorageProgressBar extends StatelessWidget {
  final bool hasItems, isDark;
  final double? usageFraction;
  const _StorageProgressBar({required this.hasItems, this.usageFraction, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final widthFactor = (usageFraction ?? (hasItems ? 0.15 : 0.01)).clamp(0.01, 1.0);
    final trackBg = isDark ? AppColors.surfaceContainer : const Color(0xFFE2E8F0);
    final activeBarColor = isDark ? AppColors.primaryContainer : const Color(0xFF10B981);

    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          decoration: BoxDecoration(
            color: activeBarColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _StorageBottomTags extends StatelessWidget {
  final bool isDark;
  const _StorageBottomTags({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tagColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'V-SANDBOX ISOLATION: ACTIVE',
          style: TextStyle(color: tagColor, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w600),
        ),
        Text(
          'ZERO NETWORK LEAK',
          style: TextStyle(color: tagColor, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
