import 'package:flutter/material.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';

class AppSettingsBottomSheet extends StatefulWidget {
  const AppSettingsBottomSheet({super.key});

  @override
  State<AppSettingsBottomSheet> createState() => _AppSettingsBottomSheetState();
}

class _AppSettingsBottomSheetState extends State<AppSettingsBottomSheet> {
  String _engineMode = 'software';
  String _preset = 'balanced';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hw = await SettingsService.getHardwareAcceleration();
    final pr = await SettingsService.getDefaultPreset();
    if (mounted) {
      setState(() {
        _engineMode = hw ? 'hardware' : 'software';
        _preset = pr;
        _isLoading = false;
      });
    }
  }

  Future<void> _purgeCache() async {
    final freed = await SettingsService.purgeTempCache();
    if (!mounted) return;
    final mb = (freed / (1024 * 1024)).toStringAsFixed(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cache purged: $mb MB freed'),
        backgroundColor: AppColors.primaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainerHighest),
          left: BorderSide(color: AppColors.surfaceContainerHighest),
          right: BorderSide(color: AppColors.surfaceContainerHighest),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ENGINE & APP SETTINGS',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontFamily: 'monospace',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: AppColors.surfaceContainerHighest, height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer))
            else ...[
              _buildSettingSection(
                title: 'DEFAULT ENCODER ENGINE',
                value: _engineMode == 'software' ? 'Software (libx264 - Safe)' : 'Hardware (MediaCodec)',
                onTap: () async {
                  final isHw = _engineMode == 'hardware';
                  await SettingsService.setHardwareAcceleration(!isHw);
                  setState(() => _engineMode = !isHw ? 'hardware' : 'software');
                },
              ),
              const SizedBox(height: 12),
              _buildSettingSection(
                title: 'DEFAULT PROCESSING PRESET',
                value: _preset.toUpperCase(),
                onTap: () async {
                  final next = _preset == 'balanced'
                      ? 'aggressive'
                      : (_preset == 'aggressive' ? 'subtle' : 'balanced');
                  await SettingsService.setDefaultPreset(next);
                  setState(() => _preset = next);
                },
              ),
              const SizedBox(height: 12),
              _buildSettingSection(
                title: 'STORAGE OUTPUT DIRECTORY',
                value: '/Movies/VideoUniquifier',
                onTap: null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('Purge Temporary Sandbox Cache', style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: _purgeCache,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required String value,
    required VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.outline,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              child: const Text('CHANGE', style: TextStyle(color: AppColors.primaryContainer, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
