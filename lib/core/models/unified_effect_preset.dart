/// Unified effect presets available in the video uniquifier pipeline.
enum UnifiedVisualEffect {
  none(
    id: 'none',
    displayName: 'Original / None',
    description: 'No visual modification applied',
  ),
  blurredCanvas(
    id: 'blurred_canvas',
    displayName: 'Blurred Canvas / Dynamic Split',
    description: 'Blurred background canvas with scaled foreground (70%-100%)',
  ),
  motionEcho(
    id: 'motion_echo',
    displayName: 'Temporal Motion Echo',
    description: 'Multi-layer temporal clone delay echo',
  ),
  rgbSplit(
    id: 'rgb_split',
    displayName: 'RGB Temporal Split',
    description: 'Separation of R, G, B channels with temporal delay',
  ),
  dreamyBloom(
    id: 'dreamy_bloom',
    displayName: 'Dreamy Bloom / Pro-Mist',
    description: 'Soft highlight bloom and glow blending',
  ),
  film16mm(
    id: 'film_16mm',
    displayName: '16mm Nostalgia & Film Tone',
    description: 'Warm vintage analog film tone and color curves',
  ),
  dynamicGrain(
    id: 'dynamic_grain',
    displayName: 'Dynamic Noise / Film Grain',
    description: 'Temporal dynamic film grain texture injection',
  );

  final String id;
  final String displayName;
  final String description;

  const UnifiedVisualEffect({
    required this.id,
    required this.displayName,
    required this.description,
  });

  static UnifiedVisualEffect fromId(String? id) {
    return UnifiedVisualEffect.values.firstWhere(
      (e) => e.id == id,
      orElse: () => UnifiedVisualEffect.none,
    );
  }
}
