/// Pure static formatting utilities for media duration, file sizes, audio specs, and ETA calculations.
class Formatters {
  /// Formats raw seconds or duration strings to mm:ss or hh:mm:ss display.
  static String formatDuration(String? durationStr) {
    if (durationStr == null) return '0:00';
    final sec = double.tryParse(durationStr)?.toInt() ?? 0;
    if (sec <= 0) return '0:00';
    final minutes = sec ~/ 60;
    final remainingSec = sec % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remMin = minutes % 60;
      return '$hours:${remMin.toString().padLeft(2, '0')}:${remainingSec.toString().padLeft(2, '0')}';
    }
    return '$minutes:${remainingSec.toString().padLeft(2, '0')}';
  }

  /// Formats byte count into human-readable string (B, KB, MB, GB).
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Calculates and formats ETA string for rendering progress telemetry.
  static String formatEta({
    required int totalDurationMs,
    required int timeMs,
    required double speed,
    String defaultEta = 'Calculating...',
  }) {
    if (totalDurationMs > 0 && timeMs > 0) {
      final effectiveSpeed = speed > 0 ? speed : 1.0;
      final remMs = (totalDurationMs - timeMs).clamp(0, 3600000);
      final remSec = (remMs / (effectiveSpeed * 1000)).ceil();
      return '${(remSec ~/ 60).toString().padLeft(2, '0')}:${(remSec % 60).toString().padLeft(2, '0')}s rem';
    }
    return defaultEta;
  }

  /// Formats audio codec and sample rate into human-readable descriptor (e.g. 'AAC 48kHz').
  static String formatAudioInfo(String? codec, String? sampleRate) {
    final c = codec?.toUpperCase() ?? 'AAC';
    final khz = sampleRate != null && int.tryParse(sampleRate) != null
        ? '${(int.parse(sampleRate) / 1000).toStringAsFixed(0)}kHz'
        : '48kHz';
    return '$c $khz';
  }
}
