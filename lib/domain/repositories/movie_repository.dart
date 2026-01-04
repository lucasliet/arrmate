import '../../data/models/models.dart';

abstract class MovieRepository {
  Future<List<Movie>> getMovies();
  Future<Movie> getMovie(int id);
  Future<Movie> addMovie(Movie movie);
  Future<Movie> updateMovie(Movie movie);
  Future<void> deleteMovie(int id, {bool deleteFiles = false, bool addExclusion = false});
  Future<List<Movie>> lookupMovie(String term);
  Future<List<Movie>> getCalendar({DateTime? start, DateTime? end});
  Future<QueueItems> getQueue({
    int page = 1,
    int pageSize = 20,
    String sortKey = 'timeleft',
    String sortDirection = 'ascending',
  });
}
