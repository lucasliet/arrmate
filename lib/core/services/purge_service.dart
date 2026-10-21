import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/notification/app_notification.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/services/in_app_notification_service.dart';
import '../../core/services/logger_service.dart';
import '../../core/utils/cross_seed_matcher.dart';
import '../../core/utils/media_downloads.dart';
import '../../data/api/qbittorrent_service.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

/// Outcome of the qBittorrent portion of a purge.
class _TorrentPurgeOutcome extends Equatable {
  final List<String> torrentHashesDeleted;
  final List<String> crossSeedDuplicatesDeleted;
  final bool qbittorrentSkipped;

  const _TorrentPurgeOutcome({
    required this.torrentHashesDeleted,
    required this.crossSeedDuplicatesDeleted,
    required this.qbittorrentSkipped,
  });

  static const _empty = _TorrentPurgeOutcome(
    torrentHashesDeleted: [],
    crossSeedDuplicatesDeleted: [],
    qbittorrentSkipped: false,
  );

  @override
  List<Object?> get props => [
    torrentHashesDeleted,
    crossSeedDuplicatesDeleted,
    qbittorrentSkipped,
  ];
}

/// Signature shared by `MovieRepository.deleteQueueItem` and
/// `SeriesRepository.deleteQueueItem`.
typedef DeleteQueueItem =
    Future<void> Function(
      int id, {
      bool removeFromClient,
      bool blocklist,
      bool skipRedownload,
    });

/// User decision when the seeding-time warning dialog is shown.
enum SeedingAction {
  /// Abort the whole purge (delete nothing).
  cancel,

  /// Proceed but keep torrents below the seeding threshold in qBittorrent.
  keepBelowThreshold,

  /// Delete every resolved torrent regardless of seeding time.
  deleteAll,
}

/// Whether [torrent] seeded for less than [minimumSeedingSeconds].
///
/// The single seeding-time rule shared by every flow that deletes torrents
/// with their files (library purges and the torrent list bulk delete), so the
/// warning fires under the same conditions everywhere. A threshold of `0`
/// disables the guard.
bool isBelowSeedingThreshold(Torrent torrent, int minimumSeedingSeconds) =>
    minimumSeedingSeconds > 0 && torrent.seedingTime < minimumSeedingSeconds;

/// Context of a purge operation, used when emitting per-torrent
/// notifications so the notification carries the origin (movie/series/season).
typedef PurgeContext = ({String type, int id, int? seasonNumber});

/// Read-only preview of the torrents a purge would delete.
///
/// Returned by the `preview*` methods. The catalog and media-file deletions
/// are NOT part of this preview — only the qBittorrent side. The UI inspects
/// [belowThreshold] to decide whether to show the [SeedingAction] dialog
/// before committing.
class PurgePreview extends Equatable {
  /// Every torrent (source + cross-seed) that the purge may delete.
  final List<Torrent> torrentsToDelete;

  /// Cross-seed torrents requiring explicit user approval before deletion.
  final List<Torrent> crossSeedCandidates;

  /// Source torrents of a season purge whose download also covers episodes
  /// outside the purged seasons (e.g. a complete-series pack).
  ///
  /// Deleting one with its files removes the other seasons' copies too, so
  /// each one requires explicit user approval. Always empty for movie and
  /// series purges.
  final List<Torrent> sharedPackCandidates;

  /// Subset of [torrentsToDelete] whose seeding time is below the configured
  /// threshold. Empty when no warning is needed.
  final List<Torrent> belowThreshold;

  /// `true` when qBittorrent steps were skipped because no instance is
  /// configured in the app.
  final bool qbittorrentSkipped;

  const PurgePreview({
    required this.torrentsToDelete,
    required this.crossSeedCandidates,
    required this.belowThreshold,
    required this.qbittorrentSkipped,
    this.sharedPackCandidates = const [],
  });

  /// The [crossSeedCandidates] still worth asking about once the user decided
  /// on the [sharedPackCandidates].
  ///
  /// A cross-seed copy of a pack the user kept is left out: it usually shares
  /// the pack's data on disk, so deleting it with its files would remove the
  /// very seasons the user chose to keep. [PurgeService.purgeSeason] keeps such
  /// copies regardless, so asking about them would only mislead.
  List<Torrent> crossSeedCandidatesFor(Set<String> approvedSharedPackHashes) {
    final keptPackNames = _keptPackNames(
      sharedPackCandidates,
      approvedSharedPackHashes,
    );
    return [
      for (final t in crossSeedCandidates)
        if (!keptPackNames.contains(normalizeTorrentName(t.name))) t,
    ];
  }

