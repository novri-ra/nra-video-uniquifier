import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../process/screens/process_screen.dart';
import '../../history/screens/recent_history_screen.dart';
import '../../settings/screens/settings_screen.dart';

class RootNavigationScreen extends StatelessWidget {
  const RootNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();
    const pages = [
      ProcessScreen(),
      RecentHistoryScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: provider.currentTabIndex,
        children: pages,
      ),
      bottomNavigationBar: _AppBottomNavBar(
        currentIndex: provider.currentTabIndex,
        onTap: provider.setTabIndex,
      ),
    );
  }
}

class _AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AppBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainerHighest, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_fix_high),
            label: 'Process',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
