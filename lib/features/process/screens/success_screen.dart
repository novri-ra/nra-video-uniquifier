import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/top_app_bar.dart';

class SuccessScreen extends StatelessWidget {
  final String? outputPath;

  const SuccessScreen({super.key, this.outputPath});

  Future<void> _shareVideo(BuildContext context, String path) async {
    final file = File(path);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Output video file not found.'), backgroundColor: AppColors.error),
        );
      }
      return;
    }
    try {
      await Share.shareXFiles([XFile(path, mimeType: 'video/mp4')], text: 'Unique video exported via NRA Uniquifier');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _openGallery(BuildContext context, String path) async {
    final file = File(path);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: File does not exist.'), backgroundColor: AppColors.error),
        );
      }
      return;
    }
    try {
      final res = await OpenFilex.open(path);
      if (res.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open: ${res.message}'), backgroundColor: AppColors.surfaceContainerHighest),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = outputPath != null ? outputPath!.split(RegExp(r'[/\\]')).last : 'video_01_unique.mp4';
    final directoryPath = outputPath ?? '/Movies/VideoUniquifier/';

    return Scaffold(
      appBar: const TopAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const _SuccessHeroCard(),
                  const SizedBox(height: 16),
                  _SuccessManifestCard(fileName: fileName, directoryPath: directoryPath),
                ],
              ),
              _SuccessActionButtons(
                outputPath: outputPath,
                onShare: () => _shareVideo(context, outputPath!),
                onOpen: () => _openGallery(context, outputPath!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessHeroCard extends StatelessWidget {
  const _SuccessHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainer,
              border: Border.all(color: AppColors.primaryContainer),
            ),
            child: const Icon(Icons.check_circle, color: AppColors.primaryContainer, size: 32),
          ),
          const SizedBox(height: 12),
          const Text('Video Saved!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('New unique video exported to device storage.', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 12),
          const Divider(color: AppColors.surfaceContainerHighest, height: 1),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SANDBOX HASH:', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontFamily: 'monospace')),
              Text('0x9F41..C7E0 (MODIFIED)', style: TextStyle(color: AppColors.primaryContainer, fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuccessManifestCard extends StatelessWidget {
  final String fileName;
  final String directoryPath;

  const _SuccessManifestCard({required this.fileName, required this.directoryPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ManifestHeader(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ThumbnailReadyBadge(),
              const SizedBox(width: 12),
              Expanded(
                child: _ManifestDetailsColumn(fileName: fileName, directoryPath: directoryPath),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManifestHeader extends StatelessWidget {
  const _ManifestHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('EXPORT MANIFEST', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, letterSpacing: 0.8, fontFamily: 'monospace')),
        Text('ISOLATED PROCESS', style: TextStyle(color: AppColors.primaryContainer, fontSize: 10, fontFamily: 'monospace')),
      ],
    );
  }
}

class _ManifestDetailsColumn extends StatelessWidget {
  final String fileName;
  final String directoryPath;

  const _ManifestDetailsColumn({required this.fileName, required this.directoryPath});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fileName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(directoryPath, style: const TextStyle(color: AppColors.primaryContainer, fontSize: 10, fontFamily: 'monospace'), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        const Text('Metadata stripped • Audio shifted +0.5% • Micro-cropped', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10)),
      ],
    );
  }
}

class _ThumbnailReadyBadge extends StatelessWidget {
  const _ThumbnailReadyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Stack(
        children: [
          const Center(child: Icon(Icons.videocam, color: AppColors.outline, size: 32)),
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border.all(color: AppColors.primaryContainer),
              ),
              child: const Text('READY', style: TextStyle(color: AppColors.primaryContainer, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessActionButtons extends StatelessWidget {
  final String? outputPath;
  final VoidCallback onShare;
  final VoidCallback onOpen;

  const _SuccessActionButtons({
    required this.outputPath,
    required this.onShare,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            elevation: 0,
          ),
          onPressed: outputPath != null ? onShare : null,
          icon: const Icon(Icons.share, size: 18),
          label: const Text('Share to TikTok', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurface,
            side: const BorderSide(color: AppColors.surfaceContainerHighest),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: outputPath != null ? onOpen : null,
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: const Text('Open Gallery'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.onSurfaceVariant,
            minimumSize: const Size.fromHeight(44),
          ),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.done_all, size: 16),
          label: const Text('Uniquify Another Video'),
        ),
      ],
    );
  }
}
