import '../../domain/repositories/series_repository.dart';
import '../api/sonarr_api.dart';
import 'package:arrmate/domain/models/models.dart';

class SeriesRepositoryImpl implements SeriesRepository {
  final SonarrApi _api;

  SeriesRepositoryImpl(this._api);

  @override
  Future<List<Series>> getSeries() => _api.getSeries();

  @override
  Future<Series> getSeriesById(int id) => _api.getSeriesById(id);

  @override
  Future<Series> addSeries(Series series) => _api.addSeries(series);

  @override
  Future<Series> updateSeries(Series series) => _api.updateSeries(series);

  @override
  Future<void> deleteSeries(
    int id, {
    bool deleteFiles = false,
    bool addExclusion = false,
  }) => _api.deleteSeries(
    id,
    deleteFiles: deleteFiles,
    addExclusion: addExclusion,
  );

  @override
  Future<List<Series>> lookupSeries(String term) => _api.lookupSeries(term);

  @override
  Future<List<Episode>> getEpisodes(int seriesId) => _api.getEpisodes(seriesId);

  @override
  Future<Episode> getEpisode(int id) => _api.getEpisode(id);

  @override
  Future<List<Episode>> getCalendar({DateTime? start, DateTime? end}) =>
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
