import 'package:flutter/material.dart';

import '../../../../core/providers/uniquifier_provider.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/category_accordion_card.dart';
import '../../../../shared/widgets/interactive_preview_slider.dart';
import '../../../../shared/widgets/setting_fps_selector_row.dart';
import '../../../../shared/widgets/setting_toggle_row.dart';
import 'studio_custom_sliders_card.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

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
            label: 'TikTok Extreme',
            isSelected: provider.activePreset == 'TikTok Extreme',
            onTap: () => provider.applyPreset(
              removeMetadata: true,
              modifyAudio: true,
              modifyVisuals: true,
              upscale1080p: false,
              upscaleTarget: '1080p',

              // Maximum evasion stack
              enableEnhanceAndDenoise: false,
              enableDeepAntiFingerprint:
                  true, // (Crop 8-12%, Speed Warp, Pitch Shift)
              enableHorizontalFlip: true, // (Mirroring)
              enableAutoTrim: true, // (Trim first/last frames)
              // Blurred canvas (required for TikTok aesthetic)
              enableBlurredCanvas: true,
              canvasScalePercent: 90.0, // 90% scale (more aggressive than 95%)
              // Additional filters
              enableChromaShift: true, // (Color shift)
              enableMicroOverlay: true, // (Extra noise)
              enableAggressiveAudio: true, // (Pink noise)
              // Heavy filters (kept off to prevent phone overheating)
              enableDynamicZoom: false,
              enableFrameSkip: false,

              targetFps: 30,
              presetName: 'TikTok Extreme',
            ),
          ),
          const SizedBox(width: 6),
          // --- ADD MICROSTOCK PRESET HERE ---
          _PresetChip(
            label: 'Microstock 4K',
            isSelected: provider.activePreset == 'Microstock 4K',
            onTap: () => provider.applyPreset(
              removeMetadata: true, // Must be clean of EXIF/GPS
              modifyAudio: false, // Original audio unchanged
              modifyVisuals: false, // No crop or speed warp
              upscale1080p: true, // Enable upscaler
              upscaleTarget:
                  '4k', // 4K target (highest quality tier for agencies)
              enableEnhanceAndDenoise:
                  true, // Adds a clarity pass (unsharp mask)
              enableDeepAntiFingerprint: false, // Off (no evasion needed)
              enableHorizontalFlip: false,
              enableAutoTrim: false,
              enableDynamicZoom: false,
              enableChromaShift: false,
              enableMicroOverlay: false,
              enableAggressiveAudio: false,
              enableBlurredCanvas: false,
              presetName: 'Microstock 4K',
            ),
          ),
          const SizedBox(width: 6),
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

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Pilih LUT: $label',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Center(
          child: ActionChip(
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
          ),
        ),
      ),
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
            (provider.lutName.isNotEmpty ? 1 : 0) +
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
              totalCount: 6,
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
                _LutSelectorRow(
                  selectedLut: provider.lutName,
                  onChanged: (val) {
                    provider.lutName = val;
                    provider.requestFilteredPreviewDebounced(immediate: true);
                  },
                  provider: provider,
                ),

                // --- PROGRESSIVE DISCLOSURE: SHARPENING ---
                if (provider.enableEnhanceAndDenoise) ...[
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
                      renderedPreviewFramePath:
                          provider.renderedPreviewFramePath,
                      onChanged: (val) {
                        provider.setSharpeningLevel(val);
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

                // --- PROGRESSIVE DISCLOSURE: SATURATION ---
                if (provider.modifyVisuals) ...[
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
                      renderedPreviewFramePath:
                          provider.renderedPreviewFramePath,
                      onChanged: (val) {
                        provider.setSaturationLevel(val);
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

class _LutSelectorRow extends StatelessWidget {
  final String selectedLut;
  final ValueChanged<String> onChanged;
  final UniquifierProvider provider;

  const _LutSelectorRow({
    required this.selectedLut,
    required this.onChanged,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark
        ? AppColors.outline
        : AppColors.lightOnSurfaceVariant;
    final iconColor = isDark ? AppColors.mintSage : AppColors.forestDeep;

    final basePresets = [
      ('', 'None'),
      ('cinematic_warm', 'Cinematic Warm'),
      ('moody_teal', 'Moody Teal'),
      ('vintage_film', 'Vintage Film'),
      ('high_contrast_bw', 'High Contrast B&W'),
    ];

    String? customLabel;
    if (selectedLut.isNotEmpty && (selectedLut.endsWith('.cube') || selectedLut.startsWith('/'))) {
      if (!basePresets.any((p) => p.$1 == selectedLut)) {
        final fileName = selectedLut.split(Platform.pathSeparator).last.replaceAll('.cube', '');
        customLabel = fileName.length > 15 ? '${fileName.substring(0, 12)}...' : fileName;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.color_lens_outlined, color: iconColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color Grading LUT',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '3D LUT color filter preset (.cube)',
                      style: TextStyle(color: subColor, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...basePresets.map((preset) {
                  final key = preset.$1;
                  final label = preset.$2;
                  final isSelected = selectedLut == key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _PresetChip(
                      label: label,
                      isSelected: isSelected,
                      onTap: () => onChanged(key),
                    ),
                  );
                }),
                if (customLabel != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _PresetChip(
                      label: 'Custom: $customLabel',
                      isSelected: true,
                      onTap: () {},
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Semantics(
                    button: true,
                    label: 'Impor file LUT kustom',
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                      child: Center(
                        child: ActionChip(
                          label: const Text(
                            '+ Import Custom LUT...',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                          onPressed: () async {
                            try {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['cube'],
                              );
                              if (!context.mounted) return;
                              if (result == null || result.files.single.path == null) return;
                              final absPath = result.files.single.path!;
                              // Validasi ukuran file maksimal 5MB
                              final fileSize = await File(absPath).length();
                              if (fileSize > 5 * 1024 * 1024) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'File terlalu besar (maksimal 5MB). Ukuran: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB',
                                    ),
                                  ),
                                );
                                return;
                              }
                              // Validasi header LUT (.cube) - baca 100 byte pertama
                              final allBytes = await File(absPath).readAsBytes();
                              final header = String.fromCharCodes(allBytes.sublist(0, 100));
                              if (!header.contains('LUT_3D_SIZE') && !header.contains('TITLE')) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'File LUT tidak valid. Header .cube tidak ditemukan (harus berisi LUT_3D_SIZE atau TITLE).',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final docsDir = await getApplicationDocumentsDirectory();
                              final customDir = Directory('${docsDir.path}/custom_luts');
                              if (!await customDir.exists()) {
                                await customDir.create(recursive: true);
                              }
                              final fileName = absPath.split(Platform.pathSeparator).last;
                              final savedFile = await File(absPath).copy('${customDir.path}/$fileName');
                              provider.lutName = savedFile.path;
                              provider.requestFilteredPreviewDebounced(immediate: true);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('LUT kustom berhasil diimport!'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal mengimpor LUT: ${e.toString()}'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
