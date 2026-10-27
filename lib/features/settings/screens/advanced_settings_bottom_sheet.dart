import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../widgets/audio_visual_tuning_card.dart';
import '../widgets/hardware_acceleration_card.dart';
import '../widgets/upscale_resolution_card.dart';

class AdvancedSettingsBottomSheet extends StatelessWidget {
  const AdvancedSettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainerHighest),
          left: BorderSide(color: AppColors.surfaceContainerHighest),
          right: BorderSide(color: AppColors.surfaceContainerHighest),
        ),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: const SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DragHandle(),
            _SheetHeader(),
            Divider(color: AppColors.surfaceContainerHigh, height: 1),
            _SheetBodyContent(),
            Divider(color: AppColors.surfaceContainerHigh, height: 1),
            _ApplySettingsButton(),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advanced Upscale Settings',
                  style: TextStyle(color: AppColors.onSurface, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2),
                Text(
                  'Configure render engine target resolution & hardware allocation',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainer,
              foregroundColor: AppColors.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: AppColors.surfaceContainerHighest),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _SheetBodyContent extends StatelessWidget {
  const _SheetBodyContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OUTPUT TARGET PIPELINE',
            style: TextStyle(
              color: AppColors.outline,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          UpscaleResolutionCard(
            selectedValue: provider.selectedUpscaleTarget,
            onSelect: provider.setUpscaleTarget,
          ),
          const SizedBox(height: 12),
          const AudioVisualTuningCard(),
          const SizedBox(height: 12),
          HardwareAccelerationCard(
            enabled: provider.hardwareAcceleration,
            onToggle: provider.toggleHardwareAcceleration,
          ),
          const SizedBox(height: 10),
          const ShaderTelemetryStrip(),
        ],
      ),
    );
  }
}

class _ApplySettingsButton extends StatelessWidget {
  const _ApplySettingsButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.surfaceContainerLowest,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () => Navigator.of(context).pop(),
        icon: const Text('Apply Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        label: const Icon(Icons.check, size: 18),
      ),
    );
  }
}
