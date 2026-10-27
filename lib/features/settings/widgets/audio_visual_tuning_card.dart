import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AudioVisualTuningCard extends StatelessWidget {
  final double pitchShiftPercent;
  final double cropPixels;
  final ValueChanged<double>? onPitchChanged;
  final ValueChanged<double>? onCropChanged;

  const AudioVisualTuningCard({
    super.key,
    this.pitchShiftPercent = 0.5,
    this.cropPixels = 2.0,
    this.onPitchChanged,
    this.onCropChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: AppColors.primaryContainer, size: 16),
              SizedBox(width: 8),
              Text(
                'FINE-GRAIN FILTER MODIFIERS',
                style: TextStyle(
                  color: AppColors.outline,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TuningSliderRow(
            icon: Icons.graphic_eq,
            title: 'Audio Pitch Shift',
            valueLabel: '+${pitchShiftPercent.toStringAsFixed(1)}%',
            value: pitchShiftPercent,
            min: 0.1,
            max: 2.0,
            onChanged: onPitchChanged,
          ),
          const Divider(color: AppColors.surfaceContainerHighest, height: 16),
          _TuningSliderRow(
            icon: Icons.crop,
            title: 'Visual Micro-Crop',
            valueLabel: '${cropPixels.toInt()} px border',
            value: cropPixels,
            min: 1.0,
            max: 8.0,
            onChanged: onCropChanged,
          ),
        ],
      ),
    );
  }
}

class _TuningSliderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  const _TuningSliderRow({
    required this.icon,
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.onSurfaceVariant, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: AppColors.onSurface, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: AppColors.surfaceContainerHighest),
          ),
          child: Text(
            valueLabel,
            style: const TextStyle(
              color: AppColors.primaryContainer,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
