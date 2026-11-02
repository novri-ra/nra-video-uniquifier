import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage_space/storage_space.dart';
import '../../../core/providers/batch_queue_provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/services/history_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../batch/screens/batch_queue_tab_screen.dart';
import 'bento_cards.dart';

/// 2x2 Bento Metric Grid with reactive live gauges, glassmorphic touch cards, and system vital telemetry.
class BentoMetricGrid extends StatefulWidget {
  const BentoMetricGrid({super.key});

  @override
  State<BentoMetricGrid> createState() => _BentoMetricGridState();
}

class _BentoMetricGridState extends State<BentoMetricGrid> {
  StorageSpace? _storageSpace;
  double _freeGigabytes = 48.0;
  double _freeFraction = 0.75;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadStorageMetrics);
  }

  Future<void> _loadStorageMetrics() async {
    try {
      final space = await HistoryService.getDeviceStorage();
      if (!mounted) return;
      if (space != null) {
        final freeBytes = space.free;
        final totalBytes = space.total;
        final gb = freeBytes / (1024 * 1024 * 1024);
        final fraction = totalBytes > 0 ? (freeBytes / totalBytes).clamp(0.0, 1.0) : 0.5;
        setState(() {
          _storageSpace = space;
          _freeGigabytes = gb;
          _freeFraction = fraction;
        });
      }
    } catch (_) {}
  }

  Color _storageColor(double gb) {
    if (gb >= 5.0) return const Color(0xFF10B981);
    if (gb >= 2.0) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();
    final queue = context.watch<BatchQueueProvider>();
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isClean = provider.removeMetadata;
    final metadataColor = isClean
        ? (isDark ? AppColors.primaryContainer : const Color(0xFF10B981))
        : (isDark ? AppColors.outline : const Color(0xFF6B7280));
    final ringColor = _storageColor(_freeGigabytes);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        BentoCards.buildHygieneCard(
          title: l10n?.metadataHygiene ?? 'Metadata Hygiene',
          isClean: isClean,
          accentColor: metadataColor,
          isDark: isDark,
          onTap: () => provider.toggleRemoveMetadata(!isClean),
        ),
        BentoCards.buildEngineCard(
          title: l10n?.techSpecsGuard ?? 'Production Engine',
          fps: provider.targetFps,
          codec: provider.videoCodec.key.toUpperCase(),
          hardwareAcc: provider.hardwareAcceleration,
          isDark: isDark,
          onTap: () => context.read<UniquifierProvider>().setTabIndex(2),
        ),
        BentoCards.buildStorageCard(
          title: l10n?.storageBuffer ?? 'Storage Safe Buffer',
          freeGbText: _storageSpace?.freeSize ?? '${_freeGigabytes.toStringAsFixed(1)} GB FREE',
          freeFraction: _freeFraction,
          ringColor: ringColor,
          isDark: isDark,
        ),
        _BentoQueueCard(
          title: l10n?.assetStaging ?? 'Asset Staging',
          queue: queue,
          isDark: isDark,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BatchQueueTabScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _BentoQueueCard extends StatefulWidget {
  final String title;
  final BatchQueueProvider queue;
  final bool isDark;
  final VoidCallback onTap;

  const _BentoQueueCard({
    required this.title,
    required this.queue,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_BentoQueueCard> createState() => _BentoQueueCardState();
}

class _BentoQueueCardState extends State<_BentoQueueCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const queueColor = Color(0xFFFF9F1C);
    final bgColor = widget.isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = widget.isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final titleColor = widget.isDark ? AppColors.onSurface : const Color(0xFF111827);
    final detailColor = widget.isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.layers_rounded, color: queueColor, size: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: queueColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.queue.hasItems ? '${widget.queue.totalCount} QUEUED' : '0 QUEUED',
                      style: const TextStyle(
                        color: queueColor,
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
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.queue.hasItems
                        ? '${widget.queue.completedCount} selesai • Ketuk buka'
                        : 'Antrean siap • Ketuk kelola',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: detailColor, fontSize: 9.5, height: 1.25),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
