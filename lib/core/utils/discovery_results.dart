import '../../domain/models/models.dart';

/// Available ordering modes for discovery lookup results.
enum DiscoverySortOption {
  relevance,
  latest,
  rating;

  /// User-facing label for the ordering mode.
  String get label {
    switch (this) {
      case DiscoverySortOption.relevance:
        return 'Relevant';
      case DiscoverySortOption.latest:
        return 'Latest';
      case DiscoverySortOption.rating:
        return 'Rating';
    }
  }
}

/// Filters and sorts movie lookup [results] without mutating the API list.
List<Movie> prepareMovieDiscoveryResults(
  List<Movie> results, {
  required DiscoverySortOption sort,
  required bool hideExisting,
}) {
  final prepared = results
      .where((movie) => !hideExisting || !movie.exists)
      .toList();
  switch (sort) {
    case DiscoverySortOption.relevance:
      return prepared;
    case DiscoverySortOption.latest:
      prepared.sort((first, second) => second.year.compareTo(first.year));
      return prepared;
    case DiscoverySortOption.rating:
      prepared.sort(
        (first, second) => _movieRating(second).compareTo(_movieRating(first)),
      );
      return prepared;
  }
}

/// Filters and sorts series lookup [results] without mutating the API list.
List<Series> prepareSeriesDiscoveryResults(
  List<Series> results, {
  required DiscoverySortOption sort,
  required bool hideExisting,
}) {
  final prepared = results
      .where((series) => !hideExisting || !series.exists)
      .toList();
  switch (sort) {
    case DiscoverySortOption.relevance:
      return prepared;
    case DiscoverySortOption.latest:
      prepared.sort((first, second) => second.year.compareTo(first.year));
      return prepared;
    case DiscoverySortOption.rating:
      prepared.sort(
        (first, second) =>
            (second.ratings?.value ?? 0).compareTo(first.ratings?.value ?? 0),
      );
      return prepared;
  }
}

double _movieRating(Movie movie) {
  return movie.ratings?.tmdb?.value ??
      movie.ratings?.imdb?.value ??
      movie.popularity ??
      0;
}
