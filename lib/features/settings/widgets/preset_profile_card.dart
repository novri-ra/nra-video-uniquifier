import 'package:flutter/material.dart';
import '../../../../core/providers/uniquifier_provider.dart';
import '../../../../core/theme/app_colors.dart';

/// Redesigned selectable preset profile cards matching video codec and upscale cards.
class PresetProfileCard extends StatelessWidget {
  final UniquifierProvider provider;

  const PresetProfileCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _PresetTile(
          icon: Icons.bolt,
          iconAccent: AppColors.persimmonOrange,
          title: 'TikTok / Reels Aggressive',
          description:
              'Spectral Shift, Speed Warp 1.015x, Ken Burns Zoom, HFlip, Noise',
          badge: 'FAST',
          badgeColor: AppColors.persimmonOrange,
          isSelected: provider.activePreset == 'TikTok / Reels',
          isDark: isDark,
          onTap: () => provider.applyPreset(
            removeMetadata: true,
            modifyAudio: true,
            modifyVisuals: true,
            upscale1080p: false,
            enableEnhanceAndDenoise: false,
            enableDeepAntiFingerprint: true,
            enableHorizontalFlip: true,
            enableAutoTrim: true,
            enableDynamicZoom: true,
            enableBlurredCanvas: true,
            canvasScalePercent: 95.0,
            targetFps: 30,
            presetName: 'TikTok / Reels',
          ),
        ),
        const SizedBox(height: 8),
        _PresetTile(
          icon: Icons.movie_filter,
          iconAccent: AppColors.skyPastel,
          title: 'Cinematic 2K / 4K Clean',
          description:
              'No HFlip, No Canvas Blur, AI Upscale + Unsharp, Target 2K',
          badge: 'CINEMA',
          badgeColor: AppColors.electricIce,
          isSelected: provider.activePreset == 'Cinematic 2K/4K',
          isDark: isDark,
          onTap: () => provider.applyPreset(
            removeMetadata: true,
            modifyAudio: true,
            modifyVisuals: true,
            upscale1080p: true,
            upscaleTarget: '2k',
            enableEnhanceAndDenoise: true,
            enableDeepAntiFingerprint: false,
            enableHorizontalFlip: false,
            enableBlurredCanvas: false,
            presetName: 'Cinematic 2K/4K',
          ),
        ),
        const SizedBox(height: 8),
        _PresetTile(
          icon: Icons.flash_on,
          iconAccent: AppColors.mintSage,
          title: 'Ultra-Light / Quick Export',
          description:
              'Minimal filters, CRF 22, no AI upscale, metadata scrub only',
          badge: 'QUICK',
          badgeColor: AppColors.mintSage,
          isSelected: provider.activePreset == 'Quick Export',
          isDark: isDark,
          onTap: () => provider.applyPreset(
            removeMetadata: true,
            modifyAudio: false,
            modifyVisuals: false,
            upscale1080p: false,
            enableEnhanceAndDenoise: false,
            enableDeepAntiFingerprint: false,
            enableHorizontalFlip: false,
            enableAggressiveAudio: false,
            enableAutoTrim: false,
            enableBlurredCanvas: false,
            presetName: 'Quick Export',
          ),
        ),
      ],
    );
  }
}

class _PresetTile extends StatelessWidget {
  final IconData icon;
  final Color iconAccent;
  final String title, description, badge;
  final Color badgeColor;
  final bool isSelected, isDark;
  final VoidCallback onTap;

  const _PresetTile({
    required this.icon,
    required this.iconAccent,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark
        ? AppColors.surfaceContainerHigh
        : AppColors.lightSurfaceContainer;
    final inactiveBg = isDark ? AppColors.obsidianDark : AppColors.white;
    final activeBorder = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final inactiveBorder = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;
    final textColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final descColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final iconColor = isSelected ? activeBorder : iconAccent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeBorder : inactiveBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isDark && !isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(
                            alpha: isDark ? 0.15 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: badgeColor.withValues(
                              alpha: isDark ? 0.4 : 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: descColor,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
