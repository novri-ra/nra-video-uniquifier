import 'package:flutter/material.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/setting_toggle_row.dart';

class HardwareAccelerationCard extends StatelessWidget {
  final bool? enabled;
  final ValueChanged<bool>? onToggle;

  const HardwareAccelerationCard({
    super.key,
    this.enabled,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SettingsService.hardwareAccelerationNotifier,
      builder: (context, hwAccel, _) {
        final active = enabled ?? hwAccel;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.surfaceContainerHighest),
          ),
          child: SettingToggleRow(
            icon: Icons.memory,
            title: 'Hardware Acceleration',
            subtitle: 'Force OpenGLES/Metal Shader Pipeline',
            value: active,
            onChanged: onToggle ?? SettingsService.setHardwareAcceleration,
          ),
        );
      },
    );
  }
}
