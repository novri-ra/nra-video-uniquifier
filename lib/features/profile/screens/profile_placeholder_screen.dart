import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/top_app_bar.dart';

/// Informative placeholder screen for the Workstation Profile destination.
class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopAppBar(title: 'WORKSTATION PROFILE'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
          children: const [_ProfileCard()],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  static const Color primaryPurple = Color(0xFF6C5CE7);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final titleColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final descColor = isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ProfileAvatar(),
          const SizedBox(height: 16),
          const _DevelopmentBadge(),
          const SizedBox(height: 14),
          Text(
            'Workstation Profile',
            style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            'Workstation Profile under active development. Microstock contributor portfolio and API credentials syncing will be available soon.',
            textAlign: TextAlign.center,
            style: TextStyle(color: descColor, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _ProfileCard.primaryPurple.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/people-icon.svg',
          width: 28,
          height: 28,
          colorFilter: const ColorFilter.mode(_ProfileCard.primaryPurple, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _DevelopmentBadge extends StatelessWidget {
  const _DevelopmentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _ProfileCard.primaryPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _ProfileCard.primaryPurple.withValues(alpha: 0.3)),
      ),
      child: const Text(
        'UNDER ACTIVE DEVELOPMENT',
        style: TextStyle(
          color: _ProfileCard.primaryPurple,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
