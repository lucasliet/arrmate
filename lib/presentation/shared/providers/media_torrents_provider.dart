import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/logger_service.dart';
import '../../../core/utils/cross_seed_matcher.dart';
import '../../../domain/models/models.dart';
import '../../providers/data_providers.dart';
import '../../providers/instances_provider.dart';
import '../../screens/movies/providers/movie_details_provider.dart';
import '../../screens/series/providers/series_provider.dart';

/// A download-client torrent that backs a library item.
///
/// Carries the [TorrentLink] the torrent details sheet expects, so the sheet
/// opened from a library screen shows the same relation as the one opened from
/// the activity tab.
class LinkedTorrent extends Equatable {
  /// The torrent as reported by the download client.
  final Torrent torrent;

  /// Relation between [torrent] and the library item it was resolved for.
  final TorrentLink link;

  /// Episode ids this torrent was grabbed for.
  ///
  /// A season pack covers several; empty for movies.
  final Set<int> episodeIds;

  const LinkedTorrent({
    required this.torrent,
    required this.link,
    this.episodeIds = const {},
  });

  @override
  List<Object?> get props => [torrent, link, episodeIds];
}

/// Torrents in the download client that back a single library item.
class MediaTorrents extends Equatable {
  /// Source torrents plus their cross-seed duplicates.
  final List<LinkedTorrent> torrents;

  /// `true` when no qBittorrent instance is configured.
  ///
  /// An empty [torrents] then proves nothing, so the UI stays silent instead of
  /// claiming the item has no torrents.
  final bool qbittorrentSkipped;

  const MediaTorrents({
    required this.torrents,
    this.qbittorrentSkipped = false,
  });

  /// An empty result for a configured client.
  static const empty = MediaTorrents(torrents: []);

  /// An empty result for a client that was never configured.
  static const skipped = MediaTorrents(torrents: [], qbittorrentSkipped: true);

  @override
  List<Object?> get props => [torrents, qbittorrentSkipped];
}

/// Resolves the qBittorrent torrents backing the Radarr movie [movieId].
///
/// Reverse of the torrent link index: instead of sweeping the global history
/// for every torrent in the client, it asks Radarr for the history of this one
/// movie (`GET /history/movie`, unpaged) and matches the resulting `downloadId`
/// values against the client's torrent list.
final movieTorrentsProvider = FutureProvider.autoDispose
    .family<MediaTorrents, int>((ref, movieId) async {
      final service = ref.watch(qbittorrentServiceProvider);
      if (service == null) return MediaTorrents.skipped;

      final repository = ref.watch(movieRepositoryProvider);
      final instance = ref.watch(currentRadarrInstanceProvider);
      if (repository == null || instance == null) return MediaTorrents.empty;

      final history = await repository.getMovieHistory(movieId);
      final hashes = _grabbedHashes(history);
      if (hashes.isEmpty) {
        logger.info('[MediaTorrents] Movie $movieId has no download history');
        return MediaTorrents.empty;
      }

      // Awaited rather than read as a state: watching an in-flight
      // `AsyncLoading` would rebuild this provider mid-resolution.
      Movie? movie;
      try {
        movie = await ref.watch(movieDetailsProvider(movieId).future);
      } catch (error, stackTrace) {
        // Title and `hasFile` only decorate the link; the torrents matter more.
        logger.warning(
          '[MediaTorrents] Movie $movieId unavailable for link details',
          error,
          stackTrace,
        );
      }
      final resolved = partitionCrossSeed(await service.getTorrents(), hashes);

      // `hasFile == false` is only meaningful once the movie itself is loaded;
      // without it the link stays "linked" rather than guessing a deletion.
      final link = TorrentLink(
        status: movie?.hasFile == false
            ? TorrentLinkStatus.fileMissing
            : TorrentLinkStatus.linked,
        instanceId: instance.id,
        instanceLabel: instance.label,
        instanceType: instance.type,
        movieId: movieId,
        mediaTitle: movie?.title,
      );

      logger.info(
        '[MediaTorrents] Movie $movieId: ${resolved.source.length} source + '
        '${resolved.crossSeed.length} cross-seed torrent(s)',
      );

      return MediaTorrents(
        torrents: [
          for (final torrent in resolved.source)
            LinkedTorrent(torrent: torrent, link: link),
          for (final torrent in resolved.crossSeed)
            LinkedTorrent(torrent: torrent, link: link.asCrossSeed()),
        ],
      );
    });

