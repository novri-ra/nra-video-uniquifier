import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/batch_video_item.dart';
import '../../../core/providers/batch_queue_provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/top_app_bar.dart';

class BatchProcessingScreen extends StatefulWidget {
  const BatchProcessingScreen({super.key});

  @override
  State<BatchProcessingScreen> createState() => _BatchProcessingScreenState();
}

class _BatchProcessingScreenState extends State<BatchProcessingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final queue = context.read<BatchQueueProvider>();
      final config = context.read<UniquifierProvider>();
      if (!queue.isProcessing && queue.hasItems) {
        queue.runBatch(config);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<BatchQueueProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: TopAppBar(
        title: 'BATCH QUEUE (${queue.completedCount}/${queue.totalCount})',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BatchProgressCard(queue: queue),
              const SizedBox(height: 16),
              const Text(
                'QUEUED FILES',
                style: TextStyle(
                  color: AppColors.outline,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: queue.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) => _BatchItemRow(item: queue.items[idx], index: idx),
                ),
              ),
              const SizedBox(height: 16),
              _BatchBottomAction(queue: queue),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchProgressCard extends StatelessWidget {
  final BatchQueueProvider queue;
  const _BatchProgressCard({required this.queue});

  @override
  Widget build(BuildContext context) {
    final overall = queue.overallProgress;
    final pct = (overall * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                queue.isProcessing
                    ? 'PROCESSING ITEM ${queue.currentIndex + 1} OF ${queue.totalCount}'
                    : (queue.isCancelled ? 'BATCH CANCELLED' : 'BATCH COMPLETED'),
                style: TextStyle(
                  color: queue.isProcessing
                      ? AppColors.primaryContainer
                      : (queue.isCancelled ? AppColors.error : AppColors.primary),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: overall,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchItemRow extends StatelessWidget {
  final BatchVideoItem item;
  final int index;

  const _BatchItemRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (item.status) {
      case BatchItemStatus.completed:
        statusColor = AppColors.primary;
        statusIcon = Icons.check_circle_outline;
        statusLabel = 'DONE';
        break;
      case BatchItemStatus.processing:
        statusColor = AppColors.primaryContainer;
        statusIcon = Icons.hourglass_top;
        statusLabel = '${(item.progress * 100).toInt()}%';
        break;
      case BatchItemStatus.failed:
        statusColor = AppColors.error;
        statusIcon = Icons.error_outline;
        statusLabel = 'FAILED';
        break;
      case BatchItemStatus.cancelled:
        statusColor = AppColors.outline;
        statusIcon = Icons.cancel_outlined;
        statusLabel = 'CANCELLED';
        break;
      case BatchItemStatus.pending:
        statusColor = AppColors.outline;
        statusIcon = Icons.schedule;
        statusLabel = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: item.isProcessing ? AppColors.primaryContainer : AppColors.surfaceContainerHighest,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${index + 1}. ${item.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          if (item.isProcessing) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 3,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BatchBottomAction extends StatelessWidget {
  final BatchQueueProvider queue;
  const _BatchBottomAction({required this.queue});

  @override
  Widget build(BuildContext context) {
    if (queue.isProcessing) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: () => queue.cancelBatch(),
        icon: const Icon(Icons.close, size: 18),
        label: const Text(
          'CANCEL BATCH',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
      ),
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.check, size: 18),
      label: const Text(
        'DONE',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
