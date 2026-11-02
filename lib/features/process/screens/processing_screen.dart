import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/services/ffmpeg_service.dart';
import '../../../core/services/user_interest_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../widgets/processing_log_viewer.dart';
import '../widgets/processing_radar_indicator.dart';
import '../widgets/processing_stage_tracker.dart';
import 'error_screen.dart';
import 'success_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _progress = 0.05;
  int _step = 1;
  bool _isCancelled = false;
  bool _hasNativeProgress = false;
  String _liveTerminalLogs = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(_onProgressTick);
    _controller.forward();
    _runEngine();
  }

  void _onProgressTick() {
    if (!mounted || _isCancelled || _hasNativeProgress) return;
    setState(() {
      _progress = (0.05 + (_controller.value * 0.10)).clamp(0.05, 0.15);
      _step = 1;
    });
  }

  @override
  void dispose() {
    _isCancelled = true;
    _controller.dispose();
    FfmpegService.cancel();
    super.dispose();
  }

  Future<void> _handleCancel() async {
    _isCancelled = true;
    _controller.stop();
    await FfmpegService.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _runEngine() async {
    final provider = context.read<UniquifierProvider>();
    final inputPath = provider.selectedFilePath;
    try {
      final outputPath = (inputPath == null || inputPath.isEmpty)
          ? await _simulateFallback()
          : await _processWithNative(provider, inputPath);
      if (!mounted || _isCancelled) return;
      HapticFeedback.mediumImpact();
      provider.setLastProcessedResult(outputPath);
      _dispatchTelemetryVault(provider);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SuccessScreen(outputPath: outputPath)),
      );
    } catch (e) {
      if (!mounted || _isCancelled) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ErrorScreen(errorDetails: e.toString())),
      );
    }
  }

  Future<String> _simulateFallback() async {
    await Future.delayed(const Duration(seconds: 3));
    return await FfmpegService.generateOutputPath('video_01.mp4');
  }

  void _dispatchTelemetryVault(UniquifierProvider provider) {
    try {
      UserInterestService.dispatchVideoMetadataVault(
        title: provider.selectedFileName ?? 'Untitled Video Asset',
        description: 'Processed via ${provider.activePreset} profile with anti-fingerprint evasion',
        keywords: [provider.activePreset, provider.targetResolution.label, provider.videoCodec.name],
        platforms: const ['Shutterstock', 'Adobe Stock', 'Freepik'],
        techSpecs: '${provider.fileResolution} | ${provider.targetFps} FPS | ${provider.videoCodec.name}',
        category: provider.isPortrait ? 'VERTICAL_REELS' : 'LANDSCAPE_4K',
        leadWindow: 'Q4 Commercial Window',
      );
    } catch (_) {}
  }

  Future<String> _processWithNative(UniquifierProvider provider, String inputPath) {
    return FfmpegService.processVideo(
      inputPath: inputPath,
      removeMetadata: provider.removeMetadata,
      modifyAudio: provider.modifyAudio,
      modifyVisuals: provider.modifyVisuals,
      upscale1080p: provider.upscale1080p,
      targetResolution: provider.targetResolution,
      upscaleEngine: provider.upscaleEngine,
      videoCodec: provider.videoCodec,
      enableEnhanceAndDenoise: provider.enableEnhanceAndDenoise,
      enableDeepAntiFingerprint: provider.enableDeepAntiFingerprint,
      enableHorizontalFlip: provider.enableHorizontalFlip,
      enableAggressiveAudio: provider.enableAggressiveAudio,
      enableAutoTrim: provider.enableAutoTrim,
      isPortrait: provider.isPortrait,
      enableHardwareAcceleration: provider.hardwareAcceleration,
      enableBlurredCanvas: provider.enableBlurredCanvas,
      canvasScalePercent: provider.canvasScalePercent,
      muteOriginalAudio: provider.muteOriginalAudio,
      enableDynamicZoom: provider.enableDynamicZoom,
      enableMicroOverlay: provider.enableMicroOverlay,
      enableFrameSkip: provider.enableFrameSkip,
      enableChromaShift: provider.enableChromaShift,
      thermalThrottle: provider.thermalThrottle,
      totalDurationMs: provider.totalDurationMs,
      targetFps: provider.targetFps,
      saturationLevel: provider.saturationLevel,
      cropZoomScale: provider.cropZoomScale,
      cropAnchor: provider.cropAnchor,
      introTrimOffset: provider.introTrimOffset,
      onProgress: (p, speed, timeMs) => _handleProgress(p, speed, timeMs, provider),
      onLog: _handleEngineLog,
    );
  }

  void _handleEngineLog(String log) {
    if (!mounted || _isCancelled) return;
    setState(() {
      _liveTerminalLogs = _liveTerminalLogs.isEmpty ? log : '$_liveTerminalLogs\n$log';
      if (_liveTerminalLogs.length > 5000) {
        _liveTerminalLogs = _liveTerminalLogs.substring(_liveTerminalLogs.length - 4000);
      }
    });
  }

  void _handleProgress(double p, double speed, int timeMs, UniquifierProvider provider) {
    if (!mounted || _isCancelled) return;
    _hasNativeProgress = true;
    if (_controller.isAnimating) _controller.stop();
    provider.updateRealtimeStats(p, speed, timeMs);
    setState(() {
      _progress = p.clamp(0.05, 0.99);
      if (_progress < 0.10) {
        _step = 1;
      } else if (_progress < 0.30) {
        _step = 2;
      } else if (_progress < 0.75) {
        _step = 3;
      } else if (_progress < 0.95) {
        _step = 4;
      } else {
        _step = 5;
      }
    });
  }

  Future<bool> _confirmCancel() async {
    final l10n = AppLocalizations.of(context);
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.confirmCancelTitle ?? 'Cancel Processing?'),
        content: Text(l10n?.confirmCancelBody ?? 'Process will be terminated and temporary files will be cleaned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n?.continueProcess ?? 'Continue')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n?.yesCancel ?? 'Yes, Cancel')),
        ],
      ),
    );
    return shouldCancel == true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();
    final fileName = provider.selectedFileName ?? 'video_01.mp4';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmCancel()) _handleCancel();
      },
      child: Scaffold(
        appBar: const TopAppBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CentralModuleCard(progress: _progress, step: _step),
                const SizedBox(height: 12),
                Expanded(
                  child: ProcessingLogViewer(
                    fileName: fileName,
                    duration: provider.duration,
                    executionTime: '${provider.renderingSpeed.toStringAsFixed(1)}x speed',
                    estimatedRemaining: provider.eta,
                    terminalLogs: _liveTerminalLogs.isNotEmpty ? _liveTerminalLogs : null,
                  ),
                ),
                const SizedBox(height: 12),
                _ActionSection(onCancel: _handleCancel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CentralModuleCard extends StatelessWidget {
  final double progress;
  final int step;

  const _CentralModuleCard({required this.progress, required this.step});

  String _getStageDescription(double p) {
    if (p < 0.10) return 'Menyiapkan staging environment & membaca metadata...';
    if (p < 0.30) return 'Menerapkan transformasi spasial, micro-trim & rotasi...';
    if (p < 0.75) return 'Memproses rendering filtergraph & penajaman kanonikal...';
    if (p < 0.95) return 'Mengompresi video fidelitas tinggi (CRF 17) & enkoding audio...';
    return 'Menyinkronkan ke galeri publik (MediaStore) & membersihkan cache...';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          const _ModuleHeaderTag(),
          const Divider(color: AppColors.surfaceContainerHighest, height: 20),
          ProcessingRadarIndicator(progress: progress),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.processingVideo ?? 'Processing video...',
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getStageDescription(progress),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.outline, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ProcessingStageTracker(currentStep: step),
        ],
      ),
    );
  }
}

class _ModuleHeaderTag extends StatelessWidget {
  const _ModuleHeaderTag();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'ENGINE: SANDBOX_V2',
          style: TextStyle(
            color: AppColors.outline,
            fontSize: 10,
            letterSpacing: 1,
            fontFamily: 'monospace',
          ),
        ),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'ACTIVE',
              style: TextStyle(
                color: AppColors.primaryContainer,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionSection extends StatelessWidget {
  final VoidCallback onCancel;
  const _ActionSection({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.outline,
        side: const BorderSide(color: AppColors.surfaceContainerHighest),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      onPressed: onCancel,
      icon: const Icon(Icons.close, size: 16),
      label: Text(l10n?.cancelProcessing ?? 'Cancel Processing', style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
    );
  }
}
