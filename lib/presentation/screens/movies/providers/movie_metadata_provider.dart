import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';

final movieFilesProvider = FutureProvider.autoDispose
    .family<List<MediaFile>, int>((ref, movieId) async {
      final repository = ref.watch(movieRepositoryProvider);
      if (repository == null) {
        throw Exception('Repository not available');
      }
      return repository.getMovieFiles(movieId);
    });

final movieExtraFilesProvider = FutureProvider.autoDispose
    .family<List<MovieExtraFile>, int>((ref, movieId) async {
      final repository = ref.watch(movieRepositoryProvider);
      if (repository == null) {
        throw Exception('Repository not available');
      }
      return repository.getMovieExtraFiles(movieId);
    });

final movieHistoryProvider = FutureProvider.autoDispose
    .family<List<HistoryEvent>, int>((ref, movieId) async {
      final repository = ref.watch(movieRepositoryProvider);
      if (repository == null) {
        throw Exception('Repository not available');
      }
      return repository.getMovieHistory(movieId);
    });

final movieMetadataControllerProvider = Provider.autoDispose
    .family<MovieMetadataController, int>((ref, movieId) {
      return MovieMetadataController(ref, movieId);
    });

class MovieMetadataController {
  final Ref ref;
  final int movieId;

  MovieMetadataController(this.ref, this.movieId);

  Future<void> deleteFile(int fileId) async {
    final repository = ref.read(movieRepositoryProvider);
    if (repository == null) return;

    await repository.deleteMovieFile(fileId);
    ref.invalidate(movieFilesProvider(movieId));
  }

  void refreshFiles() {
    ref.invalidate(movieFilesProvider(movieId));
  }

  void refreshExtraFiles() {
    ref.invalidate(movieExtraFilesProvider(movieId));
  }

  void refreshHistory() {
    ref.invalidate(movieHistoryProvider(movieId));
  }

  void refreshAll() {
    refreshFiles();
    refreshExtraFiles();
    refreshHistory();
  }
}
