import 'dart:async';
import '../../../../core/services/logger_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';

/// Provider that holds the list of movies fetched from Radarr.
final moviesProvider = AsyncNotifierProvider<MoviesNotifier, List<Movie>>(
  MoviesNotifier.new,
);

final movieSearchProvider = NotifierProvider<MovieSearchNotifier, String>(
  MovieSearchNotifier.new,
);

class MovieSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final movieSortProvider = NotifierProvider<MovieSortNotifier, MovieSort>(
  MovieSortNotifier.new,
);

class MovieSortNotifier extends Notifier<MovieSort> {
  @override
  MovieSort build() => const MovieSort();

  void update(MovieSort value) => state = value;
}

/// Provider that returns the list of movies filtered by search query and sorted by options.
final filteredMoviesProvider = Provider<AsyncValue<List<Movie>>>((ref) {
  final moviesState = ref.watch(moviesProvider);
  final searchQuery = ref.watch(movieSearchProvider).toLowerCase();
  final sort = ref.watch(movieSortProvider);

  return moviesState.whenData((movies) {
    var filtered = List<Movie>.from(movies);

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        final titleMatch = m.title.toLowerCase().contains(searchQuery);
        final sortTitleMatch = m.sortTitle.toLowerCase().contains(searchQuery);
        return titleMatch || sortTitleMatch;
      }).toList();
    }

    filtered = filtered.where((m) => sort.filter.filter(m)).toList();

    filtered.sort((a, b) {
      final comparison = sort.option.compare(a, b);
      return sort.isAscending ? comparison : -comparison;
    });

    return filtered;
  });
});

/// Notifier to manage fetching and refreshing the movie list.
class MoviesNotifier extends AsyncNotifier<List<Movie>> {
  @override
  FutureOr<List<Movie>> build() async {
    final repository = ref.watch(movieRepositoryProvider);
    logger.debug('[MoviesProvider] Building movie list');
    if (repository == null) {
      logger.debug('[MoviesProvider] No repository available');
      return [];
    }

    final movies = await repository.getMovies();
    // Default sort by sortTitle (A-Z)
    movies.sort((a, b) => a.sortTitle.compareTo(b.sortTitle));

    return movies;
  }

  Future<void> refresh() async {
    logger.debug('[MoviesProvider] Refreshing movies');
    // Invalidating the provider will cause it to dispose and rebuild,
    // triggering the build() method again.
    ref.invalidateSelf();
    await future;
  }
}
