import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../domain/models/models.dart';
import '../../../../domain/repositories/movie_repository.dart';
import '../../../../domain/repositories/series_repository.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/instances_provider.dart';
import '../../../widgets/instance_load_failure_banner.dart';
import 'qbittorrent_provider.dart';

/// Maximum number of history pages scanned per instance.
///
/// Acts as a backstop: the scan normally stops much earlier, either because
/// every torrent hash was resolved or because the events became older than the
/// oldest torrent still present in the client.
const int _maxHistoryPages = 25;

/// Maximum number of queue pages scanned per instance.
const int _maxQueuePages = 5;

/// Page size used for the history scan. Larger than the activity screen's page
/// size because this scan is a one-shot sweep, not an interactive list.
const int _historyPageSize = 100;

/// Slack applied to the "stop when older than the oldest torrent" rule, so
/// clock skew between the device, the *arr instance and the download client
/// cannot cut the scan short.
const Duration _historyDateSlack = Duration(days: 1);

/// Relation between the torrents in the download client and the Radarr/Sonarr
/// media library.
///
/// The index is keyed by the lowercased torrent infohash, which Radarr/Sonarr
/// expose as `downloadId` in their history and queue resources.
class TorrentLinkIndex {
  /// Links resolved from history and queue data, keyed by lowercased infohash.
  final Map<String, TorrentLink> linksByHash;

  /// Download-client categories that Radarr/Sonarr assign to their own
  /// downloads. A torrent sitting in one of these without a link is an orphan.
  final Set<String> managedCategories;

  /// Instances that failed to answer, so the UI can offer a retry.
  final List<InstanceLoadFailure> failures;

  /// Whether at least one Radarr/Sonarr instance is configured.
  final bool hasInstances;

  const TorrentLinkIndex({
    required this.linksByHash,
    required this.managedCategories,
    required this.failures,
    required this.hasInstances,
  });

  /// An index that classifies nothing, used while no data is available.
  static const empty = TorrentLinkIndex(
    linksByHash: {},
    managedCategories: {},
    failures: [],
    hasInstances: false,
  );

  /// Whether a missing hash can be classified.
  ///
  /// With no instance configured, or with a partial failure, the absence of a
  /// match proves nothing — reporting `orphan` in that situation would flag
  /// healthy torrents as garbage.
  bool get canClassifyMisses => hasInstances && failures.isEmpty;

  /// Resolves how [torrent] relates to the media library.
  TorrentLink resolve(Torrent torrent) {
    final link = linksByHash[torrent.hash.toLowerCase()];
    if (link != null) {
      // A torrent that has not finished yet simply has nothing to import; that
      // is not the same as a media file that was deleted.
      if (link.status == TorrentLinkStatus.fileMissing && !torrent.isComplete) {
        return link.copyWithStatus(TorrentLinkStatus.linked);
      }
      return link;
    }

    if (!canClassifyMisses) return TorrentLink.unknown;

    final category = torrent.category?.trim();
    if (category != null &&
        category.isNotEmpty &&
        managedCategories.contains(category)) {
      return const TorrentLink(status: TorrentLinkStatus.orphan);
    }
    return const TorrentLink(status: TorrentLinkStatus.external);
  }
}

