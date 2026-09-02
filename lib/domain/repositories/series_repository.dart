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

  /// Persists the monitoring flags of [series], seasons included.
  ///
  /// Season monitoring needs its own call: the bulk editor behind
  /// [updateSeries] accepts only series-level fields.
  Future<Series> updateSeriesMonitoring(Series series);

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

  /// Triggers an automatic search for every monitored episode of a season.
  Future<void> searchSeason(int seriesId, int seasonNumber);

  /// Retrieves episodes for a specific [seriesId].
  Future<List<Episode>> getEpisodes(int seriesId);

  /// Retrieves a specific episode by its [id].
  Future<Episode> getEpisode(int id);

  /// Retrieves upcoming episodes from the calendar, including unmonitored
  /// episodes by default.
  Future<List<Episode>> getCalendar({
    DateTime? start,
    DateTime? end,
    bool unmonitored = true,
  });

  /// Retrieves the current activity queue.
  Future<QueueItems> getQueue({
    int page = 1,
    int pageSize = 20,
    String sortKey = 'timeleft',
    String sortDirection = 'ascending',
  });

  /// Retrieves history events.
  ///
  /// [includeSeries] and [includeEpisode] embed the related series/episode in
  /// each record.
  Future<HistoryPage> getHistory({
    int page = 1,
    int pageSize = 25,
    HistoryEventType? eventType,
    bool includeSeries = false,
    bool includeEpisode = false,
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

  /// Retrieves the configured download clients.
  Future<List<DownloadClientInfo>> getDownloadClients();

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

  /// Updates the monitored state of [episodeIds].
  Future<void> monitorEpisodes(List<int> episodeIds, bool monitored);

  /// Deletes every episode file belonging to [seriesId].
  ///
  /// When [seasonNumber] is provided, only files of that season are removed;
  /// otherwise all files of the series are removed. The series itself stays
  /// in Sonarr.
  ///
  /// Returns the number of files that were deleted.
  Future<int> deleteSeriesFiles(int seriesId, {int? seasonNumber});

  /// Retrieves files available for manual import.
  Future<List<ImportableFile>> getImportableFiles(String downloadId);

  /// Retrieves files available for manual import from a folder path.
  Future<List<ImportableFile>> getImportableFilesByFolder(String folderPath);

  /// Manually imports the selected [files].
  Future<void> manualImport(List<ImportableFile> files);

  /// Rescans the series folder and updates the library.
  Future<void> rescanSeries(int seriesId);

  /// Refreshes series metadata and scans for new files.
  Future<void> refreshSeries(int seriesId);

  /// Triggers a system health check.
  Future<void> healthCheck();
}
