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