  @override
  List<Object?> get props => [
    torrentsToDelete,
    crossSeedCandidates,
    sharedPackCandidates,
    belowThreshold,
    qbittorrentSkipped,
  ];
}

/// Outcome of a purge operation.
///
/// Purge removes the movie/series from the Radarr/Sonarr catalog, deletes its
/// media files on disk, removes any active queue items, and deletes the source
/// torrents (plus cross-seed duplicates) from qBittorrent with their files.
class PurgeResult extends Equatable {
  /// Number of queue items removed from Radarr/Sonarr.
  final int queueItemsRemoved;

  /// `1` if the movie/series was deleted from the catalog, `0` otherwise.
  final int catalogDeleted;

  /// Number of media files found before the *arr catalog deletion.
  final int mediaFilesDeleted;

  /// Hashes of source torrents deleted in qBittorrent.
  final List<String> torrentHashesDeleted;

  /// Hashes of cross-seed duplicates deleted in qBittorrent.
  ///
  /// These are torrents not in the source-hash set whose normalized `name`
  /// matched a source torrent and were explicitly approved by the user.
  final List<String> crossSeedDuplicatesDeleted;

  /// `true` when qBittorrent steps were skipped because no instance is
  /// configured in the app.
  final bool qbittorrentSkipped;

  const PurgeResult({
    required this.queueItemsRemoved,
    required this.catalogDeleted,
    required this.mediaFilesDeleted,
    required this.torrentHashesDeleted,
    required this.crossSeedDuplicatesDeleted,
    required this.qbittorrentSkipped,
  });

  @override
  List<Object?> get props => [
    queueItemsRemoved,
    catalogDeleted,
    mediaFilesDeleted,
    torrentHashesDeleted,
    crossSeedDuplicatesDeleted,
    qbittorrentSkipped,
  ];

  /// Number of torrents removed from qBittorrent, source torrents and
  /// approved cross-seed duplicates together.
  int get torrentsDeleted =>
      torrentHashesDeleted.length + crossSeedDuplicatesDeleted.length;

  /// Formats this result into a multi-line snackbar summary.
  ///
  /// [label] is the first line announcing the operation (e.g.
  /// `'Movie purged.'`). The remaining lines are written in the language of
  /// [l10n], or in English when it is omitted.
  String formatSummary({required String label, AppLocalizations? l10n}) {
    final strings = l10n ?? _englishLocalizations();
    final lines = <String>[label];
    lines.add(strings.corePurgeSummaryQueueItems(queueItemsRemoved));
    lines.add(strings.corePurgeSummaryMediaFiles(mediaFilesDeleted));
    if (qbittorrentSkipped) {
      lines.add(strings.corePurgeSummaryQbittorrentSkipped);
    } else {
      final crossSeed = crossSeedDuplicatesDeleted.length;
      final torrents = torrentHashesDeleted.length;
      lines.add(
        crossSeed > 0
            ? strings.corePurgeSummaryTorrentsWithCrossSeed(torrents, crossSeed)
            : strings.corePurgeSummaryTorrents(torrents),
      );
    }
    return lines.join('\n');
  }
}

/// Normalized names of the [sharedPacks] whose hash is not in
/// [approvedSharedPackHashes], i.e. the multi-season packs a purge keeps.
Set<String> _keptPackNames(
  Iterable<Torrent> sharedPacks,
  Set<String> approvedSharedPackHashes,
) {
  return {
    for (final t in sharedPacks)
      if (!approvedSharedPackHashes.contains(t.hash.toLowerCase()))
        normalizeTorrentName(t.name),
  };
}

/// English translations, used when no [AppLocalizations] is supplied.
AppLocalizations _englishLocalizations() =>
    appLocalizationsFor(const Locale('en'));

/// Orchestrates a full purge of a movie or series across Radarr/Sonarr and
/// qBittorrent.
///
/// The service reads repositories/services fresh from the Riverpod provider at
/// call time via injected factory closures, so it always uses the currently
/// selected instances.
///
/// Cross-seed detection matches normalized torrent names. Candidates must be
/// explicitly approved by the user before their files are deleted.
class PurgeService {
  final MovieRepository? Function() _movieRepositoryFactory;
  final SeriesRepository? Function() _seriesRepositoryFactory;
  final QBittorrentService? Function() _qbittorrentServiceFactory;
  final InAppNotificationService? Function() _inAppNotificationServiceFactory;
  final AppLocalizations Function() _localizations;
  final Uuid _uuid;

