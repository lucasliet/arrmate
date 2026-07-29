/// Represents a safe external destination for a media item.
class MediaExternalLink {
  /// User-facing name of the destination.
  final String label;

  /// HTTPS URI opened for the destination.
  final Uri uri;

  const MediaExternalLink({required this.label, required this.uri});
}

/// Builds external media links using HTTPS URLs and encoded parameters.
abstract final class MediaExternalLinks {
  static final RegExp _imdbIdPattern = RegExp(r'^tt\d+$');
  static final RegExp _youTubeIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// Builds IMDb, Trakt, and Letterboxd links for a movie.
  static List<MediaExternalLink> movie({
    required String title,
    String? imdbId,
  }) {
    final normalizedImdbId = _normalizeImdbId(imdbId);
    return [
      MediaExternalLink(
        label: 'IMDb',
        uri: _imdbUri(title: title, imdbId: normalizedImdbId),
      ),
      MediaExternalLink(
        label: 'Trakt',
        uri: normalizedImdbId != null
            ? Uri.https('app.trakt.tv', '/movies/$normalizedImdbId')
            : Uri.https('app.trakt.tv', '/search', {
                'm': 'movie',
                'q': title.trim(),
              }),
      ),
      MediaExternalLink(
        label: 'Letterboxd',
        uri: Uri(
          scheme: 'https',
          host: 'letterboxd.com',
          pathSegments: ['search', 'films', title.trim(), ''],
        ),
      ),
    ];
  }

  /// Builds IMDb, Trakt, and TVDB links for a series.
  static List<MediaExternalLink> series({
    required String title,
    required int tvdbId,
    String? imdbId,
  }) {
    final normalizedImdbId = _normalizeImdbId(imdbId);
    return [
      MediaExternalLink(
        label: 'IMDb',
        uri: _imdbUri(title: title, imdbId: normalizedImdbId),
      ),
      MediaExternalLink(
        label: 'Trakt',
        uri: normalizedImdbId != null
            ? Uri.https('app.trakt.tv', '/shows/$normalizedImdbId')
            : Uri.https('app.trakt.tv', '/search', {
                'm': 'show',
                'q': title.trim(),
              }),
      ),
      MediaExternalLink(
        label: 'TVDB',
        uri: Uri.https('www.thetvdb.com', '/', {
          'tab': 'series',
          'id': tvdbId.toString(),
        }),
      ),
    ];
  }

  /// Builds a YouTube watch link for a valid trailer ID.
  static Uri? youTubeTrailer(String? trailerId) {
    final normalizedId = trailerId?.trim();
    if (normalizedId == null || !_youTubeIdPattern.hasMatch(normalizedId)) {
      return null;
    }
    return Uri.https('www.youtube.com', '/watch', {'v': normalizedId});
  }

  static Uri _imdbUri({required String title, required String? imdbId}) {
    if (imdbId != null) {
      return Uri.https('www.imdb.com', '/title/$imdbId/');
    }
    return Uri.https('www.imdb.com', '/find/', {'s': 'tt', 'q': title.trim()});
  }

  static String? _normalizeImdbId(String? imdbId) {
    final normalizedId = imdbId?.trim().toLowerCase();
    if (normalizedId == null || !_imdbIdPattern.hasMatch(normalizedId)) {
      return null;
    }
    return normalizedId;
  }
}
