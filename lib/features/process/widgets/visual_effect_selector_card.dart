import 'package:flutter/material.dart';
import '../../../../core/providers/uniquifier_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/interactive_preview_slider.dart';

class _EffectItem {
  final UnifiedVisualEffect effect;
  final String label;
  final String subLabel;
  final IconData icon;

  const _EffectItem({
    required this.effect,
    required this.label,
    required this.subLabel,
    required this.icon,
  });
}

/// Interactive Visual Effect Catalog Selector card for Studio/Process screen.
///
/// Allows horizontal browsing of the 7 unified visual effect presets
/// with immediate debounced frame rendering and contextual sub-controls.
class VisualEffectSelectorCard extends StatelessWidget {
  final UniquifierProvider provider;

  const VisualEffectSelectorCard({super.key, required this.provider});

  static const List<_EffectItem> _items = [
    _EffectItem(
      effect: UnifiedVisualEffect.none,
      label: 'None',
      subLabel: 'Original',
      icon: Icons.block,
    ),
    _EffectItem(
      effect: UnifiedVisualEffect.blurredCanvas,
      label: 'Blurred Canvas',
      subLabel: 'Dynamic Split',
      icon: Icons.blur_on,
    ),
    _EffectItem(
      effect: UnifiedVisualEffect.motionEcho,
      label: 'Echo Delay',
      subLabel: 'Motion Clone',
      icon: Icons.layers,
    ),
    _EffectItem(
      effect: UnifiedVisualEffect.rgbSplit,
      label: 'RGB Split',
      subLabel: 'Color Shift',
      icon: Icons.color_lens,
    ),
    _EffectItem(
      effect: UnifiedVisualEffect.dreamyBloom,
      label: 'Dreamy Bloom',
      subLabel: 'Pro-Mist Glow',
      icon: Icons.flare,
    ),
    _EffectItem(
      effect: UnifiedVisualEffect.film16mm,
      label: '16mm Film',
      subLabel: 'Vintage Tone',
      icon: Icons.movie_filter,
    ),
    _EffectItem(
      effect: UnifiedVisualEffect.dynamicGrain,
      label: 'Dynamic Grain',
      subLabel: 'Noise Injection',
      icon: Icons.grain,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? AppColors.obsidianDark : AppColors.white;
        final borderColor = isDark
            ? AppColors.outlineVariant
            : AppColors.lightOutlineVariant;
        final primaryAccent = isDark
            ? AppColors.mintSage
            : AppColors.forestDeep;
        final textColor = isDark
            ? AppColors.onSurface
            : AppColors.lightOnSurface;
        final subTextColor = isDark
            ? AppColors.onSurfaceVariant
            : AppColors.lightOnSurfaceVariant;
        final selectedEffect = provider.selectedVisualEffect;

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 15, color: primaryAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VISUAL FILTER CATALOG',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Real-time FFmpeg preview presets',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: subTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Active Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceContainer
                            : AppColors.hairlineBorder,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: selectedEffect == UnifiedVisualEffect.none
                              ? (isDark
                                    ? AppColors.surfaceContainerHighest
                                    : AppColors.hairlineBorder)
                              : primaryAccent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        _getActiveBadgeLabel(
                          provider.activeVisualEffects,
                          selectedEffect,
                        ),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selectedEffect == UnifiedVisualEffect.none
                              ? subTextColor
                              : primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Horizontal Preset Catalog
              SizedBox(
                height: 86,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isSelected = provider.isEffectActive(item.effect);

                    return _EffectCatalogCard(
                      item: item,
                      isSelected: isSelected,
                      isDark: isDark,
                      primaryAccent: primaryAccent,
                      onTap: () {
                        provider.toggleVisualEffect(item.effect);
                      },
                    );
                  },
                ),
              ),

