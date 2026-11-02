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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _EngineOptionTile(
          title: 'Lanczos3 (Standard Engine)',
          subtitle: '3-lobe anti-aliased mathematical matrix • Zero NPU load',
          badgeText: 'FAST & STABLE',
          engine: UpscaleEngine.lanczos,
          selectedEngine: selectedEngine,
          isDark: isDark,
          onTap: () => onSelect(UpscaleEngine.lanczos),
        ),
        const SizedBox(height: 8),
        _EngineOptionTile(
          title: 'Real-ESRGAN AI (Neural Engine)',
          subtitle: 'NCNN Vulkan AnimeVideo-v3 • Hardware Lanczos fallback',
          badgeText: 'VULKAN NEURAL',
          engine: UpscaleEngine.neuralAi,
          selectedEngine: selectedEngine,
          isDark: isDark,
          onTap: () => onSelect(UpscaleEngine.neuralAi),
          isNeural: true,
        ),
      ],
    );
  }
}

class _EngineOptionTile extends StatelessWidget {
  final String title, subtitle, badgeText;
  final UpscaleEngine engine, selectedEngine;
  final VoidCallback onTap;
  final bool isNeural, isDark;

  const _EngineOptionTile({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.engine,
    required this.selectedEngine,
    required this.isDark,
    required this.onTap,
    this.isNeural = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = engine == selectedEngine;
    final activeBg = isDark ? AppColors.surfaceContainerHigh : const Color(0xFFF5F3FF);
    final inactiveBg = isDark ? AppColors.surfaceContainerLow : Colors.white;
    final activeBorder = isDark ? AppColors.primaryContainer : const Color(0xFF6C5CE7);
    final inactiveBorder = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final textColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final descColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);

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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? activeBorder : textColor,
                        ),
                      ),
                      if (isNeural) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.bolt, size: 14, color: activeBorder),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: descColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeBorder.withValues(alpha: 0.15)
                    : (isDark ? AppColors.surfaceContainerHighest : AppColors.lightSurfaceContainerHigh),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? activeBorder.withValues(alpha: 0.5) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontFamily: 'monospace',
                  color: isSelected ? activeBorder : descColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
