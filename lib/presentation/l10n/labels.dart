/// Localized labels for domain and presentation enums and models.
///
/// The domain layer keeps its English `label`/`title`/`description` getters
/// for logs, tests and matching; the UI goes through the extensions exported
/// here, which take the current [AppLocalizations] (usually `context.l10n`).
library;

export '../../core/l10n/app_locale.dart' show AppLocalizations;
export 'app_labels.dart';
export 'error_messages.dart';
export 'history_queue_labels.dart';
export 'media_labels.dart';
export 'torrent_status_labels.dart';