              // Contextual Sub-Controls based on active presets
              if (provider.isEffectActive(
                UnifiedVisualEffect.blurredCanvas,
              )) ...[
                Divider(
                  color: isDark
                      ? AppColors.surfaceContainerHighest
                      : AppColors.hairlineBorder,
                  height: 18,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: InteractivePreviewSlider(
                    value: provider.canvasScalePercent.clamp(70.0, 100.0),
                    min: 70.0,
                    max: 100.0,
                    divisions: 30,
                    label: '${provider.canvasScalePercent.toInt()}%',
                    parameterName: 'BLURRED CANVAS FOREGROUND SCALE',
                    effect: PreviewEffect.canvasScale,
                    thumbnailPath: provider.thumbnailPath,
                    isPreviewRendering: provider.isPreviewRendering,
                    renderedPreviewFramePath: provider.renderedPreviewFramePath,
                    onChanged: (val) {
                      provider.setCanvasScalePercent(val);
                      provider.requestFilteredPreviewDebounced();
                    },
                    onChangeEnd: (_) {
                      provider.requestFilteredPreviewDebounced(immediate: true);
                    },
                  ),
                ),
              ],
              if (provider.isEffectActive(UnifiedVisualEffect.motionEcho)) ...[
                Divider(
                  color: isDark
                      ? AppColors.surfaceContainerHighest
                      : AppColors.hairlineBorder,
                  height: 18,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: InteractivePreviewSlider(
                    value: provider.motionEchoDelay.clamp(0.05, 0.40),
                    min: 0.05,
                    max: 0.40,
                    divisions: 7,
                    label: '${provider.motionEchoDelay.toStringAsFixed(2)}s',
                    parameterName: 'TEMPORAL CLONE DELAY',
                    effect: PreviewEffect.sharpening,
                    thumbnailPath: provider.thumbnailPath,
                    isPreviewRendering: provider.isPreviewRendering,
                    renderedPreviewFramePath: provider.renderedPreviewFramePath,
                    onChanged: (val) {
                      provider.setMotionEchoDelay(val);
                      provider.requestFilteredPreviewDebounced();
                    },
                    onChangeEnd: (_) {
                      provider.requestFilteredPreviewDebounced(immediate: true);
                    },
                  ),
                ),
              ],
              if (selectedEffect != UnifiedVisualEffect.none &&
                  !provider.isEffectActive(UnifiedVisualEffect.blurredCanvas) &&
                  !provider.isEffectActive(UnifiedVisualEffect.motionEcho)) ...[
                Divider(
                  color: isDark
                      ? AppColors.surfaceContainerHighest
                      : AppColors.hairlineBorder,
                  height: 18,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: primaryAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedEffect.description,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: subTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getActiveBadgeLabel(
    Set<UnifiedVisualEffect> activeEffects,
    UnifiedVisualEffect selectedEffect,
  ) {
    final active = activeEffects
        .where((e) => e != UnifiedVisualEffect.none)
        .toList();
    if (active.isEmpty) return 'ORIGINAL';
    if (active.length == 1) {
      switch (active.first) {
        case UnifiedVisualEffect.none:
          return 'ORIGINAL';
        case UnifiedVisualEffect.blurredCanvas:
          return 'CANVAS';
        case UnifiedVisualEffect.motionEcho:
          return 'ECHO';
        case UnifiedVisualEffect.rgbSplit:
          return 'RGB SPLIT';
        case UnifiedVisualEffect.dreamyBloom:
          return 'BLOOM';
        case UnifiedVisualEffect.film16mm:
          return '16MM';
        case UnifiedVisualEffect.dynamicGrain:
          return 'GRAIN';
      }
    }
    return '${active.length} ACTIVE';
  }
}

class _EffectCatalogCard extends StatelessWidget {
  final _EffectItem item;
  final bool isSelected;
  final bool isDark;
  final Color primaryAccent;
  final VoidCallback onTap;

  const _EffectCatalogCard({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.primaryAccent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark
        ? AppColors.primaryContainer.withValues(alpha: 0.35)
        : AppColors.forestDeep.withValues(alpha: 0.08);
    final inactiveBg = isDark
        ? AppColors.surfaceContainer
        : AppColors.offWhiteCanvas;
    final activeBorder = primaryAccent;
    final inactiveBorder = isDark
        ? AppColors.surfaceContainerHighest
        : AppColors.hairlineBorder;

    final titleColor = isSelected
        ? (isDark ? AppColors.onSurface : AppColors.forestDeep)
        : (isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurface);

    final subColor = isDark
        ? AppColors.outline
        : AppColors.lightOnSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${item.label}, filter preset',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 108,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeBorder : inactiveBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: isSelected
                        ? primaryAccent
                        : (isDark
                              ? AppColors.outline
                              : AppColors.lightOnSurfaceVariant),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: primaryAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 9,
                        color: isDark
                            ? AppColors.obsidianBase
                            : AppColors.white,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: 'monospace',
                      color: subColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
