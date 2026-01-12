import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';
import 'movies_provider.dart';

/// Provider for fetching the details of a specific movie using its ID.
final movieDetailsProvider = FutureProvider.autoDispose.family<Movie, int>((
  ref,
  movieId,
) async {
  final repository = ref.watch(movieRepositoryProvider);
  if (repository == null) {
    throw Exception('Repository not available');
  }
  return repository.getMovie(movieId);
});

// Helper for actions (monitor, delete, etc)
/// Controller for managing movie actions (monitoring, deleting, updating).
class MovieController {
  final Ref ref;
  final int movieId;

  MovieController(this.ref, this.movieId);

  Future<void> toggleMonitor(Movie movie) async {
    final repository = ref.read(movieRepositoryProvider);
    if (repository == null) return;

    final updatedMovie = movie.copyWith(monitored: !movie.monitored);

    // Using ref.read to access the provider notifier/controller if it were a notifier.
    // Since it's a FutureProvider, we can't update state directly easily (optimistic).
    // So we perform action and invalidate.
    await repository.updateMovie(updatedMovie);
    ref.invalidate(movieDetailsProvider(movieId));
  }

  Future<void> deleteMovie({
    bool deleteFiles = false,
    bool addExclusion = false,
  }) async {
    final repository = ref.read(movieRepositoryProvider);
    if (repository == null) return;
    await repository.deleteMovie(
      movieId,
      deleteFiles: deleteFiles,
      addExclusion: addExclusion,
    );
    ref.invalidate(moviesProvider);
  }

  Future<void> updateMovie(Movie movie, {bool moveFiles = false}) async {
    final repository = ref.read(movieRepositoryProvider);
    if (repository == null) return;
    await repository.updateMovie(movie, moveFiles: moveFiles);
    ref.invalidate(movieDetailsProvider(movieId));
  }

  Future<void> refresh() async {
    ref.invalidate(movieDetailsProvider(movieId));
  }

  Future<void> automaticSearch() async {
    final repository = ref.read(movieRepositoryProvider);
    if (repository == null) return;
    await repository.searchMovies([movieId]);
  }

  Future<void> rescan() async {
    final repository = ref.read(movieRepositoryProvider);
    if (repository == null) return;
    // Trigger update first, then scan
    await repository.refreshMovie(movieId);
    await repository.rescanMovie(movieId);
  }
}

/// Provider for accessing the MovieController.
final movieControllerProvider = Provider.autoDispose
    .family<MovieController, int>((ref, movieId) {
      return MovieController(ref, movieId);
    });
