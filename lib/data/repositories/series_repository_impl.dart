import '../../core/services/logger_service.dart';
import '../../domain/repositories/series_repository.dart';
import '../api/sonarr_api.dart';
import 'package:arrmate/domain/models/models.dart';

/// Implementation of [SeriesRepository] using [SonarrApi].
class SeriesRepositoryImpl implements SeriesRepository {
  final SonarrApi _api;

  SeriesRepositoryImpl(this._api);

  @override
  Future<List<Series>> getSeries() async {
    logger.debug('[SeriesRepository] Fetching all series');
    return _api.getSeries();
  }

  @override
  Future<Series> getSeriesById(int id) => _api.getSeriesById(id);

  @override
  Future<Series> addSeries(Series series) async {
    logger.info('[SeriesRepository] Adding series: ${series.title}');
    return _api.addSeries(series);
  }

  @override
  Future<Series> updateSeries(Series series, {bool moveFiles = false}) async {
    logger.info(
      '[SeriesRepository] Updating series: ${series.title} (id: ${series.id})',
    );
    return _api.updateSeries(series, moveFiles: moveFiles);
  }

  @override
  Future<void> deleteSeries(
    int id, {
    bool deleteFiles = false,
    bool addExclusion = false,
  }) async {
    logger.info(
      '[SeriesRepository] Deleting series: $id (files: $deleteFiles, exclude: $addExclusion)',
    );
    return _api.deleteSeries(
      id,
      deleteFiles: deleteFiles,
      addExclusion: addExclusion,
    );
  }

  @override
  Future<List<Series>> lookupSeries(String term) async {
    logger.debug('[SeriesRepository] Looking up series: $term');
    return _api.lookupSeries(term);
  }

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

  @override
  Future<List<RootFolder>> getRootFolders() {
    return _api.getRootFolders();
  }

  @override
  Future<List<MediaFile>> getSeriesFiles(int seriesId) =>
      _api.getSeriesFiles(seriesId);

  @override
  Future<List<SeriesExtraFile>> getSeriesExtraFiles(int seriesId) =>
      _api.getSeriesExtraFiles(seriesId);

  @override
  Future<List<HistoryEvent>> getSeriesHistory(int seriesId) =>
      _api.getSeriesHistory(seriesId);

  @override
  Future<void> deleteSeriesFile(int fileId) => _api.deleteSeriesFile(fileId);

  @override
  Future<List<ImportableFile>> getImportableFiles(String downloadId) =>
      _api.getImportableFiles(downloadId);

  @override
  Future<void> manualImport(List<ImportableFile> files) =>
      _api.manualImport(files);
}
