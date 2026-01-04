import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/models.dart';
import '../../../providers/data_providers.dart';

final moviesProvider = AsyncNotifierProvider<MoviesNotifier, List<Movie>>(
  MoviesNotifier.new,
);

class MoviesNotifier extends AsyncNotifier<List<Movie>> {
  @override
  FutureOr<List<Movie>> build() async {
    final repository = ref.watch(movieRepositoryProvider);
    if (repository == null) {
      return [];
    }
    
    final movies = await repository.getMovies();
    // Sort by sortTitle
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
