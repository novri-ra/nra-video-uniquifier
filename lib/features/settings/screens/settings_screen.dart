import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/setting_toggle_row.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../widgets/hardware_acceleration_card.dart';
import '../widgets/preset_profile_card.dart';
import '../widgets/upscale_resolution_card.dart';
import '../widgets/upscale_engine_card.dart';
import '../widgets/codec_selector_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _cacheSizeBytes = 0;
  bool _notificationSound = true;
  bool _backgroundProcessing = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cache = await SettingsService.getTempCacheSize();
    final sound = await SettingsService.getNotificationSound();
    final bg = await SettingsService.getBackgroundProcessing();
    if (mounted) {
      setState(() {
        _cacheSizeBytes = cache;
        _notificationSound = sound;
        _backgroundProcessing = bg;
      });
    }
  }

  Future<void> _purgeCache() async {
    final mb = (_cacheSizeBytes / (1024 * 1024)).toStringAsFixed(1);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Purge cache?'),
        content: Text('Delete $mb MB of temporary files and thumbnails?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Purge')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final freed = await SettingsService.purgeTempCache();
    final updated = await SettingsService.getTempCacheSize();
    if (!mounted) return;
    setState(() => _cacheSizeBytes = updated);
    final freedMb = (freed / (1024 * 1024)).toStringAsFixed(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cache purged: $freedMb MB freed'), backgroundColor: AppColors.primaryContainer),
    );
  }

  Future<void> _toggleSound(bool val) async {
    await SettingsService.setNotificationSound(val);
    if (mounted) setState(() => _notificationSound = val);
  }

  Future<void> _toggleBackground(bool val) async {
    await SettingsService.setBackgroundProcessing(val);
    if (mounted) setState(() => _backgroundProcessing = val);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();

    return Scaffold(
      appBar: const TopAppBar(title: 'SETTINGS'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SettingsSectionHeader(title: 'PRESET PROFILES', subtitle: 'Quick configuration templates for evasion workflows'),
            const SizedBox(height: 8),
            PresetProfileCard(provider: provider),
            const SizedBox(height: 16),
            const _SettingsSectionHeader(title: 'VIDEO ENCODING CODEC', subtitle: 'Select output video codec standard for render pipeline'),
            const SizedBox(height: 8),
            CodecSelectorCard(currentCodec: provider.videoCodec, onSelect: provider.setVideoCodec),
            const SizedBox(height: 16),
            const _SettingsSectionHeader(title: 'DEFAULT RESOLUTION UPSCALE', subtitle: 'Lanczos 3-lobe anti-aliased scaling matrix'),
            const SizedBox(height: 8),
            UpscaleResolutionCard(selectedValue: provider.selectedUpscaleTarget, onSelect: provider.setUpscaleTarget),
            const SizedBox(height: 16),
            const _SettingsSectionHeader(title: 'SUPER-RESOLUTION ENGINE', subtitle: 'Neural AI (NCNN Vulkan) or mathematical Lanczos3'),
            const SizedBox(height: 8),
            UpscaleEngineCard(selectedEngine: provider.upscaleEngine, onSelect: provider.setUpscaleEngine),
            const SizedBox(height: 16),
            const _SettingsSectionHeader(title: 'HARDWARE ACCELERATION', subtitle: 'MediaCodec / OpenGL shader pipeline'),
            const SizedBox(height: 8),
            HardwareAccelerationCard(enabled: provider.hardwareAcceleration, onToggle: provider.toggleHardwareAcceleration),
            const SizedBox(height: 16),
            const _SettingsSectionHeader(title: 'BACKGROUND & ALERTS', subtitle: 'Background processing & notification chime'),
            const SizedBox(height: 8),
            _AlertsSettingsCard(
              backgroundProcessing: _backgroundProcessing,
              notificationSound: _notificationSound,
              onToggleBackground: _toggleBackground,
              onToggleSound: _toggleSound,
            ),
            const SizedBox(height: 16),
            const _SettingsSectionHeader(title: 'STORAGE & CACHE MAINTENANCE', subtitle: 'Staged input buffers and generated thumbnails'),
            const SizedBox(height: 8),
            _CacheMaintenanceCard(cacheBytes: _cacheSizeBytes, onPurge: _purgeCache),
            const SizedBox(height: 16),
            const _AppInfoCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title, subtitle;
  const _SettingsSectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 11)),
      ],
    );
  }
}

class _AlertsSettingsCard extends StatelessWidget {
  final bool backgroundProcessing, notificationSound;
  final ValueChanged<bool> onToggleBackground, onToggleSound;

  const _AlertsSettingsCard({
    required this.backgroundProcessing,
    required this.notificationSound,
    required this.onToggleBackground,
    required this.onToggleSound,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          SettingToggleRow(
            icon: Icons.work_outline,
            title: 'Background Processing',
            subtitle: 'Keep rendering active when minimized',
            value: backgroundProcessing,
            onChanged: onToggleBackground,
          ),
          const Divider(height: 1, color: AppColors.surfaceContainerHighest),
          SettingToggleRow(
            icon: Icons.volume_up_outlined,
            title: 'Notification Sound',
            subtitle: 'Play completion chime on finish',
            value: notificationSound,
            onChanged: onToggleSound,
          ),
        ],
      ),
    );
  }
}

class _CacheMaintenanceCard extends StatelessWidget {
  final int cacheBytes;
  final VoidCallback onPurge;

  const _CacheMaintenanceCard({required this.cacheBytes, required this.onPurge});

  @override
  Widget build(BuildContext context) {
    final mb = (cacheBytes / (1024 * 1024)).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Temporary Cache', style: TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('$mb MB staged files & thumbnails', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontFamily: 'monospace')),
            ],
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryContainer,
              side: const BorderSide(color: AppColors.primaryContainer),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: onPurge,
            icon: const Icon(Icons.delete_sweep, size: 16),
            label: const Text('Purge Cache', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  const _AppInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.surfaceContainerHighest)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NRA Video Uniquifier v1.0.0', style: TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
              SizedBox(height: 2),
              Text('Anti-Fingerprint Evasion Engine', style: TextStyle(color: AppColors.outline, fontSize: 10, fontFamily: 'monospace')),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.surfaceContainerHighest)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, color: AppColors.primaryContainer, size: 14),
                SizedBox(width: 4),
                Text('OFFLINE PRIVACY', style: TextStyle(color: AppColors.primaryContainer, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
