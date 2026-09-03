import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/constants/api_constants.dart';
import 'package:arrmate/domain/models/models.dart';

/// API Client for interacting with Sonarr.
class SonarrApi {
  final ApiClient _client;
  final Instance instance;

  SonarrApi(this.instance, [ApiClient? client])
    : _client =
          client ??
          ApiClient(
            baseUrl: '${instance.connectionUrls.first}${ApiConstants.apiPath}',
            fallbackBaseUrls: instance.connectionUrls
                .skip(1)
                .map((url) => '$url${ApiConstants.apiPath}')
                .toList(),
            headers: instance.authHeaders,
            diagnosticSource: instance.id,
          );

  /// Retrieves all series from the Sonarr library.
  Future<List<Series>> getSeries() async {
    final response = await _client.get(
      '/series',
      customTimeout: instance.timeout(InstanceTimeout.slow),
    );
    return (response as List)
        .map((e) => Series.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves a specific series by its [id].
  Future<Series> getSeriesById(int id) async {
    final response = await _client.get('/series/$id');
    return Series.fromJson(response as Map<String, dynamic>);
  }

  /// Adds a new series to the library.
  Future<Series> addSeries(Series series) async {
    final response = await _client.post('/series', data: series.toJson());
    return Series.fromJson(response as Map<String, dynamic>);
  }

  /// Updates an existing series.
  ///
  /// [moveFiles] - If true, moves files to the new path if the path has changed.
  Future<Series> updateSeries(Series series, {bool moveFiles = false}) async {
    await _client.put(
      '/series/editor',
      data: {
        'seriesIds': [series.id],
        'monitored': series.monitored,
        'monitorNewItems':
            (series.monitorNewItems ?? SeriesMonitorNewItems.none).name,
        'seriesType': series.seriesType.name,
        'seasonFolder': series.seasonFolder,
        'qualityProfileId': series.qualityProfileId,
        'rootFolderPath': series.rootFolderPath,
        'tags': series.tags,
        'applyTags': 'replace',
        if (moveFiles) 'moveFiles': true,
      },
    );
    return series;
  }

  /// Persists the monitoring flags of [series], seasons included.
  ///
  /// [updateSeries] cannot do this: `/series/editor` is a bulk editor that
  /// only accepts series-level fields, so a `seasons` entry sent to it is
  /// silently dropped and the request still answers 200. Per-season
  /// monitoring lives on the single-series endpoint instead.
  ///
  /// The body is the resource Sonarr itself returned, with only the
  /// monitoring flags rewritten, so every field Arrmate does not model
  /// round-trips untouched rather than being reset to a default.
  Future<Series> updateSeriesMonitoring(Series series) async {
    final current =
        await _client.get('/series/${series.id}') as Map<String, dynamic>;

    final monitoredBySeason = {
      for (final season in series.seasons)
        season.seasonNumber: season.monitored,
    };
    final seasons = ((current['seasons'] as List?) ?? const []).map((season) {
      final json = Map<String, dynamic>.from(season as Map);
      final monitored = monitoredBySeason[json['seasonNumber'] as int];
      if (monitored != null) json['monitored'] = monitored;
      return json;
    }).toList();

    final response = await _client.put(
      '/series/${series.id}',
      data: {...current, 'monitored': series.monitored, 'seasons': seasons},
    );
    return Series.fromJson(response as Map<String, dynamic>);
  }

  /// Deletes a series from the library.
  ///
  /// [deleteFiles] - If true, also deletes the series files from disk.
  /// [addExclusion] - If true, adds the series to the exclusion list (prevents re-import).
  Future<void> deleteSeries(
    int id, {
    bool deleteFiles = false,
    bool addExclusion = false,
  }) async {
    await _client.delete(
      '/series/$id',
      queryParameters: {
        'deleteFiles': deleteFiles,
        'addImportListExclusion': addExclusion,
      },
      customTimeout: instance.timeout(InstanceTimeout.slow),
    );
  }

  /// Retrieves available quality profiles.
  Future<List<QualityProfile>> getQualityProfiles() async {
    final response = await _client.get('/qualityprofile');
    return (response as List)
        .map((e) => QualityProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves configured root folders.
  Future<List<RootFolder>> getRootFolders() async {
    final response = await _client.get(
      '/rootfolder',
      customTimeout: instance.timeout(InstanceTimeout.slow),
    );
    return (response as List)
        .map((e) => RootFolder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Searches for releases for a specific episode, season or series.
  ///
  /// - [episodeId]: looks up releases for a single episode.
  /// - [seriesId] + [seasonNumber]: looks up releases (including season packs)
  ///   for an entire season.
  Future<List<Release>> getSeriesReleases({
    int? episodeId,
    int? seriesId,
    int? seasonNumber,
  }) async {
    final response = await _client.get(
      '/release',
      queryParameters: {
        'episodeId': ?episodeId,
        'seriesId': ?seriesId,
        'seasonNumber': ?seasonNumber,
      },
      customTimeout: instance.timeout(InstanceTimeout.releaseSearch),
    );
    return (response as List)
        .map((e) => Release.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Commands Sonarr to download a specific release.
  Future<void> downloadRelease(String guid, String indexerId) async {
    await _client.post(
      '/release',
      data: {'guid': guid, 'indexerId': indexerId},
      customTimeout: instance.timeout(InstanceTimeout.releaseDownload),
    );
  }

  /// Searches for series by [term].
  Future<List<Series>> lookupSeries(String term) async {
    final response = await _client.get(
      '/series/lookup',
      queryParameters: {'term': term},
      customTimeout: instance.timeout(InstanceTimeout.slow),
    );
    return (response as List)
        .map((e) => Series.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Commands Sonarr to search for a specific series.
  Future<void> seriesSearch(int seriesId) async {
    await _client.post(
      '/command',
      data: {'name': 'SeriesSearch', 'seriesId': seriesId},
      customTimeout: instance.timeout(InstanceTimeout.releaseSearch),
    );
  }

  /// Commands Sonarr to search for a specific episode.
  Future<void> episodeSearch(int episodeId) async {
    await _client.post(
      '/command',
      data: {
        'name': 'EpisodeSearch',
        'episodeIds': [episodeId],
      },
      customTimeout: instance.timeout(InstanceTimeout.releaseSearch),
    );
  }

  /// Commands Sonarr to search for every monitored episode of a season.
  Future<void> seasonSearch(int seriesId, int seasonNumber) async {
    await _client.post(
      '/command',
      data: {
        'name': 'SeasonSearch',
        'seriesId': seriesId,
        'seasonNumber': seasonNumber,
      },
      customTimeout: instance.timeout(InstanceTimeout.releaseSearch),
    );
  }

  /// Retrieves episodes for a specific series.
  Future<List<Episode>> getEpisodes(int seriesId) async {
    final response = await _client.get(
      '/episode',
      queryParameters: {'seriesId': seriesId},
    );
    return (response as List)
        .map((e) => Episode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves a specific episode by its [id].
  Future<Episode> getEpisode(int id) async {
    final response = await _client.get('/episode/$id');
    return Episode.fromJson(response as Map<String, dynamic>);
  }

  /// Retrieves upcoming episodes from the calendar.
  ///
  /// [start] and [end] define the date range.
  /// [unmonitored] includes episodes that are not monitored when true.
  Future<List<Episode>> getCalendar({
    DateTime? start,
    DateTime? end,
    bool unmonitored = true,
  }) async {
    final response = await _client.get(
      '/calendar',
      queryParameters: {
        if (start != null) 'start': start.toIso8601String(),
        if (end != null) 'end': end.toIso8601String(),
        'unmonitored': unmonitored,
        'includeSeries': true,
        'includeEpisodeFile': true,
      },
      customTimeout: instance.timeout(InstanceTimeout.slow),
    );

    // The Sonarr calendar returns Episodes, but we need to ensure that the Series data is included if available
    return (response as List)
        .map((e) => Episode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves the current activity queue.
  Future<QueueItems> getQueue({
    int page = 1,
    int pageSize = 20,
    String sortKey = 'timeleft',
    String sortDirection = 'ascending',
  }) async {
    final response = await _client.get(
      '/queue',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'sortKey': sortKey,
        'sortDirection': sortDirection,
        'includeUnknownSeriesItems': true,
      },
    );
    return QueueItems.fromJson(response as Map<String, dynamic>);
  }

  /// Retrieves history events.
  ///
  /// [includeSeries] and [includeEpisode] ask Sonarr to embed the related
  /// series/episode in each record, so callers can resolve the media without a
  /// second request.
  Future<HistoryPage> getHistory({
    int page = 1,
    int pageSize = 25,
    HistoryEventType? eventType,
    int? episodeId,
    bool includeSeries = false,
    bool includeEpisode = false,
  }) async {
    final response = await _client.get(
      '/history',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (eventType != null && eventType.toSonarrEventTypes() != null)
          'eventType': eventType.toSonarrEventTypes(),
        'episodeId': ?episodeId,
        if (includeSeries) 'includeSeries': true,
        if (includeEpisode) 'includeEpisode': true,
      },
    );
    return HistoryPage.fromJson(
      response as Map<String, dynamic>,
      instanceId: instance.id,
    );
  }

  /// Deletes an item from the queue.
  ///
  /// [removeFromClient] - If true, removes it from the download client.
  /// [blocklist] - If true, adds the release to the blocklist.
  /// [skipRedownload] - If true, does not re-download the release.
  Future<void> deleteQueueItem(
    int id, {
    bool removeFromClient = true,
    bool blocklist = false,
    bool skipRedownload = false,
  }) async {
    await _client.delete(
      '/queue/$id',
      queryParameters: {
        'removeFromClient': removeFromClient,
        'blocklist': blocklist,
        'skipRedownload': skipRedownload,
      },
    );
  }

  /// Retrieves application logs.
  Future<LogPage> getLogs({int page = 1, int pageSize = 50}) async {
    final response = await _client.get(
      '/log',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return LogPage.fromJson(response as Map<String, dynamic>);
  }

  /// Retrieves health checks.
  Future<List<HealthCheck>> getHealth() async {
    final response = await _client.get('/health');
    return (response as List)
        .map((e) => HealthCheck.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves the configured download clients.
  Future<List<DownloadClientInfo>> getDownloadClients() async {
    final response = await _client.get('/downloadclient');
    return (response as List)
        .map((e) => DownloadClientInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves files for a specific series.
  Future<List<MediaFile>> getSeriesFiles(int seriesId) async {
    final response = await _client.get(
      '/episodefile',
      queryParameters: {'seriesId': seriesId},
    );
    return (response as List)
        .map((e) => MediaFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves extra files (e.g. subtitles, nfo) for a specific series.
  Future<List<SeriesExtraFile>> getSeriesExtraFiles(int seriesId) async {
    final response = await _client.get(
      '/extrafile',
      queryParameters: {'seriesId': seriesId},
    );
    return (response as List)
        .map((e) => SeriesExtraFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves history for a specific series.
  Future<List<HistoryEvent>> getSeriesHistory(int seriesId) async {
    final response = await _client.get(
      '/history/series',
      queryParameters: {'seriesId': seriesId},
    );
    return (response as List)
        .map((e) => HistoryEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Deletes an episode file.
  Future<void> deleteSeriesFile(int fileId) async {
    await _client.delete('/episodefile/$fileId');
  }

  /// Deletes episode files in a single Sonarr operation.
  Future<void> deleteSeriesFiles(List<int> fileIds) async {
    if (fileIds.isEmpty) {
      return;
    }
    await _client.delete(
      '/episodefile/bulk',
      data: {'episodeFileIds': fileIds},
    );
  }

  /// Updates the monitored state of the selected episodes.
  Future<void> monitorEpisodes(List<int> episodeIds, bool monitored) async {
    if (episodeIds.isEmpty) {
      return;
    }
    await _client.put(
      '/episode/monitor',
      data: {'episodeIds': episodeIds, 'monitored': monitored},
    );
  }

  /// Retrieves a specific episode file by its [id].
  Future<MediaFile> getEpisodeFile(int id) async {
    final response = await _client.get('/episodefile/$id');
    return MediaFile.fromJson(response as Map<String, dynamic>);
  }

  /// Retrieves files available for manual import.
  Future<List<ImportableFile>> getImportableFiles(String downloadId) async {
    final response = await _client.get(
      '/manualimport',
      queryParameters: {'downloadId': downloadId, 'filterExistingFiles': false},
    );
    return (response as List)
        .map((e) => ImportableFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves files available for manual import from a folder path.
  Future<List<ImportableFile>> getImportableFilesByFolder(
    String folderPath,
  ) async {
    final response = await _client.get(
      '/manualimport',
      queryParameters: {'folder': folderPath, 'filterExistingFiles': false},
    );
    return (response as List)
        .map((e) => ImportableFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Manually imports the selected [files].
  ///
  /// The `ManualImport` command reads a file shape of its own instead of the
  /// resource `/manualimport` returned: series and episodes come from flat
  /// `seriesId` and `episodeIds` fields, and the nested objects are ignored.
  /// Posting the resource as it arrived left both at their defaults, so the
  /// command had no media to import against.
  ///
  /// [copyFiles] forbids moving the source out of the download folder. Left to
  /// `auto`, the server only copies when it recognises a download that cannot
  /// be moved and moves the file otherwise, pulling the data out from under a
  /// torrent that is still seeding.
  Future<void> manualImport(
    List<ImportableFile> files, {
    bool copyFiles = false,
  }) async {
    final entries = <Map<String, dynamic>>[];
    final unlinked = <String>[];

    for (final file in files) {
      final seriesId = file.series?.guid;
      final episodeIds =
          file.episodes?.map((e) => e.id).toList() ?? const <int>[];
      if (seriesId == null || episodeIds.isEmpty) {
        unlinked.add(file.displayName);
        continue;
      }
      entries.add(_toImportCommandFile(file, seriesId, episodeIds));
    }

    if (unlinked.isNotEmpty) {
      throw MissingDataError('No episode is linked to ${unlinked.join(', ')}');
    }

    await _client.post(
      '/command',
      data: {
        'name': 'ManualImport',
        'files': entries,
        'importMode': copyFiles ? 'copy' : 'auto',
      },
      customTimeout: instance.timeout(InstanceTimeout.slow),
    );
  }

  /// Maps [file] onto the entry the `ManualImport` command expects, importing
  /// it into [episodeIds] of the series [seriesId].
  ///
  /// Only the fields the command declares are sent; everything else the
  /// resource carries is dropped rather than ignored server-side.
  Map<String, dynamic> _toImportCommandFile(
    ImportableFile file,
    int seriesId,
    List<int> episodeIds,
  ) {
    return {
      if (file.path != null) 'path': file.path,
      if (file.folderName != null) 'folderName': file.folderName,
      'seriesId': seriesId,
      'episodeIds': episodeIds,
      if (file.episodeFileId != null) 'episodeFileId': file.episodeFileId,
      if (file.quality != null) 'quality': file.quality!.toJson(),
      if (file.languages != null)
        'languages': file.languages!.map((e) => e.toJson()).toList(),
      if (file.releaseGroup != null) 'releaseGroup': file.releaseGroup,
      if (file.indexerFlags != null) 'indexerFlags': file.indexerFlags,
      if (file.releaseType != null) 'releaseType': file.releaseType,
      if (file.downloadId != null) 'downloadId': file.downloadId,
    };
  }

  /// Retrieves the system status.
  Future<InstanceStatus> getSystemStatus() async {
    final response = await _client.get('/system/status');
    return InstanceStatus.fromJson(response as Map<String, dynamic>);
  }

  /// Retrieves the storage locations available to Sonarr.
  Future<List<InstanceDiskSpace>> getDiskSpace() async {
    final response = await _client.get('/diskspace');
    return (response as List)
        .map((item) => InstanceDiskSpace.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves available tags.
  Future<List<Tag>> getTags() async {
    final response = await _client.get('/tag');
    return (response as List)
        .map((e) => Tag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves notification schemas.
  Future<List<NotificationResource>> getNotificationSchemas() async {
    final response = await _client.get('/notification/schema');
    return (response as List)
        .map((e) => NotificationResource.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves all notification settings.
  Future<List<NotificationResource>> getNotifications() async {
    final response = await _client.get('/notification');
    return (response as List)
        .map((e) => NotificationResource.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new notification setting.
  Future<NotificationResource> createNotification(
    NotificationResource notification,
  ) async {
    final response = await _client.post(
      '/notification',
      data: notification.toJson(),
    );
    return NotificationResource.fromJson(response as Map<String, dynamic>);
  }

  /// Updates an existing notification setting.
  Future<NotificationResource> updateNotification(
    NotificationResource notification,
  ) async {
    final response = await _client.put(
      '/notification/${notification.id}',
      data: notification.toJson(),
    );
    return NotificationResource.fromJson(response as Map<String, dynamic>);
  }

  Future<dynamic> sendCommand(
    String name, {
    Map<String, dynamic>? params,
  }) async {
    final body = {'name': name, ...?params};
    final response = await _client.post(
      '/command',
      data: body,
      customTimeout: instance.timeout(InstanceTimeout.slow),
    );
    return response;
  }

  Future<void> rescanSeries(int seriesId) async {
    await sendCommand('RescanSeries', params: {'seriesId': seriesId});
  }

  Future<void> refreshSeries(int seriesId) async {
    await sendCommand('RefreshSeries', params: {'seriesId': seriesId});
  }

  /// Commands Sonarr to run a system health check.
  Future<void> healthCheck() async {
    await sendCommand('HealthCheck');
  }
}
