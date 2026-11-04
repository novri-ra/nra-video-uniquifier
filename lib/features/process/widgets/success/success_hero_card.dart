import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Hero header card on the success screen displaying status icon and sandbox hash.
class SuccessHeroCard extends StatelessWidget {
  final String outputHash;

  const SuccessHeroCard({
    super.key,
    this.outputHash = '0x9F41..C7E0 (MODIFIED)',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final title = l10n?.videoSavedTitle ?? 'Video Saved!';
    final desc =
        l10n?.videoSavedDesc ?? 'Exported to public Movies/Uniquifier gallery';

    final cardBg = isDark ? AppColors.surface : AppColors.white;
    final borderColor = isDark
        ? AppColors.surfaceContainerHighest
        : AppColors.hairlineBorder;
    final titleColor = isDark ? AppColors.white : AppColors.textDark;
    final descColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final circleBg = isDark
        ? AppColors.surfaceContainer
        : AppColors.lightSurfaceContainer;
    final circleBorder = isDark
        ? AppColors.primaryContainer
        : AppColors.forestDeep;
    final iconColor = isDark
        ? AppColors.primaryContainer
        : AppColors.forestDeep;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleBg,
              border: Border.all(color: circleBorder),
            ),
            child: Icon(Icons.check_circle, color: iconColor, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: descColor, fontSize: 12)),
          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SANDBOX HASH:',
                style: TextStyle(
                  color: descColor,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                outputHash,
                style: TextStyle(
                  color: isDark
                      ? AppColors.primaryContainer
                      : AppColors.forestDeep,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
