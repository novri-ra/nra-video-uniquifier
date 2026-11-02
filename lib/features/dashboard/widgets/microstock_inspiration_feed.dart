import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Horizontal scroll feed for commercial microstock trends and high-converting themes.
class MicrostockInspirationFeed extends StatelessWidget {
  const MicrostockInspirationFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final trends = const [
      _TrendItem(
        category: 'HOLIDAYS',
        title: 'Ramadan & Eid Celebrations',
        description: 'Lanterns, calligraphy, family gatherings in 4K 60FPS',
        accent: Color(0xFF00F0A8),
      ),
      _TrendItem(
        category: 'COMMERCIAL TECH',
        title: 'AI & Autonomous Robotics',
        description: 'Humanoid robots, neural data streams, clean lab lighting',
        accent: Color(0xFF64B5F6),
      ),
      _TrendItem(
        category: 'SUSTAINABILITY',
        title: 'Clean Energy & Green Tech',
        description: 'Solar farms, wind turbines, eco agriculture time-lapses',
        accent: Color(0xFF81C784),
      ),
      _TrendItem(
        category: 'CORPORATE',
        title: 'Global Remote Collaboration',
        description: 'Diverse teams, video calls, fintech dashboard workflows',
        accent: Color(0xFFFFB74D),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              (l10n?.inspirationTitle ?? 'UPCOMING TRENDS').toUpperCase(),
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontFamily: 'monospace',
              ),
            ),
            const Text(
              'HIGH COMMERCIAL VALUE',
              style: TextStyle(
                color: AppColors.outline,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: trends.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _TrendCard(trend: trends[i]),
          ),
        ),
      ],
    );
  }
}

class _TrendItem {
  final String category, title, description;
  final Color accent;
  const _TrendItem({
    required this.category,
    required this.title,
    required this.description,
    required this.accent,
  });
}

class _TrendCard extends StatelessWidget {
  final _TrendItem trend;
  const _TrendCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: trend.accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                trend.category,
                style: TextStyle(
                  color: trend.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trend.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                trend.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 9.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
