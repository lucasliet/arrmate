import '../../domain/models/models.dart';

abstract class MovieRepository {
  Future<List<Movie>> getMovies();
  Future<Movie> getMovie(int id);
  Future<Movie> addMovie(Movie movie);
  Future<Movie> updateMovie(Movie movie, {bool moveFiles = false});
  Future<void> deleteMovie(
    int id, {
    bool deleteFiles = false,
    bool addExclusion = false,
  });
  Future<List<Movie>> lookupMovie(String term);
  Future<List<Movie>> getCalendar({DateTime? start, DateTime? end});
  Future<QueueItems> getQueue({
    int page = 1,
    int pageSize = 20,
    String sortKey = 'timeleft',
    String sortDirection = 'ascending',
  });
  Future<HistoryPage> getHistory({
    int page = 1,
    int pageSize = 25,
    HistoryEventType? eventType,
  });
  Future<void> deleteQueueItem(
    int id, {
    bool removeFromClient = true,
    bool blocklist = false,
    bool skipRedownload = false,
  });

  Future<LogPage> getLogs({int page = 1, int pageSize = 50});

  Future<List<HealthCheck>> getHealth();

  Future<List<QualityProfile>> getQualityProfiles();

  Future<List<RootFolder>> getRootFolders();
}
