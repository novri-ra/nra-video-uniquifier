import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Manifest summary card showing video thumbnail, file path, and mutation tags.
class SuccessManifestCard extends StatelessWidget {
  final String fileName;
  final String directoryPath;
  final String? thumbnailPath;
  final List<String>? activeMutations;

  const SuccessManifestCard({
    super.key,
    required this.fileName,
    required this.directoryPath,
    this.thumbnailPath,
    this.activeMutations,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surface : AppColors.white;
    final borderColor = isDark
        ? AppColors.surfaceContainerHighest
        : AppColors.hairlineBorder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ManifestHeader(isDark: isDark),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThumbnailReadyBadge(
                thumbnailPath: thumbnailPath,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ManifestDetailsColumn(
                  fileName: fileName,
                  directoryPath: directoryPath,
                  isDark: isDark,
                  activeMutations: activeMutations,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManifestHeader extends StatelessWidget {
  final bool isDark;
  const _ManifestHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'EXPORT MANIFEST',
          style: TextStyle(
            color: isDark
                ? AppColors.onSurfaceVariant
                : AppColors.textDark.withValues(alpha: 0.75),
            fontSize: 10,
            letterSpacing: 0.8,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          'GALLERY INDEXED',
          style: TextStyle(
            color: isDark ? AppColors.mintSage : AppColors.forestDeep,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _ManifestDetailsColumn extends StatelessWidget {
  final String fileName;
  final String directoryPath;
  final bool isDark;
  final List<String>? activeMutations;

  const _ManifestDetailsColumn({
    required this.fileName,
    required this.directoryPath,
    required this.isDark,
    this.activeMutations,
  });

  @override
  Widget build(BuildContext context) {
    final fileNameColor = isDark ? Colors.white : AppColors.textDark;
    final dirColor = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final metaColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    final mutationsText =
        (activeMutations != null && activeMutations!.isNotEmpty)
        ? activeMutations!.join(' • ')
        : 'Metadata stripped • PTS & Audio shifted • Micro-cropped • Color EQ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fileName,
          style: TextStyle(
            color: fileNameColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          directoryPath,
          style: TextStyle(
            color: dirColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(mutationsText, style: TextStyle(color: metaColor, fontSize: 10)),
      ],
    );
  }
}

class _ThumbnailReadyBadge extends StatelessWidget {
  final String? thumbnailPath;
  final bool isDark;
  const _ThumbnailReadyBadge({this.thumbnailPath, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasThumb = thumbnailPath != null && File(thumbnailPath!).existsSync();
    final borderColor = isDark
        ? AppColors.surfaceContainerHighest
        : AppColors.hairlineBorder;
    final badgeColor = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return Container(
      width: 80,
      height: 80,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerLow
            : AppColors.offWhiteCanvas,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasThumb)
            Image.file(
              File(thumbnailPath!),
              cacheWidth: 240,
              cacheHeight: 240,
              fit: BoxFit.cover,
            )
          else
            const Center(
              child: Icon(Icons.videocam, color: AppColors.outline, size: 32),
            ),
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceContainerLowest.withValues(alpha: 0.9)
                    : AppColors.white.withValues(alpha: 0.9),
                border: Border.all(color: badgeColor),
              ),
              child: Text(
                'READY',
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
