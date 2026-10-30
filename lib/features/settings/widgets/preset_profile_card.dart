import 'package:flutter/material.dart';
import '../../../../core/providers/uniquifier_provider.dart';
import '../../../../core/theme/app_theme.dart';

/// Redesigned selectable obsidian preset profile cards matching video codec and upscale cards.
class PresetProfileCard extends StatelessWidget {
  final UniquifierProvider provider;

  const PresetProfileCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PresetTile(
          icon: Icons.bolt,
          title: 'TikTok Fast',
          description: '8% crop, dynamic micro-tilt, metadata scrub & auto-trim',
          badge: 'FAST',
          badgeColor: AppColors.primaryContainer,
          isSelected: provider.activePreset == 'TikTok Fast',
          onTap: () => provider.applyPreset(
            removeMetadata: true,
            modifyAudio: true,
            modifyVisuals: true,
            upscale1080p: false,
            enableEnhanceAndDenoise: false,
            enableDeepAntiFingerprint: true,
            enableAutoTrim: true,
            presetName: 'TikTok Fast',
          ),
        ),
        const SizedBox(height: 8),
        _PresetTile(
          icon: Icons.security,
          title: 'Maximum Anti-Fingerprint',
          description: '2K Lanczos, flip, pink noise, dual-band EQ & trim',
          badge: 'ULTRA',
          badgeColor: AppColors.secondary,
          isSelected: provider.activePreset == 'Maximum Anti-Fingerprint',
          onTap: () => provider.applyPreset(
            removeMetadata: true,
            modifyAudio: true,
            modifyVisuals: true,
            upscale1080p: true,
            upscaleTarget: '2k',
            enableEnhanceAndDenoise: true,
            enableDeepAntiFingerprint: true,
            enableHorizontalFlip: true,
            enableAggressiveAudio: true,
            enableAutoTrim: true,
            presetName: 'Maximum Anti-Fingerprint',
          ),
        ),
        const SizedBox(height: 8),
        _PresetTile(
          icon: Icons.shield_outlined,
          title: 'Lossless Stealth',
          description: 'Zero visual distortion • Pure container & EXIF scrubbing',
          badge: 'CLEAN',
          badgeColor: AppColors.outline,
          isSelected: provider.activePreset == 'Lossless Stealth',
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
            presetName: 'Lossless Stealth',
          ),
        ),
      ],
    );
  }
}

class _PresetTile extends StatelessWidget {
  final IconData icon;
  final String title, description, badge;
  final Color badgeColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHighest,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryContainer : AppColors.outline,
              size: 20,
            ),
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
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
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
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
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
