import 'dart:convert';
import 'dart:typed_data';

import 'package:arrmate/core/network/api_error.dart';
import 'package:arrmate/data/api/jellyfin_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JellyfinService authentication', () {
    test(
      'username:password mode hits AuthenticateByName and stores the token',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Users/AuthenticateByName':
              return {
                'AccessToken': 'token-123',
                'User': {'Id': 'user-9', 'Name': 'admin'},
              };
            case '/System/Info':
              return {'ServerName': 'Jelly', 'Version': '10.9.0'};
          }
          return <String, dynamic>{};
        });
        final service = _serviceUserPassword(adapter);

        // When
        final status = await service.getSystemStatus();

        // Then
        expect(adapter.methods.first, 'POST');
        expect(adapter.requests.first.path, '/Users/AuthenticateByName');
        final authHeaders = adapter.headers.first;
        expect(
          authHeaders['Authorization'],
          contains('MediaBrowser Client="Arrmate"'),
        );
        expect(
          authHeaders['Authorization'],
          contains('DeviceId="install-user-1"'),
        );
        // The stored access token travels as Token in the MediaBrowser
        // Authorization header (Jellyfin 12 rejects X-Emby-Token).
        expect(
          adapter.headers.last['Authorization'],
          contains('Token="token-123"'),
        );
        expect(status.appName, 'Jellyfin');
        expect(status.instanceName, 'Jelly');
        expect(status.version, '10.9.0');
        expect(service.supportsProgressSync, isTrue);
      },
    );

    test(
      'api-key mode sends a MediaBrowser Token and never guesses a user id',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/System/Info':
              return {'ServerName': 'Jelly', 'Version': '10.9.0'};
          }
          return <String, dynamic>{};
        });
        final service = _serviceApiKey(adapter);

        // When
        final status = await service.getSystemStatus();

        // An admin API key has no user scope: `/Users` must not be probed to
        // attribute watch state to an arbitrary account.
        // Then
        expect(adapter.requests.any((uri) => uri.path == '/Users'), isFalse);
        expect(adapter.requests.map((uri) => uri.path), ['/System/Info']);
        expect(
          adapter.headers.last['Authorization'],
          contains('Token="jelly-key"'),
        );
        expect(status.appName, 'Jellyfin');
        expect(status.version, '10.9.0');
        expect(service.supportsProgressSync, isFalse);
      },
    );

    test('drops a custom Authorization header in user mode', () async {
      // Given
      final instance = _instanceWithBasicAuth(apiKey: 'lucas:secret');

      // When
      final headers = JellyfinService.effectiveCustomHeaders(instance);

      // Then
      expect(headers.containsKey('Authorization'), isFalse);
      expect(headers['X-Proxy'], 'keep-me');
    });

    test('drops a custom Authorization header in API key mode', () async {
      // Given
      final instance = _instanceWithBasicAuth(apiKey: 'jelly-key');

      // When
      final headers = JellyfinService.effectiveCustomHeaders(instance);

      // Then
      expect(headers.containsKey('Authorization'), isFalse);
      expect(headers['X-Proxy'], 'keep-me');
    });

    test('keeps every custom header without managed credentials', () async {
      // Given
      final instance = Instance(
        id: 'jf-1',
        type: InstanceType.jellyfin,
        label: 'Jellyfin',
        url: 'http://jf.test',
        headers: [
          // No colon after decoding → not Jellyfin login credentials, so
          // the header passes through untouched.
          InstanceHeader(
            name: 'Authorization',
            value: 'Basic cHJveHktdG9rZW4=',
          ),
          InstanceHeader(name: 'X-Proxy', value: 'keep-me'),
        ],
      );

      // When
      final headers = JellyfinService.effectiveCustomHeaders(instance);

      // Then
      expect(headers['Authorization'], 'Basic cHJveHktdG9rZW4=');
      expect(headers['X-Proxy'], 'keep-me');
    });

    test(
      'empty key with Basic Auth logs in with the decoded credentials',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Users/AuthenticateByName':
              return {
                'AccessToken': 'token-123',
                'User': {'Id': 'user-9', 'Name': 'lucas'},
              };
            case '/System/Info':
              return {'ServerName': 'Jelly', 'Version': '12.2.0'};
          }
          return <String, dynamic>{};
        });
        final service = _buildService(
          adapter,
          apiKey: '',
          deviceId: 'install-basic-1',
          headers: [
            InstanceHeader(
              name: 'Authorization',
              value: 'Basic bHVjYXM6c2VjcmV0',
            ),
          ],
        );

        // When
        final status = await service.getSystemStatus();

        // Then
        expect(adapter.methods.first, 'POST');
        expect(adapter.requests.first.path, '/Users/AuthenticateByName');
        expect(adapter.bodies.first, {'Username': 'lucas', 'Pw': 'secret'});
        expect(service.supportsProgressSync, isTrue);
        expect(status.version, '12.2.0');
        for (final headers in adapter.headers.skip(1)) {
          expect(headers['Authorization'], contains('Token="token-123"'));
        }
      },
    );

    test('malformed Basic Auth falls back to custom headers only', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        switch (options.uri.path) {
          case '/System/Info':
            return const _StatusBody(401, 'Forbidden');
          case '/System/Info/Public':
            return {'ServerName': 'Public Jelly', 'Version': '12.2.0'};
        }
        return <String, dynamic>{};
      });
      final service = _buildService(
        adapter,
        apiKey: '',
        headers: [InstanceHeader(name: 'Authorization', value: 'Basic !!!')],
      );

      // When
      final status = await service.getSystemStatus();

      // Then
      expect(
        adapter.requests.any((uri) => uri.path == '/Users/AuthenticateByName'),
        isFalse,
      );
      expect(service.supportsProgressSync, isFalse);
      expect(status.instanceName, 'Public Jelly');
    });

    test('throws when /System/Info rejects the API key with 401', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        switch (options.uri.path) {
          case '/System/Info':
            return const _StatusBody(401, 'Unauthorized');
          case '/System/Info/Public':
            return {'ServerName': 'Public Jelly', 'Version': '10.8.0'};
        }
        return <String, dynamic>{};
      });
      final service = _serviceApiKey(adapter);

      // When
      final call = service.getSystemStatus();

      // Then
      await expectLater(call, throwsA(isA<Exception>()));
      expect(adapter.requests.map((uri) => uri.path), ['/System/Info']);
    });

    test(
      'falls back to /System/Info/Public when a non-admin user gets 403 on /System/Info',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Users/AuthenticateByName':
              return {
                'AccessToken': 'token-123',
                'User': {
                  'Id': 'user-9',
                  'Name': 'regular',
                  'Policy': {'IsAdministrator': false},
                },
              };
            case '/System/Info':
              return const _StatusBody(403, 'Forbidden');
            case '/System/Info/Public':
              return {'ServerName': 'Public Jelly', 'Version': '10.8.0'};
          }
          return <String, dynamic>{};
        });
        final service = _serviceUserPassword(adapter);

        // When
        final status = await service.getSystemStatus();

        // Then
        // The login made only for the check is signed out afterwards.
        expect(adapter.requests.map((uri) => uri.path), [
          '/Users/AuthenticateByName',
          '/System/Info',
          '/System/Info/Public',
          '/Sessions/Logout',
        ]);
        expect(status.instanceName, 'Public Jelly');
        expect(status.version, '10.8.0');
        expect(status.authentication, 'Credentials');
      },
    );

    test('resolves the injected device id once across logins', () async {
      // Given
      var resolutions = 0;
      final adapter = _RecordingAdapter((options) {
        switch (options.uri.path) {
          case '/Users/AuthenticateByName':
            return {
              'AccessToken': 'token-123',
              'User': {'Id': 'user-9', 'Name': 'admin'},
            };
        }
        return <String, dynamic>{};
      });
      final service = _buildService(
        adapter,
        apiKey: 'admin:pass',
        deviceIdResolver: () async {
          resolutions++;
          return 'counted-device-1';
        },
      );

      // When
      await service.getSystemStatus();
      await service.getSystemStatus();

      // Two logins share one resolution: the id identifies the installation,
      // and re-resolving could churn Jellyfin device registrations.
      // Then
      expect(resolutions, 1);
      expect(
        adapter.headers.first['Authorization'],
        contains('DeviceId="counted-device-1"'),
      );
    });
  });

  group('JellyfinService credential validation', () {
    test(
      'rejects an API key whose /System/Info call fails at the transport '
      'level while the public endpoint answers',
      () async {
        // Given — browsers surface a 401 without CORS headers this way.
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/System/Info':
              return const _TransportFailure();
            case '/System/Info/Public':
              return {'ServerName': 'Public Jelly', 'Version': '12.2.0'};
          }
          return <String, dynamic>{};
        });
        final service = _buildService(adapter, apiKey: 'xyz');

        // When
        final call = service.getSystemStatus();

        // Then
        await expectLater(
          call,
          throwsA(
            isA<UnauthorizedError>().having(
              (e) => e.message,
              'message',
              contains('Invalid Jellyfin credentials'),
            ),
          ),
        );
      },
    );

    test('reports an unreachable server, not a raw error', () async {
      // Given
      final adapter = _RecordingAdapter((_) => const _TransportFailure());
      final service = _buildService(adapter, apiKey: 'xyz');

      // When
      final call = service.getSystemStatus();

      // Then
      await expectLater(
        call,
        throwsA(
          isA<ConnectionError>().having(
            (e) => e.message,
            'message',
            contains('unreachable'),
          ),
        ),
      );
    });

    test('maps a refused sign-in to invalid credentials', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        if (options.uri.path == '/Users/AuthenticateByName') {
          return const _StatusBody(401, 'Unauthorized');
        }
        return <String, dynamic>{};
      });
      final service = _buildService(adapter, apiKey: 'demo:wrong');

      // When
      final call = service.getSystemStatus();

      // Then
      await expectLater(call, throwsA(isA<UnauthorizedError>()));
    });

    test(
      'maps a transport-level sign-in failure on a reachable server to '
      'invalid credentials',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Users/AuthenticateByName':
              return const _TransportFailure();
            case '/System/Info/Public':
              return {'ServerName': 'Public Jelly', 'Version': '12.2.0'};
          }
          return <String, dynamic>{};
        });
        final service = _buildService(adapter, apiKey: 'demo:wrong');

        // When
        final call = service.getSystemStatus();

        // Then
        await expectLater(call, throwsA(isA<UnauthorizedError>()));
      },
    );
  });

  group('JellyfinService sessions', () {
    const storedSession = InstanceUserSession(
      accessToken: 'stored-token',
      deviceId: 'arrmate-device-7',
      userId: 'user-9',
      userName: 'admin',
      isAdministrator: true,
    );

    test('signIn returns a session with a per-instance device id', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        if (options.uri.path == '/Users/AuthenticateByName') {
          return {
            'AccessToken': 'token-123',
            'User': {
              'Id': 'user-9',
              'Name': 'admin',
              'Policy': {'IsAdministrator': true},
            },
          };
        }
        return <String, dynamic>{};
      });
      final service = _serviceUserPassword(adapter);

      // When
      final session = await service.signIn();

      // Then
      expect(session.accessToken, 'token-123');
      expect(session.userId, 'user-9');
      expect(session.userName, 'admin');
      expect(session.isAdministrator, isTrue);
      expect(session.deviceId, startsWith('arrmate-'));
      expect(session.deviceId, isNot('install-user-1'));
      expect(
        adapter.headers.single['Authorization'],
        contains('DeviceId="${session.deviceId}"'),
      );
    });

    test('signing in again reuses the stored session device id', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        return {
          'AccessToken': 'token-456',
          'User': {'Id': 'user-9', 'Name': 'admin'},
        };
      });
      final service = _buildService(
        adapter,
        apiKey: 'admin:newpass',
        userSession: storedSession,
      );

      // When
      final session = await service.signIn();

      // Then
      expect(session.accessToken, 'token-456');
      expect(session.deviceId, 'arrmate-device-7');
    });

    test('signIn without credentials asks for them', () async {
      // Given
      final adapter = _RecordingAdapter((_) => <String, dynamic>{});
      final service = _buildService(adapter, apiKey: 'plain-key');

      // When
      final call = service.signIn();

      // Then
      await expectLater(call, throwsA(isA<MissingDataError>()));
      expect(adapter.requests, isEmpty);
    });

    test('uses the stored session token without signing in', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        if (options.uri.path == '/System/Info') {
          return {'ServerName': 'Jelly', 'Version': '12.2.0'};
        }
        return <String, dynamic>{};
      });
      final service = _buildService(
        adapter,
        apiKey: '',
        userSession: storedSession,
      );

      // When
      final status = await service.getSystemStatus();

      // Then
      expect(adapter.requests.map((uri) => uri.path), ['/System/Info']);
      expect(
        adapter.headers.single['Authorization'],
        allOf(
          contains('Token="stored-token"'),
          contains('DeviceId="arrmate-device-7"'),
        ),
      );
      expect(service.supportsProgressSync, isTrue);
      expect(status.authentication, 'Credentials');
    });

    test('asks to sign in again when the stored session is rejected', () async {
      // Given
      final adapter = _RecordingAdapter(
        (_) => const _StatusBody(401, 'Unauthorized'),
      );
      final service = _buildService(
        adapter,
        apiKey: '',
        userSession: storedSession,
      );

      // When
      final call = service.getSystemStatus();

      // Then — no password is stored, so nothing is replayed.
      await expectLater(
        call,
        throwsA(
          isA<UnauthorizedError>().having(
            (e) => e.message,
            'message',
            contains('Sign in again'),
          ),
        ),
      );
      expect(
        adapter.requests.any((uri) => uri.path == '/Users/AuthenticateByName'),
        isFalse,
      );
    });

    test('logout ends the stored session', () async {
      // Given
      final adapter = _RecordingAdapter((_) => const _StatusBody(204, ''));
      final service = _buildService(
        adapter,
        apiKey: '',
        userSession: storedSession,
      );

      // When
      await service.logout();

      // Then
      expect(adapter.requests.single.path, '/Sessions/Logout');
      expect(adapter.methods.single, 'POST');
      expect(
        adapter.headers.single['Authorization'],
        contains('Token="stored-token"'),
      );
    });

    test('logout is a no-op for an API key', () async {
      // Given
      final adapter = _RecordingAdapter((_) => <String, dynamic>{});
      final service = _serviceApiKey(adapter);

      // When
      await service.logout();

      // Then
      expect(adapter.requests, isEmpty);
    });

    test('revokeApiKey deletes exactly the given key', () async {
      // Given
      final adapter = _RecordingAdapter((_) => const _StatusBody(204, ''));
      final service = _buildService(
        adapter,
        apiKey: '',
        userSession: storedSession,
      );

      // When
      await service.revokeApiKey('owned-key');

      // Then — no lookup by name: other "Arrmate" keys stay untouched.
      expect(adapter.methods, ['DELETE']);
      expect(adapter.requests.single.path, '/Auth/Keys/owned-key');
    });

    test('revokeApiKey explains a refused revocation', () async {
      // Given
      final adapter = _RecordingAdapter((_) => const _StatusBody(403, ''));
      final service = _buildService(
        adapter,
        apiKey: '',
        userSession: storedSession,
      );

      // When
      final call = service.revokeApiKey('owned-key');

      // Then
      await expectLater(
        call,
        throwsA(
          isA<UnauthorizedError>().having(
            (e) => e.message,
            'message',
            contains('administrator'),
          ),
        ),
      );
    });

    test('withoutBasicCredentials drops only the Basic credentials header', () {
      // Given
      final headers = _instanceWithBasicAuth(apiKey: '').headers;

      // When
      final filtered = JellyfinService.withoutBasicCredentials(headers);

      // Then
      expect(filtered.map((h) => h.name), ['X-Proxy']);
    });
  });

  group('JellyfinService resolvePlayableItem', () {
    test(
      'matches an item whose path equals the target after normalization',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Items':
              return {
                'Items': [
                  _itemJson(
                    id: 'item-1',
                    path: '/Data/Movies/MOVIE.2024.1080P.MKv',
                    mediaSourceId: 'src-1',
                  ),
                ],
                'TotalRecordCount': 1,
              };
          }
          return <String, dynamic>{};
        });
        final service = _serviceApiKey(adapter);

        // When
        final item = await service.resolvePlayableItem(
          filePath: '/data/movies/movie.2024.1080p.mkv',
          isEpisode: false,
        );

        // Then
        expect(item?.id, 'item-1');
        expect(item?.providerIds, isEmpty);
      },
    );

    test(
      'matches the same file name under the same parent across roots',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Items':
              // A freshly scanned item: matching path tail, no provider ids.
              return {
                'Items': [
                  _itemJson(
                    id: 'item-tail',
                    path:
                        '/data/tvseries/sonarr/Dark Matter/Season 2/Dark.Matter.S02E07.mkv',
                    mediaSourceId: 'src-tail',
                  ),
                ],
                'TotalRecordCount': 1,
              };
          }
          return <String, dynamic>{};
        });
        final service = _serviceApiKey(adapter);

        // When
        final item = await service.resolvePlayableItem(
          filePath:
              '/data/tvshows/Dark Matter (2024)/Season 2/Dark.Matter.S02E07.mkv',
          isEpisode: true,
          seriesName: 'Dark Matter',
          seasonNumber: 2,
          episodeNumber: 7,
        );

        // Then
        expect(item?.id, 'item-tail');
      },
    );

    test('suffix-matches the item and ignores unrelated results', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        switch (options.uri.path) {
          case '/Items':
            expect(
              options.uri.queryParameters['SearchTerm'],
              'Movie.2024.1080p',
            );
            expect(options.uri.queryParameters['Recursive'], 'true');
            expect(
              options.uri.queryParameters['IncludeItemTypes'],
              'Movie,Episode,Video',
            );
            return {
              'Items': [
                _itemJson(
                  id: 'item-other',
                  path: '/somewhere/else/Other.File.mkv',
                  mediaSourceId: 'src-x',
                ),
                _itemJson(
                  id: 'item-1',
                  path: '/media/data/Movies/Movie 2024/Movie.2024.1080p.mkv',
                  mediaSourceId: 'src-1',
                ),
              ],
              'TotalRecordCount': 2,
            };
        }
        return <String, dynamic>{};
      });
      final service = _serviceApiKey(adapter);

      // When
      final item = await service.resolvePlayableItem(
        filePath: '/data/Movies/Movie 2024/Movie.2024.1080p.mkv',
        isEpisode: false,
      );

      // Then
      expect(item?.id, 'item-1');
    });

    test(
      'scans via Media/Updated only and finds the item while polling',
      () async {
        // Given
        var mediaUpdatedPosted = false;
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Items':
              if (!mediaUpdatedPosted) {
                return {'Items': [], 'TotalRecordCount': 0};
              }
              return {
                'Items': [
                  _itemJson(
                    id: 'item-new',
                    path: '/data/movies/New Movie/New.Movie.2024.mkv',
                    mediaSourceId: 'src-new',
                  ),
                ],
                'TotalRecordCount': 1,
              };
            case '/Library/Media/Updated':
              mediaUpdatedPosted = true;
              return const _StatusBody(204, '');
          }
          return <String, dynamic>{};
        });
        final service = _serviceApiKey(adapter);
        final progress = <String>[];

        // When
        final item = await service.resolvePlayableItem(
          filePath: '/data/movies/New Movie/New.Movie.2024.mkv',
          isEpisode: false,
          onProgress: progress.add,
        );

        // Then
        expect(item?.id, 'item-new');
        final updatedIndex = adapter.requests.indexWhere(
          (uri) => uri.path == '/Library/Media/Updated',
        );
        expect(updatedIndex, greaterThanOrEqualTo(0));
        expect(adapter.bodies[updatedIndex], {
          'Updates': [
            {
              'Path': '/data/movies/New Movie/New.Movie.2024.mkv',
              'UpdateType': 'Created',
            },
          ],
        });
        // The virtual folder lookup, per-folder refresh, and full scan are
        // admin-only routes: none of them may be touched.
        expect(
          adapter.requests.any(
            (uri) =>
                uri.path == '/Library/VirtualFolders' ||
                uri.path == '/Library/Refresh' ||
                uri.path.endsWith('/Refresh'),
          ),
          isFalse,
        );
        expect(progress, contains('Waiting for Jellyfin to index the file...'));
      },
    );

    test(
      'reports the refusal and aborts when the user may not scan (403)',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Items':
              return {'Items': [], 'TotalRecordCount': 0};
            case '/Library/Media/Updated':
              return const _StatusBody(403, 'Forbidden');
          }
          return <String, dynamic>{};
        });
        final service = _serviceApiKey(adapter);
        final progress = <String>[];

        // When
        final item = await service.resolvePlayableItem(
          filePath: '/data/movies/Ghost/Ghost.2024.mkv',
          isEpisode: false,
          onProgress: progress.add,
        );

        // Then
        expect(item, isNull);
        expect(
          progress,
          contains('Jellyfin user cannot trigger a library scan'),
        );
        // Polling after a refused scan would be pointless: nothing follows.
        expect(adapter.requests.last.path, '/Library/Media/Updated');
      },
    );

    test(
      'never returns a candidate that matches neither path nor provider ids',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Items':
              // The fake ignores every server-side filter: the returned item
              // carries the searched name but the wrong path and ids.
              return {
                'Items': [
                  _itemJson(
                    id: 'wrong-1',
                    path: '/x/Some.Other.File.mkv',
                    mediaSourceId: 'src-w',
                    providerIds: {'Tmdb': '999'},
                  ),
                ],
                'TotalRecordCount': 1,
              };
            case '/Library/Media/Updated':
              return const _StatusBody(403, '');
          }
          return <String, dynamic>{};
        });
        final service = _serviceApiKey(adapter);

        // When
        final item = await service.resolvePlayableItem(
          filePath: '/data/movies/Wanted Movie/Wanted.Movie.2024.mkv',
          title: 'Wanted Movie',
          tmdbId: 42,
          isEpisode: false,
        );

        // An unproven candidate must be rejected even when the server
        // "matched" it — a wrong title would play the wrong movie.
        // Then
        expect(item, isNull);
        expect(adapter.requests.last.path, '/Library/Media/Updated');
      },
    );

    test(
      'title search validates the tmdb id client-side among decoys',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Items':
              expect(options.uri.queryParameters['SearchTerm'], 'Movie');
              expect(options.uri.queryParameters['years'], '2024');
              expect(
                options.uri.queryParameters.containsKey('AnyProviderIdEquals'),
                isFalse,
              );
              return {
                'Items': [
                  _itemJson(
                    id: 'decoy',
                    path: '/data/movies/other.mkv',
                    mediaSourceId: 'src-d',
                    providerIds: {'Tmdb': '111'},
                  ),
                  _itemJson(
                    id: 'item-right',
                    path: '/somewhere/wrong.mkv',
                    mediaSourceId: 'src-r',
                    providerIds: {'Tmdb': '411'},
                  ),
                ],
                'TotalRecordCount': 2,
              };
          }
          return <String, dynamic>{};
        });
        final service = _serviceApiKey(adapter);

        // When
        final item = await service.resolvePlayableItem(
          filePath: '/data/movies/Movie.2024.mkv',
          title: 'Movie',
          productionYear: 2024,
          tmdbId: 411,
          isEpisode: false,
        );

        // Then
        expect(item?.id, 'item-right');
        // Found during the title search; no scan is requested.
        expect(
          adapter.requests.any((uri) => uri.path == '/Library/Media/Updated'),
          isFalse,
        );
      },
    );

    test('validates a movie by imdb id case-insensitively', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        switch (options.uri.path) {
          case '/Items':
            return {
              'Items': [
                _itemJson(
                  id: 'item-imdb',
                  path: '/somewhere/else/Movie.2024.mkv',
                  mediaSourceId: 'src-1',
                  providerIds: {'Imdb': 'TT0117731'},
                ),
              ],
              'TotalRecordCount': 1,
            };
        }
        return <String, dynamic>{};
      });
      final service = _serviceApiKey(adapter);

      // When
      final item = await service.resolvePlayableItem(
        filePath: '/data/movies/Movie.2024.mkv',
        title: 'Movie',
        imdbId: 'tt0117731',
        isEpisode: false,
      );

      // Then
      expect(item?.id, 'item-imdb');
    });

    test(
      'lists episodes via the season param and filters numbers client-side',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Items':
              if (options.uri.queryParameters['IncludeItemTypes'] == 'Series') {
                expect(options.uri.queryParameters['SearchTerm'], 'Show');
                return {
                  'Items': [
                    // Right name, wrong show: only the tvdb id tells them
                    // apart.
                    {
                      'Id': 'series-decoy',
                      'Name': 'Show',
                      'Type': 'Series',
                      'ProviderIds': {'Tvdb': '999'},
                    },
                    {
                      'Id': 'series-1',
                      'Name': 'Show',
                      'Type': 'Series',
                      'ProviderIds': {'Tvdb': '121361'},
                    },
                  ],
                  'TotalRecordCount': 2,
                };
              }
              // Stage 1 title search: unrelated episode, rejected by the
              // client-side path/tvdb validation.
              return {
                'Items': [
                  _itemJson(
                    id: 'decoy-ep',
                    type: 'Episode',
                    path: '/data/tv/Other/S01/E01.mkv',
                    mediaSourceId: 'src-decoy',
                  ),
                ],
                'TotalRecordCount': 1,
              };
            case '/Shows/series-1/Episodes':
              expect(options.uri.queryParameters['season'], '2');
              expect(
                options.uri.queryParameters.containsKey('seasonNumber'),
                isFalse,
              );
              expect(
                options.uri.queryParameters.containsKey('episodeNumber'),
                isFalse,
              );
              // The server "ignored" the season filter and returned both.
              return {
                'Items': [
                  {
                    'Id': 'ep-s01e01',
                    'Name': 'Pilot',
                    'Type': 'Episode',
                    'Path': '/data/tv/Show/S01/E01.mkv',
                    'ParentIndexNumber': 1,
                    'IndexNumber': 1,
                    'MediaSources': [
                      _mediaSourceJson(
                        id: 'src-s01e01',
                        path: '/data/tv/Show/S01/E01.mkv',
                      ),
                    ],
                  },
                  {
                    'Id': 'ep-s02e05',
                    'Name': 'Episode 5',
                    'Type': 'Episode',
                    'Path': '/data/tv/Show/S02/E05.mkv',
                    'ParentIndexNumber': 2,
                    'IndexNumber': 5,
                    'MediaSources': [
                      _mediaSourceJson(
                        id: 'src-s02e05',
                        path: '/data/tv/Show/S02/E05.mkv',
                      ),
                    ],
                  },
                ],
                'TotalRecordCount': 2,
              };
          }
          return <String, dynamic>{};
        });
        final service = _serviceApiKey(adapter);

        // When
        final item = await service.resolvePlayableItem(
          filePath: '/data/tv/Show/S02/E05.mkv',
          isEpisode: true,
          seriesName: 'Show',
          seriesTvdbId: 121361,
          seasonNumber: 2,
          episodeNumber: 5,
        );

        // S02E05, never the S01E01 the unfiltered listing offered first.
        // Then
        expect(item?.id, 'ep-s02e05');
        expect(
          adapter.requests.any(
            (uri) => uri.queryParameters.containsKey('AnyProviderIdEquals'),
          ),
          isFalse,
        );
      },
    );

    test('accepts an episode from the title search by its tvdb id', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        switch (options.uri.path) {
          case '/Items':
            // Ignores the search filters: the path belongs to a different
            // file, only the episode tvdb id proves the match.
            return {
              'Items': [
                {
                  'Id': 'ep-by-tvdb',
                  'Name': 'Different Name',
                  'Type': 'Episode',
                  'Path': '/mount/x/Wrong.Episode.mkv',
                  'ProviderIds': {'Tvdb': '555555'},
                  'MediaSources': [
                    _mediaSourceJson(
                      id: 'src-ep',
                      path: '/mount/x/Wrong.Episode.mkv',
                    ),
                  ],
                },
              ],
              'TotalRecordCount': 1,
            };
        }
        return <String, dynamic>{};
      });
      final service = _serviceApiKey(adapter);

      // When
      final item = await service.resolvePlayableItem(
        filePath: '/data/tv/Show/S02/E05.mkv',
        isEpisode: true,
        seriesName: 'Show',
        episodeTvdbId: 555555,
        seasonNumber: 2,
        episodeNumber: 5,
      );

      // Then
      expect(item?.id, 'ep-by-tvdb');
    });

    test('strips a year suffix from the series name when searching', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        switch (options.uri.path) {
          case '/Items':
            final term = options.uri.queryParameters['SearchTerm'];
            // The catalogued series carries the bare name; a suffixed
            // term must not be the only one tried.
            if (options.uri.queryParameters['IncludeItemTypes'] == 'Series' &&
                term == 'Dark Matter') {
              return {
                'Items': [
                  {
                    'Id': 'series-1',
                    'Name': 'Dark Matter',
                    'Type': 'Series',
                    'ProviderIds': {'Tvdb': '371980'},
                  },
                ],
                'TotalRecordCount': 1,
              };
            }
            return {'Items': [], 'TotalRecordCount': 0};
          case '/Shows/series-1/Episodes':
            return {
              'Items': [
                {
                  'Id': 'ep-207',
                  'Name': 'The Pyramid',
                  'Type': 'Episode',
                  'Path': '/data/tvshows/Dark Matter/Season 2/E07.mkv',
                  'ParentIndexNumber': 2,
                  'IndexNumber': 7,
                  'MediaSources': [
                    _mediaSourceJson(
                      id: 'src-207',
                      path: '/data/tvshows/Dark Matter/Season 2/E07.mkv',
                    ),
                  ],
                },
              ],
              'TotalRecordCount': 1,
            };
        }
        return <String, dynamic>{};
      });
      final service = _serviceApiKey(
        adapter,
        pollInterval: Duration.zero,
        pollTimeout: Duration.zero,
      );

      // When
      final item = await service.resolvePlayableItem(
        filePath:
            '/data/tvshows/Dark Matter (2024)/Season 2/Dark.Matter.S02E07.mkv',
        isEpisode: true,
        seriesName: 'Dark Matter (2024)',
        seriesTvdbId: 371980,
        seasonNumber: 2,
        episodeNumber: 7,
      );

      // Then
      final terms = adapter.requests
          .where((uri) => uri.path == '/Items')
          .map((uri) => uri.queryParameters['SearchTerm'])
          .toList();
      expect(terms, contains('Dark Matter'));
      expect(item?.id, 'ep-207');
    });

    test(
      'accepts a unique series name match when no tvdb id is available',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Items':
              if (options.uri.queryParameters['IncludeItemTypes'] == 'Series') {
                return {
                  'Items': [
                    {'Id': 'series-1', 'Name': 'Show', 'Type': 'Series'},
                  ],
                  'TotalRecordCount': 1,
                };
              }
              return {'Items': [], 'TotalRecordCount': 0};
            case '/Shows/series-1/Episodes':
              return {
                'Items': [
                  {
                    'Id': 'ep-1',
                    'Type': 'Episode',
                    'Path': '/data/tv/Show/S02/E05.mkv',
                    'ParentIndexNumber': 2,
                    'IndexNumber': 5,
                    'MediaSources': [
                      _mediaSourceJson(
                        id: 'src-ep',
                        path: '/data/tv/Show/S02/E05.mkv',
                      ),
                    ],
                  },
                ],
                'TotalRecordCount': 1,
              };
          }
          return <String, dynamic>{};
        });
        final service = _serviceApiKey(adapter);

        // When
        final item = await service.resolvePlayableItem(
          filePath: '/data/tv/Show/S02/E05.mkv',
          isEpisode: true,
          seriesName: 'Show',
          seasonNumber: 2,
          episodeNumber: 5,
        );

        // Then
        expect(item?.id, 'ep-1');
      },
    );

    test(
      'refuses to guess when several catalogued series share the name',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Items':
              if (options.uri.queryParameters['IncludeItemTypes'] == 'Series') {
                return {
                  'Items': [
                    {'Id': 'series-a', 'Name': 'Show', 'Type': 'Series'},
                    {'Id': 'series-b', 'Name': 'Show', 'Type': 'Series'},
                  ],
                  'TotalRecordCount': 2,
                };
              }
              return {'Items': [], 'TotalRecordCount': 0};
            case '/Library/Media/Updated':
              return const _StatusBody(403, '');
          }
          return <String, dynamic>{};
        });
        final service = _serviceApiKey(adapter);

        // When
        final item = await service.resolvePlayableItem(
          filePath: '/data/tv/Show/S02/E05.mkv',
          isEpisode: true,
          seriesName: 'Show',
          seasonNumber: 2,
          episodeNumber: 5,
        );

        // Then
        expect(item, isNull);
        // Without a proven series the episode listing is never requested.
        expect(
          adapter.requests.any((uri) => uri.path.startsWith('/Shows/')),
          isFalse,
        );
      },
    );
  });

  group('JellyfinService getPlaybackSession', () {
    test('stream headers never carry a custom Basic authorization', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        switch (options.uri.path) {
          case '/Users/AuthenticateByName':
            return {
              'AccessToken': 'token-123',
              'User': {'Id': 'user-9', 'Name': 'lucas'},
            };
          case '/Items/item-1/PlaybackInfo':
            return {
              'MediaSources': [_mediaSourceJson(id: 'src-1')],
            };
        }
        return <String, dynamic>{};
      });
      final instance = _instanceWithBasicAuth(apiKey: 'lucas:secret');
      final dio = Dio()
        ..httpClientAdapter = adapter
        ..options.baseUrl = instance.effectiveUrl
        ..options.validateStatus = (status) => status != null && status < 500;
      final service = JellyfinService(instance, dio: dio);

      // When
      final session = await service.getPlaybackSession(_playableItem());

      // Then
      expect(
        session.httpHeaders['Authorization'],
        contains('MediaBrowser Client="Arrmate"'),
      );
      expect(session.httpHeaders['X-Proxy'], 'keep-me');
      for (final value in session.httpHeaders.values) {
        expect(value, isNot(contains('Basic ')));
      }
    });

    test('builds the static stream URL plus the HLS alternative and extracts '
        'streams', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        switch (options.uri.path) {
          case '/Items/item-1/PlaybackInfo':
            return {
              'MediaSources': [_mediaSourceJson(id: 'src-1')],
            };
        }
        return <String, dynamic>{};
      });
      final service = _serviceApiKey(adapter);

      // When
      final session = await service.getPlaybackSession(_playableItem());

      // Then
      expect(session.itemId, 'item-1');
      expect(session.mediaSourceId, 'src-1');
      expect(
        session.streamUrl.toString(),
        'http://jf.test/Videos/item-1/stream'
        '?static=true&MediaSourceId=src-1&ApiKey=jelly-key',
      );
      // The HLS alternative is always produced (default bitrate cap) so
      // the player can switch quality or fall back from Direct Play.
      expect(
        session.hlsUrl.toString(),
        'http://jf.test/Videos/item-1/master.m3u8'
        '?MediaSourceId=src-1&ApiKey=jelly-key'
        '&VideoBitrate=4000000&VideoCodec=h264&AudioCodec=aac%2Cmp3',
      );
      expect(
        session.httpHeaders['Authorization'],
        allOf(
          contains('MediaBrowser Client="Arrmate"'),
          contains('Token="jelly-key"'),
        ),
      );
      // API-key mode has no user scope: resume must stay untouched.
      expect(session.playbackPosition, Duration.zero);
      expect(session.audioStreams, hasLength(1));
      expect(session.audioStreams.first.displayTitle, 'English AAC');
      expect(session.subtitleStreams, hasLength(1));
      expect(
        session.subtitleStreams.first.deliveryUrl,
        '/Videos/item-1/src-1/Subtitles/2/0/Stream.vtt',
      );

      // No user id is guessed for PlaybackInfo in API-key mode, and the
      // handshake carries a device profile so external subtitle streams
      // come back with a DeliveryUrl.
      final playbackInfoIndex = adapter.requests.indexWhere(
        (uri) => uri.path == '/Items/item-1/PlaybackInfo',
      );
      expect(adapter.bodies[playbackInfoIndex], {
        'IsPlayback': true,
        'AutoOpenLiveStream': true,
        'DeviceProfile': {
          'SubtitleProfiles': [
            {'Format': 'vtt', 'Method': 'External'},
            {'Format': 'srt', 'Method': 'External'},
            {'Format': 'ass', 'Method': 'External'},
            {'Format': 'ssa', 'Method': 'External'},
          ],
        },
      });
      final playbackInfoRequest = adapter.requests.firstWhere(
        (uri) => uri.path == '/Items/item-1/PlaybackInfo',
      );
      expect(
        playbackInfoRequest.queryParameters.containsKey('userId'),
        isFalse,
      );
    });

    test(
      'user mode resumes from the stored position and sends the user id',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Users/AuthenticateByName':
              return {
                'AccessToken': 'token-123',
                'User': {'Id': 'user-9', 'Name': 'admin'},
              };
            case '/Items/item-1/PlaybackInfo':
              return {
                'MediaSources': [_mediaSourceJson(id: 'src-1')],
              };
          }
          return <String, dynamic>{};
        });
        final service = _serviceUserPassword(adapter);

        // When
        final session = await service.getPlaybackSession(_playableItem());

        // 300000000 Jellyfin ticks are 100 ns each: 30 s of resume position
        // for the authenticated user.
        // Then
        expect(session.playbackPosition, const Duration(seconds: 30));
        final playbackInfoRequest = adapter.requests.firstWhere(
          (uri) => uri.path == '/Items/item-1/PlaybackInfo',
        );
        expect(playbackInfoRequest.queryParameters['userId'], 'user-9');
        expect(
          adapter.headers.last['Authorization'],
          contains('Token="token-123"'),
        );
      },
    );

    test('keeps Direct Play primary and caps the HLS alternative at the '
        'requested bitrate', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        switch (options.uri.path) {
          case '/Items/item-1/PlaybackInfo':
            return {
              'MediaSources': [_mediaSourceJson(id: 'src-1')],
            };
        }
        return <String, dynamic>{};
      });
      final service = _serviceApiKey(adapter);

      // When
      final session = await service.getPlaybackSession(
        _playableItem(),
        maxBitrate: 8000000,
      );

      // Then
      expect(
        session.streamUrl.toString(),
        'http://jf.test/Videos/item-1/stream'
        '?static=true&MediaSourceId=src-1&ApiKey=jelly-key',
      );
      expect(
        session.hlsUrl.toString(),
        'http://jf.test/Videos/item-1/master.m3u8'
        '?MediaSourceId=src-1&ApiKey=jelly-key'
        '&VideoBitrate=8000000&VideoCodec=h264&AudioCodec=aac%2Cmp3',
      );
    });
  });

  group('JellyfinService ensureApiKey', () {
    test(
      'mints an Arrmate key for an administrator when none exists',
      () async {
        // Given
        var keysCreated = false;
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Users/AuthenticateByName':
              return {
                'AccessToken': 'token-123',
                'User': {
                  'Id': 'user-9',
                  'Name': 'admin',
                  'Policy': {'IsAdministrator': true},
                },
              };
            case '/Auth/Keys':
              if (options.method == 'POST') {
                keysCreated = true;
                return const _StatusBody(204, '');
              }
              // The list endpoint answers with an
              // AuthenticationInfoQueryResult.
              return {
                'TotalRecordCount': keysCreated ? 1 : 0,
                'Items': keysCreated
                    ? [
                        {
                          'AccessTokenId': 'abc',
                          'AppName': 'Arrmate',
                          'AccessToken': 'minted-key',
                        },
                      ]
                    : <Map<String, dynamic>>[],
              };
          }
          return <String, dynamic>{};
        });
        final service = _serviceUserPassword(adapter);

        // When
        final key = await service.ensureApiKey();

        // Then
        expect(key?.key, 'minted-key');
        expect(key?.created, isTrue);
        final postKeysIndex = <int>[
          for (var i = 0; i < adapter.requests.length; i++)
            if (adapter.requests[i].path == '/Auth/Keys' &&
                adapter.methods[i] == 'POST')
              i,
        ].single;
        expect(
          adapter.requests[postKeysIndex].queryParameters['app'],
          'Arrmate',
        );
      },
    );

    test('reuses an existing Arrmate key without creating a new one', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        switch (options.uri.path) {
          case '/Users/AuthenticateByName':
            return {
              'AccessToken': 'token-123',
              'User': {
                'Id': 'user-9',
                'Name': 'admin',
                'Policy': {'IsAdministrator': true},
              },
            };
          case '/Auth/Keys':
            return {
              'TotalRecordCount': 1,
              'Items': [
                {
                  'AccessTokenId': 'abc',
                  'AppName': 'arrmate',
                  'AccessToken': 'existing-key',
                },
              ],
            };
        }
        return <String, dynamic>{};
      });
      final service = _serviceUserPassword(adapter);

      // When
      final key = await service.ensureApiKey();

      // Then
      expect(key?.key, 'existing-key');
      expect(key?.created, isFalse);
      final authKeysIndexes = <int>[
        for (var i = 0; i < adapter.requests.length; i++)
          if (adapter.requests[i].path == '/Auth/Keys') i,
      ];
      expect(authKeysIndexes, hasLength(1));
      expect(adapter.methods[authKeysIndexes.single], 'GET');
    });

    test(
      'returns null for a non-administrator without touching /Auth/Keys',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/Users/AuthenticateByName':
              return {
                'AccessToken': 'token-123',
                'User': {
                  'Id': 'user-9',
                  'Name': 'regular',
                  'Policy': {'IsAdministrator': false},
                },
              };
          }
          return <String, dynamic>{};
        });
        final service = _serviceUserPassword(adapter);

        // When
        final key = await service.ensureApiKey();

        // Then
        expect(key, isNull);
        expect(
          adapter.requests.any((uri) => uri.path == '/Auth/Keys'),
          isFalse,
        );
      },
    );

    test('returns null in API-key mode', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        return <String, dynamic>{};
      });
      final service = _serviceApiKey(adapter);

      // When
      final key = await service.ensureApiKey();

      // Then
      expect(key, isNull);
      expect(adapter.requests, isEmpty);
    });
  });

  group('JellyfinService playback reporting', () {
    test('reports progress and stop for the authenticated user', () async {
      // Given
      final adapter = _RecordingAdapter((options) {
        switch (options.uri.path) {
          case '/Users/AuthenticateByName':
            return {
              'AccessToken': 'token-123',
              'User': {'Id': 'user-9', 'Name': 'admin'},
            };
          case '/Sessions/Playing/Progress':
            return const _StatusBody(500, 'boom');
        }
        return <String, dynamic>{};
      });
      final service = _serviceUserPassword(adapter);

      // When
      await service.reportPlaybackProgress(
        itemId: 'item-1',
        mediaSourceId: 'src-1',
        position: const Duration(minutes: 1),
        isPaused: false,
      );
      await service.reportPlaybackStopped(
        itemId: 'item-1',
        mediaSourceId: 'src-1',
        position: const Duration(minutes: 2),
      );

      final progressIndex = adapter.requests.indexWhere(
        (uri) => uri.path == '/Sessions/Playing/Progress',
      );
      final progressBody = adapter.bodies[progressIndex]! as Map;
      // Then
      expect(progressBody['PositionTicks'], 600000000);
      expect(progressBody['IsPaused'], false);
      final stopIndex = adapter.requests.indexWhere(
        (uri) => uri.path == '/Sessions/Playing/Stopped',
      );
      final stopBody = adapter.bodies[stopIndex]! as Map;
      expect(stopBody['PositionTicks'], 1200000000);
      expect(
        adapter.requests
            .where((uri) => uri.path.startsWith('/Sessions/Playing/'))
            .map((uri) => uri.queryParameters['userId']),
        everyElement('user-9'),
      );
      // A failed progress report never aborts the session.
      expect(progressBody, isNotNull);
    });

    test(
      'api-key mode never touches the playback reporting endpoints',
      () async {
        // Given
        final adapter = _RecordingAdapter((options) {
          switch (options.uri.path) {
            case '/System/Info':
              return {'ServerName': 'Jelly', 'Version': '10.9.0'};
          }
          return <String, dynamic>{};
        });
        final service = _serviceApiKey(adapter);

        // When
        await service.reportPlaybackProgress(
          itemId: 'item-1',
          mediaSourceId: 'src-1',
          position: const Duration(minutes: 1),
          isPaused: false,
        );
        await service.reportPlaybackStopped(
          itemId: 'item-1',
          mediaSourceId: 'src-1',
          position: const Duration(minutes: 2),
        );

        // Watch-state writes are per-user data; a scope-less API key must
        // not attribute them to an arbitrary account.
        // Then
        expect(
          adapter.requests.any(
            (uri) => uri.path.startsWith('/Sessions/Playing/'),
          ),
          isFalse,
        );
      },
    );
  });
}

