import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/models.dart';
import '../../../providers/data_providers.dart';

final moviesProvider = AsyncNotifierProvider<MoviesNotifier, List<Movie>>(
  MoviesNotifier.new,
);

final movieSearchProvider = NotifierProvider<MovieSearchNotifier, String>(MovieSearchNotifier.new);

class MovieSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  
  // ignore: use_setters_to_change_properties
  void update(String value) => state = value;
}

final movieSortProvider = NotifierProvider<MovieSortNotifier, MovieSort>(MovieSortNotifier.new);

class MovieSortNotifier extends Notifier<MovieSort> {
  @override
  MovieSort build() => const MovieSort();

  // ignore: use_setters_to_change_properties
  void update(MovieSort value) => state = value;
}

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

class MoviesNotifier extends AsyncNotifier<List<Movie>> {
  @override
  FutureOr<List<Movie>> build() async {
    final repository = ref.watch(movieRepositoryProvider);
    if (repository == null) {
      return [];
    }
    
    final movies = await repository.getMovies();
    // Default sort by sortTitle (A-Z)
    movies.sort((a, b) => a.sortTitle.compareTo(b.sortTitle));
    
    return movies;
  }

  Future<void> refresh() async {
    // Invalidating the provider will cause it to dispose and rebuild, 
    // triggering the build() method again.
    ref.invalidateSelf();
    await future;
  }
}
