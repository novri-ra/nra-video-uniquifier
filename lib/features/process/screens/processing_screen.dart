import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/uniquifier_provider.dart';
import '../../../core/services/ffmpeg_service.dart';
import '../../../core/theme/app_theme.dart';
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
  double _progress = 0.45;
  int _step = 2;
  bool _isCancelled = false;

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
    if (!mounted || _isCancelled) return;
    setState(() {
      _progress = 0.10 + (_controller.value * 0.85);
      if (_progress < 0.25) {
        _step = 1;
      } else if (_progress < 0.55) {
        _step = 2;
      } else if (_progress < 0.85) {
        _step = 3;
      } else {
        _step = 4;
      }
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
      String outputPath;
      if (inputPath == null || inputPath.isEmpty) {
        await Future.delayed(const Duration(seconds: 3));
        outputPath = await FfmpegService.generateOutputPath('video_01.mp4');
      } else {
        outputPath = await FfmpegService.processVideo(
          inputPath: inputPath,
          removeMetadata: provider.removeMetadata,
          modifyAudio: provider.modifyAudio,
          modifyVisuals: provider.modifyVisuals,
          upscale1080p: provider.upscale1080p,
          targetResolution: provider.targetResolution,
          videoCodec: provider.videoCodec,
          enableEnhanceAndDenoise: provider.enableEnhanceAndDenoise,
          enableDeepAntiFingerprint: provider.enableDeepAntiFingerprint,
          enableHorizontalFlip: provider.enableHorizontalFlip,
          enableAggressiveAudio: provider.enableAggressiveAudio,
          enableAutoTrim: provider.enableAutoTrim,
          isPortrait: provider.isPortrait,
          enableHardwareAcceleration: provider.hardwareAcceleration,
          totalDurationMs: provider.totalDurationMs,
          onProgress: (p, speed, timeMs) {
            if (mounted && !_isCancelled) {
              if (_controller.isAnimating) {
                _controller.stop();
              }
              provider.updateRealtimeStats(p, speed, timeMs);
              setState(() {
                _progress = p.clamp(0.05, 0.98);
                if (_progress < 0.25) {
                  _step = 1;
                } else if (_progress < 0.55) {
                  _step = 2;
                } else if (_progress < 0.85) {
                  _step = 3;
                } else {
                  _step = 4;
                }
              });
            }
          },
        );
      }

      if (!mounted || _isCancelled) return;
      provider.setLastProcessedResult(outputPath);
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

  void _finishSuccess() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SuccessScreen()),
    );
  }

  void _finishError() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ErrorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UniquifierProvider>();
    final fileName = provider.selectedFileName ?? 'video_01.mp4';
    final fileDuration = provider.duration;

    return Scaffold(
      appBar: const TopAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        _CentralModuleCard(progress: _progress, step: _step),
                        const SizedBox(height: 16),
                        ProcessingLogViewer(
                          fileName: fileName,
                          duration: fileDuration,
                          executionTime: '${provider.renderingSpeed.toStringAsFixed(1)}x speed',
                          estimatedRemaining: provider.eta,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _ActionSection(
                      onCancel: _handleCancel,
                      onSuccessTest: _finishSuccess,
                      onErrorTest: _finishError,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CentralModuleCard extends StatelessWidget {
  final double progress;
  final int step;

  const _CentralModuleCard({required this.progress, required this.step});

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
          const Text(
            'Processing video...',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Applying micro-crop & shifting audio pitch\n(Step $step of 4)',
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
  final VoidCallback onSuccessTest;
  final VoidCallback onErrorTest;

  const _ActionSection({
    required this.onCancel,
    required this.onSuccessTest,
    required this.onErrorTest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.outline,
            side: const BorderSide(color: AppColors.surfaceContainerHighest),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: onCancel,
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Cancel Processing', style: TextStyle(fontFamily: 'monospace', fontSize: 13)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: onSuccessTest,
              child: const Text('Simulate Success', style: TextStyle(color: AppColors.outline, fontSize: 11)),
            ),
            const SizedBox(width: 8),
            const Text('•', style: TextStyle(color: AppColors.outline, fontSize: 11)),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onErrorTest,
              child: const Text('Simulate Error', style: TextStyle(color: AppColors.outline, fontSize: 11)),
            ),
          ],
        ),
      ],
    );
  }
}
