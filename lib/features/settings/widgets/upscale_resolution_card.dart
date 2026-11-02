import 'package:flutter/material.dart';
import '../../../../core/services/device_capability_service.dart';
import '../../../../core/theme/app_theme.dart';

class UpscaleResolutionCard extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onSelect;
  final DeviceTier tier;

  const UpscaleResolutionCard({
    super.key,
    required this.selectedValue,
    required this.onSelect,
    this.tier = DeviceTier.mid,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warn2k = DeviceCapabilityService.getResolutionWarning(targetKey: '2k', tier: tier);
    final warn4k = DeviceCapabilityService.getResolutionWarning(targetKey: '4k', tier: tier);

    return Column(
      children: [
        _ResolutionOptionTile(
          title: '1080p Full HD (Recommended)',
          subtitle: 'Optimal quality & balance • Lanczos filter',
          resolution: '1920×1080',
          value: '1080p',
          selectedValue: selectedValue,
          isDark: isDark,
          onTap: () => onSelect('1080p'),
        ),
        const SizedBox(height: 8),
        _ResolutionOptionTile(
          title: tier == DeviceTier.flagship ? '2K QHD (Optimal / Safe)' : '2K QHD (Heavy CPU)',
          subtitle: tier == DeviceTier.flagship ? 'Full hardware acceleration • Smooth' : 'Requires heavy CPU usage',
          resolution: '2560×1440',
          value: '2k',
          selectedValue: selectedValue,
          isDark: isDark,
          onTap: () => onSelect('2k'),
          warningTag: warn2k,
        ),
        const SizedBox(height: 8),
        _ResolutionOptionTile(
          title: tier == DeviceTier.flagship ? '4K UHD (Fully Supported)' : '4K UHD (High Compute)',
          subtitle: tier == DeviceTier.flagship ? 'Flagship GPU accelerated • Max detail' : 'Extreme computation load',
          resolution: '3840×2160',
          value: '4k',
          selectedValue: selectedValue,
          isDark: isDark,
          onTap: () => onSelect('4k'),
          warningTag: warn4k,
        ),
      ],
    );
  }
}

class _ResolutionOptionTile extends StatelessWidget {
  final String title, subtitle, resolution, value, selectedValue;
  final VoidCallback onTap;
  final String? warningTag;
  final bool isDark;

  const _ResolutionOptionTile({
    required this.title,
    required this.subtitle,
    required this.resolution,
    required this.value,
    required this.selectedValue,
    required this.isDark,
    required this.onTap,
    this.warningTag,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    final activeBg = isDark ? AppColors.surfaceContainerHigh : const Color(0xFFF5F3FF);
    final inactiveBg = isDark ? AppColors.surfaceContainerLow : Colors.white;
    final activeBorder = isDark ? AppColors.primaryContainer : const Color(0xFF6C5CE7);
    final inactiveBorder = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeBorder : inactiveBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isDark && !isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _OptionRowContent(
                isSelected: isSelected,
                isDark: isDark,
                title: title,
                subtitle: subtitle,
                warningTag: warningTag,
              ),
            ),
            _ResolutionBadge(resolution: resolution, isSelected: isSelected, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _OptionRowContent extends StatelessWidget {
  final bool isSelected, isDark;
  final String title, subtitle;
  final String? warningTag;

  const _OptionRowContent({
    required this.isSelected,
    required this.isDark,
    required this.title,
    required this.subtitle,
    this.warningTag,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final descColor = isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Row(
      children: [
        _RadioIndicator(isSelected: isSelected, isDark: isDark),
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
                      color: textColor,
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
              Text(subtitle, style: TextStyle(color: descColor, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool isSelected, isDark;
  const _RadioIndicator({required this.isSelected, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryContainer : AppColors.lightPrimary;
    final outline = isDark ? AppColors.outline : AppColors.lightOutline;

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? accent : outline,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? (isDark ? AppColors.surfaceContainerLowest : Colors.white)
            : Colors.transparent,
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
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
  final bool isSelected, isDark;

  const _ResolutionBadge({
    required this.resolution,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryContainer : AppColors.lightPrimary;
    final descColor = isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant;
    final inactiveBg = isDark ? AppColors.surfaceContainerLow : AppColors.lightSurfaceContainerLow;
    final inactiveBorder = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? accent.withValues(alpha: 0.12) : inactiveBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? accent.withValues(alpha: 0.4) : inactiveBorder,
        ),
      ),
      child: Text(
        resolution,
        style: TextStyle(
          color: isSelected ? accent : descColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
