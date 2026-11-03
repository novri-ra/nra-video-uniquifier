import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Row widget for choosing video target framerate (24, 30, 60 FPS).
class SettingFpsSelectorRow extends StatelessWidget {
  final int selectedFps;
  final ValueChanged<int> onChanged;

  const SettingFpsSelectorRow({
    super.key,
    required this.selectedFps,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark
        ? AppColors.outline
        : AppColors.lightOnSurfaceVariant;
    final iconColor = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: iconColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Framerate Video (FPS)',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target framerate output video (-r)',
                      style: TextStyle(color: subColor, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FpsButtonRow(
            selectedFps: selectedFps,
            isDark: isDark,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FpsButtonRow extends StatelessWidget {
  final int selectedFps;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _FpsButtonRow({
    required this.selectedFps,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [24, 30, 60].map((fps) {
        final isSelected = selectedFps == fps;
        final activeColor = isDark ? AppColors.mintSage : AppColors.forestDeep;
        final activeBg = activeColor.withValues(alpha: isDark ? 0.20 : 0.12);
        final inactiveBg = isDark
            ? AppColors.obsidianDark
            : AppColors.hairlineBorder;
        final activeBorder = activeColor;
        final inactiveBorder = isDark
            ? AppColors.outlineVariant
            : AppColors.lightOutlineVariant;
        final textColor = isSelected
            ? activeColor
            : (isDark
                  ? AppColors.onSurfaceVariant
                  : AppColors.lightOnSurfaceVariant);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => onChanged(fps),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? activeBg : inactiveBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? activeBorder : inactiveBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$fps FPS',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
