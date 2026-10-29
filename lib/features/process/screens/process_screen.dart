import 'package:flutter/material.dart';
import '../../settings/screens/advanced_settings_bottom_sheet.dart';
import '../../settings/screens/app_settings_bottom_sheet.dart';
import '../widgets/engine_state_strip.dart';
import '../widgets/modifiers_card.dart';
import '../widgets/source_file_section.dart';
import 'batch_processing_screen.dart';
import 'processing_screen.dart';
import '../../../core/models/batch_video_item.dart';
import '../../../core/providers/batch_queue_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../shared/widgets/top_app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

class ProcessScreen extends StatelessWidget {
  const ProcessScreen({super.key});

  void _openAdvancedSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AdvancedSettingsBottomSheet(),
    );
  }

  Future<void> _pickVideo(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'mkv'],
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        if (!context.mounted) return;
        final validFiles = result.files.where((f) => f.path != null).toList();
        if (validFiles.isEmpty) return;

        if (validFiles.length == 1) {
          final file = validFiles.first;
          context.read<BatchQueueProvider>().clear();
          context.read<UniquifierProvider>().setVideoFile(
                path: file.path!,
                name: file.name,
                sizeBytes: file.size,
              );
        } else {
          final batchItems = validFiles
              .map((f) => BatchVideoItem(
                    id: f.path!,
                    path: f.path!,
                    name: f.name,
                    sizeBytes: f.size,
                  ))
              .toList();
          context.read<BatchQueueProvider>().setItems(batchItems);
          final first = validFiles.first;
          context.read<UniquifierProvider>().setVideoFile(
                path: first.path!,
                name: first.name,
                sizeBytes: first.size,
              );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: AppColors.errorContainer,
          ),
        );
      }
    }
  }

  void _startProcessing(BuildContext context) {
    final batchQueue = context.read<BatchQueueProvider>();
    if (batchQueue.hasItems && batchQueue.totalCount > 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BatchProcessingScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProcessingScreen()),
      );
    }
  }

  void _openAppSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppSettingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();
    final batchQueue = context.watch<BatchQueueProvider>();
    final hasFile = provider.selectedFileName != null;
    final batchCount = batchQueue.hasItems ? batchQueue.totalCount : (hasFile ? 1 : 0);

    return Scaffold(
      appBar: TopAppBar(onSettingsTap: () => _openAppSettings(context)),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _ProcessBody(
            hasFile: hasFile,
            batchCount: batchCount,
            provider: provider,
            onPickVideo: () => _pickVideo(context),
            onOpenAdvanced: () => _openAdvancedSettings(context),
            onStartProcessing: () => _startProcessing(context),
          ),
        ),
      ),
    );
  }
}

class _ProcessBody extends StatelessWidget {
  final bool hasFile;
  final int batchCount;
  final UniquifierProvider provider;
  final VoidCallback onPickVideo;
  final VoidCallback onOpenAdvanced;
  final VoidCallback onStartProcessing;

  const _ProcessBody({
    required this.hasFile,
    required this.batchCount,
    required this.provider,
    required this.onPickVideo,
    required this.onOpenAdvanced,
    required this.onStartProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SourceFileSection(hasFile: hasFile, provider: provider, onPickVideo: onPickVideo),
        const SizedBox(height: 16),
        const ModifiersHeader(),
        const SizedBox(height: 6),
        ModifiersCard(provider: provider, onOpenAdvanced: onOpenAdvanced),
        const SizedBox(height: 12),
        EngineStateStrip(provider: provider, onTap: onOpenAdvanced),
        const SizedBox(height: 24),
        const _OfflineGuaranteeNote(),
        const SizedBox(height: 10),
        _ProcessActionButton(
          enabled: hasFile,
          batchCount: batchCount,
          onPressed: onStartProcessing,
        ),
      ],
    );
  }
}

class _OfflineGuaranteeNote extends StatelessWidget {
  const _OfflineGuaranteeNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user, color: AppColors.primaryContainer, size: 14),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            '100% on-device processing • No data leaves device',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontFamily: 'monospace'),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ProcessActionButton extends StatelessWidget {
  final bool enabled;
  final int batchCount;
  final VoidCallback onPressed;

  const _ProcessActionButton({
    required this.enabled,
    this.batchCount = 1,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final labelText = batchCount > 1 ? 'START BATCH ($batchCount VIDEOS)' : 'START UNIQUIFYING';

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
        foregroundColor: enabled ? AppColors.onPrimary : AppColors.outline,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
      ),
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.bolt, size: 20),
      label: Text(
        labelText,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
