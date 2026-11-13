import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HardwareAccelerationCard extends StatelessWidget {
  final bool? enabled;
  final ValueChanged<bool>? onToggle;

  const HardwareAccelerationCard({super.key, this.enabled, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLow : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark
              ? AppColors.surfaceContainerHighest
              : AppColors.lightOutlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.memory, color: AppColors.outline, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hardware Acceleration',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Permanently Disabled (Software Engine Active for 100% '
                    'Quality)',
                    style: TextStyle(
                      color: AppColors.outline,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // onChanged: null keeps the switch permanently locked.
            const Switch(value: false, onChanged: null),
          ],
        ),
      ),
    );
  }
}
