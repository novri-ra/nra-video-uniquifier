import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../../process/screens/process_screen.dart';
import '../../history/screens/recent_history_screen.dart';

class RootNavigationScreen extends StatelessWidget {
  const RootNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();
    const pages = [
      ProcessScreen(),
      _PresetsScreen(),
      RecentHistoryScreen(),
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
            icon: Icon(Icons.video_settings),
            label: 'Process',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune),
            label: 'Presets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Inspect',
          ),
        ],
      ),
    );
  }
}

class _PresetsScreen extends StatelessWidget {
  const _PresetsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopAppBar(title: 'PRESET PROFILES'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _PresetsHeader(),
            SizedBox(height: 16),
            _PresetCardsList(),
          ],
        ),
      ),
    );
  }
}

class _PresetCardsList extends StatelessWidget {
  const _PresetCardsList();

  void _apply(BuildContext context, String name, VoidCallback action) {
    action();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied preset: $name'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surfaceContainerHigh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<UniquifierProvider>();

    return Column(
      children: [
        _buildTikTokPreset(context, provider),
        const SizedBox(height: 12),
        _buildMaxStealthPreset(context, provider),
        const SizedBox(height: 12),
        _buildLosslessPreset(context, provider),
      ],
    );
  }

  Widget _buildTikTokPreset(BuildContext context, UniquifierProvider provider) {
    return _PresetCard(
      title: 'TikTok Fast Mode',
      tag: 'SPEED OPTIMIZED',
      tagColor: AppColors.primaryContainer,
      description: 'Removes metadata, shifts audio pitch by 0.5%, and upscales to 1080p Lanczos.',
      features: const ['Metadata: OFF', 'Audio: +0.5%', 'Visual: Original', '1080p Lanczos'],
      onApply: () => _apply(context, 'TikTok Fast Mode', () {
        provider.applyPreset(removeMetadata: true, modifyAudio: true, modifyVisuals: false, upscale1080p: true);
      }),
    );
  }

  Widget _buildMaxStealthPreset(BuildContext context, UniquifierProvider provider) {
    return _PresetCard(
      title: 'Maximum Anti-Fingerprint',
      tag: 'MAX STEALTH',
      tagColor: AppColors.secondary,
      description: 'Full algorithmic transformation: micro-crop, audio shift, metadata wipe, and 1080p.',
      features: const ['Metadata: OFF', 'Audio: +0.5%', 'Crop: 4px Micro', '1080p Lanczos'],
      onApply: () => _apply(context, 'Maximum Anti-Fingerprint', () {
        provider.applyPreset(removeMetadata: true, modifyAudio: true, modifyVisuals: true, upscale1080p: true);
      }),
    );
  }

  Widget _buildLosslessPreset(BuildContext context, UniquifierProvider provider) {
    return _PresetCard(
      title: 'Lossless Stealth',
      tag: 'INSTANT RENDER',
      tagColor: AppColors.outline,
      description: 'Zero visual re-encoding. Strips metadata and retunes audio timestamps in seconds.',
      features: const ['Metadata: OFF', 'Audio: +0.5%', 'Video: Direct Copy', 'Fastest'],
      onApply: () => _apply(context, 'Lossless Stealth', () {
        provider.applyPreset(removeMetadata: true, modifyAudio: true, modifyVisuals: false, upscale1080p: false);
      }),
    );
  }
}

class _PresetsHeader extends StatelessWidget {
  const _PresetsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Platform Presets',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select a profile to automatically tune modifiers for anti-fingerprint evasion.',
          style: TextStyle(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  final String title;
  final String tag;
  final Color tagColor;
  final String description;
  final List<String> features;
  final VoidCallback onApply;

  const _PresetCard({
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.description,
    required this.features,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PresetCardHeader(title: title, tag: tag, tagColor: tagColor),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _PresetFeaturesWrap(features: features),
          const SizedBox(height: 12),
          _PresetApplyButton(onApply: onApply),
        ],
      ),
    );
  }
}

class _PresetCardHeader extends StatelessWidget {
  final String title;
  final String tag;
  final Color tagColor;

  const _PresetCardHeader({
    required this.title,
    required this.tag,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: tagColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            tag,
            style: TextStyle(
              color: tagColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetFeaturesWrap extends StatelessWidget {
  final List<String> features;

  const _PresetFeaturesWrap({required this.features});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: features.map((f) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: AppColors.surfaceContainerHighest),
          ),
          child: Text(
            f,
            style: const TextStyle(
              color: AppColors.outline,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PresetApplyButton extends StatelessWidget {
  final VoidCallback onApply;

  const _PresetApplyButton({required this.onApply});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryContainer,
          side: const BorderSide(color: AppColors.primaryContainer),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: onApply,
        icon: const Icon(Icons.bolt, size: 16),
        label: const Text(
          'Apply & Configure',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}