  /// Creates the service.
  ///
  /// [localizations] supplies the translations for the in-app notifications
  /// the purge emits; English is used when it is omitted.
  PurgeService({
    required MovieRepository? Function() movieRepositoryFactory,
    required SeriesRepository? Function() seriesRepositoryFactory,
    required QBittorrentService? Function() qbittorrentServiceFactory,
    required InAppNotificationService? Function()
    inAppNotificationServiceFactory,
    AppLocalizations Function()? localizations,
    Uuid? uuid,
  }) : _localizations = localizations ?? _englishLocalizations,
       _movieRepositoryFactory = movieRepositoryFactory,
       _seriesRepositoryFactory = seriesRepositoryFactory,
       _qbittorrentServiceFactory = qbittorrentServiceFactory,
       _inAppNotificationServiceFactory = inAppNotificationServiceFactory,
       _uuid = uuid ?? const Uuid();

  /// Purges a movie from Radarr and qBittorrent.
  Future<PurgeResult> purgeMovie(
    int movieId, {
    Set<String> approvedCrossSeedHashes = const {},
  }) async {
    final repository = _movieRepositoryFactory();
    if (repository == null) {
      throw StateError('Movie repository not available');
    }

    logger.info('[PurgeService] Purging movie $movieId');

    final downloads = await collectMovieDownloads(repository, movieId);
    final mediaFilesDeleted = await _countMovieFiles(repository, movieId);
    await repository.deleteMovie(
      movieId,
      deleteFiles: true,
      addExclusion: false,
    );
    final queueItemsRemoved = await _removeQueueItems(
      repository.deleteQueueItem,
      downloads.queueIds,
    );
    logger.info(
      '[PurgeService] Movie $movieId deleted (files: $mediaFilesDeleted)',
    );

    final torrentOutcome = await _purgeTorrents(
      downloads.hashes,
      approvedCrossSeedHashes: approvedCrossSeedHashes,
      context: (type: 'movie', id: movieId, seasonNumber: null),
    );

    return PurgeResult(
      queueItemsRemoved: queueItemsRemoved,
      catalogDeleted: 1,
      mediaFilesDeleted: mediaFilesDeleted,
      torrentHashesDeleted: torrentOutcome.torrentHashesDeleted,
      crossSeedDuplicatesDeleted: torrentOutcome.crossSeedDuplicatesDeleted,
      qbittorrentSkipped: torrentOutcome.qbittorrentSkipped,
    );
  }

  /// Purges a series from Sonarr and qBittorrent.
  Future<PurgeResult> purgeSeries(
    int seriesId, {
    Set<String> approvedCrossSeedHashes = const {},
  }) async {
    final repository = _seriesRepositoryFactory();
    if (repository == null) {
      throw StateError('Series repository not available');
    }

    logger.info('[PurgeService] Purging series $seriesId');

    final downloads = await collectSeriesDownloads(repository, seriesId);
    final mediaFilesDeleted = await _countSeriesFiles(repository, seriesId);
    await repository.deleteSeries(
      seriesId,
      deleteFiles: true,
      addExclusion: false,
    );
    final queueItemsRemoved = await _removeQueueItems(
      repository.deleteQueueItem,
      downloads.queueIds,
    );
    logger.info(
      '[PurgeService] Series $seriesId deleted (files: $mediaFilesDeleted)',
    );

    final torrentOutcome = await _purgeTorrents(
      downloads.hashes,
      approvedCrossSeedHashes: approvedCrossSeedHashes,
      context: (type: 'series', id: seriesId, seasonNumber: null),
    );

    return PurgeResult(
      queueItemsRemoved: queueItemsRemoved,
      catalogDeleted: 1,
      mediaFilesDeleted: mediaFilesDeleted,
      torrentHashesDeleted: torrentOutcome.torrentHashesDeleted,
      crossSeedDuplicatesDeleted: torrentOutcome.crossSeedDuplicatesDeleted,
      qbittorrentSkipped: torrentOutcome.qbittorrentSkipped,
    );
  }

