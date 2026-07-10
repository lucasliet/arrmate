import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/notification/app_notification.dart';
import '../../core/services/in_app_notification_service.dart';
import '../../core/services/logger_service.dart';
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
  });

  @override
  List<Object?> get props => [
    torrentsToDelete,
    crossSeedCandidates,
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

  /// Number of media files reported deleted by the *arr side.
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

  /// Formats this result into a multi-line snackbar summary.
  ///
  /// [label] is the first line announcing the operation (e.g.
  /// `'Movie purged.'`).
  String formatSummary({required String label}) {
    final lines = <String>[label];
    lines.add('Queue items: $queueItemsRemoved');
    lines.add('Media files: $mediaFilesDeleted');
    if (qbittorrentSkipped) {
      lines.add('qBittorrent skipped — configure a qBittorrent instance.');
    } else {
      final crossSeed = crossSeedDuplicatesDeleted.length;
      final torrents = torrentHashesDeleted.length;
      lines.add(
        'Torrents: $torrents${crossSeed > 0 ? ' (+$crossSeed cross-seed)' : ''}',
      );
    }
    return lines.join('\n');
  }
}

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
  final Uuid _uuid;

  PurgeService({
    required MovieRepository? Function() movieRepositoryFactory,
    required SeriesRepository? Function() seriesRepositoryFactory,
    required QBittorrentService? Function() qbittorrentServiceFactory,
    required InAppNotificationService? Function()
    inAppNotificationServiceFactory,
    Uuid? uuid,
  }) : _movieRepositoryFactory = movieRepositoryFactory,
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

    final (hashes, queueIds) = await _collectMovieHashes(repository, movieId);
    final queueItemsRemoved = await _removeQueueItems(
      repository.deleteQueueItem,
      queueIds,
    );

    final mediaFilesDeleted = await _deleteMovieFiles(repository, movieId);
    await repository.deleteMovie(
      movieId,
      deleteFiles: true,
      addExclusion: false,
    );
    logger.info(
      '[PurgeService] Movie $movieId deleted (files: $mediaFilesDeleted)',
    );

    final torrentOutcome = await _purgeTorrents(
      hashes,
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

    final (hashes, queueIds) = await _collectSeriesHashes(repository, seriesId);
    final queueItemsRemoved = await _removeQueueItems(
      repository.deleteQueueItem,
      queueIds,
    );

    final mediaFilesDeleted = await _deleteSeriesFiles(repository, seriesId);
    await repository.deleteSeries(
      seriesId,
      deleteFiles: true,
      addExclusion: false,
    );
    logger.info(
      '[PurgeService] Series $seriesId deleted (files: $mediaFilesDeleted)',
    );

    final torrentOutcome = await _purgeTorrents(
      hashes,
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
    final (hashes, _) = await _collectMovieHashes(repository, movieId);
    return _buildPreview(hashes, minimumSeedingSeconds);
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
    final (hashes, _) = await _collectSeriesHashes(repository, seriesId);
    return _buildPreview(hashes, minimumSeedingSeconds);
  }

  /// Previews the torrents a season purge would delete, without mutating.
  Future<PurgePreview> previewSeason(
    int seriesId,
    List<int> episodeIds, {
    int minimumSeedingSeconds = 0,
  }) async {
    final repository = _seriesRepositoryFactory();
    if (repository == null) {
      throw StateError('Series repository not available');
    }
    final hashes = await _collectSeasonHashes(repository, seriesId, episodeIds);
    return _buildPreview(hashes, minimumSeedingSeconds);
  }

  /// Purges a season: deletes its episode files and source torrents. The
  /// series stays in the catalog (`catalogDeleted: 0`).
  ///
  /// [episodeIds] restricts hash collection to the given episodes. [action]
  /// controls whether below-threshold torrents are kept.
  Future<PurgeResult> purgeSeason(
    int seriesId,
    int seasonNumber,
    List<int> episodeIds, {
    SeedingAction action = SeedingAction.deleteAll,
    int minimumSeedingSeconds = 0,
    Set<String> approvedCrossSeedHashes = const {},
  }) async {
    final repository = _seriesRepositoryFactory();
    if (repository == null) {
      throw StateError('Series repository not available');
    }

    logger.info(
      '[PurgeService] Purging series $seriesId season $seasonNumber '
      '(${episodeIds.length} episode(s))',
    );

    final hashes = await _collectSeasonHashes(repository, seriesId, episodeIds);

    final mediaFilesDeleted = await _deleteSeriesFiles(
      repository,
      seriesId,
      seasonNumber: seasonNumber,
    );

    final resolved = await _resolveTorrents(hashes);
    final torrentOutcome = await _deleteTorrents(
      resolved.source,
      resolved.crossSeed,
      approvedCrossSeedHashes: approvedCrossSeedHashes,
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

    final (hashes, queueIds) = await _collectMovieHashes(repository, movieId);
    final queueItemsRemoved = await _removeQueueItems(
      repository.deleteQueueItem,
      queueIds,
    );
    final mediaFilesDeleted = await _deleteMovieFiles(repository, movieId);
    await repository.deleteMovie(
      movieId,
      deleteFiles: true,
      addExclusion: false,
    );

    final resolved = await _resolveTorrents(hashes);
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

    final (hashes, queueIds) = await _collectSeriesHashes(repository, seriesId);
    final queueItemsRemoved = await _removeQueueItems(
      repository.deleteQueueItem,
      queueIds,
    );
    final mediaFilesDeleted = await _deleteSeriesFiles(repository, seriesId);
    await repository.deleteSeries(
      seriesId,
      deleteFiles: true,
      addExclusion: false,
    );

    final resolved = await _resolveTorrents(hashes);
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

  /// Collects source torrent hashes + queue ids for [movieId].
  ///
  /// Hashes come from history (grabbed + imported) and the active queue.
  /// The queue is paginated via [_collectQueue] so items beyond the first
  /// page (Radarr/Sonarr default `pageSize: 20`) are still swept up.
  Future<(Set<String>, List<int>)> _collectMovieHashes(
    MovieRepository repository,
    int movieId,
  ) async {
    final hashes = <String>{};
    final history = await repository.getMovieHistory(movieId);
    for (final event in history) {
      if (event.eventType == HistoryEventType.grabbed ||
          event.eventType == HistoryEventType.imported) {
        final id = event.downloadId;
        if (id != null && id.isNotEmpty) hashes.add(id.toLowerCase());
      }
    }

    final (queueIds, queueHashes) = await _collectQueue(
      ({required int page, required int pageSize}) =>
          repository.getQueue(page: page, pageSize: pageSize),
      (q) => q.movieId == movieId,
    );
    hashes.addAll(queueHashes);

    logger.info(
      '[PurgeService] Movie $movieId: ${hashes.length} hash(es), '
      '${queueIds.length} queue item(s)',
    );
    return (hashes, queueIds);
  }

  Future<(Set<String>, List<int>)> _collectSeriesHashes(
    SeriesRepository repository,
    int seriesId,
  ) async {
    final hashes = <String>{};
    final history = await repository.getSeriesHistory(seriesId);
    for (final event in history) {
      if (event.eventType == HistoryEventType.grabbed ||
          event.eventType == HistoryEventType.imported) {
        final id = event.downloadId;
        if (id != null && id.isNotEmpty) hashes.add(id.toLowerCase());
      }
    }

    final (queueIds, queueHashes) = await _collectQueue(
      ({required int page, required int pageSize}) =>
          repository.getQueue(page: page, pageSize: pageSize),
      (q) => q.seriesId == seriesId,
    );
    hashes.addAll(queueHashes);

    logger.info(
      '[PurgeService] Series $seriesId: ${hashes.length} hash(es), '
      '${queueIds.length} queue item(s)',
    );
    return (hashes, queueIds);
  }

  /// Collects source torrent hashes for a season of [seriesId], restricted to
  /// the given [episodeIds]. Hashes come only from history (grabbed + imported)
  /// events whose `episodeId` is in [episodeIds]. Queue items are not removed
  /// for season purges.
  Future<Set<String>> _collectSeasonHashes(
    SeriesRepository repository,
    int seriesId,
    List<int> episodeIds,
  ) async {
    final episodeSet = episodeIds.toSet();
    final hashes = <String>{};
    final history = await repository.getSeriesHistory(seriesId);
    for (final event in history) {
      if ((event.eventType == HistoryEventType.grabbed ||
              event.eventType == HistoryEventType.imported) &&
          event.episodeId != null &&
          episodeSet.contains(event.episodeId)) {
        final id = event.downloadId;
        if (id != null && id.isNotEmpty) hashes.add(id.toLowerCase());
      }
    }

    logger.info(
      '[PurgeService] Series $seriesId season: ${hashes.length} hash(es) '
      'from ${episodeIds.length} episode(s)',
    );
    return hashes;
  }

  /// Builds a [PurgePreview] from the resolved [sourceHashes], partitioning
  /// torrents by the seeding threshold.
  Future<PurgePreview> _buildPreview(
    Set<String> sourceHashes,
    int minimumSeedingSeconds,
  ) async {
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
    final below = minimumSeedingSeconds > 0
        ? all.where((t) => t.seedingTime < minimumSeedingSeconds).toList()
        : const <Torrent>[];
    return PurgePreview(
      torrentsToDelete: all,
      crossSeedCandidates: resolved.crossSeed,
      belowThreshold: below,
      qbittorrentSkipped: false,
    );
  }

  /// Pages through the activity queue accumulating ids + download hashes for
  /// items matching [matches].
  ///
  /// Radarr/Sonarr do not support server-side filtering by movie/series id,
  /// so we walk all pages and apply [matches] locally. Stops when a page is
  /// short (last page) or when we have consumed `totalRecords`. A [maxPages]
  /// cap guards against runaway loops on misbehaving APIs.
  Future<(List<int> queueIds, Set<String> hashes)> _collectQueue(
    Future<QueueItems> Function({required int page, required int pageSize})
    getQueue,
    bool Function(QueueItem) matches,
  ) async {
    const pageSize = 100;
    const maxPages = 50;
    final queueIds = <int>[];
    final hashes = <String>{};
    for (var page = 1; page <= maxPages; page++) {
      final q = await getQueue(page: page, pageSize: pageSize);
      for (final item in q.records.where(matches)) {
        queueIds.add(item.id);
        final id = item.downloadId;
        if (id != null && id.isNotEmpty) hashes.add(id.toLowerCase());
      }
      // Last page reached when fewer than `pageSize` items are returned, or
      // when we've already consumed every record reported by the server.
      if (q.records.length < pageSize) break;
      if (q.records.length >= q.totalRecords) break;
    }
    return (queueIds, hashes);
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

  /// Best-effort informational count of media files before deleting the movie.
  ///
  // We call deleteMovieFiles first to obtain a count, then pass
  // deleteFiles:true to deleteMovie so any files missed in the race are still
  // cleaned by Radarr. Radarr tolerates a no-op file deletion.
  /// Deletes the movie's media files one by one and returns how many actually
  /// got deleted.
  ///
  /// Each file is deleted via its own [MovieRepository.deleteMovieFile] call;
  /// a failure on one file is logged and skipped so the remaining files are
  /// still attempted. The count therefore reflects the real number of files
  /// removed from disk, not a pre-deletion estimate. [deleteMovie] with
  /// `deleteFiles: true` runs afterwards as a safety net for anything missed
  /// here (e.g. files that appeared between the list and the delete).
  Future<int> _deleteMovieFiles(MovieRepository repository, int movieId) async {
    final List<MediaFile> files;
    try {
      files = await repository.getMovieFiles(movieId);
    } catch (e) {
      logger.warning('[PurgeService] getMovieFiles failed: $e');
      return 0;
    }

    var deleted = 0;
    for (final file in files) {
      try {
        await repository.deleteMovieFile(file.id);
        deleted++;
      } catch (e) {
        logger.warning('[PurgeService] deleteMovieFile ${file.id} failed: $e');
      }
    }
    return deleted;
  }

  /// Deletes the series' episode files one by one and returns how many
  /// actually got deleted.
  ///
  /// When [seasonNumber] is provided, only files of that season are removed;
  /// otherwise all files of the series are removed. Mirrors [_deleteMovieFiles]
  /// for the per-file resilience.
  Future<int> _deleteSeriesFiles(
    SeriesRepository repository,
    int seriesId, {
    int? seasonNumber,
  }) async {
    if (seasonNumber != null) {
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

    final List<MediaFile> files;
    try {
      files = await repository.getSeriesFiles(seriesId);
    } catch (e) {
      logger.warning('[PurgeService] getSeriesFiles failed: $e');
      return 0;
    }

    var deleted = 0;
    for (final file in files) {
      try {
        await repository.deleteSeriesFile(file.id);
        deleted++;
      } catch (e) {
        logger.warning('[PurgeService] deleteSeriesFile ${file.id} failed: $e');
      }
    }
    return deleted;
  }

  /// Resolves the torrents a purge would delete, without mutating anything.
  ///
  /// Returns source torrents (matched by hash) and cross-seed duplicates
  /// separately so callers can inspect seeding time before committing via
  /// [_deleteTorrents] and the outcome keeps the source/cross-seed split.
  Future<({List<Torrent> source, List<Torrent> crossSeed})> _resolveTorrents(
    Set<String> sourceHashes,
  ) async {
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
    final sourceFoundHashes = <String>{};
    for (final t in torrents) {
      if (sourceHashes.contains(t.hash.toLowerCase())) {
        sourceFoundHashes.add(t.hash.toLowerCase());
      }
    }

    final source = <Torrent>[];
    final sourceNames = <String>{};
    for (final t in torrents) {
      if (sourceFoundHashes.contains(t.hash.toLowerCase())) {
        source.add(t);
        sourceNames.add(_normalizeName(t.name));
      }
    }
    final crossSeed = <Torrent>[];
    for (final t in torrents) {
      final h = t.hash.toLowerCase();
      if (sourceFoundHashes.contains(h)) continue; // already source
      if (sourceNames.contains(_normalizeName(t.name))) {
        crossSeed.add(t);
      }
    }

    logger.info(
      '[PurgeService] Resolved ${source.length} source + '
      '${crossSeed.length} cross-seed torrent(s) to delete',
    );
    return (source: source, crossSeed: crossSeed);
  }

  /// Deletes the resolved torrents in qBittorrent, honoring [action].
  ///
  /// [approvedCrossSeedHashes] restricts cross-seed deletions to torrents that
  /// the user explicitly approved. When [action] is
  /// [SeedingAction.keepBelowThreshold], torrents whose seeding time is below
  /// [minimumSeedingSeconds] are kept in qBittorrent (they keep seeding); only
  /// the eligible ones are deleted. All deletes use `deleteFiles: true` so
  /// hardlinked inodes are reclaimed.
  Future<_TorrentPurgeOutcome> _deleteTorrents(
    List<Torrent> source,
    List<Torrent> crossSeed, {
    Set<String> approvedCrossSeedHashes = const {},
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

    bool isBelowThreshold(Torrent t) =>
        action == SeedingAction.keepBelowThreshold &&
        t.seedingTime < minimumSeedingSeconds;

    for (final t in source) {
      if (isBelowThreshold(t)) {
        logger.info(
          '[PurgeService] Keeping source torrent ${t.name} '
          '(seeding ${t.seedingTime}s < ${minimumSeedingSeconds}s)',
        );
        continue;
      }
      final h = t.hash.toLowerCase();
      if (hashesToDelete.add(h)) {
        sourceDeleted.add(h);
        _emitTorrentPurgedNotification(t, context, isCrossSeed: false);
      }
    }
    for (final t in crossSeed) {
      final h = t.hash.toLowerCase();
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
        _emitTorrentPurgedNotification(t, context, isCrossSeed: true);
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
          ? 'Purged torrent (season $season)'
          : 'Purged torrent',
      message: t.name,
      type: NotificationType.purged,
      priority: NotificationPriority.medium,
      timestamp: DateTime.now(),
      metadata: {
        if (context != null) 'instanceType': context.type,
        if (context != null) 'instanceId': context.id,
        if (season != null) 'seasonNumber': season,
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

  /// Lowercases and trims a torrent name for case-insensitive comparison.
  static String _normalizeName(String name) => name.toLowerCase().trim();
}
