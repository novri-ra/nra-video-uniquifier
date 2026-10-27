import 'package:flutter/material.dart';
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _HistoryHeaderTitle(),
        Row(
          children: [
            Text(
              '$itemCount Files • $totalSize',
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontFamily: 'monospace'),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              color: AppColors.onSurfaceVariant,
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
    return Row(
      children: [
        const Text(
          'Recent Exports',
          style: TextStyle(color: AppColors.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            border: Border.all(color: AppColors.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Text(
            'QUEUE LOG',
            style: TextStyle(
              color: AppColors.primaryContainer,
              fontSize: 9,
              fontWeight: FontWeight.w600,
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

  const StorageTelemetryBar({
    super.key,
    required this.totalSize,
    required this.hasItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          _StorageTopRow(totalSize: totalSize),
          const SizedBox(height: 8),
          _StorageProgressBar(hasItems: hasItems),
          const SizedBox(height: 6),
          const _StorageBottomTags(),
        ],
      ),
    );
  }
}

class _StorageTopRow extends StatelessWidget {
  final String totalSize;
  const _StorageTopRow({required this.totalSize});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.storage, color: AppColors.outline, size: 14),
            const SizedBox(width: 6),
            const Text('Local Sandbox Storage: ', style: TextStyle(color: AppColors.onSurface, fontSize: 11)),
            Text(
              '$totalSize used',
              style: const TextStyle(
                color: AppColors.primaryContainer,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const Text(
          'DEVICE STORAGE',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

class _StorageProgressBar extends StatelessWidget {
  final bool hasItems;
  const _StorageProgressBar({required this.hasItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.surfaceContainerHighest, width: 0.5),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: hasItems ? 0.15 : 0.01,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _StorageBottomTags extends StatelessWidget {
  const _StorageBottomTags();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'V-SANDBOX ISOLATION: ACTIVE',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 9, fontFamily: 'monospace'),
        ),
        Text(
          'ZERO NETWORK LEAK',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 9, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
