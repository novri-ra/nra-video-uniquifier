import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isOffline;
  final VoidCallback? onSettingsTap;

  const TopAppBar({
    super.key,
    this.title = 'VIDEO UNIQUIFIER',
    this.isOffline = true,
    this.onSettingsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceContainerHighest, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _TitleSection(title: title)),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onSettingsTap != null)
                  IconButton(
                    icon: const Icon(Icons.tune, size: 18, color: AppColors.onSurfaceVariant),
                    tooltip: 'Settings',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: onSettingsTap,
                  ),
                if (onSettingsTap != null && isOffline) const SizedBox(width: 4),
                if (isOffline) const _OfflineBadge(),
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
  const _TitleSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.terminal, color: AppColors.primaryContainer, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.onSurface,
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

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.lock, color: AppColors.primaryContainer, size: 12),
          const SizedBox(width: 4),
          const Text(
            'OFFLINE',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
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
