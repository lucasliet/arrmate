import '../../domain/repositories/movie_repository.dart';
import '../api/radarr_api.dart';
import 'package:arrmate/domain/models/models.dart';

class MovieRepositoryImpl implements MovieRepository {
  final RadarrApi _api;

  MovieRepositoryImpl(this._api);

  @override
  Future<List<Movie>> getMovies() => _api.getMovies();

  @override
  Future<Movie> getMovie(int id) => _api.getMovie(id);

  @override
  Future<Movie> addMovie(Movie movie) => _api.addMovie(movie);

  @override
  Future<Movie> updateMovie(Movie movie, {bool moveFiles = false}) =>
      _api.updateMovie(movie, moveFiles: moveFiles);

  @override
  Future<List<RootFolder>> getRootFolders() => _api.getRootFolders();

  @override
  Future<void> deleteMovie(
    int id, {
    bool deleteFiles = false,
    bool addExclusion = false,
  }) => _api.deleteMovie(
    id,
    deleteFiles: deleteFiles,
    addExclusion: addExclusion,
  );

  @override
  Future<List<Movie>> lookupMovie(String term) => _api.lookupMovie(term);

  @override
  Future<List<Movie>> getCalendar({DateTime? start, DateTime? end}) =>
      _api.getCalendar(start: start, end: end);

  @override
  Future<QueueItems> getQueue({
    int page = 1,
    int pageSize = 20,
    String sortKey = 'timeleft',
    String sortDirection = 'ascending',
  }) => _api.getQueue(
    page: page,
    pageSize: pageSize,
    sortKey: sortKey,
    sortDirection: sortDirection,
  );

  @override
  Future<HistoryPage> getHistory({
    int page = 1,
    int pageSize = 25,
    HistoryEventType? eventType,
  }) => _api.getHistory(page: page, pageSize: pageSize, eventType: eventType);

  @override
  Future<void> deleteQueueItem(
    int id, {
    bool removeFromClient = true,
    bool blocklist = false,
    bool skipRedownload = false,
  }) => _api.deleteQueueItem(
    id,
    removeFromClient: removeFromClient,
    blocklist: blocklist,
    skipRedownload: skipRedownload,
  );

  @override
  Future<LogPage> getLogs({int page = 1, int pageSize = 50}) {
    return _api.getLogs(page: page, pageSize: pageSize);
  }

  @override
  Future<List<HealthCheck>> getHealth() {
    return _api.getHealth();
  }

  @override
  Future<List<QualityProfile>> getQualityProfiles() {
    return _api.getQualityProfiles();
  }
}
