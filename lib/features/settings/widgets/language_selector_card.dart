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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final currentCode = localeProvider.languageCode;
    final border = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _LanguageOptionTile(
            title: l10n?.languageId ?? 'Bahasa Indonesia (ID)',
            subtitle: 'Bahasa Indonesia',
            isSelected: currentCode == 'id',
            isDark: isDark,
            onTap: () => localeProvider.changeLanguage('id'),
          ),
          Divider(height: 1, color: border),
          _LanguageOptionTile(
            title: l10n?.languageEn ?? 'English (EN)',
            subtitle: 'English',
            isSelected: currentCode == 'en',
            isDark: isDark,
            onTap: () => localeProvider.changeLanguage('en'),
          ),
        ],
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  final String title, subtitle;
  final bool isSelected, isDark;
  final VoidCallback onTap;

  const _LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radioActiveGreen = Color(0xFF10B981);
    final radioInactive = isDark ? AppColors.outline : const Color(0xFF9CA3AF);
    final activeTextColor = isDark ? AppColors.primaryContainer : const Color(0xFF6C5CE7);
    final inactiveTextColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final subColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off,
              color: isSelected ? radioActiveGreen : radioInactive,
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
                      color: isSelected ? activeTextColor : inactiveTextColor,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(subtitle, style: TextStyle(color: subColor, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
