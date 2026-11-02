import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Hero Bento Card highlighting seasonal microstock event upload windows.
class SeasonalHeroCard extends StatelessWidget {
  final VoidCallback onLaunchStudio;

  const SeasonalHeroCard({super.key, required this.onLaunchStudio});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainerHighest),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceContainerLow,
            AppColors.primaryContainer.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryContainer, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SEASONAL WINDOW',
                    style: const TextStyle(
                      color: AppColors.primaryContainer,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '60-90 DAYS LEAD',
                  style: TextStyle(color: AppColors.outline, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.seasonalWindowTitle ?? 'Seasonal Upload Window (60-90 Days Lead Time)',
            style: const TextStyle(color: AppColors.onSurface, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Q1 Global Campaigns: Valentine\'s Day • Ramadan & Eid al-Fitr • Lunar New Year',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, height: 1.3),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _SpecBadge(label: '4K / 60FPS'),
              _SpecBadge(label: 'ProRes / H.264'),
              _SpecBadge(label: 'Alpha Channel'),
              _SpecBadge(label: 'CFR Locked'),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onLaunchStudio,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_fix_high_rounded, color: AppColors.onPrimary, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'LAUNCH STUDIO DEDUPLICATION',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecBadge extends StatelessWidget {
  final String label;
  const _SpecBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
