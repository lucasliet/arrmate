import 'package:equatable/equatable.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../constants/api_constants.dart';
import '../services/logger_service.dart';

/// Maximum number of queue pages walked while collecting an item's downloads.
///
/// Guards against runaway loops on misbehaving APIs.
const int _maxQueuePages = 50;

/// Downloads Radarr/Sonarr recorded for a single library item.
///
/// The one resolution shared by every flow that maps a movie, series or season
/// to its download-client torrents — the purge (preview and commit) and the
/// torrents listed on the details screens — so what a screen shows is exactly
/// what a purge of the same item would delete.
class MediaDownloads extends Equatable {
  /// Episode ids covered by each download, keyed by lowercased infohash.
  ///
  /// The set is empty for movies, and for series events that carry no episode.
  final Map<String, Set<int>> episodesByHash;

  /// Ids of the activity queue items that belong to the item.
  final List<int> queueIds;

  /// Creates the collected downloads.
  const MediaDownloads({
    this.episodesByHash = const {},
    this.queueIds = const [],
  });

  /// Lowercased infohashes of every download found for the item.
  Set<String> get hashes => episodesByHash.keys.toSet();

  /// Hashes whose download also covers an episode outside [scopeEpisodeIds].
  ///
  /// Used by season purges to spot packs spanning other seasons: deleting one
  /// of those with its files would take the other seasons' copies with it.
  Set<String> hashesBeyond(Iterable<int> scopeEpisodeIds) {
    final scope = scopeEpisodeIds.toSet();
    return {
      for (final entry in episodesByHash.entries)
        if (entry.value.any((episodeId) => !scope.contains(episodeId)))
          entry.key,
    };
  }

  @override
  List<Object?> get props => [episodesByHash, queueIds];
}

/// Whether [event] records a download the client may still hold.
///
/// Only `grabbed` and `imported` events carry such a download: the grab exists
/// from the moment the release is handed to the client, and the import is the
/// only trace of a download added by hand and picked up from its category.
bool isDownloadEvent(HistoryEvent event) =>
    event.eventType == HistoryEventType.grabbed ||
    event.eventType == HistoryEventType.imported;

/// Collects the downloads of the Radarr movie [movieId].
///
/// Hashes come from the movie history (grabbed + imported) and from the
/// activity queue, which is walked page by page because Radarr cannot filter it
/// by movie.
Future<MediaDownloads> collectMovieDownloads(
  MovieRepository repository,
  int movieId,
) async {
  final episodesByHash = <String, Set<int>>{};
  _addHistory(episodesByHash, await repository.getMovieHistory(movieId));

  final queueIds = await _addQueue(
    episodesByHash,
    ({required int page, required int pageSize}) =>
        repository.getQueue(page: page, pageSize: pageSize),
    (item) => item.movieId == movieId,
  );

  logger.info(
    '[MediaDownloads] Movie $movieId: ${episodesByHash.length} hash(es), '
    '${queueIds.length} queue item(s)',
  );
  return MediaDownloads(episodesByHash: episodesByHash, queueIds: queueIds);
}

/// Collects the downloads of the Sonarr series [seriesId].
///
/// Same sources as [collectMovieDownloads]; each hash also carries the episodes
/// its grab, import or queue entry covered.
Future<MediaDownloads> collectSeriesDownloads(
  SeriesRepository repository,
  int seriesId,
) async {
  final episodesByHash = <String, Set<int>>{};
  _addHistory(episodesByHash, await repository.getSeriesHistory(seriesId));

  final queueIds = await _addQueue(
    episodesByHash,
    ({required int page, required int pageSize}) =>
        repository.getQueue(page: page, pageSize: pageSize),
    (item) => item.seriesId == seriesId,
  );

  logger.info(
    '[MediaDownloads] Series $seriesId: ${episodesByHash.length} hash(es), '
    '${queueIds.length} queue item(s)',
  );
  return MediaDownloads(episodesByHash: episodesByHash, queueIds: queueIds);
}

/// Collects the downloads of [seriesId] that cover at least one of
/// [episodeIds].
///
/// Each returned hash carries its *full* episode coverage across the series,
/// not only the episodes in [episodeIds], so a caller can tell a season pack
/// from a pack that also spans other seasons. Only the history is read: queue
/// items are not part of a season purge.
Future<MediaDownloads> collectSeasonDownloads(
  SeriesRepository repository,
  int seriesId,
  Iterable<int> episodeIds,
) async {
  final episodeSet = episodeIds.toSet();
  final coverage = <String, Set<int>>{};
  _addHistory(coverage, await repository.getSeriesHistory(seriesId));

  final episodesByHash = {
    for (final entry in coverage.entries)
      if (entry.value.any(episodeSet.contains)) entry.key: entry.value,
  };

  logger.info(
    '[MediaDownloads] Series $seriesId season: ${episodesByHash.length} '
    'hash(es) from ${episodeSet.length} episode(s)',
  );
  return MediaDownloads(episodesByHash: episodesByHash);
}

/// Adds the download events of [history] to [episodesByHash].
void _addHistory(
  Map<String, Set<int>> episodesByHash,
  List<HistoryEvent> history,
) {
  for (final event in history) {
    if (!isDownloadEvent(event)) continue;
    _addDownload(episodesByHash, event.downloadId, event.episodeId);
  }
}

/// Pages through the activity queue adding the downloads of the items that
/// satisfy [matches] to [episodesByHash], and returns their queue ids.
///
/// Stops when a page is short (last page) or once `totalRecords` items were
/// consumed; [_maxQueuePages] caps the walk.
Future<List<int>> _addQueue(
  Map<String, Set<int>> episodesByHash,
  Future<QueueItems> Function({required int page, required int pageSize})
  getQueue,
  bool Function(QueueItem item) matches,
) async {
  const pageSize = ApiConstants.queuePageSize;
  final queueIds = <int>[];
  for (var page = 1; page <= _maxQueuePages; page++) {
    final queue = await getQueue(page: page, pageSize: pageSize);
    for (final item in queue.records.where(matches)) {
      queueIds.add(item.id);
      _addDownload(episodesByHash, item.downloadId, item.episodeId);
    }
    if (queue.records.length < pageSize) break;
    if (queue.records.length >= queue.totalRecords) break;
  }
  return queueIds;
}

/// Records [downloadId] (and [episodeId], when known) in [episodesByHash].
void _addDownload(
  Map<String, Set<int>> episodesByHash,
  String? downloadId,
  int? episodeId,
) {
  if (downloadId == null || downloadId.isEmpty) return;
  final episodes = episodesByHash.putIfAbsent(
    downloadId.toLowerCase(),
    () => <int>{},
  );
  if (episodeId != null) episodes.add(episodeId);
}
