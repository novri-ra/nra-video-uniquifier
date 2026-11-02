import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Interactive bento metric cards with animated visual center gauges.
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
    const emerald = Color(0xFF10B981);

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
            border: Border.all(color: widget.isClean ? emerald.withValues(alpha: 0.35) : borderColor),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(widget.isClean ? Icons.shield_rounded : Icons.shield_outlined, color: widget.accentColor, size: 19),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.isClean ? 'ACTIVE' : 'OFF',
                      style: const TextStyle(color: emerald, fontSize: 8, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (widget.isClean)
                        BoxShadow(color: emerald.withValues(alpha: 0.25), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: widget.isClean ? 1.0 : 0.0,
                        strokeWidth: 4,
                        backgroundColor: emerald.withValues(alpha: 0.15),
                        color: emerald,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.isClean ? '100%' : '0%',
                            style: const TextStyle(color: emerald, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                          ),
                          const Text(
                            'EXIF CLEAN',
                            style: TextStyle(color: emerald, fontSize: 6.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: titleColor, fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              Text(
                widget.isClean ? 'Zero Digital Fingerprint' : 'Original Raw Exif',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: widget.isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563), fontSize: 9.5),
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
    final bgColor = widget.isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = widget.isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final titleColor = widget.isDark ? AppColors.onSurface : const Color(0xFF111827);

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
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFF06B6D4), size: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${widget.fps} FPS CFR',
                      style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 8, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _WaveBar(height: 18, delayMs: 0),
                      const SizedBox(width: 4),
                      _WaveBar(height: 32, delayMs: 150),
                      const SizedBox(width: 4),
                      _WaveBar(height: 42, delayMs: 300),
                      const SizedBox(width: 4),
                      _WaveBar(height: 26, delayMs: 450),
                      const SizedBox(width: 4),
                      _WaveBar(height: 36, delayMs: 600),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: titleColor, fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              Text(
                '${widget.codec} LOCKED • ${widget.hardwareAcc ? "GPU" : "CPU"}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 9.5, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveBar extends StatelessWidget {
  final double height;
  final int delayMs;
  const _WaveBar({required this.height, required this.delayMs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF06B6D4).withValues(alpha: 0.3), blurRadius: 4),
        ],
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
    final percent = (freeFraction * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.storage_rounded, color: ringColor, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: ringColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SANDBOX',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: freeFraction,
                    strokeWidth: 4.5,
                    backgroundColor: ringColor.withValues(alpha: 0.15),
                    color: ringColor,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent%',
                        style: TextStyle(color: ringColor, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                      ),
                      const Text(
                        'AVAILABLE',
                        style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: titleColor, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
          Text(
            freeGbText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: ringColor, fontSize: 9.5, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
