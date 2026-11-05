import 'package:flutter/material.dart';
import '../../../../core/providers/uniquifier_provider.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/category_accordion_card.dart';
import '../../../../shared/widgets/setting_fps_selector_row.dart';
import '../../../../shared/widgets/interactive_preview_slider.dart';
import '../../../../shared/widgets/setting_toggle_row.dart';
import 'studio_custom_sliders_card.dart';

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
              removeMetadata: true,
              modifyAudio: true,
              modifyVisuals: true,
              upscale1080p: false,
              upscaleTarget: '1080p',
              enableEnhanceAndDenoise: false,
              enableDeepAntiFingerprint: true,
              enableHorizontalFlip: true,
              enableAutoTrim: true,
              enableDynamicZoom: true,
              enableBlurredCanvas: true,
              canvasScalePercent: 95.0,
              targetFps: 30,
              presetName: 'TikTok / Reels',
            ),
          ),
          const SizedBox(width: 6),
          _PresetChip(
            label: 'Cinematic 2K/4K',
            isSelected: provider.activePreset == 'Cinematic 2K/4K',
            onTap: () => provider.applyPreset(
              removeMetadata: true,
              modifyAudio: true,
              modifyVisuals: true,
              upscale1080p: true,
              upscaleTarget: '2k',
              enableEnhanceAndDenoise: true,
              enableDeepAntiFingerprint: false,
              enableHorizontalFlip: false,
              enableBlurredCanvas: false,
              presetName: 'Cinematic 2K/4K',
            ),
          ),
          const SizedBox(width: 6),
          _PresetChip(
            label: 'Quick Export',
            isSelected: provider.activePreset == 'Quick Export',
            onTap: () => provider.applyPreset(
              removeMetadata: true,
              modifyAudio: false,
              modifyVisuals: false,
              upscale1080p: false,
              upscaleTarget: '1080p',
              enableEnhanceAndDenoise: false,
              enableDeepAntiFingerprint: false,
              enableHorizontalFlip: false,
              enableBlurredCanvas: false,
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
  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final inactiveBg = isDark
        ? AppColors.obsidianDark
        : AppColors.hairlineBorder;
    final activeText = isDark ? AppColors.obsidianBase : AppColors.white;
    final inactiveText = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final borderColor = isSelected
        ? activeBg
        : (isDark ? AppColors.outlineVariant : AppColors.lightOutlineVariant);

    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? activeText : inactiveText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
      backgroundColor: isSelected ? activeBg : inactiveBg,
      side: BorderSide(color: borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onPressed: onTap,
    );
  }
}