/// Indexes the torrents of the selected qBittorrent instance against every
/// configured Radarr/Sonarr instance.
///
/// The provider depends on a fingerprint of the torrent hashes rather than on
/// the torrent list itself, so the fast download polling of
/// [qbittorrentTorrentsProvider] does not trigger a re-index on every tick.
final torrentLinkIndexProvider = FutureProvider.autoDispose<TorrentLinkIndex>((
  ref,
) async {
  final fingerprint = ref.watch(
    qbittorrentTorrentsProvider.select(_torrentFingerprint),
  );
  final radarrInstances = ref.watch(
    instancesByTypeProvider(InstanceType.radarr),
  );
  final sonarrInstances = ref.watch(
    instancesByTypeProvider(InstanceType.sonarr),
  );
  final hasInstances = radarrInstances.isNotEmpty || sonarrInstances.isNotEmpty;

  if (fingerprint.isEmpty || !hasInstances) {
    return TorrentLinkIndex(
      linksByHash: const {},
      managedCategories: const {},
      failures: const [],
      hasInstances: hasInstances,
    );
  }

  final torrents =
      ref.read(qbittorrentTorrentsProvider).valueOrNull ?? const [];
  final pendingHashes = {
    for (final torrent in torrents) torrent.hash.toLowerCase(),
  };
  final oldestAddedOn = _oldestAddedOn(torrents);

  logger.info(
    '[TorrentLinkIndex] Indexing ${pendingHashes.length} torrent(s) against '
    '${radarrInstances.length} Radarr + ${sonarrInstances.length} Sonarr '
    'instance(s)',
  );

  final results = await Future.wait([
    for (final instance in radarrInstances)
      _collectMovieLinks(
        instance,
        ref.read(movieRepositoryForInstanceProvider(instance)),
        pendingHashes,
        oldestAddedOn,
      ),
    for (final instance in sonarrInstances)
      _collectSeriesLinks(
        instance,
        ref.read(seriesRepositoryForInstanceProvider(instance)),
        pendingHashes,
        oldestAddedOn,
      ),
  ]);

  final linksByHash = <String, TorrentLink>{};
  final managedCategories = <String>{};
  final failures = <InstanceLoadFailure>[];
  for (final result in results) {
    linksByHash.addAll(result.links);
    managedCategories.addAll(result.categories);
    if (result.failure != null) failures.add(result.failure!);
  }

  // Fallback for instances that do not expose their download-client settings:
  // any category holding a linked torrent is, by definition, *arr-managed.
  if (managedCategories.isEmpty) {
    for (final torrent in torrents) {
      final category = torrent.category?.trim();
      if (category == null || category.isEmpty) continue;
      if (!linksByHash.containsKey(torrent.hash.toLowerCase())) continue;
      managedCategories.add(category);
    }
  }

  logger.info(
    '[TorrentLinkIndex] Resolved ${linksByHash.length} link(s), '
    '${managedCategories.length} managed category(ies), '
    '${failures.length} failure(s)',
  );

  return TorrentLinkIndex(
    linksByHash: linksByHash,
    managedCategories: managedCategories,
    failures: failures,
    hasInstances: true,
  );
});

/// Outcome of indexing a single Radarr/Sonarr instance.
class _InstanceLinkResult {
  final Map<String, TorrentLink> links;
  final Set<String> categories;
  final InstanceLoadFailure? failure;

  const _InstanceLinkResult({
    required this.links,
    required this.categories,
    this.failure,
  });
}

/// Builds a stable fingerprint of the torrent hashes currently in the client.
///
/// Progress, speed and peer counts change on every poll; the set of hashes does
/// not, which keeps the index from being rebuilt every few seconds.
String _torrentFingerprint(AsyncValue<List<Torrent>> state) {
  final torrents = state.valueOrNull;
  if (torrents == null || torrents.isEmpty) return '';
  final hashes = torrents.map((t) => t.hash.toLowerCase()).toList()..sort();
  return hashes.join(',');
}

