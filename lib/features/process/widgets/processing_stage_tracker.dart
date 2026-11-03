import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProcessingStageTracker extends StatelessWidget {
  final int currentStep;

  const ProcessingStageTracker({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StageStep(
          label: 'METADATA',
          isCompleted: currentStep > 1,
          isActive: currentStep == 1,
        ),
        const SizedBox(width: 4),
        _StageStep(
          label: 'TRANSFORM',
          isCompleted: currentStep > 2,
          isActive: currentStep == 2,
        ),
        const SizedBox(width: 4),
        _StageStep(
          label: 'FILTERGRAPH',
          isCompleted: currentStep > 3,
          isActive: currentStep == 3,
        ),
        const SizedBox(width: 4),
        _StageStep(
          label: 'ENCODE',
          isCompleted: currentStep > 4,
          isActive: currentStep == 4,
        ),
        const SizedBox(width: 4),
        _StageStep(
          label: 'EXPORT',
          isCompleted: currentStep > 5,
          isActive: currentStep == 5,
        ),
      ],
    );
  }
}

class _StageStep extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isActive;

  const _StageStep({
    required this.label,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color lineColor;
    if (isActive) {
      lineColor = AppColors.vividCoral;
    } else if (isCompleted) {
      lineColor = isDark ? AppColors.mintSage : AppColors.forestDeep;
    } else {
      lineColor = isDark ? AppColors.obsidianDark : AppColors.hairlineBorder;
    }

    final Color textColor;
    final FontWeight fontWeight;
    if (isActive || isCompleted) {
      textColor = isDark ? AppColors.mintSage : AppColors.forestDeep;
      fontWeight = FontWeight.w800;
    } else {
      textColor = isDark
          ? AppColors.textLight.withValues(alpha: 0.40)
          : AppColors.textDark.withValues(alpha: 0.40);
      fontWeight = FontWeight.w600;
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3.0,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 7.5,
              fontWeight: fontWeight,
              letterSpacing: 0.8,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
