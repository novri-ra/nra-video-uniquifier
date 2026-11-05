import 'dart:io';
import 'dart:isolate';
// ignore: depend_on_referenced_packages
import 'package:crypto/crypto.dart';
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
class SuccessScreen extends StatefulWidget {
  final String? outputPath;

  const SuccessScreen({super.key, this.outputPath});

  static Future<String> computeFileHash(String filePath) async {
    return await Isolate.run(() async {
      try {
        final file = File(filePath);
        if (!await file.exists()) return '0x0000..0000 (UNAVAILABLE)';
        final bytes = await file.readAsBytes();
        final digest = sha256.convert(bytes);
        final hex = digest.toString().toUpperCase();
        return '0x${hex.substring(0, 4)}..${hex.substring(hex.length - 4)} (VERIFIED)';
      } catch (_) {
        return '0x0000..0000 (ERROR)';
      }
    });
  }

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  String _outputHash = 'Computing SHA-256...';
  String? _lastHashedPath;

  @override
  void initState() {
    super.initState();
    _triggerHashComputation();
  }

  @override
  void didUpdateWidget(covariant SuccessScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outputPath != widget.outputPath) {
      _triggerHashComputation();
    }
  }

  void _triggerHashComputation() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<UniquifierProvider>();
      final effectivePath =
          widget.outputPath ?? provider.lastProcessedOutputPath;
      if (effectivePath == null || effectivePath.isEmpty) {
        if (mounted) setState(() => _outputHash = '0x0000..0000 (NO FILE)');
        return;
      }
      if (_lastHashedPath == effectivePath) return;
      _lastHashedPath = effectivePath;

      final hash = await SuccessScreen.computeFileHash(effectivePath);
      if (mounted) {
        setState(() {
          _outputHash = hash;
        });
      }
    });
  }

  List<String> _buildActiveMutations(UniquifierProvider provider) {
    final list = <String>[];
    if (provider.removeMetadata) list.add('Metadata stripped');
    if (provider.modifyAudio) list.add('PTS & Audio shifted');
    if (provider.cropZoomScale > 1.0 || provider.enableDynamicZoom) {
      list.add('Micro-cropped');
    }
    if (provider.modifyVisuals) list.add('Color EQ');
    if (provider.enableDeepAntiFingerprint) list.add('Deep Evasion');
    if (provider.enableBlurredCanvas) list.add('Blurred Canvas');
    if (provider.enableHorizontalFlip) list.add('H-Flipped');
    if (provider.enableMicroOverlay) list.add('Micro-Overlay');
    if (provider.enableFrameSkip) list.add('Frame Jitter');
    if (provider.enableChromaShift) list.add('Chroma Shift');
    return list.isNotEmpty
        ? list
        : [
            'Metadata stripped',
            'PTS & Audio shifted',
            'Micro-cropped',
            'Color EQ',
          ];
  }

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
    final effectivePath = widget.outputPath ?? provider.lastProcessedOutputPath;
    final fileName = effectivePath != null
        ? effectivePath.split(RegExp(r'[/\\]')).last
        : 'UQ_video_output.mp4';
    final directoryPath =
        effectivePath ?? '/storage/emulated/0/Movies/Uniquifier';
    final outputThumb = provider.outputThumbnailPath;
    final hasOutputThumb =
        outputThumb != null && File(outputThumb).existsSync();
    final inputThumb = provider.thumbnailPath;
    final hasInputThumb = inputThumb != null && File(inputThumb).existsSync();
    final thumbPath = hasOutputThumb
        ? outputThumb
        : (hasInputThumb ? inputThumb : null);
    final activeMutations = _buildActiveMutations(provider);

    return Scaffold(
      appBar: const TopAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SuccessHeroCard(outputHash: _outputHash),
              const SizedBox(height: 16),
              SuccessManifestCard(
                fileName: fileName,
                directoryPath: directoryPath,
                thumbnailPath: thumbPath,
                activeMutations: activeMutations,
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
