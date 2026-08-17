import '../../domain/models/models.dart';
import '../screens/calendar/providers/calendar_provider.dart';

/// Sample entities used to populate the UI while the guided tour runs on a
/// fresh install.
///
/// Every object here is built on the fly by the widget layer and thrown away
/// when the tour ends: nothing is stored in a provider, persisted to disk, or
/// sent to a server. Its only purpose is to give each tour step a visible,
/// representative target on screens that would otherwise be empty.
class TourMockData {
  const TourMockData._();

  /// Sample movies rendered on the Movies screen.
  static List<Movie> movies() {
    final added = DateTime.now().subtract(const Duration(days: 40));
    return [
      _movie(
        id: 1,
        title: 'Northern Lights',
        year: 2024,
        added: added,
        downloaded: true,
      ),
      _movie(id: 2, title: 'The Last Signal', year: 2023, added: added),
      _movie(
        id: 3,
        title: 'Paper Kingdom',
        year: 2025,
        added: added,
        status: MovieStatus.announced,
      ),
      _movie(
        id: 4,
        title: 'Silent Harbor',
        year: 2022,
        added: added,
        downloaded: true,
        monitored: false,
      ),
      _movie(
        id: 5,
        title: 'Echoes of Tomorrow',
        year: 2024,
        added: added,
        downloaded: true,
      ),
      _movie(id: 6, title: 'Copper Canyon', year: 2021, added: added),
    ];
  }

  /// Sample series rendered on the Series screen.
  static List<Series> series() {
    final added = DateTime.now().subtract(const Duration(days: 40));
    return [
      _series(
        id: 1,
        title: 'Blue Harbor',
        year: 2023,
        added: added,
        seasonCount: 3,
        percentOfEpisodes: 100,
      ),
      _series(
        id: 2,
        title: 'Static Fields',
        year: 2021,
        added: added,
        seasonCount: 2,
        percentOfEpisodes: 62,
      ),
      _series(
        id: 3,
        title: 'The Longest Winter',
        year: 2024,
        added: added,
        seasonCount: 1,
        percentOfEpisodes: 40,
      ),
      _series(
        id: 4,
        title: 'Night Bus',
        year: 2020,
        added: added,
        seasonCount: 4,
        percentOfEpisodes: 100,
        monitored: false,
        status: SeriesStatus.ended,
      ),
      _series(
        id: 5,
        title: 'Orbital',
        year: 2025,
        added: added,
        seasonCount: 1,
        percentOfEpisodes: 0,
        status: SeriesStatus.upcoming,
      ),
      _series(
        id: 6,
        title: 'Field Notes',
        year: 2019,
        added: added,
        seasonCount: 5,
        percentOfEpisodes: 100,
        status: SeriesStatus.ended,
      ),
    ];
  }

  /// Sample releases rendered on the Calendar screen.
  static List<CalendarEvent> calendarEvents() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final movies = TourMockData.movies();
    final seriesList = TourMockData.series();

