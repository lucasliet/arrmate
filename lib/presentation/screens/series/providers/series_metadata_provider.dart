import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';
import 'season_episodes_provider.dart';
import 'series_provider.dart';

/// Provider for fetching media files for a specific series.
final seriesFilesProvider = FutureProvider.autoDispose
    .family<List<MediaFile>, int>((ref, seriesId) async {
      final repository = ref.watch(seriesRepositoryProvider);
      if (repository == null) {
        throw Exception('Repository not available');
      }
      return repository.getSeriesFiles(seriesId);
    });

final seriesExtraFilesProvider = FutureProvider.autoDispose
    .family<List<SeriesExtraFile>, int>((ref, seriesId) async {
      final repository = ref.watch(seriesRepositoryProvider);
      if (repository == null) {
        throw Exception('Repository not available');
      }
      return repository.getSeriesExtraFiles(seriesId);
    });

/// Provider for fetching history events for a specific series.
final seriesHistoryProvider = FutureProvider.autoDispose
    .family<List<HistoryEvent>, int>((ref, seriesId) async {
      final repository = ref.watch(seriesRepositoryProvider);
      if (repository == null) {
        throw Exception('Repository not available');
      }
      return repository.getSeriesHistory(seriesId);
    });

final seriesMetadataControllerProvider = Provider.autoDispose
    .family<SeriesMetadataController, int>((ref, seriesId) {
      return SeriesMetadataController(ref, seriesId);
    });

/// Controller for managing metadata operations (e.g. deleting files) for a series.
class SeriesMetadataController {
  final Ref ref;
  final int seriesId;

  SeriesMetadataController(this.ref, this.seriesId);

  Future<void> deleteFile(int fileId) async {
    final repository = ref.read(seriesRepositoryProvider);
    if (repository == null) {
      throw StateError('Series repository not available');
    }

    await repository.deleteSeriesFile(fileId);
    ref.invalidate(seriesFilesProvider(seriesId));
  }

  /// Deletes every file of the series; when [seasonNumber] is provided, only
  /// that season's files are removed. The series stays in Sonarr.
  ///
  /// Providers are invalidated in a [finally] block so the UI refreshes even
  /// when the repository throws after a partial deletion.
  Future<int> deleteAllFiles({int? seasonNumber}) async {
    final repository = ref.read(seriesRepositoryProvider);
    if (repository == null) {
      throw StateError('Series repository not available');
    }

    try {
      return await repository.deleteSeriesFiles(
        seriesId,
        seasonNumber: seasonNumber,
      );
    } finally {
      ref.invalidate(seriesFilesProvider(seriesId));
      ref.invalidate(seriesDetailsProvider(seriesId));
      if (seasonNumber != null) {
        ref.invalidate(seasonEpisodesProvider(seriesId, seasonNumber));
      }
    }
  }

  void refreshFiles() {
    ref.invalidate(seriesFilesProvider(seriesId));
  }

  void refreshExtraFiles() {
    ref.invalidate(seriesExtraFilesProvider(seriesId));
  }

  void refreshHistory() {
    ref.invalidate(seriesHistoryProvider(seriesId));
  }

  void refreshAll() {
    refreshFiles();
    refreshExtraFiles();
    refreshHistory();
  }
}