/// Returns the oldest `addedOn` among [torrents], used as the history scan
/// boundary: no torrent still present can match an older event.
///
/// qBittorrent reports `added_on` as Unix seconds, and `0` when it is unknown —
/// those are ignored so a single unstamped torrent does not silently disable
/// the boundary.
DateTime? _oldestAddedOn(List<Torrent> torrents) {
  int? oldest;
  for (final torrent in torrents) {
    final addedOn = torrent.addedOn;
    if (addedOn <= 0) continue;
    if (oldest == null || addedOn < oldest) oldest = addedOn;
  }
  if (oldest == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(oldest * 1000, isUtc: true);
}

Future<_InstanceLinkResult> _collectMovieLinks(
  Instance instance,
  MovieRepository repository,
  Set<String> torrentHashes,
  DateTime? oldestAddedOn,
) {
  return _collectLinks(
    instance: instance,
    torrentHashes: torrentHashes,
    oldestAddedOn: oldestAddedOn,
    loadHistory: (page) => repository.getHistory(
      page: page,
      pageSize: _historyPageSize,
      eventType: HistoryEventType.grabbed,
      includeMovie: true,
    ),
    loadQueue: (page) =>
        repository.getQueue(page: page, pageSize: ApiConstants.queuePageSize),
    loadDownloadClients: repository.getDownloadClients,
    buildFromEvent: (event) => _movieLinkFromEvent(instance, event),
    buildFromQueueItem: (item) => _movieLinkFromQueueItem(instance, item),
  );
}

Future<_InstanceLinkResult> _collectSeriesLinks(
  Instance instance,
  SeriesRepository repository,
  Set<String> torrentHashes,
  DateTime? oldestAddedOn,
) {
  return _collectLinks(
    instance: instance,
    torrentHashes: torrentHashes,
    oldestAddedOn: oldestAddedOn,
    loadHistory: (page) => repository.getHistory(
      page: page,
      pageSize: _historyPageSize,
      eventType: HistoryEventType.grabbed,
      includeSeries: true,
      includeEpisode: true,
    ),
    loadQueue: (page) =>
        repository.getQueue(page: page, pageSize: ApiConstants.queuePageSize),
    loadDownloadClients: repository.getDownloadClients,
    buildFromEvent: (event) => _seriesLinkFromEvent(instance, event),
    buildFromQueueItem: (item) => _seriesLinkFromQueueItem(instance, item),
  );
}

/// Scans one instance for links, shared by the Radarr and Sonarr paths.
///
/// Failures are captured as an [InstanceLoadFailure] instead of propagating, so
/// one unreachable instance never blanks out the whole index.
Future<_InstanceLinkResult> _collectLinks({
  required Instance instance,
  required Set<String> torrentHashes,
  required DateTime? oldestAddedOn,
  required Future<HistoryPage> Function(int page) loadHistory,
  required Future<QueueItems> Function(int page) loadQueue,
  required Future<List<DownloadClientInfo>> Function() loadDownloadClients,
  required TorrentLink? Function(HistoryEvent event) buildFromEvent,
  required TorrentLink? Function(QueueItem item) buildFromQueueItem,
}) async {
  final links = <String, TorrentLink>{};
  final categories = <String>{};

  // The download-client settings are optional context: an instance that hides
  // them still produces links, it only loses orphan detection precision.
  try {
    for (final client in await loadDownloadClients()) {
      if (!client.enable) continue;
      categories.addAll(client.categories);
    }
  } catch (error, stackTrace) {
    logger.warning(
      '[TorrentLinkIndex] Download clients unavailable for ${instance.id}',
      error,
      stackTrace,
    );
  }

  try {
    final pending = {...torrentHashes};
    await _scanHistory(
      loadHistory: loadHistory,
      buildFromEvent: buildFromEvent,
      pending: pending,
      links: links,
      oldestAddedOn: oldestAddedOn,
    );
    await _scanQueue(
      loadQueue: loadQueue,
      buildFromQueueItem: buildFromQueueItem,
      torrentHashes: torrentHashes,
      links: links,
    );
  } catch (error, stackTrace) {
    logger.error(
      '[TorrentLinkIndex] Failed to index instance ${instance.id}',
      error,
      stackTrace,
    );
    return _InstanceLinkResult(
      links: links,
      categories: categories,
      failure: InstanceLoadFailure(
        instanceId: instance.id,
        instanceType: instance.type,
        instanceLabel: instance.label,
        message: 'Library links could not be loaded.',
      ),
    );
  }

  return _InstanceLinkResult(links: links, categories: categories);
}

/// Pages through `grabbed` history events collecting the hashes that belong to
/// torrents still present in the client.
Future<void> _scanHistory({
  required Future<HistoryPage> Function(int page) loadHistory,
  required TorrentLink? Function(HistoryEvent event) buildFromEvent,
  required Set<String> pending,
  required Map<String, TorrentLink> links,
  required DateTime? oldestAddedOn,
}) async {
  for (var page = 1; page <= _maxHistoryPages; page++) {
    final historyPage = await loadHistory(page);
    final records = historyPage.records;
    if (records.isEmpty) return;

    for (final event in records) {
      final downloadId = event.downloadId?.toLowerCase();
      if (downloadId == null || downloadId.isEmpty) continue;
      if (!pending.contains(downloadId)) continue;
      final link = buildFromEvent(event);
      if (link == null) continue;
      final existing = links[downloadId];
      if (existing == null) {
        links[downloadId] = link;
        continue;
      }
      // A season pack yields one event per episode: the torrent only counts as
      // "file removed" when none of its episodes is on disk anymore.
      if (existing.status == TorrentLinkStatus.fileMissing &&
          link.status == TorrentLinkStatus.linked) {
        links[downloadId] = existing.copyWithStatus(TorrentLinkStatus.linked);
      }
    }

    pending.removeWhere(links.containsKey);
    if (pending.isEmpty) return;
    if (!historyPage.hasMore) return;
    if (_isOlderThanTorrents(records, oldestAddedOn)) return;
  }
}

/// Whether the scan can stop because [records] already predate every torrent
/// still in the client.
///
/// Only applied when the page really is sorted newest-first, so an instance
/// answering in another order falls back to the page cap instead of being cut
/// short.
bool _isOlderThanTorrents(List<HistoryEvent> records, DateTime? oldestAddedOn) {
  if (oldestAddedOn == null) return false;
  for (var i = 1; i < records.length; i++) {
    if (records[i].date.isAfter(records[i - 1].date)) return false;
  }
  return records.last.date.isBefore(oldestAddedOn.subtract(_historyDateSlack));
}

/// Pages through the activity queue, which is authoritative for downloads that
/// have not been imported yet.
Future<void> _scanQueue({
  required Future<QueueItems> Function(int page) loadQueue,
  required TorrentLink? Function(QueueItem item) buildFromQueueItem,
  required Set<String> torrentHashes,
  required Map<String, TorrentLink> links,
}) async {
  for (var page = 1; page <= _maxQueuePages; page++) {
    final queue = await loadQueue(page);
    for (final item in queue.records) {
      final downloadId = item.downloadId?.toLowerCase();
      if (downloadId == null || downloadId.isEmpty) continue;
      if (!torrentHashes.contains(downloadId)) continue;
      final link = buildFromQueueItem(item);
      if (link != null) links[downloadId] = link;
    }
    if (queue.records.length < ApiConstants.queuePageSize) return;
    if (queue.records.length >= queue.totalRecords) return;
  }
}

TorrentLink? _movieLinkFromEvent(Instance instance, HistoryEvent event) {
  final movieId = event.movieId ?? event.movie?.id;
  if (movieId == null) return null;
  final movie = event.movie;
  // `hasFile` is only known when the instance honored `includeMovie`; without
  // it the link stays "linked" rather than guessing a deletion.
  final fileMissing = movie != null && movie.hasFile == false;
  return TorrentLink(
    status: fileMissing
        ? TorrentLinkStatus.fileMissing
        : TorrentLinkStatus.linked,
    instanceId: instance.id,
    instanceLabel: instance.label,
    instanceType: instance.type,
    movieId: movieId,
    mediaTitle: movie?.title,
    sourceTitle: event.sourceTitle,
  );
}

TorrentLink? _seriesLinkFromEvent(Instance instance, HistoryEvent event) {
  final seriesId = event.seriesId ?? event.series?.id;
  if (seriesId == null) return null;
  final episode = event.episode;
  final fileMissing = episode != null && !episode.hasFile;
  return TorrentLink(
    status: fileMissing
        ? TorrentLinkStatus.fileMissing
        : TorrentLinkStatus.linked,
    instanceId: instance.id,
    instanceLabel: instance.label,
    instanceType: instance.type,
    seriesId: seriesId,
    episodeId: event.episodeId ?? episode?.id,
    seasonNumber: episode?.seasonNumber,
    episodeNumber: episode?.episodeNumber,
    mediaTitle: event.series?.title,
    sourceTitle: event.sourceTitle,
  );
}

TorrentLink? _movieLinkFromQueueItem(Instance instance, QueueItem item) {
  final movieId = item.movieId ?? item.movie?.id;
  if (movieId == null) return null;
  return TorrentLink(
    status: TorrentLinkStatus.linked,
    instanceId: instance.id,
    instanceLabel: instance.label,
    instanceType: instance.type,
    movieId: movieId,
    mediaTitle: item.movie?.title,
    sourceTitle: item.title,
  );
}

TorrentLink? _seriesLinkFromQueueItem(Instance instance, QueueItem item) {
  final seriesId = item.seriesId ?? item.series?.id;
  if (seriesId == null) return null;
  return TorrentLink(
    status: TorrentLinkStatus.linked,
    instanceId: instance.id,
    instanceLabel: instance.label,
    instanceType: instance.type,
    seriesId: seriesId,
    episodeId: item.episodeId ?? item.episode?.id,
    seasonNumber: item.seasonNumber ?? item.episode?.seasonNumber,
    episodeNumber: item.episode?.episodeNumber,
    mediaTitle: item.series?.title,
    sourceTitle: item.title,
  );
}
