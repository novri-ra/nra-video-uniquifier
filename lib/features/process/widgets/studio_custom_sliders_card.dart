import 'package:flutter/material.dart';
import '../../../../core/providers/uniquifier_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/interactive_preview_slider.dart';

/// Control card for manual zoom scale, anchor pill selection, and intro cut slider.
class StudioCustomSlidersCard extends StatelessWidget {
  final UniquifierProvider provider;

  const StudioCustomSlidersCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.obsidianDark : AppColors.white;
    final borderCol = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;
    final trimAccent = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InteractivePreviewSlider(
            value: provider.cropZoomScale,
            min: 1.0,
            max: 1.5,
            divisions: 10,
            label: '${provider.cropZoomScale.toStringAsFixed(2)}x',
            parameterName: 'ZOOM & FACE FOCUS (CROP)',
            effect: PreviewEffect.cropZoom,
            thumbnailPath: provider.thumbnailPath,
            onChanged: provider.setCropZoomScale,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Anchor: ',
                style: TextStyle(
                  color: isDark
                      ? AppColors.outline
                      : AppColors.lightOnSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              _AnchorPill(
                label: 'Top (Face)',
                isSelected: provider.cropAnchor == 'top',
                onTap: () => provider.setCropAnchor('top'),
                isDark: isDark,
              ),
              _AnchorPill(
                label: 'Center',
                isSelected: provider.cropAnchor == 'center',
                onTap: () => provider.setCropAnchor('center'),
                isDark: isDark,
              ),
              _AnchorPill(
                label: 'Bottom',
                isSelected: provider.cropAnchor == 'bottom',
                onTap: () => provider.setCropAnchor('bottom'),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          InteractivePreviewSlider(
            value: provider.rotateAngle,
            min: -2.0,
            max: 2.0,
            divisions: 40,
            label:
                '${provider.rotateAngle >= 0 ? '+' : ''}${provider.rotateAngle.toStringAsFixed(1)}°',
            parameterName: 'MICRO-ROTATION / TILT',
            effect: PreviewEffect.microRotation,
            thumbnailPath: provider.thumbnailPath,
            onChanged: provider.setRotateAngle,
          ),
          if (provider.enableAutoTrim) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.content_cut, size: 15, color: trimAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'INTRO TRIM OFFSET (FIRST FRAME CUT)',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.outline
                          : AppColors.lightOnSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${provider.introTrimOffset.toStringAsFixed(1)}s',
                  style: TextStyle(
                    color: trimAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: trimAccent,
                thumbColor: trimAccent,
                trackHeight: 3,
              ),
              child: Slider(
                value: provider.introTrimOffset,
                min: 0.0,
                max: 3.0,
                divisions: 30,
                onChanged: provider.setIntroTrimOffset,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnchorPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _AnchorPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final inActiveBg = isDark
        ? AppColors.surfaceContainerHighest
        : AppColors.hairlineBorder;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.18) : inActiveBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? activeColor
                : (isDark ? AppColors.textLight : AppColors.textDark),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
