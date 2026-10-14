import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/logger_service.dart';
import '../../../../core/utils/sensitive_data_redactor.dart';
import 'playback_request.dart';

/// Minimal description of a track discovered by the underlying player engine.
///
/// Engine tracks are matched against the media-server track options
/// ([AudioTrackOption]/[SubtitleTrackOption]) by label first and by ordering
/// as a fallback — see [matchDiscoveredTrack].
class PlayerTrack extends Equatable {
  /// Creates a discovered track description.
  const PlayerTrack({
    required this.id,
    this.title,
    this.language,
    this.isExternal = false,
  });

  /// Engine-specific track identifier used to select the track.
  final String id;

  /// Track title reported by the engine, if any.
  final String? title;

  /// Track language tag reported by the engine, if any.
  final String? language;

  /// Whether the track was loaded from an external file/URI.
  final bool isExternal;

  @override
  List<Object?> get props => [id, title, language, isExternal];
}

/// Picks the discovered engine track that best matches a media-server option.
///
/// Matching strategy:
/// 1. Exact (case-insensitive) match between the option [label] and the
///    engine track title or language, when the engine exposes them.
/// 2. Otherwise, the option's [ordinal] (its position among the sibling
///    options of the same kind) is mapped onto the discovered track list,
///    which follows the same media ordering in the common case.
///
/// Returns `null` when no plausible match exists.
PlayerTrack? matchDiscoveredTrack({
  required List<PlayerTrack> discovered,
  required String label,
  required int ordinal,
}) {
  final needle = label.toLowerCase();
  for (final track in discovered) {
    final title = track.title?.toLowerCase();
    final language = track.language?.toLowerCase();
    if (title == needle || language == needle) {
      return track;
    }
  }
  if (ordinal >= 0 && ordinal < discovered.length) {
    return discovered[ordinal];
  }
  return null;
}

/// Abstraction over the media engine powering a playback session.
///
/// Modeled after what media_kit's `Player` offers so the session controller
/// and the UI can run headless in tests against fakes, while production uses
/// the media_kit-backed adapter.
abstract interface class StreamPlayer {
  /// Playback position updates.
  Stream<Duration> get positionStream;

  /// Buffered-ahead position updates.
  Stream<Duration> get bufferStream;

  /// Total media duration updates.
  Stream<Duration> get durationStream;

  /// Whether playback is currently running (not paused).
  Stream<bool> get playingStream;

  /// Whether the engine is currently buffering.
  Stream<bool> get bufferingStream;

  /// Whether the end of the media has been reached.
  Stream<bool> get completedStream;

  /// Fatal engine errors that end the playback session.
  Stream<String> get errorStream;

  /// Current playback position.
  Duration get position;

  /// Total media duration.
  Duration get duration;

  /// Opens [url] as the media source, sending [httpHeaders] with requests and
  /// optionally starting at [startPosition].
  Future<void> open(
    Uri url, {
    Map<String, String> httpHeaders,
    Duration? startPosition,
  });

  /// Resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Toggles between playing and paused.
  Future<void> togglePlayPause();

  /// Jumps to [position].
  Future<void> seek(Duration position);

  /// Lists the audio tracks currently discovered by the engine.
  Future<List<PlayerTrack>> discoverAudioTracks();

  /// Lists the subtitle tracks currently discovered by the engine.
  Future<List<PlayerTrack>> discoverSubtitleTracks();

  /// Selects a discovered audio track by its [PlayerTrack.id].
  Future<void> selectAudioTrackId(String trackId);

  /// Selects a discovered embedded subtitle track by [PlayerTrack.id],
  /// or disables subtitles when `null`.
  Future<void> selectEmbeddedSubtitleTrack(String? trackId);

  /// Loads an external subtitle file from [subtitleUri].
  Future<void> selectExternalSubtitleTrack(Uri subtitleUri);

  /// Releases all engine resources.
  Future<void> dispose();
}

/// Coordinates a single playback session between the engine, the reporter and
/// the player screen.
///
/// Responsibilities:
/// - Opens the requested stream (with HTTP headers).
/// - Seeks to the resume position once the first buffer/duration is known.
/// - Reports [PlaybackProgressReporter.onStart] once per session.
/// - Reports [PlaybackProgressReporter.onProgress] every [progressInterval]
///   while playing (skipped while paused).
/// - Reports [PlaybackProgressReporter.onStop] on completion or dispose.
/// - Surfaces engine failures through [errorMessage] for the Retry UI.
class PlaybackSessionController {
  /// Creates a session controller for [request].
  ///
  /// [playerFactory] must return a fresh [StreamPlayer]; it is invoked lazily
  /// so tests never construct a real media engine. [progressInterval] controls
  /// how often progress is reported (defaults to 10 seconds).
  PlaybackSessionController({
    required this.request,
    required StreamPlayer Function() playerFactory,
    this.progressInterval = defaultProgressInterval,
    DateTime Function()? clock,
  }) : _playerFactory = playerFactory,
       _clock = clock ?? DateTime.now;

