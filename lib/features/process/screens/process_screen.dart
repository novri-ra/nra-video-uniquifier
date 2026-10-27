import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../../settings/screens/advanced_settings_bottom_sheet.dart';
import '../../settings/screens/app_settings_bottom_sheet.dart';
import '../widgets/engine_state_strip.dart';
import '../widgets/modifiers_card.dart';
import '../widgets/source_file_section.dart';
import 'processing_screen.dart';

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
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null && context.mounted) {
          context.read<UniquifierProvider>().setVideoFile(
                path: file.path!,
                name: file.name,
                sizeBytes: file.size,
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProcessingScreen()),
    );
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
    final hasFile = provider.selectedFileName != null;

    return Scaffold(
      appBar: TopAppBar(onSettingsTap: () => _openAppSettings(context)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _ProcessBody(
            hasFile: hasFile,
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
  final UniquifierProvider provider;
  final VoidCallback onPickVideo;
  final VoidCallback onOpenAdvanced;
  final VoidCallback onStartProcessing;

  const _ProcessBody({
    required this.hasFile,
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
        _ProcessActionButton(enabled: hasFile, onPressed: onStartProcessing),
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
        Text(
          '100% on-device processing • No data leaves device',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

class _ProcessActionButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _ProcessActionButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
      ),
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.bolt, size: 20),
      label: const Text('Process Video', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }
}
