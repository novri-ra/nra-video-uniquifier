// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NRA Video Uniquifier';

  @override
  String get navProcess => 'Process';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get selectVideo => 'Select Video';

  @override
  String get changeVideo => 'Change Video';

  @override
  String get startProcess => 'Start Processing';

  @override
  String get processingVideo => 'Processing video...';

  @override
  String get cancelProcessing => 'Cancel Processing';

  @override
  String get confirmCancelTitle => 'Cancel Processing?';

  @override
  String get confirmCancelBody =>
      'Process will be terminated and temporary files will be cleaned.';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get continueProcess => 'Continue';

  @override
  String get exportSuccess => 'Export Successful';

  @override
  String get videoReadyGallery => 'Video ready in gallery';

  @override
  String get exportFailed => 'Export Failed';

  @override
  String get storageWarning =>
      'Remaining internal storage is less than 2 GB. Please clean up space before processing.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageId => 'Bahasa Indonesia (ID)';

  @override
  String get languageEn => 'English (EN)';

  @override
  String get thermalThrottleTitle => 'Thermal Throttle Mode';

  @override
  String get thermalThrottleSubtitle =>
      'Limits FFmpeg to 4 threads to prevent device overheating';

  @override
  String get framerateLabel => 'Target Framerate';

  @override
  String get sharpeningLabel => 'Sharpening Level';

  @override
  String get saturationLabel => 'Saturation Level';

  @override
  String get modifiersTitle => 'Modifiers & Filters';

  @override
  String get presetTikTok => 'TikTok / Reels';

  @override
  String get presetCinematic => 'Cinematic 2K/4K';

  @override
  String get presetExtreme => 'Extreme Evasion';
}
