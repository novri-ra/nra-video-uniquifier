import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/batch_video_item.dart';
import '../../../core/providers/batch_queue_provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../../process/screens/batch_processing_screen.dart';

/// Dedicated Batch Queue Tab Screen for managing multiple video deduplication tasks.
class BatchQueueTabScreen extends StatelessWidget {
  const BatchQueueTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<BatchQueueProvider>();
    final config = context.watch<UniquifierProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isDark
        ? AppColors.primaryContainer
        : AppColors.lightPrimary;
    final onPrimaryText = isDark
        ? AppColors.onPrimary
        : AppColors.lightOnPrimary;

    return Scaffold(
      appBar: TopAppBar(
        title: 'BATCH QUEUE (${queue.completedCount}/${queue.totalCount})',
        showBackButton: Navigator.canPop(context),
      ),
      body: SafeArea(
        child: queue.items.isEmpty
            ? _EmptyBatchQueueView(
                isDark: isDark,
                onJumpToStudio: () => config.setTabIndex(2),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _BatchSummaryCard(queue: queue, isDark: isDark),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'QUEUED ASSETS',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.outline
                              : AppColors.lightOnSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (queue.hasItems && !queue.isProcessing)
                        TextButton(
                          onPressed: queue.clear,
                          child: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...queue.items.map(
                    (item) => _BatchItemRow(item: item, isDark: isDark),
                  ),
                  const SizedBox(height: 20),
                  if (!queue.isProcessing)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: onPrimaryText,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BatchProcessingScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        'START BATCH (${queue.totalCount} VIDEOS)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _EmptyBatchQueueView extends StatelessWidget {
  final bool isDark;
  final VoidCallback onJumpToStudio;

  const _EmptyBatchQueueView({
    required this.isDark,
    required this.onJumpToStudio,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final descColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final accent = isDark ? AppColors.primaryContainer : AppColors.lightPrimary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.layers_clear_outlined,
              color: isDark ? AppColors.outline : AppColors.lightOutline,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No Videos in Batch Queue',
              style: TextStyle(
                color: titleColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select multiple files in Studio to queue and deduplicate them sequentially.',
              textAlign: TextAlign.center,
              style: TextStyle(color: descColor, fontSize: 12),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: onJumpToStudio,
              icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
              label: const Text('Go to Studio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchSummaryCard extends StatelessWidget {
  final BatchQueueProvider queue;
  final bool isDark;

  const _BatchSummaryCard({required this.queue, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceContainerLow : AppColors.lightSurface;
    final border = isDark
        ? AppColors.surfaceContainerHighest
        : AppColors.lightOutlineVariant;
    final successColor = isDark
        ? AppColors.primaryContainer
        : AppColors.lightPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(
            label: 'TOTAL',
            value: '${queue.totalCount}',
            isDark: isDark,
          ),
          _StatColumn(
            label: 'COMPLETED',
            value: '${queue.completedCount}',
            color: successColor,
            isDark: isDark,
          ),
          _StatColumn(
            label: 'FAILED',
            value: '${queue.failedCount}',
            color: queue.failedCount > 0 ? AppColors.error : null,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label, value;
  final Color? color;
  final bool isDark;

  const _StatColumn({
    required this.label,
    required this.value,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = isDark
        ? AppColors.onSurface
        : AppColors.lightOnSurface;
    final labelColor = isDark
        ? AppColors.outline
        : AppColors.lightOnSurfaceVariant;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color ?? defaultColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _BatchItemRow extends StatelessWidget {
  final BatchVideoItem item;
  final bool isDark;

  const _BatchItemRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceContainerLow : AppColors.lightSurface;
    final border = isDark
        ? AppColors.surfaceContainerHighest
        : AppColors.lightOutlineVariant;
    final textColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final primaryAccent = isDark
        ? AppColors.primaryContainer
        : AppColors.lightPrimary;
    final inactiveOutline = isDark
        ? AppColors.outline
        : AppColors.lightOnSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            item.status == BatchItemStatus.completed
                ? Icons.check_circle
                : item.status == BatchItemStatus.processing
                ? Icons.sync
                : Icons.schedule,
            size: 16,
            color: item.status == BatchItemStatus.completed
                ? primaryAccent
                : inactiveOutline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            item.status.name.toUpperCase(),
            style: TextStyle(
              color: item.status == BatchItemStatus.completed
                  ? primaryAccent
                  : inactiveOutline,
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
