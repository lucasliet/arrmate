import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
GoogleTokenStore createDefaultGoogleTokenStore() => SecureGoogleTokenStore();

/// [GoogleTokenStore] backed by the platform's encrypted secure storage,
/// used by every native build.
class SecureGoogleTokenStore implements GoogleTokenStore {
  final FlutterSecureStorage _storage;

  /// Creates the store, optionally injecting the underlying secure
  /// [storage] for tests.
  SecureGoogleTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();

  @override
  Future<void> save(Map<String, String> values) async {
    await Future.wait([
      for (final entry in values.entries)
        _storage.write(key: entry.key, value: entry.value),
    ]);
  }

  @override
  Future<void> clear() => _storage.deleteAll();
}