  /// Previews the torrents a movie purge would delete, without mutating.
  ///
  /// [minimumSeedingSeconds] partitions the resolved torrents into the
  /// `belowThreshold` list so the UI can decide whether to show the
  /// [SeedingAction] warning dialog.
  Future<PurgePreview> previewMovie(
    int movieId, {
    int minimumSeedingSeconds = 0,
  }) async {
    final repository = _movieRepositoryFactory();
    if (repository == null) {
      throw StateError('Movie repository not available');
    }
    final downloads = await collectMovieDownloads(repository, movieId);
    return _buildPreview(downloads.hashes, minimumSeedingSeconds);
  }

  /// Previews the torrents a series purge would delete, without mutating.
  Future<PurgePreview> previewSeries(
    int seriesId, {
    int minimumSeedingSeconds = 0,
  }) async {
    final repository = _seriesRepositoryFactory();
    if (repository == null) {
      throw StateError('Series repository not available');
    }
    final downloads = await collectSeriesDownloads(repository, seriesId);
    return _buildPreview(downloads.hashes, minimumSeedingSeconds);
  }

  /// Previews the torrents a season purge would delete, without mutating.
  ///
  /// [scopeEpisodeIds] lists every episode of the seasons purged in this
  /// operation, with or without a file; a source torrent covering an episode
  /// outside it lands in [PurgePreview.sharedPackCandidates]. It defaults to
  /// [episodeIds], which flags any pack reaching beyond them.
  Future<PurgePreview> previewSeason(
    int seriesId,
    List<int> episodeIds, {
    int minimumSeedingSeconds = 0,
    Iterable<int>? scopeEpisodeIds,
  }) async {
    final repository = _seriesRepositoryFactory();
    if (repository == null) {
      throw StateError('Series repository not available');
    }
    final downloads = await collectSeasonDownloads(
      repository,
      seriesId,
      episodeIds,
    );
    return _buildPreview(
      downloads.hashes,
      minimumSeedingSeconds,
      sharedPackHashes: downloads.hashesBeyond(scopeEpisodeIds ?? episodeIds),
    );
  }

  /// Purges a season: deletes its episode files and source torrents. The
  /// series stays in the catalog (`catalogDeleted: 0`).
  ///
  /// [episodeIds] restricts hash collection to the given episodes. [action]
  /// controls whether below-threshold torrents are kept. A source torrent that
  /// also covers episodes outside [scopeEpisodeIds] (see [previewSeason]) is
  /// only deleted when its hash is in [approvedSharedPackHashes].
  Future<PurgeResult> purgeSeason(
    int seriesId,
    int seasonNumber,
    List<int> episodeIds, {
    SeedingAction action = SeedingAction.deleteAll,
    int minimumSeedingSeconds = 0,
    Set<String> approvedCrossSeedHashes = const {},
    Iterable<int>? scopeEpisodeIds,
    Set<String> approvedSharedPackHashes = const {},
  }) async {
    final repository = _seriesRepositoryFactory();
    if (repository == null) {
      throw StateError('Series repository not available');
    }

    logger.info(
      '[PurgeService] Purging series $seriesId season $seasonNumber '
      '(${episodeIds.length} episode(s))',
    );

    final downloads = await collectSeasonDownloads(
      repository,
      seriesId,
      episodeIds,
    );

    final mediaFilesDeleted = await _deleteSeriesFiles(
      repository,
      seriesId,
      seasonNumber: seasonNumber,
    );

    final resolved = await _resolveTorrents(downloads.hashes);
    final torrentOutcome = await _deleteTorrents(
      resolved.source,
      resolved.crossSeed,
      approvedCrossSeedHashes: approvedCrossSeedHashes,
      sharedPackHashes: downloads.hashesBeyond(scopeEpisodeIds ?? episodeIds),
      approvedSharedPackHashes: approvedSharedPackHashes,
      action: action,
      minimumSeedingSeconds: minimumSeedingSeconds,
      context: (type: 'season', id: seriesId, seasonNumber: seasonNumber),
    );

    return PurgeResult(
      queueItemsRemoved: 0,
      catalogDeleted: 0,
      mediaFilesDeleted: mediaFilesDeleted,
      torrentHashesDeleted: torrentOutcome.torrentHashesDeleted,
      crossSeedDuplicatesDeleted: torrentOutcome.crossSeedDuplicatesDeleted,
      qbittorrentSkipped: torrentOutcome.qbittorrentSkipped,
    );
  }

