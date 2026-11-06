import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Defines how the floating preview visualizes a parameter change.
enum PreviewEffect {
  /// Simulates crop/zoom by scaling the thumbnail.
  cropZoom,

  /// Simulates rotation by rotating the thumbnail.
  microRotation,

  /// Simulates sharpening via increased contrast.
  sharpening,

  /// Simulates saturation via color matrix.
  saturation,

  /// Simulates blurred canvas scale via padded frame.
  canvasScale,
}

/// Reusable slider with a floating preview overlay that shows a real-time
/// visual transformation on the video thumbnail while the user drags.
///
/// The overlay appears on [onChangeStart], updates each frame via
/// local Flutter transforms (zero FFmpeg calls), and fades out on
/// [onChangeEnd] with a 200ms animation.
class InteractivePreviewSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String label;
  final String parameterName;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final PreviewEffect effect;

  /// Path to the source video thumbnail. When null, overlay shows a
  /// placeholder icon instead of a real image.
  final String? thumbnailPath;

  /// Whether FFmpeg is actively rendering a debounced preview frame.
  final bool isPreviewRendering;

  /// Rendered single-frame image path generated via FFmpeg.
  final String? renderedPreviewFramePath;

  /// Aspect ratio for full-fidelity preview frame display (defaults to 16/9).
  final double? aspectRatio;

  const InteractivePreviewSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.label,
    required this.parameterName,
    required this.onChanged,
    this.onChangeEnd,
    required this.effect,
    this.thumbnailPath,
    this.isPreviewRendering = false,
    this.renderedPreviewFramePath,
    this.aspectRatio,
  });

  @override
  State<InteractivePreviewSlider> createState() =>
      _InteractivePreviewSliderState();
}

class _InteractivePreviewSliderState extends State<InteractivePreviewSlider>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _fadeController;
  double _liveValue = 0;

  @override
  void initState() {
    super.initState();
    _liveValue = widget.value;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void didUpdateWidget(covariant InteractivePreviewSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && _overlayEntry == null) {
      _liveValue = widget.value;
    }
    if (_overlayEntry != null &&
        (widget.isPreviewRendering != oldWidget.isPreviewRendering ||
            widget.renderedPreviewFramePath !=
                oldWidget.renderedPreviewFramePath ||
            widget.thumbnailPath != oldWidget.thumbnailPath)) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _fadeController.dispose();
    super.dispose();
  }

  void _showOverlay() {
    _removeOverlay();
    _liveValue = widget.value;
    _overlayEntry = OverlayEntry(
      builder: (_) => _FloatingPreviewOverlay(
        animation: _fadeController,
        liveValue: _liveValue,
        parameterName: widget.parameterName,
        label: widget.label,
        effect: widget.effect,
        thumbnailPath: widget.thumbnailPath,
        min: widget.min,
        max: widget.max,
        isPreviewRendering: widget.isPreviewRendering,
        renderedPreviewFramePath: widget.renderedPreviewFramePath,
        aspectRatio: widget.aspectRatio,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    _fadeController.forward(from: 0);
  }

  void _updateOverlay(double val) {
    _liveValue = val;
    widget.onChanged(val);
    _overlayEntry?.markNeedsBuild();
  }

  void _hideOverlay(double val) {
    widget.onChangeEnd?.call(val);
    _fadeController.reverse().then((_) {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final inactiveColor = isDark
        ? AppColors.surfaceContainerHighest
        : AppColors.lightOutlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.parameterName,
                style: TextStyle(
                  color: isDark
                      ? AppColors.outline
                      : AppColors.lightOnSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: activeColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: activeColor,
            inactiveTrackColor: inactiveColor,
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.16),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: widget.value.clamp(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChangeStart: (_) => _showOverlay(),
            onChanged: _updateOverlay,
            onChangeEnd: _hideOverlay,
          ),
        ),
      ],
    );
  }
}

class _FloatingPreviewOverlay extends StatelessWidget {
  final Animation<double> animation;
  final double liveValue;
  final String parameterName;
  final String label;
  final PreviewEffect effect;
  final String? thumbnailPath;
  final double min;
  final double max;
  final bool isPreviewRendering;
  final String? renderedPreviewFramePath;
  final double? aspectRatio;

