import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/settings/screens/settings_screen.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool? isOffline;
  final VoidCallback? onSettingsTap;
  final bool showSettingsAction;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  const TopAppBar({
    super.key,
    this.title = 'NRA VIDEO UNIQUIFIER',
    this.isOffline,
    this.onSettingsTap,
    this.showSettingsAction = true,
    this.showBackButton = false,
    this.onBackTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  void _openSettings(BuildContext context) {
    if (onSettingsTap != null) {
      onSettingsTap!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showBackButton) ...[
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFFF4F4F6) : const Color(0xFF111827),
                ),
                tooltip: 'Back',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: onBackTap ?? () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(child: _TitleSection(title: title, isDark: isDark)),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSettingsAction)
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/setting-icon.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant,
                        BlendMode.srcIn,
                      ),
                    ),
                    tooltip: 'Settings',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => _openSettings(context),
                  ),
                if (showSettingsAction) const SizedBox(width: 4),
                _NetworkStatusBadge(
                  forcedOffline: isOffline,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  final String title;
  final bool isDark;
  const _TitleSection({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryContainer : AppColors.lightPrimary;
    final textColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.terminal, color: accent, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _NetworkStatusBadge extends StatelessWidget {
  final bool? forcedOffline;
  final bool isDark;

  const _NetworkStatusBadge({
    this.forcedOffline,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final connectivity = ConnectivityService.instance;

    return ValueListenableBuilder<bool>(
      valueListenable: connectivity.isOnline,
      builder: (context, onlineValue, _) {
        final effectiveOnline = forcedOffline != null ? !forcedOffline! : onlineValue;
        return effectiveOnline
            ? _OnlineBadge(isDark: isDark)
            : _OfflineBadge(isDark: isDark);
      },
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  final bool isDark;
  const _OnlineBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const onlineColor = Color(0xFF10B981);
    final bg = isDark
        ? const Color(0xFF064E3B).withValues(alpha: 0.40)
        : const Color(0xFFECFDF5);
    final border = isDark
        ? const Color(0xFF047857)
        : const Color(0xFFA7F3D0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: onlineColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'ONLINE',
            style: TextStyle(
              color: onlineColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  final bool isDark;
  const _OfflineBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceContainer : AppColors.lightSurfaceContainer;
    final border = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final accent = isDark ? AppColors.primaryContainer : AppColors.lightPrimary;
    final textColor = isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.lock, color: accent, size: 12),
          const SizedBox(width: 4),
          Text(
            'OFFLINE',
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
