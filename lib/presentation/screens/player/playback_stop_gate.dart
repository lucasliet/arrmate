import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Remembers whether the open player still owes a Jellyfin Stopped report.
///
/// A player with a progress reporter calls [arm] when the session starts and
/// [track] with the Stopped request when the route is leaving. Continue
/// Watching awaits [settled] before refetching, so Resume sees the position
/// that report stored. The web fallback never calls [arm], so [settled] is
/// already complete and the refresh runs immediately.
class PlaybackStopGate {
  Future<void> _pending = Future<void>.value();
  Completer<void>? _session;

  /// Completes when the armed session's stop report has finished.
  ///
  /// Completes immediately when no session is armed.
  Future<void> get settled {
    final session = _session;
    if (session != null) {
      return session.future;
    }
    return _pending;
  }

  /// Marks a session that will report stop before the list may refetch.
  void arm() {
    final session = _session;
    if (session != null && !session.isCompleted) {
      return;
    }
    _session = Completer<void>();
  }

  /// Completes the armed session when [report] finishes.
  ///
  /// [report] may already be complete. When nothing was armed, [settled]
  /// follows [report] directly.
  void track(Future<void> report) {
    _pending = report;
    final session = _session;
    if (session == null) {
      return;
    }
    report.whenComplete(() {
      if (!session.isCompleted) {
        session.complete();
      }
      if (identical(_session, session)) {
        _session = null;
      }
    });
  }
}

/// The gate shared by the player and the watching list.
final playbackStopGateProvider = Provider<PlaybackStopGate>(
  (ref) => PlaybackStopGate(),
);
