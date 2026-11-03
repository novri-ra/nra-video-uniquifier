import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Floating capsule navigation bar with balanced 5-slot layout.
class FloatingCapsuleNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingCapsuleNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static List<_NavItemData> _navItems(AppLocalizations? l10n) {
    return [
      _NavItemData(
        svgAsset: 'assets/home-icon.svg',
        fallbackIcon: Icons.home_rounded,
        label: 'Home',
        index: 0,
      ),
      const _NavItemData(
        svgAsset: 'assets/analytics-icon.svg',
        fallbackIcon: Icons.analytics_outlined,
        label: 'Intel',
        index: 1,
      ),
      _NavItemData(
        svgAsset: 'assets/plus-icon.svg',
        fallbackIcon: Icons.add_rounded,
        label: 'Studio',
        isHeroAction: true,
        index: 2,
      ),
      const _NavItemData(
        svgAsset: 'assets/bell-icon.svg',
        fallbackIcon: Icons.notifications_none_rounded,
        label: 'History',
        index: 3,
      ),
      const _NavItemData(
        svgAsset: 'assets/people-icon.svg',
        fallbackIcon: Icons.person_outline_rounded,
        label: 'Profile',
        index: 4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final items = _navItems(l10n);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _CapsuleContainer(
          isDark: isDark,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((data) {
              return Expanded(
                child: data.isHeroAction
                    ? _CenterHeroButton(
                        data: data,
                        isSelected: currentIndex == data.index,
                        onTap: () => onTap(data.index),
                      )
                    : _NavBarItemTile(
                        data: data,
                        isSelected: currentIndex == data.index,
                        isDark: isDark,
                        onTap: () => onTap(data.index),
                      ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _CapsuleContainer extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _CapsuleContainer({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    final capsuleBg = isDark
        ? AppColors.obsidianDark.withValues(alpha: 0.90)
        : AppColors.white.withValues(alpha: 0.95);
    final borderColor = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
          child: child,
        ),
      ),
    );
  }
}

class _NavItemData {
  final String? svgAsset;
  final IconData? fallbackIcon;
  final String label;
  final bool isHeroAction;
  final int index;

  const _NavItemData({
    this.svgAsset,
    this.fallbackIcon,
    required this.label,
    this.isHeroAction = false,
    required this.index,
  });
}

class _CenterHeroButton extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _CenterHeroButton({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: data.label,
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.vividCoral,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.vividCoral.withValues(alpha: 0.40),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: data.svgAsset != null
                    ? SvgPicture.asset(
                        data.svgAsset!,
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          AppColors.white,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(data.fallbackIcon, size: 24, color: AppColors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    final activeColor = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final inactiveColor = isDark
        ? AppColors.mintSage.withValues(alpha: 0.40)
        : AppColors.obsidianDark.withValues(alpha: 0.40);
    final iconColor = isSelected ? activeColor : inactiveColor;

    return Semantics(
      container: true,
      label: data.label,
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data.svgAsset != null)
                  SvgPicture.asset(
                    data.svgAsset!,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  )
                else
                  Icon(data.fallbackIcon, size: 20, color: iconColor),
                const SizedBox(height: 3),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 9.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
