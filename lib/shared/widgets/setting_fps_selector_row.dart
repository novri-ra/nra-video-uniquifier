import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final subColor = isDark ? AppColors.outline : const Color(0xFF4B5563);
    final iconColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF6C5CE7);

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
          _FpsButtonRow(selectedFps: selectedFps, isDark: isDark, onChanged: onChanged),
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
        final activeBg = isDark
            ? AppColors.primaryContainer.withValues(alpha: 0.2)
            : const Color(0xFF10B981).withValues(alpha: 0.12);
        final inactiveBg = isDark ? AppColors.surfaceContainerLowest : const Color(0xFFF3F4F6);
        final activeBorder = isDark ? AppColors.primaryContainer : const Color(0xFF10B981);
        final inactiveBorder = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
        final textColor = isSelected
            ? (isDark ? AppColors.primaryContainer : const Color(0xFF047857))
            : (isDark ? AppColors.onSurfaceVariant : const Color(0xFF374151));

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
