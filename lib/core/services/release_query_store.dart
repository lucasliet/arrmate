import 'dart:convert';

import 'package:arrmate/core/services/logger_service.dart';
import 'package:arrmate/domain/models/shared/release_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a persisted release query and its persistence preference.
class SavedReleaseQuery {
  final ReleaseQuery query;
  final bool remember;

  const SavedReleaseQuery({required this.query, required this.remember});
}

/// Persists independent release filter configurations for movies and series.
class ReleaseQueryStore {
  static const _movieQueryKey = 'movie_release_query';
  static const _seriesQueryKey = 'series_release_query';
  static const _movieRememberKey = 'remember_movie_release_query';
  static const _seriesRememberKey = 'remember_series_release_query';

  /// Loads the persisted query for the requested media type.
  Future<SavedReleaseQuery> load({required bool isMovie}) async {
    SharedPreferences preferences;
    try {
      preferences = await SharedPreferences.getInstance();
    } catch (error, stackTrace) {
      logger.warning(
        '[ReleaseQueryStore] SharedPreferences unavailable, using defaults',
        error,
        stackTrace,
      );
      return const SavedReleaseQuery(query: ReleaseQuery(), remember: false);
    }

    final remember = preferences.getBool(_rememberKey(isMovie)) ?? false;
    final encodedQuery = preferences.getString(_queryKey(isMovie));
    if (!remember || encodedQuery == null) {
      return SavedReleaseQuery(query: const ReleaseQuery(), remember: remember);
    }

    try {
      final json = jsonDecode(encodedQuery);
      if (json is! Map<String, dynamic>) {
        return const SavedReleaseQuery(query: ReleaseQuery(), remember: true);
      }
      return SavedReleaseQuery(
        query: ReleaseQuery.fromJson(json),
        remember: true,
      );
    } catch (error, stackTrace) {
      logger.warning(
        '[ReleaseQueryStore] Stored release query is malformed, '
        'restoring safe defaults',
        error,
        stackTrace,
      );
      return const SavedReleaseQuery(query: ReleaseQuery(), remember: true);
    }
  }

  /// Saves [query] when persistence is enabled and clears it otherwise.
  Future<void> save({
    required bool isMovie,
    required ReleaseQuery query,
    required bool remember,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_rememberKey(isMovie), remember);
    if (remember) {
      await preferences.setString(
        _queryKey(isMovie),
        jsonEncode(query.toJson()),
      );
      return;
    }
    await preferences.remove(_queryKey(isMovie));
  }

  String _queryKey(bool isMovie) => isMovie ? _movieQueryKey : _seriesQueryKey;

  String _rememberKey(bool isMovie) =>
      isMovie ? _movieRememberKey : _seriesRememberKey;
}