  /// Purges multiple movies, aggregating the results into a single
  /// [PurgeResult].
  Future<PurgeResult> purgeMovies(
    List<int> movieIds, {
    SeedingAction action = SeedingAction.deleteAll,
    int minimumSeedingSeconds = 0,
    Set<String> approvedCrossSeedHashes = const {},
  }) async {
    var queueItemsRemoved = 0;
    var catalogDeleted = 0;
    var mediaFilesDeleted = 0;
    final torrentHashes = <String>{};
    final crossSeed = <String>{};
    var qbittorrentSkipped = false;

    for (final id in movieIds) {
      final result = await purgeMovieWithAction(
        id,
        action: action,
        minimumSeedingSeconds: minimumSeedingSeconds,
        approvedCrossSeedHashes: approvedCrossSeedHashes,
      );
      queueItemsRemoved += result.queueItemsRemoved;
      catalogDeleted += result.catalogDeleted;
      mediaFilesDeleted += result.mediaFilesDeleted;
      torrentHashes.addAll(result.torrentHashesDeleted);
      crossSeed.addAll(result.crossSeedDuplicatesDeleted);
      qbittorrentSkipped = qbittorrentSkipped || result.qbittorrentSkipped;
    }

    return PurgeResult(
      queueItemsRemoved: queueItemsRemoved,
      catalogDeleted: catalogDeleted,
      mediaFilesDeleted: mediaFilesDeleted,
      torrentHashesDeleted: torrentHashes.toList(),
      crossSeedDuplicatesDeleted: crossSeed.toList(),
      qbittorrentSkipped: qbittorrentSkipped,
    );
  }

  /// Purges multiple series, aggregating the results into a single
  /// [PurgeResult].
  Future<PurgeResult> purgeSeriesList(
    List<int> seriesIds, {
    SeedingAction action = SeedingAction.deleteAll,
    int minimumSeedingSeconds = 0,
    Set<String> approvedCrossSeedHashes = const {},
  }) async {
    var queueItemsRemoved = 0;
    var catalogDeleted = 0;
    var mediaFilesDeleted = 0;
    final torrentHashes = <String>{};
    final crossSeed = <String>{};
    var qbittorrentSkipped = false;

    for (final id in seriesIds) {
      final result = await purgeSeriesWithAction(
        id,
        action: action,
        minimumSeedingSeconds: minimumSeedingSeconds,
        approvedCrossSeedHashes: approvedCrossSeedHashes,
      );
      queueItemsRemoved += result.queueItemsRemoved;
      catalogDeleted += result.catalogDeleted;
      mediaFilesDeleted += result.mediaFilesDeleted;
      torrentHashes.addAll(result.torrentHashesDeleted);
      crossSeed.addAll(result.crossSeedDuplicatesDeleted);
      qbittorrentSkipped = qbittorrentSkipped || result.qbittorrentSkipped;
    }

    return PurgeResult(
      queueItemsRemoved: queueItemsRemoved,
      catalogDeleted: catalogDeleted,
      mediaFilesDeleted: mediaFilesDeleted,
      torrentHashesDeleted: torrentHashes.toList(),
      crossSeedDuplicatesDeleted: crossSeed.toList(),
      qbittorrentSkipped: qbittorrentSkipped,
    );
  }

  /// Commits a purge of the resolved torrents for [movieId], honoring the
  /// seeding-time [action].
  ///
  /// Reuses the catalog + media-file deletion from [purgeMovie] but lets the
  /// caller skip below-threshold torrents. Use after [previewMovie].
  Future<PurgeResult> purgeMovieWithAction(
    int movieId, {
    SeedingAction action = SeedingAction.deleteAll,
    int minimumSeedingSeconds = 0,
    Set<String> approvedCrossSeedHashes = const {},
  }) async {
    final repository = _movieRepositoryFactory();
    if (repository == null) {
      throw StateError('Movie repository not available');
    }

    final downloads = await collectMovieDownloads(repository, movieId);
    final mediaFilesDeleted = await _countMovieFiles(repository, movieId);
    await repository.deleteMovie(
      movieId,
      deleteFiles: true,
      addExclusion: false,
    );
    final queueItemsRemoved = await _removeQueueItems(
      repository.deleteQueueItem,
      downloads.queueIds,
    );

    final resolved = await _resolveTorrents(downloads.hashes);
    final torrentOutcome = await _deleteTorrents(
      resolved.source,
      resolved.crossSeed,
      approvedCrossSeedHashes: approvedCrossSeedHashes,
      action: action,
      minimumSeedingSeconds: minimumSeedingSeconds,
      context: (type: 'movie', id: movieId, seasonNumber: null),
    );

    return PurgeResult(
      queueItemsRemoved: queueItemsRemoved,
      catalogDeleted: 1,
      mediaFilesDeleted: mediaFilesDeleted,
      torrentHashesDeleted: torrentOutcome.torrentHashesDeleted,
      crossSeedDuplicatesDeleted: torrentOutcome.crossSeedDuplicatesDeleted,
      qbittorrentSkipped: torrentOutcome.qbittorrentSkipped,
    );
  }

