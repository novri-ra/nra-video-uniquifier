import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Floating capsule navigation bar with blurred backdrop and squircle active highlights.
class FloatingCapsuleNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingCapsuleNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final items = [
      _NavItemData(icon: Icons.dashboard_rounded, label: l10n?.navDashboard ?? 'Home'),
      _NavItemData(icon: Icons.auto_fix_high_rounded, label: l10n?.navStudio ?? 'Studio'),
      _NavItemData(icon: Icons.auto_awesome_rounded, label: l10n?.navMicrostock ?? 'AI Stock'),
      _NavItemData(icon: Icons.layers_rounded, label: l10n?.navBatch ?? 'Batch'),
      _NavItemData(icon: Icons.tune_rounded, label: l10n?.navSettings ?? 'Settings'),
    ];

    final capsuleBg = isDark
        ? AppColors.surfaceContainer.withValues(alpha: 0.82)
        : AppColors.lightSurfaceContainer.withValues(alpha: 0.88);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: capsuleBg,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  return Expanded(
                    child: _NavBarItemTile(
                      data: items[i],
                      isSelected: currentIndex == i,
                      isDark: isDark,
                      onTap: () => onTap(i),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData({required this.icon, required this.label});
}

class _NavBarItemTile extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavBarItemTile({
    required this.data,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeAccent = isDark ? AppColors.primaryContainer : AppColors.lightPrimary;
    final inactiveColor = isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: data.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? activeAccent.withValues(alpha: isDark ? 0.16 : 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                data.icon,
                size: 20,
                color: isSelected ? activeAccent : inactiveColor,
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeAccent : inactiveColor,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
