import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Interactive bento metric cards with press micro-animations.
class BentoCards {
  static Widget buildHygieneCard({
    required String title,
    required bool isClean,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) => _BentoHygieneCard(
        title: title,
        isClean: isClean,
        accentColor: accentColor,
        isDark: isDark,
        onTap: onTap,
      );

  static Widget buildEngineCard({
    required String title,
    required int fps,
    required String codec,
    required bool hardwareAcc,
    required bool isDark,
    required VoidCallback onTap,
  }) => _BentoEngineCard(
        title: title,
        fps: fps,
        codec: codec,
        hardwareAcc: hardwareAcc,
        isDark: isDark,
        onTap: onTap,
      );

  static Widget buildStorageCard({
    required String title,
    required String freeGbText,
    required double freeFraction,
    required Color ringColor,
    required bool isDark,
  }) => _BentoStorageCard(
        title: title,
        freeGbText: freeGbText,
        freeFraction: freeFraction,
        ringColor: ringColor,
        isDark: isDark,
      );
}

class _BentoHygieneCard extends StatefulWidget {
  final String title;
  final bool isClean;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _BentoHygieneCard({
    required this.title,
    required this.isClean,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_BentoHygieneCard> createState() => _BentoHygieneCardState();
}

class _BentoHygieneCardState extends State<_BentoHygieneCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = widget.isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final titleColor = widget.isDark ? AppColors.onSurface : const Color(0xFF111827);
    final detailColor = widget.isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.isClean ? widget.accentColor.withValues(alpha: 0.35) : borderColor),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    widget.isClean ? Icons.shield_rounded : Icons.shield_outlined,
                    color: widget.accentColor,
                    size: 20,
                  ),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: widget.isClean ? 1.0 : 0.2,
                          strokeWidth: 2.8,
                          backgroundColor: widget.accentColor.withValues(alpha: 0.15),
                          color: widget.accentColor,
                        ),
                        Icon(
                          widget.isClean ? Icons.check : Icons.lock_open_rounded,
                          size: 11,
                          color: widget.accentColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.isClean ? '100% EXIF Clean • Scrubbed' : 'Raw Exif Active • Unscrubbed',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: detailColor, fontSize: 9.5, height: 1.25),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoEngineCard extends StatefulWidget {
  final String title;
  final int fps;
  final String codec;
  final bool hardwareAcc;
  final bool isDark;
  final VoidCallback onTap;

  const _BentoEngineCard({
    required this.title,
    required this.fps,
    required this.codec,
    required this.hardwareAcc,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_BentoEngineCard> createState() => _BentoEngineCardState();
}

class _BentoEngineCardState extends State<_BentoEngineCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const engineColor = Color(0xFF6C5CE7);
    final bgColor = widget.isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = widget.isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final titleColor = widget.isDark ? AppColors.onSurface : const Color(0xFF111827);
    final detailColor = widget.isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.bolt_rounded, color: engineColor, size: 21),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: engineColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${widget.fps} FPS CFR',
                      style: const TextStyle(
                        color: engineColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.codec} • ${widget.hardwareAcc ? "GPU HW" : "CPU"} Locked',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: detailColor, fontSize: 9.5, height: 1.25),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoStorageCard extends StatelessWidget {
  final String title, freeGbText;
  final double freeFraction;
  final Color ringColor;
  final bool isDark;

  const _BentoStorageCard({
    required this.title,
    required this.freeGbText,
    required this.freeFraction,
    required this.ringColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);
    final detailColor = isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.storage_rounded, color: ringColor, size: 20),
              SizedBox(
                width: 28,
                height: 28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: freeFraction,
                      strokeWidth: 3,
                      backgroundColor: ringColor.withValues(alpha: 0.15),
                      color: ringColor,
                    ),
                    Text(
                      '${(freeFraction * 100).toInt()}%',
                      style: TextStyle(
                        color: ringColor,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: freeFraction,
                  minHeight: 4,
                  backgroundColor: ringColor.withValues(alpha: 0.15),
                  color: ringColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                freeGbText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: detailColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
