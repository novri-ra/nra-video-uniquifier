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
        final fraction = totalBytes > 0
            ? (freeBytes / totalBytes).clamp(0.0, 1.0)
            : 0.5;
        setState(() {
          _storageSpace = space;
          _freeGigabytes = gb;
          _freeFraction = fraction;
        });
      }
    } catch (_) {}
  }

  Color _storageColor(double gb) {
    if (gb >= 5.0) return AppColors.mustardOchre;
    if (gb >= 2.0) return AppColors.persimmonOrange;
    return AppColors.vividCoral;
  }

  List<Widget> _buildGridCards(
    BuildContext context,
    UniquifierProvider provider,
    BatchQueueProvider queue,
    AppLocalizations? l10n,
    bool isDark,
    bool isClean,
    Color metadataColor,
    Color ringColor,
  ) {
    return [
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
        codec: provider.videoCodec.key == 'h265' ? 'H.265' : 'H.264',
        hardwareAcc: provider.hardwareAcceleration,
        isDark: isDark,
        onTap: () => context.read<UniquifierProvider>().setTabIndex(2),
      ),
      BentoCards.buildStorageCard(
        title: l10n?.storageBuffer ?? 'Storage Safe Buffer',
        freeGbText:
            _storageSpace?.freeSize ??
            '${_freeGigabytes.toStringAsFixed(1)} GB FREE',
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();
    final queue = context.watch<BatchQueueProvider>();
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isClean = provider.removeMetadata;
    final metadataColor = isClean
        ? (isDark ? AppColors.mintSage : AppColors.forestDeep)
        : AppColors.outline;
    final ringColor = _storageColor(_freeGigabytes);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.70,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _buildGridCards(
        context,
        provider,
        queue,
        l10n,
        isDark,
        isClean,
        metadataColor,
        ringColor,
      ),
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

  Widget _buildTopRow() {
    const queueColor = AppColors.persimmonOrange;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(Icons.layers_rounded, color: queueColor, size: 20),
        GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: queueColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: queueColor.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.add, size: 12, color: queueColor),
          ),
        ),
      ],
    );
  }

  Widget _buildPillContainer(Color countColor) {
    return Container(
      width: 110,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.peachCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.persimmonOrange.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.peachCream.withValues(
              alpha: widget.isDark ? 0.25 : 0.40,
            ),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_rounded, color: countColor, size: 22),
          const SizedBox(width: 8),
          Text(
            '${widget.queue.totalCount}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: countColor,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterVisual(BuildContext context) {
    final labelColor = widget.isDark
        ? AppColors.outline
        : AppColors.lightOnSurfaceVariant;
    const countColor = AppColors.persimmonOrange;
    final l10n = AppLocalizations.of(context);
    final queueLabel = l10n?.queueReady ?? 'SIAP ANTREAN';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillContainer(countColor),
          const SizedBox(height: 6),
          Text(
            queueLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    Color titleColor,
    Color queueColor,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context);
    final emptyText = l10n?.readyToUpload ?? 'Ready to Upload • Tap +';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: titleColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          widget.queue.hasItems
              ? '${widget.queue.completedCount}/${widget.queue.totalCount} Selesai • Buka'
              : emptyText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: queueColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration(Color bg, Color border) => BoxDecoration(
    color: bg,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: border),
    boxShadow: [
      if (!widget.isDark)
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    const queueColor = AppColors.persimmonOrange;
    final bgColor = widget.isDark ? AppColors.obsidianDark : AppColors.white;
    final borderColor = widget.isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;
    final titleColor = widget.isDark
        ? AppColors.onSurface
        : AppColors.lightOnSurface;

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
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          decoration: _cardDecoration(bgColor, borderColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(),
              const Spacer(),
              _buildCenterVisual(context),
              const Spacer(),
              _buildFooter(titleColor, queueColor, context),
            ],
          ),
        ),
      ),
    );
  }
}
