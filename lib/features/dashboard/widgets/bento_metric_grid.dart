import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage_space/storage_space.dart';
import '../../../core/providers/batch_queue_provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/services/history_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../batch/screens/batch_queue_tab_screen.dart';

/// 2x2 Bento Metric Grid with reactive live providers & dynamic circular progress storage ring.
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
        _BentoCard(
          icon: isClean ? Icons.shield_rounded : Icons.shield_outlined,
          title: l10n?.metadataHygiene ?? 'Metadata Hygiene',
          status: isClean ? '100% CLEAN' : 'PASSTHROUGH',
          detail: isClean
              ? 'GPS & EXIF Scrubbed • Zero Fingerprint'
              : 'Original Metadata Intact • Unscrubbed',
          accentColor: metadataColor,
          isDark: isDark,
          onTap: () => provider.toggleRemoveMetadata(!isClean),
        ),
        _BentoCard(
          icon: Icons.speed_rounded,
          title: l10n?.techSpecsGuard ?? 'Technical Specs Guard',
          status: '${provider.targetFps} FPS CFR',
          detail: 'BT.709 Primaries • ${provider.videoCodec.key.toUpperCase()} Tagged',
          accentColor: isDark ? const Color(0xFF4DFFB2) : const Color(0xFF6C5CE7),
          isDark: isDark,
          onTap: () => context.read<UniquifierProvider>().setTabIndex(2),
        ),
        _BentoStorageCard(
          title: l10n?.storageBuffer ?? 'Storage Safe Buffer',
          freeGbText: _storageSpace?.freeSize ?? '${_freeGigabytes.toStringAsFixed(1)} GB FREE',
          freeFraction: _freeFraction,
          ringColor: ringColor,
          isDark: isDark,
        ),
        _BentoCard(
          icon: Icons.layers_outlined,
          title: l10n?.assetStaging ?? 'Asset Staging',
          status: queue.hasItems ? '${queue.totalCount} QUEUED' : '0 QUEUED',
          detail: queue.hasItems
              ? '${queue.completedCount} completed • Tap to view'
              : 'Staging queue ready • Tap to batch',
          accentColor: isDark ? const Color(0xFFFFB74D) : const Color(0xFFF59E0B),
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

class _BentoCard extends StatelessWidget {
  final IconData icon;
  final String title, status, detail;
  final Color accentColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _BentoCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.detail,
    required this.accentColor,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final detailColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            if (!isDark)
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
                Icon(icon, color: accentColor, size: 20),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: detailColor,
                    fontSize: 9.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoStorageCard extends StatelessWidget {
  final String title, freeGbText;
  final double freeFraction;
  final Color ringColor;
  final bool isDark;

  const _BentoStorageCard({
    required this.title,
    required this.freeGbText,
    required this.freeFraction,
    required this.ringColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final detailColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
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
              Icon(Icons.storage_rounded, color: ringColor, size: 20),
              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: freeFraction,
                      strokeWidth: 3.5,
                      backgroundColor: ringColor.withValues(alpha: 0.20),
                      color: ringColor,
                    ),
                    Text(
                      '${(freeFraction * 100).toInt()}%',
                      style: TextStyle(
                        color: ringColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                freeGbText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: detailColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
