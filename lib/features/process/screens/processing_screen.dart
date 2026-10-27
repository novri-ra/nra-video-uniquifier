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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CentralModuleCard(progress: _progress, step: _step),
              ProcessingLogViewer(fileName: fileName, duration: fileDuration),
              _ActionSection(
                onCancel: _handleCancel,
                onSuccessTest: _finishSuccess,
                onErrorTest: _finishError,
              ),
            ],
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
            const SizedBox(width: 5),
            const Text(
              'ACTIVE',
              style: TextStyle(
                color: AppColors.primaryContainer,
                fontSize: 10,
                fontWeight: FontWeight.w600,
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
        _CancelButton(onPressed: onCancel),
        const SizedBox(height: 8),
        _TestRow(onSuccess: onSuccessTest, onError: onErrorTest),
        const Text(
          'Realme 3 Pro OOM guard active • Process isolate isolated',
          style: TextStyle(color: AppColors.outline, fontSize: 10, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CancelButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.errorContainer),
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.close, size: 18),
      label: const Text('Cancel Operation'),
    );
  }
}

class _TestRow extends StatelessWidget {
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const _TestRow({required this.onSuccess, required this.onError});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: onSuccess,
          child: const Text('[Test Success]', style: TextStyle(color: AppColors.primaryContainer, fontSize: 11)),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onError,
          child: const Text('[Test Error]', style: TextStyle(color: AppColors.error, fontSize: 11)),
        ),
      ],
    );
  }
}
