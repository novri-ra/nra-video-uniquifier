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

    return Scaffold(
      appBar: TopAppBar(
        title: 'BATCH QUEUE (${queue.completedCount}/${queue.totalCount})',
      ),
      body: SafeArea(
        child: queue.items.isEmpty
            ? _EmptyBatchQueueView(onJumpToStudio: () => config.setTabIndex(1))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _BatchSummaryCard(queue: queue),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'QUEUED ASSETS',
                        style: TextStyle(
                          color: AppColors.outline,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (queue.hasItems && !queue.isProcessing)
                        TextButton(
                          onPressed: queue.clear,
                          child: const Text('Clear All', style: TextStyle(color: AppColors.error, fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...queue.items.map((item) => _BatchItemRow(item: item)),
                  const SizedBox(height: 20),
                  if (!queue.isProcessing)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BatchProcessingScreen()),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text('START BATCH (${queue.totalCount} VIDEOS)'),
                    ),
                ],
              ),
      ),
    );
  }
}

class _EmptyBatchQueueView extends StatelessWidget {
  final VoidCallback onJumpToStudio;
  const _EmptyBatchQueueView({required this.onJumpToStudio});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.layers_clear_outlined, color: AppColors.outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No Videos in Batch Queue',
              style: TextStyle(color: AppColors.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select multiple files in Studio to queue and deduplicate them sequentially.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryContainer,
                side: const BorderSide(color: AppColors.primaryContainer),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
  const _BatchSummaryCard({required this.queue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(label: 'TOTAL', value: '${queue.totalCount}'),
          _StatColumn(label: 'COMPLETED', value: '${queue.completedCount}', color: AppColors.primaryContainer),
          _StatColumn(label: 'FAILED', value: '${queue.failedCount}', color: queue.failedCount > 0 ? AppColors.error : null),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _StatColumn({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color ?? AppColors.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.outline, fontSize: 10, fontFamily: 'monospace')),
      ],
    );
  }
}

class _BatchItemRow extends StatelessWidget {
  final BatchVideoItem item;
  const _BatchItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceContainerHighest),
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
                ? AppColors.primaryContainer
                : AppColors.outline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.onSurface, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          Text(
            item.status.name.toUpperCase(),
            style: TextStyle(
              color: item.status == BatchItemStatus.completed ? AppColors.primaryContainer : AppColors.outline,
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
