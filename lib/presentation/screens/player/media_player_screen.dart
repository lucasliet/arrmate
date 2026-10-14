import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/platform/platform_capabilities.dart';
import '../../../../core/services/logger_service.dart';
import '../activity/providers/watching_provider.dart';
import 'playback_request.dart';
import 'playback_session_controller.dart';
import 'providers/player_providers.dart';
import 'widgets/player_controls.dart';
import 'widgets/player_video_surface.dart';

/// Path segment prefixing every media server stream route.
const String _videosPathSegment = '/Videos/';

/// Builds the absolute URL for an externally delivered subtitle file.
///
/// [deliveryPath] is the media server's subtitle delivery URL: either already
/// absolute (`http(s)://...`) or server relative (for example
/// `/Videos/{id}/{mediaSourceId}/Subtitles/{index}/0/Stream.vtt`), possibly
/// carrying its own query string.
///
/// Relative paths are resolved against [streamUrl], keeping its origin and
/// any reverse-proxy base path prefix (e.g. `/jellyfin` in
/// `/jellyfin/Videos/{id}/stream`). Query parameters start from [streamUrl]'s
/// (which carries the required `ApiKey`) and are overlaid with the delivery
/// path's own parameters; the stream URL's `ApiKey` wins when both carry
/// one. Returns `null` when [deliveryPath] is not a valid absolute URI.
Uri? buildAbsoluteSubtitleUri(Uri streamUrl, String deliveryPath) {
  if (deliveryPath.startsWith('http://') ||
      deliveryPath.startsWith('https://')) {
    return Uri.tryParse(deliveryPath);
  }
  final queryStart = deliveryPath.indexOf('?');
  final subPath = queryStart < 0
      ? deliveryPath
      : deliveryPath.substring(0, queryStart);
  final subQuery = queryStart < 0
      ? const <String, String>{}
      : Uri.splitQueryString(deliveryPath.substring(queryStart + 1));

  final streamQuery = streamUrl.queryParameters;
  final queryParameters = <String, String>{
    ...streamQuery,
    // The stream URL's ApiKey authenticates the whole session, so it must
    // not be replaced by the delivery path's possibly stale copy (matched
    // case-insensitively: servers may still emit the legacy casing).
    for (final entry in subQuery.entries)
      if (entry.key.toLowerCase() != 'apikey' ||
          !streamQuery.keys.any((k) => k.toLowerCase() == 'apikey'))
        entry.key: entry.value,
  };

  final basePath = _reverseProxyBasePath(streamUrl.path);
  final normalizedPath = subPath.startsWith('/') ? subPath : '/$subPath';
  return streamUrl.replace(
    path: '$basePath$normalizedPath',
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  );
}

/// Returns the reverse-proxy base path of a media server [streamPath].
///
/// Everything before the `/Videos/` segment (e.g. `/jellyfin` in
/// `/jellyfin/Videos/{id}/stream`) is the reverse-proxy base path. Returns an
/// empty string when the path is already rooted at `/Videos/` or carries no
/// recognizable marker.
String _reverseProxyBasePath(String streamPath) {
  final videosIndex = streamPath.indexOf(_videosPathSegment);
  if (videosIndex <= 0) {
    return '';
  }
  return streamPath.substring(0, videosIndex);
}

/// Fullscreen in-app video player.
///
/// Rendered in the root navigator so it overlays the app shell. When the
/// platform cannot host the internal player (web), a fallback view explains
/// the limitation and offers opening the media externally when the request
/// provides an external URL.
class MediaPlayerScreen extends ConsumerStatefulWidget {
  /// Creates a player screen for [request].
  ///
  /// [playerFactory] overrides the engine used to build the [StreamPlayer];
  /// production resolves it from [streamPlayerFactoryProvider] while tests
  /// inject fakes (media_kit must never be constructed headless).
  const MediaPlayerScreen({
    super.key,
    required this.request,
    this.playerFactory,
  });

  /// The media to play.
  final PlaybackRequest request;

  /// Optional engine factory overriding the default media_kit one.
  final StreamPlayer Function()? playerFactory;

