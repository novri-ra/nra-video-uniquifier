import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../shared/widgets/floating_capsule_nav_bar.dart';
import '../../batch/screens/batch_queue_tab_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../microstock/screens/microstock_ai_screen.dart';
import '../../process/screens/process_screen.dart';
import '../../settings/screens/settings_screen.dart';

/// Root navigation screen housing the 5 core application destinations and floating pill navbar.
class RootNavigationScreen extends StatelessWidget {
  const RootNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();
    const pages = [
      DashboardScreen(),
      ProcessScreen(),
      MicrostockAiScreen(),
      BatchQueueTabScreen(),
      SettingsScreen(),
    ];

    final safeIndex = provider.currentTabIndex.clamp(0, pages.length - 1);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: safeIndex,
            children: pages,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingCapsuleNavBar(
              currentIndex: safeIndex,
              onTap: provider.setTabIndex,
            ),
          ),
        ],
      ),
    );
  }
}