/// Jellyfin item JSON used across playback search assertions.
Map<String, dynamic> _itemJson({
  required String id,
  required String path,
  required String mediaSourceId,
  String type = 'Movie',
  Map<String, String>? providerIds,
}) {
  return {
    'Id': id,
    'Name': 'Item $id',
    'Type': type,
    'Path': path,
    'ProviderIds': ?providerIds,
    'MediaSources': [_mediaSourceJson(id: mediaSourceId, path: path)],
  };
}

Map<String, dynamic> _mediaSourceJson({required String id, String? path}) {
  return {
    'Id': id,
    'Path': ?path,
    'Container': 'mkv',
    'MediaStreams': [
      {'Index': 0, 'Type': 'Video', 'Codec': 'h264'},
      {
        'Index': 1,
        'Type': 'Audio',
        'Codec': 'aac',
        'Language': 'eng',
        'DisplayTitle': 'English AAC',
        'IsDefault': true,
      },
      {
        'Index': 2,
        'Type': 'Subtitle',
        'Codec': 'subrip',
        'IsExternal': true,
        'DeliveryUrl': '/Videos/item-1/$id/Subtitles/2/0/Stream.vtt',
      },
    ],
  };
}

JellyfinItem _playableItem() {
  return JellyfinItem(
    id: 'item-1',
    name: 'Movie',
    type: 'Movie',
    path: '/data/movies/M.mkv',
    playbackPositionTicks: 300000000,
    mediaSources: [
      JellyfinMediaSource(
        id: 'src-1',
        container: 'mkv',
        path: '/data/movies/M.mkv',
        mediaStreams: [
          const JellyfinMediaStream(index: 0, type: 'Video', codec: 'h264'),
          const JellyfinMediaStream(
            index: 1,
            type: 'Audio',
            codec: 'aac',
            language: 'eng',
            displayTitle: 'English AAC',
            isDefault: true,
          ),
          const JellyfinMediaStream(
            index: 2,
            type: 'Subtitle',
            codec: 'subrip',
            isExternal: true,
            deliveryUrl: '/Videos/item-1/src-1/Subtitles/2/0/Stream.vtt',
          ),
        ],
      ),
    ],
  );
}

