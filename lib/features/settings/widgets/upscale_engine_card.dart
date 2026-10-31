import 'package:flutter/material.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_theme.dart';

class UpscaleEngineCard extends StatelessWidget {
  final UpscaleEngine selectedEngine;
  final ValueChanged<UpscaleEngine> onSelect;

  const UpscaleEngineCard({
    super.key,
    required this.selectedEngine,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EngineOptionTile(
          title: 'Lanczos3 (Standard Engine)',
          subtitle: '3-lobe anti-aliased mathematical matrix • Zero NPU load',
          badgeText: 'FAST & STABLE',
          engine: UpscaleEngine.lanczos,
          selectedEngine: selectedEngine,
          onTap: () => onSelect(UpscaleEngine.lanczos),
        ),
        const SizedBox(height: 8),
        _EngineOptionTile(
          title: 'Real-ESRGAN AI (Neural Engine)',
          subtitle: 'NCNN Vulkan AnimeVideo-v3 • Hardware Lanczos fallback',
          badgeText: 'VULKAN NEURAL',
          engine: UpscaleEngine.neuralAi,
          selectedEngine: selectedEngine,
          onTap: () => onSelect(UpscaleEngine.neuralAi),
          isNeural: true,
        ),
      ],
    );
  }
}

class _EngineOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final UpscaleEngine engine;
  final UpscaleEngine selectedEngine;
  final VoidCallback onTap;
  final bool isNeural;

  const _EngineOptionTile({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.engine,
    required this.selectedEngine,
    required this.onTap,
    this.isNeural = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = engine == selectedEngine;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHighest,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primaryContainer : AppColors.onSurface,
                        ),
                      ),
                      if (isNeural) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.bolt, size: 14, color: AppColors.primaryContainer),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer.withAlpha(50)
                    : AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppColors.primaryContainer : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
