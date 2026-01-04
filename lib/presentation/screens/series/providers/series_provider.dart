import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/models.dart';
import '../../../providers/data_providers.dart';

// Series List Provider
final seriesProvider = AsyncNotifierProvider<SeriesNotifier, List<Series>>(
  SeriesNotifier.new,
);

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

// Single Series Details Provider
final seriesDetailsProvider = FutureProvider.autoDispose.family<Series, int>((ref, seriesId) async {
  final repository = ref.watch(seriesRepositoryProvider);
  if (repository == null) {
    throw Exception('Repository not available');
  }
  return repository.getSeriesById(seriesId);
});

// Helper for Series Actions
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

  Future<void> deleteSeries({bool deleteFiles = false, bool addExclusion = false}) async {
    final repository = ref.read(seriesRepositoryProvider);
    if (repository == null) return;
    await repository.deleteSeries(seriesId, deleteFiles: deleteFiles, addExclusion: addExclusion);
  }
  
  Future<void> refresh() async {
    ref.invalidate(seriesDetailsProvider(seriesId));
  }
}

final seriesControllerProvider = Provider.autoDispose.family<SeriesController, int>((ref, seriesId) {
  return SeriesController(ref, seriesId);
});
