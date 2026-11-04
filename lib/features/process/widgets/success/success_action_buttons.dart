import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Primary action buttons on the success screen (Share, Open Gallery, Uniquify Another).
class SuccessActionButtons extends StatelessWidget {
  final String? outputPath;
  final VoidCallback onExportAndShare;
  final VoidCallback onOpenGallery;
  final VoidCallback onUniquifyAnother;

  const SuccessActionButtons({
    super.key,
    required this.outputPath,
    required this.onExportAndShare,
    required this.onOpenGallery,
    required this.onUniquifyAnother,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final exportShareText = l10n?.exportShareVideo ?? 'Export & Share Video';
    final openGalleryText = l10n?.openGallery ?? 'Open Gallery';
    final uniquifyAnotherText =
        l10n?.uniquifyAnother ?? 'Uniquify Another Video';

    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forestDeep,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0,
          ),
          onPressed: outputPath != null ? onExportAndShare : null,
          icon: const Icon(
            Icons.share_rounded,
            size: 18,
            color: AppColors.white,
          ),
          label: Text(
            exportShareText,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.forestDeep,
            side: const BorderSide(color: AppColors.forestDeep, width: 1.5),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: outputPath != null ? onOpenGallery : null,
          icon: const Icon(
            Icons.photo_library_outlined,
            size: 18,
            color: AppColors.forestDeep,
          ),
          label: Text(
            openGalleryText,
            style: const TextStyle(
              color: AppColors.forestDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.outline,
            minimumSize: const Size.fromHeight(44),
          ),
          onPressed: onUniquifyAnother,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: Text(uniquifyAnotherText),
        ),
      ],
    );
  }
}
