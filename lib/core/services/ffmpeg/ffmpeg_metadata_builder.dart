import '../../utils/variation_generator.dart';

/// Assembles MP4 container metadata and device tags for FFmpeg commands.
class FfmpegMetadataBuilder {
  /// Appends metadata removal and randomized device profile tags to the command buffer.
  static void writeMetadataTags(
    StringBuffer buffer, [
    DeviceProfile profile = DeviceProfile.defaultProfile,
  ]) {
    buffer.write(
      ' -map_metadata -1 -map_chapters -1 -bitexact -fflags +bitexact'
      ' -metadata make="${profile.make}" -metadata model="${profile.model}" -metadata encoder="${profile.encoder}"'
      ' -metadata:s:v:0 handler_name="${profile.videoHandler}" -metadata:s:a:0 handler_name="${profile.audioHandler}"',
    );
  }
}
