import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'playback_session_controller.dart';

/// [StreamPlayer] implementation backed by media_kit.
///
/// Track selection strategy for media-server track options:
/// the server reports absolute stream indexes that do not map 1:1 onto the
/// engine's per-type track ids, so the screen matches options against the
/// tracks discovered here via [matchDiscoveredTrack] (label first, ordering
/// fallback) and then selects by engine id.
class MediaKitStreamPlayer implements StreamPlayer {
  /// Creates a player. [player] is injectable for advanced setups.
  MediaKitStreamPlayer({Player? player}) : _player = player ?? Player();

  final Player _player;

  /// Video renderer bound to the underlying player.
  late final VideoController videoController = VideoController(_player);

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Stream<Duration> get bufferStream => _player.stream.buffer;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  @override
  Stream<bool> get playingStream => _player.stream.playing;

  @override
  Stream<bool> get bufferingStream => _player.stream.buffering;

  @override
  Stream<bool> get completedStream => _player.stream.completed;

  @override
  Stream<String> get errorStream => _player.stream.error;

  @override
  Duration get position => _player.state.position;

  @override
  Duration get duration => _player.state.duration;

  @override
  Future<void> open(
    Uri url, {
    Map<String, String> httpHeaders = const {},
    Duration? startPosition,
  }) {
    return _player.open(
      Media(
        url.toString(),
        httpHeaders: httpHeaders,
        start: startPosition != null && startPosition > Duration.zero
            ? startPosition
            : null,
      ),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> togglePlayPause() => _player.playOrPause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<List<PlayerTrack>> discoverAudioTracks() async => [
    for (final track in _player.state.tracks.audio)
      if (_isSelectable(track.id))
        PlayerTrack(id: track.id, title: track.title, language: track.language),
  ];

  @override
  Future<List<PlayerTrack>> discoverSubtitleTracks() async => [
    for (final track in _player.state.tracks.subtitle)
      if (_isSelectable(track.id))
        PlayerTrack(
          id: track.id,
          title: track.title,
          language: track.language,
          isExternal: track.uri,
        ),
  ];

  @override
  Future<void> selectAudioTrackId(String trackId) async {
    AudioTrack match = AudioTrack.auto();
    for (final track in _player.state.tracks.audio) {
      if (track.id == trackId) {
        match = track;
        break;
      }
    }
    await _player.setAudioTrack(match);
  }

  @override
  Future<void> selectEmbeddedSubtitleTrack(String? trackId) async {
    if (trackId == null) {
      await _player.setSubtitleTrack(SubtitleTrack.no());
      return;
    }
    SubtitleTrack match = SubtitleTrack.no();
    for (final track in _player.state.tracks.subtitle) {
      if (track.id == trackId) {
        match = track;
        break;
      }
    }
    await _player.setSubtitleTrack(match);
  }

  @override
  Future<void> selectExternalSubtitleTrack(Uri subtitleUri) {
    return _player.setSubtitleTrack(SubtitleTrack.uri(subtitleUri.toString()));
  }

  @override
  Future<void> dispose() => _player.dispose();

  /// media_kit exposes `auto`/`no` pseudo tracks that must never be offered
  /// as selectable options.
  static bool _isSelectable(String trackId) =>
      trackId != 'auto' && trackId != 'no';
}

/// Creates the default media_kit-backed player used in production.
StreamPlayer createMediaKitStreamPlayer() => MediaKitStreamPlayer();
