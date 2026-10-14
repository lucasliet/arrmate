import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrmate/core/network/api_error.dart';
import 'package:arrmate/core/services/jellyfin_playback_reporter.dart';
import 'package:arrmate/core/services/playback_launch_service.dart';
import 'package:arrmate/data/api/jellyfin_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/repositories.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/providers/jellyfin_session_state_provider.dart';
import 'package:arrmate/presentation/screens/player/playback_request.dart';
import 'package:arrmate/presentation/screens/series/providers/episode_providers.dart';
import 'package:arrmate/presentation/screens/series/providers/series_provider.dart';

class MockJellyfinService extends Mock implements JellyfinService {}

class MockMovieRepository extends Mock implements MovieRepository {}

const _streamUrl =
    'http://jellyfin.local:8096/Videos/item-1/stream?static=true'
    '&MediaSourceId=src-1&ApiKey=secret-token';

final _launchButtonKey = Key('launchPlayback');

JellyfinItem _item() => const JellyfinItem(
  id: 'item-1',
  name: 'The Matrix',
  type: 'Movie',
  path: '/media/movies/The.Matrix.1999.mkv',
  mediaSources: [JellyfinMediaSource(id: 'src-1')],
);

JellyfinPlaybackSession _session() => JellyfinPlaybackSession(
  itemId: 'item-1',
  mediaSourceId: 'src-1',
  streamUrl: Uri.parse(_streamUrl),
  httpHeaders: const {'Authorization': 'MediaBrowser Client="Arrmate"'},
  playbackPosition: const Duration(seconds: 90),
  audioStreams: const [
    JellyfinMediaStream(
      index: 1,
      type: 'Audio',
      displayTitle: 'English (AC3 5.1)',
    ),
    JellyfinMediaStream(index: 2, type: 'Audio', language: 'fre', codec: 'aac'),
  ],
  subtitleStreams: const [
    JellyfinMediaStream(
      index: 3,
      type: 'Subtitle',
      language: 'eng',
      codec: 'subrip',
      isExternal: true,
      deliveryUrl: '/Videos/item-1/src-1/Subtitles/3/0/Stream.vtt',
    ),
    JellyfinMediaStream(
      index: 4,
      type: 'Subtitle',
      displayTitle: 'Forced (eng)',
    ),
  ],
);

Movie _movie() => Movie.fromJson({
  'id': 42,
  'tmdbId': 603,
  'imdbId': 'tt0133093',
  'title': 'The Matrix',
  'year': 1999,
  'hasFile': true,
  'added': '2024-01-01T00:00:00.000Z',
});

Episode _episode() => Episode(
  id: 10,
  seriesId: 5,
  tvdbId: 321,
  seasonNumber: 1,
  episodeNumber: 2,
  title: 'Pilot',
  hasFile: true,
  episodeFile: _mediaFile(path: '/tv/Show/S01E02.mkv'),
  series: _series(),
);

/// Episode exactly as [SonarrApi.getEpisodes] returns it: `episodeFile` and
/// `series` are not requested, so only the ids are populated.
Episode _episodeWithoutEmbeds() => Episode(
  id: 10,
  seriesId: 5,
  tvdbId: 321,
  seasonNumber: 1,
  episodeNumber: 2,
  title: 'Pilot',
  hasFile: true,
  episodeFileId: 7,
);

Series _series() => Series.fromJson({
  'id': 5,
  'title': 'Breaking Bad',
  'tvdbId': 77,
  'added': '2024-01-01T00:00:00.000Z',
});

MediaFile _mediaFile({required String path}) => MediaFile.fromJson({
  'id': 1,
  'relativePath': path.split('/').last,
  'path': path,
  'size': 1024,
  'dateAdded': DateTime(2024, 1, 1).toIso8601String(),
});

Instance _jellyfinInstance({
  String id = 'jellyfin-1',
  required String apiKey,
}) => Instance(
  id: id,
  type: InstanceType.jellyfin,
  label: 'Jellyfin',
  url: 'http://jellyfin.local:8096',
  apiKey: apiKey,
);

