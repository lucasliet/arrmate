import 'dart:async';

import 'package:arrmate/presentation/screens/player/playback_request.dart';
import 'package:arrmate/presentation/screens/player/playback_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fully in-memory [StreamPlayer] with controllable streams; no native media
/// libraries are ever constructed.
class FakeStreamPlayer implements StreamPlayer {
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _bufferingController = StreamController<bool>.broadcast();
  final _completedController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  final openedUrls = <Uri>[];
  final openedHeaders = <Map<String, String>>[];
  final openedStartPositions = <Duration?>[];
  final seeks = <Duration>[];
  int pauseCount = 0;
  bool failOpen = false;
  bool disposed = false;

  /// When set, [open] waits for it, letting the test interleave engine
  /// emissions mid-open (reproduces the native position race).
  Completer<void>? openGate;

  @override
  Duration position = Duration.zero;

  @override
  Duration duration = Duration.zero;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get bufferStream => _bufferController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<bool> get playingStream => _playingController.stream;

  @override
  Stream<bool> get bufferingStream => _bufferingController.stream;

  @override
  Stream<bool> get completedStream => _completedController.stream;

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  Future<void> open(
    Uri url, {
    Map<String, String> httpHeaders = const {},
    Duration? startPosition,
  }) async {
    openedUrls.add(url);
    openedHeaders.add(httpHeaders);
    openedStartPositions.add(startPosition);
    if (failOpen) {
      throw Exception('simulated open failure');
    }
    final gate = openGate;
    if (gate != null) {
      await gate.future;
    }
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {
    pauseCount++;
  }

  @override
  Future<void> togglePlayPause() async {}

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    this.position = position;
  }

  @override
  Future<List<PlayerTrack>> discoverAudioTracks() async => const [];

  @override
  Future<List<PlayerTrack>> discoverSubtitleTracks() async => const [];

  @override
  Future<void> selectAudioTrackId(String trackId) async {}

  @override
  Future<void> selectEmbeddedSubtitleTrack(String? trackId) async {}

  @override
  Future<void> selectExternalSubtitleTrack(Uri subtitleUri) async {}

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  void emitPosition(Duration value) => _positionController.add(value);

  void emitBuffer(Duration value) => _bufferController.add(value);

  void emitDuration(Duration value) {
    duration = value;
    _durationController.add(value);
  }

  void emitPlaying(bool value) => _playingController.add(value);

  void emitCompleted(bool value) => _completedController.add(value);

  void emitError(String message) => _errorController.add(message);
}

/// [PlaybackProgressReporter] recording every call for assertions.
class FakeReporter extends PlaybackProgressReporter {
  final starts = <Duration>[];
  final progresses = <({Duration position, bool isPaused})>[];
  final stops = <Duration>[];

  @override
  Future<void> onStart(Duration position) async {
    starts.add(position);
  }

  @override
  Future<void> onProgress(Duration position, {required bool isPaused}) async {
    progresses.add((position: position, isPaused: isPaused));
  }

  @override
  Future<void> onStop(Duration position) async {
    stops.add(position);
  }
}

PlaybackRequest _buildRequest({
  Duration resumePosition = Duration.zero,
  PlaybackProgressReporter? reporter,
}) {
  return PlaybackRequest(
    title: 'Test Media',
    streamUrl: Uri.parse('http://server.example/Videos/1/stream'),
    httpHeaders: const {'Authorization': 'MediaBrowser token="secret"'},
    resumePosition: resumePosition,
    reporter: reporter,
  );
}