/// Resolves the qBittorrent torrents backing the Sonarr series [seriesId].
///
/// Every torrent carries the episode ids it was grabbed for, so the episode
/// details sheet can narrow the list down to one episode while a season pack
/// still shows up under each of its episodes.
final seriesTorrentsProvider = FutureProvider.autoDispose
    .family<MediaTorrents, int>((ref, seriesId) async {
      final service = ref.watch(qbittorrentServiceProvider);
      if (service == null) return MediaTorrents.skipped;

      final repository = ref.watch(seriesRepositoryProvider);
      final instance = ref.watch(currentSonarrInstanceProvider);
      if (repository == null || instance == null) return MediaTorrents.empty;

      final history = await repository.getSeriesHistory(seriesId);
      final episodesByHash = _episodesByHash(history);
      if (episodesByHash.isEmpty) {
        logger.info('[MediaTorrents] Series $seriesId has no download history');
        return MediaTorrents.empty;
      }

      // Awaited rather than read as a state: watching an in-flight
      // `AsyncLoading` would rebuild this provider mid-resolution.
      Series? series;
      try {
        series = await ref.watch(seriesDetailsProvider(seriesId).future);
      } catch (error, stackTrace) {
        // The title only decorates the link; the torrents matter more.
        logger.warning(
          '[MediaTorrents] Series $seriesId unavailable for link details',
          error,
          stackTrace,
        );
      }
      final resolved = partitionCrossSeed(
        await service.getTorrents(),
        episodesByHash.keys.toSet(),
      );

      logger.info(
        '[MediaTorrents] Series $seriesId: ${resolved.source.length} source + '
        '${resolved.crossSeed.length} cross-seed torrent(s)',
      );

      /// Builds the relation for [torrent], reusing the episode set collected
      /// for the source hash it belongs to.
      LinkedTorrent build(
        Torrent torrent,
        Set<int> episodeIds,
        bool crossSeed,
      ) {
        // Only a single-episode grab can claim an episode: a season pack would
        // otherwise pretend to be whichever of its episodes came first.
        final episodeId = episodeIds.length == 1 ? episodeIds.single : null;
        final link = TorrentLink(
          status: TorrentLinkStatus.linked,
          instanceId: instance.id,
          instanceLabel: instance.label,
          instanceType: instance.type,
          seriesId: seriesId,
          episodeId: episodeId,
          mediaTitle: series?.title,
        );
        return LinkedTorrent(
          torrent: torrent,
          link: crossSeed ? link.asCrossSeed() : link,
          episodeIds: episodeIds,
        );
      }

      final sourceEpisodesByName = <String, Set<int>>{};
      final torrents = <LinkedTorrent>[];
      for (final torrent in resolved.source) {
        final episodeIds =
            episodesByHash[torrent.hash.toLowerCase()] ?? const <int>{};
        sourceEpisodesByName[normalizeTorrentName(torrent.name)] = episodeIds;
        torrents.add(build(torrent, episodeIds, false));
      }
      for (final torrent in resolved.crossSeed) {
        final episodeIds =
            sourceEpisodesByName[normalizeTorrentName(torrent.name)] ??
            const <int>{};
        torrents.add(build(torrent, episodeIds, true));
      }

      return MediaTorrents(torrents: torrents);
    });

/// Collects the lowercased infohashes Radarr/Sonarr recorded for a media item.
///
/// Only `grabbed` and `imported` events carry a download the client may still
/// hold, matching what the purge service resolves for the same item. The queue
/// is deliberately not scanned: the `grabbed` event exists from the moment the
/// release is handed to the client, so in-flight downloads are already covered.
Set<String> _grabbedHashes(List<HistoryEvent> history) {
  final hashes = <String>{};
  for (final event in history) {
    if (event.eventType != HistoryEventType.grabbed &&
        event.eventType != HistoryEventType.imported) {
      continue;
    }
    final downloadId = event.downloadId;
    if (downloadId == null || downloadId.isEmpty) continue;
    hashes.add(downloadId.toLowerCase());
  }
  return hashes;
}

/// Groups the episode ids of a series history by lowercased infohash.
Map<String, Set<int>> _episodesByHash(List<HistoryEvent> history) {
  final episodesByHash = <String, Set<int>>{};
  for (final event in history) {
    if (event.eventType != HistoryEventType.grabbed &&
        event.eventType != HistoryEventType.imported) {
      continue;
    }
    final downloadId = event.downloadId;
    if (downloadId == null || downloadId.isEmpty) continue;
    final episodes = episodesByHash.putIfAbsent(
      downloadId.toLowerCase(),
      () => <int>{},
    );
    final episodeId = event.episodeId;
    if (episodeId != null) episodes.add(episodeId);
  }
  return episodesByHash;
}
