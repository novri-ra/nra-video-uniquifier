import 'package:flutter/material.dart';
import '../widgets/engine_state_strip.dart';
import '../widgets/modifiers_card.dart';
import '../widgets/source_file_section.dart';
import '../widgets/visual_effect_selector_card.dart';
import 'batch_processing_screen.dart';
import 'processing_screen.dart';
import '../../../core/models/batch_video_item.dart';
import '../../../core/providers/batch_queue_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../../settings/screens/settings_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

class ProcessScreen extends StatefulWidget {
  const ProcessScreen({super.key});

  @override
  State<ProcessScreen> createState() => _ProcessScreenState();
}

class _ProcessScreenState extends State<ProcessScreen> {
  bool _isNavigating = false;

  void _openSettingsTab(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
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
        if (validFiles.isNotEmpty) _applyPickedFiles(context, validFiles);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to open file picker.'),
            backgroundColor: AppColors.errorContainer,
          ),
        );
      }
    }
  }

  void _applyPickedFiles(BuildContext context, List<PlatformFile> validFiles) {
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
          .map(
            (f) => BatchVideoItem(
              id: f.path!,
              path: f.path!,
              name: f.name,
              sizeBytes: f.size,
            ),
          )
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

  Future<void> _startProcessing(BuildContext context) async {
    if (_isNavigating) return;
    final provider = context.read<UniquifierProvider>();
    final batchQueue = context.read<BatchQueueProvider>();
    if (!batchQueue.hasItems && provider.selectedFilePath == null) return;

    _isNavigating = true;
    try {
      if (batchQueue.hasItems && batchQueue.totalCount > 1) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BatchProcessingScreen()),
        );
      } else {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProcessingScreen()));
      }
    } finally {
      if (mounted) {
        _isNavigating = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();
    final batchQueue = context.watch<BatchQueueProvider>();
    final hasFile = provider.selectedFileName != null;
    final batchCount = batchQueue.hasItems
        ? batchQueue.totalCount
        : (hasFile ? 1 : 0);

    return Scaffold(
      appBar: TopAppBar(onSettingsTap: () => _openSettingsTab(context)),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
          child: _ProcessBody(
            hasFile: hasFile,
            batchCount: batchCount,
            provider: provider,
            onPickVideo: () => _pickVideo(context),
            onOpenAdvanced: () => _openSettingsTab(context),
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
        SourceFileSection(
          hasFile: hasFile,
          provider: provider,
          onPickVideo: onPickVideo,
        ),
        const SizedBox(height: 16),
        const ModifiersHeader(),
        const SizedBox(height: 6),
        PresetChipRow(provider: provider),
        const SizedBox(height: 8),
        VisualEffectSelectorCard(provider: provider),
        const SizedBox(height: 8),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final textColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.forestDeep;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user, color: iconColor, size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '100% on-device processing • No data leaves device',
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: isDark ? FontWeight.w500 : FontWeight.w700,
            ),
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
    final l10n = AppLocalizations.of(context);
    final singleLabel = (l10n?.startProcess ?? 'START UNIQUIFYING')
        .toUpperCase();
    final labelText = batchCount > 1
        ? 'START BATCH ($batchCount VIDEOS)'
        : singleLabel;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabledBg = isDark
        ? AppColors.surfaceContainerHigh
        : AppColors.lightSurfaceContainerHigh;
    final disabledFg = isDark
        ? AppColors.outline
        : AppColors.lightOnSurfaceVariant;
    final contentColor = enabled ? AppColors.white : disabledFg;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.forestDeep,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: disabledBg,
        disabledForegroundColor: disabledFg,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
      ),
      onPressed: enabled ? onPressed : null,
      icon: Icon(Icons.bolt, size: 20, color: contentColor),
      label: Text(
        labelText,
        style: TextStyle(
          color: contentColor,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