  /// Commits a purge of the resolved torrents for [seriesId], honoring the
  /// seeding-time [action]. Use after [previewSeries].
  Future<PurgeResult> purgeSeriesWithAction(
    int seriesId, {
    SeedingAction action = SeedingAction.deleteAll,
    int minimumSeedingSeconds = 0,
    Set<String> approvedCrossSeedHashes = const {},
  }) async {
    final repository = _seriesRepositoryFactory();
    if (repository == null) {
      throw StateError('Series repository not available');
    }

    final downloads = await collectSeriesDownloads(repository, seriesId);
    final mediaFilesDeleted = await _countSeriesFiles(repository, seriesId);
    await repository.deleteSeries(
      seriesId,
      deleteFiles: true,
      addExclusion: false,
    );
    final queueItemsRemoved = await _removeQueueItems(
      repository.deleteQueueItem,
      downloads.queueIds,
    );

    final resolved = await _resolveTorrents(downloads.hashes);
    final torrentOutcome = await _deleteTorrents(
      resolved.source,
      resolved.crossSeed,
      approvedCrossSeedHashes: approvedCrossSeedHashes,
      action: action,
      minimumSeedingSeconds: minimumSeedingSeconds,
      context: (type: 'series', id: seriesId, seasonNumber: null),
    );

    return PurgeResult(
      queueItemsRemoved: queueItemsRemoved,
      catalogDeleted: 1,
      mediaFilesDeleted: mediaFilesDeleted,
      torrentHashesDeleted: torrentOutcome.torrentHashesDeleted,
      crossSeedDuplicatesDeleted: torrentOutcome.crossSeedDuplicatesDeleted,
      qbittorrentSkipped: torrentOutcome.qbittorrentSkipped,
    );
  }

  // ---- helpers -----------------------------------------------------------

  /// Builds a [PurgePreview] from the resolved [sourceHashes], partitioning
  /// torrents by the seeding threshold.
  ///
  /// Source torrents whose hash is in [sharedPackHashes] are reported as
  /// [PurgePreview.sharedPackCandidates].
  Future<PurgePreview> _buildPreview(
    Set<String> sourceHashes,
    int minimumSeedingSeconds, {
    Set<String> sharedPackHashes = const {},
  }) async {
    final service = _qbittorrentServiceFactory();
    if (service == null) {
      return const PurgePreview(
        torrentsToDelete: [],
        crossSeedCandidates: [],
        belowThreshold: [],
        qbittorrentSkipped: true,
      );
    }
    final resolved = await _resolveTorrents(sourceHashes);
    final all = [...resolved.source, ...resolved.crossSeed];
    final below = all
        .where((t) => isBelowSeedingThreshold(t, minimumSeedingSeconds))
        .toList();
    return PurgePreview(
      torrentsToDelete: all,
      crossSeedCandidates: resolved.crossSeed,
      sharedPackCandidates: [
        for (final t in resolved.source)
          if (sharedPackHashes.contains(t.hash.toLowerCase())) t,
      ],
      belowThreshold: below,
      qbittorrentSkipped: false,
    );
  }

  /// Removes queue items, tolerating already-gone items.
  Future<int> _removeQueueItems(
    DeleteQueueItem deleteQueueItem,
    List<int> queueIds,
  ) async {
    var removed = 0;
    for (final id in queueIds) {
      try {
        await deleteQueueItem(
          id,
          removeFromClient: true,
          blocklist: false,
          skipRedownload: false,
        );
        removed++;
      } catch (e) {
        logger.warning('[PurgeService] Queue item $id removal failed: $e');
      }
    }
    return removed;
  }

  Future<int> _countMovieFiles(MovieRepository repository, int movieId) async {
    try {
      return (await repository.getMovieFiles(movieId)).length;
    } catch (e) {
      logger.warning('[PurgeService] getMovieFiles failed: $e');
      return 0;
    }
  }