class ModifiersHeader extends StatelessWidget {
  const ModifiersHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'PROCESSING SETTINGS',
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '15 MODIFIERS',
          style: TextStyle(
            color: textColor,
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
        final coreActive =
            (provider.removeMetadata ? 1 : 0) +
            (provider.enableDeepAntiFingerprint ? 1 : 0) +
            (provider.enableAutoTrim ? 1 : 0);

        final visualActive =
            (provider.modifyVisuals ? 1 : 0) +
            (provider.upscale1080p ? 1 : 0) +
            (provider.enableEnhanceAndDenoise ? 1 : 0) +
            (provider.enableHorizontalFlip ? 1 : 0) +
            (provider.enableDynamicZoom ? 1 : 0) +
            (provider.enableFrameSkip ? 1 : 0);

        final textureActive =
            (provider.enableBlurredCanvas ? 1 : 0) +
            (provider.enableChromaShift ? 1 : 0) +
            (provider.enableMicroOverlay ? 1 : 0) +
            (provider.sharpeningLevel != 1.0 ? 1 : 0) +
            (provider.saturationLevel != 1.0 ? 1 : 0);

        final audioActive =
            (provider.modifyAudio ? 1 : 0) +
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
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
                SettingToggleRow(
                  icon: Icons.shield_outlined,
                  title: 'Deep Evasion',
                  subtitle: '8% margin crop & 0.8° tilt',
                  value: provider.enableDeepAntiFingerprint,
                  onChanged: provider.toggleDeepAntiFingerprint,
                ),
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
                SettingToggleRow(
                  icon: Icons.content_cut,
                  title: 'Auto-Trim',
                  subtitle: 'Cuts 0.5s intro & outro',
                  value: provider.enableAutoTrim,
                  onChanged: provider.toggleAutoTrim,
                ),
                if (provider.enableDeepAntiFingerprint ||
                    provider.enableAutoTrim)
                  StudioCustomSlidersCard(provider: provider),
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
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
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
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
                SettingToggleRow(
                  icon: Icons.auto_fix_high,
                  title: 'Denoise & Clarity',
                  subtitle: 'HQ denoise & unsharp mask',
                  value: provider.enableEnhanceAndDenoise,
                  onChanged: provider.toggleEnhanceAndDenoise,
                ),
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
                SettingToggleRow(
                  icon: Icons.flip,
                  title: 'Horizontal Flip',
                  subtitle: 'Mirrors video landmarks',
                  value: provider.enableHorizontalFlip,
                  onChanged: provider.toggleHorizontalFlip,
                ),
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
                SettingToggleRow(
                  icon: Icons.zoom_in,
                  title: 'Dynamic Zoom Motion',
                  subtitle: 'Continuous 1.0x-1.08x focal shift',
                  value: provider.enableDynamicZoom,
                  onChanged: provider.toggleDynamicZoom,
                ),
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
                SettingToggleRow(
                  icon: Icons.speed,
                  title: 'Temporal Frame Skip',
                  subtitle: 'Decimates cadence periodicity',
                  value: provider.enableFrameSkip,
                  onChanged: provider.toggleFrameSkip,
                ),
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
                SettingFpsSelectorRow(
                  selectedFps: provider.targetFps,
                  onChanged: provider.setTargetFps,
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
                SettingToggleRow(
                  icon: Icons.blur_on,
                  title: 'Blurred Canvas Frame',
                  subtitle: 'Padded background blur',
                  value: provider.enableBlurredCanvas,
                  onChanged: provider.toggleBlurredCanvas,
                ),
                if (provider.enableBlurredCanvas) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: InteractivePreviewSlider(
                      value: provider.canvasScalePercent.clamp(70.0, 100.0),
                      min: 70.0,
                      max: 100.0,
                      divisions: 30,
                      label: '${provider.canvasScalePercent.toInt()}%',
                      parameterName: 'BLURRED CANVAS SCALE',
                      effect: PreviewEffect.canvasScale,
                      thumbnailPath: provider.thumbnailPath,
                      isPreviewRendering: provider.isPreviewRendering,
                      renderedPreviewFramePath:
                          provider.renderedPreviewFramePath,
                      onChanged: (val) {
                        provider.setCanvasScalePercent(val);
                        provider.requestFilteredPreviewDebounced();
                      },
                      onChangeEnd: (_) {
                        provider.requestFilteredPreviewDebounced(
                          immediate: true,
                        );
                      },
                    ),
                  ),
                ],
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
                SettingToggleRow(
                  icon: Icons.palette_outlined,
                  title: 'Film Chroma Shift',
                  subtitle: 'Matte RGB histogram curve',
                  value: provider.enableChromaShift,
                  onChanged: provider.toggleChromaShift,
                ),
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
                SettingToggleRow(
                  icon: Icons.grain,
                  title: 'Micro-Noise Overlay',
                  subtitle: 'Temporal noise texture overlay',
                  value: provider.enableMicroOverlay,
                  onChanged: provider.toggleMicroOverlay,
                ),
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: InteractivePreviewSlider(
                    value: provider.sharpeningLevel.clamp(0.1, 2.0),
                    min: 0.1,
                    max: 2.0,
                    divisions: 19,
                    label: '${provider.sharpeningLevel.toStringAsFixed(1)}x',
                    parameterName:
                        AppLocalizations.of(context)?.sharpeningLabel ??
                        'SHARPENING INTENSITY',
                    effect: PreviewEffect.sharpening,
                    thumbnailPath: provider.thumbnailPath,
                    isPreviewRendering: provider.isPreviewRendering,
                    renderedPreviewFramePath: provider.renderedPreviewFramePath,
                    onChanged: (val) {
                      provider.setSharpeningLevel(val);
                      provider.requestFilteredPreviewDebounced();
                    },
                    onChangeEnd: (_) {
                      provider.requestFilteredPreviewDebounced(immediate: true);
                    },
                  ),
                ),
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: InteractivePreviewSlider(
                    value: provider.saturationLevel.clamp(0.8, 1.3),
                    min: 0.8,
                    max: 1.3,
                    divisions: 10,
                    label: '${provider.saturationLevel.toStringAsFixed(2)}x',
                    parameterName:
                        AppLocalizations.of(context)?.saturationLabel ??
                        'SATURATION / VIBRANCE',
                    effect: PreviewEffect.saturation,
                    thumbnailPath: provider.thumbnailPath,
                    isPreviewRendering: provider.isPreviewRendering,
                    renderedPreviewFramePath: provider.renderedPreviewFramePath,
                    onChanged: (val) {
                      provider.setSaturationLevel(val);
                      provider.requestFilteredPreviewDebounced();
                    },
                    onChangeEnd: (_) {
                      provider.requestFilteredPreviewDebounced(immediate: true);
                    },
                  ),
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
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
                SettingToggleRow(
                  icon: Icons.waves,
                  title: 'Audio Masking',
                  subtitle: 'Ambient pink noise layer',
                  value: provider.enableAggressiveAudio,
                  onChanged: provider.toggleAggressiveAudio,
                ),
                const Divider(
                  color: AppColors.surfaceContainerHighest,
                  height: 1,
                ),
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
