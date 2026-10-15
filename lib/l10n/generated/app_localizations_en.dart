// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get activityTabHistory => 'History';

  @override
  String get activityTabQueue => 'Queue';

  @override
  String get activityTabTorrents => 'Torrents';

  @override
  String get activityTabWatching => 'Watching';

  @override
  String get appInitErrorTitle => 'Initialization Error';

  @override
  String get appInitNotificationServicesFailed =>
      'Failed to initialize notification services. Some features may not work correctly.';

  @override
  String get appTitle => 'Arrmate';

  @override
  String get appleIntelligenceAssetsUnavailable =>
      'The Apple Intelligence model is not ready yet. Try again later.';

  @override
  String get appleIntelligenceBusy =>
      'Apple Intelligence is busy. Try again in a moment.';

  @override
  String get appleIntelligenceContextTooLong =>
      'The question is too long for Apple Intelligence. Try a shorter one.';

  @override
  String get appleIntelligenceDeclined =>
      'Apple Intelligence declined to answer. Try rephrasing the question.';

  @override
  String get appleIntelligenceDeviceNotEligible =>
      'This device does not support Apple Intelligence.';

  @override
  String get appleIntelligenceGenerationFailed =>
      'Apple Intelligence failed to generate a response.';

  @override
  String get appleIntelligenceModelNotReady =>
      'The Apple Intelligence model is still downloading. Try again later.';

  @override
  String get appleIntelligenceNotEnabled =>
      'Turn on Apple Intelligence in the system settings.';

  @override
  String get appleIntelligenceUnavailable =>
      'Apple Intelligence is unavailable on this device.';

  @override
  String get appleIntelligenceUnsupportedLanguage =>
      'Apple Intelligence does not support this language on this device.';

  @override
  String get appleIntelligenceUnsupportedOs =>
      'Apple Intelligence requires iOS 26 or macOS 26.';

  @override
  String get assistantCloud => 'Cloud';

  @override
  String assistantDeleteModelContent(String model) {
    return 'Remove \"$model\" from your device?';
  }

  @override
  String get assistantDeleteModelTitle => 'Delete Model';

  @override
  String get assistantDownloadModel => 'Download Model';

  @override
  String get assistantDownloadingModel => 'Downloading Model';

  @override
  String get assistantEmptyPrompt => 'Ask about the app';

  @override
  String get assistantInputHint => 'Ask about Arrmate...';

  @override
  String get assistantInstalled => 'Installed';

  @override
  String get assistantLinkNotOpened => 'The link could not be opened';

  @override
  String get assistantLocalModels => 'Local Models';

  @override
  String get assistantNoLocalModel => 'No local model selected';

  @override
  String get assistantOnDeviceModel => 'On-device model';

  @override
  String get assistantOnlineModel => 'Online model';

  @override
  String get assistantOnlyHttpsLinks => 'Only HTTPS links are supported';

  @override
  String assistantOpenLinkFailed(String error) {
    return 'Unable to open link: $error';
  }

  @override
  String get assistantSelectModelFirst => 'Select a model first';

  @override
  String get assistantStartingDownload => 'Starting download...';

  @override
  String get assistantSwitchModel => 'Switch Model';

  @override
  String get assistantTitle => 'Assistant';

  @override
  String get assistantUseCloud => 'Use Cloud';

  @override
  String get assistantUseCloudOrLocal =>
      'Use Cloud or import/download a local model';

  @override
  String backupAppVersion(String version) {
    return 'App version: $version';
  }

  @override
  String get backupAutomaticNote =>
      'Automatic backups run about 30 seconds after you change instances or settings, while signed in. Some settings (like the home tab) apply fully after restarting the app.';

  @override
  String backupCreated(String time) {
    return 'Created: $time';
  }

  @override
  String get backupDriveDescription =>
      'Your settings, preferences and configured instances (including their API keys) are stored in the app\'s private folder on your Google Drive, invisible to other apps.';

  @override
  String get backupDriveTitle => 'Google Drive backup';

  @override
  String get backupDriveUnavailableMessage =>
      'This build was compiled without Google credentials. Ask the developer to build with the Google OAuth configuration, or run locally with the --dart-define flags. Use the local file backup below instead.';

  @override
  String get backupDriveUnavailableTitle => 'Google Drive backup not available';

  @override
  String get backupExportToFile => 'Export backup to file';

  @override
  String get backupExportToFileSubtitle => 'Save a .json copy on this device';

  @override
  String backupExported(String fileName) {
    return 'Backup exported to $fileName';
  }

  @override
  String backupFoundMessage(String time) {
    return 'Saved $time. Restore it to bring its settings and instances to this device. Automatic backups stay paused until you restore or back up manually.';
  }

  @override
  String get backupFoundTitle => 'Backup found in your Google Drive';

  @override
  String backupInstanceCount(int count) {
    return 'Instances: $count';
  }

  @override
  String backupLastBackup(String time) {
    return 'Last backup: $time';
  }

  @override
  String get backupNever => 'never';

  @override
  String get backupNow => 'Back up now';

  @override
  String backupPlatform(String platform) {
    return 'Platform: $platform';
  }

  @override
  String get backupRestoreBackupMenu => 'Restore backup…';

  @override
  String get backupRestoreConfirmTitle => 'Restore backup?';

  @override
  String get backupRestoreFailed => 'Restore failed';

  @override
  String get backupRestoreFromFile => 'Restore from file…';

  @override
  String get backupRestoreReplaceWarning =>
      'This replaces the settings and instances currently on this device.';

  @override
  String get backupRestored => 'Backup restored';

  @override
  String get backupSignInWithGoogle => 'Sign in with Google';

  @override
  String get backupSignOut => 'Sign out';

  @override
  String get backupTitle => 'Backup & Restore';

  @override
  String get calendarAnyInstance => 'Any instance';

  @override
  String get calendarDataLoadFailed => 'Calendar data could not be loaded.';

  @override
  String get calendarFilterByInstance => 'Filter by instance';

  @override
  String get calendarFilterByMediaType => 'Filter by media type';

  @override
  String get calendarHideSpecials => 'Hide specials';

  @override
  String get calendarInstanceAny => 'Instance: Any';

  @override
  String calendarInstanceNamed(String name) {
    return 'Instance: $name';
  }

  @override
  String get calendarLoadMore => 'Load more';

  @override
  String get calendarLoading => 'Loading calendar...';

  @override
  String get calendarNoMatchingEvents => 'No matching events';

  @override
  String get calendarNoMatchingEventsHint =>
      'Adjust the calendar filters to see more events.';

  @override
  String get calendarNoUpcomingEvents => 'No upcoming events';

  @override
  String get calendarNoUpcomingEventsHint =>
      'Check back later or add content to your libraries.';

  @override
  String calendarOpenItemFailed(String error) {
    return 'Unable to open item: $error';
  }

  @override
  String get calendarPremieres => 'Premieres';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarTomorrow => 'Tomorrow';

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
  String coreGoogleSignInAccountLoadFailed(String status) {
    return 'Google sign-in failed: the account could not be loaded (status $status).';
  }

  @override
  String get coreGoogleSignInBrowserFailed =>
      'The sign-in browser could not be opened. Please try again.';

  @override
  String get coreGoogleSignInCancelled =>
      'Google sign-in was cancelled before it finished.';

  @override
  String get coreGoogleSignInConsentDenied =>
      'Google sign-in was cancelled: consent was denied.';

  @override
  String get coreGoogleSignInIncompleteToken =>
      'Google sign-in failed: the token response was incomplete.';

  @override
  String coreGoogleSignInNetworkError(String status) {
    return 'Google sign-in failed: network or server error (status $status).';
  }

  @override
  String get coreGoogleSignInNoCode =>
      'Google sign-in failed: no authorization code was returned.';

  @override
  String get coreGoogleSignInNoEmail =>
      'Google sign-in failed: the account has no e-mail.';

  @override
  String coreGoogleSignInProviderError(String reason) {
    return 'Google sign-in failed: $reason';
  }

  @override
  String get coreGoogleSignInRedirectUnverified =>
      'Google sign-in failed: the redirect could not be verified.';

  @override
  String coreGoogleSignInServerStatus(String status) {
    return 'Google sign-in failed: the server returned status $status.';
  }

  @override
  String get coreGoogleSignInStatusUnavailable => 'unavailable';

  @override
  String get coreGoogleSignInTimedOut =>
      'Google sign-in timed out. Please try again.';

  @override
  String get coreGoogleSignInUnavailableOnWeb =>
      'Google sign-in is not available on the web.';

  @override
  String get corePurgeNotificationTitle => 'Purged torrent';

  @override
  String corePurgeNotificationTitleSeason(int season) {
    return 'Purged torrent (season $season)';
  }

  @override
  String corePurgeSummaryMediaFiles(int count) {
    return 'Media files: $count';
  }

  @override
  String get corePurgeSummaryQbittorrentSkipped =>
      'qBittorrent skipped — configure a qBittorrent instance.';

  @override
  String corePurgeSummaryQueueItems(int count) {
    return 'Queue items: $count';
  }

  @override
  String corePurgeSummaryTorrents(int count) {
    return 'Torrents: $count';
  }

  @override
  String corePurgeSummaryTorrentsWithCrossSeed(int count, int crossSeed) {
    return 'Torrents: $count (+$crossSeed cross-seed)';
  }

  @override
  String get coreUpdateArchiveMissingFiles =>
      'The update archive is missing required application files.';

  @override
  String get coreUpdateArchiveTooLarge =>
      'The update archive exceeds its extraction limits.';

  @override
  String get coreUpdateArchiveUnsafeLink =>
      'The update archive contains an unsafe symbolic link.';

  @override
  String get coreUpdateArchiveUnsafePath =>
      'The update archive contains an unsafe path.';

  @override
  String get coreUpdateArchiveWritesThroughLink =>
      'The update archive writes through a symbolic link.';

  @override
  String get coreUpdateCheckFailed =>
      'Could not check for updates. Please try again.';

  @override
  String get coreUpdateInstallerNotStarted =>
      'The update installer could not start. The app has not been changed.';

  @override
  String get coreUpdateLinuxRequiresAppImage =>
      'Automatic Linux updates require the AppImage. Download and run the AppImage release first.';

  @override
  String get coreUpdateMacBundleRequired =>
      'Run the installed Arrmate.app bundle to update it.';

  @override
  String get coreUpdateNotAppImage => 'The update is not an x64 AppImage.';

  @override
  String coreUpdateOtaFailed(String status) {
    return 'Update failed: $status';
  }

  @override
  String coreUpdatePrepareFailed(String tool) {
    return 'Could not prepare the update package ($tool).';
  }

  @override
  String get coreUpdateReadOnlyFolder =>
      'The application folder is read-only. Move Arrmate to a folder writable by your user and try again.';

  @override
  String get coreUpdateUnverifiedPackage =>
      'The release does not contain a verified package for this platform.';

  @override
  String get coreUpdateVerificationFailed =>
      'The update failed its size or SHA-256 verification.';

  @override
  String get coreUpdateVersionMismatch =>
      'The downloaded application version does not match the release.';

  @override
  String get coreUpdateWindowsIncomplete =>
      'Run Arrmate from the complete Windows release directory to update it.';

  @override
  String diagnosticsCheckFailed(String error) {
    return 'Failed · $error';
  }

  @override
  String diagnosticsCheckOk(int ms) {
    return 'OK · ${ms}ms';
  }

  @override
  String diagnosticsCheckOkWithVersion(int ms, String version) {
    return 'OK · ${ms}ms · v$version';
  }

  @override
  String get diagnosticsChecking => 'Checking configured endpoints...';

  @override
  String get diagnosticsEndpointActive => 'Active endpoint';

  @override
  String get diagnosticsEndpointAlternative => 'Alternative endpoint';

  @override
  String get diagnosticsEndpointAlternativeActive =>
      'Alternative endpoint · Active';

  @override
  String get diagnosticsEndpointConnectivity => 'Endpoint connectivity';

  @override
  String get diagnosticsEndpointPrimary => 'Primary endpoint';

  @override
  String get diagnosticsEndpointPrimaryActive => 'Primary endpoint · Active';

  @override
  String get diagnosticsEndpointsAvailable => 'Endpoints available';

  @override
  String get diagnosticsEndpointsUnavailable => 'Endpoints unavailable';

  @override
  String diagnosticsExportFailed(String error) {
    return 'Failed to export report: $error';
  }

  @override
  String get diagnosticsExportReport => 'Export report';

  @override
  String diagnosticsGenerated(String date) {
    return 'Generated $date';
  }

  @override
  String diagnosticsInterfaces(String interfaces) {
    return 'Interfaces: $interfaces';
  }

  @override
  String get diagnosticsNetworkAvailable => 'Network available';

  @override
  String get diagnosticsNoInstances =>
      'No Radarr, Sonarr, or qBittorrent instances are configured.';

  @override
  String get diagnosticsNoNetworkInterface => 'No network interface';

  @override
  String get diagnosticsNoRecentRequests => 'No recent requests recorded.';

  @override
  String get diagnosticsPurposeBody =>
      'Tests every configured endpoint for reachability and latency, shows recent request traces, and exports a sanitized report. Health shows alerts reported by Radarr and Sonarr.';

  @override
  String get diagnosticsPurposeTitle => 'Connection troubleshooting';

  @override
  String get diagnosticsRecentRequests => 'Recent request traces';

  @override
  String get diagnosticsRefreshing => 'Refreshing endpoint checks...';

  @override
  String get diagnosticsRunAgain => 'Run connection checks again';

  @override
  String diagnosticsRunFailed(String error) {
    return 'Failed to run connection diagnostics: $error';
  }

  @override
  String get diagnosticsSomeEndpointsUnavailable =>
      'Some endpoints unavailable';

  @override
  String get diagnosticsTitle => 'Connection Diagnostics';

  @override
  String get diagnosticsUnknownError => 'unknown error';

  @override
  String get diagnosticsUnknownStatus => 'unknown';

  @override
  String get discoveryConfigureAddition => 'Configure Addition';

  @override
  String get discoveryHideAlreadyAdded => 'Hide already added';

  @override
  String discoveryLoadFoldersFailed(String error) {
    return 'Error loading folders: $error';
  }

  @override
  String discoveryLoadProfilesFailed(String error) {
    return 'Error loading profiles: $error';
  }

  @override
  String get discoveryNoOverview => 'No overview available.';

  @override
  String get discoveryNoRating => 'No rating';

  @override
  String get discoveryNoResultsFound => 'No results found';

  @override
  String discoveryRootFolderFreeSpace(String path, String free) {
    return '$path ($free GB Free)';
  }

  @override
  String discoveryRuntimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get discoverySearchPrompt => 'Search by title, provider ID, or URL';

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
  String healthCheckCouldNotStart(String service) {
    return '$service check could not start';
  }

  @override
  String healthConnectionFailed(String service) {
    return '$service connection failed';
  }

  @override
  String get healthConnectionIssues => 'Connection issues';

  @override
  String get healthLoadFailed => 'Failed to load health status';

  @override
  String get healthLoadFailureSubtitle =>
      'Could not load server health. Check the connection and try again.';

  @override
  String get healthNoInstancesSubtitle =>
      'Add a Radarr or Sonarr instance to view server health.';

  @override
  String get healthNoIssuesSubtitle =>
      'Connected servers reported no health warnings.';

  @override
  String get healthNoIssuesTitle => 'No server issues found';

  @override
  String get healthRunCheck => 'Run health check';

  @override
  String get healthRunFailureSubtitle =>
      'The latest available server status is shown below.';

  @override
  String get healthServerWarnings => 'Server warnings';

  @override
  String get healthTitle => 'System Health';

  @override
  String healthWiki(String url) {
    return 'Wiki: $url';
  }

  @override
  String get historyAllEvents => 'All events';

  @override
  String get historyAllInstances => 'All instances';

  @override
  String get historyDetailDate => 'Date';

  @override
  String get historyDetailScore => 'Score';

  @override
  String get historyEmpty => 'No history events';

  @override
  String get historyLoadFailed => 'History data could not be loaded.';

  @override
  String get historyLoadMore => 'Load More';

  @override
  String get instanceAddBasicAuth => 'Add Basic Auth';

  @override
  String get instanceAddHeader => 'Add Header';

  @override
  String get instanceAdvancedSettings => 'Advanced Settings';

  @override
  String get instanceAdvancedSettingsSubtitle =>
      'Custom Headers & Authentication';

  @override
  String get instanceAlternativeUrl => 'Alternative URL';

  @override
  String get instanceAlternativeUrlHelper =>
      'Optional URL used outside your local network';

  @override
  String get instanceAlternativeUrlSameAsPrimary =>
      'Must differ from the primary URL';

  @override
  String get instanceApiKeyOrBasicAuthRequired =>
      'Provide an API key or add Basic Auth below';

  @override
  String get instanceApiKeySessionExpiredValidation =>
      'Add Basic Auth below to sign in again, or enter an API key';

  @override
  String get instanceAuthCustomHeader => 'Custom Header';

  @override
  String get instanceAuthUsernamePassword => 'Username & Password';

  @override
  String get instanceBasicAuthBase64Note =>
      'Credentials will be encoded to Base64.';

  @override
  String get instanceBasicAuthTitle => 'Basic Authentication';

  @override
  String instanceDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get instanceDeleteJellyfinWarning =>
      'Arrmate will also remove its Jellyfin connection from Radarr/Sonarr, revoke the Arrmate API key it created and sign out of Jellyfin. This action cannot be undone.';

  @override
  String get instanceDeleteTitle => 'Delete Instance?';

  @override
  String get instanceDeleteWarning => 'This action cannot be undone.';

  @override
  String get instanceEditTitle => 'Edit Instance';

  @override
  String instanceErrorHttpStatus(String status) {
    return 'The server answered with HTTP $status.';
  }

  @override
  String get instanceErrorTimeout =>
      'The server took too long to answer. Try again or enable Slow Instance Mode.';

  @override
  String get instanceErrorUnreachable =>
      'Server unreachable. Check the URL and your network.';

  @override
  String get instanceGoBack => 'Go back';

  @override
  String get instanceHeaderName => 'Header Name';

  @override
  String get instanceHeaderValue => 'Header Value';

  @override
  String get instanceHideApiKey => 'Hide API key';

  @override
  String get instanceJellyfinFallbackUser => 'a Jellyfin user';

  @override
  String get instanceJellyfinHelperDefault =>
      'API key (Jellyfin dashboard → Advanced → API Keys). Leave empty if using \"Add Basic Auth\" below to sign in with a username and password.';

  @override
  String get instanceJellyfinHelperSessionExpired =>
      'Session expired — add Basic Auth below to sign in again, or enter an API key';

  @override
  String instanceJellyfinHelperSignedIn(String user) {
    return 'Signed in as $user. Leave empty to keep the session, enter an API key to switch, or add Basic Auth below to sign in again.';
  }

  @override
  String get instanceJellyfinSessionExpiredBanner =>
      'Your Jellyfin session has expired. Add Basic Auth in Advanced Settings with your username and password to sign in again.';

  @override
  String get instanceLibraryAutoUpdateSetupTitle => 'Library Auto-Update Setup';

  @override
  String get instanceNameHint => 'e.g. Home Server';

  @override
  String get instanceNameLabel => 'Name';

  @override
  String get instanceNotFoundMessage =>
      'The requested instance no longer exists or could not be loaded.';

  @override
  String get instanceNotFoundTitle => 'Instance not found';

  @override
  String get instancePassword => 'Password';

  @override
  String get instanceQbittorrentApiKeyHelper =>
      'Bearer token (qBittorrent ≥ v5.2.0). Leave empty if using \"Add Basic Auth\" below for older versions.';

  @override
  String instanceRemovedCleanupFailed(String failures) {
    return 'Instance removed, but some cleanup failed:\n$failures';
  }

  @override
  String get instanceRequired => 'Required';

  @override
  String get instanceSave => 'Save Instance';

  @override
  String get instanceSetUpLibraryAutoUpdate => 'Set Up Library Auto-Update';

  @override
  String instanceSetupFailed(String error) {
    return 'Setup failed: $error';
  }

  @override
  String get instanceShowApiKey => 'Show API key';

  @override
  String get instanceSlowMode => 'Slow Instance Mode';

  @override
  String get instanceSlowModeSubtitle =>
      'Increase timeouts for slower connections';

  @override
  String get instanceTestConnection => 'Test Connection';

  @override
  String instanceTestSuccessArr(String version, String name, int count) {
    return 'Connection successful!\nVersion: $version\nInstance: $name\nTags: $count available';
  }

  @override
  String instanceTestSuccessQbittorrent(String auth, int count) {
    return 'Connection successful!\nAuth: $auth\nTorrents: $count';
  }

  @override
  String get instanceUrlHelper => 'Include http:// or https:// and port';

  @override
  String get instanceUrlInvalid => 'Must be a valid HTTP or HTTPS URL';

  @override
  String get instanceUsername => 'Username';

  @override
  String instanceValidationFailed(String error) {
    return 'Validation failed: $error';
  }

  @override
  String get jellyfinSetupApiKeyRequired =>
      'Jellyfin API key required for automatic library updates: set an API key in the field, or sign in with an administrator account (Add Basic Auth)';

  @override
  String get jellyfinSetupNoConnection =>
      'No Jellyfin connection configured in Arrmate.';

  @override
  String jellyfinSetupNotArrInstance(String name) {
    return '$name is not a Radarr or Sonarr instance.';
  }

  @override
  String jellyfinSetupRemoveConnectorFailed(String name, String error) {
    return 'Could not remove the Jellyfin connection from $name: $error';
  }

  @override
  String jellyfinSetupRevokeKeyFailed(String error) {
    return 'Could not revoke the Arrmate API key in Jellyfin: $error';
  }

  @override
  String jellyfinSetupSignOutFailed(String error) {
    return 'Could not sign out of Jellyfin: $error';
  }

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
  String get logsAllCopied => 'All logs copied to clipboard';

  @override
  String get logsAppLogsCleared => 'App logs cleared';

  @override
  String get logsClearAppLogs => 'Clear App Logs';

  @override
  String get logsCopyAllVisible => 'Copy all visible logs';

  @override
  String get logsDetailException => 'Exception/Error:';

  @override
  String get logsDetailLevel => 'Level';

  @override
  String get logsDetailLogger => 'Logger';

  @override
  String get logsDetailMessage => 'Message:';

  @override
  String get logsDetailTime => 'Time';

  @override
  String get logsDetailTitle => 'Log Detail';

  @override
  String get logsLevelDebug => 'Debug';

  @override
  String get logsLevelInfo => 'Info';

  @override
  String get logsLevelWarn => 'Warn';

  @override
  String get logsLogCopied => 'Log copied';

  @override
  String get logsNoAppLogsMatchingFilter => 'No app logs found matching filter';

  @override
  String get logsNoLogsMatchingFilter => 'No logs found matching filter';

  @override
  String get logsSource => 'Log source';

  @override
  String get logsTabApp => 'App Logs';

  @override
  String get logsTabArr => 'ARR Logs';

  @override
  String get logsTitle => 'System Logs';

  @override
  String get manualImportEmptySubtitle =>
      'There are no files available for manual import.';

  @override
  String get manualImportEmptyTitle => 'No Importable Files';

  @override
  String manualImportFailed(String error) {
    return 'Failed to import: $error';
  }

  @override
  String manualImportIssueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count with issues',
    );
    return '$_temp0';
  }

  @override
  String get manualImportLoadFailed => 'Failed to load importable files';

  @override
  String get manualImportLoading => 'Loading importable files...';

  @override
  String get manualImportNoFilesSelected => 'No files selected';

  @override
  String manualImportSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file(s) selected',
    );
    return '$_temp0';
  }

  @override
  String manualImportSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file(s) imported successfully',
    );
    return '$_temp0';
  }

  @override
  String get manualImportTitle => 'Manual Import';

  @override
  String manualImportValidCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count valid',
    );
    return '$_temp0';
  }

  @override
  String moviesAddFailed(String error) {
    return 'Error adding movie: $error';
  }

  @override
  String get moviesAddMissingSelection =>
      'Please select a movie, quality profile, and root folder';

  @override
  String get moviesAddMovieButton => 'Add movie';

  @override
  String get moviesAddMovieTitle => 'Add Movie';

  @override
  String get moviesAddedSuccessfully => 'Movie added successfully';

  @override
  String get moviesAllFolders => 'All folders';

  @override
  String get moviesAlsoDeleteFiles => 'Also delete files from disk';

  @override
  String moviesDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get moviesDeleteFileConfirm =>
      'Are you sure you want to delete this file? This action cannot be undone.';

  @override
  String get moviesDeleteFileTitle => 'Delete File';

  @override
  String moviesDeleteFilesConfirm(String title) {
    return 'Delete all files for \"$title\"? This removes the movie file from disk; the movie stays in Radarr.';
  }

  @override
  String moviesDeleteFilesFailed(String error) {
    return 'Failed to delete files: $error';
  }

  @override
  String moviesDeleteMovieConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get moviesDeleteMovieTitle => 'Delete Movie';

  @override
  String get moviesDeleted => 'Movie deleted';

  @override
  String moviesDeletedFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count files',
      one: 'Deleted 1 file',
    );
    return '$_temp0';
  }

  @override
  String get moviesDeletedWithFiles => 'Movie and files deleted';

  @override
  String get moviesEditTitle => 'Edit Movie';

  @override
  String get moviesEmptyFilteredSubtitle =>
      'Try clearing or adjusting your search query or filters.';

  @override
  String get moviesEmptySubtitle =>
      'Add movies to your Radarr library to see them here.';

  @override
  String get moviesEmptyTitle => 'No movies found';

  @override
  String get moviesFileDeleted => 'File deleted';

  @override
  String get moviesFilesSection => 'Files';

  @override
  String get moviesHistorySection => 'History';

  @override
  String get moviesInfoPath => 'Path';

  @override
  String get moviesInfoStudio => 'Studio';

  @override
  String get moviesLoadFilesFailed => 'Failed to load files';

  @override
  String get moviesLoadHistoryFailed => 'Failed to load history';

  @override
  String get moviesLoading => 'Loading movies...';

  @override
  String get moviesLoadingDetails => 'Loading details...';

  @override
  String get moviesMinimumAvailability => 'Minimum Availability';

  @override
  String moviesMoveFilesConfirm(String path) {
    return 'Do you want to move the files to \"$path\"?';
  }

  @override
  String get moviesMoveFilesTitle => 'Move Files?';

  @override
  String get moviesNoFilesToDelete => 'No files to delete';

  @override
  String get moviesNoHistoryEvents => 'No history events';

  @override
  String get moviesNoMediaFiles => 'No media files';

  @override
  String moviesOpenLinkFailed(String error) {
    return 'Unable to open link: $error';
  }

  @override
  String get moviesOverview => 'Overview';

  @override
  String get moviesPreventReAdd => 'Prevent this movie from being re-added';

  @override
  String get moviesPreviewTitle => 'Movie Preview';

  @override
  String moviesPurgeConfirm(String title) {
    return 'This will permanently remove \"$title\" from Radarr, delete its media files, and delete all source torrents (plus cross-seed duplicates) from qBittorrent. Frees disk space used by hardlinked data.';
  }

  @override
  String moviesPurgeFailed(String error) {
    return 'Failed to purge: $error';
  }

  @override
  String moviesPurgePreviewFailed(String error) {
    return 'Failed to preview: $error';
  }

  @override
  String get moviesPurgeTitle => 'Purge movie';

  @override
  String get moviesPurged => 'Movie purged.';

  @override
  String get moviesRefreshAndScan => 'Refresh & Scan';

  @override
  String get moviesRefreshAndScanTriggered => 'Refresh & Scan triggered';

  @override
  String get moviesRootFolderHelper =>
      'Changing this will move files if confirmed';

  @override
  String get moviesSearchHint => 'Search movies...';

  @override
  String moviesSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get moviesSortAndFilter => 'Sort & Filter';

  @override
  String get moviesSwitchToGrid => 'Switch to Grid';

  @override
  String get moviesSwitchToList => 'Switch to List';

  @override
  String get moviesTrailer => 'Trailer';

  @override
  String moviesUpdateFailed(String error) {
    return 'Error updating movie: $error';
  }

  @override
  String get moviesUpdated => 'Movie updated';

  @override
  String moviesViewPoster(String title) {
    return 'View $title poster';
  }

  @override
  String get notificationSettingsArrUpdate => '*arr Instance Update';

  @override
  String get notificationSettingsArrUpdateSubtitle =>
      'When Radarr/Sonarr server is updated';

  @override
  String get notificationSettingsAutoConfigure =>
      'Auto-configure *arr instances';

  @override
  String get notificationSettingsAutoConfiguring =>
      'Auto-configuring notifications...';

  @override
  String notificationSettingsConfiguredCount(int success, int total) {
    return '$success/$total instances configured.';
  }

  @override
  String get notificationSettingsConnected => 'Connected to ntfy.sh';

  @override
  String get notificationSettingsCopyTopic => 'Copy topic';

  @override
  String get notificationSettingsDisconnected => 'Disconnected';

  @override
  String get notificationSettingsDownloads => 'Downloads';

  @override
  String get notificationSettingsEnable => 'Enable Notifications';

  @override
  String get notificationSettingsFailure => 'Notify on Failure';

  @override
  String get notificationSettingsFailureSubtitle =>
      'When a download fails to import';

  @override
  String get notificationSettingsFileDeleted => 'File Deleted';

  @override
  String get notificationSettingsFileDeletedSubtitle =>
      'When a media file is deleted';

  @override
  String get notificationSettingsGrab => 'Notify on Grab';

  @override
  String get notificationSettingsGrabSubtitle =>
      'When a release is sent to download client';

  @override
  String get notificationSettingsHealthIssues => 'Health Issues';

  @override
  String get notificationSettingsHealthIssuesSubtitle =>
      'When system health issues are detected';

  @override
  String get notificationSettingsHealthRestored => 'Health Restored';

  @override
  String get notificationSettingsHealthRestoredSubtitle =>
      'When a health issue is resolved';

  @override
  String get notificationSettingsImport => 'Notify on Import';

  @override
  String get notificationSettingsImportSubtitle =>
      'When a file is successfully imported';

  @override
  String get notificationSettingsInAppBody =>
      'Notifications are received in real-time while the app is open. When you close the app, new notifications will be fetched the next time you open it.';

  @override
  String get notificationSettingsInAppTitle => 'In-App Notifications';

  @override
  String get notificationSettingsIncludeWarnings => 'Include Warnings';

  @override
  String get notificationSettingsIncludeWarningsSubtitle =>
      'Also notify on health warnings';

  @override
  String get notificationSettingsManualInteraction => 'Manual Interaction';

  @override
  String get notificationSettingsManualInteractionSubtitle =>
      'When manual intervention is required';

  @override
  String get notificationSettingsManualSetup => 'OR MANUAL SETUP';

  @override
  String get notificationSettingsManualStep1 => '1. Go to Settings > Connect';

  @override
  String get notificationSettingsManualStep2 => '2. Add new connection > ntfy';

  @override
  String get notificationSettingsManualStep3 => '3. Configure:';

  @override
  String get notificationSettingsMediaAdded => 'Movie/Series Added';

  @override
  String get notificationSettingsMediaAddedSubtitle =>
      'When a movie or series is added';

  @override
  String get notificationSettingsMediaDeleted => 'Movie/Series Deleted';

  @override
  String get notificationSettingsMediaDeletedSubtitle =>
      'When a movie or series is deleted';

  @override
  String get notificationSettingsMediaUpdates => 'Media Updates';

  @override
  String get notificationSettingsNtfyDocs => 'ntfy documentation';

  @override
  String get notificationSettingsServerUrl => 'Server URL';

  @override
  String get notificationSettingsSetupInArr => 'Setup in Radarr/Sonarr';

  @override
  String get notificationSettingsSetupResults => 'Setup Results';

  @override
  String get notificationSettingsSetupSubtitle =>
      'Tap to generate your unique topic';

  @override
  String get notificationSettingsSetupTitle => 'Setup Notifications';

  @override
  String get notificationSettingsTopic => 'Topic';

  @override
  String get notificationSettingsTopicCopied => 'Topic copied to clipboard';

  @override
  String notificationSettingsUnexpectedError(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String get notificationSettingsYourTopic => 'Your Topic';

  @override
  String notificationSetupConfigured(String name) {
    return '$name configured successfully.';
  }

  @override
  String notificationSetupFailed(String name, String error) {
    return 'Failed to configure $name: $error';
  }

  @override
  String get notificationSetupNoTopic => 'No Ntfy topic configured in Arrmate.';

  @override
  String notificationSetupUpdated(String name) {
    return '$name updated successfully.';
  }

  @override
  String get notificationsAllCleared => 'All notifications cleared';

  @override
  String get notificationsAllMarkedRead => 'All notifications marked as read';

  @override
  String get notificationsClearAll => 'Clear all';

  @override
  String get notificationsClearAllConfirm =>
      'This will remove all notifications. This action cannot be undone.';

  @override
  String get notificationsClearAllTitle => 'Clear all notifications?';

  @override
  String get notificationsDismissed => 'Notification dismissed';

  @override
  String get notificationsEmptySubtitle =>
      'When you receive notifications from Radarr or Sonarr, they will appear here.';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsNewBadge => 'NEW';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get playbackLoadMovieFileFailed => 'Could not load the movie file';

  @override
  String get playbackNoEpisodeFile => 'No playable file found for this episode';

  @override
  String get playbackNoJellyfin => 'No Jellyfin server is configured';

  @override
  String get playbackNoMovieFile => 'No playable file found for this movie';

  @override
  String get playbackNotFound => 'Could not find this media in Jellyfin';

  @override
  String get playbackSearchingLibrary => 'Searching the Jellyfin library…';

  @override
  String get playbackSessionExpired =>
      'Your Jellyfin session has expired. Sign in again.';

  @override
  String get playbackSignIn => 'Sign in';

  @override
  String playbackStartFailed(String error) {
    return 'Could not start playback: $error';
  }

  @override
  String playbackTrackLabel(int index) {
    return 'Track $index';
  }

  @override
  String get playerAudio => 'Audio';

  @override
  String get playerBack => 'Back';

  @override
  String get playerExternalOpenFailed => 'Could not open an external player';

  @override
  String get playerExternalUnavailable =>
      'Opening this media in an external player is not available for the current server configuration.';

  @override
  String get playerNoMediaRequested => 'No media was requested for playback.';

  @override
  String get playerQualityDataSaver => 'Data saver';

  @override
  String get playerQualityOriginal => 'Original';

  @override
  String playerQualityTooltip(String quality) {
    return 'Quality: $quality';
  }

  @override
  String get playerStartFailed =>
      'Could not start playback. Check your connection and try again.';

  @override
  String get playerSubtitleExternal => 'External';

  @override
  String get playerSubtitlesDisabled => 'Disabled';

  @override
  String get playerTitle => 'Player';

  @override
  String get playerUnexpectedFailure => 'Playback failed unexpectedly.';

  @override
  String get playerUnsupportedOnWeb =>
      'In-app playback is not supported on the web yet';

  @override
  String get providerAssistantDeleteFailed => 'Failed to delete model.';

  @override
  String providerAssistantDownloadFailed(String error) {
    return 'Failed to download model: $error';
  }

  @override
  String get providerAssistantEnableOnlineFailed =>
      'Failed to enable online model.';

  @override
  String get providerAssistantGenerateFailed =>
      'Failed to generate a response.';

  @override
  String get providerAssistantImportFailed => 'Failed to import model.';

  @override
  String get providerAssistantInitFailed =>
      'Failed to initialize assistant resources.';

  @override
  String get providerAssistantLoadModelFailed =>
      'Failed to load the selected model.';

  @override
  String get providerAssistantModelNotFound => 'Model not found.';

  @override
  String get providerAssistantNoToolCalling =>
      'This model does not support tool-calling. Use a Gemma model.';

  @override
  String get providerAssistantRefreshModelsFailed =>
      'Failed to refresh installed models.';

  @override
  String get providerAssistantSelectModelFirst =>
      'Select a model before chatting.';

  @override
  String get providerBackupCompleted => 'Backup completed.';

  @override
  String get providerBackupCorrupt =>
      'The backup file is corrupted or from an unsupported version.';

  @override
  String providerBackupExportFailed(String error) {
    return 'Backup export failed: $error';
  }

  @override
  String get providerBackupExported => 'Backup exported to file.';

  @override
  String providerBackupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String providerBackupLoadFailed(String error) {
    return 'Could not load the backup: $error';
  }

  @override
  String get providerBackupNotFound => 'No backup found in your Google Drive.';

  @override
  String providerBackupReadFileFailed(String error) {
    return 'Could not read the backup file: $error';
  }

  @override
  String providerBackupRestoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String providerBackupRestored(int settingsCount, int instanceCount) {
    return 'Restored $settingsCount settings and $instanceCount instances.';
  }

  @override
  String get providerBackupSessionExpired =>
      'Google session expired. Sign in again.';

  @override
  String get providerBackupSignInFailed =>
      'Sign-in failed. Check your connection and try again.';

  @override
  String get providerBackupSignedOut => 'Sign in to Google first.';

  @override
  String get providerBackupUnknownError => 'unknown error';

  @override
  String providerInstanceTypeMismatch(String expected, String actual) {
    return 'Expected $expected, but connected to $actual';
  }

  @override
  String get purgeCrossSeedFoundContent =>
      'A torrent with the same release name was found. Delete it too?';

  @override
  String get purgeCrossSeedFoundTitle => 'Cross-seed torrent found';

  @override
  String get purgeDeleteAll => 'Delete all';

  @override
  String get purgeDeleteAnyway => 'Delete anyway';

  @override
  String get purgeDeleteTorrent => 'Delete torrent';

  @override
  String get purgeHash => 'Hash';

  @override
  String get purgeKeepSeeding => 'Keep seeding';

  @override
  String get purgeKeepTorrent => 'Keep torrent';

  @override
  String get purgeNoTags => 'No tags';

  @override
  String get purgeSavePath => 'Save path';

  @override
  String purgeSeededFor(String duration) {
    return 'Seeded $duration';
  }

  @override
  String get purgeTitleRemovedEitherWay =>
      'The title will still be removed from the library and its files deleted either way.';

  @override
  String purgeTorrentBelowMinimum(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'This torrent seeded for less than the minimum of $_temp0:';
  }

  @override
  String get purgeTorrentStillSeeding => 'Torrent still seeding';

  @override
  String purgeTorrentsBelowMinimum(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count torrents',
      one: '1 torrent',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'The following $_temp0 seeded for less than the minimum of $_temp1:';
  }

  @override
  String get purgeTorrentsStillSeeding => 'Torrents still seeding';

  @override
  String get qualityProfilesEmpty =>
      'No profiles found or instance not connected';

  @override
  String qualityProfilesId(String id) {
    return 'ID: $id';
  }

  @override
  String get qualityProfilesRadarr => 'Radarr Profiles';

  @override
  String get qualityProfilesSonarr => 'Sonarr Profiles';

  @override
  String get qualityProfilesTitle => 'Quality Profiles';

  @override
  String get queueAddToBlocklist => 'Add to Blocklist';

  @override
  String get queueAddToBlocklistSubtitle =>
      'Prevent this release from being grabbed again';

  @override
  String get queueAnyClient => 'Any client';

  @override
  String get queueAnyInstance => 'Any instance';

  @override
  String get queueAnyProtocol => 'Any protocol';

  @override
  String get queueAscending => 'Ascending';

  @override
  String get queueCustomFormatScore => 'Custom Format Score';

  @override
  String get queueCustomFormats => 'Custom Formats';

  @override
  String get queueDescending => 'Descending';

  @override
  String get queueDetailPath => 'Path';

  @override
  String get queueDirection => 'Direction';

  @override
  String get queueEmptySubtitle => 'No active downloads at the moment.';

  @override
  String get queueEmptyTitle => 'Queue is empty';

  @override
  String queueEtaDays(int count) {
    return '${count}d';
  }

  @override
  String get queueEtaDone => 'Done';

  @override
  String queueEtaHours(int count) {
    return '${count}h';
  }

  @override
  String get queueEtaLessThanMinute => '<1m';

  @override
  String queueEtaMinutes(int count) {
    return '${count}m';
  }

  @override
  String get queueFilterSection => 'Filter';

  @override
  String get queueGroupedTasks => 'Grouped Tasks';

  @override
  String get queueInformation => 'Information';

  @override
  String get queueInstance => 'Instance';

  @override
  String get queueItemRemoved => 'Item removed from queue';

  @override
  String get queueLoadFailed => 'Queue data could not be loaded.';

  @override
  String get queueLoading => 'Loading queue...';

  @override
  String get queueManualImportDescription =>
      'This download requires manual intervention. Select which files to import.';

  @override
  String get queueManualImportRequired => 'Manual Import Required';

  @override
  String get queueNoMatchSubtitle => 'Adjust or reset the queue filters.';

  @override
  String get queueNoMatchTitle => 'No matching tasks';

  @override
  String get queueOpenDetails => 'Open Details';

  @override
  String get queueOpenMovie => 'Open Movie';

  @override
  String get queueOpenSeries => 'Open Series';

  @override
  String get queueOptions => 'Queue options';

  @override
  String queueProblemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count problems)',
      one: '(1 problem)',
    );
    return '$_temp0';
  }

  @override
  String get queueProblemsOnly => 'Problems only';

  @override
  String get queueProblemsOnlySubtitle =>
      'Show tasks that need attention or manual import';

  @override
  String get queueRemovalOptions => 'Removal Options';

  @override
  String get queueRemoveFromClient => 'Remove from Download Client';

  @override
  String get queueRemoveFromClientSubtitle =>
      'Delete the download from the client';

  @override
  String get queueRemoveFromQueue => 'Remove from Queue';

  @override
  String get queueSearchReplacement => 'Search for Replacement';

  @override
  String get queueSearchReplacementSubtitle =>
      'Automatically search for another release';

  @override
  String queueSizeLeft(String size) {
    return '$size left';
  }

  @override
  String queueTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String queueTimeRemainingDaysHours(int days, int hours) {
    return '${days}d ${hours}h remaining';
  }

  @override
  String queueTimeRemainingHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m remaining';
  }

  @override
  String get queueTimeRemainingLessThanMinute => 'Less than a minute';

  @override
  String queueTimeRemainingMinutes(int minutes) {
    return '${minutes}m remaining';
  }

  @override
  String get queueUnableToImport => 'Unable to Import Automatically';

  @override
  String get queueUnknownError => 'Unknown error';

  @override
  String get releasesAge => 'Age';

  @override
  String releasesAgeDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
    );
    return '$_temp0';
  }

  @override
  String releasesAgeShort(int days) {
    return '${days}d';
  }

  @override
  String get releasesApproval => 'Approval';

  @override
  String get releasesApproved => 'Approved';

  @override
  String get releasesClearSearch => 'Clear search';

  @override
  String get releasesCustomFormat => 'Custom format';

  @override
  String get releasesCustomFormatScore => 'Custom format score';

  @override
  String get releasesCustomFormats => 'Custom formats';

  @override
  String get releasesDetailsTitle => 'Release details';

  @override
  String get releasesDownload => 'Download';

  @override
  String get releasesDownloadRelease => 'Download release';

  @override
  String get releasesDownloadTitle => 'Download Release';

  @override
  String get releasesEpisodeOrMovie => 'Episode or movie';

  @override
  String get releasesEpisodes => 'Episodes';

  @override
  String get releasesExcludeFreeleech => 'Exclude freeleech';

  @override
  String get releasesFilterTooltip => 'Filter releases';

  @override
  String get releasesFiltersSubtitle => 'Combine any number of filters';

  @override
  String get releasesFiltersTitle => 'Release filters';

  @override
  String get releasesFreeleech => 'Freeleech';

  @override
  String get releasesFreeleechOnly => 'Freeleech only';

  @override
  String releasesGrabConfirm(String title) {
    return 'Are you sure you want to grab \"$title\"?';
  }

  @override
  String releasesGrabError(String error) {
    return 'Error grabbing release: $error';
  }

  @override
  String get releasesGrabSuccess => 'Release grabbed successfully';

  @override
  String get releasesIndexerFlags => 'Indexer flags';

  @override
  String get releasesLanguages => 'Languages';

  @override
  String get releasesMappedEpisodes => 'Mapped episodes';

  @override
  String get releasesNoMatch => 'No releases match the current filters';

  @override
  String get releasesNoneFound => 'No releases found';

  @override
  String get releasesOriginalLanguageOnly => 'Original language only';

  @override
  String get releasesQualityWeight => 'Quality weight';

  @override
  String get releasesRejected => 'Rejected';

  @override
  String get releasesRejectedTooltip => 'Rejected release';

  @override
  String get releasesRejectionReasons => 'Rejection reasons';

  @override
  String get releasesReleaseRejected => 'Release rejected';

  @override
  String get releasesReleaseType => 'Release type';

  @override
  String get releasesReleaseWeight => 'Release weight';

  @override
  String get releasesRememberFilters => 'Remember filters';

  @override
  String get releasesRememberFiltersSubtitle =>
      'Keep this configuration for future searches';

  @override
  String get releasesRequestedEpisode => 'Requested episode';

  @override
  String releasesResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
    );
    return '$_temp0';
  }

  @override
  String releasesResultCountHidden(int count, int hidden) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
    );
    return '$_temp0 · $hidden hidden';
  }

  @override
  String get releasesSearchHint => 'Search releases';

  @override
  String get releasesSeasonPack => 'Season pack';

  @override
  String get releasesSeasonPacks => 'Season packs';

  @override
  String get releasesSeeders => 'Seeders';

  @override
  String get releasesSeedsPeers => 'Seeds / peers';

  @override
  String get releasesSendingTooltip => 'Sending release to the download client';

  @override
  String seriesAddFailed(String error) {
    return 'Error adding series: $error';
  }

  @override
  String get seriesAddMissingSelection =>
      'Please select a series, quality profile, and root folder';

  @override
  String get seriesAddSeries => 'Add series';

  @override
  String get seriesAddSeriesTitle => 'Add Series';

  @override
  String get seriesAddedSuccessfully => 'Series added successfully';

  @override
  String get seriesAirDate => 'Air Date';

  @override
  String get seriesAllFolders => 'All folders';

  @override
  String get seriesAllSeasonsMonitored => 'All seasons monitored';

  @override
  String get seriesAllSeasonsUnmonitored => 'All seasons unmonitored';

  @override
  String get seriesAlsoDeleteFiles => 'Also delete files from disk';

  @override
  String get seriesAndFilesDeleted => 'Series and files deleted';

  @override
  String get seriesConfigureAddition => 'Configure Addition';

  @override
  String seriesDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get seriesDeleteFile => 'Delete File';

  @override
  String get seriesDeleteFileConfirm =>
      'Are you sure you want to delete this file? This action cannot be undone.';

  @override
  String seriesDeleteFilesConfirm(String title) {
    return 'Delete all files for \"$title\"? This removes every episode file from disk; the series stays in Sonarr.';
  }

  @override
  String seriesDeleteFilesFailed(String error) {
    return 'Failed to delete files: $error';
  }

  @override
  String seriesDeleteFilesForSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete files for $count seasons',
      one: 'Delete files for 1 season',
    );
    return '$_temp0';
  }

  @override
  String get seriesDeleteSeasonFiles => 'Delete season files';

  @override
  String seriesDeleteSeasonFilesConfirm(String title, int season) {
    return 'Delete all files for \"$title - Season $season\"? This removes every episode file in this season from disk.';
  }

  @override
  String get seriesDeleteSeasonsFilesContent =>
      'This deletes the episode files of the selected seasons from disk. The series stays in Sonarr.';

  @override
  String get seriesDeleteSeries => 'Delete Series';

  @override
  String seriesDeleteSeriesConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get seriesDeleted => 'Series deleted';

  @override
  String seriesDeletedFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count files',
      one: 'Deleted 1 file',
    );
    return '$_temp0';
  }

  @override
  String get seriesEditSeries => 'Edit Series';

  @override
  String get seriesEmptySubtitle =>
      'Add series to your Sonarr library to see them here.';

  @override
  String get seriesEpisodeActions => 'Episode actions';

  @override
  String seriesEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Episodes',
    );
    return '$_temp0';
  }

  @override
  String seriesEpisodeLoadFailed(String error) {
    return 'Failed to load the episode: $error';
  }

  @override
  String get seriesEpisodeLoading => 'Loading episode...';

  @override
  String get seriesEpisodeMonitored => 'Episode monitored';

  @override
  String get seriesEpisodeUnmonitored => 'Episode unmonitored';

  @override
  String get seriesFile => 'File';

  @override
  String get seriesFileDeleted => 'File deleted';

  @override
  String get seriesHideAlreadyAdded => 'Hide already added';

  @override
  String get seriesHistory => 'History';

  @override
  String seriesLoadEpisodesFailed(String error) {
    return 'Failed to load episodes: $error';
  }

  @override
  String get seriesLoadFileInfoFailed => 'Failed to load file info';

  @override
  String seriesLoadFoldersError(String error) {
    return 'Error loading folders: $error';
  }

  @override
  String get seriesLoadHistoryFailed => 'Failed to load history';

  @override
  String seriesLoadProfilesError(String error) {
    return 'Error loading profiles: $error';
  }

  @override
  String get seriesLoadingDetails => 'Loading details...';

  @override
  String get seriesLoadingSeries => 'Loading series...';

  @override
  String get seriesMonitorEpisode => 'Monitor episode';

  @override
  String get seriesMonitorNewSeasons => 'Monitor New Seasons';

  @override
  String get seriesMonitorNewSeasonsSubtitle =>
      'Automatically monitor seasons added in the future';

  @override
  String get seriesMonitoredSubtitle => 'Monitor episodes for this series';

  @override
  String get seriesMoveFilesContent =>
      'You changed the root folder. Do you want to move existing files to the new location?';

  @override
  String get seriesMoveFilesTitle => 'Move Files?';

  @override
  String get seriesNetwork => 'Network';

  @override
  String get seriesNoEpisodesFound => 'No episodes found';

  @override
  String get seriesNoFileAvailable => 'No file available';

  @override
  String get seriesNoFilesToDelete => 'No files to delete';

  @override
  String get seriesNoHistoryEvents => 'No history events';

  @override
  String get seriesNoOverview => 'No overview available.';

  @override
  String get seriesNoRating => 'No rating';

  @override
  String get seriesNoResultsFound => 'No results found';

  @override
  String get seriesNoResultsSubtitle =>
      'Try clearing or adjusting your search query or filters.';

  @override
  String get seriesNoSeriesFound => 'No series found';

  @override
  String get seriesNoSonarrInstance => 'No Sonarr instance configured';

  @override
  String get seriesOverview => 'Overview';

  @override
  String get seriesPath => 'Path';

  @override
  String get seriesPreventReAdd => 'Prevent this series from being re-added';

  @override
  String get seriesPreview => 'Series Preview';

  @override
  String seriesPreviewCrossSeedsFailed(String error) {
    return 'Failed to preview cross-seeds: $error';
  }

  @override
  String seriesPreviewFailed(String error) {
    return 'Failed to preview: $error';
  }

  @override
  String seriesPurgeFailed(String error) {
    return 'Failed to purge: $error';
  }

  @override
  String get seriesPurgeSeason => 'Purge season';

  @override
  String seriesPurgeSeasonConfirm(String title, int season) {
    return 'Delete all files for \"$title - Season $season\" and remove their source torrents from qBittorrent? The series stays in Sonarr.';
  }

  @override
  String get seriesPurgeSeasonsContent =>
      'This deletes the episode files of the selected seasons and their source torrents from qBittorrent. The series stays in Sonarr.';

  @override
  String seriesPurgeSeasonsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Purge $count seasons',
      one: 'Purge 1 season',
    );
    return '$_temp0';
  }

  @override
  String get seriesPurgeSeries => 'Purge series';

  @override
  String seriesPurgeSeriesConfirm(String title) {
    return 'This will permanently remove \"$title\" and all its episodes from Sonarr, delete its media files, and delete all source torrents (plus cross-seed duplicates) from qBittorrent. Frees disk space used by hardlinked data.';
  }

  @override
  String get seriesPurged => 'Series purged.';

  @override
  String seriesPurgedSeasonsSummary(int seasons, int files, int torrents) {
    String _temp0 = intl.Intl.pluralLogic(
      seasons,
      locale: localeName,
      other: '$seasons seasons',
      one: '1 season',
    );
    String _temp1 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files files',
      one: '1 file',
    );
    String _temp2 = intl.Intl.pluralLogic(
      torrents,
      locale: localeName,
      other: '$torrents torrents',
      one: '1 torrent',
    );
    return 'Purged $_temp0: $_temp1, $_temp2.';
  }

  @override
  String seriesPurgedSummary(int files, int torrents) {
    String _temp0 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files files',
      one: '1 file',
    );
    String _temp1 = intl.Intl.pluralLogic(
      torrents,
      locale: localeName,
      other: '$torrents torrents',
      one: '1 torrent',
    );
    return 'Purged: $_temp0, $_temp1.';
  }

  @override
  String get seriesRefreshAndScan => 'Refresh & Scan';

  @override
  String get seriesRefreshScanTriggered => 'Refresh & Scan triggered';

  @override
  String seriesRootFolderFreeSpace(String path, String free) {
    return '$path ($free GB Free)';
  }

  @override
  String get seriesRootFolderHeader => 'ROOT FOLDER';

  @override
  String seriesRuntimeMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String get seriesSearchByHint => 'Search by title, provider ID, or URL';

  @override
  String seriesSearchFailed(String error) {
    return 'Failed to search: $error';
  }

  @override
  String get seriesSearchHint => 'Search series...';

  @override
  String seriesSearchStartedFor(String name) {
    return 'Search started for $name';
  }

  @override
  String seriesSearchStartedForSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Search started for $count seasons',
      one: 'Search started for 1 season',
    );
    return '$_temp0';
  }

  @override
  String seriesSearchingFor(String name) {
    return 'Searching for $name...';
  }

  @override
  String get seriesSeasonActions => 'Season actions';

  @override
  String seriesSeasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seasons',
    );
    return '$_temp0';
  }

  @override
  String get seriesSeasonFolder => 'Season Folder';

  @override
  String get seriesSeasonFolders => 'Season Folders';

  @override
  String get seriesSeasonFoldersSubtitle =>
      'Use Season folders (e.g. Season 01/...)';

  @override
  String seriesSeasonLoadFailed(String error) {
    return 'Failed to load the season: $error';
  }

  @override
  String get seriesSeasonLoading => 'Loading season...';

  @override
  String get seriesSeasonTitle => 'Season';

  @override
  String get seriesSeasons => 'Seasons';

  @override
  String get seriesSelect => 'Select';

  @override
  String get seriesSelectPath => 'Select Path';

  @override
  String seriesSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
    );
    return '$_temp0';
  }

  @override
  String get seriesSeriesType => 'Series Type';

  @override
  String get seriesSortAndFilter => 'Sort & Filter';

  @override
  String get seriesSwitchToGrid => 'Switch to Grid';

  @override
  String get seriesSwitchToList => 'Switch to List';

  @override
  String seriesTitleWithSeason(String title, int season) {
    return '$title - Season $season';
  }

  @override
  String seriesUnableToOpenLink(String error) {
    return 'Unable to open link: $error';
  }

  @override
  String get seriesUnmonitorEpisode => 'Unmonitor episode';

  @override
  String seriesUnmonitoredSeasons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Unmonitored $count seasons',
      one: 'Unmonitored 1 season',
    );
    return '$_temp0';
  }

  @override
  String seriesUpdateEpisodeFailed(String error) {
    return 'Failed to update episode: $error';
  }

  @override
  String seriesUpdateFailed(String error) {
    return 'Error updating series: $error';
  }

  @override
  String seriesViewPoster(String title) {
    return 'View $title poster';
  }

  @override
  String get seriesWatch => 'Watch';

  @override
  String get seriesYesMoveFiles => 'Yes, Move Files';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAddInstance => 'Add Instance';

  @override
  String get settingsAppUpToDate => 'App is up to date';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAssistant => 'Assistant';

  @override
  String get settingsAssistantSubtitle => 'Ask how the app works';

  @override
  String get settingsBackupLocalFileSubtitle => 'Import or export a local file';

  @override
  String get settingsColorScheme => 'Color Scheme';

  @override
  String get settingsCouldNotCheckUpdates => 'Could not check for updates';

  @override
  String get settingsGettingStarted => 'Getting Started';

  @override
  String get settingsGettingStartedSubtitle => 'Replay the setup tour';

  @override
  String get settingsHomeTab => 'Home Tab';

  @override
  String settingsInstanceTagCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return '$_temp0';
  }

  @override
  String get settingsInstances => 'Instances';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsNoArrInstancesConfigured => 'No Arr instances configured';

  @override
  String get settingsNoInstances => 'No instances configured';

  @override
  String get settingsNoRadarrSonarrInstances =>
      'No Radarr or Sonarr instances configured';

  @override
  String get settingsNotificationCenter => 'Notification Center';

  @override
  String get settingsNotificationSettings => 'Notification Settings';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsEnabledSubtitle =>
      'Enabled · ntfy.sh integration';

  @override
  String get settingsNotificationsSetupSubtitle => 'Setup notifications';

  @override
  String get settingsSelectColor => 'Select Color';

  @override
  String get settingsSelectHomeTab => 'Select Home Tab';

  @override
  String get settingsSelectLanguage => 'Select Language';

  @override
  String get settingsSelectMode => 'Select Mode';

  @override
  String get settingsSessionExpiredSignIn => 'Session expired · tap to sign in';

  @override
  String get settingsSourceCode => 'Source Code';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsSystemManagementSubtitle =>
      'Diagnostics, status, logs, and app maintenance';

  @override
  String get settingsThemeMode => 'Theme Mode';

  @override
  String settingsUnreadNotifications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread notifications',
      one: '1 unread notification',
    );
    return '$_temp0';
  }

  @override
  String get settingsVersion => 'Version';

  @override
  String settingsVersionViaAltStore(String version) {
    return '$version • updates via AltStore';
  }

  @override
  String get settingsViewAllNotifications => 'View all notifications';

  @override
  String get sharedAddImportExclusion => 'Add to import exclusion list';

  @override
  String get sharedAddImportExclusionSubtitle =>
      'Prevent the item from being added again by an import list.';

  @override
  String get sharedAscending => 'Ascending';

  @override
  String sharedBatchDeleteFilesFailed(String error) {
    return 'Failed to delete files: $error';
  }

  @override
  String get sharedBatchDeleteMovieFilesContent =>
      'This deletes the media files of the selected movies from disk. They stay in Radarr.';

  @override
  String sharedBatchDeleteMovieFilesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete files for $count movies',
      one: 'Delete files for 1 movie',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteMoviesKeepFiles =>
      'This removes the selected movies from Radarr. Files stay on disk.';

  @override
  String sharedBatchDeleteMoviesPartial(int deleted, int total, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total movies',
      one: '1 movie',
    );
    return 'Deleted $deleted of $_temp0 before error: $error';
  }

  @override
  String sharedBatchDeleteMoviesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count movies',
      one: 'Delete 1 movie',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteMoviesWithFiles =>
      'This removes the selected movies from Radarr and deletes their files from disk.';

  @override
  String get sharedBatchDeleteSeriesFilesContent =>
      'This deletes the media files of the selected series from disk. They stay in Sonarr.';

  @override
  String sharedBatchDeleteSeriesFilesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete files for $count series',
      one: 'Delete files for 1 series',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteSeriesKeepFiles =>
      'This removes the selected series from Sonarr. Files stay on disk.';

  @override
  String sharedBatchDeleteSeriesPartial(int deleted, int total, String error) {
    return 'Deleted $deleted of $total series before error: $error';
  }

  @override
  String sharedBatchDeleteSeriesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count series',
      one: 'Delete 1 series',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchDeleteSeriesWithFiles =>
      'This removes the selected series from Sonarr and deletes their files from disk.';

  @override
  String sharedBatchDeletedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count files',
      one: 'Deleted 1 file',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count movies',
      one: 'Deleted 1 movie',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedMoviesAndFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count movies and files',
      one: 'Deleted 1 movie and files',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count series',
      one: 'Deleted 1 series',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchDeletedSeriesAndFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count series and files',
      one: 'Deleted 1 series and files',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchMonitoredMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Monitored $count movies',
      one: 'Monitored 1 movie',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchMonitoredSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Monitored $count series',
      one: 'Monitored 1 series',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchPreviewCrossSeedsFailed(String error) {
    return 'Failed to preview cross-seeds: $error';
  }

  @override
  String sharedBatchPreviewFailed(String error) {
    return 'Failed to preview: $error';
  }

  @override
  String sharedBatchPurgeFailed(String error) {
    return 'Failed to purge: $error';
  }

  @override
  String get sharedBatchPurgeMoviesContent =>
      'This permanently removes the selected movies from Radarr, deletes their files, and deletes all source torrents from qBittorrent.';

  @override
  String sharedBatchPurgeMoviesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Purge $count movies',
      one: 'Purge 1 movie',
    );
    return '$_temp0';
  }

  @override
  String get sharedBatchPurgeSeriesContent =>
      'This permanently removes the selected series from Sonarr, deletes their files, and deletes all source torrents from qBittorrent.';

  @override
  String sharedBatchPurgeSeriesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Purge $count series',
      one: 'Purge 1 series',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchPurgedMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Purged $count movies.',
      one: 'Purged 1 movie.',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchPurgedSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Purged $count series.',
      one: 'Purged 1 series.',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchUnmonitoredMovies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Unmonitored $count movies',
      one: 'Unmonitored 1 movie',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchUnmonitoredSeries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Unmonitored $count series',
      one: 'Unmonitored 1 series',
    );
    return '$_temp0';
  }

  @override
  String sharedBatchUpdateMoviesPartial(int updated, int total, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total movies',
      one: '1 movie',
    );
    return 'Updated $updated of $_temp0 before error: $error';
  }

  @override
  String sharedBatchUpdateSeriesPartial(int updated, int total, String error) {
    return 'Updated $updated of $total series before error: $error';
  }

  @override
  String get sharedDescending => 'Descending';

  @override
  String get sharedFailedToLoadTorrents => 'Failed to load torrents';

  @override
  String get sharedNoRadarrInstance => 'No Radarr instance configured';

  @override
  String get sharedNoTorrentsInClient => 'No torrents in the download client';

  @override
  String sharedSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
    );
    return '$_temp0';
  }

  @override
  String get sharedTorrents => 'Torrents';

  @override
  String get sharedTorrentsDeleteContent =>
      'This removes the selected torrents from qBittorrent and deletes their files from disk.';

  @override
  String sharedTorrentsDeleteFailed(String error) {
    return 'Failed to delete torrents: $error';
  }

  @override
  String sharedTorrentsDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count torrents',
      one: 'Delete 1 torrent',
    );
    return '$_temp0';
  }

  @override
  String sharedTorrentsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count torrents and files',
      one: 'Deleted 1 torrent and files',
    );
    return '$_temp0';
  }

  @override
  String sharedTorrentsDeletedKept(int count, int kept) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count torrents and files (kept $kept still seeding)',
      one: 'Deleted 1 torrent and files (kept $kept still seeding)',
    );
    return '$_temp0';
  }

  @override
  String get sharedTorrentsKeepSeedingAll =>
      'Keep seeding leaves them and their files untouched.';

  @override
  String get sharedTorrentsKeepSeedingSome =>
      'The other selected torrents and their files are deleted either way.';

  @override
  String get sharedTorrentsNoQbittorrent =>
      'No qBittorrent instance configured';

  @override
  String get sharedTorrentsNoneDeleted => 'No torrents deleted';

  @override
  String sharedTorrentsNoneDeletedKept(int kept) {
    return 'No torrents deleted (kept $kept still seeding)';
  }

  @override
  String get systemAppMaintenance => 'App Maintenance';

  @override
  String get systemClearImageCache => 'Clear image cache';

  @override
  String get systemClearImageCacheSubtitle =>
      'Free up cached poster and image storage';

  @override
  String get systemDaysHelper => '0 disables the warning';

  @override
  String get systemDaysInvalid => 'Enter a valid number (0 or more)';

  @override
  String get systemDaysLabel => 'Days';

  @override
  String get systemDiagnosticsSubtitle =>
      'Test endpoints, latency, request traces, and export a report';

  @override
  String get systemHealth => 'Health';

  @override
  String get systemHealthSubtitle => 'Server-reported Radarr and Sonarr alerts';

  @override
  String get systemImageCacheCleared => 'Image cache cleared';

  @override
  String get systemLogs => 'Logs';

  @override
  String get systemLogsSubtitle => 'System event logs';

  @override
  String get systemManagementTitle => 'System Management';

  @override
  String get systemMinimumSeedingDays => 'Minimum seeding days';

  @override
  String get systemMinimumSeedingDaysDescription =>
      'Torrents that seeded for less than this are flagged for confirmation before deletion. Set to 0 to disable.';

  @override
  String get systemOverviewDiskSpace => 'Disk Space';

  @override
  String get systemOverviewDiskSpaceUnavailable =>
      'Disk space information is unavailable.';

  @override
  String get systemOverviewEmptySubtitle =>
      'Add a Radarr or Sonarr instance to view system data.';

  @override
  String systemOverviewEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Episodes',
      one: '1 Episode',
    );
    return '$_temp0';
  }

  @override
  String systemOverviewFreeOf(String free, String total) {
    return '$free free of $total';
  }

  @override
  String systemOverviewLibrarySize(String size) {
    return '$size Library';
  }

  @override
  String get systemOverviewLibraryUnavailable =>
      'Library statistics are unavailable.';

  @override
  String get systemOverviewLoadFailed => 'Failed to load the system overview.';

  @override
  String get systemOverviewLoading => 'Loading system overview...';

  @override
  String systemOverviewMovieCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Movies',
      one: '1 Movie',
    );
    return '$_temp0';
  }

  @override
  String get systemOverviewNoStorage => 'No storage locations reported.';

  @override
  String systemOverviewSeriesCount(int count) {
    return '$count Series';
  }

  @override
  String get systemOverviewSubtitle => 'Storage, versions, and library sizes';

  @override
  String get systemOverviewTitle => 'System Overview';

  @override
  String systemOverviewUsed(String size, int percent) {
    return 'Used $size ($percent%)';
  }

  @override
  String get systemOverviewVersionUnavailable =>
      'Version information is unavailable.';

  @override
  String get systemQualityProfilesSubtitle =>
      'Available profiles from instances';

  @override
  String get systemResetConfirmBody =>
      'This restores appearance, language, view mode, and notification preferences to their defaults. Configured instances are preserved.';

  @override
  String get systemResetConfirmTitle => 'Reset app settings?';

  @override
  String get systemResetSettings => 'Reset app settings';

  @override
  String get systemResetSettingsSubtitle =>
      'Restore appearance, language, view, and notification defaults';

  @override
  String systemSeedingDaysShort(int count) {
    return '${count}d';
  }

  @override
  String get systemSeedingWarningDisabled => 'Seeding warning disabled';

  @override
  String systemSeedingWarningEnabled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return 'Warn before deleting torrents that seeded for less than $_temp0.';
  }

  @override
  String get systemServer => 'Server';

  @override
  String get systemSettingsReset => 'App settings reset to defaults';

  @override
  String get systemTorrentProtection => 'Torrent Protection';

  @override
  String get systemVersionHistorySubtitle =>
      'Changelog for every published release';

  @override
  String torrentAddFailed(String error) {
    return 'Failed to add torrent: $error';
  }

  @override
  String get torrentAddOptions => 'Options';

  @override
  String get torrentAddOr => 'OR';

  @override
  String get torrentAddSource => 'Source';

  @override
  String get torrentAddSourceRequired =>
      'Please provide URLs or select a .torrent file';

  @override
  String get torrentAddTorrent => 'Add Torrent';

  @override
  String get torrentAdded => 'Torrent added successfully';

  @override
  String get torrentAlsoDeleteFiles => 'Also delete files on disk';

  @override
  String get torrentCategoriesLoadFailed =>
      'Could not load categories. Using free text mode.';

  @override
  String get torrentCategoryOptional => 'Category (Optional)';

  @override
  String get torrentChangeSaveLocation => 'Change Save Location';

  @override
  String get torrentChangeSaveLocationWarning =>
      'This will move all downloaded data to the new location.';

  @override
  String get torrentClearSearch => 'Clear search';

  @override
  String torrentConnectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count connected',
    );
    return '$_temp0';
  }

  @override
  String get torrentCrossSeedExplanation =>
      'Matched as a cross-seed: same release name as the torrent Radarr/Sonarr grabbed, different infohash.';

  @override
  String get torrentDeleteWithFiles => 'Delete with files';

  @override
  String get torrentEmptySubtitle => 'Add a new torrent to start downloading';

  @override
  String get torrentEmptyTitle => 'No Torrents';

  @override
  String get torrentEnterValidPath => 'Please enter a valid path';

  @override
  String torrentEta(String eta) {
    return 'ETA: $eta';
  }

  @override
  String get torrentFiles => 'Files';

  @override
  String get torrentFilterLibraryLink => 'Library link';

  @override
  String get torrentFilterTooltip => 'Filter torrents';

  @override
  String get torrentFiltersSubtitle => 'Combine any number of filters';

  @override
  String get torrentFiltersTitle => 'Torrent filters';

  @override
  String torrentImportFailed(String error) {
    return 'Failed to import: $error';
  }

  @override
  String torrentImportFilesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file(s) imported successfully',
    );
    return '$_temp0';
  }

  @override
  String torrentImportFilesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file(s) selected for import',
    );
    return '$_temp0';
  }

  @override
  String get torrentImportLoadMoviesFailed => 'Failed to load movies';

  @override
  String get torrentImportLoadSeriesFailed => 'Failed to load series';

  @override
  String get torrentImportLoadingMovies => 'Loading movies...';

  @override
  String get torrentImportLoadingSeries => 'Loading series...';

  @override
  String get torrentImportNoFilesSelected => 'No files selected';

  @override
  String torrentImportNoFilesSubtitle(String path) {
    return 'No importable files found in $path';
  }

  @override
  String get torrentImportNoFilesTitle => 'No Files Found';

  @override
  String get torrentImportNoMoviesSubtitle =>
      'No monitored movies match your search.';

  @override
  String get torrentImportNoMoviesTitle => 'No Movies Found';

  @override
  String get torrentImportNoSeriesSubtitle =>
      'No monitored series match your search.';

  @override
  String get torrentImportNoSeriesTitle => 'No Series Found';

  @override
  String get torrentImportSearchHint => 'Search...';

  @override
  String get torrentImportSelectFilesHint =>
      'Select files to import. Tap on a file to configure its mapping.';

  @override
  String get torrentImportSelectTarget => 'Select Target';

  @override
  String get torrentImportToLibrary => 'Import to Media Library';

  @override
  String get torrentImportToMovie => 'Import to Movie';

  @override
  String get torrentImportToSeries => 'Import to Series';

  @override
  String get torrentInfoAddedOn => 'Added On';

  @override
  String get torrentInfoCategory => 'Category';

  @override
  String get torrentInfoHash => 'Hash';

  @override
  String get torrentInfoInstance => 'Instance';

  @override
  String get torrentInfoMedia => 'Media';

  @override
  String get torrentInfoSavePath => 'Save Path';

  @override
  String get torrentLibraryLinksLoadFailed =>
      'Library links could not be loaded.';

  @override
  String get torrentLoadFailed => 'Failed to load torrents';

  @override
  String torrentLoadFilesFailed(String error) {
    return 'Failed to load files: $error';
  }

  @override
  String get torrentLoadPeersFailed => 'Failed to load peers';

  @override
  String get torrentLoadTrackersFailed => 'Failed to load trackers';

  @override
  String get torrentLoading => 'Loading torrents...';

  @override
  String get torrentLoadingFiles => 'Loading files...';

  @override
  String get torrentLoadingPeers => 'Loading peers...';

  @override
  String get torrentLoadingTrackers => 'Loading trackers...';

  @override
  String get torrentLocationMoved =>
      'Location moved successfully. Data is being moved.';

  @override
  String get torrentMove => 'Move';

  @override
  String torrentMoveFailed(String error) {
    return 'Failed to move: $error';
  }

  @override
  String get torrentNewLocation => 'New Location';

  @override
  String get torrentNoFilesFound => 'No files found';

  @override
  String get torrentNoFilterMatches => 'No torrents match the current filters';

  @override
  String get torrentNoPeers => 'No peers connected';

  @override
  String get torrentNoPeersSubtitle =>
      'Peers will appear when the torrent is active';

  @override
  String get torrentNoTrackers => 'No trackers';

  @override
  String get torrentNoTrackersSubtitle =>
      'Announce URLs appear here once qBittorrent has them';

  @override
  String get torrentPause => 'Pause';

  @override
  String torrentPeerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peers',
    );
    return '$_temp0';
  }

  @override
  String get torrentPeers => 'Peers';

  @override
  String torrentPercentCompleted(String percent) {
    return '$percent completed';
  }

  @override
  String torrentPercentDone(String percent) {
    return '$percent done';
  }

  @override
  String torrentPickFileFailed(String error) {
    return 'Failed to pick file: $error';
  }

  @override
  String get torrentRecheck => 'Recheck';

  @override
  String get torrentRememberFilters => 'Remember filters';

  @override
  String get torrentRememberFiltersSubtitle =>
      'Keep this configuration for future sessions';

  @override
  String get torrentRemove => 'Remove';

  @override
  String torrentRemoveConfirm(String name) {
    return 'Are you sure you want to remove \"$name\"?';
  }

  @override
  String torrentRemoveFailed(String error) {
    return 'Failed to remove torrent: $error';
  }

  @override
  String get torrentRemoveTitle => 'Remove Torrent?';

  @override
  String get torrentRemoveTorrent => 'Remove Torrent';

  @override
  String torrentResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count torrents',
    );
    return '$_temp0';
  }

  @override
  String torrentResultCountWithHidden(int count, int hidden) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count torrents · $hidden hidden',
    );
    return '$_temp0';
  }

  @override
  String get torrentResume => 'Resume';

  @override
  String get torrentSavePathOptional => 'Save Path (Optional)';

  @override
  String get torrentSearchHint => 'Search torrents';

  @override
  String get torrentSectionActions => 'Actions';

  @override
  String get torrentSectionInformation => 'Information';

  @override
  String get torrentSectionMediaLibrary => 'Media Library';

  @override
  String get torrentSectionProgress => 'Progress';

  @override
  String get torrentSelectFile => 'Select .torrent File';

  @override
  String get torrentSelectionClear => 'Clear selection';

  @override
  String get torrentSetPriority => 'Set Priority';

  @override
  String get torrentSortAscending => 'Ascending';

  @override
  String get torrentSortDescending => 'Descending';

  @override
  String get torrentStartPaused => 'Start Paused';

  @override
  String get torrentStatDlSpeed => 'DL Speed';

  @override
  String get torrentStatDownloaded => 'Downloaded';

  @override
  String get torrentStatLeechers => 'Leechers';

  @override
  String get torrentStatRatio => 'Ratio';

  @override
  String get torrentStatSeedTime => 'Seed Time';

  @override
  String get torrentStatSeeds => 'Seeds';

  @override
  String get torrentStatTotalSize => 'Total Size';

  @override
  String get torrentStatUlSpeed => 'UL Speed';

  @override
  String get torrentStatUploaded => 'Uploaded';

  @override
  String get torrentTagsCommaSeparated => 'Comma separated';

  @override
  String get torrentTagsLoadFailed =>
      'Could not load tags. Using free text mode.';

  @override
  String get torrentTagsOptional => 'Tags (Optional)';

  @override
  String get torrentTagsSearchHint => 'Type to search or add custom tags';

  @override
  String torrentTrackerDownloads(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count downloads',
      one: '1 download',
    );
    return '$_temp0';
  }

  @override
  String torrentTrackerLeechers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leechers',
      one: '1 leecher',
    );
    return '$_temp0';
  }

  @override
  String torrentTrackerPeers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peers',
      one: '1 peer',
    );
    return '$_temp0';
  }

  @override
  String torrentTrackerSeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seeds',
      one: '1 seed',
    );
    return '$_temp0';
  }

  @override
  String torrentTrackerTier(int tier) {
    return 'Tier $tier';
  }

  @override
  String get torrentTrackers => 'Trackers';

  @override
  String get torrentUrlsHint =>
      'Paste magnet links or HTTP URLs here\nOne per line';

  @override
  String get torrentUrlsLabel => 'Magnet Link or URLs';

  @override
  String get tourActivityBody =>
      'Monitor your download queue, history, and qBittorrent torrents here.';

  @override
  String get tourActivityQueueBody =>
      'Active downloads report progress, size left, and estimated completion. Tap one for details and actions.';

  @override
  String get tourActivityQueueTitle => 'Download queue';

  @override
  String get tourAddInstanceBody =>
      'Tap here to create a new server connection. The next steps walk through the form.';

  @override
  String get tourAddInstanceTitle => 'Add Instance';

  @override
  String get tourCalendarBody =>
      'Track upcoming movie releases and series episodes.';

  @override
  String get tourCalendarEventsBody =>
      'Each card shows what airs or releases next, grouped by day and colour-coded by release type.';

  @override
  String get tourCalendarEventsTitle => 'Upcoming releases';

  @override
  String get tourInstanceApiKeyBody =>
      'Radarr/Sonarr require an API key from Settings → General. qBittorrent uses a Bearer token (v5.2.0+) or Basic Auth.';

  @override
  String get tourInstanceApiKeyTitle => 'API Key';

  @override
  String get tourInstanceNameBody =>
      'A friendly label so you can tell your servers apart (e.g. \"Home Server\").';

  @override
  String get tourInstanceNameTitle => 'Name';

  @override
  String get tourInstanceTypeBody =>
      'Pick Radarr (movies), Sonarr (series), or qBittorrent (downloads). Each needs its own connection.';

  @override
  String get tourInstanceTypeTitle => 'Choose the server type';

  @override
  String get tourInstanceUrlBody =>
      'Your server address including http(s):// and port, e.g. http://192.168.1.10:7878.';

  @override
  String get tourInstanceUrlTitle => 'URL';

  @override
  String get tourInstancesBody =>
      'Your Radarr, Sonarr, and qBittorrent servers live here. Let\'s add your first one.';

  @override
  String get tourInstancesTitle => 'Instances';

  @override
  String get tourMockupBanner =>
      'Sample content shown during the tour. It disappears once the tour ends.';

  @override
  String get tourMoviesLibraryBody =>
      'Every movie Radarr manages shows up here with its monitoring and download status.';

  @override
  String get tourMoviesLibraryTitle => 'Your movie library';

  @override
  String get tourMoviesSearchBody => 'Find movies in your library by title.';

  @override
  String get tourMoviesSortBody =>
      'Reorder and filter your library to browse faster.';

  @override
  String get tourMoviesSortTitle => 'Sort & Filter';

  @override
  String get tourNavigationBody =>
      'Switch between Movies, Series, Calendar, Activity, and Settings anytime.';

  @override
  String get tourNavigationTitle => 'Navigation';

  @override
  String get tourSaveInstanceBody =>
      'When everything checks out, save to finish setup. You can add the other servers any time from Settings.';

  @override
  String get tourSaveInstanceTitle => 'Save Instance';

  @override
  String get tourSeriesLibraryBody =>
      'Your Sonarr series live here, with season counts and how much of each show is already downloaded.';

  @override
  String get tourSeriesLibraryTitle => 'Your series library';

  @override
  String get tourSkip => 'Skip';

  @override
  String get tourTestConnectionBody =>
      'Verifies the URL and credentials before saving.';

  @override
  String get tourTestConnectionTitle => 'Test Connection';

  @override
  String get tourTorrentsBody =>
      'Torrents from qBittorrent report live speed, ratio, and peers, with pause, resume, and import actions.';

  @override
  String get tourTorrentsTitle => 'Torrents';

  @override
  String get updateAndRestart => 'Update and restart';

  @override
  String get updateAvailableTitle => 'New Version Available';

  @override
  String get updateChangelog => 'Changelog:';

  @override
  String get updateDownloadingTitle => 'Downloading Update';

  @override
  String get updateInstallingTitle => 'Installing...';

  @override
  String get updateLater => 'Later';

  @override
  String get updateNow => 'Update Now';

  @override
  String get updatePreparing => 'Preparing the update...';

  @override
  String get updateRestartNotice =>
      'The app will close and restart to finish the update.';

  @override
  String get updateUnexpectedError => 'An unexpected error occurred.';

  @override
  String updateVersion(String version) {
    return 'Version: $version';
  }

  @override
  String get versionHistoryEmptySubtitle =>
      'Release history could not be loaded.';

  @override
  String get versionHistoryEmptyTitle => 'No releases available';

  @override
  String get versionHistoryInstalled => 'Installed';

  @override
  String versionHistoryLoadFailed(String error) {
    return 'Failed to load version history: $error';
  }

  @override
  String get versionHistoryLoading => 'Loading version history...';

  @override
  String get versionHistoryTitle => 'Version History';

  @override
  String get watchingContinueWatching => 'Continue Watching';

  @override
  String get watchingEmptySubtitle =>
      'Media you pause in Jellyfin and the next episodes of series you follow will appear here.';

  @override
  String get watchingEmptyTitle => 'Nothing in progress';

  @override
  String get watchingLoading => 'Loading continue watching...';

  @override
  String get watchingNextEpisode => 'Next episode';

  @override
  String watchingNextEpisodeRuntime(String runtime) {
    return 'Next episode · $runtime';
  }

  @override
  String get watchingNextUp => 'Next Up';

  @override
  String get whatsNewNoNotes => 'This release does not include release notes.';

  @override
  String whatsNewTitle(String version) {
    return 'What\'s New in v$version';
  }

  @override
  String get whatsNewViewAllVersions => 'View All Versions';

  @override
  String get widgetsClosePoster => 'Close poster';

  @override
  String widgetsCustomFormatScore(String score) {
    return 'Score: $score';
  }

  @override
  String get widgetsDeleteFile => 'Delete File';

  @override
  String get widgetsEventAdditionalData => 'Additional Data';

  @override
  String get widgetsEventDate => 'Date';

  @override
  String get widgetsEventDetailsTitle => 'Event Details';

  @override
  String get widgetsEventSourceTitle => 'Source Title';

  @override
  String get widgetsEventType => 'Event Type';

  @override
  String get widgetsExtraFileMetadata => 'Metadata';

  @override
  String get widgetsExtraFileOther => 'Other';

  @override
  String get widgetsExtraFileSubtitle => 'Subtitle';

  @override
  String get widgetsFileAudioBitrate => 'Audio Bitrate';

  @override
  String get widgetsFileAudioChannels => 'Audio Channels';

  @override
  String get widgetsFileAudioCodec => 'Audio Codec';

  @override
  String get widgetsFileAudioLanguages => 'Audio Languages';

  @override
  String get widgetsFileAudioStreams => 'Audio Streams';

  @override
  String get widgetsFileBitDepth => 'Bit Depth';

  @override
  String get widgetsFileCustomFormats => 'Custom Formats';

  @override
  String get widgetsFileDateAdded => 'Date Added';

  @override
  String get widgetsFileDetailsTitle => 'File Details';

  @override
  String get widgetsFileDuration => 'Duration';

  @override
  String get widgetsFileDynamicRange => 'Dynamic Range';

  @override
  String get widgetsFileFrameRate => 'Frame Rate';

  @override
  String get widgetsFileGeneral => 'General';

  @override
  String get widgetsFileHdrType => 'HDR Type';

  @override
  String get widgetsFileMediaInfo => 'Media Info';

  @override
  String get widgetsFilePath => 'Path';

  @override
  String get widgetsFileResolution => 'Resolution';

  @override
  String get widgetsFileRevision => 'Revision';

  @override
  String get widgetsFileScanType => 'Scan Type';

  @override
  String get widgetsFileSource => 'Source';

  @override
  String get widgetsFileSubtitles => 'Subtitles';

  @override
  String get widgetsFileVideoBitrate => 'Video Bitrate';

  @override
  String get widgetsFileVideoCodec => 'Video Codec';

  @override
  String get widgetsNoPreviousOnline =>
      'No previous online connection recorded';

  @override
  String get widgetsNoTagsAvailable => 'No tags available';

  @override
  String get widgetsNotifications => 'Notifications';

  @override
  String get widgetsOffline => 'Offline';

  @override
  String widgetsOfflineCacheCaveat(String lastOnline, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
    );
    return '$lastOnline · Cached images may be up to $_temp0 old';
  }

  @override
  String get widgetsPlay => 'Play';

  @override
  String get widgetsQueueDownloadFailed => 'Download failed';

  @override
  String get widgetsQueueDownloadPaused => 'Download paused';

  @override
  String get widgetsQueueDownloadPending => 'Download pending';

  @override
  String get widgetsQueueDownloadWarning => 'Download warning';

  @override
  String get widgetsQueueStatusUnknown => 'Status unknown';

  @override
  String widgetsSelectInstance(String type) {
    return 'Select $type instance';
  }

  @override
  String get widgetsSelectTags => 'Select Tags';

  @override
  String get widgetsSomeInstancesFailed => 'Some instances could not be loaded';

  @override
  String get widgetsSortBy => 'Sort By';

  @override
  String get widgetsSortOrder => 'Order';

  @override
  String widgetsTagButtonWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get widgetsUnknownFile => 'Unknown File';
}
