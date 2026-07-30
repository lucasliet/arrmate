/// Identifies the media catalog used to normalize lookup identifiers.
enum MediaLookupType { movie, series }

/// Normalizes titles, raw IDs, provider IDs, and supported provider URLs.
String normalizeMediaLookupQuery(String input, MediaLookupType type) {
  final query = input.trim();
  if (query.isEmpty) return '';

  final imdbMatch = RegExp(
    r'(?:imdb\.com(?:/[^/]+)*/title/)?(tt\d{5,})',
    caseSensitive: false,
  ).firstMatch(query);
  if (imdbMatch != null) {
    return 'imdb:${imdbMatch.group(1)!.toLowerCase()}';
  }

  final tmdbMatch = RegExp(
    type == MediaLookupType.movie
        ? r'themoviedb\.org/movie/(\d+)'
        : r'themoviedb\.org/tv/(\d+)',
    caseSensitive: false,
  ).firstMatch(query);
  if (tmdbMatch != null) {
    return 'tmdb:${tmdbMatch.group(1)}';
  }

  if (type == MediaLookupType.series) {
    final tvdbMatch = RegExp(
      r'thetvdb\.com/(?:dereferrer/)?series/(\d+)',
      caseSensitive: false,
    ).firstMatch(query);
    if (tvdbMatch != null) {
      return 'tvdb:${tvdbMatch.group(1)}';
    }
  }

  if (RegExp(r'^\d+$').hasMatch(query)) {
    final provider = type == MediaLookupType.movie ? 'tmdb' : 'tvdb';
    return '$provider:$query';
  }

  final providerQuery = RegExp(
    r'^(imdb|tmdb|tvdb)\s*:\s*(.+)$',
    caseSensitive: false,
  ).firstMatch(query);
  if (providerQuery != null) {
    return '${providerQuery.group(1)!.toLowerCase()}:${providerQuery.group(2)!.trim()}';
  }

  return query;
}