void main() {
  group('PlaybackSessionController', () {
    test('seekTo tracks the target so an immediate exit reports it', () async {
      // Given
      final player = FakeStreamPlayer();
      final reporter = FakeReporter();
      final controller = PlaybackSessionController(
        request: _buildRequest(reporter: reporter),
        playerFactory: () => player,
        progressInterval: const Duration(hours: 1),
      );
      await controller.initialize();
      await pumpEventQueue();

      // When
      await controller.seekTo(const Duration(minutes: 9, seconds: 25));
      await controller.dispose();

      // Then
      expect(player.seeks, [const Duration(minutes: 9, seconds: 25)]);
      expect(reporter.stops, [const Duration(minutes: 9, seconds: 25)]);
    });

    test('seekBy moves relative to the last known position', () async {
      // Given
      final player = FakeStreamPlayer();
      final controller = PlaybackSessionController(
        request: _buildRequest(),
        playerFactory: () => player,
        progressInterval: const Duration(hours: 1),
      );
      await controller.initialize();
      await pumpEventQueue();
      player.emitPosition(const Duration(minutes: 5));
      await pumpEventQueue();

      // When
      await controller.seekBy(const Duration(seconds: 10));
      await controller.seekBy(-const Duration(minutes: 10));

      // Then
      expect(player.seeks, [
        const Duration(minutes: 5, seconds: 10),
        Duration.zero,
      ]);
      expect(controller.position, Duration.zero);

      await controller.dispose();
    });

    test(
      'onStart reports the resume position despite a zero emission mid-open',
      () async {
        // Given
        final player = FakeStreamPlayer()..openGate = Completer<void>();
        final reporter = FakeReporter();
        final controller = PlaybackSessionController(
          request: _buildRequest(
            resumePosition: const Duration(minutes: 48, seconds: 35),
            reporter: reporter,
          ),
          playerFactory: () => player,
          progressInterval: const Duration(hours: 1),
        );

        // When
        final initializing = controller.initialize();
        // The engine emits 0 while opening, before the resume seek lands.
        player.emitPosition(Duration.zero);
        await pumpEventQueue();
        player.openGate!.complete();
        await initializing;
        await pumpEventQueue();

        // Then
        expect(reporter.starts, [const Duration(minutes: 48, seconds: 35)]);

        await controller.dispose();
      },
    );

    test('opens the stream with headers and reports start once', () async {
      // Given
      final player = FakeStreamPlayer();
      final reporter = FakeReporter();
      final request = _buildRequest(
        resumePosition: const Duration(seconds: 90),
        reporter: reporter,
      );
      final controller = PlaybackSessionController(
        request: request,
        playerFactory: () => player,
        progressInterval: const Duration(hours: 1),
      );

      // When
      await controller.initialize();
      await pumpEventQueue();

      // Then
      expect(player.openedUrls, [request.streamUrl]);
      expect(player.openedHeaders.single, request.httpHeaders);
      expect(player.openedStartPositions, [const Duration(seconds: 90)]);
      expect(reporter.starts, [const Duration(seconds: 90)]);
      expect(reporter.stops, isEmpty);

      await controller.dispose();
      expect(reporter.starts.length, 1);
    });

    test('ignores zero buffer and duration resets during open', () async {
      // Given
      final player = FakeStreamPlayer()..openGate = Completer<void>();
      final reporter = FakeReporter();
      final controller = PlaybackSessionController(
        request: _buildRequest(
          resumePosition: const Duration(minutes: 52, seconds: 36),
          reporter: reporter,
        ),
        playerFactory: () => player,
        progressInterval: const Duration(hours: 1),
      );

      // When: media_kit's stop(open: true) emits 0s on position, duration
      // and buffer before loadlist runs.
      final initializing = controller.initialize();
      player.emitPosition(Duration.zero);
      player.emitDuration(Duration.zero);
      player.emitBuffer(Duration.zero);
      await pumpEventQueue();
      player.openGate!.complete();
      await initializing;
      await pumpEventQueue();

      // Then: the 0s reset must not consume the resume seek.
      expect(player.seeks, isEmpty);

      await controller.dispose();
    });

    test(
      'seeks to the resume position when real duration arrives after zero resets',
      () async {
        // Given
        final player = FakeStreamPlayer()..openGate = Completer<void>();
        final reporter = FakeReporter();
        final controller = PlaybackSessionController(
          request: _buildRequest(
            resumePosition: const Duration(minutes: 52, seconds: 36),
            reporter: reporter,
          ),
          playerFactory: () => player,
          progressInterval: const Duration(hours: 1),
        );
        final initializing = controller.initialize();
        player.emitPosition(Duration.zero);
        player.emitDuration(Duration.zero);
        player.emitBuffer(Duration.zero);
        await pumpEventQueue();
        player.openGate!.complete();
        await initializing;
        await pumpEventQueue();

        // When: the real duration arrives.
        player.emitDuration(const Duration(hours: 1, minutes: 45));
        await pumpEventQueue();
        await controller.dispose();

        // Then: the resume seek fires and stop reports the resume position.
        expect(player.seeks, [const Duration(minutes: 52, seconds: 36)]);
        expect(reporter.stops, [const Duration(minutes: 52, seconds: 36)]);
      },
    );

    test('re-applies resume seek when the engine ticks from zero and keeps '
        'the resume position if closed before the seek lands', () async {
      // Given
      var now = DateTime.utc(2026, 10, 13, 17, 38);
      final player = FakeStreamPlayer();
      final reporter = FakeReporter();
      const resume = Duration(minutes: 52, seconds: 36);
      final controller = PlaybackSessionController(
        request: _buildRequest(resumePosition: resume, reporter: reporter),
        playerFactory: () => player,
        progressInterval: const Duration(hours: 1),
        clock: () => now,
      );
      await controller.initialize();
      player.emitDuration(const Duration(hours: 1, minutes: 45));
      await pumpEventQueue();
      expect(player.seeks, [resume]);

      // When: the engine ignored the early seek and starts playing from 0s.
      now = now.add(const Duration(milliseconds: 600));
      player.emitPosition(const Duration(seconds: 1));
      await pumpEventQueue();

      // Then: the controller re-seeks to the resume point and never lets the
      // pre-resume 1s tick overwrite the stop position.
      expect(player.seeks, [resume, resume]);
      await controller.dispose();
      expect(reporter.stops, [resume]);
    });

    test(
      'seeks to the resume position once the first buffer arrives',
      () async {
        // Given
        final player = FakeStreamPlayer();
        final controller = PlaybackSessionController(
          request: _buildRequest(resumePosition: const Duration(seconds: 90)),
          playerFactory: () => player,
          progressInterval: const Duration(hours: 1),
        );

        // When
        await controller.initialize();
        // Then
        expect(player.seeks, isEmpty);

        player.emitBuffer(const Duration(seconds: 1));
        await pumpEventQueue();
        expect(player.seeks, [const Duration(seconds: 90)]);

        // Further buffer/duration events must not re-seek.
        player.emitBuffer(const Duration(seconds: 2));
        player.emitDuration(const Duration(minutes: 42));
        await pumpEventQueue();
        expect(player.seeks, [const Duration(seconds: 90)]);

        await controller.dispose();
      },
    );

    test('reports progress periodically while playing', () async {
      // Given
      final player = FakeStreamPlayer();
      final reporter = FakeReporter();
      final controller = PlaybackSessionController(
        request: _buildRequest(reporter: reporter),
        playerFactory: () => player,
        progressInterval: const Duration(milliseconds: 20),
      );

      // When
      await controller.initialize();
      player.emitPlaying(true);
      player.emitPosition(const Duration(seconds: 10));
      await Future<void>.delayed(const Duration(milliseconds: 90));

      // Then
      expect(reporter.progresses.length, greaterThanOrEqualTo(2));
      for (final entry in reporter.progresses) {
        expect(entry.isPaused, isFalse);
      }

      await controller.dispose();
    });

    test('does not report progress while paused', () async {
      // Given
      final player = FakeStreamPlayer();
      final reporter = FakeReporter();
      final controller = PlaybackSessionController(
        request: _buildRequest(reporter: reporter),
        playerFactory: () => player,
        progressInterval: const Duration(milliseconds: 20),
      );

      // When
      await controller.initialize();
      player.emitPlaying(false);
      player.emitPosition(const Duration(seconds: 10));
      await Future<void>.delayed(const Duration(milliseconds: 90));

      // Then
      expect(reporter.progresses, isEmpty);

      await controller.dispose();
    });

    test('reports stop with the last position on dispose', () async {
      // Given
      final player = FakeStreamPlayer();
      final reporter = FakeReporter();
      final controller = PlaybackSessionController(
        request: _buildRequest(reporter: reporter),
        playerFactory: () => player,
        progressInterval: const Duration(hours: 1),
      );

      // When
      await controller.initialize();
      player.emitPosition(const Duration(minutes: 1, seconds: 23));
      await pumpEventQueue();
      await controller.dispose();

      // Then
      expect(reporter.stops, [const Duration(minutes: 1, seconds: 23)]);
      expect(player.disposed, isTrue);
    });

    test('reports stop once when playback completes', () async {
      // Given
      final player = FakeStreamPlayer();
      final reporter = FakeReporter();
      final controller = PlaybackSessionController(
        request: _buildRequest(reporter: reporter),
        playerFactory: () => player,
        progressInterval: const Duration(hours: 1),
      );

      // When
      await controller.initialize();
      player.emitPosition(const Duration(minutes: 5));
      player.emitCompleted(true);
      await pumpEventQueue();
      // Duplicate completion events must not re-report.
      player.emitCompleted(true);
      await pumpEventQueue();
      await controller.dispose();

      // Then
      expect(reporter.stops.length, 1);
      expect(reporter.stops.single, const Duration(minutes: 5));
    });

    test('surfaces player errors as an error state', () async {
      // Given
      final player = FakeStreamPlayer();
      final controller = PlaybackSessionController(
        request: _buildRequest(reporter: FakeReporter()),
        playerFactory: () => player,
        progressInterval: const Duration(hours: 1),
      );
      await controller.initialize();
      expect(controller.errorMessage.value, isNull);

      // When
      player.emitError('connection lost');
      await pumpEventQueue();

      // Then
      expect(controller.errorMessage.value, 'connection lost');

      await controller.dispose();
    });

    test(
      'fatal player error before media loads pauses the player and redacts URL and ApiKey in errorMessage',
      () async {
        // Given
        final player = FakeStreamPlayer();
        final controller = PlaybackSessionController(
          request: _buildRequest(reporter: FakeReporter()),
          playerFactory: () => player,
          progressInterval: const Duration(hours: 1),
        );
        await controller.initialize();

        // When
        player.emitError(
          'Failed to open http://jellyfin.local:8096/Videos/1/stream?ApiKey=supersecret',
        );
        await pumpEventQueue();

        // Then
        expect(player.pauseCount, 1);
        expect(
          controller.errorMessage.value,
          'Failed to open http://[host]:8096/Videos/1/stream?[redacted]',
        );
        expect(controller.errorMessage.value, isNot(contains('supersecret')));
        expect(
          controller.errorMessage.value,
          isNot(contains('jellyfin.local')),
        );

        await controller.dispose();
      },
    );

    test(
      'non-fatal player error after media duration is loaded does not set errorMessage or pause playback',
      () async {
        // Given
        final player = FakeStreamPlayer();
        final reporter = FakeReporter();
        final controller = PlaybackSessionController(
          request: _buildRequest(reporter: reporter),
          playerFactory: () => player,
          progressInterval: const Duration(milliseconds: 20),
        );
        await controller.initialize();
        player.emitDuration(const Duration(minutes: 90));
        player.emitPlaying(true);
        player.emitPosition(const Duration(seconds: 30));
        await pumpEventQueue();

        // When
        player.emitError('ffmpeg/video: h264: top block unavailable');
        await Future<void>.delayed(const Duration(milliseconds: 60));

        // Then
        expect(controller.errorMessage.value, isNull);
        expect(player.pauseCount, 0);
        expect(reporter.progresses, isNotEmpty);

        await controller.dispose();
      },
    );

    test(
      'retry reopens the stream and resumes from the last position',
      () async {
        // Given
        final player = FakeStreamPlayer();
        final controller = PlaybackSessionController(
          request: _buildRequest(),
          playerFactory: () => player,
          progressInterval: const Duration(hours: 1),
        );

        // When
        await controller.initialize();
        player.emitPosition(const Duration(seconds: 10));
        player.emitError('connection lost');
        await pumpEventQueue();
        // Then
        expect(controller.errorMessage.value, isNotNull);

        await controller.retry();
        expect(player.openedUrls.length, 2);
        expect(controller.errorMessage.value, isNull);

        player.emitBuffer(const Duration(seconds: 1));
        await pumpEventQueue();
        expect(player.seeks, [const Duration(seconds: 10)]);

        await controller.dispose();
      },
    );

    test('switching source preserves the current position', () async {
      // Given
      final player = FakeStreamPlayer();
      final controller = PlaybackSessionController(
        request: _buildRequest(),
        playerFactory: () => player,
        progressInterval: const Duration(hours: 1),
      );

      // When
      await controller.initialize();
      player.emitPosition(const Duration(seconds: 33));
      await pumpEventQueue();

      await controller.switchSource(
        Uri.parse('http://server.example/Videos/1/hls'),
      );
      // Then
      expect(
        player.openedUrls.last,
        Uri.parse('http://server.example/Videos/1/hls'),
      );

      player.emitBuffer(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(player.seeks, [const Duration(seconds: 33)]);

      await controller.dispose();
    });

    test('does not report start when opening fails', () async {
      // Given
      final player = FakeStreamPlayer()..failOpen = true;
      final reporter = FakeReporter();
      final controller = PlaybackSessionController(
        request: _buildRequest(reporter: reporter),
        playerFactory: () => player,
        progressInterval: const Duration(hours: 1),
      );

      // When
      await controller.initialize();
      await pumpEventQueue();

      // Then
      expect(reporter.starts, isEmpty);
      expect(controller.errorMessage.value, isNotNull);

      await controller.dispose();
    });

    test('skips reporting entirely when no reporter is provided', () async {
      // Given
      final player = FakeStreamPlayer();
      final controller = PlaybackSessionController(
        request: _buildRequest(),
        playerFactory: () => player,
        progressInterval: const Duration(milliseconds: 20),
      );

      // When
      await controller.initialize();
      player.emitPlaying(true);
      player.emitCompleted(true);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await controller.dispose();

      // Then
      expect(player.disposed, isTrue);
    });
  });

  group('matchDiscoveredTrack', () {
    const discovered = [
      PlayerTrack(id: '0', title: 'English', language: 'eng'),
      PlayerTrack(id: '1', title: 'Commentary', language: 'ger'),
    ];

    test('prefers title/language matches over ordering', () {
      // Given
      const label = 'ger';

      // When
      final match = matchDiscoveredTrack(
        discovered: discovered,
        label: label,
        ordinal: 0,
      );

      // Then
      expect(match?.id, '1');
    });

    test('falls back to the option ordering', () {
      // Given
      const label = 'Unknown · AAC · Stereo';

      // When
      final match = matchDiscoveredTrack(
        discovered: discovered,
        label: label,
        ordinal: 1,
      );

      // Then
      expect(match?.id, '1');
    });

    test('is case-insensitive on labels', () {
      // Given
      const label = 'ENGLISH';

      // When
      final match = matchDiscoveredTrack(
        discovered: discovered,
        label: label,
        ordinal: 1,
      );

      // Then
      expect(match?.id, '0');
    });

    test('returns null when nothing matches', () {
      // Given
      const label = 'English';

      // When
      final match = matchDiscoveredTrack(
        discovered: const [],
        label: label,
        ordinal: 0,
      );

      // Then
      expect(match, isNull);
    });
  });
}
