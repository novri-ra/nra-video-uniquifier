import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Bento card displaying hardware engine vitals, locked CFR, and equalizer bars.
class BentoEngineCard extends StatefulWidget {
  final String title;
  final int fps;
  final String codec;
  final bool hardwareAcc;
  final bool isDark;
  final VoidCallback onTap;

  const BentoEngineCard({
    super.key,
    required this.title,
    required this.fps,
    required this.codec,
    required this.hardwareAcc,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<BentoEngineCard> createState() => _BentoEngineCardState();
}

class _BentoEngineCardState extends State<BentoEngineCard> {
  bool _pressed = false;

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(Icons.bolt_rounded, color: AppColors.electricIce, size: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.electricIce.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${widget.fps} FPS CFR',
            style: const TextStyle(
              color: AppColors.electricIce,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterVisual() {
    final labelColor = widget.isDark ? Colors.white70 : const Color(0xFF4B5563);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _WaveBar(height: 24),
                SizedBox(width: 5),
                _WaveBar(height: 40),
                SizedBox(width: 5),
                _WaveBar(height: 52),
                SizedBox(width: 5),
                _WaveBar(height: 34),
                SizedBox(width: 5),
                _WaveBar(height: 46),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.fps} FPS CFR • ${widget.codec}',
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color titleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          style: const TextStyle(
            color: AppColors.electricIce,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration(Color bg, Color border) => BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          if (!widget.isDark)
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? AppColors.obsidianDark : Colors.white;
    final borderColor = widget.isDark ? const Color(0x1FA3EFD5) : AppColors.lightOutlineVariant;
    final titleColor = widget.isDark ? AppColors.onSurface : AppColors.lightOnSurface;

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
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          decoration: _cardDecoration(bgColor, borderColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(),
              const Spacer(),
              _buildCenterVisual(),
              const Spacer(),
              _buildFooter(titleColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveBar extends StatelessWidget {
  final double height;
  const _WaveBar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          colors: [AppColors.electricIce, AppColors.skyPastel],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        boxShadow: [
          BoxShadow(color: AppColors.electricIce.withValues(alpha: 0.35), blurRadius: 4),
        ],
      ),
    );
  }
}
