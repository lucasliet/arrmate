import 'package:arrmate/core/network/api_error.dart';
import 'package:arrmate/data/api/qbittorrent_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/activity/providers/qbittorrent_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQBittorrentService extends Mock implements QBittorrentService {}

void main() {
  late MockQBittorrentService service;

  setUp(() {
    service = MockQBittorrentService();
    when(service.allowAuthenticationRetry).thenReturn(null);
  });

  /// Opens the list provider and keeps it alive, the way the Torrents tab does.
  ProviderContainer openList() {
    final container = ProviderContainer(
      overrides: [
        qbittorrentServiceProvider.overrideWithValue(service),
        currentQBittorrentInstanceProvider.overrideWithValue(null),
      ],
    );
    container.listen(qbittorrentTorrentsProvider, (_, _) {});
    return container;
  }

  group('QBittorrentNotifier', () {
    testWidgets('should stop polling when the credentials are refused', (
      tester,
    ) async {
      // Given
      when(
        service.getTorrents,
      ).thenAnswer((_) => Future.error(const UnauthorizedError()));
      final container = openList();
      await tester.pump();

      // When ten minutes go by
      await tester.pump(const Duration(minutes: 10));

      // Then the server was asked once and the error is on screen
      verify(service.getTorrents).called(1);
      expect(container.read(qbittorrentTorrentsProvider).hasError, isTrue);
      container.dispose();
    });

    testWidgets('should keep polling after other errors, a minute apart', (
      tester,
    ) async {
      when(service.getTorrents).thenAnswer(
        (_) => Future.error(
          DioException.connectionError(
            requestOptions: RequestOptions(path: '/api/v2/torrents/info'),
            reason: 'unreachable',
          ),
        ),
      );
      final container = openList();
      await tester.pump();

      await tester.pump(const Duration(seconds: 61));
      await tester.pump(const Duration(seconds: 61));

      // The first try plus one per minute
      verify(service.getTorrents).called(3);
      container.dispose();
    });

    testWidgets('should show the error instead of stale data when the '
        'credentials are refused mid-session', (tester) async {
      // Given a list that loaded, then credentials that stop working
      var calls = 0;
      when(service.getTorrents).thenAnswer((_) async {
        calls++;
        if (calls == 1) return [_torrent()];
        throw const UnauthorizedError();
      });
      final container = openList();
      await tester.pump();
      expect(container.read(qbittorrentTorrentsProvider).hasError, isFalse);
      expect(container.read(qbittorrentTorrentsProvider).value, hasLength(1));

      // When the next poll is refused
      await tester.pump(const Duration(seconds: 20));

      // Then the list reports the error and polling stops
      final state = container.read(qbittorrentTorrentsProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<UnauthorizedError>());
      await tester.pump(const Duration(minutes: 10));
      expect(calls, 2);
      container.dispose();
    });

    for (final failure in <String, Object Function()>{
      'a 404': () => DioException.badResponse(
        statusCode: 404,
        requestOptions: RequestOptions(path: '/api/v2/torrents/info'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v2/torrents/info'),
          statusCode: 404,
        ),
      ),
      'an unreachable server': () => DioException.connectionError(
        requestOptions: RequestOptions(path: '/api/v2/torrents/info'),
        reason: 'unreachable',
      ),
    }.entries) {
      testWidgets('should show the error when a refresh meets '
          '${failure.key}', (tester) async {
        // Given a list that loaded
        var calls = 0;
        when(service.getTorrents).thenAnswer((_) async {
          calls++;
          if (calls == 1) return [_torrent()];
          throw failure.value();
        });
        final container = openList();
        await tester.pump();
        expect(container.read(qbittorrentTorrentsProvider).value, hasLength(1));

        // When the user refreshes and the server fails
        await container.read(qbittorrentTorrentsProvider.notifier).refresh();

        // Then the error is shown instead of the old list
        final state = container.read(qbittorrentTorrentsProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<DioException>());
        container.dispose();
      });
    }

    testWidgets('should keep the list on screen when a poll fails', (
      tester,
    ) async {
      // Given a list that loaded, then a server that stops answering
      var calls = 0;
      when(service.getTorrents).thenAnswer((_) async {
        calls++;
        if (calls == 1) return [_torrent()];
        throw DioException.connectionError(
          requestOptions: RequestOptions(path: '/api/v2/torrents/info'),
          reason: 'unreachable',
        );
      });
      final container = openList();
      await tester.pump();

      // When the next poll fails
      await tester.pump(const Duration(seconds: 20));

      // Then the old list stays, since the user did not ask for the poll
      final state = container.read(qbittorrentTorrentsProvider);
      expect(state.hasError, isFalse);
      expect(state.value, hasLength(1));
      container.dispose();
    });

    testWidgets('should keep showing the error when a poll fails after a '
        'refresh that failed', (tester) async {
      // Given a list that loaded, then a server that stops answering
      var calls = 0;
      when(service.getTorrents).thenAnswer((_) async {
        calls++;
        if (calls == 1) return [_torrent()];
        throw DioException.connectionError(
          requestOptions: RequestOptions(path: '/api/v2/torrents/info'),
          reason: 'unreachable',
        );
      });
      final container = openList();
      await tester.pump();
      await container.read(qbittorrentTorrentsProvider.notifier).refresh();
      expect(container.read(qbittorrentTorrentsProvider).hasError, isTrue);

      // When the next poll fails too
      await tester.pump(const Duration(seconds: 61));

      // Then the error is still shown, not replaced by the old list
      expect(container.read(qbittorrentTorrentsProvider).hasError, isTrue);
      container.dispose();
    });

    testWidgets('should allow a login when the list is opened and when '
        'refreshed', (tester) async {
      when(service.getTorrents).thenAnswer((_) async => [_torrent()]);
      final container = openList();
      await tester.pump();

      // Opening the list is something the user did
      verify(service.allowAuthenticationRetry).called(1);

      // So is pressing refresh
      await container.read(qbittorrentTorrentsProvider.notifier).refresh();
      verify(service.allowAuthenticationRetry).called(1);
      container.dispose();
    });

    testWidgets('should not allow a login on a poll', (tester) async {
      when(service.getTorrents).thenAnswer((_) async => [_torrent()]);
      final container = openList();
      await tester.pump();
      clearInteractions(service);

      await tester.pump(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 20));

      verifyNever(service.allowAuthenticationRetry);
      verify(service.getTorrents).called(greaterThan(1));
      container.dispose();
    });
  });
}

Torrent _torrent() {
  return Torrent(
    hash: 'aabb',
    name: 'Arrival.2016.1080p',
    size: 1000,
    progress: 1.0,
    dlspeed: 0,
    upspeed: 0,
    eta: 0,
    ratio: 1,
    status: TorrentStatus.uploading,
    state: 'uploading',
    tags: const [],
    savePath: '/downloads',
    numSeeds: 1,
    numLeechs: 0,
    downloaded: 1000,
    uploaded: 1000,
    amountLeft: 0,
    addedOn: 1700000000,
    priority: 0,
  );
}
