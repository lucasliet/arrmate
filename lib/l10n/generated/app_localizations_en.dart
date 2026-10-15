// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appInitErrorTitle => 'Initialization Error';

  @override
  String get appInitNotificationServicesFailed =>
      'Failed to initialize notification services. Some features may not work correctly.';

  @override
  String get appTitle => 'Arrmate';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonAutomaticSearch => 'Automatic Search';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonClearFilters => 'Clear filters';

  @override
  String get commonClient => 'Client';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDeleteFiles => 'Delete files';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get commonEdit => 'Edit';

  @override
  String commonErrorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get commonFilter => 'Filter';

  @override
  String get commonImport => 'Import';

  @override
  String get commonIndexer => 'Indexer';

  @override
  String get commonInteractiveSearch => 'Interactive Search';

  @override
  String get commonLanguage => 'Language';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonMonitor => 'Monitor';

  @override
  String get commonMonitored => 'Monitored';

  @override
  String get commonMovies => 'Movies';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonOpenExternally => 'Open externally';

  @override
  String get commonOpenInLibrary => 'Open in library';

  @override
  String get commonProtocol => 'Protocol';

  @override
  String get commonPurge => 'Purge';

  @override
  String get commonQuality => 'Quality';

  @override
  String get commonQualityProfile => 'Quality Profile';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonRestore => 'Restore';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonRootFolder => 'Root Folder';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonSearchStarted => 'Search started';

  @override
  String get commonSelectAll => 'Select all';

  @override
  String get commonSeries => 'Series';

  @override
  String get commonSize => 'Size';

  @override
  String get commonSort => 'Sort';

  @override
  String get commonSortBy => 'Sort by';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonTags => 'Tags';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonUnmonitor => 'Unmonitor';

  @override
  String get commonUnmonitored => 'Unmonitored';

  @override
  String get commonWatchInJellyfin => 'Watch in Jellyfin';

  @override
  String get commonYes => 'Yes';

  @override
  String get errorConnectionFailed =>
      'Connection failed. Please check your network.';

  @override
  String errorInvalidUrl(String url) {
    return 'Invalid URL: $url';
  }

  @override
  String get errorNotFound => 'Resource not found.';

  @override
  String get errorRequestCancelled => 'Request cancelled';

  @override
  String get errorRequestTimedOut => 'Request timed out. Please try again.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorUnauthorized => 'Unauthorized. Please check your API key.';

  @override
  String get errorUnknown => 'An unknown error occurred.';

  @override
  String get errorValidationFailed => 'Validation failed.';

  @override
  String formatDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String formatHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String get formatJustNow => 'Just now';

  @override
  String formatLastOnline(String time) {
    return 'Last online $time';
  }

  @override
  String formatMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String formatMonthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String formatSeason(int number) {
    return 'Season $number';
  }

  @override
  String formatSeasonEpisode(int season, int episode) {
    return 'Season $season, Episode $episode';
  }

  @override
  String formatTitleWithSeason(String title, int season) {
    return '$title (Season $season)';
  }

  @override
  String formatWeeksAgo(int count) {
    return '${count}w ago';
  }

  @override
  String formatYearsAgo(int count) {
    return '${count}y ago';
  }

  @override
  String get formatYesterday => 'Yesterday';

  @override
  String get labelAll => 'All';

  @override
  String get labelAppearanceDark => 'Dark';

  @override
  String get labelAppearanceLight => 'Light';

  @override
  String get labelAppearanceSystem => 'System';

  @override
  String get labelCalendarAllMedia => 'All media';

  @override
  String get labelCalendarUnknownMovie => 'Unknown Movie';

  @override
  String get labelCalendarUnknownSeries => 'Unknown Series';

  @override
  String get labelColorAmber => 'Amber';

  @override
  String get labelColorBlue => 'Blue';

  @override
  String get labelColorGreen => 'Green';

  @override
  String get labelColorIndigo => 'Indigo';

  @override
  String get labelColorOrange => 'Orange';

  @override
  String get labelColorPink => 'Pink';

  @override
  String get labelColorPurple => 'Purple';

  @override
  String get labelColorRed => 'Red';

  @override
  String get labelColorTeal => 'Teal';

  @override
  String get labelDangling => 'Dangling';

  @override
  String get labelDeleted => 'Deleted';

  @override
  String get labelDigitalRelease => 'Digital Release';

  @override
  String get labelDiscoverySortLatest => 'Latest';

  @override
  String get labelDiscoverySortRelevant => 'Relevant';

  @override
  String get labelDownloaded => 'Downloaded';

  @override
  String get labelDownloading => 'Downloading';

  @override
  String get labelEpisode => 'Episode';

  @override
  String get labelError => 'Error';

  @override
  String get labelFailed => 'Failed';

  @override
  String get labelFilePriorityDoNotDownload => 'Do Not Download';

  @override
  String get labelFilePriorityHigh => 'High Priority';

  @override
  String get labelFilePriorityLow => 'Low Priority';

  @override
  String get labelFilePriorityMaximal => 'Maximal Priority';

  @override
  String get labelFilePriorityNormal => 'Normal Priority';

  @override
  String get labelFilterAllMovies => 'All Movies';

  @override
  String get labelFilterAllSeries => 'All Series';

  @override
  String get labelGrabbed => 'Grabbed';

  @override
  String get labelHistoryDeletedGeneric => 'File was deleted.';

  @override
  String get labelHistoryDeletedManual =>
      'File was deleted manually or by a client through the API.';

  @override
  String get labelHistoryDeletedMissingFromDisk =>
      'File was not found on disk so it was unlinked from the database.';

  @override
  String get labelHistoryDeletedUpgrade =>
      'File was deleted to import an upgrade.';

  @override
  String get labelHistoryDownloadFailedDescription => 'Download failed.';

  @override
  String get labelHistoryDownloadIgnoredDescription => 'Download ignored.';

  @override
  String labelHistoryEpisodeGrabbed(String indexer, String client) {
    return 'Episode grabbed from $indexer and sent to $client.';
  }

  @override
  String labelHistoryEpisodeImported(String client) {
    return 'Episode downloaded successfully and imported from $client.';
  }

  @override
  String get labelHistoryEpisodeRenamed => 'Episode file was renamed.';

  @override
  String get labelHistoryFallbackClient => 'download client';

  @override
  String get labelHistoryFallbackIndexer => 'indexer';

  @override
  String get labelHistoryIgnored => 'Ignored';

  @override
  String get labelHistoryImported => 'Imported';

  @override
  String labelHistoryMovieGrabbed(String indexer, String client) {
    return 'Movie grabbed from $indexer and sent to $client.';
  }

  @override
  String labelHistoryMovieImported(String client) {
    return 'Movie downloaded successfully and imported from $client.';
  }

  @override
  String get labelHistoryMovieRenamed => 'Movie file was renamed.';

  @override
  String get labelHistoryRenamed => 'Renamed';

  @override
  String get labelHistoryTitleDeleted => 'File Deleted';

  @override
  String get labelHistoryTitleFailed => 'Download Failed';

  @override
  String get labelHistoryTitleGrabbed => 'Release Grabbed';

  @override
  String get labelHistoryTitleIgnored => 'Download Ignored';

  @override
  String get labelHistoryTitleImported => 'Folder Imported';

  @override
  String get labelHistoryTitleRenamed => 'File Renamed';

  @override
  String get labelHistoryTitleUnknown => 'Unknown Event';

  @override
  String get labelHistoryUnknownEventDescription => 'Unknown event.';

  @override
  String get labelInCinemas => 'In Cinemas';

  @override
  String get labelMissing => 'Missing';

  @override
  String get labelMovieMonitorMovieAndCollection => 'Movie + Collection';

  @override
  String get labelMovieMonitorMovieOnly => 'Movie';

  @override
  String get labelMovieStateUnreleased => 'Unreleased';

  @override
  String get labelMovieStateUnwanted => 'Unwanted';

  @override
  String get labelMovieStateWaiting => 'Waiting';

  @override
  String get labelMovieStatusAnnounced => 'Announced';

  @override
  String get labelMovieStatusReleased => 'Released';

  @override
  String get labelMovieStatusTba => 'Unannounced';

  @override
  String get labelNone => 'None';

  @override
  String get labelPaused => 'Paused';

  @override
  String get labelPhysicalRelease => 'Physical Release';

  @override
  String get labelQueueCompleted => 'Completed';

  @override
  String get labelQueuePending => 'Pending';

  @override
  String get labelQueueWarning => 'Warning';

  @override
  String get labelQueued => 'Queued';

  @override
  String get labelSeeding => 'Seeding';

  @override
  String get labelSeriesMonitorAll => 'All Episodes';

  @override
  String get labelSeriesMonitorExisting => 'Existing Episodes';

  @override
  String get labelSeriesMonitorFirstSeason => 'First Season';

  @override
  String get labelSeriesMonitorFuture => 'Future Episodes';

  @override
  String get labelSeriesMonitorLastSeason => 'Last Season';

  @override
  String get labelSeriesMonitorMissing => 'Missing Episodes';

  @override
  String get labelSeriesMonitorPilot => 'Pilot Episode';

  @override
  String get labelSeriesMonitorRecent => 'Recent Episodes';

  @override
  String get labelSeriesMonitorSpecials => 'Monitor Specials';

  @override
  String get labelSeriesStatusContinuing => 'Continuing';

  @override
  String get labelSeriesStatusEnded => 'Ended';

  @override
  String get labelSeriesStatusUpcoming => 'Upcoming';

  @override
  String get labelSeriesTypeAnime => 'Anime';

  @override
  String get labelSeriesTypeDaily => 'Daily';

  @override
  String get labelSeriesTypeStandard => 'Standard';

  @override
  String get labelSeriesUnmonitorSpecials => 'Unmonitor Specials';

  @override
  String get labelSortAdded => 'Added';

  @override
  String get labelSortNextAiring => 'Next Airing';

  @override
  String get labelSortPreviousAiring => 'Previous Airing';

  @override
  String get labelSortRating => 'Rating';

  @override
  String get labelSortRuntime => 'Runtime';

  @override
  String get labelSortTitle => 'Title';

  @override
  String get labelSortYear => 'Year';

  @override
  String get labelSpecials => 'Specials';

  @override
  String get labelTabActivity => 'Activity';

  @override
  String get labelTabCalendar => 'Calendar';

  @override
  String get labelTabSettings => 'Settings';

  @override
  String get labelTba => 'TBA';

  @override
  String get labelTorrentChecking => 'Checking';

  @override
  String get labelTorrentLinkExternal => 'Not in library';

  @override
  String get labelTorrentLinkExternalDescription =>
      'This torrent was downloaded outside the media library.';

  @override
  String get labelTorrentLinkFileMissing => 'File removed';

  @override
  String get labelTorrentLinkFileMissingDescription =>
      'The catalog item still exists, but its media file was deleted.';

  @override
  String get labelTorrentLinkLinked => 'In library';

  @override
  String get labelTorrentLinkLinkedDescription =>
      'This torrent backs an item that is still in the media library.';

  @override
  String get labelTorrentLinkOrphan => 'Orphan';

  @override
  String get labelTorrentLinkOrphanDescription =>
      'Radarr/Sonarr downloaded this torrent, but the catalog item is gone. Only the torrent is left.';

  @override
  String get labelTorrentLinkUnknownDescription =>
      'The library relation could not be determined.';

  @override
  String get labelTorrentMissingFiles => 'Missing Files';

  @override
  String get labelTorrentPausedDl => 'Paused (DL)';

  @override
  String get labelTorrentPausedUp => 'Paused (UP)';

  @override
  String get labelTorrentQueuedDl => 'Queued (DL)';

  @override
  String get labelTorrentQueuedUp => 'Queued (UP)';

  @override
  String get labelTorrentSortActivity => 'Activity';

  @override
  String get labelTorrentSortAddedDate => 'Added date';

  @override
  String get labelTorrentSortDownloadSpeed => 'Download speed';

  @override
  String get labelTorrentSortName => 'Name';

  @override
  String get labelTorrentSortProgress => 'Progress';

  @override
  String get labelTorrentSortRatio => 'Ratio';

  @override
  String get labelTorrentSortSeedTime => 'Seed time';

  @override
  String get labelTorrentStalledDl => 'Stalled (DL)';

  @override
  String get labelTorrentStalledUp => 'Stalled (UP)';

  @override
  String get labelTrackerDisabled => 'Disabled';

  @override
  String get labelTrackerNotContacted => 'Not contacted';

  @override
  String get labelTrackerNotWorking => 'Not working';

  @override
  String get labelTrackerUpdating => 'Updating';

  @override
  String get labelTrackerWorking => 'Working';

  @override
  String get labelUnnamedFile => 'an unnamed file';

  @override
  String get labelViewModeGrid => 'Grid';

  @override
  String get labelViewModeList => 'List';

  @override
  String get labelWanted => 'Wanted';

  @override
  String get languagePromptSubtitle => 'You can change it later in Settings.';

  @override
  String get languagePromptTitle => 'Choose your language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSelectLanguage => 'Select Language';
}
