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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.surfaceContainerHighest),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _EngineStatusLabel(isHardware: provider.hardwareAcceleration)),
            const SizedBox(width: 8),
            const _RenderEstimateLabel(),
          ],
        ),
      ),
    );
  }
}

class _EngineStatusLabel extends StatelessWidget {
  final bool isHardware;
  const _EngineStatusLabel({required this.isHardware});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.memory, color: AppColors.primaryContainer, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isHardware ? 'GPU Accel: Metal / GLES (Active)' : 'Software CPU Fallback',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}

class _RenderEstimateLabel extends StatelessWidget {
  const _RenderEstimateLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          'Est. Render: ~2.4s',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontFamily: 'monospace'),
        ),
        SizedBox(width: 4),
        Icon(Icons.tune, color: AppColors.outline, size: 12),
      ],
    );
  }
}
