import 'dart:convert';

import 'package:arrmate/core/services/logger_service.dart';
import 'package:arrmate/domain/models/qbittorrent/torrent_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a persisted torrent query and its persistence preference.
class SavedTorrentQuery {
  final TorrentQuery query;
  final bool remember;

  const SavedTorrentQuery({required this.query, required this.remember});
}

/// Persists the torrent filter configuration for the Activity torrents tab.
class TorrentQueryStore {
  static const _queryKey = 'torrent_query';
  static const _rememberKey = 'remember_torrent_query';
  final Future<SharedPreferences> Function() _preferencesLoader;
  Future<void> _saveQueue = Future<void>.value();

  /// Creates a store backed by shared preferences.
  TorrentQueryStore({Future<SharedPreferences> Function()? preferencesLoader})
    : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  /// Loads the persisted query.
  Future<SavedTorrentQuery> load() async {
    SharedPreferences preferences;
    try {
      preferences = await _preferencesLoader();
    } catch (error, stackTrace) {
      logger.warning(
        '[TorrentQueryStore] SharedPreferences unavailable, using defaults',
        error,
        stackTrace,
      );
      return const SavedTorrentQuery(query: TorrentQuery(), remember: false);
    }

    Object? storedRemember;
    Object? storedQuery;
    try {
      storedRemember = preferences.get(_rememberKey);
      storedQuery = preferences.get(_queryKey);
    } catch (error, stackTrace) {
      logger.warning(
        '[TorrentQueryStore] Stored torrent preferences are unavailable, '
        'using defaults',
        error,
        stackTrace,
      );
      return const SavedTorrentQuery(query: TorrentQuery(), remember: false);
    }

    final remember = storedRemember is bool ? storedRemember : false;
    final encodedQuery = storedQuery is String ? storedQuery : null;
    if ((storedRemember != null && storedRemember is! bool) ||
        (storedQuery != null && storedQuery is! String)) {
      logger.warning(
        '[TorrentQueryStore] Stored torrent preferences have unexpected types, '
        'restoring safe defaults',
      );
    }
    if (!remember || encodedQuery == null) {
      return SavedTorrentQuery(query: const TorrentQuery(), remember: remember);
    }

    try {
      final json = jsonDecode(encodedQuery);
      if (json is! Map<String, dynamic>) {
        return const SavedTorrentQuery(query: TorrentQuery(), remember: true);
      }
      return SavedTorrentQuery(
        query: TorrentQuery.fromJson(json),
        remember: true,
      );
    } catch (error, stackTrace) {
      logger.warning(
        '[TorrentQueryStore] Stored torrent query is malformed, '
        'restoring safe defaults',
        error,
        stackTrace,
      );
      return const SavedTorrentQuery(query: TorrentQuery(), remember: true);
    }
  }

  /// Saves [query] when persistence is enabled and clears it otherwise.
  Future<void> save({required TorrentQuery query, required bool remember}) {
    final save = _saveQueue.then(
      (_) => _write(query: query, remember: remember),
    );
    _saveQueue = save;
    return save;
  }

  Future<void> _write({
    required TorrentQuery query,
    required bool remember,
  }) async {
    try {
      final preferences = await _preferencesLoader();
      await preferences.setBool(_rememberKey, remember);
      if (remember) {
        await preferences.setString(_queryKey, jsonEncode(query.toJson()));
        return;
      }
      await preferences.remove(_queryKey);
    } catch (error, stackTrace) {
      logger.warning(
        '[TorrentQueryStore] Failed to save torrent preferences',
        error,
        stackTrace,
      );
    }
  }
}
