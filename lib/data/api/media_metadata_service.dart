import 'package:dio/dio.dart';

import '../../core/services/logger_service.dart';
import '../../domain/models/shared/media_credits.dart';

/// Reads credits and titles from the public metadata servers behind Radarr
/// and Sonarr.
///
/// The lookup endpoints of Radarr and Sonarr return no cast or crew for a
/// title that is not in the library yet, so the preview shown before adding
/// asks the same servers they use. No API key is involved.
class MediaMetadataService {
  /// Base URL of the Radarr metadata server.
  static const radarrMetadataUrl = 'https://api.radarr.video/v1';

  /// Base URL of the Sonarr metadata server.
  static const sonarrMetadataUrl = 'https://skyhook.sonarr.tv/v1';

  /// Most cast members kept from a response.
  static const maxCast = 20;

  /// Most crew members kept from a response.
  static const maxCrew = 10;

  static const _crewDepartmentPriority = ['Directing', 'Writing', 'Production'];

  final Dio _dio;

  /// Creates a [MediaMetadataService], optionally over an existing [dio].
  MediaMetadataService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  /// Fetches titles, cast and crew of the movie identified by [tmdbId].
  Future<MediaPreviewDetails> getMovieDetails(int tmdbId) async {
    logger.debug('[MediaMetadataService] Fetching movie details: $tmdbId');
    final response = await _dio.get<dynamic>(
      '$radarrMetadataUrl/movie/$tmdbId',
    );
    return parseMovieDetails(_asMap(response.data));
  }

  /// Fetches the cast of the series identified by [tvdbId].
  ///
  /// The Sonarr metadata server reports neither crew nor an original title.
  Future<MediaPreviewDetails> getSeriesDetails(int tvdbId) async {
    logger.debug('[MediaMetadataService] Fetching series details: $tvdbId');
    final response = await _dio.get<dynamic>(
      '$sonarrMetadataUrl/tvdb/shows/en/$tvdbId',
    );
    return parseSeriesDetails(_asMap(response.data));
  }

  /// Builds the details from a Radarr metadata server movie payload.
  static MediaPreviewDetails parseMovieDetails(Map<String, dynamic> json) {
    final credits = _asMap(json['Credits']);
    final cast = _sortedByOrder(credits['Cast'])
        .map(
          (entry) => _credit(
            name: entry['Name'],
            role: entry['Character'],
            imageUrl: _headshot(entry['Images']),
          ),
        )
        .nonNulls
        .take(maxCast)
        .toList();
    return MediaPreviewDetails(
      originalTitle: _text(json['OriginalTitle']),
      englishTitle: _text(json['Title']),
      cast: cast,
      crew: _parseCrew(credits['Crew']),
    );
  }

  /// Builds the details from a Sonarr metadata server show payload.
  static MediaPreviewDetails parseSeriesDetails(Map<String, dynamic> json) {
    final cast = _maps(json['actors'])
        .map(
          (entry) => _credit(
            name: entry['name'],
            role: entry['character'],
            imageUrl: _text(entry['image']),
          ),
        )
        .nonNulls
        .take(maxCast)
        .toList();
    return MediaPreviewDetails(cast: cast);
  }

  /// Merges the jobs of each person into one credit and puts directors and
  /// writers first, since those are the names people recognize a title by.
  static List<MediaCredit> _parseCrew(Object? raw) {
    final entries = _sortedByOrder(raw);
    int priority(Map<String, dynamic> entry) {
      final index = _crewDepartmentPriority.indexOf(
        _text(entry['Department']) ?? '',
      );
      return index < 0 ? _crewDepartmentPriority.length : index;
    }

    final ranked = [
      for (var p = 0; p <= _crewDepartmentPriority.length; p++)
        ...entries.where((entry) => priority(entry) == p),
    ];
    final jobsByPerson = <String, List<String>>{};
    final imageByPerson = <String, String?>{};
    for (final entry in ranked) {
      final name = _text(entry['Name']);
      if (name == null) continue;
      final jobs = jobsByPerson.putIfAbsent(name, () => []);
      final job = _text(entry['Job']);
      if (job != null && !jobs.contains(job)) jobs.add(job);
      imageByPerson[name] ??= _headshot(entry['Images']);
    }
    return jobsByPerson.entries
        .take(maxCrew)
        .map(
          (person) => MediaCredit(
            name: person.key,
            role: person.value.isEmpty ? null : person.value.join(', '),
            imageUrl: imageByPerson[person.key],
          ),
        )
        .toList();
  }

  static MediaCredit? _credit({
    required Object? name,
    required Object? role,
    required String? imageUrl,
  }) {
    final personName = _text(name);
    if (personName == null) return null;
    return MediaCredit(name: personName, role: _text(role), imageUrl: imageUrl);
  }

  /// Picks the headshot and asks TMDB for a thumbnail instead of the
  /// full-size original.
  static String? _headshot(Object? images) {
    for (final image in _maps(images)) {
      final url = _text(image['Url']);
      if (url != null) return url.replaceFirst('/t/p/original/', '/t/p/w185/');
    }
    return null;
  }

  static List<Map<String, dynamic>> _sortedByOrder(Object? raw) {
    final entries = _maps(raw).toList();
    int order(Map<String, dynamic> entry) =>
        (entry['Order'] as num?)?.toInt() ?? entries.length;
    // List.sort is not stable; the index keeps the server order on ties.
    final indexed = entries.indexed.toList()
      ..sort((a, b) {
        final byOrder = order(a.$2).compareTo(order(b.$2));
        return byOrder != 0 ? byOrder : a.$1.compareTo(b.$1);
      });
    return [for (final entry in indexed) entry.$2];
  }

  static Iterable<Map<String, dynamic>> _maps(Object? raw) => raw is List
      ? raw.whereType<Map<dynamic, dynamic>>().map(Map<String, dynamic>.from)
      : const [];

  static Map<String, dynamic> _asMap(Object? raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};

  static String? _text(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
