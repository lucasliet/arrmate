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
  final Future<SharedPreferences> Function() _preferencesLoader;
  Future<void> _saveQueue = Future<void>.value();

  /// Creates a store backed by shared preferences.
  ReleaseQueryStore({Future<SharedPreferences> Function()? preferencesLoader})
    : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  /// Loads the persisted query for the requested media type.
  Future<SavedReleaseQuery> load({required bool isMovie}) async {
    SharedPreferences preferences;
    try {
      preferences = await _preferencesLoader();
    } catch (error, stackTrace) {
      logger.warning(
        '[ReleaseQueryStore] SharedPreferences unavailable, using defaults',
        error,
        stackTrace,
      );
      return const SavedReleaseQuery(query: ReleaseQuery(), remember: false);
    }

    Object? storedRemember;
    Object? storedQuery;
    try {
      storedRemember = preferences.get(_rememberKey(isMovie));
      storedQuery = preferences.get(_queryKey(isMovie));
    } catch (error, stackTrace) {
      logger.warning(
        '[ReleaseQueryStore] Stored release preferences are unavailable, '
        'using defaults',
        error,
        stackTrace,
      );
      return const SavedReleaseQuery(query: ReleaseQuery(), remember: false);
    }

    final remember = storedRemember is bool ? storedRemember : false;
    final encodedQuery = storedQuery is String ? storedQuery : null;
    if ((storedRemember != null && storedRemember is! bool) ||
        (storedQuery != null && storedQuery is! String)) {
      logger.warning(
        '[ReleaseQueryStore] Stored release preferences have unexpected types, '
        'restoring safe defaults',
      );
    }
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
  }) {
    final save = _saveQueue.then(
      (_) => _write(isMovie: isMovie, query: query, remember: remember),
    );
    _saveQueue = save;
    return save;
  }

  Future<void> _write({
    required bool isMovie,
    required ReleaseQuery query,
    required bool remember,
  }) async {
    try {
      final preferences = await _preferencesLoader();
      await preferences.setBool(_rememberKey(isMovie), remember);
      if (remember) {
        await preferences.setString(
          _queryKey(isMovie),
          jsonEncode(query.toJson()),
        );
        return;
      }
      await preferences.remove(_queryKey(isMovie));
    } catch (error, stackTrace) {
      logger.warning(
        '[ReleaseQueryStore] Failed to save release preferences',
        error,
        stackTrace,
      );
    }
  }

  String _queryKey(bool isMovie) => isMovie ? _movieQueryKey : _seriesQueryKey;

  String _rememberKey(bool isMovie) =>
      isMovie ? _movieRememberKey : _seriesRememberKey;
}
