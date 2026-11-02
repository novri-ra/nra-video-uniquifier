import 'package:flutter/material.dart';
import '../../../../core/providers/uniquifier_provider.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/category_accordion_card.dart';
import '../../../../shared/widgets/setting_slider_toggle_row.dart';
import '../../../../shared/widgets/setting_toggle_row.dart';

class PresetChipRow extends StatelessWidget {
  final UniquifierProvider provider;
  const PresetChipRow({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PresetChip(
            label: 'TikTok / Reels',
            isSelected: provider.activePreset == 'TikTok / Reels',
            onTap: () => provider.applyPreset(
              removeMetadata: true, modifyAudio: true, modifyVisuals: true,
              upscale1080p: false, upscaleTarget: '1080p',
              enableEnhanceAndDenoise: false, enableDeepAntiFingerprint: true,
              enableHorizontalFlip: true, enableAutoTrim: true,
              enableBlurredCanvas: true, canvasScalePercent: 95.0,
              presetName: 'TikTok / Reels',
            ),
          ),
          const SizedBox(width: 6),
          _PresetChip(
            label: 'Cinematic 2K/4K',
            isSelected: provider.activePreset == 'Cinematic 2K/4K',
            onTap: () => provider.applyPreset(
              removeMetadata: true, modifyAudio: true, modifyVisuals: true,
              upscale1080p: true, upscaleTarget: '2k',
              enableEnhanceAndDenoise: true, enableDeepAntiFingerprint: false,
              enableHorizontalFlip: false, enableBlurredCanvas: false,
              presetName: 'Cinematic 2K/4K',
            ),
          ),
          const SizedBox(width: 6),
          _PresetChip(
            label: 'Quick Export',
            isSelected: provider.activePreset == 'Quick Export',
            onTap: () => provider.applyPreset(
              removeMetadata: true, modifyAudio: false, modifyVisuals: false,
              upscale1080p: false, upscaleTarget: '1080p',
              enableEnhanceAndDenoise: false, enableDeepAntiFingerprint: false,
              enableHorizontalFlip: false, enableBlurredCanvas: false,
              presetName: 'Quick Export',
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: TextStyle(
        color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
        fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace',
      )),
      backgroundColor: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
      side: BorderSide(color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHighest),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      onPressed: onTap,
    );
  }
}

class ModifiersHeader extends StatelessWidget {
  const ModifiersHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'PROCESSING SETTINGS',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8),
        Text(
          '15 MODIFIERS',
          style: TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class ModifiersCard extends StatelessWidget {
  final UniquifierProvider provider;
  final VoidCallback onOpenAdvanced;

  const ModifiersCard({
    super.key,
    required this.provider,
    required this.onOpenAdvanced,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final coreActive = (provider.removeMetadata ? 1 : 0) +
            (provider.enableDeepAntiFingerprint ? 1 : 0) +
            (provider.enableAutoTrim ? 1 : 0);

        final visualActive = (provider.modifyVisuals ? 1 : 0) +
            (provider.upscale1080p ? 1 : 0) +
            (provider.enableEnhanceAndDenoise ? 1 : 0) +
            (provider.enableHorizontalFlip ? 1 : 0) +
            (provider.enableDynamicZoom ? 1 : 0) +
            (provider.enableFrameSkip ? 1 : 0);

        final textureActive = (provider.enableBlurredCanvas ? 1 : 0) +
            (provider.enableChromaShift ? 1 : 0) +
            (provider.enableMicroOverlay ? 1 : 0) +
            (provider.sharpeningLevel != 1.0 ? 1 : 0) +
            (provider.saturationLevel != 1.0 ? 1 : 0);

        final audioActive = (provider.modifyAudio ? 1 : 0) +
            (provider.enableAggressiveAudio ? 1 : 0) +
            (provider.muteOriginalAudio ? 1 : 0);

        return Column(
          children: [
            CategoryAccordionCard(
              title: 'CORE PROTECTION',
              icon: Icons.security,
              activeCount: coreActive,
              totalCount: 3,
              initiallyExpanded: true,
              children: [
                SettingToggleRow(
                  icon: Icons.fingerprint,
                  title: 'Remove Metadata',
                  subtitle: 'Cleans GPS & device info',
                  value: provider.removeMetadata,
                  onChanged: provider.toggleRemoveMetadata,
                ),
                const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                SettingToggleRow(
                  icon: Icons.shield_outlined,
                  title: 'Deep Evasion',
                  subtitle: '8% margin crop & 0.8° tilt',
                  value: provider.enableDeepAntiFingerprint,
                  onChanged: provider.toggleDeepAntiFingerprint,
                ),
                const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                SettingToggleRow(
                  icon: Icons.content_cut,
                  title: 'Auto-Trim',
                  subtitle: 'Cuts 0.5s intro & outro',
                  value: provider.enableAutoTrim,
                  onChanged: provider.toggleAutoTrim,
                ),
              ],
            ),
            const SizedBox(height: 8),
            CategoryAccordionCard(
              title: 'VISUAL & MOTION',
              icon: Icons.motion_photos_on,
              activeCount: visualActive,
              totalCount: 6,
              initiallyExpanded: true,
              children: [
                SettingToggleRow(
                  icon: Icons.crop,
                  title: 'Modify Visuals',
                  subtitle: 'Micro-crop & color tweak',
                  value: provider.modifyVisuals,
                  onChanged: provider.toggleModifyVisuals,
                ),
                const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                SettingToggleRow(
                  icon: Icons.hd,
                  title: 'Upscale to ${provider.targetResolutionLabel}',
                  subtitle: provider.upscaleEngine == UpscaleEngine.neuralAi
                      ? 'Real-ESRGAN AI (${provider.targetResolutionDetails})'
                      : 'Lanczos algorithm (${provider.targetResolutionDetails})',
                  value: provider.upscale1080p,
                  onChanged: provider.toggleUpscale1080p,
                  onTapSubtitle: onOpenAdvanced,
                ),
                const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                SettingToggleRow(
                  icon: Icons.auto_fix_high,
                  title: 'Denoise & Clarity',
                  subtitle: 'HQ denoise & unsharp mask',
                  value: provider.enableEnhanceAndDenoise,
                  onChanged: provider.toggleEnhanceAndDenoise,
                ),
                const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                SettingToggleRow(
                  icon: Icons.flip,
                  title: 'Horizontal Flip',
                  subtitle: 'Mirrors video landmarks',
                  value: provider.enableHorizontalFlip,
                  onChanged: provider.toggleHorizontalFlip,
                ),
                const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                SettingToggleRow(
                  icon: Icons.zoom_in,
                  title: 'Dynamic Zoom Motion',
                  subtitle: 'Continuous 1.0x-1.08x focal shift',
                  value: provider.enableDynamicZoom,
                  onChanged: provider.toggleDynamicZoom,
                ),
                const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                SettingToggleRow(
                  icon: Icons.speed,
                  title: 'Temporal Frame Skip',
                  subtitle: 'Decimates cadence periodicity',
                  value: provider.enableFrameSkip,
                  onChanged: provider.toggleFrameSkip,
                ),
              ],
            ),
            const SizedBox(height: 8),
            CategoryAccordionCard(
              title: 'FRAMING & TEXTURE',
              icon: Icons.auto_awesome_mosaic,
              activeCount: textureActive,
              totalCount: 5,
              initiallyExpanded: true,
              children: [
                SettingSliderToggleRow(
                  icon: Icons.blur_on,
                  title: 'Blurred Canvas Frame',
                  subtitle: 'Padded background blur',
                  value: provider.enableBlurredCanvas,
                  onChanged: provider.toggleBlurredCanvas,
                  sliderValue: provider.canvasScalePercent,
                  sliderLabel: 'Scale: ${provider.canvasScalePercent.toInt()}%',
                  onSliderChanged: provider.setCanvasScalePercent,
                ),
                const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                SettingToggleRow(
                  icon: Icons.palette_outlined,
                  title: 'Film Chroma Shift',
                  subtitle: 'Matte RGB histogram curve',
                  value: provider.enableChromaShift,
                  onChanged: provider.toggleChromaShift,
                ),
                const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                SettingToggleRow(
                  icon: Icons.grain,
                  title: 'Micro-Noise Overlay',
                  subtitle: 'Temporal noise texture overlay',
                  value: provider.enableMicroOverlay,
                  onChanged: provider.toggleMicroOverlay,
                ),
                const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                SettingSliderToggleRow(
                  icon: Icons.deblur,
                  title: 'Sharpening Level',
                  subtitle: 'Adjust unsharp mask intensity',
                  value: true,
                  onChanged: (_) {},
                  sliderValue: provider.sharpeningLevel * 100,
                  min: 20.0,
                  max: 200.0,
                  sliderLabel: '${provider.sharpeningLevel.toStringAsFixed(1)}x',
                  onSliderChanged: (v) => provider.setSharpeningLevel(v / 100),
                ),
                const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                SettingSliderToggleRow(
                  icon: Icons.color_lens_outlined,
                  title: 'Saturation Level',
                  subtitle: 'Color intensity control',
                  value: true,
                  onChanged: (_) {},
                  sliderValue: provider.saturationLevel * 100,
                  min: 80.0,
                  max: 130.0,
                  sliderLabel: '${provider.saturationLevel.toStringAsFixed(2)}x',
                  onSliderChanged: (v) => provider.setSaturationLevel(v / 100),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CategoryAccordionCard(
              title: 'AUDIO MASKING',
              icon: Icons.graphic_eq,
              activeCount: audioActive,
              totalCount: 3,
              initiallyExpanded: true,
              children: [
                SettingToggleRow(
                  icon: Icons.graphic_eq,
                  title: 'Modify Audio',
                  subtitle: 'Shift pitch by 0.5%',
                  value: provider.modifyAudio,
                  onChanged: provider.toggleModifyAudio,
                ),
                const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                SettingToggleRow(
                  icon: Icons.waves,
                  title: 'Audio Masking',
                  subtitle: 'Ambient pink noise layer',
                  value: provider.enableAggressiveAudio,
                  onChanged: provider.toggleAggressiveAudio,
                ),
                const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                SettingToggleRow(
                  icon: Icons.volume_off,
                  title: 'Mute Original Audio',
                  subtitle: 'Ducks audio for music overlay',
                  value: provider.muteOriginalAudio,
                  onChanged: provider.toggleMuteOriginalAudio,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
