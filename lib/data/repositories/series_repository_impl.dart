import '../../domain/repositories/series_repository.dart';
import '../api/sonarr_api.dart';
import '../models/models.dart';

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
  Future<void> deleteSeries(int id, {bool deleteFiles = false, bool addExclusion = false}) =>
      _api.deleteSeries(id, deleteFiles: deleteFiles, addExclusion: addExclusion);

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
  }) =>
      _api.getQueue(
        page: page,
        pageSize: pageSize,
        sortKey: sortKey,
        sortDirection: sortDirection,
      );
}
