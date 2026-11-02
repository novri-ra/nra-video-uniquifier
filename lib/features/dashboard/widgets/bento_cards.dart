import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'bento_engine_card.dart';

/// Interactive bento metric cards with scaled-up visual gauges and balanced hierarchy.
class BentoCards {
  static Widget buildHygieneCard({
    required String title,
    required bool isClean,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) =>
      _BentoHygieneCard(
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
  }) =>
      BentoEngineCard(
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
  }) =>
      _BentoStorageCard(
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

  Widget _buildTopRow() {
    const emerald = Color(0xFF10B981);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(
          widget.isClean ? Icons.shield_rounded : Icons.shield_outlined,
          color: widget.accentColor,
          size: 19,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: emerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.isClean ? 'ACTIVE' : 'OFF',
            style: const TextStyle(
              color: emerald,
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
    const emerald = Color(0xFF10B981);
    final labelColor = widget.isDark ? Colors.white70 : const Color(0xFF4B5563);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                if (widget.isClean)
                  BoxShadow(
                    color: emerald.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: widget.isClean ? 1.0 : 0.0,
                  strokeWidth: 5.5,
                  backgroundColor: emerald.withValues(alpha: 0.15),
                  color: emerald,
                ),
                Text(
                  widget.isClean ? '100%' : '0%',
                  style: const TextStyle(
                    color: emerald,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'EXIF CLEAN',
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color titleColor, Color subColor) {
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
          widget.isClean ? 'Zero Digital Fingerprint' : 'Original Raw Exif',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: subColor, fontSize: 9.5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = widget.isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final titleColor = widget.isDark ? AppColors.onSurface : const Color(0xFF111827);
    final subColor = widget.isDark ? AppColors.onSurfaceVariant : const Color(0xFF4B5563);
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
          padding: const EdgeInsets.all(14),
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
              _buildTopRow(),
              const Spacer(),
              _buildCenterVisual(),
              const Spacer(),
              _buildFooter(titleColor, subColor),
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

  Widget _buildTopRow() {
    return Row(
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
    );
  }

  Widget _buildCenterVisual() {
    final percent = (freeFraction * 100).toInt();
    const cyan = Color(0xFF06B6D4);
    final labelColor = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: freeFraction,
                  strokeWidth: 5.5,
                  backgroundColor: ringColor.withValues(alpha: 0.15),
                  color: ringColor,
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: cyan,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AVAILABLE',
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.surfaceContainerLow : Colors.white;
    final borderColor = isDark ? AppColors.surfaceContainerHighest : AppColors.lightOutlineVariant;
    final titleColor = isDark ? AppColors.onSurface : const Color(0xFF111827);

    return Container(
      padding: const EdgeInsets.all(14),
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
          _buildTopRow(),
          const Spacer(),
          _buildCenterVisual(),
          const Spacer(),
          _buildFooter(titleColor),
        ],
      ),
    );
  }
}
