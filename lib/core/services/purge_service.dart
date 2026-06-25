import 'package:equatable/equatable.dart';

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
  /// These are torrents not in the source-hash set but whose `name` AND
  /// `savePath` matched a source torrent — a best-effort signal that the
  /// candidate is a hardlinked duplicate of the source content.
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
/// Cross-seed duplicate detection is best-effort: a torrent is treated as a
/// duplicate only when both its `name` (case-insensitive) and `savePath`
/// match a source torrent. This avoids deleting unrelated torrents that
/// happen to share a release name with the source. Releases in separate
/// directories hardlinked to the same content are NOT caught by this rule.
class PurgeService {
  final MovieRepository? Function() _movieRepositoryFactory;
  final SeriesRepository? Function() _seriesRepositoryFactory;
  final QBittorrentService? Function() _qbittorrentServiceFactory;

  PurgeService({
    required MovieRepository? Function() movieRepositoryFactory,
    required SeriesRepository? Function() seriesRepositoryFactory,
    required QBittorrentService? Function() qbittorrentServiceFactory,
  }) : _movieRepositoryFactory = movieRepositoryFactory,
       _seriesRepositoryFactory = seriesRepositoryFactory,
       _qbittorrentServiceFactory = qbittorrentServiceFactory;

  /// Purges a movie from Radarr and qBittorrent.
  Future<PurgeResult> purgeMovie(int movieId) async {
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

    final mediaFilesDeleted = await _deleteMovieFilesForCount(
      repository,
      movieId,
    );
    await repository.deleteMovie(
      movieId,
      deleteFiles: true,
      addExclusion: false,
    );
    logger.info(
      '[PurgeService] Movie $movieId deleted (files: $mediaFilesDeleted)',
    );

    final torrentOutcome = await _purgeTorrents(hashes);

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
  Future<PurgeResult> purgeSeries(int seriesId) async {
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

    final mediaFilesDeleted = await _deleteSeriesFilesForCount(
      repository,
      seriesId,
    );
    await repository.deleteSeries(
      seriesId,
      deleteFiles: true,
      addExclusion: false,
    );
    logger.info(
      '[PurgeService] Series $seriesId deleted (files: $mediaFilesDeleted)',
    );

    final torrentOutcome = await _purgeTorrents(hashes);

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
  Future<int> _deleteMovieFilesForCount(
    MovieRepository repository,
    int movieId,
  ) async {
    try {
      return await repository.deleteMovieFiles(movieId);
    } catch (e) {
      logger.warning('[PurgeService] deleteMovieFiles count failed: $e');
      return 0;
    }
  }

  Future<int> _deleteSeriesFilesForCount(
    SeriesRepository repository,
    int seriesId,
  ) async {
    try {
      return await repository.deleteSeriesFiles(seriesId);
    } catch (e) {
      logger.warning('[PurgeService] deleteSeriesFiles count failed: $e');
      return 0;
    }
  }

  /// Resolves and deletes torrents in qBittorrent for [sourceHashes].
  ///
  /// Source torrents are matched by hash. Cross-seed duplicates are matched by
  /// torrent `name` (case-insensitive) AND `savePath` (normalized) among
  /// torrents whose hash is NOT in the source set. The `savePath` guard
  /// prevents deleting an unrelated torrent that happens to share a release
  /// name with the source. All deletes use `deleteFiles: true` so hardlinked
  /// inodes are reclaimed.
  Future<_TorrentPurgeOutcome> _purgeTorrents(Set<String> sourceHashes) async {
    final service = _qbittorrentServiceFactory();
    if (service == null) {
      logger.info('[PurgeService] qBittorrent not configured; skipping');
      return _TorrentPurgeOutcome(
        torrentHashesDeleted: const [],
        crossSeedDuplicatesDeleted: const [],
        qbittorrentSkipped: true,
      );
    }

    if (sourceHashes.isEmpty) {
      logger.info('[PurgeService] No source hashes to delete');
      return _TorrentPurgeOutcome._empty;
    }

    final torrents = await service.getTorrents();
    final sourceTorrents = torrents.where(
      (t) => sourceHashes.contains(t.hash.toLowerCase()),
    );
    final sourceNames = <String>{};
    final sourceSavePaths = <String>{};
    final sourceFoundHashes = <String>{};
    for (final t in sourceTorrents) {
      sourceNames.add(_normalizeName(t.name));
      sourceSavePaths.add(_normalizePath(t.savePath));
      sourceFoundHashes.add(t.hash.toLowerCase());
    }

    final hashesToDelete = <String>{...sourceFoundHashes};
    final crossSeedHashes = <String>[];
    for (final t in torrents) {
      final h = t.hash.toLowerCase();
      if (sourceFoundHashes.contains(h)) continue; // already source
      if (sourceNames.contains(_normalizeName(t.name)) &&
          sourceSavePaths.contains(_normalizePath(t.savePath))) {
        if (hashesToDelete.add(h)) crossSeedHashes.add(h);
      }
    }

    if (hashesToDelete.isEmpty) {
      logger.info('[PurgeService] No matching torrents in qBittorrent');
      return _TorrentPurgeOutcome._empty;
    }

    logger.info(
      '[PurgeService] Deleting ${hashesToDelete.length} torrent(s) '
      '(${sourceFoundHashes.length} source + '
      '${crossSeedHashes.length} cross-seed) with files',
    );

    await service.deleteTorrents(hashesToDelete.toList(), deleteFiles: true);

    return _TorrentPurgeOutcome(
      torrentHashesDeleted: sourceFoundHashes.toList(),
      crossSeedDuplicatesDeleted: crossSeedHashes,
      qbittorrentSkipped: false,
    );
  }

  /// Lowercases and trims a torrent name for case-insensitive comparison.
  static String _normalizeName(String name) => name.toLowerCase().trim();

  /// Normalizes a save path for cross-seed comparison: trims whitespace,
  /// lowercases (paths are case-sensitive on Linux but cross-seed typically
  /// links into the same directory), and strips a single trailing slash so
  /// `/downloads/` and `/downloads` compare equal.
  static String _normalizePath(String path) {
    var p = path.trim().toLowerCase();
    if (p.endsWith('/') && p.length > 1) p = p.substring(0, p.length - 1);
    return p;
  }
}
