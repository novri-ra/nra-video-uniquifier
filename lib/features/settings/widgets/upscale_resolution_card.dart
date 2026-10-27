import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class UpscaleResolutionCard extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onSelect;

  const UpscaleResolutionCard({
    super.key,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResolutionOptionTile(
          title: '720p HD (Fastest)',
          subtitle: 'Best for older devices',
          resolution: '1280×720',
          value: '720p',
          selectedValue: selectedValue,
          onTap: () => onSelect('720p'),
        ),
        const SizedBox(height: 8),
        _ResolutionOptionTile(
          title: '1080p Full HD (Recommended)',
          subtitle: 'Optimal quality & balance • Lanczos filter',
          resolution: '1920×1080',
          value: '1080p',
          selectedValue: selectedValue,
          onTap: () => onSelect('1080p'),
        ),
        const SizedBox(height: 8),
        _ResolutionOptionTile(
          title: '2K QHD (May lag)',
          subtitle: 'Requires heavy CPU usage',
          resolution: '2560×1440',
          value: '2k',
          selectedValue: selectedValue,
          onTap: () => onSelect('2k'),
          warningTag: 'HIGH THERMAL',
        ),
      ],
    );
  }
}

class _ResolutionOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String resolution;
  final String value;
  final String selectedValue;
  final VoidCallback onTap;
  final String? warningTag;

  const _ResolutionOptionTile({
    required this.title,
    required this.subtitle,
    required this.resolution,
    required this.value,
    required this.selectedValue,
    required this.onTap,
    this.warningTag,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainerHigh : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHighest,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _OptionRowContent(
                isSelected: isSelected,
                title: title,
                subtitle: subtitle,
                warningTag: warningTag,
              ),
            ),
            _ResolutionBadge(resolution: resolution, isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _OptionRowContent extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String subtitle;
  final String? warningTag;

  const _OptionRowContent({
    required this.isSelected,
    required this.title,
    required this.subtitle,
    this.warningTag,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RadioIndicator(isSelected: isSelected),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (warningTag != null) ...[
                    const SizedBox(width: 6),
                    _WarningBadge(label: warningTag!),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool isSelected;
  const _RadioIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primaryContainer : AppColors.outline,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryContainer),
              ),
            )
          : null,
    );
  }
}

class _WarningBadge extends StatelessWidget {
  final String label;
  const _WarningBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning, color: AppColors.error, size: 9),
          const SizedBox(width: 2),
          Text(label, style: const TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ResolutionBadge extends StatelessWidget {
  final String resolution;
  final bool isSelected;

  const _ResolutionBadge({required this.resolution, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.12) : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.4) : AppColors.surfaceContainerHighest,
        ),
      ),
      child: Text(
        resolution,
        style: TextStyle(
          color: isSelected ? AppColors.primaryContainer : AppColors.outline,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
