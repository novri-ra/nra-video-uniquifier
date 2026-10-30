import 'package:flutter/material.dart';
import '../../../../core/providers/uniquifier_provider.dart';
import '../../../../core/theme/app_theme.dart';

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
          '11 MODIFIERS',
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
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.surfaceContainerHighest),
          ),
          child: Column(
            children: [
              _ToggleRow(
                icon: Icons.fingerprint,
                title: 'Remove Metadata',
                subtitle: 'Cleans GPS & device info',
                value: provider.removeMetadata,
                onChanged: provider.toggleRemoveMetadata,
              ),
              const Divider(color: AppColors.surfaceContainerHighest, height: 1),
              _ToggleRow(
                icon: Icons.graphic_eq,
                title: 'Modify Audio',
                subtitle: 'Shift pitch by 0.5%',
                value: provider.modifyAudio,
                onChanged: provider.toggleModifyAudio,
              ),
              const Divider(color: AppColors.surfaceContainerHighest, height: 1),
              _VisualAndUpscaleRows(provider: provider, onOpenAdvanced: onOpenAdvanced),
              const Divider(color: AppColors.surfaceContainerHighest, height: 1),
              _ToggleRow(
                icon: Icons.auto_fix_high,
                title: 'Denoise & Clarity',
                subtitle: 'HQ denoise & unsharp mask',
                value: provider.enableEnhanceAndDenoise,
                onChanged: provider.toggleEnhanceAndDenoise,
              ),
              const Divider(color: AppColors.surfaceContainerHighest, height: 1),
              _ToggleRow(
                icon: Icons.security,
                title: 'Deep Evasion',
                subtitle: '8% margin crop & 0.8° tilt',
                value: provider.enableDeepAntiFingerprint,
                onChanged: provider.toggleDeepAntiFingerprint,
              ),
              const Divider(color: AppColors.surfaceContainerHighest, height: 1),
              _ToggleRow(
                icon: Icons.flip,
                title: 'Horizontal Flip',
                subtitle: 'Mirrors video landmarks',
                value: provider.enableHorizontalFlip,
                onChanged: provider.toggleHorizontalFlip,
              ),
              const Divider(color: AppColors.surfaceContainerHighest, height: 1),
              _ToggleRow(
                icon: Icons.waves,
                title: 'Audio Masking',
                subtitle: 'Ambient pink noise layer',
                value: provider.enableAggressiveAudio,
                onChanged: provider.toggleAggressiveAudio,
              ),
              const Divider(color: AppColors.surfaceContainerHighest, height: 1),
              _ToggleRow(
                icon: Icons.content_cut,
                title: 'Auto-Trim',
                subtitle: 'Cuts 0.5s intro & outro',
                value: provider.enableAutoTrim,
                onChanged: provider.toggleAutoTrim,
              ),
              const Divider(color: AppColors.surfaceContainerHighest, height: 1),
              _ToggleRow(
                icon: Icons.blur_on,
                title: 'Blurred Canvas Frame',
                subtitle: 'Padded background blur',
                value: provider.enableBlurredCanvas,
                onChanged: provider.toggleBlurredCanvas,
              ),
              const Divider(color: AppColors.surfaceContainerHighest, height: 1),
              _ToggleRow(
                icon: Icons.volume_off,
                title: 'Mute Original Audio',
                subtitle: 'Ducks audio for music overlay',
                value: provider.muteOriginalAudio,
                onChanged: provider.toggleMuteOriginalAudio,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VisualAndUpscaleRows extends StatelessWidget {
  final UniquifierProvider provider;
  final VoidCallback onOpenAdvanced;

  const _VisualAndUpscaleRows({
    required this.provider,
    required this.onOpenAdvanced,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ToggleRow(
          icon: Icons.crop,
          title: 'Modify Visuals',
          subtitle: 'Micro-crop & color tweak',
          value: provider.modifyVisuals,
          onChanged: provider.toggleModifyVisuals,
        ),
        const Divider(color: AppColors.surfaceContainerHighest, height: 1),
        _ToggleRow(
          icon: Icons.hd,
          title: 'Upscale to ${provider.targetResolutionLabel}',
          subtitle: 'Lanczos algorithm (${provider.targetResolutionDetails})',
          value: provider.upscale1080p,
          onChanged: provider.toggleUpscale1080p,
          onTapSubtitle: onOpenAdvanced,
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTapSubtitle;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTapSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: AppColors.onSurfaceVariant, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: _ToggleLabel(title: title, subtitle: subtitle, onTapSubtitle: onTapSubtitle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ToggleLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTapSubtitle;

  const _ToggleLabel({
    required this.title,
    required this.subtitle,
    this.onTapSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
              color: onTapSubtitle != null ? AppColors.primaryContainer : AppColors.outline,
              fontSize: 10,
              fontFamily: 'monospace',
              decoration: onTapSubtitle != null ? TextDecoration.underline : TextDecoration.none,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