  const _FloatingPreviewOverlay({
    required this.animation,
    required this.liveValue,
    required this.parameterName,
    required this.label,
    required this.effect,
    required this.thumbnailPath,
    required this.min,
    required this.max,
    this.isPreviewRendering = false,
    this.renderedPreviewFramePath,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.obsidianDark.withValues(alpha: 0.95)
        : AppColors.white.withValues(alpha: 0.96);
    final borderCol = isDark
        ? AppColors.outlineVariant
        : AppColors.lightOutlineVariant;
    final accent = isDark ? AppColors.mintSage : AppColors.forestDeep;
    final size = MediaQuery.of(context).size;
    final previewWidth = (size.width * 0.44).clamp(130.0, 200.0);
    final ratio = aspectRatio ?? (16 / 9);
    final previewHeight = (previewWidth / ratio).clamp(70.0, 220.0);
    final cardWidth = previewWidth + 24;

    return Positioned(
      top: size.height * 0.15,
      left: (size.width - cardWidth) / 2,
      child: FadeTransition(
        opacity: animation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCol),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  parameterName,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.onSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: previewWidth,
                    height: previewHeight,
                    color: const Color(0xFF141E1C),
                    child: AspectRatio(
                      aspectRatio: ratio,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: previewWidth,
                          height: previewHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                child: _buildPreviewContent(
                                  previewWidth,
                                  previewHeight,
                                  accent,
                                ),
                              ),
                              if (isPreviewRendering)
                                Positioned(
                                  bottom: 4,
                                  left: 6,
                                  right: 6,
                                  child: _buildLoadingBadge(accent),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatLiveLabel(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBadge(Color accent) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.6), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(width: 4),
            const Flexible(
              child: Text(
                'Rendering preview...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLiveLabel() {
    switch (effect) {
      case PreviewEffect.cropZoom:
        return '${liveValue.toStringAsFixed(2)}x';
      case PreviewEffect.microRotation:
        return '${liveValue >= 0 ? '+' : ''}${liveValue.toStringAsFixed(1)}°';
      case PreviewEffect.sharpening:
        return '${liveValue.toStringAsFixed(1)}x';
      case PreviewEffect.saturation:
        return '${liveValue.toStringAsFixed(2)}x';
      case PreviewEffect.canvasScale:
        return '${liveValue.toInt()}%';
    }
  }

  Widget _buildPreviewContent(
    double previewWidth,
    double previewHeight,
    Color accent,
  ) {
    if (renderedPreviewFramePath != null &&
        File(renderedPreviewFramePath!).existsSync()) {
      return Image.file(
        File(renderedPreviewFramePath!),
        key: ValueKey<String>(renderedPreviewFramePath!),
        fit: BoxFit.contain,
        width: previewWidth,
        height: previewHeight,
        errorBuilder: (_, _, _) =>
            _buildSimulatedFallback(previewWidth, previewHeight, accent),
      );
    }

    return _buildSimulatedFallback(
      previewWidth,
      previewHeight,
      accent,
      key: const ValueKey<String>('simulated_preview'),
    );
  }

  Widget _buildSimulatedFallback(
    double previewWidth,
    double previewHeight,
    Color accent, {
    Key? key,
  }) {
    Widget thumbnail;
    if (thumbnailPath != null && thumbnailPath!.isNotEmpty) {
      thumbnail = Image.file(
        File(thumbnailPath!),
        fit: BoxFit.contain,
        width: previewWidth,
        height: previewHeight,
        errorBuilder: (_, _, _) =>
            _placeholderBox(previewWidth, previewHeight, accent),
      );
    } else {
      thumbnail = _placeholderBox(previewWidth, previewHeight, accent);
    }

    return KeyedSubtree(
      key: key ?? UniqueKey(),
      child: _applyEffect(thumbnail),
    );
  }

  Widget _placeholderBox(double width, double height, Color accent) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF2A3A37),
      child: Center(
        child: Icon(Icons.videocam_outlined, color: accent, size: 32),
      ),
    );
  }

  Widget _applyEffect(Widget child) {
    final normalized = max > min ? (liveValue - min) / (max - min) : 0.5;

    switch (effect) {
      case PreviewEffect.cropZoom:
        // 1.0x → 1.5x maps to scale 1.0 → 1.5
        final scale = 1.0 + (normalized * 0.5);
        return Transform.scale(scale: scale, child: child);

      case PreviewEffect.microRotation:
        // -2° to +2° rotation
        final angle = (normalized - 0.5) * 0.07;
        return Transform.rotate(angle: angle, child: child);

      case PreviewEffect.sharpening:
        // Simulate sharpness via slight contrast boost
        final contrast = 0.8 + (normalized * 0.4);
        return ColorFiltered(
          colorFilter: ColorFilter.matrix(<double>[
            contrast,
            0,
            0,
            0,
            (1 - contrast) * 128,
            0,
            contrast,
            0,
            0,
            (1 - contrast) * 128,
            0,
            0,
            contrast,
            0,
            (1 - contrast) * 128,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        );

      case PreviewEffect.saturation:
        // Desaturate (0.8) to oversaturate (1.3)
        final sat = 0.8 + (normalized * 0.5);
        final inv = 1 - sat;
        final r = 0.2126 * inv;
        final g = 0.7152 * inv;
        final b = 0.0722 * inv;
        return ColorFiltered(
          colorFilter: ColorFilter.matrix(<double>[
            r + sat,
            g,
            b,
            0,
            0,
            r,
            g + sat,
            b,
            0,
            0,
            r,
            g,
            b + sat,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: child,
        );

      case PreviewEffect.canvasScale:
        // Simulate scale-down inside padded frame
        final scale = 0.7 + (normalized * 0.3);
        return Container(
          color: const Color(0xFF1A2523),
          child: Center(
            child: Transform.scale(scale: scale, child: child),
          ),
        );
    }
  }
}
