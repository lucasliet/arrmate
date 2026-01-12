import '../../domain/models/models.dart';

/// Repository interface for series-related operations.
abstract class SeriesRepository {
  /// Retrieves all series.
  Future<List<Series>> getSeries();

  /// Retrieves a specific series by its [id].
  Future<Series> getSeriesById(int id);

  /// Adds a new series.
  Future<Series> addSeries(Series series);

  /// Updates an existing series.
  Future<Series> updateSeries(Series series, {bool moveFiles = false});

  /// Deletes a series.
  Future<void> deleteSeries(
    int id, {
    bool deleteFiles = false,
    bool addExclusion = false,
  });

  /// Searches for series by [term].
  Future<List<Series>> lookupSeries(String term);

  /// Triggers an automatic search for a specific series.
  Future<void> searchSeries(int seriesId);

  /// Triggers an automatic search for a specific episode.
  Future<void> searchEpisode(int episodeId);

  /// Retrieves episodes for a specific [seriesId].
  Future<List<Episode>> getEpisodes(int seriesId);

  /// Retrieves a specific episode by its [id].
  Future<Episode> getEpisode(int id);

  /// Retrieves upcoming episodes from the calendar.
  Future<List<Episode>> getCalendar({DateTime? start, DateTime? end});

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

  /// Retrieves files for a specific series.
  Future<List<MediaFile>> getSeriesFiles(int seriesId);

  /// Retrieves extra files for a specific series.
  Future<List<SeriesExtraFile>> getSeriesExtraFiles(int seriesId);

  /// Retrieves history for a specific series.
  Future<List<HistoryEvent>> getSeriesHistory(int seriesId);

  /// Deletes an episode file.
  Future<void> deleteSeriesFile(int fileId);

  /// Retrieves files available for manual import.
  Future<List<ImportableFile>> getImportableFiles(String downloadId);

  /// Manually imports the selected [files].
  Future<void> manualImport(List<ImportableFile> files);

  /// Rescans the series folder and updates the library.
  Future<void> rescanSeries(int seriesId);

  /// Refreshes series metadata and scans for new files.
  Future<void> refreshSeries(int seriesId);
}
