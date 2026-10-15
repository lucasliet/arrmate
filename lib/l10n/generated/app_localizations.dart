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

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsSelectLanguage;
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