  @override
  ConsumerState<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends ConsumerState<MediaPlayerScreen> {
  late final ProviderContainer _container;
  PlaybackSessionController? _controller;
  late final PlatformCapabilities _capabilities = ref.read(
    platformCapabilitiesProvider,
  );
  late final bool _isMobilePlatform =
      !_capabilities.isWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  bool _canOpenExternally = false;
  bool _useDataSaver = false;
  int? _selectedAudioIndex;
  int? _selectedSubtitleIndex;

  /// External hand-off URL, or `null` when the request does not allow
  /// launching externally.
  ///
  /// Deliberately never falls back to [PlaybackRequest.streamUrl]: the stream
  /// URL embeds the server API key and must not leave the app.
  Uri? get _externalUri {
    final externalUrl = widget.request.externalUrl;
    if (externalUrl == null) {
      return null;
    }
    return Uri.tryParse(externalUrl);
  }

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    if (!_capabilities.supportsInternalVideoPlayer) {
      _probeExternalLaunch();
      return;
    }
    final controller = PlaybackSessionController(
      request: widget.request,
      playerFactory:
          widget.playerFactory ?? ref.read(streamPlayerFactoryProvider),
    );
    _controller = controller;
    controller.finished.addListener(_handleFinished);
    unawaited(controller.initialize());
    if (_isMobilePlatform) {
      // Prefer landscape and immersive mode while the player is open.
      unawaited(
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
      );
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
      );
    }
    _probeExternalLaunch();
  }

  @override
  void dispose() {
    _refreshWatchingList();
    _controller?.finished.removeListener(_handleFinished);
    unawaited(_controller?.dispose());
    if (_isMobilePlatform) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
      unawaited(
        SystemChrome.setPreferredOrientations(DeviceOrientation.values),
      );
    }
    super.dispose();
  }

  /// Reloads Continue Watching after this route leaves the tree.
  ///
  /// Disposal covers browser Back, the in-app back control, and a normal pop.
  /// Browser Back on web removes the route without completing the future
  /// returned by `GoRouter.push`, so the refresh cannot wait on that future.
  void _refreshWatchingList() {
    _container.invalidate(watchingItemsProvider);
  }

  void _handleFinished() {
    if (!(_controller?.finished.value ?? false) || !mounted) {
      return;
    }
    context.pop();
  }

  Future<void> _probeExternalLaunch() async {
    final uri = _externalUri;
    // Without an explicit externalUrl there is nothing safe to probe: the
    // stream URL (which carries the ApiKey) must never be launched outside.
    if (uri == null) {
      return;
    }
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (mounted) {
        setState(() => _canOpenExternally = canLaunch);
      }
    } catch (error, stackTrace) {
      logger.warning(
        '[MediaPlayerScreen] Cannot launch ${uri.host}${uri.path}',
        error,
        stackTrace,
      );
      if (mounted) {
        setState(() => _canOpenExternally = false);
      }
    }
  }

  Future<void> _openExternally() async {
    final uri = _externalUri;
    if (uri == null) {
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, stackTrace) {
      logger.warning(
        '[MediaPlayerScreen] Failed to open ${uri.host}${uri.path} externally',
        error,
        stackTrace,
      );
      if (mounted) {
        context.showErrorSnackBar('Could not open an external player');
      }
    }
  }

  Future<void> _selectAudioOption(AudioTrackOption option) async {
    final player = _controller?.player;
    if (player == null) {
      return;
    }
    // The server's stream indexes do not map 1:1 onto engine track ids, so
    // match by label first and fall back to the option's ordering.
    final discovered = await player.discoverAudioTracks();
    final ordinal = widget.request.audioTracks.indexOf(option);
    final match = matchDiscoveredTrack(
      discovered: discovered,
      label: option.label,
      ordinal: ordinal,
    );
    if (match == null) {
      logger.warning(
        '[MediaPlayerScreen] No engine audio track matches "${option.label}"',
      );
      return;
    }
    await player.selectAudioTrackId(match.id);
    if (mounted) {
      setState(() => _selectedAudioIndex = option.index);
    }
  }

  Future<void> _selectSubtitleOption(SubtitleTrackOption? option) async {
    final player = _controller?.player;
    if (player == null) {
      return;
    }
    if (option == null) {
      await player.selectEmbeddedSubtitleTrack(null);
    } else if (option.isExternal && option.deliveryPath != null) {
      // External subtitles are delivered by the media server at a server
      // relative path; buildAbsoluteSubtitleUri resolves it against the
      // stream URL while preserving the reverse-proxy base path and the
      // authenticated ApiKey query parameter.
      final absolute = buildAbsoluteSubtitleUri(
        widget.request.streamUrl,
        option.deliveryPath!,
      );
      if (absolute != null) {
        await player.selectExternalSubtitleTrack(absolute);
      }
    } else {
      final discovered = await player.discoverSubtitleTracks();
      final embeddedOptions = widget.request.subtitleTracks
          .where((track) => !track.isExternal)
          .toList();
      final ordinal = embeddedOptions.indexOf(option);
      final match = matchDiscoveredTrack(
        discovered: discovered,
        label: option.label,
        ordinal: ordinal,
      );
      if (match == null) {
        logger.warning(
          '[MediaPlayerScreen] No engine subtitle track matches '
          '"${option.label}"',
        );
        return;
      }
      await player.selectEmbeddedSubtitleTrack(match.id);
    }
    if (mounted) {
      setState(() => _selectedSubtitleIndex = option?.index);
    }
  }

  Future<void> _toggleQuality() async {
    final controller = _controller;
    if (controller == null || widget.request.hlsUrl == null) {
      return;
    }
    setState(() => _useDataSaver = !_useDataSaver);
    final nextSource = _useDataSaver
        ? widget.request.hlsUrl!
        : widget.request.streamUrl;
    await controller.switchSource(nextSource);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_capabilities.supportsInternalVideoPlayer || controller == null) {
      return _UnsupportedPlaybackView(
        canOpenExternally: _canOpenExternally,
        onOpenExternally: _openExternally,
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: ValueListenableBuilder<String?>(
        valueListenable: controller.errorMessage,
        builder: (context, errorMessage, _) {
          if (errorMessage != null) {
            return _PlaybackErrorView(
              message: errorMessage,
              onRetry: () => unawaited(controller.retry()),
              onBack: () => context.pop(),
            );
          }
          final player = controller.player;
          if (player == null) {
            return const ColoredBox(color: Colors.black);
          }
          return PlayerControls(
            title: widget.request.title,
            positionStream: player.positionStream,
            bufferStream: player.bufferStream,
            durationStream: player.durationStream,
            playingStream: player.playingStream,
            bufferingStream: player.bufferingStream,
            onBack: () => context.pop(),
            onTogglePlay: () => unawaited(player.togglePlayPause()),
            onSeek: (position) => unawaited(controller.seekTo(position)),
            onSeekDelta: (delta) => unawaited(controller.seekBy(delta)),
            audioTracks: widget.request.audioTracks,
            subtitleTracks: widget.request.subtitleTracks,
            selectedAudioIndex: _selectedAudioIndex,
            selectedSubtitleIndex: _selectedSubtitleIndex,
            onSelectAudio: (option) => unawaited(_selectAudioOption(option)),
            onSelectSubtitle: (option) =>
                unawaited(_selectSubtitleOption(option)),
            qualityLabel: widget.request.hlsUrl == null
                ? null
                : (_useDataSaver ? 'Data saver' : 'Original'),
            onToggleQuality: widget.request.hlsUrl == null
                ? null
                : () => unawaited(_toggleQuality()),
            onOpenExternally: _canOpenExternally && _externalUri != null
                ? _openExternally
                : null,
            child: PlayerVideoSurface(player: player),
          );
        },
      ),
    );
  }
}

/// Fallback shown on platforms without in-app playback support (web).
class _UnsupportedPlaybackView extends StatelessWidget {
  const _UnsupportedPlaybackView({
    required this.canOpenExternally,
    required this.onOpenExternally,
  });

  final bool canOpenExternally;
  final VoidCallback onOpenExternally;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(paddingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_disabled_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: paddingMd),
              Text(
                'In-app playback is not supported on the web yet',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              if (canOpenExternally) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onOpenExternally,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open externally'),
                ),
              ] else ...[
                const SizedBox(height: paddingSm),
                Text(
                  'Opening this media in an external player is not available '
                  'for the current server configuration.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error view with a Retry action shown when the engine fails mid-session.
class _PlaybackErrorView extends StatelessWidget {
  const _PlaybackErrorView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(paddingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: paddingLg),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(onPressed: onBack, child: const Text('Back')),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