  Future<int> _countSeriesFiles(
    SeriesRepository repository,
    int seriesId,
  ) async {
    try {
      return (await repository.getSeriesFiles(seriesId)).length;
    } catch (e) {
      logger.warning('[PurgeService] getSeriesFiles failed: $e');
      return 0;
    }
  }

  Future<int> _deleteSeriesFiles(
    SeriesRepository repository,
    int seriesId, {
    required int seasonNumber,
  }) async {
    try {
      return await repository.deleteSeriesFiles(
        seriesId,
        seasonNumber: seasonNumber,
      );
    } catch (e) {
      logger.warning('[PurgeService] deleteSeriesFiles failed: $e');
      return 0;
    }
  }

  /// Resolves the torrents a purge would delete, without mutating anything.
  ///
  /// Returns source torrents (matched by hash) and cross-seed duplicates
  /// separately so callers can inspect seeding time before committing via
  /// [_deleteTorrents] and the outcome keeps the source/cross-seed split.
  Future<CrossSeedPartition> _resolveTorrents(Set<String> sourceHashes) async {
    if (sourceHashes.isEmpty) {
      logger.info('[PurgeService] No source hashes to resolve');
      return (source: <Torrent>[], crossSeed: <Torrent>[]);
    }

    final service = _qbittorrentServiceFactory();
    if (service == null) {
      logger.info('[PurgeService] qBittorrent not configured; skipping');
      return (source: <Torrent>[], crossSeed: <Torrent>[]);
    }

    final torrents = await service.getTorrents();
    final resolved = partitionCrossSeed(torrents, sourceHashes);

    logger.info(
      '[PurgeService] Resolved ${resolved.source.length} source + '
      '${resolved.crossSeed.length} cross-seed torrent(s) to delete',
    );
    return resolved;
  }

  /// Deletes the resolved torrents in qBittorrent, honoring [action].
  ///
  /// [approvedCrossSeedHashes] restricts cross-seed deletions to torrents that
  /// the user explicitly approved, and [approvedSharedPackHashes] does the
  /// same for the source torrents listed in [sharedPackHashes]. When [action]
  /// is [SeedingAction.keepBelowThreshold], torrents whose seeding time is
  /// below [minimumSeedingSeconds] are kept in qBittorrent (they keep
  /// seeding); only the eligible ones are deleted. Cross-seed copies of a
  /// shared pack that stays are kept even when approved. All deletes use
  /// `deleteFiles: true` so hardlinked inodes are reclaimed.
  Future<_TorrentPurgeOutcome> _deleteTorrents(
    List<Torrent> source,
    List<Torrent> crossSeed, {
    Set<String> approvedCrossSeedHashes = const {},
    Set<String> sharedPackHashes = const {},
    Set<String> approvedSharedPackHashes = const {},
    SeedingAction action = SeedingAction.deleteAll,
    int minimumSeedingSeconds = 0,
    PurgeContext? context,
  }) async {
    final service = _qbittorrentServiceFactory();
    if (service == null) {
      return _TorrentPurgeOutcome(
        torrentHashesDeleted: const [],
        crossSeedDuplicatesDeleted: const [],
        qbittorrentSkipped: true,
      );
    }
    if (source.isEmpty && crossSeed.isEmpty) {
      return _TorrentPurgeOutcome._empty;
    }

    final sourceDeleted = <String>[];
    final crossSeedDeleted = <String>[];
    final hashesToDelete = <String>{};
    // Announced only once qBittorrent confirmed the deletion.
    final deleted = <(Torrent, bool)>[];

    bool isBelowThreshold(Torrent t) =>
        action == SeedingAction.keepBelowThreshold &&
        isBelowSeedingThreshold(t, minimumSeedingSeconds);

    for (final t in source) {
      final h = t.hash.toLowerCase();
      if (sharedPackHashes.contains(h) &&
          !approvedSharedPackHashes.contains(h)) {
        logger.info(
          '[PurgeService] Keeping unapproved multi-season pack ${t.name}',
        );
        continue;
      }
      if (isBelowThreshold(t)) {
        logger.info(
          '[PurgeService] Keeping source torrent ${t.name} '
          '(seeding ${t.seedingTime}s < ${minimumSeedingSeconds}s)',
        );
        continue;
      }
      if (hashesToDelete.add(h)) {
        sourceDeleted.add(h);
        deleted.add((t, false));
      }
    }
    // Copies of a kept multi-season pack usually share its data on disk:
    // deleting them with their files would remove the seasons being kept.
    final keptPackNames = _keptPackNames(
      source.where((t) => sharedPackHashes.contains(t.hash.toLowerCase())),
      approvedSharedPackHashes,
    );
    for (final t in crossSeed) {
      final h = t.hash.toLowerCase();
      if (keptPackNames.contains(normalizeTorrentName(t.name))) {
        logger.info(
          '[PurgeService] Keeping cross-seed of kept multi-season pack '
          '${t.name}',
        );
        continue;
      }
      if (!approvedCrossSeedHashes.contains(h)) {
        logger.info('[PurgeService] Keeping unapproved cross-seed ${t.name}');
        continue;
      }
      if (isBelowThreshold(t)) {
        logger.info(
          '[PurgeService] Keeping cross-seed torrent ${t.name} '
          '(seeding ${t.seedingTime}s < ${minimumSeedingSeconds}s)',
        );
        continue;
      }
      if (hashesToDelete.add(h)) {
        crossSeedDeleted.add(h);
        deleted.add((t, true));
      }
    }

    if (hashesToDelete.isEmpty) {
      logger.info('[PurgeService] No torrents to delete after seeding filter');
      return _TorrentPurgeOutcome._empty;
    }

    logger.info(
      '[PurgeService] Deleting ${hashesToDelete.length} torrent(s) with files',
    );

    await service.deleteTorrents(hashesToDelete.toList(), deleteFiles: true);

    for (final (torrent, isCrossSeed) in deleted) {
      _emitTorrentPurgedNotification(
        torrent,
        context,
        isCrossSeed: isCrossSeed,
      );
    }

    return _TorrentPurgeOutcome(
      torrentHashesDeleted: sourceDeleted,
      crossSeedDuplicatesDeleted: crossSeedDeleted,
      qbittorrentSkipped: false,
    );
  }

