import '../../core/l10n/app_locale.dart';
import '../../domain/models/models.dart';

/// Localized labels for [TorrentStatus].
extension TorrentStatusL10n on TorrentStatus {
  /// Returns the translated [TorrentStatus.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    TorrentStatus.downloading => l10n.labelDownloading,
    TorrentStatus.uploading => l10n.labelSeeding,
    TorrentStatus.stalledDL => l10n.labelTorrentStalledDl,
    TorrentStatus.stalledUP => l10n.labelTorrentStalledUp,
    TorrentStatus.pausedDL => l10n.labelTorrentPausedDl,
    TorrentStatus.pausedUP => l10n.labelTorrentPausedUp,
    TorrentStatus.queuedDL => l10n.labelTorrentQueuedDl,
    TorrentStatus.queuedUP => l10n.labelTorrentQueuedUp,
    TorrentStatus.checkingDL ||
    TorrentStatus.checkingUP ||
    TorrentStatus.checkingResumeData => l10n.labelTorrentChecking,
    TorrentStatus.missingFiles => l10n.labelTorrentMissingFiles,
    TorrentStatus.error => l10n.labelError,
    TorrentStatus.unknown => l10n.commonUnknown,
  };
}

/// Localized labels for [TorrentStatusFilter].
extension TorrentStatusFilterL10n on TorrentStatusFilter {
  /// Returns the translated [TorrentStatusFilter.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    TorrentStatusFilter.all => l10n.labelAll,
    TorrentStatusFilter.downloading => l10n.labelDownloading,
    TorrentStatusFilter.seeding => l10n.labelSeeding,
    TorrentStatusFilter.paused => l10n.labelPaused,
    TorrentStatusFilter.error => l10n.labelError,
  };
}

/// Localized labels for [TorrentLinkFilter].
extension TorrentLinkFilterL10n on TorrentLinkFilter {
  /// Returns the translated [TorrentLinkFilter.label].
  String localizedLabel(AppLocalizations l10n) =>
      status?.localizedLabel(l10n) ?? l10n.labelAll;
}

/// Localized labels for [TorrentSortOption].
extension TorrentSortOptionL10n on TorrentSortOption {
  /// Returns the translated [TorrentSortOption.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    TorrentSortOption.activity => l10n.labelTorrentSortActivity,
    TorrentSortOption.addedDate => l10n.labelTorrentSortAddedDate,
    TorrentSortOption.progress => l10n.labelTorrentSortProgress,
    TorrentSortOption.size => l10n.commonSize,
    TorrentSortOption.downloadSpeed => l10n.labelTorrentSortDownloadSpeed,
    TorrentSortOption.ratio => l10n.labelTorrentSortRatio,
    TorrentSortOption.seedTime => l10n.labelTorrentSortSeedTime,
    TorrentSortOption.name => l10n.labelTorrentSortName,
  };
}

/// Localized labels for [TorrentLinkStatus].
extension TorrentLinkStatusL10n on TorrentLinkStatus {
  /// Returns the translated short [TorrentLinkStatus.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    TorrentLinkStatus.linked => l10n.labelTorrentLinkLinked,
    TorrentLinkStatus.fileMissing => l10n.labelTorrentLinkFileMissing,
    TorrentLinkStatus.orphan => l10n.labelTorrentLinkOrphan,
    TorrentLinkStatus.external => l10n.labelTorrentLinkExternal,
    TorrentLinkStatus.unknown => l10n.commonUnknown,
  };

  /// Returns the translated [TorrentLinkStatus.description].
  String localizedDescription(AppLocalizations l10n) => switch (this) {
    TorrentLinkStatus.linked => l10n.labelTorrentLinkLinkedDescription,
    TorrentLinkStatus.fileMissing =>
      l10n.labelTorrentLinkFileMissingDescription,
    TorrentLinkStatus.orphan => l10n.labelTorrentLinkOrphanDescription,
    TorrentLinkStatus.external => l10n.labelTorrentLinkExternalDescription,
    TorrentLinkStatus.unknown => l10n.labelTorrentLinkUnknownDescription,
  };
}

/// Localized labels for [TorrentLink].
extension TorrentLinkL10n on TorrentLink {
  /// Returns the translated [TorrentLink.displayLabel].
  ///
  /// Media titles are kept as is; only the status fallback is translated.
  String localizedDisplayLabel(AppLocalizations l10n) {
    final hasMedia =
        status == TorrentLinkStatus.linked ||
        status == TorrentLinkStatus.fileMissing;
    final title = mediaTitle ?? sourceTitle;
    if (!hasMedia || title == null || title.isEmpty) {
      return status.localizedLabel(l10n);
    }
    return displayLabel;
  }
}

/// Localized labels for [TorrentTrackerStatus].
extension TorrentTrackerStatusL10n on TorrentTrackerStatus {
  /// Returns the translated [TorrentTrackerStatus.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    TorrentTrackerStatus.disabled => l10n.labelTrackerDisabled,
    TorrentTrackerStatus.notContacted => l10n.labelTrackerNotContacted,
    TorrentTrackerStatus.working => l10n.labelTrackerWorking,
    TorrentTrackerStatus.updating => l10n.labelTrackerUpdating,
    TorrentTrackerStatus.notWorking => l10n.labelTrackerNotWorking,
    TorrentTrackerStatus.unknown => l10n.commonUnknown,
  };
}

/// Localized labels for [FilePriority].
extension FilePriorityL10n on FilePriority {
  /// Returns the translated [FilePriority.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    FilePriority.doNotDownload => l10n.labelFilePriorityDoNotDownload,
    FilePriority.low => l10n.labelFilePriorityLow,
    FilePriority.normal => l10n.labelFilePriorityNormal,
    FilePriority.high => l10n.labelFilePriorityHigh,
    FilePriority.maximal => l10n.labelFilePriorityMaximal,
  };
}
