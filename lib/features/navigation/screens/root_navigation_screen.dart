import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../shared/widgets/floating_capsule_nav_bar.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../history/screens/recent_history_screen.dart';
import '../../process/screens/process_screen.dart';
import '../../profile/screens/profile_placeholder_screen.dart';

/// Root navigation screen housing the 4 core application destinations with lazy tab mounting.
class RootNavigationScreen extends StatefulWidget {
  const RootNavigationScreen({super.key});

  @override
  State<RootNavigationScreen> createState() => _RootNavigationScreenState();
}

class _RootNavigationScreenState extends State<RootNavigationScreen> {
  final List<bool> _initializedTabs = [true, false, false, false];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();
    final currentIndex = provider.currentTabIndex.clamp(0, 3);
    _initializedTabs[currentIndex] = true;

    final pages = [
      _initializedTabs[0] ? const DashboardScreen() : const SizedBox.shrink(),
      _initializedTabs[1] ? const ProcessScreen() : const SizedBox.shrink(),
      _initializedTabs[2]
          ? const RecentHistoryScreen()
          : const SizedBox.shrink(),
      _initializedTabs[3]
          ? const ProfilePlaceholderScreen()
          : const SizedBox.shrink(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: currentIndex, children: pages),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingCapsuleNavBar(
              currentIndex: currentIndex,
              onTap: (index) =>
                  context.read<UniquifierProvider>().setTabIndex(index),
            ),
          ),
        ],
      ),
    );
  }
}
