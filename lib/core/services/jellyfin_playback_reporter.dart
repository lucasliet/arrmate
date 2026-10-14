import '../../data/api/jellyfin_service.dart';
import '../../presentation/screens/player/playback_request.dart';

/// [PlaybackProgressReporter] that mirrors in-app playback into Jellyfin
/// watch state ("Continue Watching").
///
/// Every callback forwards to the matching `/Sessions/Playing/*` endpoint of
/// [JellyfinService]. Reporting failures are swallowed there, so they can
/// never break playback. Only created in user mode — see
/// [JellyfinService.supportsProgressSync].
class JellyfinPlaybackReporter extends PlaybackProgressReporter {
  final JellyfinService _service;

  /// Jellyfin id of the played item.
  final String itemId;

  /// Jellyfin id of the played media source.
  final String mediaSourceId;

  /// Creates a reporter for a resolved playback session.
  const JellyfinPlaybackReporter(
    this._service, {
    required this.itemId,
    required this.mediaSourceId,
  });

  @override
  Future<void> onStart(Duration position) {
    // There is intentionally no `/Sessions/Playing/Start` call: Jellyfin 12
    // removed that endpoint (404), while Progress upserts the playing session
    // on old and new servers alike — so the opening position is reported as
    // an unpaused Progress tick.
    return _service.reportPlaybackProgress(
      itemId: itemId,
      mediaSourceId: mediaSourceId,
      position: position,
      isPaused: false,
    );
  }

  @override
  Future<void> onProgress(Duration position, {required bool isPaused}) {
    return _service.reportPlaybackProgress(
      itemId: itemId,
      mediaSourceId: mediaSourceId,
      position: position,
      isPaused: isPaused,
    );
  }

  @override
  Future<void> onStop(Duration position) {
    return _service.reportPlaybackStopped(
      itemId: itemId,
      mediaSourceId: mediaSourceId,
      position: position,
    );
  }
}
