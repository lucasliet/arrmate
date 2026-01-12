import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import 'package:arrmate/domain/models/models.dart';

/// API Client for interacting with Radarr.
class RadarrApi {
  final ApiClient _client;
  final Instance instance;

  RadarrApi(this.instance, [ApiClient? client])
    : _client =
          client ??
          ApiClient(
            baseUrl: '${instance.url}${ApiConstants.apiPath}',
            headers: instance.authHeaders,
          );

  /// Retrieves all movies from the Radarr library.
  Future<List<Movie>> getMovies() async {
    final response = await _client.get(
      '/movie',
      customTimeout: instance.timeout(InstanceTimeout.slow),
    );
    return (response as List)
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves a specific movie by its [id].
  Future<Movie> getMovie(int id) async {
    final response = await _client.get('/movie/$id');
    return Movie.fromJson(response as Map<String, dynamic>);
  }

  /// Adds a new movie to the library.
  Future<Movie> addMovie(Movie movie) async {
    final response = await _client.post('/movie', data: movie.toJson());
    return Movie.fromJson(response as Map<String, dynamic>);
  }

  /// Updates an existing movie.
  ///
  /// [moveFiles] - If true, moves files to the new path if the path has changed.
  Future<Movie> updateMovie(Movie movie, {bool moveFiles = false}) async {
    final response = await _client.put(
      '/movie/${movie.id}',
      data: movie.toJson(),
      queryParameters: {'moveFiles': moveFiles},
    );
    return Movie.fromJson(response as Map<String, dynamic>);
  }

  /// Deletes a movie from the library.
  ///
  /// [deleteFiles] - If true, also deletes the movie files from disk.
  /// [addExclusion] - If true, adds the movie to the exclusion list (prevents re-import).
  Future<void> deleteMovie(
    int id, {
    bool deleteFiles = false,
    bool addExclusion = false,
  }) async {
    await _client.delete(
      '/movie/$id',
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

  /// Searches for releases for a specific movie.
  Future<List<Release>> getMovieReleases(int movieId) async {
    final response = await _client.get(
      '/release',
      queryParameters: {'movieId': movieId},
      customTimeout: instance.timeout(InstanceTimeout.releaseSearch),
    );
    return (response as List)
        .map((e) => Release.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Commands Radarr to download a specific release.
  Future<void> downloadRelease(String guid, String indexerId) async {
    await _client.post(
      '/release',
      data: {'guid': guid, 'indexerId': indexerId},
      customTimeout: instance.timeout(InstanceTimeout.releaseDownload),
    );
  }

  /// Searches for movies by [term].
  Future<List<Movie>> lookupMovie(String term) async {
    final response = await _client.get(
      '/movie/lookup',
      queryParameters: {'term': term},
    );
    return (response as List)
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves upcoming movies from the calendar.
  ///
  /// [start] and [end] define the date range.
  Future<List<Movie>> getCalendar({DateTime? start, DateTime? end}) async {
    final response = await _client.get(
      '/calendar',
      queryParameters: {
        if (start != null) 'start': start.toIso8601String(),
        if (end != null) 'end': end.toIso8601String(),
      },
      customTimeout: instance.timeout(InstanceTimeout.slow),
    );
    return (response as List)
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
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
        'includeUnknownMovieItems': true,
      },
    );
    return QueueItems.fromJson(response as Map<String, dynamic>);
  }

  /// Retrieves the status of a specific command.
  Future<dynamic> getCommand(String id) async {
    final response = await _client.get('/command/$id');
    return response;
  }

  /// Sends a command to Radarr.
  ///
  /// [name] is the command name (e.g., 'RefreshMovie').
  /// [params] are optional parameters for the command.
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
        if (eventType != null && eventType.toRadarrEventType() != null)
          'eventType': eventType.toRadarrEventType(),
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

  /// Retrieves files for a specific movie.
  Future<List<MediaFile>> getMovieFiles(int movieId) async {
    final response = await _client.get(
      '/moviefile',
      queryParameters: {'movieId': movieId},
    );
    return (response as List)
        .map((e) => MediaFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves extra files (e.g. subtitles, nfo) for a specific movie.
  Future<List<MovieExtraFile>> getMovieExtraFiles(int movieId) async {
    final response = await _client.get(
      '/extrafile',
      queryParameters: {'movieId': movieId},
    );
    return (response as List)
        .map((e) => MovieExtraFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retrieves history for a specific movie.
  Future<List<HistoryEvent>> getMovieHistory(int movieId) async {
    final response = await _client.get(
      '/history/movie',
      queryParameters: {'movieId': movieId},
    );
    return (response as List)
        .map((e) => HistoryEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Deletes a movie file.
  Future<void> deleteMovieFile(int fileId) async {
    await _client.delete('/moviefile/$fileId');
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

  Future<void> rescanMovie(int movieId) async {
    await sendCommand('RescanMovie', params: {'movieId': movieId});
  }

  Future<void> refreshMovie(int movieId) async {
    await sendCommand('RefreshMovie', params: {'movieId': movieId});
  }

  /// Commands Radarr to run a system health check.
  Future<void> healthCheck() async {
    await sendCommand('HealthCheck');
  }
}
