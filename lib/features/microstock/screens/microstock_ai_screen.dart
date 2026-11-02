import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/top_app_bar.dart';

/// Microstock AI Workspace: Keyframe extraction, title generation, and metadata injector.
class MicrostockAiScreen extends StatelessWidget {
  const MicrostockAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopAppBar(title: 'MICROSTOCK AI'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: const [
            _HeroWorkspaceCard(),
            SizedBox(height: 16),
            _FeatureRowCard(
              icon: Icons.burst_mode_rounded,
              title: 'Keyframe Extraction Engine',
              subtitle: 'Extracts sharpest unblurred 4K thumbnails for stock preview',
              badge: 'READY',
            ),
            SizedBox(height: 12),
            _FeatureRowCard(
              icon: Icons.tag_rounded,
              title: 'Automated Metadata & XMP',
              subtitle: 'Generates 50 SEO keywords & commercial descriptions compliant with Adobe Stock & Shutterstock',
              badge: 'V2 PIPELINE',
            ),
            SizedBox(height: 12),
            _FeatureRowCard(
              icon: Icons.high_quality_rounded,
              title: 'Commercial Quality Gate',
              subtitle: 'Checks noise floor, artifact ratio, and macroblock compression before submission',
              badge: 'ACTIVE',
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroWorkspaceCard extends StatelessWidget {
  const _HeroWorkspaceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.primaryContainer, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Microstock Suite',
                      style: TextStyle(color: AppColors.onSurface, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Automated Tagging & Keyframe Studio',
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Extract pristine keyframes, generate high-converting commercial tags, and burn QuickTime metadata directly into rendered outputs for instant stock marketplace approval.',
            style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.9), fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _FeatureRowCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;

  const _FeatureRowCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryContainer, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(color: AppColors.primaryContainer, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
