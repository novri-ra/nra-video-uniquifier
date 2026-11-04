import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/services/media_scanner_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../widgets/success/success_action_buttons.dart';
import '../widgets/success/success_hero_card.dart';
import '../widgets/success/success_manifest_card.dart';

/// Screen displayed upon successful video uniquification process.
class SuccessScreen extends StatelessWidget {
  final String? outputPath;

  const SuccessScreen({super.key, this.outputPath});

  Future<void> _shareVideo(BuildContext context, String path) async {
    final file = File(path);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Output video file not found.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    try {
      await Share.shareXFiles([
        XFile(path, mimeType: 'video/mp4'),
      ], text: 'Unique video exported via NRA Uniquifier');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openGallery(BuildContext context, String path) async {
    final opened = await MediaScannerService.openGallery(path);
    if (!opened) {
      try {
        final res = await OpenFilex.open(path);
        if (res.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to open: ${res.message}'),
              backgroundColor: AppColors.surfaceContainerHighest,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Open error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();
    final effectivePath = outputPath ?? provider.lastProcessedOutputPath;
    final fileName = effectivePath != null
        ? effectivePath.split(RegExp(r'[/\\]')).last
        : 'UQ_video_output.mp4';
    final directoryPath =
        effectivePath ?? '/storage/emulated/0/Movies/Uniquifier';
    final thumbPath = provider.outputThumbnailPath;

    return Scaffold(
      appBar: const TopAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SuccessHeroCard(),
              const SizedBox(height: 16),
              SuccessManifestCard(
                fileName: fileName,
                directoryPath: directoryPath,
                thumbnailPath: thumbPath,
              ),
              const SizedBox(height: 24),
              SuccessActionButtons(
                outputPath: effectivePath,
                onExportAndShare: () => _shareVideo(context, effectivePath!),
                onOpenGallery: () => _openGallery(context, effectivePath!),
                onUniquifyAnother: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
