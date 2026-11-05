import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/providers/uniquifier_provider.dart';
import '../../../../core/theme/app_colors.dart';

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
    final cardBg = isDark ? AppColors.obsidianDark : AppColors.white;
    final borderColor = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;

    final isSmallScreen = MediaQuery.of(context).size.width < 340;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _EngineStatusLabel(
                isHardware: provider.hardwareAcceleration,
                isDark: isDark,
                compact: isSmallScreen,
              ),
            ),
            const SizedBox(width: 6),
            _RenderEstimateLabel(
              isDark: isDark,
              durationMs: provider.totalDurationMs,
              compact: isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _EngineStatusLabel extends StatelessWidget {
  final bool isHardware, isDark, compact;
  const _EngineStatusLabel({
    required this.isHardware,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final textColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.textDark.withValues(alpha: 0.75);
    final gpuLabel = Platform.isAndroid
        ? (compact ? 'MediaCodec' : 'GPU: MediaCodec / Vulkan')
        : (compact ? 'Metal/GLES' : 'GPU: Metal / GLES');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.memory, color: iconColor, size: 14),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            isHardware ? '$gpuLabel (Active)' : 'Software CPU Fallback',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _RenderEstimateLabel extends StatelessWidget {
  final bool isDark;
  final int durationMs;
  final bool compact;
  const _RenderEstimateLabel({
    required this.isDark,
    this.durationMs = 0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.textDark.withValues(alpha: 0.75);
    final iconColor = isDark ? AppColors.outline : AppColors.forestDeep;

    final estimateText = durationMs > 0
        ? (compact
              ? '~${(durationMs / 1000 * 0.45).clamp(1.5, 300.0).toStringAsFixed(1)}s'
              : 'Est: ~${(durationMs / 1000 * 0.45).clamp(1.5, 300.0).toStringAsFixed(1)}s')
        : (compact ? 'Dynamic' : 'Est: Dynamic');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          estimateText,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.tune, color: iconColor, size: 12),
      ],
    );
  }
}
