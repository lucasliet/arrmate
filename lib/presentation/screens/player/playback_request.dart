import 'package:equatable/equatable.dart';

/// Reports playback progress back to the media server integration.
///
/// The in-app player invokes these callbacks at well-defined points of a
/// session. Implementations are provided by the media-server layer (e.g.
/// Jellyfin), keeping the player decoupled from any specific server.
abstract class PlaybackProgressReporter {
  /// Creates a reporter.
  const PlaybackProgressReporter();

  /// Called once when playback successfully starts.
  ///
  /// [position] is the initial playback position, which equals the resume
  /// position when a resume point was supplied.
  Future<void> onStart(Duration position);

  /// Called periodically while playback is running (roughly every 10s).
  ///
  /// Not called while playback is paused.
  Future<void> onProgress(Duration position, {required bool isPaused});

  /// Called once when playback ends, either because the media finished or
  /// because the player screen was closed.
  Future<void> onStop(Duration position);
}

/// A selectable audio track offered by the player screen.
class AudioTrackOption extends Equatable {
  /// Creates an audio track option.
  const AudioTrackOption({required this.index, required this.label});

  /// Media server stream index used as a stable selection key.
  final int index;

  /// Human readable description (language/codec/title) shown in the UI.
  final String label;

  @override
  List<Object?> get props => [index, label];
}

/// A selectable subtitle track offered by the player screen.
class SubtitleTrackOption extends Equatable {
  /// Creates a subtitle track option.
  const SubtitleTrackOption({
    required this.index,
    required this.label,
    this.isExternal = false,
    this.deliveryPath,
  });

  /// Media server stream index, or `-1` for the "disabled" pseudo option.
  final int index;

  /// Human readable description (language/format/title) shown in the UI.
  final String label;

  /// Whether the subtitle file lives outside the media container and must be
  /// loaded from a separate URL.
  final bool isExternal;

  /// Media-server-relative URL of an external subtitle file (for example
  /// `/Videos/{id}/{mediaSourceId}/Subtitles/{index}/0/Stream.vtt`).
  ///
  /// The player screen builds the absolute URL by taking the origin of
  /// [PlaybackRequest.streamUrl] (keeping its query, which carries the API
  /// key) and replacing the path with this value.
  final String? deliveryPath;

  @override
  List<Object?> get props => [index, label, isExternal, deliveryPath];
}

/// Describes a piece of media to be played by the in-app player.
class PlaybackRequest extends Equatable {
  /// Creates a playback request.
  const PlaybackRequest({
    required this.title,
    required this.streamUrl,
    this.hlsUrl,
    this.httpHeaders = const {},
    this.resumePosition = Duration.zero,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
    this.externalUrl,
    this.reporter,
  });

  /// Display title (`Movie Title` or `S01E02 · Episode`).
  final String title;

  /// Direct play URL; already contains any required authentication (ApiKey).
  final Uri streamUrl;

  /// Transcoding (HLS) alternative used by the "Data saver" quality toggle.
  final Uri? hlsUrl;

  /// HTTP headers required to fetch the stream (e.g. authorization tokens).
  final Map<String, String> httpHeaders;

  /// Position to resume from; [Duration.zero] when starting from scratch.
  final Duration resumePosition;

  /// Selectable audio tracks; empty when there is nothing to choose from.
  final List<AudioTrackOption> audioTracks;

  /// Selectable subtitle tracks; empty when none are available.
  final List<SubtitleTrackOption> subtitleTracks;

  /// URL to open in an external player or browser as a fallback.
  final String? externalUrl;

  /// Progress reporter; `null` disables progress reporting.
  final PlaybackProgressReporter? reporter;

  @override
  List<Object?> get props => [
    title,
    streamUrl,
    hlsUrl,
    httpHeaders,
    resumePosition,
    audioTracks,
    subtitleTracks,
    externalUrl,
    reporter,
  ];
}
