import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../media_kit_stream_player.dart';
import '../playback_session_controller.dart';

/// Renders the video output of a [StreamPlayer].
///
/// Only the media_kit-backed player can render video; other implementations
/// (e.g. test fakes) fall back to an empty surface.
class PlayerVideoSurface extends StatelessWidget {
  /// Creates a video surface for [player].
  const PlayerVideoSurface({super.key, required this.player});

  /// The player whose video output is rendered.
  final StreamPlayer player;

  @override
  Widget build(BuildContext context) {
    final mediaKitPlayer = player;
    if (mediaKitPlayer is MediaKitStreamPlayer) {
      return Video(controller: mediaKitPlayer.videoController);
    }
    return const SizedBox.expand();
  }
}
