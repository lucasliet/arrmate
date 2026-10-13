import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../media_kit_stream_player.dart';
import '../playback_session_controller.dart';

/// Creates the [StreamPlayer] engine used by the in-app player screen.
///
/// Exposed as a provider so tests can override the engine without touching
/// media_kit (which must never be constructed in headless tests).
final streamPlayerFactoryProvider = Provider<StreamPlayer Function()>(
  (ref) => createMediaKitStreamPlayer,
);
