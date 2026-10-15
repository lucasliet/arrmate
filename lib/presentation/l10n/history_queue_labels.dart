import '../../core/l10n/app_locale.dart';
import '../../domain/models/models.dart';

/// Localized labels for [HistoryEventType].
extension HistoryEventTypeL10n on HistoryEventType {
  /// Returns the translated short badge [HistoryEventType.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    HistoryEventType.grabbed => l10n.labelGrabbed,
    HistoryEventType.imported => l10n.labelHistoryImported,
    HistoryEventType.failed => l10n.labelFailed,
    HistoryEventType.ignored => l10n.labelHistoryIgnored,
    HistoryEventType.renamed => l10n.labelHistoryRenamed,
    HistoryEventType.deleted => l10n.labelDeleted,
    HistoryEventType.unknown => l10n.commonUnknown,
  };

  /// Returns the translated [HistoryEventType.title].
  String localizedTitle(AppLocalizations l10n) => switch (this) {
    HistoryEventType.grabbed => l10n.labelHistoryTitleGrabbed,
    HistoryEventType.imported => l10n.labelHistoryTitleImported,
    HistoryEventType.failed => l10n.labelHistoryTitleFailed,
    HistoryEventType.ignored => l10n.labelHistoryTitleIgnored,
    HistoryEventType.renamed => l10n.labelHistoryTitleRenamed,
    HistoryEventType.deleted => l10n.labelHistoryTitleDeleted,
    HistoryEventType.unknown => l10n.labelHistoryTitleUnknown,
  };
}

/// Localized labels for [HistoryEvent].
extension HistoryEventL10n on HistoryEvent {
  /// Returns the translated [HistoryEvent.languageLabel].
  ///
  /// Language names come from the server and are kept as is; only the
  /// "Unknown" fallback is translated.
  String localizedLanguageLabel(AppLocalizations l10n) {
    final names = languages;
    if (names == null || names.isEmpty) return l10n.commonUnknown;
    return languageLabel;
  }

  /// Returns the translated [HistoryEvent.description].
  ///
  /// Server-provided failure messages are returned untouched.
  String localizedDescription(AppLocalizations l10n) {
    final indexerName = indexer ?? l10n.labelHistoryFallbackIndexer;
    final clientName = downloadClient ?? l10n.labelHistoryFallbackClient;

    switch (eventType) {
      case HistoryEventType.grabbed:
        return isMovie
            ? l10n.labelHistoryMovieGrabbed(indexerName, clientName)
            : l10n.labelHistoryEpisodeGrabbed(indexerName, clientName);
      case HistoryEventType.imported:
        return isMovie
            ? l10n.labelHistoryMovieImported(clientName)
            : l10n.labelHistoryEpisodeImported(clientName);
      case HistoryEventType.failed:
        return message ?? l10n.labelHistoryDownloadFailedDescription;
      case HistoryEventType.ignored:
        return message ?? l10n.labelHistoryDownloadIgnoredDescription;
      case HistoryEventType.renamed:
        return isMovie
            ? l10n.labelHistoryMovieRenamed
            : l10n.labelHistoryEpisodeRenamed;
      case HistoryEventType.deleted:
        return switch (data?['reason']) {
          'Manual' => l10n.labelHistoryDeletedManual,
          'MissingFromDisk' => l10n.labelHistoryDeletedMissingFromDisk,
          'Upgrade' => l10n.labelHistoryDeletedUpgrade,
          _ => l10n.labelHistoryDeletedGeneric,
        };
      case HistoryEventType.unknown:
        return l10n.labelHistoryUnknownEventDescription;
    }
  }
}

/// Localized labels for [QueueStatus].
extension QueueStatusL10n on QueueStatus {
  /// Returns the translated [QueueStatus.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    QueueStatus.unknown => l10n.commonUnknown,
    QueueStatus.queued => l10n.labelQueued,
    QueueStatus.paused => l10n.labelPaused,
    QueueStatus.downloading => l10n.labelDownloading,
    QueueStatus.completed => l10n.labelQueueCompleted,
    QueueStatus.failed => l10n.labelFailed,
    QueueStatus.warning => l10n.labelQueueWarning,
    QueueStatus.delay => l10n.labelQueuePending,
  };
}

/// Localized labels for [QueueItem].
extension QueueItemL10n on QueueItem {
  /// Returns the translated [QueueItem.displayTitle].
  String localizedDisplayTitle(AppLocalizations l10n) {
    final movieItem = movie;
    if (movieItem != null) return movieItem.title;
    final seriesItem = series;
    final season = seasonNumber;
    if (seriesItem != null && taskGroupCount > 1 && season != null) {
      return l10n.formatTitleWithSeason(seriesItem.title, season);
    }
    if (seriesItem != null) return seriesItem.title;
    return title;
  }

  /// Returns the translated [QueueItem.languagesLabel].
  ///
  /// Language names come from the server; only the "Unknown" fallback is
  /// translated.
  String localizedLanguagesLabel(AppLocalizations l10n) {
    final hasNames = languages.any(
      (language) => language.name?.trim().isNotEmpty ?? false,
    );
    return hasNames ? languagesLabel : l10n.commonUnknown;
  }
}

/// Localized labels for [ImportableFile].
extension ImportableFileL10n on ImportableFile {
  /// Returns the translated [ImportableFile.displayName].
  String localizedDisplayName(AppLocalizations l10n) =>
      name ?? relativePath ?? path ?? l10n.labelUnnamedFile;
}
