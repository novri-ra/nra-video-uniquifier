import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// Static application name
  ///
  /// In en, this message translates to:
  /// **'NRA Video Uniquifier'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navDashboard;

  /// No description provided for @navStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get navStudio;

  /// No description provided for @navMicrostock.
  ///
  /// In en, this message translates to:
  /// **'Microstock AI'**
  String get navMicrostock;

  /// No description provided for @navBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get navBatch;

  /// No description provided for @navProcess.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get navProcess;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @selectVideo.
  ///
  /// In en, this message translates to:
  /// **'Select Video'**
  String get selectVideo;

  /// No description provided for @changeVideo.
  ///
  /// In en, this message translates to:
  /// **'Change Video'**
  String get changeVideo;

  /// No description provided for @startProcess.
  ///
  /// In en, this message translates to:
  /// **'Start Processing'**
  String get startProcess;

  /// No description provided for @processingVideo.
  ///
  /// In en, this message translates to:
  /// **'Processing video...'**
  String get processingVideo;

  /// No description provided for @cancelProcessing.
  ///
  /// In en, this message translates to:
  /// **'Cancel Processing'**
  String get cancelProcessing;

  /// No description provided for @confirmCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Processing?'**
  String get confirmCancelTitle;

  /// No description provided for @confirmCancelBody.
  ///
  /// In en, this message translates to:
  /// **'Process will be terminated and temporary files will be cleaned.'**
  String get confirmCancelBody;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @continueProcess.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueProcess;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export Successful'**
  String get exportSuccess;

  /// No description provided for @videoReadyGallery.
  ///
  /// In en, this message translates to:
  /// **'Video ready in gallery'**
  String get videoReadyGallery;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export Failed'**
  String get exportFailed;

  /// No description provided for @storageWarning.
  ///
  /// In en, this message translates to:
  /// **'Remaining internal storage is less than 2 GB. Please clean up space before processing.'**
  String get storageWarning;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageId.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia (ID)'**
  String get languageId;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English (EN)'**
  String get languageEn;

  /// No description provided for @themeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeModeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @greetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Creator'**
  String get greetingTitle;

  /// No description provided for @gpuStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Vulkan NCNN Ready'**
  String get gpuStatusReady;

  /// No description provided for @seasonalWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Seasonal Upload Window (60-90 Days Lead Time)'**
  String get seasonalWindowTitle;

  /// No description provided for @storageBuffer.
  ///
  /// In en, this message translates to:
  /// **'Storage Buffer'**
  String get storageBuffer;

  /// No description provided for @metadataHygiene.
  ///
  /// In en, this message translates to:
  /// **'Metadata Hygiene'**
  String get metadataHygiene;

  /// No description provided for @techSpecsGuard.
  ///
  /// In en, this message translates to:
  /// **'Technical Specs Guard'**
  String get techSpecsGuard;

  /// No description provided for @assetStaging.
  ///
  /// In en, this message translates to:
  /// **'Asset Staging Pipeline'**
  String get assetStaging;

  /// No description provided for @inspirationTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Microstock Trends'**
  String get inspirationTitle;

  /// No description provided for @groupPreferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get groupPreferences;

  /// No description provided for @groupHardware.
  ///
  /// In en, this message translates to:
  /// **'HARDWARE & ENGINE'**
  String get groupHardware;

  /// No description provided for @groupStorage.
  ///
  /// In en, this message translates to:
  /// **'STORAGE & CACHE'**
  String get groupStorage;

  /// No description provided for @groupAbout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT & BRAND'**
  String get groupAbout;

  /// No description provided for @thermalThrottleTitle.
  ///
  /// In en, this message translates to:
  /// **'Thermal Throttle Mode'**
  String get thermalThrottleTitle;

  /// No description provided for @thermalThrottleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Limits FFmpeg to 4 threads to prevent device overheating'**
  String get thermalThrottleSubtitle;

  /// No description provided for @framerateLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Framerate'**
  String get framerateLabel;

  /// No description provided for @sharpeningLabel.
  ///
  /// In en, this message translates to:
  /// **'Sharpening Level'**
  String get sharpeningLabel;

  /// No description provided for @saturationLabel.
  ///
  /// In en, this message translates to:
  /// **'Saturation Level'**
  String get saturationLabel;

  /// No description provided for @modifiersTitle.
  ///
  /// In en, this message translates to:
  /// **'Modifiers & Filters'**
  String get modifiersTitle;

  /// No description provided for @presetTikTok.
  ///
  /// In en, this message translates to:
  /// **'TikTok / Reels'**
  String get presetTikTok;

  /// No description provided for @presetCinematic.
  ///
  /// In en, this message translates to:
  /// **'Cinematic 2K/4K'**
  String get presetCinematic;

  /// No description provided for @presetExtreme.
  ///
  /// In en, this message translates to:
  /// **'Extreme Evasion'**
  String get presetExtreme;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
