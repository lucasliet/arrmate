import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/models.dart';

class RadarrApi {
  final ApiClient _client;
  final Instance instance;

  RadarrApi(this.instance, [ApiClient? client])
      : _client = client ?? ApiClient(
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
    final response = await _client.put('/movie/${movie.id}', data: movie.toJson());
    return Movie.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteMovie(int id, {bool deleteFiles = false, bool addExclusion = false}) async {
    await _client.delete(
      '/movie/$id',
      queryParameters: {
        'deleteFiles': deleteFiles,
        'addExclusion': addExclusion,
      },
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
}