  /// How often progress is reported while playing.
  static const Duration defaultProgressInterval = Duration(seconds: 10);

  /// Minimum interval between resume-seek retries when the engine starts
  /// decoding frames from 0s before the initial seek takes effect.
  static const Duration _resumeRetryCooldown = Duration(milliseconds: 500);

  /// Tolerance below [_resumeTarget] within which an emitted engine position
  /// proves the resume seek landed (keyframe alignment may land a few seconds
  /// before the exact target).
  static const Duration _resumeVerificationTolerance = Duration(seconds: 5);

  /// The playback request driving this session.
  final PlaybackRequest request;

  /// Interval between progress reports while playing.
  final Duration progressInterval;

  final StreamPlayer Function() _playerFactory;
  final DateTime Function() _clock;
  final _subscriptions = <StreamSubscription<void>>[];
  Timer? _progressTimer;

  StreamPlayer? _player;
  Duration _lastPosition = Duration.zero;
  Duration _resumeTarget = Duration.zero;
  bool _resumeApplied = true;
  bool _resumeVerified = true;
  DateTime? _lastResumeSeekAt;
  bool _playing = false;
  bool _startReported = false;
  bool _stopReported = false;
  bool _disposed = false;

  /// Last fatal error message, or `null` while playback is healthy.
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  /// Whether the media finished playing (the screen then pops back).
  final ValueNotifier<bool> finished = ValueNotifier<bool>(false);

  /// The underlying player engine, or `null` before [initialize].
  StreamPlayer? get player => _player;

  /// Current playback position as last reported by the engine.
  Duration get position => _lastPosition;

  /// Starts the session: subscribes to engine streams, opens the media and
  /// begins progress reporting.
  Future<void> initialize() async {
    if (_disposed) {
      return;
    }
    _lastPosition = request.resumePosition;
    _resetResumeState(request.resumePosition);
    final player = _player ??= _playerFactory();
    _listenToPlayer(player);
    _startProgressTimer();
    await _open(request.streamUrl);
  }

  /// Reopens the stream after a failure, preserving the last known position.
  Future<void> retry() async {
    if (_player == null) {
      return initialize();
    }
    logger.info('[PlaybackSessionController] Retrying "${request.title}"');
    errorMessage.value = null;
    finished.value = false;
    _resetResumeState(_lastPosition);
    _stopReported = false;
    _progressTimer?.cancel();
    _startProgressTimer();
    await _open(request.streamUrl);
  }

  /// Switches the media source (e.g. Original ↔ Data Saver) while preserving
  /// the playback position.
  Future<void> switchSource(Uri url) async {
    final player = _player;
    if (player == null) {
      return;
    }
    logger.info(
      '[PlaybackSessionController] Switching source for "${request.title}"',
    );
    finished.value = false;
    _resetResumeState(_lastPosition);
    await _open(url);
  }

  /// Jumps to [position], tracking it as the last known position right away.
  ///
  /// The engine reports positions on its own cadence, so without this a
  /// seek followed by an immediate exit would report the pre-seek position.
  /// The next engine emission converges to the true value afterwards.
  Future<void> seekTo(Duration position) async {
    final target = position < Duration.zero ? Duration.zero : position;
    _lastPosition = target;
    _resumeTarget = target;
    _resumeApplied = true;
    _resumeVerified = true;
    final player = _player;
    if (player == null) {
      return;
    }
    try {
      await player.seek(target);
    } catch (error, stackTrace) {
      logger.warning(
        '[PlaybackSessionController] Seek to $target failed',
        error,
        stackTrace,
      );
    }
  }

  /// Seeks relative to the last known position (e.g. ±10s).
  Future<void> seekBy(Duration delta) => seekTo(_lastPosition + delta);

  /// Cancels every subscription and timer, reports the final position and
  /// releases the engine.
  Future<void> dispose() async {
    _disposed = true;
    _progressTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _safeReportStop();
    await _player?.dispose();
    _player = null;
  }

  void _resetResumeState(Duration target) {
    _resumeTarget = target;
    final noResume = target <= Duration.zero;
    _resumeApplied = noResume;
    _resumeVerified = noResume;
    _lastResumeSeekAt = null;
  }

  void _listenToPlayer(StreamPlayer player) {
    _subscriptions
      ..add(player.errorStream.listen(_handlePlayerError))
      ..add(player.playingStream.listen((playing) => _playing = playing))
      ..add(
        player.bufferStream.listen((buffer) {
          // media_kit's open() calls stop(open: true) first, which emits
          // buffer = Duration.zero before loadlist even runs; only a real
          // non-zero buffer means media data is loaded.
          if (buffer > Duration.zero) {
            _applyResumeIfNeeded();
          }
        }),
      )
      ..add(
        player.durationStream.listen((duration) {
          if (duration > Duration.zero) {
            _applyResumeIfNeeded();
          }
        }),
      )
      ..add(
        player.completedStream.listen(
          (completed) => unawaited(_handleCompleted(completed)),
        ),
      )
      ..add(player.positionStream.listen(_handlePosition));
  }

