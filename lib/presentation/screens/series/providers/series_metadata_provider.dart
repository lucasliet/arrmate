import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';

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

class SeriesMetadataController {
  final Ref ref;
  final int seriesId;

  SeriesMetadataController(this.ref, this.seriesId);

  Future<void> deleteFile(int fileId) async {
    final repository = ref.read(seriesRepositoryProvider);
    if (repository == null) return;

    await repository.deleteSeriesFile(fileId);
    ref.invalidate(seriesFilesProvider(seriesId));
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
