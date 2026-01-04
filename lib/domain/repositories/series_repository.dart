import '../../data/models/models.dart';

abstract class SeriesRepository {
  Future<List<Series>> getSeries();
  Future<Series> getSeriesById(int id);
  Future<Series> addSeries(Series series);
  Future<Series> updateSeries(Series series);
  Future<void> deleteSeries(int id, {bool deleteFiles = false, bool addExclusion = false});
  Future<List<Series>> lookupSeries(String term);
  Future<List<Episode>> getEpisodes(int seriesId);
  Future<Episode> getEpisode(int id);
  Future<List<Episode>> getCalendar({DateTime? start, DateTime? end});
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
}
