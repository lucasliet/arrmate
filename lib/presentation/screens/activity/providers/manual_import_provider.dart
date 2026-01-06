import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';
import 'activity_provider.dart';

final manualImportFilesProvider = FutureProvider.autoDispose
    .family<List<ImportableFile>, String>((ref, downloadId) async {
      final queueItems = await ref.watch(queueProvider.future);
      final queueItem = queueItems.firstWhere(
        (item) => item.downloadId == downloadId,
        orElse: () => throw Exception('Queue item not found'),
      );

      if (queueItem.movieId != null) {
        final repository = ref.watch(movieRepositoryProvider);
        if (repository == null) {
          throw Exception('Movie repository not available');
        }
        return repository.getImportableFiles(downloadId);
      } else if (queueItem.seriesId != null) {
        final repository = ref.watch(seriesRepositoryProvider);
        if (repository == null) {
          throw Exception('Series repository not available');
        }
        return repository.getImportableFiles(downloadId);
      }

      throw Exception('Unknown media type');
    });

final manualImportControllerProvider = Provider.autoDispose
    .family<ManualImportController, String>((ref, downloadId) {
      return ManualImportController(ref, downloadId);
    });

class ManualImportController {
  final Ref ref;
  final String downloadId;

  ManualImportController(this.ref, this.downloadId);

  Future<void> importFiles(List<ImportableFile> files) async {
    final queueItems = await ref.read(queueProvider.future);
    final queueItem = queueItems.firstWhere(
      (item) => item.downloadId == downloadId,
      orElse: () => throw Exception('Queue item not found'),
    );

    if (queueItem.movieId != null) {
      final repository = ref.read(movieRepositoryProvider);
      if (repository == null) {
        throw Exception('Movie repository not available');
      }
      await repository.manualImport(files);
    } else if (queueItem.seriesId != null) {
      final repository = ref.read(seriesRepositoryProvider);
      if (repository == null) {
        throw Exception('Series repository not available');
      }
      await repository.manualImport(files);
    } else {
      throw Exception('Unknown media type');
    }

    ref.invalidate(queueProvider);
    ref.invalidate(manualImportFilesProvider(downloadId));
  }

  void refreshFiles() {
    ref.invalidate(manualImportFilesProvider(downloadId));
  }
}
