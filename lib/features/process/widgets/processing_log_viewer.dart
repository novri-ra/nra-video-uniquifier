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
    final displayLogs = (terminalLogs != null && terminalLogs!.trim().isNotEmpty)
        ? terminalLogs!
        : '[SANDBOX] Initializing media engine & filtergraph pipeline...\n[SANDBOX] Awaiting stdout/stderr stream...';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? AppColors.surface : AppColors.white;
        final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.hairlineBorder;
        final isBounded = constraints.hasBoundedHeight;
        final logBox = _TerminalLogBox(logs: displayLogs);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TelemetryRow(label: 'SOURCE', value: '$fileName ($duration)'),
              Divider(color: borderColor, height: 16),
              _TelemetryRow(label: 'EXECUTION TIME', value: '$executionTime / Est. $estimatedRemaining'),
              Divider(color: borderColor, height: 16),
              const _SandboxStateRow(),
              Divider(color: borderColor, height: 16),
              if (isBounded)
                Expanded(child: logBox)
              else
                SizedBox(height: 120, child: logBox),
            ],
          ),
        );
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = isDark ? AppColors.onSurfaceVariant : AppColors.textDark;

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
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: isDark ? FontWeight.w400 : FontWeight.w600,
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stateColor = isDark ? AppColors.onSurfaceVariant.withValues(alpha: 0.9) : AppColors.forestDeep;

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
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.memory, color: isDark ? AppColors.primaryContainer : AppColors.forestDeep, size: 13),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'CPU Core Efficiency • On-Device',
                  style: TextStyle(
                    color: stateColor,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: isDark ? FontWeight.w400 : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TerminalLogBox extends StatefulWidget {
  final String logs;

  const _TerminalLogBox({required this.logs});

  @override
  State<_TerminalLogBox> createState() => _TerminalLogBoxState();
}

class _TerminalLogBoxState extends State<_TerminalLogBox> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void didUpdateWidget(covariant _TerminalLogBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.logs != oldWidget.logs) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBg = isDark ? AppColors.surfaceContainerLowest : AppColors.offWhiteCanvas;
    final boxBorder = isDark ? AppColors.surfaceContainerHighest : AppColors.hairlineBorder;
    final logTextColor = isDark ? AppColors.onSurfaceVariant : AppColors.forestDeep;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: boxBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: boxBorder),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        child: Text(
          widget.logs,
          style: TextStyle(
            color: logTextColor,
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