JellyfinService _serviceApiKey(
  _RecordingAdapter adapter, {
  Duration? pollInterval,
  Duration? pollTimeout,
}) {
  return _buildService(
    adapter,
    apiKey: 'jelly-key',
    pollInterval: pollInterval,
    pollTimeout: pollTimeout,
  );
}

JellyfinService _serviceUserPassword(_RecordingAdapter adapter) {
  return _buildService(
    adapter,
    apiKey: 'admin:pass',
    deviceId: 'install-user-1',
  );
}

/// Instance carrying a reverse-proxy Basic header plus a passthrough header.
Instance _instanceWithBasicAuth({required String apiKey}) => Instance(
  id: 'jf-1',
  type: InstanceType.jellyfin,
  label: 'Jellyfin',
  url: 'http://jf.test',
  apiKey: apiKey,
  headers: [
    InstanceHeader(name: 'Authorization', value: 'Basic dXNlcjpwYXNz'),
    InstanceHeader(name: 'X-Proxy', value: 'keep-me'),
  ],
);

JellyfinService _buildService(
  _RecordingAdapter adapter, {
  required String apiKey,
  Duration? pollInterval,
  Duration? pollTimeout,
  String? deviceId,
  Future<String> Function()? deviceIdResolver,
  List<InstanceHeader> headers = const [],
  InstanceUserSession? userSession,
}) {
  final instance = Instance(
    id: 'jf-1',
    type: InstanceType.jellyfin,
    label: 'Jellyfin',
    url: 'http://jf.test',
    apiKey: apiKey,
    headers: headers,
    userSession: userSession,
  );
  final dio = Dio()
    ..httpClientAdapter = adapter
    ..options.baseUrl = instance.effectiveUrl
    ..options.validateStatus = (status) => status != null && status < 500;
  return JellyfinService(
    instance,
    dio: dio,
    pollInterval: pollInterval ?? _testPollInterval,
    pollTimeout: pollTimeout ?? _testPollTimeout,
    deviceIdResolver:
        deviceIdResolver ?? (deviceId == null ? null : () async => deviceId),
  );
}

