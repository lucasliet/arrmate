import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../playback_request.dart';

/// Immersive overlay with playback controls rendered above the video surface.
///
/// Owns the auto-hide behavior (controls fade out after a few seconds of no
/// interaction while playing) and the audio/subtitle selection sheets.
class PlayerControls extends StatefulWidget {
  /// Creates the controls overlay.
  const PlayerControls({
    super.key,
    required this.title,
    required this.child,
    required this.positionStream,
    required this.bufferStream,
    required this.durationStream,
    required this.playingStream,
    required this.bufferingStream,
    required this.onBack,
    required this.onTogglePlay,
    required this.onSeek,
    required this.onSeekDelta,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
    this.selectedAudioIndex,
    this.selectedSubtitleIndex,
    this.onSelectAudio,
    this.onSelectSubtitle,
    this.qualityLabel,
    this.onToggleQuality,
    this.onOpenExternally,
  });

  /// Media title shown in the top bar.
  final String title;

  /// Video surface rendered beneath the overlay.
  final Widget child;

  /// Playback position updates.
  final Stream<Duration> positionStream;

  /// Buffered-ahead position updates.
  final Stream<Duration> bufferStream;

  /// Total media duration updates.
  final Stream<Duration> durationStream;

  /// Whether playback is currently running.
  final Stream<bool> playingStream;

  /// Whether the engine is currently buffering.
  final Stream<bool> bufferingStream;

  /// Closes the player screen.
  final VoidCallback onBack;

  /// Toggles between playing and paused.
  final VoidCallback onTogglePlay;

  /// Seeks to an absolute position.
  final ValueChanged<Duration> onSeek;

  /// Seeks relative to the current position (e.g. ±10s).
  final ValueChanged<Duration> onSeekDelta;

  /// Selectable audio tracks; empty hides the audio button.
  final List<AudioTrackOption> audioTracks;

  /// Selectable subtitle tracks; empty hides the subtitle button.
  final List<SubtitleTrackOption> subtitleTracks;

  /// Index of the currently selected audio track, if any.
  final int? selectedAudioIndex;

  /// Index of the currently selected subtitle track (`null` = disabled).
  final int? selectedSubtitleIndex;

  /// Applies an audio track selection.
  final ValueChanged<AudioTrackOption>? onSelectAudio;

  /// Applies a subtitle selection; `null` disables subtitles.
  final ValueChanged<SubtitleTrackOption?>? onSelectSubtitle;

  /// Label of the current quality mode; non-null enables the quality toggle.
  final String? qualityLabel;

  /// Toggles between the original stream and the data saver (HLS) stream.
  final VoidCallback? onToggleQuality;

  /// Opens the media in an external player; null hides the button.
  final VoidCallback? onOpenExternally;

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  static const _hideDelay = Duration(seconds: 3);
  static const _seekStep = Duration(seconds: 10);
  static const _fadeDuration = Duration(milliseconds: 200);

