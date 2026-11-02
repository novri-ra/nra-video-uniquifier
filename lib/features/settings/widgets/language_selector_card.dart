import 'package:flutter/material.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// Interactive selector card for choosing UI language (ID or EN).
class LanguageSelectorCard extends StatelessWidget {
  final LocaleProvider localeProvider;

  const LanguageSelectorCard({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentCode = localeProvider.languageCode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          _LanguageOptionTile(
            title: l10n?.languageId ?? 'Bahasa Indonesia (ID)',
            subtitle: 'Bahasa Indonesia',
            isSelected: currentCode == 'id',
            onTap: () => localeProvider.changeLanguage('id'),
          ),
          const Divider(height: 1, color: AppColors.surfaceContainerHighest),
          _LanguageOptionTile(
            title: l10n?.languageEn ?? 'English (EN)',
            subtitle: 'English',
            isSelected: currentCode == 'en',
            onTap: () => localeProvider.changeLanguage('en'),
          ),
        ],
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  final String title, subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryContainer : AppColors.outline,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.primaryContainer : AppColors.onSurface,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(subtitle, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
