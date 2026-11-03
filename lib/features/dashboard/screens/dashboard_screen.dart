import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/bento_metric_grid.dart';
import '../widgets/live_intel_ticker_card.dart';
import '../widgets/microstock_inspiration_feed.dart';
import '../widgets/seasonal_hero_card.dart';

/// Modern Bento Grid Dashboard Screen for creators and video deduplication workflows.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openStudioTab(BuildContext context) {
    context.read<UniquifierProvider>().setTabIndex(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopAppBar(onSettingsTap: () => _openSettings(context)),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            const _GreetingHeaderSection(),
            const SizedBox(height: 14),
            SeasonalHeroCard(onLaunchStudio: () => _openStudioTab(context)),
            const SizedBox(height: 12),
            const LiveIntelTickerCard(),
            const SizedBox(height: 14),
            const BentoMetricGrid(),
            const SizedBox(height: 16),
            const MicrostockInspirationFeed(),
          ],
        ),
      ),
    );
  }
}

class _GreetingHeaderSection extends StatelessWidget {
  const _GreetingHeaderSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.obsidianDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.outlineVariant : AppColors.lightOutlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.forestDeep, AppColors.mintSage],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'NRA',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.greetingTitle ?? 'Welcome, Creator',
                  style: TextStyle(
                    color: isDark ? AppColors.onSurface : AppColors.lightOnSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.mintSage : AppColors.forestDeep,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l10n?.gpuStatusReady ?? 'Vulkan NCNN Ready',
                      style: TextStyle(
                        color: isDark ? AppColors.mintSage : AppColors.forestDeep,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
