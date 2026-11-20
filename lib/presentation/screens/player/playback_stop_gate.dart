import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/logger_service.dart';

/// Remembers whether the open player still owes a Jellyfin Stopped report.
///
/// A player with a progress reporter calls [arm] when the session starts and
/// [track] with the Stopped request when the route is leaving. Continue
/// Watching awaits [settled] before refetching, so Resume sees the position
/// that report stored. The web fallback never calls [arm], so [settled] is
/// already complete and the refresh runs immediately.
///
/// The wait is bounded by [settleTimeout]: a report stuck on a stalled server
/// keeps running in the background, but no longer holds the refresh. That
/// report stays reachable through [lateReport], so the list can refetch once
/// more when a slow server finally stores the position.
class PlaybackStopGate {
  /// Creates a gate that waits at most [settleTimeout] for a stop report.
  PlaybackStopGate({this.settleTimeout = defaultSettleTimeout});

  /// How long [settled] waits for a stop report unless told otherwise.
  static const Duration defaultSettleTimeout = Duration(seconds: 3);

  /// Longest time [settled] waits for a tracked stop report.
  final Duration settleTimeout;

  Future<void> _pending = Future<void>.value();
  Completer<void>? _session;
  Future<void>? _lateReport;
  Future<void>? _tracked;

  /// The last tracked stop report when it outlived [settleTimeout], so
  /// [settled] completed before the server stored the position.
  ///
  /// Null while the wait is still running, when the report finished in time,
  /// and after a newer report is tracked.
  Future<void>? get lateReport => _lateReport;

  /// Completes when the armed session's stop report has finished or
  /// [settleTimeout] has passed since it was tracked.
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

  /// Completes the armed session when [report] finishes or [settleTimeout]
  /// passes, whichever comes first.
  ///
  /// [report] may already be complete. When nothing was armed, [settled]
  /// follows [report] directly, under the same limit.
  void track(Future<void> report) {
    _lateReport = null;
    _tracked = report;
    final bounded = report.timeout(
      settleTimeout,
      onTimeout: () {
        if (identical(_tracked, report)) {
          _lateReport = report;
        }
        logger.warning(
          '[PlaybackStopGate] Stop report still pending after '
          '${settleTimeout.inMilliseconds}ms; releasing the Watching refresh',
        );
      },
    );
    _pending = bounded;
    final session = _session;
    if (session == null) {
      return;
    }
    bounded.whenComplete(() {
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
