import 'package:flutter/material.dart';
import '../../../../core/providers/uniquifier_provider.dart';
import '../../../../core/theme/app_theme.dart';

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
            onClear: provider.clearSelection,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'SOURCE FILE',
          style: TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          hasFile ? 'READY FOR TRANSCODE' : 'NO FILE SELECTED',
          style: TextStyle(
            color: hasFile ? AppColors.primaryContainer : AppColors.outline,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VideoThumbnail(duration: provider.duration),
              const SizedBox(width: 12),
              Expanded(child: _VideoMetaColumn(provider: provider)),
              _ClearIconButton(onPressed: onClear),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.surfaceContainerHighest, height: 1),
          const SizedBox(height: 6),
          _VideoReplaceFooter(sha256: provider.sha256, onTap: onReplace),
        ],
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  final String duration;
  const _VideoThumbnail({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Stack(
        children: [
          const Center(child: Icon(Icons.videocam, color: AppColors.primaryContainer, size: 24)),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.surfaceContainerHighest),
              ),
              child: Text(
                duration,
                style: const TextStyle(color: AppColors.onSurface, fontSize: 9, fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoMetaColumn extends StatelessWidget {
  final UniquifierProvider provider;
  const _VideoMetaColumn({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider.selectedFileName ?? '',
          style: const TextStyle(color: AppColors.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${provider.fileResolution} • ${provider.fileSize} • ${provider.fileCodec}',
          style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontFamily: 'monospace'),
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
    return IconButton(
      icon: const Icon(Icons.close, size: 16),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceContainer,
        foregroundColor: AppColors.onSurfaceVariant,
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
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.refresh, color: AppColors.outline, size: 12),
              SizedBox(width: 4),
              Text(
                'Tap to replace source file',
                style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
          Text(
            'SHA-256: $sha256',
            style: const TextStyle(color: AppColors.primaryContainer, fontSize: 10, fontFamily: 'monospace'),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.surfaceContainerHighest),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_file, color: AppColors.outline, size: 32),
            SizedBox(height: 8),
            Text(
              'Select Video File to Uniquify',
              style: TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2),
            Text(
              'Supports MP4, MOV, MKV • Zero Network Transmission',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;
  const _MetaChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontFamily: 'monospace'),
      ),
    );
  }
}
