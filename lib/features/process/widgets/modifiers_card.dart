import 'package:flutter/material.dart';
import '../../../../core/providers/uniquifier_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/setting_slider_toggle_row.dart';
import '../../../../shared/widgets/setting_toggle_row.dart';

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
            (provider.enableMicroOverlay ? 1 : 0);

        final audioActive = (provider.modifyAudio ? 1 : 0) +
            (provider.enableAggressiveAudio ? 1 : 0) +
            (provider.muteOriginalAudio ? 1 : 0);

        return Column(
          children: [
            _CategoryAccordionCard(
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
            _CategoryAccordionCard(
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
                  subtitle: 'Lanczos algorithm (${provider.targetResolutionDetails})',
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
            _CategoryAccordionCard(
              title: 'FRAMING & TEXTURE',
              icon: Icons.auto_awesome_mosaic,
              activeCount: textureActive,
              totalCount: 3,
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
              ],
            ),
            const SizedBox(height: 8),
            _CategoryAccordionCard(
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

class _CategoryAccordionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final int activeCount;
  final int totalCount;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _CategoryAccordionCard({
    required this.title,
    required this.icon,
    required this.activeCount,
    required this.totalCount,
    this.initiallyExpanded = false,
    required this.children,
  });

  @override
  State<_CategoryAccordionCard> createState() => _CategoryAccordionCardState();
}

class _CategoryAccordionCardState extends State<_CategoryAccordionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(widget.icon, color: AppColors.primaryContainer, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.activeCount > 0
                              ? AppColors.primaryContainer.withValues(alpha: 0.15)
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: widget.activeCount > 0
                                ? AppColors.primaryContainer.withValues(alpha: 0.4)
                                : AppColors.surfaceContainerHighest,
                          ),
                        ),
                        child: Text(
                          '${widget.activeCount}/${widget.totalCount} ACTIVE',
                          style: TextStyle(
                            color: widget.activeCount > 0
                                ? AppColors.primaryContainer
                                : AppColors.outline,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.onSurfaceVariant,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(color: AppColors.surfaceContainerHighest, height: 1),
            ...widget.children,
          ],
        ],
      ),
    );
  }
}
