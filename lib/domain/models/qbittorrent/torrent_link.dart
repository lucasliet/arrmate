import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../instance/instance.dart';

/// Describes how a torrent in the download client relates to the Radarr/Sonarr
/// media library.
enum TorrentLinkStatus {
  /// The torrent backs a movie/episode that is still in the catalog with its
  /// media file in place.
  linked,

  /// The torrent maps to a catalog item that still exists, but whose media file
  /// was already deleted.
  fileMissing,

  /// The torrent was managed by Radarr/Sonarr (it sits in one of their download
  /// client categories) but no catalog entry references it anymore — only the
  /// torrent survived.
  orphan,

  /// The torrent was never related to the media library (added by hand or by
  /// another tool).
  external,

  /// The relation could not be determined: the index is still loading, no
  /// Radarr/Sonarr instance is configured, or every instance failed to answer.
  unknown;

  /// Short user-facing name of the status.
  String get label {
    switch (this) {
      case TorrentLinkStatus.linked:
        return 'In library';
      case TorrentLinkStatus.fileMissing:
        return 'File removed';
      case TorrentLinkStatus.orphan:
        return 'Orphan';
      case TorrentLinkStatus.external:
        return 'Not in library';
      case TorrentLinkStatus.unknown:
        return 'Unknown';
    }
  }

  /// Longer explanation shown in the torrent details sheet.
  String get description {
    switch (this) {
      case TorrentLinkStatus.linked:
        return 'This torrent backs an item that is still in the media library.';
      case TorrentLinkStatus.fileMissing:
        return 'The catalog item still exists, but its media file was deleted.';
      case TorrentLinkStatus.orphan:
        return 'Radarr/Sonarr downloaded this torrent, but the catalog item is '
            'gone. Only the torrent is left.';
      case TorrentLinkStatus.external:
        return 'This torrent was downloaded outside the media library.';
      case TorrentLinkStatus.unknown:
        return 'The library relation could not be determined.';
    }
  }

  /// Icon representing the status.
  IconData get icon {
    switch (this) {
      case TorrentLinkStatus.linked:
        return Icons.link;
      case TorrentLinkStatus.fileMissing:
        return Icons.report_gmailerrorred_outlined;
      case TorrentLinkStatus.orphan:
        return Icons.link_off;
      case TorrentLinkStatus.external:
        return Icons.download_outlined;
      case TorrentLinkStatus.unknown:
        return Icons.help_outline;
    }
  }

  /// Whether the status warrants extra visual weight in the list.
  bool get isCritical => this == TorrentLinkStatus.orphan;

  /// Resolves the status color from the active [colorScheme].
  Color color(ColorScheme colorScheme) {
    switch (this) {
      case TorrentLinkStatus.linked:
        return colorScheme.primary;
      case TorrentLinkStatus.fileMissing:
        return colorScheme.tertiary;
      case TorrentLinkStatus.orphan:
        return colorScheme.error;
      case TorrentLinkStatus.external:
      case TorrentLinkStatus.unknown:
        return colorScheme.onSurfaceVariant;
    }
  }
}

/// Relation between a qBittorrent torrent and the media library.
///
/// Built by the torrent link index from Radarr/Sonarr history and queue data,
/// where the torrent infohash is exposed as `downloadId`.
class TorrentLink extends Equatable {
  /// How the torrent relates to the library.
  final TorrentLinkStatus status;

  /// Identifier of the Radarr/Sonarr instance that owns the relation.
  final String? instanceId;

  /// Label of the owning instance, for display.
  final String? instanceLabel;

  /// Type of the owning instance.
  final InstanceType? instanceType;

  /// Radarr movie id, when the torrent maps to a movie.
  final int? movieId;

  /// Sonarr series id, when the torrent maps to an episode.
  final int? seriesId;

  /// Sonarr episode id, when the torrent maps to an episode.
  final int? episodeId;

  /// Season number of the linked episode.
  final int? seasonNumber;

  /// Episode number of the linked episode.
  final int? episodeNumber;

  /// Title of the linked movie or series.
  final String? mediaTitle;

  /// Release title recorded by Radarr/Sonarr, used as a fallback label.
  final String? sourceTitle;

  /// Whether this relation was inherited from a same-named sibling torrent
  /// instead of being matched by infohash.
  ///
  /// A cross-seeded release keeps its name but gets a new infohash on every
  /// tracker, so Radarr/Sonarr only ever reference one of the copies.
  final bool isCrossSeed;

  const TorrentLink({
    required this.status,
    this.instanceId,
    this.instanceLabel,
    this.instanceType,
    this.movieId,
    this.seriesId,
    this.episodeId,
    this.seasonNumber,
    this.episodeNumber,
    this.mediaTitle,
    this.sourceTitle,
    this.isCrossSeed = false,
  });

  /// A link whose relation could not be determined.
  static const unknown = TorrentLink(status: TorrentLinkStatus.unknown);

  /// Whether the torrent points at a known catalog item.
  bool get hasMedia => movieId != null || seriesId != null;

  /// `SxxEyy` label of the linked episode, when known.
  String? get episodeLabel {
    if (seasonNumber == null || episodeNumber == null) return null;
    final season = seasonNumber!.toString().padLeft(2, '0');
    final episode = episodeNumber!.toString().padLeft(2, '0');
    return 'S${season}E$episode';
  }

  /// Compact label for the list badge.
  ///
  /// Falls back to the status label when no media information is available.
  String get displayLabel {
    if (status == TorrentLinkStatus.linked ||
        status == TorrentLinkStatus.fileMissing) {
      final title = mediaTitle ?? sourceTitle;
      if (title == null || title.isEmpty) return status.label;
      final episode = episodeLabel;
      return episode == null ? title : '$title · $episode';
    }
    return status.label;
  }

  /// Returns a copy of this link with [status] replaced.
  TorrentLink copyWithStatus(TorrentLinkStatus status) {
    return TorrentLink(
      status: status,
      instanceId: instanceId,
      instanceLabel: instanceLabel,
      instanceType: instanceType,
      movieId: movieId,
      seriesId: seriesId,
      episodeId: episodeId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      mediaTitle: mediaTitle,
      sourceTitle: sourceTitle,
      isCrossSeed: isCrossSeed,
    );
  }

  /// Returns a copy of this link flagged as inherited by a cross-seed sibling.
  TorrentLink asCrossSeed() {
    if (isCrossSeed) return this;
    return TorrentLink(
      status: status,
      instanceId: instanceId,
      instanceLabel: instanceLabel,
      instanceType: instanceType,
      movieId: movieId,
      seriesId: seriesId,
      episodeId: episodeId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      mediaTitle: mediaTitle,
      sourceTitle: sourceTitle,
      isCrossSeed: true,
    );
  }

  @override
  List<Object?> get props => [
    status,
    instanceId,
    instanceLabel,
    instanceType,
    movieId,
    seriesId,
    episodeId,
    seasonNumber,
    episodeNumber,
    mediaTitle,
    sourceTitle,
    isCrossSeed,
  ];
}
