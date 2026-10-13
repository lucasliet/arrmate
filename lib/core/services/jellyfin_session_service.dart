import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/jellyfin_service.dart';
import '../../domain/models/models.dart';
import 'logger_service.dart';

/// Provider for the [JellyfinSessionService].
final jellyfinSessionServiceProvider = Provider(
  (ref) => JellyfinSessionService(),
);

/// Keeps Jellyfin passwords out of storage by exchanging them for sessions.
///
/// `username:password` credentials — typed in the API Key field or carried
/// by a Basic `Authorization` header — are signed in once, and only the
/// returned [InstanceUserSession] is persisted. Instances saved before
/// sessions existed are migrated the same way on their next load.
class JellyfinSessionService {
  final JellyfinService Function(Instance instance) _jellyfinServiceFactory;

  /// Creates the service. [jellyfinServiceFactory] is an injection point for
  /// tests; production uses the real [JellyfinService].
  JellyfinSessionService({
    JellyfinService Function(Instance instance)? jellyfinServiceFactory,
  }) : _jellyfinServiceFactory =
           jellyfinServiceFactory ?? ((instance) => JellyfinService(instance));

  /// Whether [instance] still carries a Jellyfin password that should be
  /// exchanged for a session.
  bool needsCredentialExchange(Instance instance) {
    return instance.type == InstanceType.jellyfin &&
        _jellyfinServiceFactory(instance).hasLoginCredentials;
  }

  /// Returns [instance] ready to be persisted without a password.
  ///
  /// - Login credentials are signed in and replaced by the resulting
  ///   [Instance.userSession]; the API Key field is cleared and a Basic
  ///   credentials header is dropped. Signing in again reuses the stored
  ///   device id, so the server replaces the previous session.
  /// - A plain API key replacing a stored session drops the session locally
  ///   only; the caller signs it out once the new credentials are saved.
  /// - Anything else is returned unchanged.
  ///
  /// Throws the [JellyfinService.signIn] errors when the sign-in fails.
  Future<Instance> exchangeCredentials(Instance instance) async {
    if (instance.type != InstanceType.jellyfin) return instance;

    final service = _jellyfinServiceFactory(instance);
    if (service.hasLoginCredentials) {
      final session = await service.signIn();
      return instance.copyWith(
        apiKey: '',
        headers: JellyfinService.withoutBasicCredentials(instance.headers),
        userSession: session,
      );
    }

    if (instance.apiKey.isNotEmpty && instance.userSession != null) {
      logger.info(
        '[JellyfinSessionService] API key replaces the stored session; '
        'dropping it locally until the new key is saved',
      );
      return instance.copyWith(clearUserSession: true);
    }

    return instance;
  }

  /// Signs the stored session of [instance] out on the server, logging
  /// instead of throwing on failure. Used to discard sessions that will not
  /// be persisted.
  Future<void> logoutQuietly(Instance instance) async {
    if (instance.userSession == null) return;
    try {
      await _jellyfinServiceFactory(instance.copyWith(apiKey: '')).logout();
    } catch (e, stackTrace) {
      logger.warning(
        '[JellyfinSessionService] Could not sign out a discarded session',
        e,
        stackTrace,
      );
    }
  }
}
