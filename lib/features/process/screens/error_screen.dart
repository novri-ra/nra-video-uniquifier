import 'package:flutter/material.dart';
import '../../../core/utils/path_redactor.dart';
import '../../../shared/widgets/top_app_bar.dart';

class ErrorScreen extends StatelessWidget {
  final String? errorDetails;

  const ErrorScreen({super.key, this.errorDetails});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const TopAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
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
                    const SizedBox(height: 20),
                    const _ErrorActionButtons(),
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

class _ErrorHeroHeader extends StatelessWidget {
  const _ErrorHeroHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.error),
                ),
                child: Icon(
                  Icons.warning,
                  color: colorScheme.error,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Processing Failed',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Out of Memory or Unsupported Format',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'SANDBOX TELEMETRY',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
          ),
          child: Text(
            'FATAL',
            style: TextStyle(
              color: colorScheme.error,
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

class _TelemetryLogBox extends StatelessWidget {
  final String? errorDetails;
  const _TelemetryLogBox({this.errorDetails});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final raw =
        errorDetails ??
        '[ERROR:0x8007000E] Isolated runner process was killed by OS.\n'
            'Reason: Signal 9 (SIGKILL) - Memory pressure threshold exceeded.\n'
            'Native pipeline state: 0/4 stages completed.';
    final redacted = redactFileSystemPaths(raw);
    final summary = redacted
        .split('\n')
        .firstWhere(
          (line) => line.trim().isNotEmpty,
          orElse: () => 'Processing error',
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                summary,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ExpansionTile(
              iconColor: colorScheme.onErrorContainer,
              collapsedIconColor: colorScheme.onErrorContainer,
              title: Text(
                'View technical details',
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontSize: 11,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: SelectableText(
                    redacted,
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRecommendedFixes extends StatelessWidget {
  const _ErrorRecommendedFixes();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECOMMENDED ACTION',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 0.8,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Switch to Software (libx264) Safe Engine in Settings.\n'
            '• Toggle off Upscaling (or lower target resolution).\n'
            '• Clear temporary cache before retrying.',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12,
              height: 1.5,
            ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0,
          ),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text(
            'Try Safe Mode',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(color: colorScheme.outlineVariant),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Return to Source File'),
        ),
      ],
    );
  }
}
