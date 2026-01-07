import 'dart:async';
import 'package:arrmate/presentation/providers/settings_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';

/// Provider that holds the list of series fetched from Sonarr.
final seriesProvider = AsyncNotifierProvider<SeriesNotifier, List<Series>>(
  SeriesNotifier.new,
);

final seriesSearchProvider = NotifierProvider<SeriesSearchNotifier, String>(
  SeriesSearchNotifier.new,
);

class SeriesSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final seriesSortProvider = NotifierProvider<SeriesSortNotifier, SeriesSort>(
  SeriesSortNotifier.new,
);

class SeriesSortNotifier extends Notifier<SeriesSort> {
  @override
  SeriesSort build() {
    return ref.watch(settingsProvider.select((s) => s.seriesSort));
  }

  void update(SeriesSort value) {
    ref.read(settingsProvider.notifier).setSeriesSort(value);
  }
}

/// Provider that returns the list of series filtered by search query and sorted by options.
final filteredSeriesProvider = Provider<AsyncValue<List<Series>>>((ref) {
  final seriesState = ref.watch(seriesProvider);
  final searchQuery = ref.watch(seriesSearchProvider).toLowerCase();
  final sort = ref.watch(seriesSortProvider);

  return seriesState.whenData((series) {
    var filtered = List<Series>.from(series);

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((s) {
        final titleMatch = s.title.toLowerCase().contains(searchQuery);
        final sortTitleMatch = s.sortTitle.toLowerCase().contains(searchQuery);
        return titleMatch || sortTitleMatch;
      }).toList();
    }

    filtered = filtered.where((s) => sort.filter.filter(s)).toList();

    filtered.sort((a, b) {
      final comparison = sort.option.compare(a, b);
      return sort.isAscending ? comparison : -comparison;
    });

    return filtered;
  });
});

/// Notifier to manage fetching and refreshing the series list.
class SeriesNotifier extends AsyncNotifier<List<Series>> {
  @override
  FutureOr<List<Series>> build() async {
    final repository = ref.watch(seriesRepositoryProvider);
    if (repository == null) {
      return [];
    }

    final series = await repository.getSeries();
    // Sort by sortTitle
    series.sort((a, b) => a.sortTitle.compareTo(b.sortTitle));

    return series;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Provider for fetching the details of a specific series using its ID.
final seriesDetailsProvider = FutureProvider.autoDispose.family<Series, int>((
  ref,
  seriesId,
) async {
  final repository = ref.watch(seriesRepositoryProvider);
  if (repository == null) {
    throw Exception('Repository not available');
  }
  return repository.getSeriesById(seriesId);
});

/// Controller for managing series actions (monitor, delete, update).
class SeriesController {
  final Ref ref;
  final int seriesId;

  SeriesController(this.ref, this.seriesId);

  Future<void> toggleMonitor(Series series) async {
    final repository = ref.read(seriesRepositoryProvider);
    if (repository == null) return;

    final updatedSeries = series.copyWith(monitored: !series.monitored);

    await repository.updateSeries(updatedSeries);
    ref.invalidate(seriesDetailsProvider(seriesId));
  }

  Future<void> updateSeries(Series series, {bool moveFiles = false}) async {
    final repository = ref.read(seriesRepositoryProvider);
    if (repository == null) return;
    await repository.updateSeries(series, moveFiles: moveFiles);
    ref.invalidate(seriesDetailsProvider(seriesId));
  }

  Future<void> deleteSeries({
    bool deleteFiles = false,
    bool addExclusion = false,
  }) async {
    final repository = ref.read(seriesRepositoryProvider);
    if (repository == null) return;
    await repository.deleteSeries(
      seriesId,
      deleteFiles: deleteFiles,
      addExclusion: addExclusion,
    );
    ref.invalidate(seriesProvider);
  }

  Future<void> refresh() async {
    ref.invalidate(seriesDetailsProvider(seriesId));
  }

  Future<void> automaticSearch() async {
    final repository = ref.read(seriesRepositoryProvider);
    if (repository == null) return;
    await repository.searchSeries(seriesId);
  }

  /// Toggles the monitoring status for a specific season of the series.
  ///
  /// This updates the season's `monitored` field and pushes the entire series
  /// to the Sonarr API, following the same pattern as the reference iOS app.
  Future<void> toggleSeasonMonitor(Series series, int seasonNumber) async {
    final repository = ref.read(seriesRepositoryProvider);
    if (repository == null) return;

    final updatedSeasons = series.seasons.map((season) {
      if (season.seasonNumber == seasonNumber) {
        return season.copyWith(monitored: !season.monitored);
      }
      return season;
    }).toList();

    final updatedSeries = series.copyWith(seasons: updatedSeasons);
    await repository.updateSeries(updatedSeries);
    ref.invalidate(seriesDetailsProvider(seriesId));
  }

  /// Sets the monitoring status for all seasons of the series.
  ///
  /// When [monitored] is true, all seasons will be monitored.
  /// When [monitored] is false, all seasons will be unmonitored.
  Future<void> monitorAllSeasons(Series series, bool monitored) async {
    final repository = ref.read(seriesRepositoryProvider);
    if (repository == null) return;

    final updatedSeasons = series.seasons.map((season) {
      return season.copyWith(monitored: monitored);
    }).toList();

    final updatedSeries = series.copyWith(seasons: updatedSeasons);
    await repository.updateSeries(updatedSeries);
    ref.invalidate(seriesDetailsProvider(seriesId));
  }
}

final seriesControllerProvider = Provider.autoDispose
    .family<SeriesController, int>((ref, seriesId) {
      return SeriesController(ref, seriesId);
    });
