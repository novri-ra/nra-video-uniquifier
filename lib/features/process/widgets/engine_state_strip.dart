import 'package:flutter/material.dart';
import '../../../../core/providers/uniquifier_provider.dart';
import '../../../../core/theme/app_theme.dart';

class EngineStateStrip extends StatelessWidget {
  final UniquifierProvider provider;
  final VoidCallback onTap;

  const EngineStateStrip({
    super.key,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceContainerLowest : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.surfaceContainerHighest : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _EngineStatusLabel(isHardware: provider.hardwareAcceleration, isDark: isDark)),
            const SizedBox(width: 8),
            _RenderEstimateLabel(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _EngineStatusLabel extends StatelessWidget {
  final bool isHardware, isDark;
  const _EngineStatusLabel({required this.isHardware, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? AppColors.primaryContainer : const Color(0xFF6C5CE7);
    final textColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF0F172A);

    return Row(
      children: [
        Icon(Icons.memory, color: iconColor, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isHardware ? 'GPU Accel: Metal / GLES (Active)' : 'Software CPU Fallback',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textColor, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _RenderEstimateLabel extends StatelessWidget {
  final bool isDark;
  const _RenderEstimateLabel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);
    final iconColor = isDark ? AppColors.outline : const Color(0xFF6B7280);

    return Row(
      children: [
        Text(
          'Est. Render: ~2.4s',
          style: TextStyle(color: textColor, fontSize: 11, fontFamily: 'monospace'),
        ),
        const SizedBox(width: 4),
        Icon(Icons.tune, color: iconColor, size: 12),
      ],
    );
  }
}
