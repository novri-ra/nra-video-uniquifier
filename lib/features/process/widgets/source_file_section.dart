import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/batch_queue_provider.dart';
import '../../../../core/providers/uniquifier_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class SourceFileSection extends StatelessWidget {
  final bool hasFile;
  final UniquifierProvider provider;
  final VoidCallback onPickVideo;

  const SourceFileSection({
    super.key,
    required this.hasFile,
    required this.provider,
    required this.onPickVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SourceFileHeader(hasFile: hasFile),
        const SizedBox(height: 6),
        if (hasFile)
          _SelectedVideoCard(
            provider: provider,
            onReplace: onPickVideo,
            onClear: () {
              context.read<BatchQueueProvider>().clear();
              provider.clearSelection();
            },
          )
        else
          _EmptyPickerCard(onTap: onPickVideo),
      ],
    );
  }
}

class _SourceFileHeader extends StatelessWidget {
  final bool hasFile;
  const _SourceFileHeader({required this.hasFile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final batchQueue = context.watch<BatchQueueProvider>();
    final isBatch = batchQueue.hasItems && batchQueue.totalCount > 1;
    final statusText = isBatch
        ? 'BATCH: ${batchQueue.totalCount} QUEUED'
        : (hasFile ? 'READY FOR TRANSCODE' : 'NO FILE SELECTED');
    final activeStatusColor = isDark ? AppColors.primaryContainer : const Color(0xFF10B981);
    final headerColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SOURCE FILE',
          style: TextStyle(color: headerColor, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, fontFamily: 'monospace'),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            statusText,
            style: TextStyle(color: hasFile ? activeStatusColor : (isDark ? AppColors.outline : const Color(0xFF9CA3AF)), fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SelectedVideoCard extends StatelessWidget {
  final UniquifierProvider provider;
  final VoidCallback onReplace;
  final VoidCallback onClear;

  const _SelectedVideoCard({
    required this.provider,
    required this.onReplace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;

    return Container(
      padding: const EdgeInsets.all(10),
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
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VideoThumbnail(
                duration: provider.duration,
                thumbnailPath: provider.thumbnailPath,
              ),
              const SizedBox(width: 12),
              Expanded(child: _VideoMetaColumn(provider: provider)),
              _ClearIconButton(onPressed: onClear),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 6),
          _VideoReplaceFooter(sha256: provider.sha256, onTap: onReplace),
        ],
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  final String duration;
  final String? thumbnailPath;
  const _VideoThumbnail({required this.duration, this.thumbnailPath});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasThumb = thumbnailPath != null && File(thumbnailPath!).existsSync();
    final thumbBg = isDark ? AppColors.surfaceContainerHigh : const Color(0xFFF3F4F6);
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final iconColor = isDark ? AppColors.primaryContainer : const Color(0xFF6C5CE7);

    return Container(
      width: 64,
      height: 80,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: thumbBg, borderRadius: BorderRadius.circular(4), border: Border.all(color: borderColor)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasThumb)
            Image.file(File(thumbnailPath!), cacheWidth: 240, cacheHeight: 240, fit: BoxFit.cover)
          else
            Center(child: Icon(Icons.videocam, color: iconColor, size: 24)),
          Positioned(
            bottom: 4,
            right: 4,
            child: _ThumbnailDurationBadge(duration: duration, isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailDurationBadge extends StatelessWidget {
  final String duration;
  final bool isDark;
  const _ThumbnailDurationBadge({required this.duration, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = (isDark ? AppColors.surfaceContainerLowest : const Color(0xFF111827)).withValues(alpha: 0.9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2)),
      child: Text(duration, style: const TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace')),
    );
  }
}

class _VideoMetaColumn extends StatelessWidget {
  final UniquifierProvider provider;
  const _VideoMetaColumn({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final subColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider.selectedFileName ?? '',
          style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${provider.fileResolution} • ${provider.fileSize} • ${provider.fileCodec}',
          style: TextStyle(color: subColor, fontSize: 11, fontFamily: 'monospace'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _MetaChip(text: provider.fps),
            const SizedBox(width: 6),
            _MetaChip(text: provider.audioInfo),
          ],
        ),
      ],
    );
  }
}

class _ClearIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ClearIconButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: const Icon(Icons.close, size: 16),
      style: IconButton.styleFrom(
        backgroundColor: isDark ? AppColors.surfaceContainer : const Color(0xFFF3F4F6),
        foregroundColor: isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563),
        padding: EdgeInsets.zero,
        minimumSize: const Size(28, 28),
        fixedSize: const Size(28, 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      onPressed: onPressed,
    );
  }
}

class _VideoReplaceFooter extends StatelessWidget {
  final String sha256;
  final VoidCallback onTap;

  const _VideoReplaceFooter({required this.sha256, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final subColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);
    final shaColor = isDark ? AppColors.primaryContainer : const Color(0xFF6C5CE7);

    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, color: isDark ? AppColors.outline : const Color(0xFF6B7280), size: 12),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n?.changeVideo ?? 'Tap to replace source file',
                    style: TextStyle(color: subColor, fontSize: 10, fontFamily: 'monospace'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'SHA-256: $sha256',
              style: TextStyle(color: shaColor, fontSize: 10, fontFamily: 'monospace'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPickerCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyPickerCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 120,
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
        child: _EmptyPickerContent(isDark: isDark),
      ),
    );
  }
}

class _EmptyPickerContent extends StatelessWidget {
  final bool isDark;
  const _EmptyPickerContent({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final subColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);
    final iconColor = isDark ? AppColors.outline : const Color(0xFF6C5CE7);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.video_file_outlined, color: iconColor, size: 32),
        const SizedBox(height: 8),
        Text(
          l10n?.selectVideo ?? 'Select Video File to Uniquify',
          style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          'Supports MP4, MOV, MKV • Zero Network Transmission',
          style: TextStyle(color: subColor, fontSize: 10, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;
  const _MetaChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? AppColors.surfaceContainer : const Color(0xFFF3F4F6);
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final textColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF374151);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 10, fontFamily: 'monospace'),
      ),
    );
  }
}
