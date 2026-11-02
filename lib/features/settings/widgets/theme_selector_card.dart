import 'package:flutter/material.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Interactive theme mode selector supporting System, Light, and Dark options.
class ThemeSelectorCard extends StatelessWidget {
  final ThemeProvider themeProvider;

  const ThemeSelectorCard({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = themeProvider.themeMode;

    return Column(
      children: [
        _ThemeTile(
          icon: Icons.brightness_auto_rounded,
          title: l10n?.themeSystem ?? 'System Default',
          subtitle: 'Follows OS dynamic appearance',
          isSelected: current == ThemeMode.system,
          onTap: () => themeProvider.setThemeMode(ThemeMode.system),
        ),
        const Divider(height: 1, color: AppColors.surfaceContainerHighest),
        _ThemeTile(
          icon: Icons.light_mode_rounded,
          title: l10n?.themeLight ?? 'Light Mode',
          subtitle: 'Clean light surface palette',
          isSelected: current == ThemeMode.light,
          onTap: () => themeProvider.setThemeMode(ThemeMode.light),
        ),
        const Divider(height: 1, color: AppColors.surfaceContainerHighest),
        _ThemeTile(
          icon: Icons.dark_mode_rounded,
          title: l10n?.themeDark ?? 'Dark Mode',
          subtitle: 'Obsidian & charcoal high-contrast palette',
          isSelected: current == ThemeMode.dark,
          onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
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
              icon,
              size: 20,
              color: isSelected ? AppColors.primaryContainer : AppColors.outline,
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
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryContainer : AppColors.outline,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