  /// Resolves and deletes torrents in qBittorrent for [sourceHashes].
  ///
  /// Convenience wrapper around [_resolveTorrents] + [_deleteTorrents] for the
  /// non-interactive purge path (no seeding check).
  Future<_TorrentPurgeOutcome> _purgeTorrents(
    Set<String> sourceHashes, {
    Set<String> approvedCrossSeedHashes = const {},
    PurgeContext? context,
  }) async {
    final service = _qbittorrentServiceFactory();
    if (service == null) {
      logger.info('[PurgeService] qBittorrent not configured; skipping');
      return _TorrentPurgeOutcome(
        torrentHashesDeleted: const [],
        crossSeedDuplicatesDeleted: const [],
        qbittorrentSkipped: true,
      );
    }
    final resolved = await _resolveTorrents(sourceHashes);
    return _deleteTorrents(
      resolved.source,
      resolved.crossSeed,
      approvedCrossSeedHashes: approvedCrossSeedHashes,
      context: context,
    );
  }

  /// Emits an in-app notification recording that [t] was purged.
  ///
  /// Fire-and-forget: failures are logged and never propagated, so a
  /// notification hiccup cannot break the purge flow. [context] carries the
  /// origin (movie/series/season) and [isCrossSeed] flags cross-seed dupes.
  void _emitTorrentPurgedNotification(
    Torrent t,
    PurgeContext? context, {
    required bool isCrossSeed,
  }) {
    final service = _inAppNotificationServiceFactory();
    if (service == null) return;

    final season = context?.seasonNumber;
    final notification = AppNotification(
      id: _uuid.v4(),
      title: season != null
          ? _localizations().corePurgeNotificationTitleSeason(season)
          : _localizations().corePurgeNotificationTitle,
      message: t.name,
      type: NotificationType.purged,
      priority: NotificationPriority.medium,
      timestamp: DateTime.now(),
      metadata: {
        if (context != null) 'instanceType': context.type,
        if (context != null) 'instanceId': context.id,
        'seasonNumber': ?season,
        'hash': t.hash,
        'size': t.size,
        'savePath': t.savePath,
        'isCrossSeed': isCrossSeed,
      },
    );

    try {
      service.addNotification(notification);
    } catch (e, stackTrace) {
      logger.warning(
        '[PurgeService] Failed to emit purge notification for ${t.hash}: $e',
        e,
        stackTrace,
      );
    }
  }
}
