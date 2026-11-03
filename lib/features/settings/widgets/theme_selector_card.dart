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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final current = themeProvider.themeMode;
    final dividerColor = isDark
        ? AppColors.surfaceContainerHighest
        : AppColors.lightOutlineVariant;

    return Column(
      children: [
        _ThemeTile(
          icon: Icons.brightness_auto_rounded,
          iconAccent: AppColors.skyPastel,
          title: l10n?.themeSystem ?? 'System Default',
          subtitle: 'Follows OS dynamic appearance',
          isSelected: current == ThemeMode.system,
          isDark: isDark,
          onTap: () => themeProvider.setThemeMode(ThemeMode.system),
        ),
        Divider(height: 1, color: dividerColor),
        _ThemeTile(
          icon: Icons.light_mode_rounded,
          iconAccent: AppColors.butterYellow,
          title: l10n?.themeLight ?? 'Light Mode',
          subtitle: 'Clean light surface palette',
          isSelected: current == ThemeMode.light,
          isDark: isDark,
          onTap: () => themeProvider.setThemeMode(ThemeMode.light),
        ),
        Divider(height: 1, color: dividerColor),
        _ThemeTile(
          icon: Icons.dark_mode_rounded,
          iconAccent: AppColors.mintSage,
          title: l10n?.themeDark ?? 'Dark Mode',
          subtitle: 'Obsidian & charcoal high-contrast palette',
          isSelected: current == ThemeMode.dark,
          isDark: isDark,
          onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final Color iconAccent;
  final String title, subtitle;
  final bool isSelected, isDark;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
    required this.iconAccent,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radioActive = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final radioInactive = AppColors.outline;
    final activeTextColor = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final inactiveTextColor = isDark
        ? AppColors.onSurface
        : AppColors.lightOnSurface;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final effectiveIconColor = isSelected ? activeTextColor : iconAccent;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: effectiveIconColor),
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
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(color: subColor, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off,
              color: isSelected ? radioActive : radioInactive,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
