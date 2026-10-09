import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'logger_service.dart';

/// Persists the Google OAuth tokens between sessions.
abstract class GoogleTokenStore {
  /// Returns every persisted key/value pair, empty when nothing is stored.
  Future<Map<String, String>> readAll();

  /// Persists [values] on top of the currently stored ones.
  Future<void> save(Map<String, String> values);

  /// Removes every persisted value.
  Future<void> clear();
}

/// Creates the platform default [GoogleTokenStore].
GoogleTokenStore createDefaultGoogleTokenStore() =>
    PreferencesGoogleTokenStore();

/// [GoogleTokenStore] backed by [SharedPreferences], used by the web build
/// where no encrypted keyring exists. All values are kept as a single JSON
/// map under one string key.
///
/// Browser storage is readable by any script running on the same origin, so
/// tokens here are protected only by the platform's same-origin policy — an
/// accepted tradeoff for this client-only app, which is why the session can
/// also be revoked from the account at any time.
class PreferencesGoogleTokenStore implements GoogleTokenStore {
  static const String _storageKey = 'google_oauth_tokens';

  @override
  Future<Map<String, String>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_storageKey);
    if (encoded == null) {
      return {};
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      }
    } on FormatException catch (error, stackTrace) {
      logger.warning(
        '[GoogleOAuth] Discarding malformed stored tokens',
        error,
        stackTrace,
      );
    }
    return {};
  }

  @override
  Future<void> save(Map<String, String> values) async {
    final stored = await readAll();
    stored.addAll(values);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(stored));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
