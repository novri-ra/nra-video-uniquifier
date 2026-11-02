import 'package:flutter/material.dart';
import '../helpers/seasonal_event_helper.dart';

/// Hero Bento Card highlighting dynamic seasonal microstock event upload windows.
class SeasonalHeroCard extends StatelessWidget {
  final VoidCallback onLaunchStudio;

  const SeasonalHeroCard({super.key, required this.onLaunchStudio});

  @override
  Widget build(BuildContext context) {
    final info = SeasonalEventHelper.getSeasonalWindowInfo();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFF4834D4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroBadgeRow(),
          const SizedBox(height: 12),
          Text(
            info.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            info.campaignDescription,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          const _SpecBadgeRow(),
          const SizedBox(height: 16),
          _LaunchButton(onLaunchStudio: onLaunchStudio),
        ],
      ),
    );
  }
}

class _HeroBadgeRow extends StatelessWidget {
  const _HeroBadgeRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🔥 SEASONAL WINDOW • 60-90 DAYS LEAD',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecBadgeRow extends StatelessWidget {
  const _SpecBadgeRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _SpecBadge(label: '4K / 60FPS'),
        _SpecBadge(label: 'ProRes / H.264'),
        _SpecBadge(label: 'Alpha Channel'),
        _SpecBadge(label: 'CFR Locked'),
      ],
    );
  }
}

class _SpecBadge extends StatelessWidget {
  final String label;
  const _SpecBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _LaunchButton extends StatelessWidget {
  final VoidCallback onLaunchStudio;

  const _LaunchButton({required this.onLaunchStudio});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 0,
      child: InkWell(
        onTap: onLaunchStudio,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_fix_high_rounded, color: Color(0xFF6C5CE7), size: 18),
              SizedBox(width: 8),
              Text(
                'LAUNCH STUDIO DEDUPLICATION',
                style: TextStyle(
                  color: Color(0xFF6C5CE7),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
