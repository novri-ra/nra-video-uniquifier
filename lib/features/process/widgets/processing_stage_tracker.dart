import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProcessingStageTracker extends StatelessWidget {
  final int currentStep;

  const ProcessingStageTracker({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StageStep(label: 'METADATA', isCompleted: currentStep >= 1),
        const SizedBox(width: 6),
        _StageStep(label: 'AUDIO/CROP', isCompleted: currentStep >= 2),
        const SizedBox(width: 6),
        _StageStep(label: 'HASH_GEN', isCompleted: currentStep >= 3),
        const SizedBox(width: 6),
        _StageStep(label: 'RENDER', isCompleted: currentStep >= 4),
      ],
    );
  }
}

class _StageStep extends StatelessWidget {
  final String label;
  final bool isCompleted;

  const _StageStep({
    required this.label,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.primaryContainer : AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isCompleted ? AppColors.onSurface : AppColors.outline,
              fontSize: 8,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
