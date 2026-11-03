import 'package:flutter/material.dart';
import 'package:storage_space/storage_space.dart';
import '../../../../core/theme/app_colors.dart';

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
    final metaColor = isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(child: _HistoryHeaderTitle()),
        Row(
          mainAxisSize: MainAxisSize.min,
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
    final titleColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final badgeBg = isDark ? AppColors.surfaceContainerHigh : AppColors.hairlineBorder;
    final borderColor = isDark ? AppColors.outlineVariant : AppColors.lightOutlineVariant;
    final badgeText = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            'Recent Exports',
            style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
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
    final cardBg = isDark ? AppColors.obsidianDark : AppColors.white;
    final borderColor = isDark ? AppColors.outlineVariant : AppColors.lightOutlineVariant;

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
    final freeColor = isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant;
    final freeLabel = deviceStorage != null ? '${deviceStorage!.freeSize} FREE' : 'DEVICE STORAGE';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: _SandboxUsedLabel(totalSize: totalSize, isDark: isDark)),
        const SizedBox(width: 8),
        Text(freeLabel, style: TextStyle(color: freeColor, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SandboxUsedLabel extends StatelessWidget {
  final String totalSize;
  final bool isDark;
  const _SandboxUsedLabel({required this.totalSize, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final usedColor = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final iconColor = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.storage, color: iconColor, size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(
              text: 'Sandbox: ',
              style: TextStyle(color: titleColor, fontSize: 11),
              children: [
                TextSpan(
                  text: '$totalSize used',
                  style: TextStyle(color: usedColor, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
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
    final trackBg = isDark ? AppColors.surfaceContainer : AppColors.hairlineBorder;
    final activeBarColor = isDark ? AppColors.mintSage : AppColors.forestDeep;

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
    final tagColor = isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'V-SANDBOX ISOLATION: ACTIVE',
            style: TextStyle(color: tagColor, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'ZERO NETWORK LEAK',
          style: TextStyle(color: tagColor, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
