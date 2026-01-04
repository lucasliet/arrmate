import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import 'package:arrmate/domain/models/models.dart';

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

  Future<List<Movie>> getMovies() async {
    final response = await _client.get('/movie');
    return (response as List)
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Movie> getMovie(int id) async {
    final response = await _client.get('/movie/$id');
    return Movie.fromJson(response as Map<String, dynamic>);
  }

  Future<Movie> addMovie(Movie movie) async {
    final response = await _client.post('/movie', data: movie.toJson());
    return Movie.fromJson(response as Map<String, dynamic>);
  }

  Future<Movie> updateMovie(Movie movie) async {
    final response = await _client.put(
      '/movie/${movie.id}',
      data: movie.toJson(),
    );
    return Movie.fromJson(response as Map<String, dynamic>);
  }

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

  Future<List<QualityProfile>> getQualityProfiles() async {
    final response = await _client.get('/qualityprofile');
    return (response as List)
        .map((e) => QualityProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RootFolder>> getRootFolders() async {
    final response = await _client.get('/rootfolder');
    return (response as List)
        .map((e) => RootFolder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Release>> getMovieReleases(int movieId) async {
    final response = await _client.get(
      '/release',
      queryParameters: {'movieId': movieId},
    );
    return (response as List)
        .map((e) => Release.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> downloadRelease(String guid, String indexerId) async {
    await _client.post(
      '/release',
      data: {'guid': guid, 'indexerId': indexerId},
    );
  }

  Future<List<Movie>> lookupMovie(String term) async {
    final response = await _client.get(
      '/movie/lookup',
      queryParameters: {'term': term},
    );
    return (response as List)
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Movie>> getCalendar({DateTime? start, DateTime? end}) async {
    final response = await _client.get(
      '/calendar',
      queryParameters: {
        if (start != null) 'start': start.toIso8601String(),
        if (end != null) 'end': end.toIso8601String(),
      },
    );
    return (response as List)
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

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

  Future<dynamic> getCommand(String id) async {
    final response = await _client.get('/command/$id');
    return response;
  }

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

  Future<LogPage> getLogs({int page = 1, int pageSize = 50}) async {
    final response = await _client.get(
      '/log',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return LogPage.fromJson(response as Map<String, dynamic>);
  }

  Future<List<HealthCheck>> getHealth() async {
    final response = await _client.get('/health');
    return (response as List)
        .map((e) => HealthCheck.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
