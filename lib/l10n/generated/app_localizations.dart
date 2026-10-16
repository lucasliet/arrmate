import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('es'),
    Locale('pt'),
    Locale('pt', 'BR'),
  ];

  /// No description provided for @activityTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get activityTabHistory;

  /// No description provided for @activityTabQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get activityTabQueue;

  /// No description provided for @activityTabTorrents.
  ///
  /// In en, this message translates to:
  /// **'Torrents'**
  String get activityTabTorrents;

  /// No description provided for @activityTabWatching.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get activityTabWatching;

  /// No description provided for @appInitErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Initialization Error'**
  String get appInitErrorTitle;

  /// No description provided for @appInitNotificationServicesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize notification services. Some features may not work correctly.'**
  String get appInitNotificationServicesFailed;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrmate'**
  String get appTitle;

  /// No description provided for @appleIntelligenceAssetsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The Apple Intelligence model is not ready yet. Try again later.'**
  String get appleIntelligenceAssetsUnavailable;

  /// No description provided for @appleIntelligenceBusy.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence is busy. Try again in a moment.'**
  String get appleIntelligenceBusy;

  /// No description provided for @appleIntelligenceContextTooLong.
  ///
  /// In en, this message translates to:
  /// **'The question is too long for Apple Intelligence. Try a shorter one.'**
  String get appleIntelligenceContextTooLong;

  /// No description provided for @appleIntelligenceDeclined.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence declined to answer. Try rephrasing the question.'**
  String get appleIntelligenceDeclined;

  /// No description provided for @appleIntelligenceDeviceNotEligible.
  ///
  /// In en, this message translates to:
  /// **'This device does not support Apple Intelligence.'**
  String get appleIntelligenceDeviceNotEligible;

  /// No description provided for @appleIntelligenceGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence failed to generate a response.'**
  String get appleIntelligenceGenerationFailed;

  /// No description provided for @appleIntelligenceModelNotReady.
  ///
  /// In en, this message translates to:
  /// **'The Apple Intelligence model is still downloading. Try again later.'**
  String get appleIntelligenceModelNotReady;

  /// No description provided for @appleIntelligenceNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Turn on Apple Intelligence in the system settings.'**
  String get appleIntelligenceNotEnabled;

  /// No description provided for @appleIntelligenceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence is unavailable on this device.'**
  String get appleIntelligenceUnavailable;

  /// No description provided for @appleIntelligenceUnsupportedLanguage.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence does not support this language on this device.'**
  String get appleIntelligenceUnsupportedLanguage;

  /// No description provided for @appleIntelligenceUnsupportedOs.
  ///
  /// In en, this message translates to:
  /// **'Apple Intelligence requires iOS 26 or macOS 26.'**
  String get appleIntelligenceUnsupportedOs;

  /// No description provided for @assistantCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get assistantCloud;

  /// No description provided for @assistantDeleteModelContent.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{model}\" from your device?'**
  String assistantDeleteModelContent(String model);

  /// No description provided for @assistantDeleteModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Model'**
  String get assistantDeleteModelTitle;

  /// No description provided for @assistantDownloadModel.
  ///
  /// In en, this message translates to:
  /// **'Download Model'**
  String get assistantDownloadModel;

  /// No description provided for @assistantDownloadingModel.
  ///
  /// In en, this message translates to:
  /// **'Downloading Model'**
  String get assistantDownloadingModel;

  /// No description provided for @assistantEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Ask about the app'**
  String get assistantEmptyPrompt;

  /// No description provided for @assistantInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about Arrmate...'**
  String get assistantInputHint;

  /// No description provided for @assistantInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get assistantInstalled;

  /// No description provided for @assistantLinkNotOpened.
  ///
  /// In en, this message translates to:
  /// **'The link could not be opened'**
  String get assistantLinkNotOpened;

  /// No description provided for @assistantLocalModels.
  ///
  /// In en, this message translates to:
  /// **'Local Models'**
  String get assistantLocalModels;

  /// No description provided for @assistantNoLocalModel.
  ///
  /// In en, this message translates to:
  /// **'No local model selected'**
  String get assistantNoLocalModel;

  /// No description provided for @assistantOnDeviceModel.
  ///
  /// In en, this message translates to:
  /// **'On-device model'**
  String get assistantOnDeviceModel;

  /// No description provided for @assistantOnlineModel.
  ///
  /// In en, this message translates to:
  /// **'Online model'**
  String get assistantOnlineModel;

  /// No description provided for @assistantOnlyHttpsLinks.
  ///
  /// In en, this message translates to:
  /// **'Only HTTPS links are supported'**
  String get assistantOnlyHttpsLinks;

  /// No description provided for @assistantOpenLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open link: {error}'**
  String assistantOpenLinkFailed(String error);

  /// No description provided for @assistantSelectModelFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a model first'**
  String get assistantSelectModelFirst;

  /// No description provided for @assistantStartingDownload.
  ///
  /// In en, this message translates to:
  /// **'Starting download...'**
  String get assistantStartingDownload;

  /// No description provided for @assistantSwitchModel.
  ///
  /// In en, this message translates to:
  /// **'Switch Model'**
  String get assistantSwitchModel;

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistantTitle;

  /// No description provided for @assistantUseCloud.
  ///
  /// In en, this message translates to:
  /// **'Use Cloud'**
  String get assistantUseCloud;

  /// No description provided for @assistantUseCloudOrLocal.
  ///
  /// In en, this message translates to:
  /// **'Use Cloud or import/download a local model'**
  String get assistantUseCloudOrLocal;

  /// No description provided for @backupAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version: {version}'**
  String backupAppVersion(String version);

  /// No description provided for @backupAutomaticNote.
  ///
  /// In en, this message translates to:
  /// **'Automatic backups run about 30 seconds after you change instances or settings, while signed in. Some settings (like the home tab) apply fully after restarting the app.'**
  String get backupAutomaticNote;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {time}'**
  String backupCreated(String time);

  /// No description provided for @backupDriveDescription.
  ///
  /// In en, this message translates to:
  /// **'Your settings, preferences and configured instances (including their API keys) are stored in the app\'s private folder on your Google Drive, invisible to other apps.'**
  String get backupDriveDescription;

  /// No description provided for @backupDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Drive backup'**
  String get backupDriveTitle;

  /// No description provided for @backupDriveUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This build was compiled without Google credentials. Ask the developer to build with the Google OAuth configuration, or run locally with the --dart-define flags. Use the local file backup below instead.'**
  String get backupDriveUnavailableMessage;

  /// No description provided for @backupDriveUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Drive backup not available'**
  String get backupDriveUnavailableTitle;

  /// No description provided for @backupExportToFile.
  ///
  /// In en, this message translates to:
  /// **'Export backup to file'**
  String get backupExportToFile;

  /// No description provided for @backupExportToFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a .json copy on this device'**
  String get backupExportToFileSubtitle;

  /// No description provided for @backupExported.
  ///
  /// In en, this message translates to:
  /// **'Backup exported to {fileName}'**
  String backupExported(String fileName);

  /// No description provided for @backupFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved {time}. Restore it to bring its settings and instances to this device. Automatic backups stay paused until you restore or back up manually.'**
  String backupFoundMessage(String time);

  /// No description provided for @backupFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup found in your Google Drive'**
  String get backupFoundTitle;

  /// No description provided for @backupInstanceCount.
  ///
  /// In en, this message translates to:
  /// **'Instances: {count}'**
  String backupInstanceCount(int count);

  /// No description provided for @backupLastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {time}'**
  String backupLastBackup(String time);

  /// No description provided for @backupNever.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get backupNever;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNow;

  /// No description provided for @backupPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform: {platform}'**
  String backupPlatform(String platform);

  /// No description provided for @backupRestoreBackupMenu.
  ///
  /// In en, this message translates to:
  /// **'Restore backup…'**
  String get backupRestoreBackupMenu;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore backup?'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get backupRestoreFailed;

  /// No description provided for @backupRestoreFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from file…'**
  String get backupRestoreFromFile;

  /// No description provided for @backupRestoreReplaceWarning.
  ///
  /// In en, this message translates to:
  /// **'This replaces the settings and instances currently on this device.'**
  String get backupRestoreReplaceWarning;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored'**
  String get backupRestored;

  /// No description provided for @backupSignInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get backupSignInWithGoogle;

  /// No description provided for @backupSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get backupSignOut;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupTitle;

  /// No description provided for @calendarAnyInstance.
  ///
  /// In en, this message translates to:
  /// **'Any instance'**
  String get calendarAnyInstance;

  /// No description provided for @calendarDataLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Calendar data could not be loaded.'**
  String get calendarDataLoadFailed;

  /// No description provided for @calendarFilterByInstance.
  ///
  /// In en, this message translates to:
  /// **'Filter by instance'**
  String get calendarFilterByInstance;

  /// No description provided for @calendarFilterByMediaType.
  ///
  /// In en, this message translates to:
  /// **'Filter by media type'**
  String get calendarFilterByMediaType;

  /// No description provided for @calendarHideSpecials.
  ///
  /// In en, this message translates to:
  /// **'Hide specials'**
  String get calendarHideSpecials;

  /// No description provided for @calendarInstanceAny.
  ///
  /// In en, this message translates to:
  /// **'Instance: Any'**
  String get calendarInstanceAny;

  /// No description provided for @calendarInstanceNamed.
  ///
  /// In en, this message translates to:
  /// **'Instance: {name}'**
  String calendarInstanceNamed(String name);

  /// No description provided for @calendarLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get calendarLoadMore;

  /// No description provided for @calendarLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading calendar...'**
  String get calendarLoading;

  /// No description provided for @calendarNoMatchingEvents.
  ///
  /// In en, this message translates to:
  /// **'No matching events'**
  String get calendarNoMatchingEvents;

  /// No description provided for @calendarNoMatchingEventsHint.
  ///
  /// In en, this message translates to:
  /// **'Adjust the calendar filters to see more events.'**
  String get calendarNoMatchingEventsHint;

  /// No description provided for @calendarNoUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get calendarNoUpcomingEvents;

  /// No description provided for @calendarNoUpcomingEventsHint.
  ///
  /// In en, this message translates to:
  /// **'Check back later or add content to your libraries.'**
  String get calendarNoUpcomingEventsHint;

  /// No description provided for @calendarOpenItemFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open item: {error}'**
  String calendarOpenItemFailed(String error);

  /// No description provided for @calendarPremieres.
  ///
  /// In en, this message translates to:
  /// **'Premieres'**
  String get calendarPremieres;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get calendarTomorrow;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @commonAutomaticSearch.
  ///
  /// In en, this message translates to:
  /// **'Automatic Search'**
  String get commonAutomaticSearch;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get commonClearFilters;

  /// No description provided for @commonClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get commonClient;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonDeleteFiles.
  ///
  /// In en, this message translates to:
  /// **'Delete files'**
  String get commonDeleteFiles;

  /// No description provided for @commonDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonErrorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commonErrorWithDetails(String error);

  /// No description provided for @commonFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get commonFilter;

  /// No description provided for @commonImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get commonImport;

  /// No description provided for @commonIndexer.
  ///
  /// In en, this message translates to:
  /// **'Indexer'**
  String get commonIndexer;

  /// No description provided for @commonInteractiveSearch.
  ///
  /// In en, this message translates to:
  /// **'Interactive Search'**
  String get commonInteractiveSearch;

  /// No description provided for @commonLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get commonLanguage;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonMonitor.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get commonMonitor;

  /// No description provided for @commonMonitored.
  ///
  /// In en, this message translates to:
  /// **'Monitored'**
  String get commonMonitored;

  /// No description provided for @commonMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get commonMovies;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonOpenExternally.
  ///
  /// In en, this message translates to:
  /// **'Open externally'**
  String get commonOpenExternally;

  /// No description provided for @commonOpenInLibrary.
  ///
  /// In en, this message translates to:
  /// **'Open in library'**
  String get commonOpenInLibrary;

  /// No description provided for @commonProtocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get commonProtocol;

  /// No description provided for @commonPurge.
  ///
  /// In en, this message translates to:
  /// **'Purge'**
  String get commonPurge;

  /// No description provided for @commonQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get commonQuality;

  /// No description provided for @commonQualityProfile.
  ///
  /// In en, this message translates to:
  /// **'Quality Profile'**
  String get commonQualityProfile;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get commonRestore;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonRootFolder.
  ///
  /// In en, this message translates to:
  /// **'Root Folder'**
  String get commonRootFolder;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonSearchStarted.
  ///
  /// In en, this message translates to:
  /// **'Search started'**
  String get commonSearchStarted;

  /// No description provided for @commonSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get commonSelectAll;

  /// No description provided for @commonSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get commonSeries;

  /// No description provided for @commonSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get commonSize;

  /// No description provided for @commonSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get commonSort;

  /// No description provided for @commonSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get commonSortBy;

  /// No description provided for @commonStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get commonStatus;

  /// No description provided for @commonTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get commonTags;

  /// No description provided for @commonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// No description provided for @commonUnmonitor.
  ///
  /// In en, this message translates to:
  /// **'Unmonitor'**
  String get commonUnmonitor;

  /// No description provided for @commonUnmonitored.
  ///
  /// In en, this message translates to:
  /// **'Unmonitored'**
  String get commonUnmonitored;

  /// No description provided for @commonWatchInJellyfin.
  ///
  /// In en, this message translates to:
  /// **'Watch in Jellyfin'**
  String get commonWatchInJellyfin;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @coreGoogleSignInAccountLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: the account could not be loaded (status {status}).'**
  String coreGoogleSignInAccountLoadFailed(String status);

  /// No description provided for @coreGoogleSignInBrowserFailed.
  ///
  /// In en, this message translates to:
  /// **'The sign-in browser could not be opened. Please try again.'**
  String get coreGoogleSignInBrowserFailed;

  /// No description provided for @coreGoogleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled before it finished.'**
  String get coreGoogleSignInCancelled;

  /// No description provided for @coreGoogleSignInConsentDenied.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled: consent was denied.'**
  String get coreGoogleSignInConsentDenied;

  /// No description provided for @coreGoogleSignInIncompleteToken.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: the token response was incomplete.'**
  String get coreGoogleSignInIncompleteToken;

  /// No description provided for @coreGoogleSignInNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: network or server error (status {status}).'**
  String coreGoogleSignInNetworkError(String status);

  /// No description provided for @coreGoogleSignInNoCode.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: no authorization code was returned.'**
  String get coreGoogleSignInNoCode;

  /// No description provided for @coreGoogleSignInNoEmail.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: the account has no e-mail.'**
  String get coreGoogleSignInNoEmail;

  /// No description provided for @coreGoogleSignInProviderError.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: {reason}'**
  String coreGoogleSignInProviderError(String reason);

  /// No description provided for @coreGoogleSignInRedirectUnverified.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: the redirect could not be verified.'**
  String get coreGoogleSignInRedirectUnverified;

  /// No description provided for @coreGoogleSignInServerStatus.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: the server returned status {status}.'**
  String coreGoogleSignInServerStatus(String status);

  /// No description provided for @coreGoogleSignInStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'unavailable'**
  String get coreGoogleSignInStatusUnavailable;

  /// No description provided for @coreGoogleSignInTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in timed out. Please try again.'**
  String get coreGoogleSignInTimedOut;

  /// No description provided for @coreGoogleSignInUnavailableOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not available on the web.'**
  String get coreGoogleSignInUnavailableOnWeb;

  /// No description provided for @corePurgeNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Purged torrent'**
  String get corePurgeNotificationTitle;

  /// No description provided for @corePurgeNotificationTitleSeason.
  ///
  /// In en, this message translates to:
  /// **'Purged torrent (season {season})'**
  String corePurgeNotificationTitleSeason(int season);

  /// No description provided for @corePurgeSummaryMediaFiles.
  ///
  /// In en, this message translates to:
  /// **'Media files: {count}'**
  String corePurgeSummaryMediaFiles(int count);

  /// No description provided for @corePurgeSummaryQbittorrentSkipped.
  ///
  /// In en, this message translates to:
  /// **'qBittorrent skipped — configure a qBittorrent instance.'**
  String get corePurgeSummaryQbittorrentSkipped;

  /// No description provided for @corePurgeSummaryQueueItems.
  ///
  /// In en, this message translates to:
  /// **'Queue items: {count}'**
  String corePurgeSummaryQueueItems(int count);

  /// No description provided for @corePurgeSummaryTorrents.
  ///
  /// In en, this message translates to:
  /// **'Torrents: {count}'**
  String corePurgeSummaryTorrents(int count);

  /// No description provided for @corePurgeSummaryTorrentsWithCrossSeed.
  ///
  /// In en, this message translates to:
  /// **'Torrents: {count} (+{crossSeed} cross-seed)'**
  String corePurgeSummaryTorrentsWithCrossSeed(int count, int crossSeed);

  /// No description provided for @coreUpdateArchiveMissingFiles.
  ///
  /// In en, this message translates to:
  /// **'The update archive is missing required application files.'**
  String get coreUpdateArchiveMissingFiles;

  /// No description provided for @coreUpdateArchiveTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The update archive exceeds its extraction limits.'**
  String get coreUpdateArchiveTooLarge;

  /// No description provided for @coreUpdateArchiveUnsafeLink.
  ///
  /// In en, this message translates to:
  /// **'The update archive contains an unsafe symbolic link.'**
  String get coreUpdateArchiveUnsafeLink;

  /// No description provided for @coreUpdateArchiveUnsafePath.
  ///
  /// In en, this message translates to:
  /// **'The update archive contains an unsafe path.'**
  String get coreUpdateArchiveUnsafePath;

  /// No description provided for @coreUpdateArchiveWritesThroughLink.
  ///
  /// In en, this message translates to:
  /// **'The update archive writes through a symbolic link.'**
  String get coreUpdateArchiveWritesThroughLink;

  /// No description provided for @coreUpdateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates. Please try again.'**
  String get coreUpdateCheckFailed;

  /// No description provided for @coreUpdateInstallerNotStarted.
  ///
  /// In en, this message translates to:
  /// **'The update installer could not start. The app has not been changed.'**
  String get coreUpdateInstallerNotStarted;

  /// No description provided for @coreUpdateLinuxRequiresAppImage.
  ///
  /// In en, this message translates to:
  /// **'Automatic Linux updates require the AppImage. Download and run the AppImage release first.'**
  String get coreUpdateLinuxRequiresAppImage;

  /// No description provided for @coreUpdateMacBundleRequired.
  ///
  /// In en, this message translates to:
  /// **'Run the installed Arrmate.app bundle to update it.'**
  String get coreUpdateMacBundleRequired;

  /// No description provided for @coreUpdateNotAppImage.
  ///
  /// In en, this message translates to:
  /// **'The update is not an x64 AppImage.'**
  String get coreUpdateNotAppImage;

  /// No description provided for @coreUpdateOtaFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {status}'**
  String coreUpdateOtaFailed(String status);

  /// No description provided for @coreUpdatePrepareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare the update package ({tool}).'**
  String coreUpdatePrepareFailed(String tool);

  /// No description provided for @coreUpdateReadOnlyFolder.
  ///
  /// In en, this message translates to:
  /// **'The application folder is read-only. Move Arrmate to a folder writable by your user and try again.'**
  String get coreUpdateReadOnlyFolder;

  /// No description provided for @coreUpdateUnverifiedPackage.
  ///
  /// In en, this message translates to:
  /// **'The release does not contain a verified package for this platform.'**
  String get coreUpdateUnverifiedPackage;

  /// No description provided for @coreUpdateVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'The update failed its size or SHA-256 verification.'**
  String get coreUpdateVerificationFailed;

  /// No description provided for @coreUpdateVersionMismatch.
  ///
  /// In en, this message translates to:
  /// **'The downloaded application version does not match the release.'**
  String get coreUpdateVersionMismatch;

  /// No description provided for @coreUpdateWindowsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Run Arrmate from the complete Windows release directory to update it.'**
  String get coreUpdateWindowsIncomplete;

  /// No description provided for @diagnosticsCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed · {error}'**
  String diagnosticsCheckFailed(String error);

  /// No description provided for @diagnosticsCheckOk.
  ///
  /// In en, this message translates to:
  /// **'OK · {ms}ms'**
  String diagnosticsCheckOk(int ms);

  /// No description provided for @diagnosticsCheckOkWithVersion.
  ///
  /// In en, this message translates to:
  /// **'OK · {ms}ms · v{version}'**
  String diagnosticsCheckOkWithVersion(int ms, String version);

  /// No description provided for @diagnosticsChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking configured endpoints...'**
  String get diagnosticsChecking;

  /// No description provided for @diagnosticsEndpointActive.
  ///
  /// In en, this message translates to:
  /// **'Active endpoint'**
  String get diagnosticsEndpointActive;

  /// No description provided for @diagnosticsEndpointAlternative.
  ///
  /// In en, this message translates to:
  /// **'Alternative endpoint'**
  String get diagnosticsEndpointAlternative;

  /// No description provided for @diagnosticsEndpointAlternativeActive.
  ///
  /// In en, this message translates to:
  /// **'Alternative endpoint · Active'**
  String get diagnosticsEndpointAlternativeActive;

  /// No description provided for @diagnosticsEndpointConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Endpoint connectivity'**
  String get diagnosticsEndpointConnectivity;

  /// No description provided for @diagnosticsEndpointPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary endpoint'**
  String get diagnosticsEndpointPrimary;

  /// No description provided for @diagnosticsEndpointPrimaryActive.
  ///
  /// In en, this message translates to:
  /// **'Primary endpoint · Active'**
  String get diagnosticsEndpointPrimaryActive;

  /// No description provided for @diagnosticsEndpointsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Endpoints available'**
  String get diagnosticsEndpointsAvailable;

  /// No description provided for @diagnosticsEndpointsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Endpoints unavailable'**
  String get diagnosticsEndpointsUnavailable;

  /// No description provided for @diagnosticsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export report: {error}'**
  String diagnosticsExportFailed(String error);

  /// No description provided for @diagnosticsExportReport.
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get diagnosticsExportReport;

  /// No description provided for @diagnosticsGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated {date}'**
  String diagnosticsGenerated(String date);

  /// No description provided for @diagnosticsInterfaces.
  ///
  /// In en, this message translates to:
  /// **'Interfaces: {interfaces}'**
  String diagnosticsInterfaces(String interfaces);

  /// No description provided for @diagnosticsNetworkAvailable.
  ///
  /// In en, this message translates to:
  /// **'Network available'**
  String get diagnosticsNetworkAvailable;

  /// No description provided for @diagnosticsNoInstances.
  ///
  /// In en, this message translates to:
  /// **'No Radarr, Sonarr, or qBittorrent instances are configured.'**
  String get diagnosticsNoInstances;

  /// No description provided for @diagnosticsNoNetworkInterface.
  ///
  /// In en, this message translates to:
  /// **'No network interface'**
  String get diagnosticsNoNetworkInterface;

  /// No description provided for @diagnosticsNoRecentRequests.
  ///
  /// In en, this message translates to:
  /// **'No recent requests recorded.'**
  String get diagnosticsNoRecentRequests;

  /// No description provided for @diagnosticsPurposeBody.
  ///
  /// In en, this message translates to:
  /// **'Tests every configured endpoint for reachability and latency, shows recent request traces, and exports a sanitized report. Health shows alerts reported by Radarr and Sonarr.'**
  String get diagnosticsPurposeBody;

  /// No description provided for @diagnosticsPurposeTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection troubleshooting'**
  String get diagnosticsPurposeTitle;

  /// No description provided for @diagnosticsRecentRequests.
  ///
  /// In en, this message translates to:
  /// **'Recent request traces'**
  String get diagnosticsRecentRequests;

  /// No description provided for @diagnosticsRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing endpoint checks...'**
  String get diagnosticsRefreshing;

  /// No description provided for @diagnosticsRunAgain.
  ///
  /// In en, this message translates to:
  /// **'Run connection checks again'**
  String get diagnosticsRunAgain;

  /// No description provided for @diagnosticsRunFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to run connection diagnostics: {error}'**
  String diagnosticsRunFailed(String error);

  /// No description provided for @diagnosticsSomeEndpointsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Some endpoints unavailable'**
  String get diagnosticsSomeEndpointsUnavailable;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsUnknownError.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get diagnosticsUnknownError;

  /// No description provided for @diagnosticsUnknownStatus.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get diagnosticsUnknownStatus;

  /// No description provided for @discoveryConfigureAddition.
  ///
  /// In en, this message translates to:
  /// **'Configure Addition'**
  String get discoveryConfigureAddition;

  /// No description provided for @discoveryHideAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Hide already added'**
  String get discoveryHideAlreadyAdded;

  /// No description provided for @discoveryLoadFoldersFailed.
  ///
  /// In en, this message translates to:
  /// **'Error loading folders: {error}'**
  String discoveryLoadFoldersFailed(String error);

  /// No description provided for @discoveryLoadProfilesFailed.
  ///
  /// In en, this message translates to:
  /// **'Error loading profiles: {error}'**
  String discoveryLoadProfilesFailed(String error);

  /// No description provided for @discoveryNoOverview.
  ///
  /// In en, this message translates to:
  /// **'No overview available.'**
  String get discoveryNoOverview;

  /// No description provided for @discoveryNoRating.
  ///
  /// In en, this message translates to:
  /// **'No rating'**
  String get discoveryNoRating;

  /// No description provided for @discoveryNoResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get discoveryNoResultsFound;

  /// No description provided for @discoveryRootFolderFreeSpace.
  ///
  /// In en, this message translates to:
  /// **'{path} ({free} GB Free)'**
  String discoveryRootFolderFreeSpace(String path, String free);

  /// No description provided for @discoveryRuntimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String discoveryRuntimeMinutes(int minutes);

  /// No description provided for @discoverySearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search by title, provider ID, or URL'**
  String get discoverySearchPrompt;

  /// No description provided for @errorConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Please check your network.'**
  String get errorConnectionFailed;

  /// No description provided for @errorInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL: {url}'**
  String errorInvalidUrl(String url);

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Resource not found.'**
  String get errorNotFound;

  /// No description provided for @errorRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get errorRequestCancelled;

  /// No description provided for @errorRequestTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get errorRequestTimedOut;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized. Please check your API key.'**
  String get errorUnauthorized;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get errorUnknown;

  /// No description provided for @errorValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'Validation failed.'**
  String get errorValidationFailed;

  /// No description provided for @formatDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String formatDaysAgo(int count);

  /// No description provided for @formatHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String formatHoursAgo(int count);

  /// No description provided for @formatJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get formatJustNow;

  /// No description provided for @formatLastOnline.
  ///
  /// In en, this message translates to:
  /// **'Last online {time}'**
  String formatLastOnline(String time);

  /// No description provided for @formatMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String formatMinutesAgo(int count);

  /// No description provided for @formatMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String formatMonthsAgo(int count);

  /// No description provided for @formatSeason.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String formatSeason(int number);

  /// No description provided for @formatSeasonEpisode.
  ///
  /// In en, this message translates to:
  /// **'Season {season}, Episode {episode}'**
  String formatSeasonEpisode(int season, int episode);

  /// No description provided for @formatTitleWithSeason.
  ///
  /// In en, this message translates to:
  /// **'{title} (Season {season})'**
  String formatTitleWithSeason(String title, int season);

  /// No description provided for @formatWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String formatWeeksAgo(int count);

  /// No description provided for @formatYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}y ago'**
  String formatYearsAgo(int count);

  /// No description provided for @formatYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get formatYesterday;

  /// No description provided for @healthCheckCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'{service} check could not start'**
  String healthCheckCouldNotStart(String service);

  /// No description provided for @healthConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'{service} connection failed'**
  String healthConnectionFailed(String service);

  /// No description provided for @healthConnectionIssues.
  ///
  /// In en, this message translates to:
  /// **'Connection issues'**
  String get healthConnectionIssues;

  /// No description provided for @healthLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load health status'**
  String get healthLoadFailed;

  /// No description provided for @healthLoadFailureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load server health. Check the connection and try again.'**
  String get healthLoadFailureSubtitle;

  /// No description provided for @healthNoInstancesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a Radarr or Sonarr instance to view server health.'**
  String get healthNoInstancesSubtitle;

  /// No description provided for @healthNoIssuesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connected servers reported no health warnings.'**
  String get healthNoIssuesSubtitle;

  /// No description provided for @healthNoIssuesTitle.
  ///
  /// In en, this message translates to:
  /// **'No server issues found'**
  String get healthNoIssuesTitle;

  /// No description provided for @healthRunCheck.
  ///
  /// In en, this message translates to:
  /// **'Run health check'**
  String get healthRunCheck;

  /// No description provided for @healthRunFailureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The latest available server status is shown below.'**
  String get healthRunFailureSubtitle;

  /// No description provided for @healthServerWarnings.
  ///
  /// In en, this message translates to:
  /// **'Server warnings'**
  String get healthServerWarnings;

  /// No description provided for @healthTitle.
  ///
  /// In en, this message translates to:
  /// **'System Health'**
  String get healthTitle;

  /// No description provided for @healthWiki.
  ///
  /// In en, this message translates to:
  /// **'Wiki: {url}'**
  String healthWiki(String url);

  /// No description provided for @historyAllEvents.
  ///
  /// In en, this message translates to:
  /// **'All events'**
  String get historyAllEvents;

  /// No description provided for @historyAllInstances.
  ///
  /// In en, this message translates to:
  /// **'All instances'**
  String get historyAllInstances;

  /// No description provided for @historyDetailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get historyDetailDate;

  /// No description provided for @historyDetailScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get historyDetailScore;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history events'**
  String get historyEmpty;

  /// No description provided for @historyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'History data could not be loaded.'**
  String get historyLoadFailed;

  /// No description provided for @historyLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get historyLoadMore;

  /// No description provided for @instanceAddBasicAuth.
  ///
  /// In en, this message translates to:
  /// **'Add Basic Auth'**
  String get instanceAddBasicAuth;

  /// No description provided for @instanceAddHeader.
  ///
  /// In en, this message translates to:
  /// **'Add Header'**
  String get instanceAddHeader;

  /// No description provided for @instanceAdvancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get instanceAdvancedSettings;

  /// No description provided for @instanceAdvancedSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Headers & Authentication'**
  String get instanceAdvancedSettingsSubtitle;

  /// No description provided for @instanceAlternativeUrl.
  ///
  /// In en, this message translates to:
  /// **'Alternative URL'**
  String get instanceAlternativeUrl;

  /// No description provided for @instanceAlternativeUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional URL used outside your local network'**
  String get instanceAlternativeUrlHelper;

  /// No description provided for @instanceAlternativeUrlSameAsPrimary.
  ///
  /// In en, this message translates to:
  /// **'Must differ from the primary URL'**
  String get instanceAlternativeUrlSameAsPrimary;

  /// No description provided for @instanceApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get instanceApiKeyLabel;

  /// No description provided for @instanceApiKeyOrBasicAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Provide an API key or add Basic Auth below'**
  String get instanceApiKeyOrBasicAuthRequired;

  /// No description provided for @instanceApiKeySessionExpiredValidation.
  ///
  /// In en, this message translates to:
  /// **'Add Basic Auth below to sign in again, or enter an API key'**
  String get instanceApiKeySessionExpiredValidation;

  /// No description provided for @instanceAuthApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get instanceAuthApiKey;

  /// No description provided for @instanceAuthCustomHeader.
  ///
  /// In en, this message translates to:
  /// **'Custom Header'**
  String get instanceAuthCustomHeader;

  /// No description provided for @instanceAuthUsernamePassword.
  ///
  /// In en, this message translates to:
  /// **'Username & Password'**
  String get instanceAuthUsernamePassword;

  /// No description provided for @instanceBasicAuthBase64Note.
  ///
  /// In en, this message translates to:
  /// **'Credentials will be encoded to Base64.'**
  String get instanceBasicAuthBase64Note;

  /// No description provided for @instanceBasicAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Authentication'**
  String get instanceBasicAuthTitle;

  /// No description provided for @instanceDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String instanceDeleteFailed(String error);

  /// No description provided for @instanceDeleteJellyfinWarning.
  ///
  /// In en, this message translates to:
  /// **'Arrmate will also remove its Jellyfin connection from Radarr/Sonarr, revoke the Arrmate API key it created and sign out of Jellyfin. This action cannot be undone.'**
  String get instanceDeleteJellyfinWarning;

  /// No description provided for @instanceDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Instance?'**
  String get instanceDeleteTitle;

  /// No description provided for @instanceDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get instanceDeleteWarning;

  /// No description provided for @instanceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Instance'**
  String get instanceEditTitle;

  /// No description provided for @instanceErrorHttpStatus.
  ///
  /// In en, this message translates to:
  /// **'The server answered with HTTP {status}.'**
  String instanceErrorHttpStatus(String status);

  /// No description provided for @instanceErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to answer. Try again or enable Slow Instance Mode.'**
  String get instanceErrorTimeout;

  /// No description provided for @instanceErrorUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable. Check the URL and your network.'**
  String get instanceErrorUnreachable;

  /// No description provided for @instanceGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get instanceGoBack;

  /// No description provided for @instanceHeaderName.
  ///
  /// In en, this message translates to:
  /// **'Header Name'**
  String get instanceHeaderName;

  /// No description provided for @instanceHeaderValue.
  ///
  /// In en, this message translates to:
  /// **'Header Value'**
  String get instanceHeaderValue;

  /// No description provided for @instanceHideApiKey.
  ///
  /// In en, this message translates to:
  /// **'Hide API key'**
  String get instanceHideApiKey;

  /// No description provided for @instanceJellyfinFallbackUser.
  ///
  /// In en, this message translates to:
  /// **'a Jellyfin user'**
  String get instanceJellyfinFallbackUser;

  /// No description provided for @instanceJellyfinHelperDefault.
  ///
  /// In en, this message translates to:
  /// **'API key (Jellyfin dashboard → Advanced → API Keys). Leave empty if using \"Add Basic Auth\" below to sign in with a username and password.'**
  String get instanceJellyfinHelperDefault;

  /// No description provided for @instanceJellyfinHelperSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired — add Basic Auth below to sign in again, or enter an API key'**
  String get instanceJellyfinHelperSessionExpired;

  /// No description provided for @instanceJellyfinHelperSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {user}. Leave empty to keep the session, enter an API key to switch, or add Basic Auth below to sign in again.'**
  String instanceJellyfinHelperSignedIn(String user);

  /// No description provided for @instanceJellyfinSessionExpiredBanner.
  ///
  /// In en, this message translates to:
  /// **'Your Jellyfin session has expired. Add Basic Auth in Advanced Settings with your username and password to sign in again.'**
  String get instanceJellyfinSessionExpiredBanner;

  /// No description provided for @instanceLibraryAutoUpdateSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Library Auto-Update Setup'**
  String get instanceLibraryAutoUpdateSetupTitle;

  /// No description provided for @instanceNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home Server'**
  String get instanceNameHint;

  /// No description provided for @instanceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get instanceNameLabel;

  /// No description provided for @instanceNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The requested instance no longer exists or could not be loaded.'**
  String get instanceNotFoundMessage;

  /// No description provided for @instanceNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Instance not found'**
  String get instanceNotFoundTitle;

  /// No description provided for @instancePassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get instancePassword;

  /// No description provided for @instanceQbittorrentApiKeyHelper.
  ///
  /// In en, this message translates to:
  /// **'Bearer token (qBittorrent ≥ v5.2.0). Leave empty if using \"Add Basic Auth\" below for older versions.'**
  String get instanceQbittorrentApiKeyHelper;

  /// No description provided for @instanceRemovedCleanupFailed.
  ///
  /// In en, this message translates to:
  /// **'Instance removed, but some cleanup failed:\n{failures}'**
  String instanceRemovedCleanupFailed(String failures);

  /// No description provided for @instanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get instanceRequired;

  /// No description provided for @instanceSave.
  ///
  /// In en, this message translates to:
  /// **'Save Instance'**
  String get instanceSave;

  /// No description provided for @instanceSetUpLibraryAutoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Set Up Library Auto-Update'**
  String get instanceSetUpLibraryAutoUpdate;

  /// No description provided for @instanceSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Setup failed: {error}'**
  String instanceSetupFailed(String error);

  /// No description provided for @instanceShowApiKey.
  ///
  /// In en, this message translates to:
  /// **'Show API key'**
  String get instanceShowApiKey;

  /// No description provided for @instanceSlowMode.
  ///
  /// In en, this message translates to:
  /// **'Slow Instance Mode'**
  String get instanceSlowMode;

  /// No description provided for @instanceSlowModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Increase timeouts for slower connections'**
  String get instanceSlowModeSubtitle;

  /// No description provided for @instanceTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get instanceTestConnection;

  /// No description provided for @instanceTestSuccessArr.
  ///
  /// In en, this message translates to:
  /// **'Connection successful!\nVersion: {version}\nInstance: {name}\nTags: {count} available'**
  String instanceTestSuccessArr(String version, String name, int count);

  /// No description provided for @instanceTestSuccessQbittorrent.
  ///
  /// In en, this message translates to:
  /// **'Connection successful!\nAuth: {auth}\nTorrents: {count}'**
  String instanceTestSuccessQbittorrent(String auth, int count);

  /// No description provided for @instanceUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Include http:// or https:// and port'**
  String get instanceUrlHelper;

  /// No description provided for @instanceUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Must be a valid HTTP or HTTPS URL'**
  String get instanceUrlInvalid;

  /// No description provided for @instanceUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get instanceUrlLabel;

  /// No description provided for @instanceUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get instanceUsername;

  /// No description provided for @instanceValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'Validation failed: {error}'**
  String instanceValidationFailed(String error);

  /// No description provided for @jellyfinSetupApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Jellyfin API key required for automatic library updates: set an API key in the field, or sign in with an administrator account (Add Basic Auth)'**
  String get jellyfinSetupApiKeyRequired;

  /// No description provided for @jellyfinSetupNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No Jellyfin connection configured in Arrmate.'**
  String get jellyfinSetupNoConnection;

  /// No description provided for @jellyfinSetupNotArrInstance.
  ///
  /// In en, this message translates to:
  /// **'{name} is not a Radarr or Sonarr instance.'**
  String jellyfinSetupNotArrInstance(String name);

  /// No description provided for @jellyfinSetupRemoveConnectorFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the Jellyfin connection from {name}: {error}'**
  String jellyfinSetupRemoveConnectorFailed(String name, String error);

  /// No description provided for @jellyfinSetupRevokeKeyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not revoke the Arrmate API key in Jellyfin: {error}'**
  String jellyfinSetupRevokeKeyFailed(String error);

  /// No description provided for @jellyfinSetupSignOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out of Jellyfin: {error}'**
  String jellyfinSetupSignOutFailed(String error);

  /// No description provided for @labelAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get labelAll;

  /// No description provided for @labelAppearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get labelAppearanceDark;

  /// No description provided for @labelAppearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get labelAppearanceLight;

  /// No description provided for @labelAppearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get labelAppearanceSystem;

  /// No description provided for @labelCalendarAllMedia.
  ///
  /// In en, this message translates to:
  /// **'All media'**
  String get labelCalendarAllMedia;

  /// No description provided for @labelCalendarUnknownMovie.
  ///
  /// In en, this message translates to:
  /// **'Unknown Movie'**
  String get labelCalendarUnknownMovie;

  /// No description provided for @labelCalendarUnknownSeries.
  ///
  /// In en, this message translates to:
  /// **'Unknown Series'**
  String get labelCalendarUnknownSeries;

  /// No description provided for @labelColorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get labelColorAmber;

  /// No description provided for @labelColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get labelColorBlue;

  /// No description provided for @labelColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get labelColorGreen;

  /// No description provided for @labelColorIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get labelColorIndigo;

  /// No description provided for @labelColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get labelColorOrange;

  /// No description provided for @labelColorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get labelColorPink;

  /// No description provided for @labelColorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get labelColorPurple;

  /// No description provided for @labelColorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get labelColorRed;

  /// No description provided for @labelColorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get labelColorTeal;

  /// No description provided for @labelDangling.
  ///
  /// In en, this message translates to:
  /// **'Dangling'**
  String get labelDangling;

  /// No description provided for @labelDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get labelDeleted;

  /// No description provided for @labelDigitalRelease.
  ///
  /// In en, this message translates to:
  /// **'Digital Release'**
  String get labelDigitalRelease;

  /// No description provided for @labelDiscoverySortLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get labelDiscoverySortLatest;

  /// No description provided for @labelDiscoverySortRelevant.
  ///
  /// In en, this message translates to:
  /// **'Relevant'**
  String get labelDiscoverySortRelevant;

  /// No description provided for @labelDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get labelDownloaded;

  /// No description provided for @labelDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get labelDownloading;

  /// No description provided for @labelEpisode.
  ///
  /// In en, this message translates to:
  /// **'Episode'**
  String get labelEpisode;

  /// No description provided for @labelError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get labelError;

  /// No description provided for @labelFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get labelFailed;

  /// No description provided for @labelFilePriorityDoNotDownload.
  ///
  /// In en, this message translates to:
  /// **'Do Not Download'**
  String get labelFilePriorityDoNotDownload;

  /// No description provided for @labelFilePriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get labelFilePriorityHigh;

  /// No description provided for @labelFilePriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low Priority'**
  String get labelFilePriorityLow;

  /// No description provided for @labelFilePriorityMaximal.
  ///
  /// In en, this message translates to:
  /// **'Maximal Priority'**
  String get labelFilePriorityMaximal;

  /// No description provided for @labelFilePriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal Priority'**
  String get labelFilePriorityNormal;

  /// No description provided for @labelFilterAllMovies.
  ///
  /// In en, this message translates to:
  /// **'All Movies'**
  String get labelFilterAllMovies;

  /// No description provided for @labelFilterAllSeries.
  ///
  /// In en, this message translates to:
  /// **'All Series'**
  String get labelFilterAllSeries;

  /// No description provided for @labelGrabbed.
  ///
  /// In en, this message translates to:
  /// **'Grabbed'**
  String get labelGrabbed;

  /// No description provided for @labelHistoryDeletedGeneric.
  ///
  /// In en, this message translates to:
  /// **'File was deleted.'**
  String get labelHistoryDeletedGeneric;

  /// No description provided for @labelHistoryDeletedManual.
  ///
  /// In en, this message translates to:
  /// **'File was deleted manually or by a client through the API.'**
  String get labelHistoryDeletedManual;

  /// No description provided for @labelHistoryDeletedMissingFromDisk.
  ///
  /// In en, this message translates to:
  /// **'File was not found on disk so it was unlinked from the database.'**
  String get labelHistoryDeletedMissingFromDisk;

  /// No description provided for @labelHistoryDeletedUpgrade.
  ///
  /// In en, this message translates to:
  /// **'File was deleted to import an upgrade.'**
  String get labelHistoryDeletedUpgrade;

  /// No description provided for @labelHistoryDownloadFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'Download failed.'**
  String get labelHistoryDownloadFailedDescription;

  /// No description provided for @labelHistoryDownloadIgnoredDescription.
  ///
  /// In en, this message translates to:
  /// **'Download ignored.'**
  String get labelHistoryDownloadIgnoredDescription;

  /// No description provided for @labelHistoryEpisodeGrabbed.
  ///
  /// In en, this message translates to:
  /// **'Episode grabbed from {indexer} and sent to {client}.'**
  String labelHistoryEpisodeGrabbed(String indexer, String client);

  /// No description provided for @labelHistoryEpisodeImported.
  ///
  /// In en, this message translates to:
  /// **'Episode downloaded successfully and imported from {client}.'**
  String labelHistoryEpisodeImported(String client);

  /// No description provided for @labelHistoryEpisodeRenamed.
  ///
  /// In en, this message translates to:
  /// **'Episode file was renamed.'**
  String get labelHistoryEpisodeRenamed;

  /// No description provided for @labelHistoryFallbackClient.
  ///
  /// In en, this message translates to:
  /// **'download client'**
  String get labelHistoryFallbackClient;

  /// No description provided for @labelHistoryFallbackIndexer.
  ///
  /// In en, this message translates to:
  /// **'indexer'**
  String get labelHistoryFallbackIndexer;

  /// No description provided for @labelHistoryIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored'**
  String get labelHistoryIgnored;

  /// No description provided for @labelHistoryImported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get labelHistoryImported;

  /// No description provided for @labelHistoryMovieGrabbed.
  ///
  /// In en, this message translates to:
  /// **'Movie grabbed from {indexer} and sent to {client}.'**
  String labelHistoryMovieGrabbed(String indexer, String client);

  /// No description provided for @labelHistoryMovieImported.
  ///
  /// In en, this message translates to:
  /// **'Movie downloaded successfully and imported from {client}.'**
  String labelHistoryMovieImported(String client);

  /// No description provided for @labelHistoryMovieRenamed.
  ///
  /// In en, this message translates to:
  /// **'Movie file was renamed.'**
  String get labelHistoryMovieRenamed;

  /// No description provided for @labelHistoryRenamed.
  ///
  /// In en, this message translates to:
  /// **'Renamed'**
  String get labelHistoryRenamed;

  /// No description provided for @labelHistoryTitleDeleted.
  ///
  /// In en, this message translates to:
  /// **'File Deleted'**
  String get labelHistoryTitleDeleted;

  /// No description provided for @labelHistoryTitleFailed.
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get labelHistoryTitleFailed;

  /// No description provided for @labelHistoryTitleGrabbed.
  ///
  /// In en, this message translates to:
  /// **'Release Grabbed'**
  String get labelHistoryTitleGrabbed;

  /// No description provided for @labelHistoryTitleIgnored.
  ///
  /// In en, this message translates to:
  /// **'Download Ignored'**
  String get labelHistoryTitleIgnored;

  /// No description provided for @labelHistoryTitleImported.
  ///
  /// In en, this message translates to:
  /// **'Folder Imported'**
  String get labelHistoryTitleImported;

  /// No description provided for @labelHistoryTitleRenamed.
  ///
  /// In en, this message translates to:
  /// **'File Renamed'**
  String get labelHistoryTitleRenamed;

  /// No description provided for @labelHistoryTitleUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown Event'**
  String get labelHistoryTitleUnknown;

  /// No description provided for @labelHistoryUnknownEventDescription.
  ///
  /// In en, this message translates to:
  /// **'Unknown event.'**
  String get labelHistoryUnknownEventDescription;

  /// No description provided for @labelInCinemas.
  ///
  /// In en, this message translates to:
  /// **'In Cinemas'**
  String get labelInCinemas;

  /// No description provided for @labelMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get labelMissing;

  /// No description provided for @labelMovieMonitorMovieAndCollection.
  ///
  /// In en, this message translates to:
  /// **'Movie + Collection'**
  String get labelMovieMonitorMovieAndCollection;

  /// No description provided for @labelMovieMonitorMovieOnly.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get labelMovieMonitorMovieOnly;

  /// No description provided for @labelMovieStateUnreleased.
  ///
  /// In en, this message translates to:
  /// **'Unreleased'**
  String get labelMovieStateUnreleased;

  /// No description provided for @labelMovieStateUnwanted.
  ///
  /// In en, this message translates to:
  /// **'Unwanted'**
  String get labelMovieStateUnwanted;

  /// No description provided for @labelMovieStateWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get labelMovieStateWaiting;

  /// No description provided for @labelMovieStatusAnnounced.
  ///
  /// In en, this message translates to:
  /// **'Announced'**
  String get labelMovieStatusAnnounced;

  /// No description provided for @labelMovieStatusReleased.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get labelMovieStatusReleased;

  /// No description provided for @labelMovieStatusTba.
  ///
  /// In en, this message translates to:
  /// **'Unannounced'**
  String get labelMovieStatusTba;

  /// No description provided for @labelNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get labelNone;

  /// No description provided for @labelPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get labelPaused;

  /// No description provided for @labelPhysicalRelease.
  ///
  /// In en, this message translates to:
  /// **'Physical Release'**
  String get labelPhysicalRelease;

  /// No description provided for @labelQueueCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get labelQueueCompleted;

  /// No description provided for @labelQueuePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get labelQueuePending;

  /// No description provided for @labelQueueWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get labelQueueWarning;

  /// No description provided for @labelQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get labelQueued;

  /// No description provided for @labelSeeding.
  ///
  /// In en, this message translates to:
  /// **'Seeding'**
  String get labelSeeding;

  /// No description provided for @labelSeriesMonitorAll.
  ///
  /// In en, this message translates to:
  /// **'All Episodes'**
  String get labelSeriesMonitorAll;

  /// No description provided for @labelSeriesMonitorExisting.
  ///
  /// In en, this message translates to:
  /// **'Existing Episodes'**
  String get labelSeriesMonitorExisting;

  /// No description provided for @labelSeriesMonitorFirstSeason.
  ///
  /// In en, this message translates to:
  /// **'First Season'**
  String get labelSeriesMonitorFirstSeason;

  /// No description provided for @labelSeriesMonitorFuture.
  ///
  /// In en, this message translates to:
  /// **'Future Episodes'**
  String get labelSeriesMonitorFuture;

  /// No description provided for @labelSeriesMonitorLastSeason.
  ///
  /// In en, this message translates to:
  /// **'Last Season'**
  String get labelSeriesMonitorLastSeason;

  /// No description provided for @labelSeriesMonitorMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing Episodes'**
  String get labelSeriesMonitorMissing;

  /// No description provided for @labelSeriesMonitorPilot.
  ///
  /// In en, this message translates to:
  /// **'Pilot Episode'**
  String get labelSeriesMonitorPilot;

  /// No description provided for @labelSeriesMonitorRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent Episodes'**
  String get labelSeriesMonitorRecent;

  /// No description provided for @labelSeriesMonitorSpecials.
  ///
  /// In en, this message translates to:
  /// **'Monitor Specials'**
  String get labelSeriesMonitorSpecials;

  /// No description provided for @labelSeriesStatusContinuing.
  ///
  /// In en, this message translates to:
  /// **'Continuing'**
  String get labelSeriesStatusContinuing;

  /// No description provided for @labelSeriesStatusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get labelSeriesStatusEnded;

  /// No description provided for @labelSeriesStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get labelSeriesStatusUpcoming;

  /// No description provided for @labelSeriesTypeAnime.
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get labelSeriesTypeAnime;

  /// No description provided for @labelSeriesTypeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get labelSeriesTypeDaily;

  /// No description provided for @labelSeriesTypeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get labelSeriesTypeStandard;

  /// No description provided for @labelSeriesUnmonitorSpecials.
  ///
  /// In en, this message translates to:
  /// **'Unmonitor Specials'**
  String get labelSeriesUnmonitorSpecials;

  /// No description provided for @labelSortAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get labelSortAdded;

  /// No description provided for @labelSortNextAiring.
  ///
  /// In en, this message translates to:
  /// **'Next Airing'**
  String get labelSortNextAiring;

  /// No description provided for @labelSortPreviousAiring.
  ///
  /// In en, this message translates to:
  /// **'Previous Airing'**
  String get labelSortPreviousAiring;

  /// No description provided for @labelSortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get labelSortRating;

  /// No description provided for @labelSortRuntime.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get labelSortRuntime;

  /// No description provided for @labelSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get labelSortTitle;

  /// No description provided for @labelSortYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get labelSortYear;

  /// No description provided for @labelSpecials.
  ///
  /// In en, this message translates to:
  /// **'Specials'**
  String get labelSpecials;

  /// No description provided for @labelTabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get labelTabActivity;

  /// No description provided for @labelTabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get labelTabCalendar;

  /// No description provided for @labelTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get labelTabSettings;

  /// No description provided for @labelTba.
  ///
  /// In en, this message translates to:
  /// **'TBA'**
  String get labelTba;

  /// No description provided for @labelTorrentChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get labelTorrentChecking;

  /// No description provided for @labelTorrentLinkExternal.
  ///
  /// In en, this message translates to:
  /// **'Not in library'**
  String get labelTorrentLinkExternal;

  /// No description provided for @labelTorrentLinkExternalDescription.
  ///
  /// In en, this message translates to:
  /// **'This torrent was downloaded outside the media library.'**
  String get labelTorrentLinkExternalDescription;

  /// No description provided for @labelTorrentLinkFileMissing.
  ///
  /// In en, this message translates to:
  /// **'File removed'**
  String get labelTorrentLinkFileMissing;

  /// No description provided for @labelTorrentLinkFileMissingDescription.
  ///
  /// In en, this message translates to:
  /// **'The catalog item still exists, but its media file was deleted.'**
  String get labelTorrentLinkFileMissingDescription;

  /// No description provided for @labelTorrentLinkLinked.
  ///
  /// In en, this message translates to:
  /// **'In library'**
  String get labelTorrentLinkLinked;

  /// No description provided for @labelTorrentLinkLinkedDescription.
  ///
  /// In en, this message translates to:
  /// **'This torrent backs an item that is still in the media library.'**
  String get labelTorrentLinkLinkedDescription;

  /// No description provided for @labelTorrentLinkOrphan.
  ///
  /// In en, this message translates to:
  /// **'Orphan'**
  String get labelTorrentLinkOrphan;

  /// No description provided for @labelTorrentLinkOrphanDescription.
  ///
  /// In en, this message translates to:
  /// **'Radarr/Sonarr downloaded this torrent, but the catalog item is gone. Only the torrent is left.'**
  String get labelTorrentLinkOrphanDescription;

  /// No description provided for @labelTorrentLinkUnknownDescription.
  ///
  /// In en, this message translates to:
  /// **'The library relation could not be determined.'**
  String get labelTorrentLinkUnknownDescription;

  /// No description provided for @labelTorrentMissingFiles.
  ///
  /// In en, this message translates to:
  /// **'Missing Files'**
  String get labelTorrentMissingFiles;

  /// No description provided for @labelTorrentPausedDl.
  ///
  /// In en, this message translates to:
  /// **'Paused (DL)'**
  String get labelTorrentPausedDl;

  /// No description provided for @labelTorrentPausedUp.
  ///
  /// In en, this message translates to:
  /// **'Paused (UP)'**
  String get labelTorrentPausedUp;

  /// No description provided for @labelTorrentQueuedDl.
  ///
  /// In en, this message translates to:
  /// **'Queued (DL)'**
  String get labelTorrentQueuedDl;

  /// No description provided for @labelTorrentQueuedUp.
  ///
  /// In en, this message translates to:
  /// **'Queued (UP)'**
  String get labelTorrentQueuedUp;

  /// No description provided for @labelTorrentSortActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get labelTorrentSortActivity;

  /// No description provided for @labelTorrentSortAddedDate.
  ///
  /// In en, this message translates to:
  /// **'Added date'**
  String get labelTorrentSortAddedDate;

  /// No description provided for @labelTorrentSortDownloadSpeed.
  ///
  /// In en, this message translates to:
  /// **'Download speed'**
  String get labelTorrentSortDownloadSpeed;

  /// No description provided for @labelTorrentSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get labelTorrentSortName;

  /// No description provided for @labelTorrentSortProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get labelTorrentSortProgress;

  /// No description provided for @labelTorrentSortRatio.
  ///
  /// In en, this message translates to:
  /// **'Ratio'**
  String get labelTorrentSortRatio;

  /// No description provided for @labelTorrentSortSeedTime.
  ///
  /// In en, this message translates to:
  /// **'Seed time'**
  String get labelTorrentSortSeedTime;

  /// No description provided for @labelTorrentStalledDl.
  ///
  /// In en, this message translates to:
  /// **'Stalled (DL)'**
  String get labelTorrentStalledDl;

  /// No description provided for @labelTorrentStalledUp.
  ///
  /// In en, this message translates to:
  /// **'Stalled (UP)'**
  String get labelTorrentStalledUp;

  /// No description provided for @labelTrackerDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get labelTrackerDisabled;

  /// No description provided for @labelTrackerNotContacted.
  ///
  /// In en, this message translates to:
  /// **'Not contacted'**
  String get labelTrackerNotContacted;

  /// No description provided for @labelTrackerNotWorking.
  ///
  /// In en, this message translates to:
  /// **'Not working'**
  String get labelTrackerNotWorking;

  /// No description provided for @labelTrackerUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating'**
  String get labelTrackerUpdating;

  /// No description provided for @labelTrackerWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get labelTrackerWorking;

  /// No description provided for @labelUnnamedFile.
  ///
  /// In en, this message translates to:
  /// **'an unnamed file'**
  String get labelUnnamedFile;

  /// No description provided for @labelViewModeGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get labelViewModeGrid;

  /// No description provided for @labelViewModeList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get labelViewModeList;

  /// No description provided for @labelWanted.
  ///
  /// In en, this message translates to:
  /// **'Wanted'**
  String get labelWanted;

  /// No description provided for @languagePromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change it later in Settings.'**
  String get languagePromptSubtitle;

  /// No description provided for @languagePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languagePromptTitle;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// No description provided for @logsAllCopied.
  ///
  /// In en, this message translates to:
  /// **'All logs copied to clipboard'**
  String get logsAllCopied;

  /// No description provided for @logsAppLogsCleared.
  ///
  /// In en, this message translates to:
  /// **'App logs cleared'**
  String get logsAppLogsCleared;

  /// No description provided for @logsClearAppLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear App Logs'**
  String get logsClearAppLogs;

  /// No description provided for @logsCopyAllVisible.
  ///
  /// In en, this message translates to:
  /// **'Copy all visible logs'**
  String get logsCopyAllVisible;

  /// No description provided for @logsDetailException.
  ///
  /// In en, this message translates to:
  /// **'Exception/Error:'**
  String get logsDetailException;

  /// No description provided for @logsDetailLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get logsDetailLevel;

  /// No description provided for @logsDetailLogger.
  ///
  /// In en, this message translates to:
  /// **'Logger'**
  String get logsDetailLogger;

  /// No description provided for @logsDetailMessage.
  ///
  /// In en, this message translates to:
  /// **'Message:'**
  String get logsDetailMessage;

  /// No description provided for @logsDetailTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get logsDetailTime;

  /// No description provided for @logsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Detail'**
  String get logsDetailTitle;

  /// No description provided for @logsLevelDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get logsLevelDebug;

  /// No description provided for @logsLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get logsLevelInfo;

  /// No description provided for @logsLevelWarn.
  ///
  /// In en, this message translates to:
  /// **'Warn'**
  String get logsLevelWarn;

  /// No description provided for @logsLogCopied.
  ///
  /// In en, this message translates to:
  /// **'Log copied'**
  String get logsLogCopied;

  /// No description provided for @logsNoAppLogsMatchingFilter.
  ///
  /// In en, this message translates to:
  /// **'No app logs found matching filter'**
  String get logsNoAppLogsMatchingFilter;

  /// No description provided for @logsNoLogsMatchingFilter.
  ///
  /// In en, this message translates to:
  /// **'No logs found matching filter'**
  String get logsNoLogsMatchingFilter;

  /// No description provided for @logsSource.
  ///
  /// In en, this message translates to:
  /// **'Log source'**
  String get logsSource;

  /// No description provided for @logsTabApp.
  ///
  /// In en, this message translates to:
  /// **'App Logs'**
  String get logsTabApp;

  /// No description provided for @logsTabArr.
  ///
  /// In en, this message translates to:
  /// **'ARR Logs'**
  String get logsTabArr;

  /// No description provided for @logsTitle.
  ///
  /// In en, this message translates to:
  /// **'System Logs'**
  String get logsTitle;

  /// No description provided for @manualImportEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'There are no files available for manual import.'**
  String get manualImportEmptySubtitle;

  /// No description provided for @manualImportEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Importable Files'**
  String get manualImportEmptyTitle;

  /// No description provided for @manualImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import: {error}'**
  String manualImportFailed(String error);

  /// No description provided for @manualImportIssueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} with issues}}'**
  String manualImportIssueCount(int count);

  /// No description provided for @manualImportLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load importable files'**
  String get manualImportLoadFailed;

  /// No description provided for @manualImportLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading importable files...'**
  String get manualImportLoading;

  /// No description provided for @manualImportNoFilesSelected.
  ///
  /// In en, this message translates to:
  /// **'No files selected'**
  String get manualImportNoFilesSelected;

  /// No description provided for @manualImportSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} file(s) selected}}'**
  String manualImportSelectedCount(int count);

  /// No description provided for @manualImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} file(s) imported successfully}}'**
  String manualImportSuccess(int count);

  /// No description provided for @manualImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Import'**
  String get manualImportTitle;

  /// No description provided for @manualImportValidCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} valid}}'**
  String manualImportValidCount(int count);

  /// No description provided for @moviesAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Error adding movie: {error}'**
  String moviesAddFailed(String error);

  /// No description provided for @moviesAddMissingSelection.
  ///
  /// In en, this message translates to:
  /// **'Please select a movie, quality profile, and root folder'**
  String get moviesAddMissingSelection;

  /// No description provided for @moviesAddMovieButton.
  ///
  /// In en, this message translates to:
  /// **'Add movie'**
  String get moviesAddMovieButton;

  /// No description provided for @moviesAddMovieTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Movie'**
  String get moviesAddMovieTitle;

  /// No description provided for @moviesAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Movie added successfully'**
  String get moviesAddedSuccessfully;

  /// No description provided for @moviesAllFolders.
  ///
  /// In en, this message translates to:
  /// **'All folders'**
  String get moviesAllFolders;

  /// No description provided for @moviesAlsoDeleteFiles.
  ///
  /// In en, this message translates to:
  /// **'Also delete files from disk'**
  String get moviesAlsoDeleteFiles;

  /// No description provided for @moviesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String moviesDeleteFailed(String error);

  /// No description provided for @moviesDeleteFileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this file? This action cannot be undone.'**
  String get moviesDeleteFileConfirm;

  /// No description provided for @moviesDeleteFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get moviesDeleteFileTitle;

  /// No description provided for @moviesDeleteFilesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all files for \"{title}\"? This removes the movie file from disk; the movie stays in Radarr.'**
  String moviesDeleteFilesConfirm(String title);

  /// No description provided for @moviesDeleteFilesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete files: {error}'**
  String moviesDeleteFilesFailed(String error);

  /// No description provided for @moviesDeleteMovieConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String moviesDeleteMovieConfirm(String title);

  /// No description provided for @moviesDeleteMovieTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Movie'**
  String get moviesDeleteMovieTitle;

  /// No description provided for @moviesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Movie deleted'**
  String get moviesDeleted;

  /// No description provided for @moviesDeletedFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 file} other{Deleted {count} files}}'**
  String moviesDeletedFilesCount(int count);

  /// No description provided for @moviesDeletedWithFiles.
  ///
  /// In en, this message translates to:
  /// **'Movie and files deleted'**
  String get moviesDeletedWithFiles;

  /// No description provided for @moviesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Movie'**
  String get moviesEditTitle;

  /// No description provided for @moviesEmptyFilteredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try clearing or adjusting your search query or filters.'**
  String get moviesEmptyFilteredSubtitle;

  /// No description provided for @moviesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add movies to your Radarr library to see them here.'**
  String get moviesEmptySubtitle;

  /// No description provided for @moviesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No movies found'**
  String get moviesEmptyTitle;

  /// No description provided for @moviesFileDeleted.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get moviesFileDeleted;

  /// No description provided for @moviesFilesSection.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get moviesFilesSection;

  /// No description provided for @moviesHistorySection.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get moviesHistorySection;

  /// No description provided for @moviesInfoPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get moviesInfoPath;

  /// No description provided for @moviesInfoStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get moviesInfoStudio;

  /// No description provided for @moviesLoadFilesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load files'**
  String get moviesLoadFilesFailed;

  /// No description provided for @moviesLoadHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get moviesLoadHistoryFailed;

  /// No description provided for @moviesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading movies...'**
  String get moviesLoading;

  /// No description provided for @moviesLoadingDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading details...'**
  String get moviesLoadingDetails;

  /// No description provided for @moviesMinimumAvailability.
  ///
  /// In en, this message translates to:
  /// **'Minimum Availability'**
  String get moviesMinimumAvailability;

  /// No description provided for @moviesMoveFilesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to move the files to \"{path}\"?'**
  String moviesMoveFilesConfirm(String path);

  /// No description provided for @moviesMoveFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Move Files?'**
  String get moviesMoveFilesTitle;

  /// No description provided for @moviesNoFilesToDelete.
  ///
  /// In en, this message translates to:
  /// **'No files to delete'**
  String get moviesNoFilesToDelete;

  /// No description provided for @moviesNoHistoryEvents.
  ///
  /// In en, this message translates to:
  /// **'No history events'**
  String get moviesNoHistoryEvents;

  /// No description provided for @moviesNoMediaFiles.
  ///
  /// In en, this message translates to:
  /// **'No media files'**
  String get moviesNoMediaFiles;

  /// No description provided for @moviesOpenLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open link: {error}'**
  String moviesOpenLinkFailed(String error);

  /// No description provided for @moviesOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get moviesOverview;

  /// No description provided for @moviesPreventReAdd.
  ///
  /// In en, this message translates to:
  /// **'Prevent this movie from being re-added'**
  String get moviesPreventReAdd;

  /// No description provided for @moviesPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Movie Preview'**
  String get moviesPreviewTitle;

  /// No description provided for @moviesPurgeConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove \"{title}\" from Radarr, delete its media files, and delete all source torrents (plus cross-seed duplicates) from qBittorrent. Frees disk space used by hardlinked data.'**
  String moviesPurgeConfirm(String title);

  /// No description provided for @moviesPurgeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to purge: {error}'**
  String moviesPurgeFailed(String error);

  /// No description provided for @moviesPurgePreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to preview: {error}'**
  String moviesPurgePreviewFailed(String error);

  /// No description provided for @moviesPurgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Purge movie'**
  String get moviesPurgeTitle;

  /// No description provided for @moviesPurged.
  ///
  /// In en, this message translates to:
  /// **'Movie purged.'**
  String get moviesPurged;

  /// No description provided for @moviesRefreshAndScan.
  ///
  /// In en, this message translates to:
  /// **'Refresh & Scan'**
  String get moviesRefreshAndScan;

  /// No description provided for @moviesRefreshAndScanTriggered.
  ///
  /// In en, this message translates to:
  /// **'Refresh & Scan triggered'**
  String get moviesRefreshAndScanTriggered;

  /// No description provided for @moviesRootFolderHelper.
  ///
  /// In en, this message translates to:
  /// **'Changing this will move files if confirmed'**
  String get moviesRootFolderHelper;

  /// No description provided for @moviesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search movies...'**
  String get moviesSearchHint;

  /// No description provided for @moviesSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String moviesSelectedCount(int count);

  /// No description provided for @moviesSortAndFilter.
  ///
  /// In en, this message translates to:
  /// **'Sort & Filter'**
  String get moviesSortAndFilter;

  /// No description provided for @moviesSwitchToGrid.
  ///
  /// In en, this message translates to:
  /// **'Switch to Grid'**
  String get moviesSwitchToGrid;

  /// No description provided for @moviesSwitchToList.
  ///
  /// In en, this message translates to:
  /// **'Switch to List'**
  String get moviesSwitchToList;

  /// No description provided for @moviesTrailer.
  ///
  /// In en, this message translates to:
  /// **'Trailer'**
  String get moviesTrailer;

  /// No description provided for @moviesUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Error updating movie: {error}'**
  String moviesUpdateFailed(String error);

  /// No description provided for @moviesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Movie updated'**
  String get moviesUpdated;

  /// No description provided for @moviesViewPoster.
  ///
  /// In en, this message translates to:
  /// **'View {title} poster'**
  String moviesViewPoster(String title);

  /// No description provided for @notificationSettingsArrUpdate.
  ///
  /// In en, this message translates to:
  /// **'*arr Instance Update'**
  String get notificationSettingsArrUpdate;

  /// No description provided for @notificationSettingsArrUpdateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When Radarr/Sonarr server is updated'**
  String get notificationSettingsArrUpdateSubtitle;

  /// No description provided for @notificationSettingsAutoConfigure.
  ///
  /// In en, this message translates to:
  /// **'Auto-configure *arr instances'**
  String get notificationSettingsAutoConfigure;

  /// No description provided for @notificationSettingsAutoConfiguring.
  ///
  /// In en, this message translates to:
  /// **'Auto-configuring notifications...'**
  String get notificationSettingsAutoConfiguring;

  /// No description provided for @notificationSettingsConfiguredCount.
  ///
  /// In en, this message translates to:
  /// **'{success}/{total} instances configured.'**
  String notificationSettingsConfiguredCount(int success, int total);

  /// No description provided for @notificationSettingsConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to ntfy.sh'**
  String get notificationSettingsConnected;

  /// No description provided for @notificationSettingsCopyTopic.
  ///
  /// In en, this message translates to:
  /// **'Copy topic'**
  String get notificationSettingsCopyTopic;

  /// No description provided for @notificationSettingsDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get notificationSettingsDisconnected;

  /// No description provided for @notificationSettingsDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get notificationSettingsDownloads;

  /// No description provided for @notificationSettingsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get notificationSettingsEnable;

  /// No description provided for @notificationSettingsFailure.
  ///
  /// In en, this message translates to:
  /// **'Notify on Failure'**
  String get notificationSettingsFailure;

  /// No description provided for @notificationSettingsFailureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a download fails to import'**
  String get notificationSettingsFailureSubtitle;

  /// No description provided for @notificationSettingsFileDeleted.
  ///
  /// In en, this message translates to:
  /// **'File Deleted'**
  String get notificationSettingsFileDeleted;

  /// No description provided for @notificationSettingsFileDeletedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a media file is deleted'**
  String get notificationSettingsFileDeletedSubtitle;

  /// No description provided for @notificationSettingsGrab.
  ///
  /// In en, this message translates to:
  /// **'Notify on Grab'**
  String get notificationSettingsGrab;

  /// No description provided for @notificationSettingsGrabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a release is sent to download client'**
  String get notificationSettingsGrabSubtitle;

  /// No description provided for @notificationSettingsHealthIssues.
  ///
  /// In en, this message translates to:
  /// **'Health Issues'**
  String get notificationSettingsHealthIssues;

  /// No description provided for @notificationSettingsHealthIssuesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When system health issues are detected'**
  String get notificationSettingsHealthIssuesSubtitle;

  /// No description provided for @notificationSettingsHealthRestored.
  ///
  /// In en, this message translates to:
  /// **'Health Restored'**
  String get notificationSettingsHealthRestored;

  /// No description provided for @notificationSettingsHealthRestoredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a health issue is resolved'**
  String get notificationSettingsHealthRestoredSubtitle;

  /// No description provided for @notificationSettingsImport.
  ///
  /// In en, this message translates to:
  /// **'Notify on Import'**
  String get notificationSettingsImport;

  /// No description provided for @notificationSettingsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a file is successfully imported'**
  String get notificationSettingsImportSubtitle;

  /// No description provided for @notificationSettingsInAppBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications are received in real-time while the app is open. When you close the app, new notifications will be fetched the next time you open it.'**
  String get notificationSettingsInAppBody;

  /// No description provided for @notificationSettingsInAppTitle.
  ///
  /// In en, this message translates to:
  /// **'In-App Notifications'**
  String get notificationSettingsInAppTitle;

  /// No description provided for @notificationSettingsIncludeWarnings.
  ///
  /// In en, this message translates to:
  /// **'Include Warnings'**
  String get notificationSettingsIncludeWarnings;

  /// No description provided for @notificationSettingsIncludeWarningsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Also notify on health warnings'**
  String get notificationSettingsIncludeWarningsSubtitle;

  /// No description provided for @notificationSettingsManualInteraction.
  ///
  /// In en, this message translates to:
  /// **'Manual Interaction'**
  String get notificationSettingsManualInteraction;

  /// No description provided for @notificationSettingsManualInteractionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When manual intervention is required'**
  String get notificationSettingsManualInteractionSubtitle;

  /// No description provided for @notificationSettingsManualSetup.
  ///
  /// In en, this message translates to:
  /// **'OR MANUAL SETUP'**
  String get notificationSettingsManualSetup;

  /// No description provided for @notificationSettingsManualStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Go to Settings > Connect'**
  String get notificationSettingsManualStep1;

  /// No description provided for @notificationSettingsManualStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Add new connection > ntfy'**
  String get notificationSettingsManualStep2;

  /// No description provided for @notificationSettingsManualStep3.
  ///
  /// In en, this message translates to:
  /// **'3. Configure:'**
  String get notificationSettingsManualStep3;

  /// No description provided for @notificationSettingsMediaAdded.
  ///
  /// In en, this message translates to:
  /// **'Movie/Series Added'**
  String get notificationSettingsMediaAdded;

  /// No description provided for @notificationSettingsMediaAddedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a movie or series is added'**
  String get notificationSettingsMediaAddedSubtitle;

  /// No description provided for @notificationSettingsMediaDeleted.
  ///
  /// In en, this message translates to:
  /// **'Movie/Series Deleted'**
  String get notificationSettingsMediaDeleted;

  /// No description provided for @notificationSettingsMediaDeletedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a movie or series is deleted'**
  String get notificationSettingsMediaDeletedSubtitle;

  /// No description provided for @notificationSettingsMediaUpdates.
  ///
  /// In en, this message translates to:
  /// **'Media Updates'**
  String get notificationSettingsMediaUpdates;

  /// No description provided for @notificationSettingsNtfyDocs.
  ///
  /// In en, this message translates to:
  /// **'ntfy documentation'**
  String get notificationSettingsNtfyDocs;

  /// No description provided for @notificationSettingsServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get notificationSettingsServerUrl;

  /// No description provided for @notificationSettingsSetupInArr.
  ///
  /// In en, this message translates to:
  /// **'Setup in Radarr/Sonarr'**
  String get notificationSettingsSetupInArr;

  /// No description provided for @notificationSettingsSetupResults.
  ///
  /// In en, this message translates to:
  /// **'Setup Results'**
  String get notificationSettingsSetupResults;

  /// No description provided for @notificationSettingsSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to generate your unique topic'**
  String get notificationSettingsSetupSubtitle;

  /// No description provided for @notificationSettingsSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup Notifications'**
  String get notificationSettingsSetupTitle;

  /// No description provided for @notificationSettingsTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get notificationSettingsTopic;

  /// No description provided for @notificationSettingsTopicCopied.
  ///
  /// In en, this message translates to:
  /// **'Topic copied to clipboard'**
  String get notificationSettingsTopicCopied;

  /// No description provided for @notificationSettingsUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String notificationSettingsUnexpectedError(String error);

  /// No description provided for @notificationSettingsYourTopic.
  ///
  /// In en, this message translates to:
  /// **'Your Topic'**
  String get notificationSettingsYourTopic;

  /// No description provided for @notificationSetupConfigured.
  ///
  /// In en, this message translates to:
  /// **'{name} configured successfully.'**
  String notificationSetupConfigured(String name);

  /// No description provided for @notificationSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to configure {name}: {error}'**
  String notificationSetupFailed(String name, String error);

  /// No description provided for @notificationSetupNoTopic.
  ///
  /// In en, this message translates to:
  /// **'No Ntfy topic configured in Arrmate.'**
  String get notificationSetupNoTopic;

  /// No description provided for @notificationSetupUpdated.
  ///
  /// In en, this message translates to:
  /// **'{name} updated successfully.'**
  String notificationSetupUpdated(String name);

  /// No description provided for @notificationsAllCleared.
  ///
  /// In en, this message translates to:
  /// **'All notifications cleared'**
  String get notificationsAllCleared;

  /// No description provided for @notificationsAllMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get notificationsAllMarkedRead;

  /// No description provided for @notificationsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get notificationsClearAll;

  /// No description provided for @notificationsClearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will remove all notifications. This action cannot be undone.'**
  String get notificationsClearAllConfirm;

  /// No description provided for @notificationsClearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications?'**
  String get notificationsClearAllTitle;

  /// No description provided for @notificationsDismissed.
  ///
  /// In en, this message translates to:
  /// **'Notification dismissed'**
  String get notificationsDismissed;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you receive notifications from Radarr or Sonarr, they will appear here.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsNewBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get notificationsNewBadge;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @playbackLoadMovieFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the movie file'**
  String get playbackLoadMovieFileFailed;

  /// No description provided for @playbackNoEpisodeFile.
  ///
  /// In en, this message translates to:
  /// **'No playable file found for this episode'**
  String get playbackNoEpisodeFile;

  /// No description provided for @playbackNoJellyfin.
  ///
  /// In en, this message translates to:
  /// **'No Jellyfin server is configured'**
  String get playbackNoJellyfin;

  /// No description provided for @playbackNoMovieFile.
  ///
  /// In en, this message translates to:
  /// **'No playable file found for this movie'**
  String get playbackNoMovieFile;

  /// No description provided for @playbackNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find this media in Jellyfin'**
  String get playbackNotFound;

  /// No description provided for @playbackSearchingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Searching the Jellyfin library…'**
  String get playbackSearchingLibrary;

  /// No description provided for @playbackSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your Jellyfin session has expired. Sign in again.'**
  String get playbackSessionExpired;

  /// No description provided for @playbackSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get playbackSignIn;

  /// No description provided for @playbackStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start playback: {error}'**
  String playbackStartFailed(String error);

  /// No description provided for @playbackTrackLabel.
  ///
  /// In en, this message translates to:
  /// **'Track {index}'**
  String playbackTrackLabel(int index);

  /// No description provided for @playerAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get playerAudio;

  /// No description provided for @playerBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get playerBack;

  /// No description provided for @playerExternalOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open an external player'**
  String get playerExternalOpenFailed;

  /// No description provided for @playerExternalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Opening this media in an external player is not available for the current server configuration.'**
  String get playerExternalUnavailable;

  /// No description provided for @playerNoMediaRequested.
  ///
  /// In en, this message translates to:
  /// **'No media was requested for playback.'**
  String get playerNoMediaRequested;

  /// No description provided for @playerQualityDataSaver.
  ///
  /// In en, this message translates to:
  /// **'Data saver'**
  String get playerQualityDataSaver;

  /// No description provided for @playerQualityOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get playerQualityOriginal;

  /// No description provided for @playerQualityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Quality: {quality}'**
  String playerQualityTooltip(String quality);

  /// No description provided for @playerStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start playback. Check your connection and try again.'**
  String get playerStartFailed;

  /// No description provided for @playerSubtitleExternal.
  ///
  /// In en, this message translates to:
  /// **'External'**
  String get playerSubtitleExternal;

  /// No description provided for @playerSubtitlesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get playerSubtitlesDisabled;

  /// No description provided for @playerTitle.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get playerTitle;

  /// No description provided for @playerUnexpectedFailure.
  ///
  /// In en, this message translates to:
  /// **'Playback failed unexpectedly.'**
  String get playerUnexpectedFailure;

  /// No description provided for @playerUnsupportedOnWeb.
  ///
  /// In en, this message translates to:
  /// **'In-app playback is not supported on the web yet'**
  String get playerUnsupportedOnWeb;

  /// No description provided for @providerAssistantDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete model.'**
  String get providerAssistantDeleteFailed;

  /// No description provided for @providerAssistantDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download model: {error}'**
  String providerAssistantDownloadFailed(String error);

  /// No description provided for @providerAssistantEnableOnlineFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable online model.'**
  String get providerAssistantEnableOnlineFailed;

  /// No description provided for @providerAssistantGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate a response.'**
  String get providerAssistantGenerateFailed;

  /// No description provided for @providerAssistantImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import model.'**
  String get providerAssistantImportFailed;

  /// No description provided for @providerAssistantInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize assistant resources.'**
  String get providerAssistantInitFailed;

  /// No description provided for @providerAssistantLoadModelFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the selected model.'**
  String get providerAssistantLoadModelFailed;

  /// No description provided for @providerAssistantModelNotFound.
  ///
  /// In en, this message translates to:
  /// **'Model not found.'**
  String get providerAssistantModelNotFound;

  /// No description provided for @providerAssistantNoToolCalling.
  ///
  /// In en, this message translates to:
  /// **'This model does not support tool-calling. Use a Gemma model.'**
  String get providerAssistantNoToolCalling;

  /// No description provided for @providerAssistantRefreshModelsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh installed models.'**
  String get providerAssistantRefreshModelsFailed;

  /// No description provided for @providerAssistantSelectModelFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a model before chatting.'**
  String get providerAssistantSelectModelFirst;

  /// No description provided for @providerBackupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Backup completed.'**
  String get providerBackupCompleted;

  /// No description provided for @providerBackupCorrupt.
  ///
  /// In en, this message translates to:
  /// **'The backup file is corrupted or from an unsupported version.'**
  String get providerBackupCorrupt;

  /// No description provided for @providerBackupExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup export failed: {error}'**
  String providerBackupExportFailed(String error);

  /// No description provided for @providerBackupExported.
  ///
  /// In en, this message translates to:
  /// **'Backup exported to file.'**
  String get providerBackupExported;

  /// No description provided for @providerBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String providerBackupFailed(String error);

  /// No description provided for @providerBackupLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the backup: {error}'**
  String providerBackupLoadFailed(String error);

  /// No description provided for @providerBackupNotFound.
  ///
  /// In en, this message translates to:
  /// **'No backup found in your Google Drive.'**
  String get providerBackupNotFound;

  /// No description provided for @providerBackupReadFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the backup file: {error}'**
  String providerBackupReadFileFailed(String error);

  /// No description provided for @providerBackupRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String providerBackupRestoreFailed(String error);

  /// No description provided for @providerBackupRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored {settingsCount} settings and {instanceCount} instances.'**
  String providerBackupRestored(int settingsCount, int instanceCount);

  /// No description provided for @providerBackupSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Google session expired. Sign in again.'**
  String get providerBackupSessionExpired;

  /// No description provided for @providerBackupSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Check your connection and try again.'**
  String get providerBackupSignInFailed;

  /// No description provided for @providerBackupSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Google first.'**
  String get providerBackupSignedOut;

  /// No description provided for @providerBackupUnknownError.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get providerBackupUnknownError;

  /// No description provided for @providerInstanceTypeMismatch.
  ///
  /// In en, this message translates to:
  /// **'Expected {expected}, but connected to {actual}'**
  String providerInstanceTypeMismatch(String expected, String actual);

  /// No description provided for @purgeCrossSeedFoundContent.
  ///
  /// In en, this message translates to:
  /// **'A torrent with the same release name was found. Delete it too?'**
  String get purgeCrossSeedFoundContent;

  /// No description provided for @purgeCrossSeedFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Cross-seed torrent found'**
  String get purgeCrossSeedFoundTitle;

  /// No description provided for @purgeDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get purgeDeleteAll;

  /// No description provided for @purgeDeleteAnyway.
  ///
  /// In en, this message translates to:
  /// **'Delete anyway'**
  String get purgeDeleteAnyway;

  /// No description provided for @purgeDeleteTorrent.
  ///
  /// In en, this message translates to:
  /// **'Delete torrent'**
  String get purgeDeleteTorrent;

  /// No description provided for @purgeHash.
  ///
  /// In en, this message translates to:
  /// **'Hash'**
  String get purgeHash;

  /// No description provided for @purgeKeepSeeding.
  ///
  /// In en, this message translates to:
  /// **'Keep seeding'**
  String get purgeKeepSeeding;

  /// No description provided for @purgeKeepTorrent.
  ///
  /// In en, this message translates to:
  /// **'Keep torrent'**
  String get purgeKeepTorrent;

  /// No description provided for @purgeNoTags.
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get purgeNoTags;

  /// No description provided for @purgeSavePath.
  ///
  /// In en, this message translates to:
  /// **'Save path'**
  String get purgeSavePath;

  /// No description provided for @purgeSeededFor.
  ///
  /// In en, this message translates to:
  /// **'Seeded {duration}'**
  String purgeSeededFor(String duration);

  /// No description provided for @purgeTitleRemovedEitherWay.
  ///
  /// In en, this message translates to:
  /// **'The title will still be removed from the library and its files deleted either way.'**
  String get purgeTitleRemovedEitherWay;

  /// No description provided for @purgeTorrentBelowMinimum.
  ///
  /// In en, this message translates to:
  /// **'This torrent seeded for less than the minimum of {days, plural, =1{1 day} other{{days} days}}:'**
  String purgeTorrentBelowMinimum(int days);

  /// No description provided for @purgeTorrentStillSeeding.
  ///
  /// In en, this message translates to:
  /// **'Torrent still seeding'**
  String get purgeTorrentStillSeeding;

  /// No description provided for @purgeTorrentsBelowMinimum.
  ///
  /// In en, this message translates to:
  /// **'The following {count, plural, =1{1 torrent} other{{count} torrents}} seeded for less than the minimum of {days, plural, =1{1 day} other{{days} days}}:'**
  String purgeTorrentsBelowMinimum(int count, int days);

  /// No description provided for @purgeTorrentsStillSeeding.
  ///
  /// In en, this message translates to:
  /// **'Torrents still seeding'**
  String get purgeTorrentsStillSeeding;

  /// No description provided for @qualityProfilesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No profiles found or instance not connected'**
  String get qualityProfilesEmpty;

  /// No description provided for @qualityProfilesId.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String qualityProfilesId(String id);

  /// No description provided for @qualityProfilesRadarr.
  ///
  /// In en, this message translates to:
  /// **'Radarr Profiles'**
  String get qualityProfilesRadarr;

  /// No description provided for @qualityProfilesSonarr.
  ///
  /// In en, this message translates to:
  /// **'Sonarr Profiles'**
  String get qualityProfilesSonarr;

  /// No description provided for @qualityProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quality Profiles'**
  String get qualityProfilesTitle;

  /// No description provided for @queueAddToBlocklist.
  ///
  /// In en, this message translates to:
  /// **'Add to Blocklist'**
  String get queueAddToBlocklist;

  /// No description provided for @queueAddToBlocklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prevent this release from being grabbed again'**
  String get queueAddToBlocklistSubtitle;

  /// No description provided for @queueAnyClient.
  ///
  /// In en, this message translates to:
  /// **'Any client'**
  String get queueAnyClient;

  /// No description provided for @queueAnyInstance.
  ///
  /// In en, this message translates to:
  /// **'Any instance'**
  String get queueAnyInstance;

  /// No description provided for @queueAnyProtocol.
  ///
  /// In en, this message translates to:
  /// **'Any protocol'**
  String get queueAnyProtocol;

  /// No description provided for @queueAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get queueAscending;

  /// No description provided for @queueCustomFormatScore.
  ///
  /// In en, this message translates to:
  /// **'Custom Format Score'**
  String get queueCustomFormatScore;

  /// No description provided for @queueCustomFormats.
  ///
  /// In en, this message translates to:
  /// **'Custom Formats'**
  String get queueCustomFormats;

  /// No description provided for @queueDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get queueDescending;

  /// No description provided for @queueDetailPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get queueDetailPath;

  /// No description provided for @queueDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get queueDirection;

  /// No description provided for @queueEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No active downloads at the moment.'**
  String get queueEmptySubtitle;

  /// No description provided for @queueEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get queueEmptyTitle;

  /// No description provided for @queueEtaDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String queueEtaDays(int count);

  /// No description provided for @queueEtaDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get queueEtaDone;

  /// No description provided for @queueEtaHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String queueEtaHours(int count);

  /// No description provided for @queueEtaLessThanMinute.
  ///
  /// In en, this message translates to:
  /// **'<1m'**
  String get queueEtaLessThanMinute;

  /// No description provided for @queueEtaMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String queueEtaMinutes(int count);

  /// No description provided for @queueFilterSection.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get queueFilterSection;

  /// No description provided for @queueGroupedTasks.
  ///
  /// In en, this message translates to:
  /// **'Grouped Tasks'**
  String get queueGroupedTasks;

  /// No description provided for @queueInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get queueInformation;

  /// No description provided for @queueInstance.
  ///
  /// In en, this message translates to:
  /// **'Instance'**
  String get queueInstance;

  /// No description provided for @queueItemRemoved.
  ///
  /// In en, this message translates to:
  /// **'Item removed from queue'**
  String get queueItemRemoved;

  /// No description provided for @queueLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Queue data could not be loaded.'**
  String get queueLoadFailed;

  /// No description provided for @queueLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading queue...'**
  String get queueLoading;

  /// No description provided for @queueManualImportDescription.
  ///
  /// In en, this message translates to:
  /// **'This download requires manual intervention. Select which files to import.'**
  String get queueManualImportDescription;

  /// No description provided for @queueManualImportRequired.
  ///
  /// In en, this message translates to:
  /// **'Manual Import Required'**
  String get queueManualImportRequired;

  /// No description provided for @queueNoMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust or reset the queue filters.'**
  String get queueNoMatchSubtitle;

  /// No description provided for @queueNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching tasks'**
  String get queueNoMatchTitle;

  /// No description provided for @queueOpenDetails.
  ///
  /// In en, this message translates to:
  /// **'Open Details'**
  String get queueOpenDetails;

  /// No description provided for @queueOpenMovie.
  ///
  /// In en, this message translates to:
  /// **'Open Movie'**
  String get queueOpenMovie;

  /// No description provided for @queueOpenSeries.
  ///
  /// In en, this message translates to:
  /// **'Open Series'**
  String get queueOpenSeries;

  /// No description provided for @queueOptions.
  ///
  /// In en, this message translates to:
  /// **'Queue options'**
  String get queueOptions;

  /// No description provided for @queueProblemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{(1 problem)} other{({count} problems)}}'**
  String queueProblemCount(int count);

  /// No description provided for @queueProblemsOnly.
  ///
  /// In en, this message translates to:
  /// **'Problems only'**
  String get queueProblemsOnly;

  /// No description provided for @queueProblemsOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show tasks that need attention or manual import'**
  String get queueProblemsOnlySubtitle;

  /// No description provided for @queueRemovalOptions.
  ///
  /// In en, this message translates to:
  /// **'Removal Options'**
  String get queueRemovalOptions;

  /// No description provided for @queueRemoveFromClient.
  ///
  /// In en, this message translates to:
  /// **'Remove from Download Client'**
  String get queueRemoveFromClient;

  /// No description provided for @queueRemoveFromClientSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the download from the client'**
  String get queueRemoveFromClientSubtitle;

  /// No description provided for @queueRemoveFromQueue.
  ///
  /// In en, this message translates to:
  /// **'Remove from Queue'**
  String get queueRemoveFromQueue;

  /// No description provided for @queueSearchReplacement.
  ///
  /// In en, this message translates to:
  /// **'Search for Replacement'**
  String get queueSearchReplacement;

  /// No description provided for @queueSearchReplacementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically search for another release'**
  String get queueSearchReplacementSubtitle;

  /// No description provided for @queueSizeLeft.
  ///
  /// In en, this message translates to:
  /// **'{size} left'**
  String queueSizeLeft(String size);

  /// No description provided for @queueTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task} other{{count} tasks}}'**
  String queueTaskCount(int count);

  /// No description provided for @queueTimeRemainingDaysHours.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h remaining'**
  String queueTimeRemainingDaysHours(int days, int hours);

  /// No description provided for @queueTimeRemainingHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m remaining'**
  String queueTimeRemainingHoursMinutes(int hours, int minutes);

  /// No description provided for @queueTimeRemainingLessThanMinute.
  ///
  /// In en, this message translates to:
  /// **'Less than a minute'**
  String get queueTimeRemainingLessThanMinute;

  /// No description provided for @queueTimeRemainingMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m remaining'**
  String queueTimeRemainingMinutes(int minutes);

  /// No description provided for @queueUnableToImport.
  ///
  /// In en, this message translates to:
  /// **'Unable to Import Automatically'**
  String get queueUnableToImport;

  /// No description provided for @queueUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get queueUnknownError;

  /// No description provided for @releasesAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get releasesAge;

  /// No description provided for @releasesAgeDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, other{{days} days}}'**
  String releasesAgeDays(int days);

  /// No description provided for @releasesAgeShort.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String releasesAgeShort(int days);

  /// No description provided for @releasesApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get releasesApproval;

  /// No description provided for @releasesApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get releasesApproved;

  /// No description provided for @releasesClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get releasesClearSearch;

  /// No description provided for @releasesCustomFormat.
  ///
  /// In en, this message translates to:
  /// **'Custom format'**
  String get releasesCustomFormat;

  /// No description provided for @releasesCustomFormatScore.
  ///
  /// In en, this message translates to:
  /// **'Custom format score'**
  String get releasesCustomFormatScore;

  /// No description provided for @releasesCustomFormats.
  ///
  /// In en, this message translates to:
  /// **'Custom formats'**
  String get releasesCustomFormats;

  /// No description provided for @releasesDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Release details'**
  String get releasesDetailsTitle;

  /// No description provided for @releasesDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get releasesDownload;

  /// No description provided for @releasesDownloadRelease.
  ///
  /// In en, this message translates to:
  /// **'Download release'**
  String get releasesDownloadRelease;

  /// No description provided for @releasesDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Release'**
  String get releasesDownloadTitle;

  /// No description provided for @releasesEpisodeOrMovie.
  ///
  /// In en, this message translates to:
  /// **'Episode or movie'**
  String get releasesEpisodeOrMovie;

  /// No description provided for @releasesEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get releasesEpisodes;

  /// No description provided for @releasesExcludeFreeleech.
  ///
  /// In en, this message translates to:
  /// **'Exclude freeleech'**
  String get releasesExcludeFreeleech;

  /// No description provided for @releasesFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter releases'**
  String get releasesFilterTooltip;

  /// No description provided for @releasesFiltersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Combine any number of filters'**
  String get releasesFiltersSubtitle;

  /// No description provided for @releasesFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Release filters'**
  String get releasesFiltersTitle;

  /// No description provided for @releasesFreeleech.
  ///
  /// In en, this message translates to:
  /// **'Freeleech'**
  String get releasesFreeleech;

  /// No description provided for @releasesFreeleechOnly.
  ///
  /// In en, this message translates to:
  /// **'Freeleech only'**
  String get releasesFreeleechOnly;

  /// No description provided for @releasesGrabConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to grab \"{title}\"?'**
  String releasesGrabConfirm(String title);

  /// No description provided for @releasesGrabError.
  ///
  /// In en, this message translates to:
  /// **'Error grabbing release: {error}'**
  String releasesGrabError(String error);

  /// No description provided for @releasesGrabSuccess.
  ///
  /// In en, this message translates to:
  /// **'Release grabbed successfully'**
  String get releasesGrabSuccess;

  /// No description provided for @releasesIndexerFlags.
  ///
  /// In en, this message translates to:
  /// **'Indexer flags'**
  String get releasesIndexerFlags;

  /// No description provided for @releasesLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get releasesLanguages;

  /// No description provided for @releasesMappedEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Mapped episodes'**
  String get releasesMappedEpisodes;

  /// No description provided for @releasesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No releases match the current filters'**
  String get releasesNoMatch;

  /// No description provided for @releasesNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No releases found'**
  String get releasesNoneFound;

  /// No description provided for @releasesOriginalLanguageOnly.
  ///
  /// In en, this message translates to:
  /// **'Original language only'**
  String get releasesOriginalLanguageOnly;

  /// No description provided for @releasesQualityWeight.
  ///
  /// In en, this message translates to:
  /// **'Quality weight'**
  String get releasesQualityWeight;

  /// No description provided for @releasesRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get releasesRejected;

  /// No description provided for @releasesRejectedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rejected release'**
  String get releasesRejectedTooltip;

  /// No description provided for @releasesRejectionReasons.
  ///
  /// In en, this message translates to:
  /// **'Rejection reasons'**
  String get releasesRejectionReasons;

  /// No description provided for @releasesReleaseRejected.
  ///
  /// In en, this message translates to:
  /// **'Release rejected'**
  String get releasesReleaseRejected;

  /// No description provided for @releasesReleaseType.
  ///
  /// In en, this message translates to:
  /// **'Release type'**
  String get releasesReleaseType;

  /// No description provided for @releasesReleaseWeight.
  ///
  /// In en, this message translates to:
  /// **'Release weight'**
  String get releasesReleaseWeight;

  /// No description provided for @releasesRememberFilters.
  ///
  /// In en, this message translates to:
  /// **'Remember filters'**
  String get releasesRememberFilters;

  /// No description provided for @releasesRememberFiltersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep this configuration for future searches'**
  String get releasesRememberFiltersSubtitle;

  /// No description provided for @releasesRequestedEpisode.
  ///
  /// In en, this message translates to:
  /// **'Requested episode'**
  String get releasesRequestedEpisode;

  /// No description provided for @releasesResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} results}}'**
  String releasesResultCount(int count);

  /// No description provided for @releasesResultCountHidden.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} results}} · {hidden} hidden'**
  String releasesResultCountHidden(int count, int hidden);

  /// No description provided for @releasesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search releases'**
  String get releasesSearchHint;

  /// No description provided for @releasesSeasonPack.
  ///
  /// In en, this message translates to:
  /// **'Season pack'**
  String get releasesSeasonPack;

  /// No description provided for @releasesSeasonPacks.
  ///
  /// In en, this message translates to:
  /// **'Season packs'**
  String get releasesSeasonPacks;

  /// No description provided for @releasesSeeders.
  ///
  /// In en, this message translates to:
  /// **'Seeders'**
  String get releasesSeeders;

  /// No description provided for @releasesSeedsPeers.
  ///
  /// In en, this message translates to:
  /// **'Seeds / peers'**
  String get releasesSeedsPeers;

  /// No description provided for @releasesSendingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sending release to the download client'**
  String get releasesSendingTooltip;

  /// No description provided for @seriesAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Error adding series: {error}'**
  String seriesAddFailed(String error);

  /// No description provided for @seriesAddMissingSelection.
  ///
  /// In en, this message translates to:
  /// **'Please select a series, quality profile, and root folder'**
  String get seriesAddMissingSelection;

  /// No description provided for @seriesAddSeries.
  ///
  /// In en, this message translates to:
  /// **'Add series'**
  String get seriesAddSeries;

  /// No description provided for @seriesAddSeriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Series'**
  String get seriesAddSeriesTitle;

  /// No description provided for @seriesAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Series added successfully'**
  String get seriesAddedSuccessfully;

  /// No description provided for @seriesAirDate.
  ///
  /// In en, this message translates to:
  /// **'Air Date'**
  String get seriesAirDate;

  /// No description provided for @seriesAllFolders.
  ///
  /// In en, this message translates to:
  /// **'All folders'**
  String get seriesAllFolders;

  /// No description provided for @seriesAllSeasonsMonitored.
  ///
  /// In en, this message translates to:
  /// **'All seasons monitored'**
  String get seriesAllSeasonsMonitored;

  /// No description provided for @seriesAllSeasonsUnmonitored.
  ///
  /// In en, this message translates to:
  /// **'All seasons unmonitored'**
  String get seriesAllSeasonsUnmonitored;

  /// No description provided for @seriesAlsoDeleteFiles.
  ///
  /// In en, this message translates to:
  /// **'Also delete files from disk'**
  String get seriesAlsoDeleteFiles;

  /// No description provided for @seriesAndFilesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Series and files deleted'**
  String get seriesAndFilesDeleted;

  /// No description provided for @seriesConfigureAddition.
  ///
  /// In en, this message translates to:
  /// **'Configure Addition'**
  String get seriesConfigureAddition;

  /// No description provided for @seriesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String seriesDeleteFailed(String error);

  /// No description provided for @seriesDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get seriesDeleteFile;

  /// No description provided for @seriesDeleteFileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this file? This action cannot be undone.'**
  String get seriesDeleteFileConfirm;

  /// No description provided for @seriesDeleteFilesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all files for \"{title}\"? This removes every episode file from disk; the series stays in Sonarr.'**
  String seriesDeleteFilesConfirm(String title);

  /// No description provided for @seriesDeleteFilesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete files: {error}'**
  String seriesDeleteFilesFailed(String error);

  /// No description provided for @seriesDeleteFilesForSeasons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete files for 1 season} other{Delete files for {count} seasons}}'**
  String seriesDeleteFilesForSeasons(int count);

  /// No description provided for @seriesDeleteSeasonFiles.
  ///
  /// In en, this message translates to:
  /// **'Delete season files'**
  String get seriesDeleteSeasonFiles;

  /// No description provided for @seriesDeleteSeasonFilesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all files for \"{title} - Season {season}\"? This removes every episode file in this season from disk.'**
  String seriesDeleteSeasonFilesConfirm(String title, int season);

  /// No description provided for @seriesDeleteSeasonsFilesContent.
  ///
  /// In en, this message translates to:
  /// **'This deletes the episode files of the selected seasons from disk. The series stays in Sonarr.'**
  String get seriesDeleteSeasonsFilesContent;

  /// No description provided for @seriesDeleteSeries.
  ///
  /// In en, this message translates to:
  /// **'Delete Series'**
  String get seriesDeleteSeries;

  /// No description provided for @seriesDeleteSeriesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String seriesDeleteSeriesConfirm(String title);

  /// No description provided for @seriesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Series deleted'**
  String get seriesDeleted;

  /// No description provided for @seriesDeletedFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 file} other{Deleted {count} files}}'**
  String seriesDeletedFilesCount(int count);

  /// No description provided for @seriesEditSeries.
  ///
  /// In en, this message translates to:
  /// **'Edit Series'**
  String get seriesEditSeries;

  /// No description provided for @seriesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add series to your Sonarr library to see them here.'**
  String get seriesEmptySubtitle;

  /// No description provided for @seriesEpisodeActions.
  ///
  /// In en, this message translates to:
  /// **'Episode actions'**
  String get seriesEpisodeActions;

  /// No description provided for @seriesEpisodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} Episodes}}'**
  String seriesEpisodeCount(int count);

  /// No description provided for @seriesEpisodeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the episode: {error}'**
  String seriesEpisodeLoadFailed(String error);

  /// No description provided for @seriesEpisodeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading episode...'**
  String get seriesEpisodeLoading;

  /// No description provided for @seriesEpisodeMonitored.
  ///
  /// In en, this message translates to:
  /// **'Episode monitored'**
  String get seriesEpisodeMonitored;

  /// No description provided for @seriesEpisodeUnmonitored.
  ///
  /// In en, this message translates to:
  /// **'Episode unmonitored'**
  String get seriesEpisodeUnmonitored;

  /// No description provided for @seriesFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get seriesFile;

  /// No description provided for @seriesFileDeleted.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get seriesFileDeleted;

  /// No description provided for @seriesHideAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Hide already added'**
  String get seriesHideAlreadyAdded;

  /// No description provided for @seriesHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get seriesHistory;

  /// No description provided for @seriesLoadEpisodesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load episodes: {error}'**
  String seriesLoadEpisodesFailed(String error);

  /// No description provided for @seriesLoadFileInfoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load file info'**
  String get seriesLoadFileInfoFailed;

  /// No description provided for @seriesLoadFoldersError.
  ///
  /// In en, this message translates to:
  /// **'Error loading folders: {error}'**
  String seriesLoadFoldersError(String error);

  /// No description provided for @seriesLoadHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get seriesLoadHistoryFailed;

  /// No description provided for @seriesLoadProfilesError.
  ///
  /// In en, this message translates to:
  /// **'Error loading profiles: {error}'**
  String seriesLoadProfilesError(String error);

  /// No description provided for @seriesLoadingDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading details...'**
  String get seriesLoadingDetails;

  /// No description provided for @seriesLoadingSeries.
  ///
  /// In en, this message translates to:
  /// **'Loading series...'**
  String get seriesLoadingSeries;

  /// No description provided for @seriesMonitorEpisode.
  ///
  /// In en, this message translates to:
  /// **'Monitor episode'**
  String get seriesMonitorEpisode;

  /// No description provided for @seriesMonitorNewSeasons.
  ///
  /// In en, this message translates to:
  /// **'Monitor New Seasons'**
  String get seriesMonitorNewSeasons;

  /// No description provided for @seriesMonitorNewSeasonsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically monitor seasons added in the future'**
  String get seriesMonitorNewSeasonsSubtitle;

  /// No description provided for @seriesMonitoredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor episodes for this series'**
  String get seriesMonitoredSubtitle;

  /// No description provided for @seriesMoveFilesContent.
  ///
  /// In en, this message translates to:
  /// **'You changed the root folder. Do you want to move existing files to the new location?'**
  String get seriesMoveFilesContent;

  /// No description provided for @seriesMoveFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Move Files?'**
  String get seriesMoveFilesTitle;

  /// No description provided for @seriesNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get seriesNetwork;

  /// No description provided for @seriesNoEpisodesFound.
  ///
  /// In en, this message translates to:
  /// **'No episodes found'**
  String get seriesNoEpisodesFound;

  /// No description provided for @seriesNoFileAvailable.
  ///
  /// In en, this message translates to:
  /// **'No file available'**
  String get seriesNoFileAvailable;

  /// No description provided for @seriesNoFilesToDelete.
  ///
  /// In en, this message translates to:
  /// **'No files to delete'**
  String get seriesNoFilesToDelete;

  /// No description provided for @seriesNoHistoryEvents.
  ///
  /// In en, this message translates to:
  /// **'No history events'**
  String get seriesNoHistoryEvents;

  /// No description provided for @seriesNoOverview.
  ///
  /// In en, this message translates to:
  /// **'No overview available.'**
  String get seriesNoOverview;

  /// No description provided for @seriesNoRating.
  ///
  /// In en, this message translates to:
  /// **'No rating'**
  String get seriesNoRating;

  /// No description provided for @seriesNoResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get seriesNoResultsFound;

  /// No description provided for @seriesNoResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try clearing or adjusting your search query or filters.'**
  String get seriesNoResultsSubtitle;

  /// No description provided for @seriesNoSeriesFound.
  ///
  /// In en, this message translates to:
  /// **'No series found'**
  String get seriesNoSeriesFound;

  /// No description provided for @seriesNoSonarrInstance.
  ///
  /// In en, this message translates to:
  /// **'No Sonarr instance configured'**
  String get seriesNoSonarrInstance;

  /// No description provided for @seriesOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get seriesOverview;

  /// No description provided for @seriesPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get seriesPath;

  /// No description provided for @seriesPreventReAdd.
  ///
  /// In en, this message translates to:
  /// **'Prevent this series from being re-added'**
  String get seriesPreventReAdd;

  /// No description provided for @seriesPreview.
  ///
  /// In en, this message translates to:
  /// **'Series Preview'**
  String get seriesPreview;

  /// No description provided for @seriesPreviewCrossSeedsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to preview cross-seeds: {error}'**
  String seriesPreviewCrossSeedsFailed(String error);

  /// No description provided for @seriesPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to preview: {error}'**
  String seriesPreviewFailed(String error);

  /// No description provided for @seriesPurgeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to purge: {error}'**
  String seriesPurgeFailed(String error);

  /// No description provided for @seriesPurgeSeason.
  ///
  /// In en, this message translates to:
  /// **'Purge season'**
  String get seriesPurgeSeason;

  /// No description provided for @seriesPurgeSeasonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all files for \"{title} - Season {season}\" and remove their source torrents from qBittorrent? The series stays in Sonarr.'**
  String seriesPurgeSeasonConfirm(String title, int season);

  /// No description provided for @seriesPurgeSeasonsContent.
  ///
  /// In en, this message translates to:
  /// **'This deletes the episode files of the selected seasons and their source torrents from qBittorrent. The series stays in Sonarr.'**
  String get seriesPurgeSeasonsContent;

  /// No description provided for @seriesPurgeSeasonsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Purge 1 season} other{Purge {count} seasons}}'**
  String seriesPurgeSeasonsTitle(int count);

  /// No description provided for @seriesPurgeSeries.
  ///
  /// In en, this message translates to:
  /// **'Purge series'**
  String get seriesPurgeSeries;

  /// No description provided for @seriesPurgeSeriesConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove \"{title}\" and all its episodes from Sonarr, delete its media files, and delete all source torrents (plus cross-seed duplicates) from qBittorrent. Frees disk space used by hardlinked data.'**
  String seriesPurgeSeriesConfirm(String title);

  /// No description provided for @seriesPurged.
  ///
  /// In en, this message translates to:
  /// **'Series purged.'**
  String get seriesPurged;

  /// No description provided for @seriesPurgedSeasonsSummary.
  ///
  /// In en, this message translates to:
  /// **'Purged {seasons, plural, =1{1 season} other{{seasons} seasons}}: {files, plural, =1{1 file} other{{files} files}}, {torrents, plural, =1{1 torrent} other{{torrents} torrents}}.'**
  String seriesPurgedSeasonsSummary(int seasons, int files, int torrents);

  /// No description provided for @seriesPurgedSummary.
  ///
  /// In en, this message translates to:
  /// **'Purged: {files, plural, =1{1 file} other{{files} files}}, {torrents, plural, =1{1 torrent} other{{torrents} torrents}}.'**
  String seriesPurgedSummary(int files, int torrents);

  /// No description provided for @seriesRefreshAndScan.
  ///
  /// In en, this message translates to:
  /// **'Refresh & Scan'**
  String get seriesRefreshAndScan;

  /// No description provided for @seriesRefreshScanTriggered.
  ///
  /// In en, this message translates to:
  /// **'Refresh & Scan triggered'**
  String get seriesRefreshScanTriggered;

  /// No description provided for @seriesRootFolderFreeSpace.
  ///
  /// In en, this message translates to:
  /// **'{path} ({free} GB Free)'**
  String seriesRootFolderFreeSpace(String path, String free);

  /// No description provided for @seriesRootFolderHeader.
  ///
  /// In en, this message translates to:
  /// **'ROOT FOLDER'**
  String get seriesRootFolderHeader;

  /// No description provided for @seriesRuntimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String seriesRuntimeMinutes(int minutes);

  /// No description provided for @seriesSearchByHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title, provider ID, or URL'**
  String get seriesSearchByHint;

  /// No description provided for @seriesSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to search: {error}'**
  String seriesSearchFailed(String error);

  /// No description provided for @seriesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search series...'**
  String get seriesSearchHint;

  /// No description provided for @seriesSearchStartedFor.
  ///
  /// In en, this message translates to:
  /// **'Search started for {name}'**
  String seriesSearchStartedFor(String name);

  /// No description provided for @seriesSearchStartedForSeasons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Search started for 1 season} other{Search started for {count} seasons}}'**
  String seriesSearchStartedForSeasons(int count);

  /// No description provided for @seriesSearchingFor.
  ///
  /// In en, this message translates to:
  /// **'Searching for {name}...'**
  String seriesSearchingFor(String name);

  /// No description provided for @seriesSeasonActions.
  ///
  /// In en, this message translates to:
  /// **'Season actions'**
  String get seriesSeasonActions;

  /// No description provided for @seriesSeasonCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} Seasons}}'**
  String seriesSeasonCount(int count);

  /// No description provided for @seriesSeasonFolder.
  ///
  /// In en, this message translates to:
  /// **'Season Folder'**
  String get seriesSeasonFolder;

  /// No description provided for @seriesSeasonFolders.
  ///
  /// In en, this message translates to:
  /// **'Season Folders'**
  String get seriesSeasonFolders;

  /// No description provided for @seriesSeasonFoldersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Season folders (e.g. Season 01/...)'**
  String get seriesSeasonFoldersSubtitle;

  /// No description provided for @seriesSeasonLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the season: {error}'**
  String seriesSeasonLoadFailed(String error);

  /// No description provided for @seriesSeasonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading season...'**
  String get seriesSeasonLoading;

  /// No description provided for @seriesSeasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get seriesSeasonTitle;

  /// No description provided for @seriesSeasons.
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get seriesSeasons;

  /// No description provided for @seriesSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get seriesSelect;

  /// No description provided for @seriesSelectPath.
  ///
  /// In en, this message translates to:
  /// **'Select Path'**
  String get seriesSelectPath;

  /// No description provided for @seriesSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} selected}}'**
  String seriesSelectedCount(int count);

  /// No description provided for @seriesSeriesType.
  ///
  /// In en, this message translates to:
  /// **'Series Type'**
  String get seriesSeriesType;

  /// No description provided for @seriesSortAndFilter.
  ///
  /// In en, this message translates to:
  /// **'Sort & Filter'**
  String get seriesSortAndFilter;

  /// No description provided for @seriesSwitchToGrid.
  ///
  /// In en, this message translates to:
  /// **'Switch to Grid'**
  String get seriesSwitchToGrid;

  /// No description provided for @seriesSwitchToList.
  ///
  /// In en, this message translates to:
  /// **'Switch to List'**
  String get seriesSwitchToList;

  /// No description provided for @seriesTitleWithSeason.
  ///
  /// In en, this message translates to:
  /// **'{title} - Season {season}'**
  String seriesTitleWithSeason(String title, int season);

  /// No description provided for @seriesUnableToOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Unable to open link: {error}'**
  String seriesUnableToOpenLink(String error);

  /// No description provided for @seriesUnmonitorEpisode.
  ///
  /// In en, this message translates to:
  /// **'Unmonitor episode'**
  String get seriesUnmonitorEpisode;

  /// No description provided for @seriesUnmonitoredSeasons.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Unmonitored 1 season} other{Unmonitored {count} seasons}}'**
  String seriesUnmonitoredSeasons(int count);

  /// No description provided for @seriesUpdateEpisodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update episode: {error}'**
  String seriesUpdateEpisodeFailed(String error);

  /// No description provided for @seriesUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Error updating series: {error}'**
  String seriesUpdateFailed(String error);

  /// No description provided for @seriesViewPoster.
  ///
  /// In en, this message translates to:
  /// **'View {title} poster'**
  String seriesViewPoster(String title);

  /// No description provided for @seriesWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get seriesWatch;

  /// No description provided for @seriesYesMoveFiles.
  ///
  /// In en, this message translates to:
  /// **'Yes, Move Files'**
  String get seriesYesMoveFiles;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAddInstance.
  ///
  /// In en, this message translates to:
  /// **'Add Instance'**
  String get settingsAddInstance;

  /// No description provided for @settingsAppUpToDate.
  ///
  /// In en, this message translates to:
  /// **'App is up to date'**
  String get settingsAppUpToDate;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get settingsAssistant;

  /// No description provided for @settingsAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask how the app works'**
  String get settingsAssistantSubtitle;

  /// No description provided for @settingsBackupLocalFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import or export a local file'**
  String get settingsBackupLocalFileSubtitle;

  /// No description provided for @settingsColorScheme.
  ///
  /// In en, this message translates to:
  /// **'Color Scheme'**
  String get settingsColorScheme;

  /// No description provided for @settingsCouldNotCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates'**
  String get settingsCouldNotCheckUpdates;

  /// No description provided for @settingsGettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get settingsGettingStarted;

  /// No description provided for @settingsGettingStartedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replay the setup tour'**
  String get settingsGettingStartedSubtitle;

  /// No description provided for @settingsHomeTab.
  ///
  /// In en, this message translates to:
  /// **'Home Tab'**
  String get settingsHomeTab;

  /// No description provided for @settingsInstanceTagCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tag} other{{count} tags}}'**
  String settingsInstanceTagCount(int count);

  /// No description provided for @settingsInstances.
  ///
  /// In en, this message translates to:
  /// **'Instances'**
  String get settingsInstances;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsNoArrInstancesConfigured.
  ///
  /// In en, this message translates to:
  /// **'No Arr instances configured'**
  String get settingsNoArrInstancesConfigured;

  /// No description provided for @settingsNoInstances.
  ///
  /// In en, this message translates to:
  /// **'No instances configured'**
  String get settingsNoInstances;

  /// No description provided for @settingsNoRadarrSonarrInstances.
  ///
  /// In en, this message translates to:
  /// **'No Radarr or Sonarr instances configured'**
  String get settingsNoRadarrSonarrInstances;

  /// No description provided for @settingsNotificationCenter.
  ///
  /// In en, this message translates to:
  /// **'Notification Center'**
  String get settingsNotificationCenter;

  /// No description provided for @settingsNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get settingsNotificationSettings;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enabled · ntfy.sh integration'**
  String get settingsNotificationsEnabledSubtitle;

  /// No description provided for @settingsNotificationsSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Setup notifications'**
  String get settingsNotificationsSetupSubtitle;

  /// No description provided for @settingsSelectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get settingsSelectColor;

  /// No description provided for @settingsSelectHomeTab.
  ///
  /// In en, this message translates to:
  /// **'Select Home Tab'**
  String get settingsSelectHomeTab;

  /// No description provided for @settingsSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsSelectLanguage;

  /// No description provided for @settingsSelectMode.
  ///
  /// In en, this message translates to:
  /// **'Select Mode'**
  String get settingsSelectMode;

  /// No description provided for @settingsSessionExpiredSignIn.
  ///
  /// In en, this message translates to:
  /// **'Session expired · tap to sign in'**
  String get settingsSessionExpiredSignIn;

  /// No description provided for @settingsSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get settingsSourceCode;

  /// No description provided for @settingsSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystem;

  /// No description provided for @settingsSystemManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics, status, logs, and app maintenance'**
  String get settingsSystemManagementSubtitle;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get settingsThemeMode;

  /// No description provided for @settingsUnreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread notification} other{{count} unread notifications}}'**
  String settingsUnreadNotifications(int count);

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsVersionViaAltStore.
  ///
  /// In en, this message translates to:
  /// **'{version} • updates via AltStore'**
  String settingsVersionViaAltStore(String version);

  /// No description provided for @settingsViewAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'View all notifications'**
  String get settingsViewAllNotifications;

  /// No description provided for @sharedAddImportExclusion.
  ///
  /// In en, this message translates to:
  /// **'Add to import exclusion list'**
  String get sharedAddImportExclusion;

  /// No description provided for @sharedAddImportExclusionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prevent the item from being added again by an import list.'**
  String get sharedAddImportExclusionSubtitle;

  /// No description provided for @sharedAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sharedAscending;

  /// No description provided for @sharedBatchDeleteFilesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete files: {error}'**
  String sharedBatchDeleteFilesFailed(String error);

  /// No description provided for @sharedBatchDeleteMovieFilesContent.
  ///
  /// In en, this message translates to:
  /// **'This deletes the media files of the selected movies from disk. They stay in Radarr.'**
  String get sharedBatchDeleteMovieFilesContent;

  /// No description provided for @sharedBatchDeleteMovieFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete files for 1 movie} other{Delete files for {count} movies}}'**
  String sharedBatchDeleteMovieFilesTitle(int count);

  /// No description provided for @sharedBatchDeleteMoviesKeepFiles.
  ///
  /// In en, this message translates to:
  /// **'This removes the selected movies from Radarr. Files stay on disk.'**
  String get sharedBatchDeleteMoviesKeepFiles;

  /// No description provided for @sharedBatchDeleteMoviesPartial.
  ///
  /// In en, this message translates to:
  /// **'Deleted {deleted} of {total, plural, =1{1 movie} other{{total} movies}} before error: {error}'**
  String sharedBatchDeleteMoviesPartial(int deleted, int total, String error);

  /// No description provided for @sharedBatchDeleteMoviesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 movie} other{Delete {count} movies}}'**
  String sharedBatchDeleteMoviesTitle(int count);

  /// No description provided for @sharedBatchDeleteMoviesWithFiles.
  ///
  /// In en, this message translates to:
  /// **'This removes the selected movies from Radarr and deletes their files from disk.'**
  String get sharedBatchDeleteMoviesWithFiles;

  /// No description provided for @sharedBatchDeleteSeriesFilesContent.
  ///
  /// In en, this message translates to:
  /// **'This deletes the media files of the selected series from disk. They stay in Sonarr.'**
  String get sharedBatchDeleteSeriesFilesContent;

  /// No description provided for @sharedBatchDeleteSeriesFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete files for 1 series} other{Delete files for {count} series}}'**
  String sharedBatchDeleteSeriesFilesTitle(int count);

  /// No description provided for @sharedBatchDeleteSeriesKeepFiles.
  ///
  /// In en, this message translates to:
  /// **'This removes the selected series from Sonarr. Files stay on disk.'**
  String get sharedBatchDeleteSeriesKeepFiles;

  /// No description provided for @sharedBatchDeleteSeriesPartial.
  ///
  /// In en, this message translates to:
  /// **'Deleted {deleted} of {total} series before error: {error}'**
  String sharedBatchDeleteSeriesPartial(int deleted, int total, String error);

  /// No description provided for @sharedBatchDeleteSeriesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 series} other{Delete {count} series}}'**
  String sharedBatchDeleteSeriesTitle(int count);

  /// No description provided for @sharedBatchDeleteSeriesWithFiles.
  ///
  /// In en, this message translates to:
  /// **'This removes the selected series from Sonarr and deletes their files from disk.'**
  String get sharedBatchDeleteSeriesWithFiles;

  /// No description provided for @sharedBatchDeletedFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 file} other{Deleted {count} files}}'**
  String sharedBatchDeletedFiles(int count);

  /// No description provided for @sharedBatchDeletedMovies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 movie} other{Deleted {count} movies}}'**
  String sharedBatchDeletedMovies(int count);

  /// No description provided for @sharedBatchDeletedMoviesAndFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 movie and files} other{Deleted {count} movies and files}}'**
  String sharedBatchDeletedMoviesAndFiles(int count);

  /// No description provided for @sharedBatchDeletedSeries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 series} other{Deleted {count} series}}'**
  String sharedBatchDeletedSeries(int count);

  /// No description provided for @sharedBatchDeletedSeriesAndFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 series and files} other{Deleted {count} series and files}}'**
  String sharedBatchDeletedSeriesAndFiles(int count);

  /// No description provided for @sharedBatchMonitoredMovies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Monitored 1 movie} other{Monitored {count} movies}}'**
  String sharedBatchMonitoredMovies(int count);

  /// No description provided for @sharedBatchMonitoredSeries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Monitored 1 series} other{Monitored {count} series}}'**
  String sharedBatchMonitoredSeries(int count);

  /// No description provided for @sharedBatchPreviewCrossSeedsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to preview cross-seeds: {error}'**
  String sharedBatchPreviewCrossSeedsFailed(String error);

  /// No description provided for @sharedBatchPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to preview: {error}'**
  String sharedBatchPreviewFailed(String error);

  /// No description provided for @sharedBatchPurgeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to purge: {error}'**
  String sharedBatchPurgeFailed(String error);

  /// No description provided for @sharedBatchPurgeMoviesContent.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the selected movies from Radarr, deletes their files, and deletes all source torrents from qBittorrent.'**
  String get sharedBatchPurgeMoviesContent;

  /// No description provided for @sharedBatchPurgeMoviesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Purge 1 movie} other{Purge {count} movies}}'**
  String sharedBatchPurgeMoviesTitle(int count);

  /// No description provided for @sharedBatchPurgeSeriesContent.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the selected series from Sonarr, deletes their files, and deletes all source torrents from qBittorrent.'**
  String get sharedBatchPurgeSeriesContent;

  /// No description provided for @sharedBatchPurgeSeriesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Purge 1 series} other{Purge {count} series}}'**
  String sharedBatchPurgeSeriesTitle(int count);

  /// No description provided for @sharedBatchPurgedMovies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Purged 1 movie.} other{Purged {count} movies.}}'**
  String sharedBatchPurgedMovies(int count);

  /// No description provided for @sharedBatchPurgedSeries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Purged 1 series.} other{Purged {count} series.}}'**
  String sharedBatchPurgedSeries(int count);

  /// No description provided for @sharedBatchUnmonitoredMovies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Unmonitored 1 movie} other{Unmonitored {count} movies}}'**
  String sharedBatchUnmonitoredMovies(int count);

  /// No description provided for @sharedBatchUnmonitoredSeries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Unmonitored 1 series} other{Unmonitored {count} series}}'**
  String sharedBatchUnmonitoredSeries(int count);

  /// No description provided for @sharedBatchUpdateMoviesPartial.
  ///
  /// In en, this message translates to:
  /// **'Updated {updated} of {total, plural, =1{1 movie} other{{total} movies}} before error: {error}'**
  String sharedBatchUpdateMoviesPartial(int updated, int total, String error);

  /// No description provided for @sharedBatchUpdateSeriesPartial.
  ///
  /// In en, this message translates to:
  /// **'Updated {updated} of {total} series before error: {error}'**
  String sharedBatchUpdateSeriesPartial(int updated, int total, String error);

  /// No description provided for @sharedDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sharedDescending;

  /// No description provided for @sharedFailedToLoadTorrents.
  ///
  /// In en, this message translates to:
  /// **'Failed to load torrents'**
  String get sharedFailedToLoadTorrents;

  /// No description provided for @sharedNoRadarrInstance.
  ///
  /// In en, this message translates to:
  /// **'No Radarr instance configured'**
  String get sharedNoRadarrInstance;

  /// No description provided for @sharedNoTorrentsInClient.
  ///
  /// In en, this message translates to:
  /// **'No torrents in the download client'**
  String get sharedNoTorrentsInClient;

  /// No description provided for @sharedSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} selected}}'**
  String sharedSelectedCount(int count);

  /// No description provided for @sharedTorrents.
  ///
  /// In en, this message translates to:
  /// **'Torrents'**
  String get sharedTorrents;

  /// No description provided for @sharedTorrentsDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'This removes the selected torrents from qBittorrent and deletes their files from disk.'**
  String get sharedTorrentsDeleteContent;

  /// No description provided for @sharedTorrentsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete torrents: {error}'**
  String sharedTorrentsDeleteFailed(String error);

  /// No description provided for @sharedTorrentsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 torrent} other{Delete {count} torrents}}'**
  String sharedTorrentsDeleteTitle(int count);

  /// No description provided for @sharedTorrentsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 torrent and files} other{Deleted {count} torrents and files}}'**
  String sharedTorrentsDeleted(int count);

  /// No description provided for @sharedTorrentsDeletedKept.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted 1 torrent and files (kept {kept} still seeding)} other{Deleted {count} torrents and files (kept {kept} still seeding)}}'**
  String sharedTorrentsDeletedKept(int count, int kept);

  /// No description provided for @sharedTorrentsKeepSeedingAll.
  ///
  /// In en, this message translates to:
  /// **'Keep seeding leaves them and their files untouched.'**
  String get sharedTorrentsKeepSeedingAll;

  /// No description provided for @sharedTorrentsKeepSeedingSome.
  ///
  /// In en, this message translates to:
  /// **'The other selected torrents and their files are deleted either way.'**
  String get sharedTorrentsKeepSeedingSome;

  /// No description provided for @sharedTorrentsNoQbittorrent.
  ///
  /// In en, this message translates to:
  /// **'No qBittorrent instance configured'**
  String get sharedTorrentsNoQbittorrent;

  /// No description provided for @sharedTorrentsNoneDeleted.
  ///
  /// In en, this message translates to:
  /// **'No torrents deleted'**
  String get sharedTorrentsNoneDeleted;

  /// No description provided for @sharedTorrentsNoneDeletedKept.
  ///
  /// In en, this message translates to:
  /// **'No torrents deleted (kept {kept} still seeding)'**
  String sharedTorrentsNoneDeletedKept(int kept);

  /// No description provided for @systemAppMaintenance.
  ///
  /// In en, this message translates to:
  /// **'App Maintenance'**
  String get systemAppMaintenance;

  /// No description provided for @systemClearImageCache.
  ///
  /// In en, this message translates to:
  /// **'Clear image cache'**
  String get systemClearImageCache;

  /// No description provided for @systemClearImageCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free up cached poster and image storage'**
  String get systemClearImageCacheSubtitle;

  /// No description provided for @systemDaysHelper.
  ///
  /// In en, this message translates to:
  /// **'0 disables the warning'**
  String get systemDaysHelper;

  /// No description provided for @systemDaysInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number (0 or more)'**
  String get systemDaysInvalid;

  /// No description provided for @systemDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get systemDaysLabel;

  /// No description provided for @systemDiagnosticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Test endpoints, latency, request traces, and export a report'**
  String get systemDiagnosticsSubtitle;

  /// No description provided for @systemHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get systemHealth;

  /// No description provided for @systemHealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Server-reported Radarr and Sonarr alerts'**
  String get systemHealthSubtitle;

  /// No description provided for @systemImageCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Image cache cleared'**
  String get systemImageCacheCleared;

  /// No description provided for @systemLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get systemLogs;

  /// No description provided for @systemLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System event logs'**
  String get systemLogsSubtitle;

  /// No description provided for @systemManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'System Management'**
  String get systemManagementTitle;

  /// No description provided for @systemMinimumSeedingDays.
  ///
  /// In en, this message translates to:
  /// **'Minimum seeding days'**
  String get systemMinimumSeedingDays;

  /// No description provided for @systemMinimumSeedingDaysDescription.
  ///
  /// In en, this message translates to:
  /// **'Torrents that seeded for less than this are flagged for confirmation before deletion. Set to 0 to disable.'**
  String get systemMinimumSeedingDaysDescription;

  /// No description provided for @systemOverviewDiskSpace.
  ///
  /// In en, this message translates to:
  /// **'Disk Space'**
  String get systemOverviewDiskSpace;

  /// No description provided for @systemOverviewDiskSpaceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Disk space information is unavailable.'**
  String get systemOverviewDiskSpaceUnavailable;

  /// No description provided for @systemOverviewEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a Radarr or Sonarr instance to view system data.'**
  String get systemOverviewEmptySubtitle;

  /// No description provided for @systemOverviewEpisodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Episode} other{{count} Episodes}}'**
  String systemOverviewEpisodeCount(int count);

  /// No description provided for @systemOverviewFreeOf.
  ///
  /// In en, this message translates to:
  /// **'{free} free of {total}'**
  String systemOverviewFreeOf(String free, String total);

  /// No description provided for @systemOverviewLibrarySize.
  ///
  /// In en, this message translates to:
  /// **'{size} Library'**
  String systemOverviewLibrarySize(String size);

  /// No description provided for @systemOverviewLibraryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Library statistics are unavailable.'**
  String get systemOverviewLibraryUnavailable;

  /// No description provided for @systemOverviewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the system overview.'**
  String get systemOverviewLoadFailed;

  /// No description provided for @systemOverviewLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading system overview...'**
  String get systemOverviewLoading;

  /// No description provided for @systemOverviewMovieCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Movie} other{{count} Movies}}'**
  String systemOverviewMovieCount(int count);

  /// No description provided for @systemOverviewNoStorage.
  ///
  /// In en, this message translates to:
  /// **'No storage locations reported.'**
  String get systemOverviewNoStorage;

  /// No description provided for @systemOverviewSeriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Series'**
  String systemOverviewSeriesCount(int count);

  /// No description provided for @systemOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Storage, versions, and library sizes'**
  String get systemOverviewSubtitle;

  /// No description provided for @systemOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'System Overview'**
  String get systemOverviewTitle;

  /// No description provided for @systemOverviewUsed.
  ///
  /// In en, this message translates to:
  /// **'Used {size} ({percent}%)'**
  String systemOverviewUsed(String size, int percent);

  /// No description provided for @systemOverviewVersionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Version information is unavailable.'**
  String get systemOverviewVersionUnavailable;

  /// No description provided for @systemQualityProfilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Available profiles from instances'**
  String get systemQualityProfilesSubtitle;

  /// No description provided for @systemResetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This restores appearance, language, view mode, and notification preferences to their defaults. Configured instances are preserved.'**
  String get systemResetConfirmBody;

  /// No description provided for @systemResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset app settings?'**
  String get systemResetConfirmTitle;

  /// No description provided for @systemResetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset app settings'**
  String get systemResetSettings;

  /// No description provided for @systemResetSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore appearance, language, view, and notification defaults'**
  String get systemResetSettingsSubtitle;

  /// No description provided for @systemSeedingDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String systemSeedingDaysShort(int count);

  /// No description provided for @systemSeedingWarningDisabled.
  ///
  /// In en, this message translates to:
  /// **'Seeding warning disabled'**
  String get systemSeedingWarningDisabled;

  /// No description provided for @systemSeedingWarningEnabled.
  ///
  /// In en, this message translates to:
  /// **'Warn before deleting torrents that seeded for less than {count, plural, =1{1 day} other{{count} days}}.'**
  String systemSeedingWarningEnabled(int count);

  /// No description provided for @systemServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get systemServer;

  /// No description provided for @systemSettingsReset.
  ///
  /// In en, this message translates to:
  /// **'App settings reset to defaults'**
  String get systemSettingsReset;

  /// No description provided for @systemTorrentProtection.
  ///
  /// In en, this message translates to:
  /// **'Torrent Protection'**
  String get systemTorrentProtection;

  /// No description provided for @systemVersionHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Changelog for every published release'**
  String get systemVersionHistorySubtitle;

  /// No description provided for @torrentAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add torrent: {error}'**
  String torrentAddFailed(String error);

  /// No description provided for @torrentAddOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get torrentAddOptions;

  /// No description provided for @torrentAddOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get torrentAddOr;

  /// No description provided for @torrentAddSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get torrentAddSource;

  /// No description provided for @torrentAddSourceRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide URLs or select a .torrent file'**
  String get torrentAddSourceRequired;

  /// No description provided for @torrentAddTorrent.
  ///
  /// In en, this message translates to:
  /// **'Add Torrent'**
  String get torrentAddTorrent;

  /// No description provided for @torrentAdded.
  ///
  /// In en, this message translates to:
  /// **'Torrent added successfully'**
  String get torrentAdded;

  /// No description provided for @torrentAlsoDeleteFiles.
  ///
  /// In en, this message translates to:
  /// **'Also delete files on disk'**
  String get torrentAlsoDeleteFiles;

  /// No description provided for @torrentCategoriesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load categories. Using free text mode.'**
  String get torrentCategoriesLoadFailed;

  /// No description provided for @torrentCategoryOptional.
  ///
  /// In en, this message translates to:
  /// **'Category (Optional)'**
  String get torrentCategoryOptional;

  /// No description provided for @torrentChangeSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Change Save Location'**
  String get torrentChangeSaveLocation;

  /// No description provided for @torrentChangeSaveLocationWarning.
  ///
  /// In en, this message translates to:
  /// **'This will move all downloaded data to the new location.'**
  String get torrentChangeSaveLocationWarning;

  /// No description provided for @torrentClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get torrentClearSearch;

  /// No description provided for @torrentConnectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} connected}}'**
  String torrentConnectedCount(int count);

  /// No description provided for @torrentCrossSeedBadge.
  ///
  /// In en, this message translates to:
  /// **'Cross-seed'**
  String get torrentCrossSeedBadge;

  /// No description provided for @torrentCrossSeedExplanation.
  ///
  /// In en, this message translates to:
  /// **'Matched as a cross-seed: same release name as the torrent Radarr/Sonarr grabbed, different infohash.'**
  String get torrentCrossSeedExplanation;

  /// No description provided for @torrentDeleteWithFiles.
  ///
  /// In en, this message translates to:
  /// **'Delete with files'**
  String get torrentDeleteWithFiles;

  /// No description provided for @torrentEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a new torrent to start downloading'**
  String get torrentEmptySubtitle;

  /// No description provided for @torrentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Torrents'**
  String get torrentEmptyTitle;

  /// No description provided for @torrentEnterValidPath.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid path'**
  String get torrentEnterValidPath;

  /// No description provided for @torrentEta.
  ///
  /// In en, this message translates to:
  /// **'ETA: {eta}'**
  String torrentEta(String eta);

  /// No description provided for @torrentFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get torrentFiles;

  /// No description provided for @torrentFilterLibraryLink.
  ///
  /// In en, this message translates to:
  /// **'Library link'**
  String get torrentFilterLibraryLink;

  /// No description provided for @torrentFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter torrents'**
  String get torrentFilterTooltip;

  /// No description provided for @torrentFiltersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Combine any number of filters'**
  String get torrentFiltersSubtitle;

  /// No description provided for @torrentFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Torrent filters'**
  String get torrentFiltersTitle;

  /// No description provided for @torrentImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import: {error}'**
  String torrentImportFailed(String error);

  /// No description provided for @torrentImportFilesImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} file(s) imported successfully}}'**
  String torrentImportFilesImported(int count);

  /// No description provided for @torrentImportFilesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} file(s) selected for import}}'**
  String torrentImportFilesSelected(int count);

  /// No description provided for @torrentImportLoadMoviesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load movies'**
  String get torrentImportLoadMoviesFailed;

  /// No description provided for @torrentImportLoadSeriesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load series'**
  String get torrentImportLoadSeriesFailed;

  /// No description provided for @torrentImportLoadingMovies.
  ///
  /// In en, this message translates to:
  /// **'Loading movies...'**
  String get torrentImportLoadingMovies;

  /// No description provided for @torrentImportLoadingSeries.
  ///
  /// In en, this message translates to:
  /// **'Loading series...'**
  String get torrentImportLoadingSeries;

  /// No description provided for @torrentImportNoFilesSelected.
  ///
  /// In en, this message translates to:
  /// **'No files selected'**
  String get torrentImportNoFilesSelected;

  /// No description provided for @torrentImportNoFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No importable files found in {path}'**
  String torrentImportNoFilesSubtitle(String path);

  /// No description provided for @torrentImportNoFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Files Found'**
  String get torrentImportNoFilesTitle;

  /// No description provided for @torrentImportNoMoviesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No monitored movies match your search.'**
  String get torrentImportNoMoviesSubtitle;

  /// No description provided for @torrentImportNoMoviesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Movies Found'**
  String get torrentImportNoMoviesTitle;

  /// No description provided for @torrentImportNoSeriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No monitored series match your search.'**
  String get torrentImportNoSeriesSubtitle;

  /// No description provided for @torrentImportNoSeriesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Series Found'**
  String get torrentImportNoSeriesTitle;

  /// No description provided for @torrentImportSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get torrentImportSearchHint;

  /// No description provided for @torrentImportSelectFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Select files to import. Tap on a file to configure its mapping.'**
  String get torrentImportSelectFilesHint;

  /// No description provided for @torrentImportSelectTarget.
  ///
  /// In en, this message translates to:
  /// **'Select Target'**
  String get torrentImportSelectTarget;

  /// No description provided for @torrentImportToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Import to Media Library'**
  String get torrentImportToLibrary;

  /// No description provided for @torrentImportToMovie.
  ///
  /// In en, this message translates to:
  /// **'Import to Movie'**
  String get torrentImportToMovie;

  /// No description provided for @torrentImportToSeries.
  ///
  /// In en, this message translates to:
  /// **'Import to Series'**
  String get torrentImportToSeries;

  /// No description provided for @torrentInfoAddedOn.
  ///
  /// In en, this message translates to:
  /// **'Added On'**
  String get torrentInfoAddedOn;

  /// No description provided for @torrentInfoCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get torrentInfoCategory;

  /// No description provided for @torrentInfoHash.
  ///
  /// In en, this message translates to:
  /// **'Hash'**
  String get torrentInfoHash;

  /// No description provided for @torrentInfoInstance.
  ///
  /// In en, this message translates to:
  /// **'Instance'**
  String get torrentInfoInstance;

  /// No description provided for @torrentInfoMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get torrentInfoMedia;

  /// No description provided for @torrentInfoSavePath.
  ///
  /// In en, this message translates to:
  /// **'Save Path'**
  String get torrentInfoSavePath;

  /// No description provided for @torrentLibraryLinksLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Library links could not be loaded.'**
  String get torrentLibraryLinksLoadFailed;

  /// No description provided for @torrentLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load torrents'**
  String get torrentLoadFailed;

  /// No description provided for @torrentLoadFilesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load files: {error}'**
  String torrentLoadFilesFailed(String error);

  /// No description provided for @torrentLoadPeersFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load peers'**
  String get torrentLoadPeersFailed;

  /// No description provided for @torrentLoadTrackersFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load trackers'**
  String get torrentLoadTrackersFailed;

  /// No description provided for @torrentLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading torrents...'**
  String get torrentLoading;

  /// No description provided for @torrentLoadingFiles.
  ///
  /// In en, this message translates to:
  /// **'Loading files...'**
  String get torrentLoadingFiles;

  /// No description provided for @torrentLoadingPeers.
  ///
  /// In en, this message translates to:
  /// **'Loading peers...'**
  String get torrentLoadingPeers;

  /// No description provided for @torrentLoadingTrackers.
  ///
  /// In en, this message translates to:
  /// **'Loading trackers...'**
  String get torrentLoadingTrackers;

  /// No description provided for @torrentLocationMoved.
  ///
  /// In en, this message translates to:
  /// **'Location moved successfully. Data is being moved.'**
  String get torrentLocationMoved;

  /// No description provided for @torrentMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get torrentMove;

  /// No description provided for @torrentMoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to move: {error}'**
  String torrentMoveFailed(String error);

  /// No description provided for @torrentNewLocation.
  ///
  /// In en, this message translates to:
  /// **'New Location'**
  String get torrentNewLocation;

  /// No description provided for @torrentNoFilesFound.
  ///
  /// In en, this message translates to:
  /// **'No files found'**
  String get torrentNoFilesFound;

  /// No description provided for @torrentNoFilterMatches.
  ///
  /// In en, this message translates to:
  /// **'No torrents match the current filters'**
  String get torrentNoFilterMatches;

  /// No description provided for @torrentNoPeers.
  ///
  /// In en, this message translates to:
  /// **'No peers connected'**
  String get torrentNoPeers;

  /// No description provided for @torrentNoPeersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Peers will appear when the torrent is active'**
  String get torrentNoPeersSubtitle;

  /// No description provided for @torrentNoTrackers.
  ///
  /// In en, this message translates to:
  /// **'No trackers'**
  String get torrentNoTrackers;

  /// No description provided for @torrentNoTrackersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Announce URLs appear here once qBittorrent has them'**
  String get torrentNoTrackersSubtitle;

  /// No description provided for @torrentPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get torrentPause;

  /// No description provided for @torrentPeerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} peers}}'**
  String torrentPeerCount(int count);

  /// No description provided for @torrentPeers.
  ///
  /// In en, this message translates to:
  /// **'Peers'**
  String get torrentPeers;

  /// No description provided for @torrentPercentCompleted.
  ///
  /// In en, this message translates to:
  /// **'{percent} completed'**
  String torrentPercentCompleted(String percent);

  /// No description provided for @torrentPercentDone.
  ///
  /// In en, this message translates to:
  /// **'{percent} done'**
  String torrentPercentDone(String percent);

  /// No description provided for @torrentPickFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick file: {error}'**
  String torrentPickFileFailed(String error);

  /// No description provided for @torrentRecheck.
  ///
  /// In en, this message translates to:
  /// **'Recheck'**
  String get torrentRecheck;

  /// No description provided for @torrentRememberFilters.
  ///
  /// In en, this message translates to:
  /// **'Remember filters'**
  String get torrentRememberFilters;

  /// No description provided for @torrentRememberFiltersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep this configuration for future sessions'**
  String get torrentRememberFiltersSubtitle;

  /// No description provided for @torrentRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get torrentRemove;

  /// No description provided for @torrentRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{name}\"?'**
  String torrentRemoveConfirm(String name);

  /// No description provided for @torrentRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove torrent: {error}'**
  String torrentRemoveFailed(String error);

  /// No description provided for @torrentRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Torrent?'**
  String get torrentRemoveTitle;

  /// No description provided for @torrentRemoveTorrent.
  ///
  /// In en, this message translates to:
  /// **'Remove Torrent'**
  String get torrentRemoveTorrent;

  /// No description provided for @torrentResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} torrents}}'**
  String torrentResultCount(int count);

  /// No description provided for @torrentResultCountWithHidden.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} torrents · {hidden} hidden}}'**
  String torrentResultCountWithHidden(int count, int hidden);

  /// No description provided for @torrentResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get torrentResume;

  /// No description provided for @torrentSavePathOptional.
  ///
  /// In en, this message translates to:
  /// **'Save Path (Optional)'**
  String get torrentSavePathOptional;

  /// No description provided for @torrentSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search torrents'**
  String get torrentSearchHint;

  /// No description provided for @torrentSectionActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get torrentSectionActions;

  /// No description provided for @torrentSectionInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get torrentSectionInformation;

  /// No description provided for @torrentSectionMediaLibrary.
  ///
  /// In en, this message translates to:
  /// **'Media Library'**
  String get torrentSectionMediaLibrary;

  /// No description provided for @torrentSectionProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get torrentSectionProgress;

  /// No description provided for @torrentSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select .torrent File'**
  String get torrentSelectFile;

  /// No description provided for @torrentSelectionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get torrentSelectionClear;

  /// No description provided for @torrentSetPriority.
  ///
  /// In en, this message translates to:
  /// **'Set Priority'**
  String get torrentSetPriority;

  /// No description provided for @torrentSortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get torrentSortAscending;

  /// No description provided for @torrentSortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get torrentSortDescending;

  /// No description provided for @torrentStartPaused.
  ///
  /// In en, this message translates to:
  /// **'Start Paused'**
  String get torrentStartPaused;

  /// No description provided for @torrentStatDlSpeed.
  ///
  /// In en, this message translates to:
  /// **'DL Speed'**
  String get torrentStatDlSpeed;

  /// No description provided for @torrentStatDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get torrentStatDownloaded;

  /// No description provided for @torrentStatLeechers.
  ///
  /// In en, this message translates to:
  /// **'Leechers'**
  String get torrentStatLeechers;

  /// No description provided for @torrentStatRatio.
  ///
  /// In en, this message translates to:
  /// **'Ratio'**
  String get torrentStatRatio;

  /// No description provided for @torrentStatSeedTime.
  ///
  /// In en, this message translates to:
  /// **'Seed Time'**
  String get torrentStatSeedTime;

  /// No description provided for @torrentStatSeeds.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get torrentStatSeeds;

  /// No description provided for @torrentStatTotalSize.
  ///
  /// In en, this message translates to:
  /// **'Total Size'**
  String get torrentStatTotalSize;

  /// No description provided for @torrentStatUlSpeed.
  ///
  /// In en, this message translates to:
  /// **'UL Speed'**
  String get torrentStatUlSpeed;

  /// No description provided for @torrentStatUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get torrentStatUploaded;

  /// No description provided for @torrentTagsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Comma separated'**
  String get torrentTagsCommaSeparated;

  /// No description provided for @torrentTagsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load tags. Using free text mode.'**
  String get torrentTagsLoadFailed;

  /// No description provided for @torrentTagsOptional.
  ///
  /// In en, this message translates to:
  /// **'Tags (Optional)'**
  String get torrentTagsOptional;

  /// No description provided for @torrentTagsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Type to search or add custom tags'**
  String get torrentTagsSearchHint;

  /// No description provided for @torrentTrackerDownloads.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 download} other{{count} downloads}}'**
  String torrentTrackerDownloads(int count);

  /// No description provided for @torrentTrackerLeechers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 leecher} other{{count} leechers}}'**
  String torrentTrackerLeechers(int count);

  /// No description provided for @torrentTrackerPeers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 peer} other{{count} peers}}'**
  String torrentTrackerPeers(int count);

  /// No description provided for @torrentTrackerSeeds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 seed} other{{count} seeds}}'**
  String torrentTrackerSeeds(int count);

  /// No description provided for @torrentTrackerTier.
  ///
  /// In en, this message translates to:
  /// **'Tier {tier}'**
  String torrentTrackerTier(int tier);

  /// No description provided for @torrentTrackers.
  ///
  /// In en, this message translates to:
  /// **'Trackers'**
  String get torrentTrackers;

  /// No description provided for @torrentUrlsHint.
  ///
  /// In en, this message translates to:
  /// **'Paste magnet links or HTTP URLs here\nOne per line'**
  String get torrentUrlsHint;

  /// No description provided for @torrentUrlsLabel.
  ///
  /// In en, this message translates to:
  /// **'Magnet Link or URLs'**
  String get torrentUrlsLabel;

  /// No description provided for @tourActivityBody.
  ///
  /// In en, this message translates to:
  /// **'Monitor your download queue, history, and qBittorrent torrents here.'**
  String get tourActivityBody;

  /// No description provided for @tourActivityQueueBody.
  ///
  /// In en, this message translates to:
  /// **'Active downloads report progress, size left, and estimated completion. Tap one for details and actions.'**
  String get tourActivityQueueBody;

  /// No description provided for @tourActivityQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Download queue'**
  String get tourActivityQueueTitle;

  /// No description provided for @tourAddInstanceBody.
  ///
  /// In en, this message translates to:
  /// **'Tap here to create a new server connection. The next steps walk through the form.'**
  String get tourAddInstanceBody;

  /// No description provided for @tourAddInstanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Instance'**
  String get tourAddInstanceTitle;

  /// No description provided for @tourCalendarBody.
  ///
  /// In en, this message translates to:
  /// **'Track upcoming movie releases and series episodes.'**
  String get tourCalendarBody;

  /// No description provided for @tourCalendarEventsBody.
  ///
  /// In en, this message translates to:
  /// **'Each card shows what airs or releases next, grouped by day and colour-coded by release type.'**
  String get tourCalendarEventsBody;

  /// No description provided for @tourCalendarEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming releases'**
  String get tourCalendarEventsTitle;

  /// No description provided for @tourInstanceApiKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Radarr/Sonarr require an API key from Settings → General. qBittorrent uses a Bearer token (v5.2.0+) or Basic Auth.'**
  String get tourInstanceApiKeyBody;

  /// No description provided for @tourInstanceApiKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get tourInstanceApiKeyTitle;

  /// No description provided for @tourInstanceNameBody.
  ///
  /// In en, this message translates to:
  /// **'A friendly label so you can tell your servers apart (e.g. \"Home Server\").'**
  String get tourInstanceNameBody;

  /// No description provided for @tourInstanceNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tourInstanceNameTitle;

  /// No description provided for @tourInstanceTypeBody.
  ///
  /// In en, this message translates to:
  /// **'Pick Radarr (movies), Sonarr (series), or qBittorrent (downloads). Each needs its own connection.'**
  String get tourInstanceTypeBody;

  /// No description provided for @tourInstanceTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the server type'**
  String get tourInstanceTypeTitle;

  /// No description provided for @tourInstanceUrlBody.
  ///
  /// In en, this message translates to:
  /// **'Your server address including http(s):// and port, e.g. http://192.168.1.10:7878.'**
  String get tourInstanceUrlBody;

  /// No description provided for @tourInstanceUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get tourInstanceUrlTitle;

  /// No description provided for @tourInstancesBody.
  ///
  /// In en, this message translates to:
  /// **'Your Radarr, Sonarr, and qBittorrent servers live here. Let\'s add your first one.'**
  String get tourInstancesBody;

  /// No description provided for @tourInstancesTitle.
  ///
  /// In en, this message translates to:
  /// **'Instances'**
  String get tourInstancesTitle;

  /// No description provided for @tourMockupBanner.
  ///
  /// In en, this message translates to:
  /// **'Sample content shown during the tour. It disappears once the tour ends.'**
  String get tourMockupBanner;

  /// No description provided for @tourMoviesLibraryBody.
  ///
  /// In en, this message translates to:
  /// **'Every movie Radarr manages shows up here with its monitoring and download status.'**
  String get tourMoviesLibraryBody;

  /// No description provided for @tourMoviesLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your movie library'**
  String get tourMoviesLibraryTitle;

  /// No description provided for @tourMoviesSearchBody.
  ///
  /// In en, this message translates to:
  /// **'Find movies in your library by title.'**
  String get tourMoviesSearchBody;

  /// No description provided for @tourMoviesSortBody.
  ///
  /// In en, this message translates to:
  /// **'Reorder and filter your library to browse faster.'**
  String get tourMoviesSortBody;

  /// No description provided for @tourMoviesSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort & Filter'**
  String get tourMoviesSortTitle;

  /// No description provided for @tourNavigationBody.
  ///
  /// In en, this message translates to:
  /// **'Switch between Movies, Series, Calendar, Activity, and Settings anytime.'**
  String get tourNavigationBody;

  /// No description provided for @tourNavigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get tourNavigationTitle;

  /// No description provided for @tourSaveInstanceBody.
  ///
  /// In en, this message translates to:
  /// **'When everything checks out, save to finish setup. You can add the other servers any time from Settings.'**
  String get tourSaveInstanceBody;

  /// No description provided for @tourSaveInstanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Instance'**
  String get tourSaveInstanceTitle;

  /// No description provided for @tourSeriesLibraryBody.
  ///
  /// In en, this message translates to:
  /// **'Your Sonarr series live here, with season counts and how much of each show is already downloaded.'**
  String get tourSeriesLibraryBody;

  /// No description provided for @tourSeriesLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your series library'**
  String get tourSeriesLibraryTitle;

  /// No description provided for @tourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tourSkip;

  /// No description provided for @tourTestConnectionBody.
  ///
  /// In en, this message translates to:
  /// **'Verifies the URL and credentials before saving.'**
  String get tourTestConnectionBody;

  /// No description provided for @tourTestConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get tourTestConnectionTitle;

  /// No description provided for @tourTorrentsBody.
  ///
  /// In en, this message translates to:
  /// **'Torrents from qBittorrent report live speed, ratio, and peers, with pause, resume, and import actions.'**
  String get tourTorrentsBody;

  /// No description provided for @tourTorrentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Torrents'**
  String get tourTorrentsTitle;

  /// No description provided for @updateAndRestart.
  ///
  /// In en, this message translates to:
  /// **'Update and restart'**
  String get updateAndRestart;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'New Version Available'**
  String get updateAvailableTitle;

  /// No description provided for @updateChangelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog:'**
  String get updateChangelog;

  /// No description provided for @updateDownloadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading Update'**
  String get updateDownloadingTitle;

  /// No description provided for @updateInstallingTitle.
  ///
  /// In en, this message translates to:
  /// **'Installing...'**
  String get updateInstallingTitle;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @updatePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the update...'**
  String get updatePreparing;

  /// No description provided for @updateRestartNotice.
  ///
  /// In en, this message translates to:
  /// **'The app will close and restart to finish the update.'**
  String get updateRestartNotice;

  /// No description provided for @updateUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get updateUnexpectedError;

  /// No description provided for @updateVersion.
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String updateVersion(String version);

  /// No description provided for @versionHistoryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Release history could not be loaded.'**
  String get versionHistoryEmptySubtitle;

  /// No description provided for @versionHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No releases available'**
  String get versionHistoryEmptyTitle;

  /// No description provided for @versionHistoryInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get versionHistoryInstalled;

  /// No description provided for @versionHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load version history: {error}'**
  String versionHistoryLoadFailed(String error);

  /// No description provided for @versionHistoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading version history...'**
  String get versionHistoryLoading;

  /// No description provided for @versionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Version History'**
  String get versionHistoryTitle;

  /// No description provided for @watchingContinueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get watchingContinueWatching;

  /// No description provided for @watchingEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Media you pause in Jellyfin and the next episodes of series you follow will appear here.'**
  String get watchingEmptySubtitle;

  /// No description provided for @watchingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing in progress'**
  String get watchingEmptyTitle;

  /// No description provided for @watchingLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading continue watching...'**
  String get watchingLoading;

  /// No description provided for @watchingNextEpisode.
  ///
  /// In en, this message translates to:
  /// **'Next episode'**
  String get watchingNextEpisode;

  /// No description provided for @watchingNextEpisodeRuntime.
  ///
  /// In en, this message translates to:
  /// **'Next episode · {runtime}'**
  String watchingNextEpisodeRuntime(String runtime);

  /// No description provided for @watchingNextUp.
  ///
  /// In en, this message translates to:
  /// **'Next Up'**
  String get watchingNextUp;

  /// No description provided for @whatsNewNoNotes.
  ///
  /// In en, this message translates to:
  /// **'This release does not include release notes.'**
  String get whatsNewNoNotes;

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s New in v{version}'**
  String whatsNewTitle(String version);

  /// No description provided for @whatsNewViewAllVersions.
  ///
  /// In en, this message translates to:
  /// **'View All Versions'**
  String get whatsNewViewAllVersions;

  /// No description provided for @widgetsClosePoster.
  ///
  /// In en, this message translates to:
  /// **'Close poster'**
  String get widgetsClosePoster;

  /// No description provided for @widgetsCustomFormatScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String widgetsCustomFormatScore(String score);

  /// No description provided for @widgetsDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get widgetsDeleteFile;

  /// No description provided for @widgetsEventAdditionalData.
  ///
  /// In en, this message translates to:
  /// **'Additional Data'**
  String get widgetsEventAdditionalData;

  /// No description provided for @widgetsEventDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get widgetsEventDate;

  /// No description provided for @widgetsEventDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get widgetsEventDetailsTitle;

  /// No description provided for @widgetsEventSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Source Title'**
  String get widgetsEventSourceTitle;

  /// No description provided for @widgetsEventType.
  ///
  /// In en, this message translates to:
  /// **'Event Type'**
  String get widgetsEventType;

  /// No description provided for @widgetsExtraFileMetadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get widgetsExtraFileMetadata;

  /// No description provided for @widgetsExtraFileOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get widgetsExtraFileOther;

  /// No description provided for @widgetsExtraFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get widgetsExtraFileSubtitle;

  /// No description provided for @widgetsFileAudioBitrate.
  ///
  /// In en, this message translates to:
  /// **'Audio Bitrate'**
  String get widgetsFileAudioBitrate;

  /// No description provided for @widgetsFileAudioChannels.
  ///
  /// In en, this message translates to:
  /// **'Audio Channels'**
  String get widgetsFileAudioChannels;

  /// No description provided for @widgetsFileAudioCodec.
  ///
  /// In en, this message translates to:
  /// **'Audio Codec'**
  String get widgetsFileAudioCodec;

  /// No description provided for @widgetsFileAudioLanguages.
  ///
  /// In en, this message translates to:
  /// **'Audio Languages'**
  String get widgetsFileAudioLanguages;

  /// No description provided for @widgetsFileAudioStreams.
  ///
  /// In en, this message translates to:
  /// **'Audio Streams'**
  String get widgetsFileAudioStreams;

  /// No description provided for @widgetsFileBitDepth.
  ///
  /// In en, this message translates to:
  /// **'Bit Depth'**
  String get widgetsFileBitDepth;

  /// No description provided for @widgetsFileCustomFormats.
  ///
  /// In en, this message translates to:
  /// **'Custom Formats'**
  String get widgetsFileCustomFormats;

  /// No description provided for @widgetsFileDateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get widgetsFileDateAdded;

  /// No description provided for @widgetsFileDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'File Details'**
  String get widgetsFileDetailsTitle;

  /// No description provided for @widgetsFileDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get widgetsFileDuration;

  /// No description provided for @widgetsFileDynamicRange.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Range'**
  String get widgetsFileDynamicRange;

  /// No description provided for @widgetsFileFrameRate.
  ///
  /// In en, this message translates to:
  /// **'Frame Rate'**
  String get widgetsFileFrameRate;

  /// No description provided for @widgetsFileGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get widgetsFileGeneral;

  /// No description provided for @widgetsFileHdrType.
  ///
  /// In en, this message translates to:
  /// **'HDR Type'**
  String get widgetsFileHdrType;

  /// No description provided for @widgetsFileMediaInfo.
  ///
  /// In en, this message translates to:
  /// **'Media Info'**
  String get widgetsFileMediaInfo;

  /// No description provided for @widgetsFilePath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get widgetsFilePath;

  /// No description provided for @widgetsFileResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get widgetsFileResolution;

  /// No description provided for @widgetsFileRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision'**
  String get widgetsFileRevision;

  /// No description provided for @widgetsFileScanType.
  ///
  /// In en, this message translates to:
  /// **'Scan Type'**
  String get widgetsFileScanType;

  /// No description provided for @widgetsFileSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get widgetsFileSource;

  /// No description provided for @widgetsFileSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get widgetsFileSubtitles;

  /// No description provided for @widgetsFileVideoBitrate.
  ///
  /// In en, this message translates to:
  /// **'Video Bitrate'**
  String get widgetsFileVideoBitrate;

  /// No description provided for @widgetsFileVideoCodec.
  ///
  /// In en, this message translates to:
  /// **'Video Codec'**
  String get widgetsFileVideoCodec;

  /// No description provided for @widgetsNoPreviousOnline.
  ///
  /// In en, this message translates to:
  /// **'No previous online connection recorded'**
  String get widgetsNoPreviousOnline;

  /// No description provided for @widgetsNoTagsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tags available'**
  String get widgetsNoTagsAvailable;

  /// No description provided for @widgetsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get widgetsNotifications;

  /// No description provided for @widgetsOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get widgetsOffline;

  /// No description provided for @widgetsOfflineCacheCaveat.
  ///
  /// In en, this message translates to:
  /// **'{lastOnline} · Cached images may be up to {days, plural, other{{days} days}} old'**
  String widgetsOfflineCacheCaveat(String lastOnline, int days);

  /// No description provided for @widgetsPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get widgetsPlay;

  /// No description provided for @widgetsQueueDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get widgetsQueueDownloadFailed;

  /// No description provided for @widgetsQueueDownloadPaused.
  ///
  /// In en, this message translates to:
  /// **'Download paused'**
  String get widgetsQueueDownloadPaused;

  /// No description provided for @widgetsQueueDownloadPending.
  ///
  /// In en, this message translates to:
  /// **'Download pending'**
  String get widgetsQueueDownloadPending;

  /// No description provided for @widgetsQueueDownloadWarning.
  ///
  /// In en, this message translates to:
  /// **'Download warning'**
  String get widgetsQueueDownloadWarning;

  /// No description provided for @widgetsQueueStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Status unknown'**
  String get widgetsQueueStatusUnknown;

  /// No description provided for @widgetsSelectInstance.
  ///
  /// In en, this message translates to:
  /// **'Select {type} instance'**
  String widgetsSelectInstance(String type);

  /// No description provided for @widgetsSelectTags.
  ///
  /// In en, this message translates to:
  /// **'Select Tags'**
  String get widgetsSelectTags;

  /// No description provided for @widgetsSomeInstancesFailed.
  ///
  /// In en, this message translates to:
  /// **'Some instances could not be loaded'**
  String get widgetsSomeInstancesFailed;

  /// No description provided for @widgetsSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get widgetsSortBy;

  /// No description provided for @widgetsSortOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get widgetsSortOrder;

  /// No description provided for @widgetsTagButtonWithCount.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String widgetsTagButtonWithCount(String label, int count);

  /// No description provided for @widgetsUnknownFile.
  ///
  /// In en, this message translates to:
  /// **'Unknown File'**
  String get widgetsUnknownFile;
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
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