/// Poll durations shrink-wrapped for tests: near-zero waits keep the polling
/// loop fast while still exercising several iterations.
const _testPollInterval = Duration(milliseconds: 1);
const _testPollTimeout = Duration(milliseconds: 500);

/// Request that never gets an HTTP answer, like a browser hiding a 401
/// without CORS headers or an unreachable host.
class _TransportFailure {
  const _TransportFailure();
}

/// Response with a non-default status code.
class _StatusBody {
  final int statusCode;
  final Object? body;

  const _StatusBody(this.statusCode, this.body);
}

/// Adapter that routes every request through a [handler] while recording
/// requests, methods, headers, and (JSON-decoded) bodies.
class _RecordingAdapter implements HttpClientAdapter {
  final Object? Function(RequestOptions options) handler;

  final List<Uri> requests = [];
  final List<String> methods = [];
  final List<Map<String, Object?>> headers = [];
  final List<Object?> bodies = [];

  _RecordingAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    methods.add(options.method);
    headers.add(Map<String, Object?>.from(options.headers));
    bodies.add(_decodeBody(options.data));

    final result = handler(options);
    if (result is _TransportFailure) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'XMLHttpRequest onError callback was called',
      );
    }
    if (result is _StatusBody) {
      final isPlainString = result.body is String;
      return ResponseBody.fromString(
        isPlainString ? result.body as String : jsonEncode(result.body),
        result.statusCode,
        headers: {
          Headers.contentTypeHeader: [
            isPlainString
                ? Headers.textPlainContentType
                : Headers.jsonContentType,
          ],
        },
      );
    }
    return ResponseBody.fromString(
      result is String ? result : jsonEncode(result),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  /// Dio serializes JSON bodies to strings before the adapter sees them, so
  /// decode them back for ergonomic assertions.
  Object? _decodeBody(Object? data) {
    if (data is! String) return data;
    try {
      return jsonDecode(data);
    } on FormatException {
      return data;
    }
  }

  @override
  void close({bool force = false}) {}
}
