import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Uniform toggle row with an in-line slider that activates when enabled.
class SettingSliderToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTapSubtitle;
  final double sliderValue;
  final double min;
  final double max;
  final String sliderLabel;
  final ValueChanged<double>? onSliderChanged;

  const SettingSliderToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTapSubtitle,
    required this.sliderValue,
    this.min = 0.0,
    this.max = 100.0,
    required this.sliderLabel,
    this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderRow(
            icon: icon,
            title: title,
            subtitle: subtitle,
            value: value,
            onChanged: onChanged,
            onTapSubtitle: onTapSubtitle,
          ),
          if (value)
            _SliderRow(
              sliderValue: sliderValue,
              min: min,
              max: max,
              sliderLabel: sliderLabel,
              onSliderChanged: onSliderChanged,
            ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTapSubtitle;

  const _HeaderRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTapSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: AppColors.onSurfaceVariant, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    GestureDetector(
                      onTap: onTapSubtitle,
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: onTapSubtitle != null
                              ? AppColors.primaryContainer
                              : AppColors.outline,
                          fontSize: 10,
                          fontFamily: 'monospace',
                          decoration: onTapSubtitle != null
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final double sliderValue, min, max;
  final String sliderLabel;
  final ValueChanged<double>? onSliderChanged;

  const _SliderRow({
    required this.sliderValue,
    required this.min,
    required this.max,
    required this.sliderLabel,
    this.onSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 28, right: 4),
      child: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                activeTrackColor: AppColors.primaryContainer,
                inactiveTrackColor: AppColors.surfaceContainerHighest,
                thumbColor: AppColors.primaryContainer,
                overlayColor: AppColors.primaryContainer.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              ),
              child: Slider(
                value: sliderValue.clamp(min, max),
                min: min,
                max: max,
                onChanged: onSliderChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            sliderLabel,
            style: const TextStyle(
              color: AppColors.primaryContainer,
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
