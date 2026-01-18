import '../../core/services/logger_service.dart';
import '../../domain/repositories/movie_repository.dart';
import '../api/radarr_api.dart';
import 'package:arrmate/domain/models/models.dart';

/// Implementation of [MovieRepository] using [RadarrApi].
class MovieRepositoryImpl implements MovieRepository {
  final RadarrApi _api;

  MovieRepositoryImpl(this._api);

  @override
  Future<List<Movie>> getMovies() async {
    logger.debug('[MovieRepository] Fetching all movies');
    return _api.getMovies();
  }

  @override
  Future<Movie> getMovie(int id) => _api.getMovie(id);

  @override
  Future<Movie> addMovie(Movie movie) async {
    logger.info('[MovieRepository] Adding movie: ${movie.title}');
    return _api.addMovie(movie);
  }

  @override
  Future<Movie> updateMovie(Movie movie, {bool moveFiles = false}) async {
    logger.info(
      '[MovieRepository] Updating movie: ${movie.title} (id: ${movie.id})',
    );
    return _api.updateMovie(movie, moveFiles: moveFiles);
  }

  @override
  Future<List<RootFolder>> getRootFolders() => _api.getRootFolders();

  @override
  Future<void> deleteMovie(
    int id, {
    bool deleteFiles = false,
    bool addExclusion = false,
  }) async {
    logger.info(
      '[MovieRepository] Deleting movie: $id (files: $deleteFiles, exclude: $addExclusion)',
    );
    return _api.deleteMovie(
      id,
      deleteFiles: deleteFiles,
      addExclusion: addExclusion,
    );
  }

  @override
  Future<List<Movie>> lookupMovie(String term) async {
    logger.debug('[MovieRepository] Looking up movie: $term');
    return _api.lookupMovie(term);
  }

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

  @override
  Future<void> searchMovies(List<int> movieIds) async {
    logger.info('[MovieRepository] Triggering search for movies: $movieIds');
    return _api.sendCommand('MoviesSearch', params: {'movieIds': movieIds});
  }

  @override
  Future<List<MediaFile>> getMovieFiles(int movieId) =>
      _api.getMovieFiles(movieId);

  @override
  Future<List<MovieExtraFile>> getMovieExtraFiles(int movieId) =>
      _api.getMovieExtraFiles(movieId);

  @override
  Future<List<HistoryEvent>> getMovieHistory(int movieId) =>
      _api.getMovieHistory(movieId);

  @override
  Future<void> deleteMovieFile(int fileId) => _api.deleteMovieFile(fileId);

  @override
  Future<List<ImportableFile>> getImportableFiles(String downloadId) =>
      _api.getImportableFiles(downloadId);

  @override
  Future<List<ImportableFile>> getImportableFilesByFolder(String folderPath) =>
      _api.getImportableFilesByFolder(folderPath);

  @override
  Future<void> manualImport(List<ImportableFile> files) =>
      _api.manualImport(files);

  @override
  Future<void> rescanMovie(int movieId) async {
    logger.info('[MovieRepository] Rescanning movie: $movieId');
    return _api.rescanMovie(movieId);
  }

  @override
  Future<void> refreshMovie(int movieId) async {
    logger.info('[MovieRepository] Refreshing movie: $movieId');
    return _api.refreshMovie(movieId);
  }

  @override
  Future<void> healthCheck() async {
    logger.info('[MovieRepository] Triggering health check');
    return _api.healthCheck();
  }
}
