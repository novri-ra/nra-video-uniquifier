import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProcessingRadarIndicator extends StatelessWidget {
  final double progress;

  const ProcessingRadarIndicator({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final size = screenHeight < 640 ? 120.0 : 150.0;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: RadialProgressPainter(progress: progress),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: size < 130 ? 24 : 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: AppColors.outline,
                      fontSize: 9,
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class RadialProgressPainter extends CustomPainter {
  final double progress;

  const RadialProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    final backgroundPaint = Paint()
      ..color = AppColors.surfaceContainerHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final progressPaint = Paint()
      ..color = AppColors.primaryContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RadialProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
