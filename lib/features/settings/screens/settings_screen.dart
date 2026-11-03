import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/setting_fps_selector_row.dart';
import '../../../shared/widgets/setting_toggle_row.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../widgets/app_info_card.dart';
import '../widgets/codec_selector_card.dart';
import '../widgets/hardware_acceleration_card.dart';
import '../widgets/language_selector_card.dart';
import '../widgets/preset_profile_card.dart';
import '../widgets/settings_group_card.dart';
import '../widgets/theme_selector_card.dart';
import '../widgets/upscale_engine_card.dart';
import '../widgets/upscale_resolution_card.dart';

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
    final bytes = await SettingsService.getTempCacheSize();
    final sound = await SettingsService.getNotificationSound();
    final bg = await SettingsService.getBackgroundProcessing();
    if (mounted) {
      setState(() {
        _cacheSizeBytes = bytes;
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
        backgroundColor: AppColors.surfaceContainerLow,
        title: const Text('Purge cache?'),
        content: Text('Delete $mb MB of temporary files and thumbnails?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Purge'),
          ),
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
      SnackBar(
        content: Text('Cache purged: $freedMb MB freed'),
        backgroundColor: AppColors.primaryContainer,
      ),
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
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: TopAppBar(
        title: (l10n?.settingsTitle ?? 'SETTINGS').toUpperCase(),
        showSettingsAction: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
          children: [
            ..._buildPreferencesSection(localeProvider, themeProvider, l10n),
            ..._buildPresetsAndCodecSection(provider),
            ..._buildEngineSection(provider),
            ..._buildMaintenanceSection(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPreferencesSection(
    LocaleProvider localeProvider,
    ThemeProvider themeProvider,
    AppLocalizations? l10n,
  ) {
    return [
      _SettingsSectionHeader(
        title: (l10n?.languageLabel ?? 'LANGUAGE').toUpperCase(),
        subtitle: 'Select interface language (Bahasa Indonesia / English)',
      ),
      const SizedBox(height: 8),
      LanguageSelectorCard(localeProvider: localeProvider),
      const SizedBox(height: 16),
      _SettingsSectionHeader(
        title: (l10n?.themeModeLabel ?? 'APPEARANCE & THEME').toUpperCase(),
        subtitle: 'Select application visual theme mode',
      ),
      const SizedBox(height: 8),
      SettingsGroupCard(
        title: 'THEME MODE',
        child: ThemeSelectorCard(themeProvider: themeProvider),
      ),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildPresetsAndCodecSection(UniquifierProvider provider) {
    return [
      const _SettingsSectionHeader(
        title: 'PRESET PROFILES',
        subtitle: 'Quick configuration templates for evasion workflows',
      ),
      const SizedBox(height: 8),
      PresetProfileCard(provider: provider),
      const SizedBox(height: 16),
      const _SettingsSectionHeader(
        title: 'VIDEO ENCODING CODEC',
        subtitle: 'Select output video codec standard for render pipeline',
      ),
      const SizedBox(height: 8),
      CodecSelectorCard(
        currentCodec: provider.videoCodec,
        onSelect: provider.setVideoCodec,
      ),
      const SizedBox(height: 16),
      const _SettingsSectionHeader(
        title: 'TARGET FRAMERATE (FPS)',
        subtitle: 'Output framerate control (-fps_mode cfr -r)',
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceContainerLow
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceContainerHighest
                : AppColors.lightOutlineVariant,
          ),
          boxShadow: [
            if (Theme.of(context).brightness == Brightness.light)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: SettingFpsSelectorRow(
          selectedFps: provider.targetFps,
          onChanged: provider.setTargetFps,
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildEngineSection(UniquifierProvider provider) {
    return [
      const _SettingsSectionHeader(
        title: 'DEFAULT RESOLUTION UPSCALE',
        subtitle: 'Lanczos 3-lobe anti-aliased scaling matrix',
      ),
      const SizedBox(height: 8),
      UpscaleResolutionCard(
        selectedValue: provider.selectedUpscaleTarget,
        onSelect: provider.setUpscaleTarget,
        tier: provider.deviceTier,
      ),
      const SizedBox(height: 16),
      const _SettingsSectionHeader(
        title: 'SUPER-RESOLUTION ENGINE',
        subtitle: 'Neural AI (NCNN Vulkan) or mathematical Lanczos3',
      ),
      const SizedBox(height: 8),
      UpscaleEngineCard(
        selectedEngine: provider.upscaleEngine,
        onSelect: provider.setUpscaleEngine,
      ),
      const SizedBox(height: 16),
      const _SettingsSectionHeader(
        title: 'HARDWARE ACCELERATION',
        subtitle: 'MediaCodec / OpenGL shader pipeline',
      ),
      const SizedBox(height: 8),
      HardwareAccelerationCard(
        enabled: provider.hardwareAcceleration,
        onToggle: provider.toggleHardwareAcceleration,
      ),
      const SizedBox(height: 16),
      const _SettingsSectionHeader(
        title: 'BACKGROUND & ALERTS',
        subtitle: 'Background processing & notification chime',
      ),
      const SizedBox(height: 8),
      _AlertsSettingsCard(
        backgroundProcessing: _backgroundProcessing,
        notificationSound: _notificationSound,
        onToggleBackground: _toggleBackground,
        onToggleSound: _toggleSound,
      ),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildMaintenanceSection() {
    return [
      const _SettingsSectionHeader(
        title: 'STORAGE & CACHE MAINTENANCE',
        subtitle: 'Staged input buffers and generated thumbnails',
      ),
      const SizedBox(height: 8),
      _CacheMaintenanceCard(cacheBytes: _cacheSizeBytes, onPurge: _purgeCache),
      const SizedBox(height: 16),
      const AppInfoCard(),
      const SizedBox(height: 24),
    ];
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title, subtitle;
  const _SettingsSectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: subColor, fontSize: 11)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? AppColors.surfaceContainerHighest
              : AppColors.lightOutlineVariant,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
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
          Divider(
            height: 1,
            color: isDark
                ? AppColors.surfaceContainerHighest
                : AppColors.lightOutlineVariant,
          ),
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

  const _CacheMaintenanceCard({
    required this.cacheBytes,
    required this.onPurge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mb = (cacheBytes / (1024 * 1024)).toStringAsFixed(1);
    final titleColor = isDark ? AppColors.onSurface : AppColors.lightOnSurface;
    final subColor = isDark
        ? AppColors.onSurfaceVariant
        : AppColors.lightOnSurfaceVariant;
    final btnColor = isDark ? AppColors.mintSage : AppColors.forestDeep;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.obsidianDark : AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? AppColors.outlineVariant
              : AppColors.lightOutlineVariant,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
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
              Text(
                'Temporary Cache',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$mb MB staged files & thumbnails',
                style: TextStyle(
                  color: subColor,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: btnColor,
              side: BorderSide(color: btnColor),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: onPurge,
            icon: const Icon(Icons.delete_sweep, size: 16),
            label: const Text(
              'Purge Cache',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