  final _topGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.black87, Colors.transparent],
  );
  final _bottomGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.black87],
  );

  StreamSubscription<bool>? _playingSubscription;
  Timer? _hideTimer;
  bool _visible = true;
  bool _playing = false;
  bool _dragging = false;
  Duration _dragValue = Duration.zero;

  @override
  void initState() {
    super.initState();
    _playingSubscription = widget.playingStream.listen((playing) {
      if (!mounted) {
        return;
      }
      _playing = playing;
      if (playing && _visible) {
        _scheduleHide();
      } else {
        _hideTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _playingSubscription?.cancel();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _visible = !_visible);
    if (_visible) {
      _scheduleHide();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (mounted && _playing) {
        setState(() => _visible = false);
      }
    });
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    final width = MediaQuery.sizeOf(context).width;
    final forward = details.localPosition.dx > width / 2;
    widget.onSeekDelta(forward ? _seekStep : -_seekStep);
    _scheduleHide();
  }

  Future<void> _showAudioSheet() async {
    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => RadioGroup<int>(
        groupValue: widget.selectedAudioIndex,
        onChanged: (value) => Navigator.pop(sheetContext, value),
        child: SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in widget.audioTracks)
                RadioListTile<int>(
                  value: option.index,
                  title: Text(option.label),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selectedIndex == null) {
      return;
    }
    for (final option in widget.audioTracks) {
      if (option.index == selectedIndex) {
        widget.onSelectAudio?.call(option);
        break;
      }
    }
    _scheduleHide();
  }

  Future<void> _showSubtitleSheet() async {
    final groupValue = widget.selectedSubtitleIndex ?? -1;
    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => RadioGroup<int>(
        groupValue: groupValue,
        onChanged: (value) => Navigator.pop(sheetContext, value),
        child: SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              RadioListTile<int>(
                value: -1,
                title: Text(sheetContext.l10n.playerSubtitlesDisabled),
              ),
              for (final option in widget.subtitleTracks)
                RadioListTile<int>(
                  value: option.index,
                  title: Text(option.label),
                  subtitle: option.isExternal
                      ? Text(sheetContext.l10n.playerSubtitleExternal)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selectedIndex == null) {
      return;
    }
    if (selectedIndex == -1) {
      widget.onSelectSubtitle?.call(null);
    } else {
      for (final option in widget.subtitleTracks) {
        if (option.index == selectedIndex) {
          widget.onSelectSubtitle?.call(option);
          break;
        }
      }
    }
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          onDoubleTapDown: _handleDoubleTapDown,
          onDoubleTap: () {},
          child: const SizedBox.expand(),
        ),
        StreamBuilder<bool>(
          stream: widget.bufferingStream,
          builder: (context, snapshot) {
            if (snapshot.data ?? false) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !_visible,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: _fadeDuration,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: _topGradient),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: paddingSm,
                      vertical: paddingXs,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.white,
                        ),
                        const SizedBox(width: paddingXs),
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: IgnorePointer(
            ignoring: !_visible,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: _fadeDuration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => widget.onSeekDelta(-_seekStep),
                    icon: const Icon(Icons.replay_10),
                    iconSize: 32,
                    color: Colors.white,
                  ),
                  const SizedBox(width: paddingLg),
                  StreamBuilder<bool>(
                    stream: widget.playingStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data ?? false;
                      return IconButton(
                        onPressed: widget.onTogglePlay,
                        icon: Icon(
                          playing
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                        ),
                        iconSize: 64,
                        color: Colors.white,
                      );
                    },
                  ),
                  const SizedBox(width: paddingLg),
                  IconButton(
                    onPressed: () => widget.onSeekDelta(_seekStep),
                    icon: const Icon(Icons.forward_10),
                    iconSize: 32,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !_visible,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: _fadeDuration,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: _bottomGradient),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      paddingMd,
                      paddingXs,
                      paddingMd,
                      paddingSm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [_buildSeekRow(), _buildActionsRow(theme)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeekRow() {
    return StreamBuilder<Duration>(
      stream: widget.durationStream,
      builder: (context, durationSnapshot) {
        final duration = _positive(durationSnapshot.data);
        final maxMs = duration.inMilliseconds.toDouble();
        return StreamBuilder<Duration>(
          stream: widget.bufferStream,
          builder: (context, bufferSnapshot) {
            final buffer = _positive(bufferSnapshot.data);
            return StreamBuilder<Duration>(
              stream: widget.positionStream,
              builder: (context, positionSnapshot) {
                final sliderValue = _dragging
                    ? _dragValue
                    : _positive(positionSnapshot.data);
                return Row(
                  children: [
                    Text(
                      _formatDuration(sliderValue),
                      style: const TextStyle(color: Colors.white),
                    ),
                    Expanded(
                      child: Slider(
                        value: _clampMs(sliderValue, maxMs),
                        max: maxMs,
                        secondaryTrackValue: _clampMs(buffer, maxMs),
                        onChanged: maxMs <= 0
                            ? null
                            : (value) {
                                _hideTimer?.cancel();
                                setState(() {
                                  _dragging = true;
                                  _dragValue = Duration(
                                    milliseconds: value.round(),
                                  );
                                });
                              },
                        onChangeEnd: (value) {
                          setState(() => _dragging = false);
                          widget.onSeek(Duration(milliseconds: value.round()));
                          _scheduleHide();
                        },
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActionsRow(ThemeData theme) {
    final hasActions =
        widget.audioTracks.isNotEmpty ||
        widget.subtitleTracks.isNotEmpty ||
        widget.onToggleQuality != null ||
        widget.onOpenExternally != null;
    if (!hasActions) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        if (widget.audioTracks.isNotEmpty)
          IconButton(
            onPressed: _showAudioSheet,
            icon: const Icon(Icons.audiotrack),
            tooltip: context.l10n.playerAudio,
            color: Colors.white,
          ),
        if (widget.subtitleTracks.isNotEmpty)
          IconButton(
            onPressed: _showSubtitleSheet,
            icon: const Icon(Icons.subtitles_outlined),
            tooltip: context.l10n.widgetsFileSubtitles,
            color: Colors.white,
          ),
        if (widget.onToggleQuality != null)
          IconButton(
            onPressed: widget.onToggleQuality,
            icon: const Icon(Icons.high_quality),
            tooltip: context.l10n.playerQualityTooltip(
              widget.qualityLabel ?? '',
            ),
            color: Colors.white,
          ),
        const Spacer(),
        if (widget.onOpenExternally != null)
          IconButton(
            onPressed: widget.onOpenExternally,
            icon: const Icon(Icons.open_in_new),
            tooltip: context.l10n.commonOpenExternally,
            color: Colors.white,
          ),
      ],
    );
  }

  static Duration _positive(Duration? value) {
    final duration = value ?? Duration.zero;
    return duration < Duration.zero ? Duration.zero : duration;
  }

  static double _clampMs(Duration value, double maxMs) {
    if (maxMs <= 0) {
      return 0;
    }
    return value.inMilliseconds.toDouble().clamp(0, maxMs);
  }

  /// Formats a duration as `mm:ss` or `h:mm:ss`.
  static String _formatDuration(Duration duration) {
    final safe = _positive(duration);
    String two(int value) => value.toString().padLeft(2, '0');
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    final seconds = safe.inSeconds.remainder(60);
    final mmss = '${two(minutes)}:${two(seconds)}';
    return hours > 0 ? '$hours:$mmss' : mmss;
  }
}
