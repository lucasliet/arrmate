import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/logger_service.dart';

/// Ids of the Jellyfin instances whose stored session the server rejected.
///
/// In-memory only: the flag is re-derived by the next rejected request, so
/// it is never persisted across app runs.
final jellyfinSessionExpiredProvider =
    NotifierProvider<JellyfinSessionExpiredNotifier, Set<String>>(
      JellyfinSessionExpiredNotifier.new,
    );

/// Tracks the Jellyfin instances that need a new sign-in because their
/// stored session expired or was revoked on the server.
class JellyfinSessionExpiredNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Flags the instance with [instanceId] as needing a new sign-in.
  void markExpired(String instanceId) {
    if (state.contains(instanceId)) return;
    logger.debug(
      '[JellyfinSessionExpiredNotifier] Session expired for instance '
      '$instanceId',
    );
    state = {...state, instanceId};
  }

  /// Forgets the expired flag of the instance with [instanceId], typically
  /// after a new sign-in was saved.
  void clear(String instanceId) {
    if (!state.contains(instanceId)) return;
    state = {...state}..remove(instanceId);
  }

  /// Whether the instance with [id] needs a new sign-in.
  bool isExpired(String id) => state.contains(id);
}