/// Named arguments of [JellyfinService.resolvePlayableItem] shared by every
/// stub so the recorded invocations match the real call shape.
void _stubResolvePlayableItem(
  MockJellyfinService jellyfin, {
  JellyfinItem? answer,
  Object? throwable,
}) {
  final stub = when(
    () => jellyfin.resolvePlayableItem(
      filePath: any(named: 'filePath'),
      title: any(named: 'title'),
      productionYear: any(named: 'productionYear'),
      tmdbId: any(named: 'tmdbId'),
      imdbId: any(named: 'imdbId'),
      seriesTvdbId: any(named: 'seriesTvdbId'),
      episodeTvdbId: any(named: 'episodeTvdbId'),
      seasonNumber: any(named: 'seasonNumber'),
      episodeNumber: any(named: 'episodeNumber'),
      seriesName: any(named: 'seriesName'),
      isEpisode: any(named: 'isEpisode'),
      onProgress: any(named: 'onProgress'),
    ),
  );
  if (throwable != null) {
    stub.thenThrow(throwable);
    return;
  }
  stub.thenAnswer((_) async => answer);
}

/// Stub the full resolve + session pipeline to succeed.
void _stubHappyPath(
  MockJellyfinService jellyfin, {
  required bool userMode,
  JellyfinItem? item,
}) {
  when(() => jellyfin.authenticate()).thenAnswer((_) async {});
  _stubResolvePlayableItem(jellyfin, answer: item);
  when(
    () => jellyfin.getPlaybackSession(any()),
  ).thenAnswer((_) async => _session());
  when(() => jellyfin.supportsProgressSync).thenReturn(userMode);
}

/// Stub only the authenticate + resolve calls (session is never reached).
void _stubResolve(
  MockJellyfinService jellyfin, {
  JellyfinItem? answer,
  Object? throwable,
}) {
  when(() => jellyfin.authenticate()).thenAnswer((_) async {});
  _stubResolvePlayableItem(jellyfin, answer: answer, throwable: throwable);
}

class _LaunchHarness {
  final Completer<void> done = Completer<void>();
  PlaybackRequest? playerRequest;
  int jellyfinServiceCreations = 0;
}

class _LaunchHost extends ConsumerWidget {
  const _LaunchHost({
    required this.run,
    required this.onDone,
    required this.onError,
  });

  final Future<void> Function(BuildContext context, WidgetRef ref) run;
  final void Function() onDone;
  final void Function(Object error, StackTrace stackTrace) onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: _launchButtonKey,
          onPressed: () async {
            try {
              await run(context, ref);
              onDone();
            } catch (error, stackTrace) {
              onError(error, stackTrace);
            }
          },
          child: const Text('Launch'),
        ),
      ),
    );
  }
}

