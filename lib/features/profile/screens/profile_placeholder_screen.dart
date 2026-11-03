import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/services/notification_service.dart';
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
          children: const [
            _ProfileCard(),
            SizedBox(height: 16),
            _DiagnosticsCard(),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.obsidianDark : AppColors.white;
    final borderColor = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;
    final titleColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final descColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

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
            style: TextStyle(
              color: titleColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/people-icon.svg',
          width: 28,
          height: 28,
          colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _DevelopmentBadge extends StatelessWidget {
  const _DevelopmentBadge();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        'UNDER ACTIVE DEVELOPMENT',
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard();

  Future<void> _testNotification(BuildContext context) async {
    await NotificationService.showTestNotification(
      title: 'NRA Uniquifier Test',
      body: 'Notifikasi Android 13+ channel berhasil aktif!',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent to system tray'),
        backgroundColor: AppColors.forestDeep,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.obsidianDark : AppColors.white;
    final borderColor = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;
    final accent = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'NOTIFICATION DIAGNOSTICS',
                style: TextStyle(
                  color: isDark
                      ? AppColors.onSurface
                      : AppColors.lightOnSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Test native Android 13+ channel binding and alert triggers.',
            style: TextStyle(
              color: isDark
                  ? AppColors.onSurfaceVariant
                  : AppColors.lightOnSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _testNotification(context),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text(
                'Send Test Notification',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestDeep,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
