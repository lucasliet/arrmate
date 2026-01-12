import '../../domain/models/models.dart';

/// Repository interface for movie-related operations.
abstract class MovieRepository {
  /// Retrieves all movies.
  Future<List<Movie>> getMovies();

  /// Retrieves a specific movie by its [id].
  Future<Movie> getMovie(int id);

  /// Adds a new movie.
  Future<Movie> addMovie(Movie movie);

  /// Updates an existing movie.
  Future<Movie> updateMovie(Movie movie, {bool moveFiles = false});

  /// Deletes a movie.
  Future<void> deleteMovie(
    int id, {
    bool deleteFiles = false,
    bool addExclusion = false,
  });

  /// Searches for movies by [term].
  Future<List<Movie>> lookupMovie(String term);

  /// Retrieves upcoming movies from the calendar.
  Future<List<Movie>> getCalendar({DateTime? start, DateTime? end});

  /// Retrieves the current activity queue.
  Future<QueueItems> getQueue({
    int page = 1,
    int pageSize = 20,
    String sortKey = 'timeleft',
    String sortDirection = 'ascending',
  });

  /// Retrieves history events.
  Future<HistoryPage> getHistory({
    int page = 1,
    int pageSize = 25,
    HistoryEventType? eventType,
  });

  /// Deletes an item from the queue.
  Future<void> deleteQueueItem(
    int id, {
    bool removeFromClient = true,
    bool blocklist = false,
    bool skipRedownload = false,
  });

  /// Retrieves application logs.
  Future<LogPage> getLogs({int page = 1, int pageSize = 50});

  /// Retrieves health checks.
  Future<List<HealthCheck>> getHealth();

  /// Retrieves available quality profiles.
  Future<List<QualityProfile>> getQualityProfiles();

  /// Retrieves configured root folders.
  Future<List<RootFolder>> getRootFolders();

  /// Triggers a search for the specified movies.
  Future<void> searchMovies(List<int> movieIds);

  /// Retrieves files for a specific movie.
  Future<List<MediaFile>> getMovieFiles(int movieId);

  /// Retrieves extra files for a specific movie.
  Future<List<MovieExtraFile>> getMovieExtraFiles(int movieId);

  /// Retrieves history for a specific movie.
  Future<List<HistoryEvent>> getMovieHistory(int movieId);

  /// Deletes a movie file.
  Future<void> deleteMovieFile(int fileId);

  /// Retrieves files available for manual import.
  Future<List<ImportableFile>> getImportableFiles(String downloadId);

  /// Manually imports the selected [files].
  Future<void> manualImport(List<ImportableFile> files);

  /// Rescans the movie folder and updates the library.
  Future<void> rescanMovie(int movieId);

  /// Refreshes movie metadata and scans for new files.
  Future<void> refreshMovie(int movieId);

  /// Triggers a system health check.
  Future<void> healthCheck();
}