/// Pumps a two-route app (`/detail` hosts the launch trigger, `/player`
/// records the extra) and taps the trigger.
Future<void> _pumpHarness(
  WidgetTester tester, {
  required _LaunchHarness harness,
  required List<Override> overrides,
  required Future<void> Function(BuildContext context, WidgetRef ref) run,
}) async {
  final router = GoRouter(
    initialLocation: '/detail',
    routes: [
      GoRoute(
        path: '/detail',
        builder: (_, _) => ProviderScope(
          overrides: overrides,
          child: _LaunchHost(
            run: run,
            onDone: harness.done.complete,
            onError: (error, stackTrace) =>
                harness.done.completeError(error, stackTrace),
          ),
        ),
      ),
      GoRoute(
        path: '/player',
        builder: (_, state) {
          harness.playerRequest = state.extra as PlaybackRequest?;
          return const Scaffold(body: Text('Player'));
        },
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.tap(find.byKey(_launchButtonKey));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(false);
    registerFallbackValue('');
    registerFallbackValue(JellyfinItem(id: 'fallback'));
  });

  group('PlaybackLaunchService', () {
    testWidgets('playMovie resolves the file and pushes a fully mapped request '
        '(user mode → reporter present)', (tester) async {
      // Given
      final jellyfin = MockJellyfinService();
      _stubHappyPath(jellyfin, userMode: true, item: _item());
      final harness = _LaunchHarness();
      final service = PlaybackLaunchService(
        jellyfinServiceFactory: (instance) {
          harness.jellyfinServiceCreations++;
          return jellyfin;
        },
      );
      final movieRepository = MockMovieRepository();
      when(() => movieRepository.getMovieFiles(42)).thenAnswer(
        (_) async => [_mediaFile(path: '/movies/The.Matrix.1999.mkv')],
      );

      // When
      await _pumpHarness(
        tester,
        harness: harness,
        overrides: [
          currentJellyfinInstanceProvider.overrideWithValue(
            _jellyfinInstance(apiKey: 'user:pass'),
          ),
          movieRepositoryProvider.overrideWithValue(movieRepository),
        ],
        run: (context, ref) => service.playMovie(context, ref, movie: _movie()),
      );
      await harness.done.future;
      await tester.pump();

      final request = harness.playerRequest;
      // Then
      expect(request, isNotNull);
      expect(request!.title, 'The Matrix');
      expect(request.streamUrl, Uri.parse(_streamUrl));
      expect(request.hlsUrl, isNull);
      expect(request.resumePosition, const Duration(seconds: 90));
      expect(request.httpHeaders, _session().httpHeaders);
      expect(request.audioTracks.map((track) => track.label), [
        'English (AC3 5.1)',
        'fre · aac',
      ]);
      expect(request.subtitleTracks.map((track) => track.label), [
        'eng · subrip',
        'Forced (eng)',
      ]);
      expect(request.subtitleTracks.first.isExternal, isTrue);
      expect(
        request.subtitleTracks.first.deliveryPath,
        '/Videos/item-1/src-1/Subtitles/3/0/Stream.vtt',
      );
      expect(request.subtitleTracks.last.isExternal, isFalse);
      expect(request.externalUrl, _streamUrl);
      final reporter = request.reporter;
      expect(reporter, isA<JellyfinPlaybackReporter>());
      expect((reporter as JellyfinPlaybackReporter).itemId, 'item-1');
      expect(reporter.mediaSourceId, 'src-1');

      expect(find.byType(AlertDialog), findsNothing);
      verify(
        () => jellyfin.resolvePlayableItem(
          filePath: '/movies/The.Matrix.1999.mkv',
          title: 'The Matrix',
          productionYear: 1999,
          tmdbId: 603,
          imdbId: 'tt0133093',
          seriesTvdbId: null,
          episodeTvdbId: null,
          seasonNumber: null,
          episodeNumber: null,
          seriesName: null,
          isEpisode: false,
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);

      // Let the snackbar timer fire so no timer is left pending.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('playEpisode forwards episode ids and formats the title', (
      tester,
    ) async {
      // Given
      final jellyfin = MockJellyfinService();
      _stubHappyPath(jellyfin, userMode: true, item: _item());
      final harness = _LaunchHarness();
      final service = PlaybackLaunchService(
        jellyfinServiceFactory: (instance) {
          harness.jellyfinServiceCreations++;
          return jellyfin;
        },
      );

      // When
      await _pumpHarness(
        tester,
        harness: harness,
        overrides: [
          currentJellyfinInstanceProvider.overrideWithValue(
            _jellyfinInstance(apiKey: 'user:pass'),
          ),
        ],
        run: (context, ref) =>
            service.playEpisode(context, ref, episode: _episode()),
      );
      await harness.done.future;
      await tester.pump();

      final request = harness.playerRequest;
      // Then
      expect(request, isNotNull);
      expect(request!.title, 'S01E02 · Pilot');
      verify(
        () => jellyfin.resolvePlayableItem(
          filePath: '/tv/Show/S01E02.mkv',
          title: 'S01E02 · Pilot',
          productionYear: null,
          tmdbId: null,
          imdbId: null,
          seriesTvdbId: 77,
          episodeTvdbId: 321,
          seasonNumber: 1,
          episodeNumber: 2,
          seriesName: 'Breaking Bad',
          isEpisode: true,
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets(
      'playEpisode resolves the file and series through the providers when '
      'the episode listing embeds neither',
      (tester) async {
        // Given
        final jellyfin = MockJellyfinService();
        _stubHappyPath(jellyfin, userMode: true, item: _item());
        final harness = _LaunchHarness();
        final service = PlaybackLaunchService(
          jellyfinServiceFactory: (instance) {
            harness.jellyfinServiceCreations++;
            return jellyfin;
          },
        );

        // When
        await _pumpHarness(
          tester,
          harness: harness,
          overrides: [
            currentJellyfinInstanceProvider.overrideWithValue(
              _jellyfinInstance(apiKey: 'user:pass'),
            ),
            episodeFileProvider(
              7,
            ).overrideWith((ref) => _mediaFile(path: '/tv/Show/S01E02.mkv')),
            seriesDetailsProvider(5).overrideWith((ref) async => _series()),
          ],
          run: (context, ref) => service.playEpisode(
            context,
            ref,
            episode: _episodeWithoutEmbeds(),
          ),
        );
        await harness.done.future;
        await tester.pump();

        final request = harness.playerRequest;
        // Then
        expect(request, isNotNull);
        expect(request!.title, 'S01E02 · Pilot');
        verify(
          () => jellyfin.resolvePlayableItem(
            filePath: '/tv/Show/S01E02.mkv',
            title: 'S01E02 · Pilot',
            productionYear: null,
            tmdbId: null,
            imdbId: null,
            seriesTvdbId: 77,
            episodeTvdbId: 321,
            seasonNumber: 1,
            episodeNumber: 2,
            seriesName: 'Breaking Bad',
            isEpisode: true,
            onProgress: any(named: 'onProgress'),
          ),
        ).called(1);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'API-key mode builds the request without externalUrl or a reporter',
      (tester) async {
        // Given
        final jellyfin = MockJellyfinService();
        _stubHappyPath(jellyfin, userMode: false, item: _item());
        final harness = _LaunchHarness();
        final service = PlaybackLaunchService(
          jellyfinServiceFactory: (instance) {
            harness.jellyfinServiceCreations++;
            return jellyfin;
          },
        );
        final movieRepository = MockMovieRepository();
        when(() => movieRepository.getMovieFiles(42)).thenAnswer(
          (_) async => [_mediaFile(path: '/movies/The.Matrix.1999.mkv')],
        );

        // When
        await _pumpHarness(
          tester,
          harness: harness,
          overrides: [
            currentJellyfinInstanceProvider.overrideWithValue(
              _jellyfinInstance(apiKey: 'admin-api-key'),
            ),
            movieRepositoryProvider.overrideWithValue(movieRepository),
          ],
          run: (context, ref) =>
              service.playMovie(context, ref, movie: _movie()),
        );
        await harness.done.future;
        await tester.pump();

        // Then
        expect(harness.playerRequest, isNotNull);
        // The stream URL carries the admin API key in this mode — it must
        // never be handed to external apps.
        expect(harness.playerRequest!.externalUrl, isNull);
        expect(harness.playerRequest!.reporter, isNull);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets('the Jellyfin service is cached per instance across plays', (
      tester,
    ) async {
      // Given
      final jellyfinOne = MockJellyfinService();
      final jellyfinTwo = MockJellyfinService();
      final instanceOne = _jellyfinInstance(
        id: 'jellyfin-1',
        apiKey: 'user:pass',
      );
      final instanceTwo = _jellyfinInstance(
        id: 'jellyfin-2',
        apiKey: 'user:pass',
      );
      when(() => jellyfinOne.instance).thenReturn(instanceOne);
      when(() => jellyfinTwo.instance).thenReturn(instanceTwo);
      final createdFor = <String>[];
      final service = PlaybackLaunchService(
        jellyfinServiceFactory: (instance) {
          createdFor.add(instance.id);
          return instance.id == 'jellyfin-1' ? jellyfinOne : jellyfinTwo;
        },
      );
      _stubHappyPath(jellyfinOne, userMode: true, item: _item());
      _stubHappyPath(jellyfinTwo, userMode: true, item: _item());

      // Two consecutive plays on the same instance reuse one client: the
      // factory is called only for the first one.
      final firstHarness = _LaunchHarness();
      // When
      await _pumpHarness(
        tester,
        harness: firstHarness,
        overrides: [
          currentJellyfinInstanceProvider.overrideWithValue(instanceOne),
        ],
        run: (context, ref) async {
          await service.playFile(
            context,
            ref,
            filePath: '/movies/a.mkv',
            title: 'A',
            isEpisode: false,
          );
          await service.playFile(
            context,
            ref,
            filePath: '/movies/b.mkv',
            title: 'B',
            isEpisode: false,
          );
        },
      );
      await firstHarness.done.future;
      await tester.pump();

      // Then
      expect(createdFor, ['jellyfin-1']);
      verify(() => jellyfinOne.authenticate()).called(2);
      verifyNever(() => jellyfinTwo.authenticate());

      // A different instance id gets its own client.
      final secondHarness = _LaunchHarness();
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpHarness(
        tester,
        harness: secondHarness,
        overrides: [
          currentJellyfinInstanceProvider.overrideWithValue(instanceTwo),
        ],
        run: (context, ref) => service.playFile(
          context,
          ref,
          filePath: '/movies/c.mkv',
          title: 'C',
          isEpisode: false,
        ),
      );
      await secondHarness.done.future;
      await tester.pump();

      expect(createdFor, ['jellyfin-1', 'jellyfin-2']);
      verify(() => jellyfinTwo.authenticate()).called(1);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets(
      'recreates the Jellyfin service when the same instance id is updated',
      (tester) async {
        // Given
        final originalInstance = _jellyfinInstance(
          id: 'jellyfin-1',
          apiKey: 'user:old-pass',
        );
        final updatedInstance = _jellyfinInstance(
          id: 'jellyfin-1',
          apiKey: 'user:new-pass',
        );
        final firstService = MockJellyfinService();
        final secondService = MockJellyfinService();
        when(() => firstService.instance).thenReturn(originalInstance);
        when(() => secondService.instance).thenReturn(updatedInstance);
        _stubHappyPath(firstService, userMode: true, item: _item());
        _stubHappyPath(secondService, userMode: true, item: _item());

        final createdForApiKeys = <String>[];
        final service = PlaybackLaunchService(
          jellyfinServiceFactory: (instance) {
            createdForApiKeys.add(instance.apiKey);
            return instance.apiKey == 'user:old-pass'
                ? firstService
                : secondService;
          },
        );

        // When
        final firstHarness = _LaunchHarness();
        await _pumpHarness(
          tester,
          harness: firstHarness,
          overrides: [
            currentJellyfinInstanceProvider.overrideWithValue(originalInstance),
          ],
          run: (context, ref) async {
            await service.playFile(
              context,
              ref,
              filePath: '/movies/a.mkv',
              title: 'A',
              isEpisode: false,
            );
            await service.playFile(
              context,
              ref,
              filePath: '/movies/b.mkv',
              title: 'B',
              isEpisode: false,
            );
          },
        );
        await firstHarness.done.future;
        await tester.pump();

        final secondHarness = _LaunchHarness();
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpHarness(
          tester,
          harness: secondHarness,
          overrides: [
            currentJellyfinInstanceProvider.overrideWithValue(updatedInstance),
          ],
          run: (context, ref) => service.playFile(
            context,
            ref,
            filePath: '/movies/c.mkv',
            title: 'C',
            isEpisode: false,
          ),
        );
        await secondHarness.done.future;
        await tester.pump();

        // Then
        expect(createdForApiKeys, ['user:old-pass', 'user:new-pass']);
        verify(() => firstService.authenticate()).called(2);
        verify(() => secondService.authenticate()).called(1);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'resolve returning null surfaces "not found" without navigation',
      (tester) async {
        // Given
        final jellyfin = MockJellyfinService();
        _stubResolve(jellyfin, answer: null);
        final harness = _LaunchHarness();
        final service = PlaybackLaunchService(
          jellyfinServiceFactory: (instance) {
            harness.jellyfinServiceCreations++;
            return jellyfin;
          },
        );
        PlaybackLaunchResult? launchResult;

        // When
        await _pumpHarness(
          tester,
          harness: harness,
          overrides: [
            currentJellyfinInstanceProvider.overrideWithValue(
              _jellyfinInstance(apiKey: 'user:pass'),
            ),
          ],
          run: (context, ref) async {
            launchResult = await service.playFile(
              context,
              ref,
              filePath: '/tv/Show/S01E02.mkv',
              title: 'S01E02 · Pilot',
              isEpisode: true,
            );
          },
        );
        await harness.done.future;
        await tester.pump();

        // Then
        expect(launchResult, isA<PlaybackTargetNotFound>());
        expect(harness.playerRequest, isNull);
        expect(
          find.text('Could not find this media in Jellyfin'),
          findsOneWidget,
        );
        verifyNever(() => jellyfin.getPlaybackSession(any()));

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets('an unexpected resolve error surfaces a failure result', (
      tester,
    ) async {
      // Given
      final jellyfin = MockJellyfinService();
      _stubResolve(jellyfin, throwable: Exception('authentication failed'));
      final harness = _LaunchHarness();
      final service = PlaybackLaunchService(
        jellyfinServiceFactory: (instance) {
          harness.jellyfinServiceCreations++;
          return jellyfin;
        },
      );
      PlaybackLaunchResult? launchResult;

      // When
      await _pumpHarness(
        tester,
        harness: harness,
        overrides: [
          currentJellyfinInstanceProvider.overrideWithValue(
            _jellyfinInstance(apiKey: 'user:pass'),
          ),
        ],
        run: (context, ref) async {
          launchResult = await service.playFile(
            context,
            ref,
            filePath: '/movies/The.Matrix.1999.mkv',
            title: 'The Matrix',
            tmdbId: 603,
            isEpisode: false,
          );
        },
      );
      await harness.done.future;
      await tester.pump();

      // Then
      expect(launchResult, isA<PlaybackLaunchFailure>());
      expect(harness.playerRequest, isNull);
      expect(find.textContaining('Could not start playback'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets(
      'without a configured Jellyfin instance the guard fires and no service '
      'is created',
      (tester) async {
        // Given
        final jellyfin = MockJellyfinService();
        final harness = _LaunchHarness();
        final service = PlaybackLaunchService(
          jellyfinServiceFactory: (instance) {
            harness.jellyfinServiceCreations++;
            return jellyfin;
          },
        );
        PlaybackLaunchResult? launchResult;

        // When
        await _pumpHarness(
          tester,
          harness: harness,
          overrides: [
            currentJellyfinInstanceProvider.overrideWithValue(null),
            movieRepositoryProvider.overrideWithValue(MockMovieRepository()),
          ],
          run: (context, ref) =>
              service.playMovie(context, ref, movie: _movie()),
        );
        await harness.done.future;
        await tester.pump();

        // Then
        expect(harness.jellyfinServiceCreations, 0);
        expect(harness.playerRequest, isNull);
        expect(find.text('No Jellyfin server is configured'), findsOneWidget);
        verifyNever(() => jellyfin.authenticate());
        expect(launchResult, isNull);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets('an expired Jellyfin session flags the instance for sign-in', (
      tester,
    ) async {
      // Given
      final jellyfin = MockJellyfinService();
      _stubResolve(
        jellyfin,
        throwable: const UnauthorizedError(
          'Your Jellyfin session has expired. Sign in again in the instance '
          'settings (Add Basic Auth with your username and password).',
        ),
      );
      final harness = _LaunchHarness();
      final service = PlaybackLaunchService(
        jellyfinServiceFactory: (instance) => jellyfin,
      );
      PlaybackLaunchResult? launchResult;
      Set<String>? expiredAfterLaunch;

      // When
      await _pumpHarness(
        tester,
        harness: harness,
        overrides: [
          currentJellyfinInstanceProvider.overrideWithValue(
            _jellyfinInstance(apiKey: ''),
          ),
        ],
        run: (context, ref) async {
          launchResult = await service.playFile(
            context,
            ref,
            filePath: '/movies/The.Matrix.1999.mkv',
            title: 'The Matrix',
            tmdbId: 603,
            isEpisode: false,
          );
          expiredAfterLaunch = ref.read(jellyfinSessionExpiredProvider);
        },
      );
      await harness.done.future;
      await tester.pump();

      // Then
      expect(launchResult, isA<PlaybackLaunchFailure>());
      expect(
        (launchResult! as PlaybackLaunchFailure).message,
        startsWith('Your Jellyfin session has expired.'),
      );
      expect(expiredAfterLaunch, {'jellyfin-1'});
      expect(harness.playerRequest, isNull);
      expect(
        find.text('Your Jellyfin session has expired. Sign in again.'),
        findsOneWidget,
      );
      expect(find.text('Sign in'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('dismissing the status dialog cancels the launch', (
      tester,
    ) async {
      // Given
      final jellyfin = MockJellyfinService();
      when(() => jellyfin.authenticate()).thenAnswer((_) async {});
      final resolveCompleter = Completer<JellyfinItem?>();
      when(
        () => jellyfin.resolvePlayableItem(
          filePath: any(named: 'filePath'),
          title: any(named: 'title'),
          productionYear: any(named: 'productionYear'),
          tmdbId: any(named: 'tmdbId'),
          imdbId: any(named: 'imdbId'),
          seriesTvdbId: any(named: 'seriesTvdbId'),
          episodeTvdbId: any(named: 'episodeTvdbId'),
          seasonNumber: any(named: 'seasonNumber'),
          episodeNumber: any(named: 'episodeNumber'),
          seriesName: any(named: 'seriesName'),
          isEpisode: any(named: 'isEpisode'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) => resolveCompleter.future);
      when(
        () => jellyfin.getPlaybackSession(any()),
      ).thenAnswer((_) async => _session());
      when(() => jellyfin.supportsProgressSync).thenReturn(true);

      final harness = _LaunchHarness();
      final service = PlaybackLaunchService(
        jellyfinServiceFactory: (instance) {
          harness.jellyfinServiceCreations++;
          return jellyfin;
        },
      );
      PlaybackLaunchResult? launchResult;

      // When
      await _pumpHarness(
        tester,
        harness: harness,
        overrides: [
          currentJellyfinInstanceProvider.overrideWithValue(
            _jellyfinInstance(apiKey: 'user:pass'),
          ),
        ],
        run: (context, ref) async {
          launchResult = await service.playFile(
            context,
            ref,
            filePath: '/movies/The.Matrix.1999.mkv',
            title: 'The Matrix',
            tmdbId: 603,
            isEpisode: false,
          );
        },
      );

      // The status dialog is open while resolution is paused on the
      // completer; dismissing it must cancel the launch.
      // Then
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);

      resolveCompleter.complete(_item());
      await harness.done.future;
      await tester.pump();

      expect(launchResult, isA<PlaybackLaunchCancelled>());
      expect(harness.playerRequest, isNull);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets(
      'playItem starts playback directly from a resolved JellyfinItem without resolving',
      (tester) async {
        // Given
        final jellyfin = MockJellyfinService();
        final resolvedItem = _item();
        _stubHappyPath(jellyfin, userMode: true, item: resolvedItem);
        final harness = _LaunchHarness();
        final service = PlaybackLaunchService(
          jellyfinServiceFactory: (instance) {
            harness.jellyfinServiceCreations++;
            return jellyfin;
          },
        );
        PlaybackLaunchResult? launchResult;

        // When
        await _pumpHarness(
          tester,
          harness: harness,
          overrides: [
            currentJellyfinInstanceProvider.overrideWithValue(
              _jellyfinInstance(apiKey: 'user:pass'),
            ),
          ],
          run: (context, ref) async {
            launchResult = await service.playItem(
              context,
              ref,
              item: resolvedItem,
              title: 'Severance · S01E02 · Half Loop',
            );
          },
        );
        await harness.done.future;
        await tester.pump();

        // Then
        expect(launchResult, isA<PlaybackLaunched>());
        expect(harness.playerRequest, isNotNull);
        expect(harness.playerRequest!.title, 'Severance · S01E02 · Half Loop');
        expect(
          harness.playerRequest!.resumePosition,
          const Duration(seconds: 90),
        );
        verify(() => jellyfin.getPlaybackSession(resolvedItem)).called(1);
        verifyNever(
          () => jellyfin.resolvePlayableItem(
            filePath: any(named: 'filePath'),
            isEpisode: any(named: 'isEpisode'),
          ),
        );

        await tester.pump(const Duration(seconds: 5));
      },
    );
  });
}
