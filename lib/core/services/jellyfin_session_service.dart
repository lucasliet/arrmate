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
/// `username:password` credentials, carried by a Basic `Authorization`
/// header (Add Basic Auth), are signed in once, and only the returned
/// [InstanceUserSession] is persisted. The API Key field is never a login,
/// and a Basic credentials header saved next to an API key is never used,
/// so it is dropped instead of stored.
/// Instances saved before sessions existed are migrated the same way on
/// their next load.
class JellyfinSessionService {
  final JellyfinService Function(Instance instance) _jellyfinServiceFactory;

  /// Creates the service. [jellyfinServiceFactory] is an injection point for
  /// tests; production uses the real [JellyfinService].
  JellyfinSessionService({
    JellyfinService Function(Instance instance)? jellyfinServiceFactory,
  }) : _jellyfinServiceFactory =
           jellyfinServiceFactory ?? ((instance) => JellyfinService(instance));

  /// Whether [instance] still carries a Jellyfin password that should be
  /// exchanged for a session, or dropped because an API key makes it unused.
  bool needsCredentialExchange(Instance instance) {
    if (instance.type != InstanceType.jellyfin) return false;
    if (_carriesUnusedBasicCredentials(instance)) return true;
    return _jellyfinServiceFactory(instance).hasLoginCredentials;
  }

  /// Whether [instance] authenticates with an API key while still holding a
  /// Basic credentials header, which API key mode never sends.
  ///
  /// Each header is checked on its own, as
  /// [JellyfinService.withoutBasicCredentials] does, so a password listed
  /// after another `Authorization` header is still found.
  bool _carriesUnusedBasicCredentials(Instance instance) {
    return instance.apiKey.isNotEmpty &&
        instance.headers.any(
          (header) => JellyfinService.decodeBasicCredentials([header]) != null,
        );
  }

  /// Returns [instance] ready to be persisted without a password.
  ///
  /// - Login credentials are signed in and replaced by the resulting
  ///   [Instance.userSession]; the API Key field is cleared and a Basic
  ///   credentials header is dropped. Signing in again reuses the stored
  ///   device id, so the server replaces the previous session.
  /// - An API key drops a Basic credentials header saved next to it, since
  ///   API key mode never sends it and the password must not be stored.
  /// - An API key replacing a stored session drops the session locally
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

    if (instance.apiKey.isEmpty) return instance;

    final withoutPassword = _carriesUnusedBasicCredentials(instance)
        ? instance.copyWith(
            headers: JellyfinService.withoutBasicCredentials(instance.headers),
          )
        : instance;
    if (withoutPassword.userSession == null) return withoutPassword;

    logger.info(
      '[JellyfinSessionService] API key replaces the stored session; '
      'dropping it locally until the new key is saved',
    );
    return withoutPassword.copyWith(clearUserSession: true);
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
