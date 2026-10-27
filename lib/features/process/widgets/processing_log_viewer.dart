import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProcessingLogViewer extends StatelessWidget {
  final String fileName;
  final String duration;
  final String executionTime;
  final String estimatedRemaining;
  final String? terminalLogs;

  const ProcessingLogViewer({
    super.key,
    required this.fileName,
    required this.duration,
    this.executionTime = '00:04s',
    this.estimatedRemaining = '00:05s rem',
    this.terminalLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TelemetryRow(label: 'SOURCE', value: '$fileName ($duration)'),
          const Divider(color: AppColors.surfaceContainerHighest, height: 16),
          _TelemetryRow(label: 'EXECUTION TIME', value: '$executionTime / Est. $estimatedRemaining'),
          const Divider(color: AppColors.surfaceContainerHighest, height: 16),
          const _SandboxStateRow(),
          if (terminalLogs != null && terminalLogs!.isNotEmpty) ...[
            const Divider(color: AppColors.surfaceContainerHighest, height: 16),
            _TerminalLogBox(logs: terminalLogs!),
          ],
        ],
      ),
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.outline,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _SandboxStateRow extends StatelessWidget {
  const _SandboxStateRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'SANDBOX STATE',
          style: TextStyle(
            color: AppColors.outline,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
        Row(
          children: [
            const Icon(Icons.memory, color: AppColors.primaryContainer, size: 13),
            const SizedBox(width: 4),
            Text(
              'CPU Core Efficiency • On-Device',
              style: TextStyle(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.9),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TerminalLogBox extends StatelessWidget {
  final String logs;

  const _TerminalLogBox({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: SingleChildScrollView(
        reverse: true,
        child: Text(
          logs,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
