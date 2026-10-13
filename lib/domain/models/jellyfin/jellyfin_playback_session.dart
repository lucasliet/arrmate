import 'package:equatable/equatable.dart';

import 'jellyfin_media_stream.dart';

/// A ready-to-play stream for a Jellyfin item, as built by the service.
class JellyfinPlaybackSession extends Equatable {
  /// Jellyfin id of the played item.
  final String itemId;

  /// Jellyfin id of the picked media source.
  final String mediaSourceId;

  /// Absolute primary stream URL, including `ApiKey` when a token is
  /// available.
  ///
  /// Direct Play (`static=true`) unless the caller requested a bitrate cap,
  /// in which case this is the HLS master playlist.
  final Uri streamUrl;

  /// Transcoding alternative reserved for players that need to switch to
  /// HLS; null when the service did not produce one.
  final Uri? hlsUrl;

  /// Auth headers the player must send alongside [streamUrl].
  final Map<String, String> httpHeaders;

  /// Resume position reported by Jellyfin for this item.
  final Duration playbackPosition;

  /// Audio tracks available for the session.
  final List<JellyfinMediaStream> audioStreams;

  /// Subtitle tracks (internal and external) available for the session.
  ///
  /// External tracks carry a Jellyfin-relative [JellyfinMediaStream.deliveryUrl]
  /// that the player must resolve against the server base URL.
  final List<JellyfinMediaStream> subtitleStreams;

  /// Creates a playback session description.
  const JellyfinPlaybackSession({
    required this.itemId,
    required this.mediaSourceId,
    required this.streamUrl,
    this.hlsUrl,
    this.httpHeaders = const {},
    this.playbackPosition = Duration.zero,
    this.audioStreams = const [],
    this.subtitleStreams = const [],
  });

  @override
  List<Object?> get props => [
    itemId,
    mediaSourceId,
    streamUrl,
    hlsUrl,
    httpHeaders,
    playbackPosition,
    audioStreams,
    subtitleStreams,
  ];
}