    return [
      CalendarEvent(
        releaseDate: startOfDay.add(const Duration(hours: 20)),
        type: CalendarEventType.episode,
        series: seriesList[0],
        episode: _episode(
          id: 1,
          seriesId: seriesList[0].id,
          seasonNumber: 3,
          episodeNumber: 4,
          title: 'Low Tide',
          airDate: startOfDay.add(const Duration(hours: 20)),
        ),
      ),
      CalendarEvent(
        releaseDate: startOfDay.add(const Duration(hours: 9)),
        type: CalendarEventType.digital,
        movie: movies[1],
      ),
      CalendarEvent(
        releaseDate: startOfDay.add(const Duration(days: 1, hours: 21)),
        type: CalendarEventType.episode,
        series: seriesList[2],
        episode: _episode(
          id: 2,
          seriesId: seriesList[2].id,
          seasonNumber: 1,
          episodeNumber: 7,
          title: 'Thaw',
          airDate: startOfDay.add(const Duration(days: 1, hours: 21)),
        ),
      ),
      CalendarEvent(
        releaseDate: startOfDay.add(const Duration(days: 3, hours: 18)),
        type: CalendarEventType.cinema,
        movie: movies[2],
      ),
    ];
  }

  /// Sample download tasks rendered on the Activity queue tab.
  static List<QueueItem> queueItems() {
    final now = DateTime.now();
    final movies = TourMockData.movies();
    final seriesList = TourMockData.series();

    return [
      QueueItem(
        id: 1,
        title: movies[1].title,
        movieId: movies[1].guid,
        movie: movies[1],
        status: QueueStatus.downloading,
        protocol: 'torrent',
        downloadClient: 'qBittorrent',
        quality: const MediaQuality(
          quality: QualityInfo(id: 7, name: 'Bluray-1080p'),
          revision: 1,
        ),
        size: 12884901888,
        sizeleft: 4831838208,
        estimatedCompletionTime: now.add(const Duration(minutes: 14)),
      ),
      QueueItem(
        id: 2,
        title: seriesList[2].title,
        seriesId: seriesList[2].guid,
        series: seriesList[2],
        episode: _episode(
          id: 3,
          seriesId: seriesList[2].id,
          seasonNumber: 1,
          episodeNumber: 6,
          title: 'First Frost',
        ),
        status: QueueStatus.downloading,
        protocol: 'torrent',
        downloadClient: 'qBittorrent',
        quality: const MediaQuality(
          quality: QualityInfo(id: 4, name: 'WEBDL-1080p'),
          revision: 1,
        ),
        size: 3221225472,
        sizeleft: 2469606195,
        estimatedCompletionTime: now.add(const Duration(minutes: 38)),
      ),
      QueueItem(
        id: 3,
        title: movies[5].title,
        movieId: movies[5].guid,
        movie: movies[5],
        status: QueueStatus.queued,
        protocol: 'usenet',
        downloadClient: 'SABnzbd',
        quality: const MediaQuality(
          quality: QualityInfo(id: 19, name: 'Bluray-2160p'),
          revision: 1,
        ),
        size: 26843545600,
        sizeleft: 26843545600,
      ),
    ];
  }

  /// Sample torrents rendered on the Activity torrents tab.
  static List<Torrent> torrents() {
    final addedOn =
        DateTime.now()
            .subtract(const Duration(hours: 6))
            .millisecondsSinceEpoch ~/
        1000;

    return [
      _torrent(
        hash: 'tour-mock-1',
        name: 'The.Last.Signal.2023.1080p.BluRay',
        size: 12884901888,
        progress: 0.62,
        status: TorrentStatus.downloading,
        state: 'downloading',
        category: 'radarr',
        dlspeed: 7340032,
        eta: 840,
        ratio: 0.4,
        numSeeds: 24,
        numLeechs: 6,
        addedOn: addedOn,
      ),
      _torrent(
        hash: 'tour-mock-2',
        name: 'Blue.Harbor.S03E04.1080p.WEB-DL',
        size: 3221225472,
        progress: 1,
        status: TorrentStatus.uploading,
        state: 'uploading',
        category: 'sonarr',
        upspeed: 1048576,
        ratio: 2.35,
        numSeeds: 11,
        numLeechs: 3,
        addedOn: addedOn,
        seedingTime: 9000,
      ),
      _torrent(
        hash: 'tour-mock-3',
        name: 'Copper.Canyon.2021.2160p.UHD',
        size: 26843545600,
        progress: 0.18,
        status: TorrentStatus.pausedDL,
        state: 'pausedDL',
        ratio: 0.1,
        numSeeds: 2,
        numLeechs: 1,
        addedOn: addedOn,
      ),
    ];
  }

  static Movie _movie({
    required int id,
    required String title,
    required int year,
    required DateTime added,
    bool downloaded = false,
    bool monitored = true,
    MovieStatus status = MovieStatus.released,
  }) {
    return Movie(
      guid: id,
      tmdbId: id,
      title: title,
      sortTitle: title.toLowerCase(),
      year: year,
      runtime: 118,
      status: status,
      isAvailable: status == MovieStatus.released,
      minimumAvailability: MovieStatus.released,
      monitored: monitored,
      qualityProfileId: 1,
      added: added,
      hasFile: downloaded,
      movieFile: downloaded
          ? MediaFile(id: id, size: 12884901888, dateAdded: added)
          : null,
    );
  }

  static Series _series({
    required int id,
    required String title,
    required int year,
    required DateTime added,
    required int seasonCount,
    required double percentOfEpisodes,
    bool monitored = true,
    SeriesStatus status = SeriesStatus.continuing,
  }) {
    final seasons = List.generate(
      seasonCount,
      (index) => Season(seasonNumber: index + 1, monitored: monitored),
    );

    return Series(
      guid: id,
      title: title,
      sortTitle: title.toLowerCase(),
      tvdbId: id,
      status: status,
      seriesType: SeriesType.standard,
      year: year,
      runtime: 45,
      added: added,
      monitored: monitored,
      ended: status == SeriesStatus.ended,
      seasons: seasons,
      statistics: SeriesStatistics(
        sizeOnDisk: 32212254720,
        seasonCount: seasonCount,
        episodeCount: seasonCount * 10,
        episodeFileCount: (seasonCount * 10 * percentOfEpisodes / 100).round(),
        totalEpisodeCount: seasonCount * 10,
        percentOfEpisodes: percentOfEpisodes,
      ),
    );
  }

  static Episode _episode({
    required int id,
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
    required String title,
    DateTime? airDate,
  }) {
    return Episode(
      id: id,
      seriesId: seriesId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      title: title,
      airDate: airDate,
      airDateUtc: airDate?.toUtc(),
      runtime: 45,
      monitored: true,
    );
  }

  static Torrent _torrent({
    required String hash,
    required String name,
    required int size,
    required double progress,
    required TorrentStatus status,
    required String state,
    required double ratio,
    required int numSeeds,
    required int numLeechs,
    required int addedOn,
    String? category,
    int dlspeed = 0,
    int upspeed = 0,
    int eta = -1,
    int seedingTime = 0,
  }) {
    return Torrent(
      hash: hash,
      name: name,
      size: size,
      progress: progress,
      dlspeed: dlspeed,
      upspeed: upspeed,
      eta: eta,
      ratio: ratio,
      status: status,
      state: state,
      category: category,
      tags: const [],
      savePath: '/downloads',
      numSeeds: numSeeds,
      numLeechs: numLeechs,
      downloaded: (size * progress).round(),
      uploaded: (size * ratio).round(),
      amountLeft: (size * (1 - progress)).round(),
      addedOn: addedOn,
      priority: 0,
      seedingTime: seedingTime,
    );
  }
}
