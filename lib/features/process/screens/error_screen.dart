import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/top_app_bar.dart';

class ErrorScreen extends StatelessWidget {
  final String? errorDetails;

  const ErrorScreen({super.key, this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const _ErrorHeroHeader(),
                  const SizedBox(height: 20),
                  _ErrorDiagnosticsLog(errorDetails: errorDetails),
                  const SizedBox(height: 16),
                  const _ErrorRecommendedFixes(),
                ],
              ),
              const _ErrorActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorHeroHeader extends StatelessWidget {
  const _ErrorHeroHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.errorContainer),
            ),
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: const Icon(Icons.warning, color: AppColors.error, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Processing Failed',
          style: TextStyle(color: AppColors.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Out of Memory or Unsupported Format',
          style: TextStyle(color: AppColors.outline, fontSize: 12, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

class _ErrorDiagnosticsLog extends StatelessWidget {
  final String? errorDetails;
  const _ErrorDiagnosticsLog({this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          const _TelemetryHeader(),
          const SizedBox(height: 10),
          _TelemetryLogBox(errorDetails: errorDetails),
        ],
      ),
    );
  }
}

class _TelemetryHeader extends StatelessWidget {
  const _TelemetryHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text(
              'SANDBOX TELEMETRY',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, fontFamily: 'monospace'),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
          ),
          child: const Text('FATAL', style: TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
        ),
      ],
    );
  }
}

class _TelemetryLogBox extends StatelessWidget {
  final String? errorDetails;
  const _TelemetryLogBox({this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Text(
        errorDetails ??
            '[00:04.12] Error initializing codec context: Function not implemented.\n'
                '[00:04.13] [libx264 @ 0x7fa2810] Memory allocation failed (OOM).\n'
                '[00:04.14] Exit Code 137 (SIGKILL) - Low RAM Android OOM Killer.',
        style: const TextStyle(color: AppColors.error, fontSize: 11, fontFamily: 'monospace', height: 1.4),
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ErrorRecommendedFixes extends StatelessWidget {
  const _ErrorRecommendedFixes();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECOMMENDED FIXES',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, letterSpacing: 0.8, fontFamily: 'monospace'),
          ),
          SizedBox(height: 8),
          Text(
            '• Close other running apps to free up system memory.\n'
            '• Disable "Upscale to 1080p" to reduce RAM usage.\n'
            '• Verify your storage has at least 500 MB free space.',
            style: TextStyle(color: AppColors.onSurface, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorActionButtons extends StatelessWidget {
  const _ErrorActionButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            elevation: 0,
          ),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Try Again with Lower Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurface,
            side: const BorderSide(color: AppColors.surfaceContainerHighest),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to File Selection'),
        ),
      ],
    );
  }
}
