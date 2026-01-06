import '../../core/network/api_client.dart';
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
            baseUrl: '${instance.url}${ApiConstants.apiPath}',
            headers: instance.authHeaders,
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
    final response = await _client.put(
      '/series/${series.id}',
      data: series.toJson(),
      queryParameters: {'moveFiles': moveFiles},
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
        'addExclusion': addExclusion,
      },
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

  /// Searches for releases for a specific episode or series.
  Future<List<Release>> getSeriesReleases({int? episodeId}) async {
    final response = await _client.get(
      '/release',
      queryParameters: {if (episodeId != null) 'episodeId': episodeId},
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
  Future<List<Episode>> getCalendar({DateTime? start, DateTime? end}) async {
    final response = await _client.get(
      '/calendar',
      queryParameters: {
        if (start != null) 'start': start.toIso8601String(),
        if (end != null) 'end': end.toIso8601String(),
        'includeSeries': true,
        'includeEpisodeFile': true,
      },
      customTimeout: instance.timeout(InstanceTimeout.slow),
    );

    // O calendário do Sonarr retorna Episódios, mas precisamos garantir que venha os dados da Série junto se disponível
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
  Future<HistoryPage> getHistory({
    int page = 1,
    int pageSize = 25,
    HistoryEventType? eventType,
  }) async {
    final response = await _client.get(
      '/history',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (eventType != null && eventType.toSonarrEventType() != null)
          'eventType': eventType.toSonarrEventType(),
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

  /// Manually imports the selected [files].
  Future<void> manualImport(List<ImportableFile> files) async {
    await _client.post(
      '/command',
      data: {
        'name': 'ManualImport',
        'files': files.map((f) => f.toJson()).toList(),
        'importMode': 'auto',
      },
      customTimeout: instance.timeout(InstanceTimeout.slow),
    );
  }

  /// Retrieves the system status.
  Future<InstanceStatus> getSystemStatus() async {
    final response = await _client.get('/system/status');
    return InstanceStatus.fromJson(response as Map<String, dynamic>);
  }

  /// Retrieves available tags.
  Future<List<Tag>> getTags() async {
    final response = await _client.get('/tag');
    return (response as List)
        .map((e) => Tag.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