  void _handlePosition(Duration position) {
    if (_resumeVerified) {
      _lastPosition = position;
      return;
    }
    final threshold = _resumeTarget > _resumeVerificationTolerance
        ? _resumeTarget - _resumeVerificationTolerance
        : _resumeTarget;
    if (position >= threshold) {
      _resumeApplied = true;
      _resumeVerified = true;
      _lastPosition = position;
      logger.debug(
        '[PlaybackSessionController] Resume verified at $position '
        'for "${request.title}"',
      );
      return;
    }
    // While waiting for the resume point to take effect, never let pre-resume
    // 0s emissions overwrite [_lastPosition], and if the engine has started
    // decoding frames from the beginning, re-issue the seek now that the
    // demuxer is actively playing.
    if (position > Duration.zero && _resumeApplied) {
      final now = _clock();
      final lastAttempt = _lastResumeSeekAt;
      if (lastAttempt == null ||
          now.difference(lastAttempt) >= _resumeRetryCooldown) {
        _lastResumeSeekAt = now;
        logger.debug(
          '[PlaybackSessionController] Re-applying resume seek to '
          '$_resumeTarget (engine at $position)',
        );
        unawaited(_safeSeek(_resumeTarget));
      }
    }
  }

  Future<void> _open(Uri url) async {
    final player = _player;
    if (player == null) {
      return;
    }
    try {
      await player.open(
        url,
        httpHeaders: request.httpHeaders,
        startPosition: _resumeTarget > Duration.zero ? _resumeTarget : null,
      );
      // The screen may have been closed while the open was in flight: a
      // late start report would recreate the session Jellyfin just stopped.
      if (_disposed) {
        return;
      }
      // Never log the full URL: the query string carries the server API key.
      logger.info(
        '[PlaybackSessionController] Opened "${request.title}" '
        '(${url.host}${url.path})',
      );
      _reportStartIfNeeded();
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }
      logger.error(
        '[PlaybackSessionController] Failed to open "${request.title}"',
        error,
        stackTrace,
      );
      errorMessage.value =
          'Could not start playback. Check your connection and try again.';
      _progressTimer?.cancel();
      unawaited(player.pause());
    }
  }

  void _reportStartIfNeeded() {
    if (_startReported) {
      return;
    }
    final reporter = request.reporter;
    if (reporter == null) {
      return;
    }
    _startReported = true;
    // Report the position this open started from, NOT the live position:
    // the engine emits 0 while opening, before the resume seek lands, and
    // reporting that would overwrite the server's resume point with ~0s.
    final position = _resumeTarget;
    unawaited(_safeReport(() => reporter.onStart(position), 'onStart'));
  }

  void _applyResumeIfNeeded() {
    if (_resumeApplied) {
      return;
    }
    _resumeApplied = true;
    _lastResumeSeekAt = _clock();
    final target = _resumeTarget;
    logger.debug(
      '[PlaybackSessionController] Resuming "${request.title}" at $target',
    );
    unawaited(_safeSeek(target));
  }

  void _reportProgressTick() {
    final reporter = request.reporter;
    if (reporter == null ||
        !_playing ||
        _stopReported ||
        errorMessage.value != null) {
      return;
    }
    final position = _lastPosition;
    unawaited(
      _safeReport(
        () => reporter.onProgress(position, isPaused: false),
        'onProgress',
      ),
    );
  }

  Future<void> _handleCompleted(bool completed) async {
    if (!completed || _stopReported) {
      return;
    }
    finished.value = true;
    _progressTimer?.cancel();
    logger.info(
      '[PlaybackSessionController] Playback finished for "${request.title}"',
    );
    await _safeReportStop();
  }

  void _handlePlayerError(String message) {
    final sanitized = SensitiveDataRedactor.redact(message.trim());
    if (_playing || (_player?.duration ?? Duration.zero) > Duration.zero) {
      logger.warning(
        '[PlaybackSessionController] Non-fatal player error: $sanitized',
      );
      return;
    }
    logger.error('[PlaybackSessionController] Player error: $sanitized');
    _progressTimer?.cancel();
    unawaited(_player?.pause());
    errorMessage.value = sanitized.isEmpty
        ? 'Playback failed unexpectedly.'
        : sanitized;
  }

  Future<void> _safeSeek(Duration position) async {
    final player = _player;
    if (player == null) {
      return;
    }
    try {
      await player.seek(position);
    } catch (error, stackTrace) {
      logger.warning(
        '[PlaybackSessionController] Seek to $position failed',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _safeReport(Future<void> Function() report, String label) async {
    try {
      await report();
    } catch (error, stackTrace) {
      logger.warning(
        '[PlaybackSessionController] $label report failed',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _safeReportStop() async {
    if (_stopReported) {
      return;
    }
    _stopReported = true;
    final reporter = request.reporter;
    if (reporter == null) {
      return;
    }
    final position = _lastPosition;
    await _safeReport(() => reporter.onStop(position), 'onStop');
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(progressInterval, (_) {
      _reportProgressTick();
    });
  }
}
