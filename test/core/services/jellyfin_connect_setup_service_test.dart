import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrmate/core/services/jellyfin_connect_setup_service.dart';
import 'package:arrmate/data/api/jellyfin_service.dart';
import 'package:arrmate/data/api/radarr_api.dart';
import 'package:arrmate/data/api/sonarr_api.dart';
import 'package:arrmate/domain/models/models.dart';

class MockRadarrApi extends Mock implements RadarrApi {}

class MockSonarrApi extends Mock implements SonarrApi {}

class MockJellyfinService extends Mock implements JellyfinService {}

class _MockRef extends Mock implements Ref {}

const _jellyfinUrl = 'http://jellyfin.local:8096';
const _jellyfinApiKey = 'jellyfin-secret-key';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(NotificationResource());
  });

  Instance radarrInstance() => Instance(
    id: 'radarr-1',
    type: InstanceType.radarr,
    label: 'Radarr',
    url: 'http://radarr.local:7878',
    apiKey: 'radarr-key',
  );

  Instance sonarrInstance() => Instance(
    id: 'sonarr-1',
    type: InstanceType.sonarr,
    label: 'Sonarr',
    url: 'http://sonarr.local:8989',
    apiKey: 'sonarr-key',
  );

  Instance qbittorrentInstance() => Instance(
    id: 'qbittorrent-1',
    type: InstanceType.qbittorrent,
    label: 'qBittorrent',
    url: 'http://qbittorrent.local:8080',
    apiKey: 'qb-key',
  );

  /// A Jellyfin connection with a trailing slash to prove normalization.
  Instance jellyfinInstance() => Instance(
    id: 'jellyfin-1',
    type: InstanceType.jellyfin,
    label: 'Jellyfin',
    url: '$_jellyfinUrl/',
    apiKey: _jellyfinApiKey,
  );

  /// Real Radarr `MediaBrowserSettings` schema: split address fields.
  NotificationResource mediaBrowserSchema() => NotificationResource(
    implementation: 'MediaBrowser',
    configContract: 'MediaBrowserSettings',
    fields: [
      NotificationField(name: 'Host', value: null),
      NotificationField(name: 'Port', value: 0),
      NotificationField(name: 'UseSsl', value: false),
      NotificationField(name: 'UrlBase', value: '/'),
      NotificationField(name: 'ApiKey', value: null),
      NotificationField(name: 'UpdateLibrary', value: false),
    ],
    extra: {'onRename': false},
  );

  /// Real Sonarr `EmbySettings` schema (lowercase `updateLibrary`).
  NotificationResource embySchema() => NotificationResource(
    implementation: 'Emby',
    configContract: 'EmbySettings',
    fields: [
      NotificationField(name: 'Host', value: null),
      NotificationField(name: 'Port', value: 0),
      NotificationField(name: 'UseSsl', value: false),
      NotificationField(name: 'UrlBase', value: '/'),
      NotificationField(name: 'ApiKey', value: null),
      NotificationField(name: 'updateLibrary', value: false),
    ],
  );

  /// Legacy implementation that still ships a single `Url` field.
  NotificationResource legacyUrlSchema() => NotificationResource(
    implementation: 'MediaBrowser',
    configContract: 'MediaBrowserSettings',
    fields: [
      NotificationField(name: 'Url', value: null),
      NotificationField(name: 'ApiKey', value: null),
      NotificationField(name: 'UpdateLibrary', value: false),
    ],
    extra: {'onRename': false},
  );

  JellyfinConnectSetupService serviceWith({
    RadarrApi Function(Instance instance)? radarrApiFactory,
    SonarrApi Function(Instance instance)? sonarrApiFactory,
    JellyfinService Function(Instance instance)? jellyfinServiceFactory,
    List<Instance> Function()? instancesSource,
    Future<void> Function(Instance instance)? instanceUpdater,
  }) => JellyfinConnectSetupService(
    _MockRef(),
    radarrApiFactory: radarrApiFactory,
    sonarrApiFactory: sonarrApiFactory,
    jellyfinServiceFactory: jellyfinServiceFactory,
    instancesSource: instancesSource,
    instanceUpdater: instanceUpdater,
  );

  /// Stubs [api] so a fresh connector can be created, capturing the payload.
  List<NotificationResource> Function() stubCreate(
    MockRadarrApi api, {
    List<NotificationResource> schemas = const [],
    List<NotificationResource> notifications = const [],
  }) {
    when(() => api.getNotificationSchemas()).thenAnswer((_) async => schemas);
    when(() => api.getNotifications()).thenAnswer((_) async => notifications);
    final created = <NotificationResource>[];
    when(() => api.createNotification(any())).thenAnswer((invocation) async {
      created.add(invocation.positionalArguments[0] as NotificationResource);
      return created.last;
    });
    return () => created;
  }

  Map<String, dynamic> fieldsOf(NotificationResource notification) => {
    for (final field in notification.fields) field.name: field.value,
  };

  test('creates a new MediaBrowser connector when none exists', () async {
    // Given
    final api = MockRadarrApi();
    final created = stubCreate(api, schemas: [mediaBrowserSchema()])();

    // When
    final result = await serviceWith(radarrApiFactory: (_) => api)
        .configureArrInstance(
          radarrInstance(),
          jellyfinInstance: jellyfinInstance(),
        );

    // Then
    expect(result.isSuccess, isTrue);
    verifyNever(() => api.updateNotification(any()));
    expect(created, hasLength(1));

    final connector = created.single;
    expect(connector.name, 'Arrmate Jellyfin');

    final body = connector.toJson();
    expect(body['onGrab'], isFalse);
    expect(body['onDownload'], isTrue);
    expect(body['onUpgrade'], isTrue);
    expect(body['onRename'], isTrue);
    expect(body['onMovieDelete'], isTrue);

    final fields = fieldsOf(connector);
    expect(fields['Host'], 'jellyfin.local');
    expect(fields['Port'], 8096);
    expect(fields['UseSsl'], isFalse);
    // Plain URL without a path: the schema default stays untouched.
    expect(fields['UrlBase'], '/');
    expect(fields['ApiKey'], _jellyfinApiKey);
    expect(fields['UpdateLibrary'], isTrue);
  });

  test('splits an https URL with custom port and base path', () async {
    // Given
    final api = MockRadarrApi();
    final created = stubCreate(api, schemas: [mediaBrowserSchema()])();

    // When
    final result = await serviceWith(radarrApiFactory: (_) => api)
        .configureArrInstance(
          radarrInstance(),
          jellyfinInstance: Instance(
            id: 'jellyfin-1',
            type: InstanceType.jellyfin,
            label: 'Jellyfin',
            url: 'https://media.example.com:8920/jellyfin',
            apiKey: _jellyfinApiKey,
          ),
        );

    // Then
    expect(result.isSuccess, isTrue);
    final fields = fieldsOf(created.single);
    expect(fields['Host'], 'media.example.com');
    expect(fields['Port'], 8920);
    expect(fields['UseSsl'], isTrue);
    expect(fields['UrlBase'], '/jellyfin');
    expect(fields['ApiKey'], _jellyfinApiKey);
    expect(fields['UpdateLibrary'], isTrue);
  });

  test(
    'fills the scheme-default port when the URL has no explicit port',
    () async {
      // Given
      final api = MockRadarrApi();
      final created = stubCreate(api, schemas: [mediaBrowserSchema()])();

      // When
      await serviceWith(radarrApiFactory: (_) => api).configureArrInstance(
        radarrInstance(),
        jellyfinInstance: Instance(
          id: 'jellyfin-1',
          type: InstanceType.jellyfin,
          label: 'Jellyfin',
          url: 'http://jellyfin.local',
          apiKey: _jellyfinApiKey,
        ),
      );

      final fields = fieldsOf(created.single);
      // Then
      expect(fields['Host'], 'jellyfin.local');
      // The schema ships Port = 0, which the connector validation rejects.
      expect(fields['Port'], 8096);
      expect(fields['UseSsl'], isFalse);
    },
  );

  test('updates the existing connector matched by name', () async {
    // Given
    final api = MockRadarrApi();
    final existing = NotificationResource(
      id: 7,
      name: 'Arrmate Jellyfin',
      implementation: 'MediaBrowser',
      configContract: 'MediaBrowserSettings',
      fields: [
        NotificationField(name: 'Host', value: 'old-jellyfin.local'),
        NotificationField(name: 'Port', value: 8096),
        NotificationField(name: 'UseSsl', value: false),
        NotificationField(name: 'UrlBase', value: '/'),
        NotificationField(name: 'ApiKey', value: 'old-key'),
        NotificationField(name: 'UpdateLibrary', value: false),
      ],
      extra: {'customFlag': 'keep'},
    );
    when(() => api.getNotifications()).thenAnswer((_) async => [existing]);
    final updated = <NotificationResource>[];
    when(() => api.updateNotification(any())).thenAnswer((invocation) async {
      updated.add(invocation.positionalArguments[0] as NotificationResource);
      return updated.last;
    });

    // When
    final result = await serviceWith(radarrApiFactory: (_) => api)
        .configureArrInstance(
          radarrInstance(),
          jellyfinInstance: jellyfinInstance(),
        );

    // Then
    expect(result.isSuccess, isTrue);
    verifyNever(() => api.createNotification(any()));
    // The schema is only needed when creating from scratch.
    verifyNever(() => api.getNotificationSchemas());

    expect(updated, hasLength(1));
    expect(updated.single.id, 7);

    final body = updated.single.toJson();
    expect(body['name'], 'Arrmate Jellyfin');
    // Unknown extra fields survive the update.
    expect(body['customFlag'], 'keep');

    final fields = fieldsOf(updated.single);
    expect(fields['Host'], 'jellyfin.local');
    expect(fields['Port'], 8096);
    expect(fields['UseSsl'], isFalse);
    expect(fields['UrlBase'], '/');
    expect(fields['ApiKey'], _jellyfinApiKey);
    expect(fields['UpdateLibrary'], isTrue);
  });

  test(
    'creates its own connector instead of adopting a user-created one with the same server',
    () async {
      // Given
      final api = MockRadarrApi();
      final userConnector = NotificationResource(
        id: 9,
        name: 'My Jellyfin',
        implementation: 'MediaBrowser',
        configContract: 'MediaBrowserSettings',
        fields: [
          NotificationField(name: 'Host', value: 'jellyfin.local'),
          NotificationField(name: 'Port', value: 8096),
          NotificationField(name: 'UseSsl', value: false),
          NotificationField(name: 'UrlBase', value: '/'),
          NotificationField(name: 'ApiKey', value: 'user-key'),
          NotificationField(name: 'UpdateLibrary', value: true),
        ],
      );
      final created = stubCreate(
        api,
        schemas: [mediaBrowserSchema()],
        notifications: [userConnector],
      )();

      // When
      final result = await serviceWith(radarrApiFactory: (_) => api)
          .configureArrInstance(
            radarrInstance(),
            jellyfinInstance: jellyfinInstance(),
          );

      // Then
      expect(result.isSuccess, isTrue);
      // The user's connector is neither adopted nor renamed.
      verifyNever(() => api.updateNotification(any()));
      expect(created, hasLength(1));
      expect(created.single.name, 'Arrmate Jellyfin');
      expect(created.single.id, isNull);
      expect(fieldsOf(created.single)['Host'], 'jellyfin.local');
    },
  );

  test('keeps populating the Url field for legacy implementations', () async {
    // Given
    final api = MockRadarrApi();
    final created = stubCreate(api, schemas: [legacyUrlSchema()])();

    // When
    await serviceWith(radarrApiFactory: (_) => api).configureArrInstance(
      radarrInstance(),
      jellyfinInstance: jellyfinInstance(),
    );

    final fields = fieldsOf(created.single);
    // Then
    expect(fields['Url'], _jellyfinUrl);
    expect(fields['ApiKey'], _jellyfinApiKey);
    expect(fields['UpdateLibrary'], isTrue);
  });

  test(
    'writes the primary URL even when an alternative URL is active',
    () async {
      // Given
      final api = MockRadarrApi();
      final created = stubCreate(api, schemas: [mediaBrowserSchema()])();

      // activeUrl selects the WAN tunnel for the phone's current network;
      // the connector must still get the LAN address from the primary URL.
      // When
      final result = await serviceWith(radarrApiFactory: (_) => api)
          .configureArrInstance(
            radarrInstance(),
            jellyfinInstance: Instance(
              id: 'jellyfin-1',
              type: InstanceType.jellyfin,
              label: 'Jellyfin',
              url: _jellyfinUrl,
              alternativeUrl: 'https://tunnel.example.net',
              activeUrl: 'https://tunnel.example.net',
              apiKey: _jellyfinApiKey,
            ),
          );

      // Then
      expect(result.isSuccess, isTrue);
      final fields = fieldsOf(created.single);
      expect(fields['Host'], 'jellyfin.local');
      expect(fields['Port'], 8096);
      expect(fields['UseSsl'], isFalse);
    },
  );

  test('prefers the MediaBrowser implementation over Emby', () async {
    // Given
    final api = MockRadarrApi();
    final created = stubCreate(
      api,
      schemas: [embySchema(), mediaBrowserSchema()],
    )();

    // When
    await serviceWith(radarrApiFactory: (_) => api).configureArrInstance(
      radarrInstance(),
      jellyfinInstance: jellyfinInstance(),
    );

    // Then
    expect(created.single.implementation, 'MediaBrowser');
    expect(created.single.configContract, 'MediaBrowserSettings');
  });

  test('falls back to the Emby implementation when available', () async {
    // Given
    final api = MockSonarrApi();
    when(
      () => api.getNotificationSchemas(),
    ).thenAnswer((_) async => [embySchema()]);
    when(() => api.getNotifications()).thenAnswer((_) async => []);
    final created = <NotificationResource>[];
    when(() => api.createNotification(any())).thenAnswer((invocation) async {
      created.add(invocation.positionalArguments[0] as NotificationResource);
      return created.last;
    });

    // When
    await serviceWith(sonarrApiFactory: (_) => api).configureArrInstance(
      sonarrInstance(),
      jellyfinInstance: jellyfinInstance(),
    );

    // Then
    expect(created.single.implementation, 'Emby');
    expect(created.single.configContract, 'EmbySettings');
    // Field matching is case-insensitive: Sonarr ships `updateLibrary`.
    expect(fieldsOf(created.single)['updateLibrary'], isTrue);
    expect(fieldsOf(created.single)['Host'], 'jellyfin.local');
  });

  test(
    'fails without touching the *arr API when Jellyfin has no API key',
    () async {
      // Given
      final api = MockRadarrApi();
      final jellyfin = MockJellyfinService();
      when(() => jellyfin.ensureApiKey()).thenAnswer((_) async => null);
      final service = serviceWith(
        radarrApiFactory: (_) => api,
        jellyfinServiceFactory: (_) => jellyfin,
      );

      // When
      final result = await service.configureArrInstance(
        radarrInstance(),
        // Username:password auth mode means there is no API key to reuse.
        jellyfinInstance: Instance(label: 'Jellyfin', url: _jellyfinUrl),
      );

      // Then
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('API key required'));
      verifyZeroInteractions(api);
    },
  );

  test(
    'a failing *arr instance does not prevent configuring the others',
    () async {
      // Given
      final radarrApi = MockRadarrApi();
      when(() => radarrApi.getNotifications()).thenAnswer((_) async => []);
      when(
        () => radarrApi.getNotificationSchemas(),
      ).thenThrow(Exception('connection refused'));

      final sonarrApi = MockSonarrApi();
      when(
        () => sonarrApi.getNotificationSchemas(),
      ).thenAnswer((_) async => [embySchema()]);
      when(() => sonarrApi.getNotifications()).thenAnswer((_) async => []);
      final created = <NotificationResource>[];
      when(() => sonarrApi.createNotification(any())).thenAnswer((
        invocation,
      ) async {
        created.add(invocation.positionalArguments[0] as NotificationResource);
        return created.last;
      });

      // When
      final results = await serviceWith(
        radarrApiFactory: (_) => radarrApi,
        sonarrApiFactory: (_) => sonarrApi,
        instancesSource: () => [
          radarrInstance(),
          sonarrInstance(),
          // Non-*arr instances are never configured.
          qbittorrentInstance(),
        ],
      ).configureForAllArrInstances(jellyfinInstance: jellyfinInstance());

      // Then
      expect(results, hasLength(2));
      expect(results[0].isSuccess, isFalse);
      expect(results[0].message, contains('connection refused'));
      expect(results[1].isSuccess, isTrue);

      verifyNever(() => radarrApi.createNotification(any()));
      expect(created, hasLength(1));
    },
  );

  test('reports a failure when no Jellyfin connection is configured', () async {
    // Given
    // When
    final results = await serviceWith(
      instancesSource: () => [radarrInstance()],
    ).configureForAllArrInstances();

    // Then
    expect(results, hasLength(1));
    expect(results.single.isSuccess, isFalse);
    expect(results.single.message, contains('No Jellyfin connection'));
  });

  test(
    'discovers the Jellyfin instance from the configured instances',
    () async {
      // Given
      final api = MockRadarrApi();
      final created = stubCreate(api, schemas: [mediaBrowserSchema()])();

      // When
      final results = await serviceWith(
        radarrApiFactory: (_) => api,
        instancesSource: () => [radarrInstance(), jellyfinInstance()],
      ).configureForAllArrInstances();

      // Then
      expect(results, hasLength(1));
      expect(results.single.isSuccess, isTrue);
      expect(created, hasLength(1));
      expect(fieldsOf(created.single)['Host'], 'jellyfin.local');
    },
  );

  test(
    'mints an administrator API key when credentials are username:password',
    () async {
      // Given
      final api = MockRadarrApi();
      final created = stubCreate(api, schemas: [mediaBrowserSchema()])();

      final jellyfin = MockJellyfinService();
      when(() => jellyfin.ensureApiKey()).thenAnswer(
        (_) async => const JellyfinApiKey('minted-key', created: false),
      );

      final userPasswordJellyfin = Instance(
        id: 'jellyfin-1',
        type: InstanceType.jellyfin,
        label: 'Jellyfin',
        url: _jellyfinUrl,
        apiKey: 'admin:pass',
      );

      // When
      final result =
          await serviceWith(
            radarrApiFactory: (_) => api,
            jellyfinServiceFactory: (_) => jellyfin,
          ).configureArrInstance(
            radarrInstance(),
            jellyfinInstance: userPasswordJellyfin,
          );

      // Then
      expect(result.isSuccess, isTrue);
      verify(() => jellyfin.ensureApiKey()).called(1);
      expect(fieldsOf(created.single)['ApiKey'], 'minted-key');
    },
  );

  test(
    'mints a key from Basic Auth credentials when the field is empty',
    () async {
      // Given
      final api = MockRadarrApi();
      final created = stubCreate(api, schemas: [mediaBrowserSchema()])();

      final jellyfin = MockJellyfinService();
      when(() => jellyfin.ensureApiKey()).thenAnswer(
        (_) async => const JellyfinApiKey('minted-key', created: false),
      );

      final basicAuthJellyfin = Instance(
        id: 'jellyfin-1',
        type: InstanceType.jellyfin,
        label: 'Jellyfin',
        url: _jellyfinUrl,
        headers: [
          InstanceHeader(
            name: 'Authorization',
            value: 'Basic YWRtaW46cGFzcw==',
          ),
        ],
      );

      // When
      final result =
          await serviceWith(
            radarrApiFactory: (_) => api,
            jellyfinServiceFactory: (_) => jellyfin,
          ).configureArrInstance(
            radarrInstance(),
            jellyfinInstance: basicAuthJellyfin,
          );

      // Then
      expect(result.isSuccess, isTrue);
      verify(() => jellyfin.ensureApiKey()).called(1);
      expect(fieldsOf(created.single)['ApiKey'], 'minted-key');
    },
  );

  test('fails with guidance when the user cannot mint an API key', () async {
    // Given
    final api = MockRadarrApi();

    final jellyfin = MockJellyfinService();
    when(() => jellyfin.ensureApiKey()).thenAnswer((_) async => null);

    final userPasswordJellyfin = Instance(
      id: 'jellyfin-1',
      type: InstanceType.jellyfin,
      label: 'Jellyfin',
      url: _jellyfinUrl,
      apiKey: 'regular:pass',
    );

    // When
    final result =
        await serviceWith(
          radarrApiFactory: (_) => api,
          jellyfinServiceFactory: (_) => jellyfin,
        ).configureArrInstance(
          radarrInstance(),
          jellyfinInstance: userPasswordJellyfin,
        );

    // Then
    expect(result.isSuccess, isFalse);
    expect(result.message, contains('administrator'));
    // Nothing is written to the *arr instance without a key.
    verifyNever(() => api.createNotification(any()));
    verifyNever(() => api.updateNotification(any()));
  });

  test(
    'resolves the server API key once across multiple *arr instances',
    () async {
      // Given
      final radarrApi = MockRadarrApi();
      final radarrCreated = stubCreate(
        radarrApi,
        schemas: [mediaBrowserSchema()],
      )();

      final sonarrApi = MockSonarrApi();
      when(
        () => sonarrApi.getNotificationSchemas(),
      ).thenAnswer((_) async => [embySchema()]);
      when(() => sonarrApi.getNotifications()).thenAnswer((_) async => []);
      final sonarrCreated = <NotificationResource>[];
      when(() => sonarrApi.createNotification(any())).thenAnswer((
        invocation,
      ) async {
        sonarrCreated.add(
          invocation.positionalArguments[0] as NotificationResource,
        );
        return sonarrCreated.last;
      });

      final jellyfin = MockJellyfinService();
      when(() => jellyfin.ensureApiKey()).thenAnswer(
        (_) async => const JellyfinApiKey('minted-key', created: false),
      );

      final userPasswordJellyfin = Instance(
        id: 'jellyfin-1',
        type: InstanceType.jellyfin,
        label: 'Jellyfin',
        url: _jellyfinUrl,
        apiKey: 'admin:pass',
      );

      // When
      final results = await serviceWith(
        radarrApiFactory: (_) => radarrApi,
        sonarrApiFactory: (_) => sonarrApi,
        jellyfinServiceFactory: (_) => jellyfin,
        instancesSource: () => [radarrInstance(), sonarrInstance()],
      ).configureForAllArrInstances(jellyfinInstance: userPasswordJellyfin);

      // Then
      expect(results, hasLength(2));
      expect(results.every((r) => r.isSuccess), isTrue);
      verify(() => jellyfin.ensureApiKey()).called(1);
      expect(fieldsOf(radarrCreated.single)['ApiKey'], 'minted-key');
      expect(fieldsOf(sonarrCreated.single)['ApiKey'], 'minted-key');
    },
  );

  group('disconnect', () {
    NotificationResource connector({
      required int id,
      String name = 'Arrmate Jellyfin',
      String host = 'jellyfin.local',
    }) => NotificationResource(
      id: id,
      name: name,
      implementation: 'MediaBrowser',
      configContract: 'MediaBrowserSettings',
      fields: [
        NotificationField(name: 'Host', value: host),
        NotificationField(name: 'Port', value: 8096),
      ],
    );

    MockJellyfinService cleanJellyfin() {
      final jellyfin = MockJellyfinService();
      when(() => jellyfin.revokeApiKey(any())).thenAnswer((_) async {});
      when(() => jellyfin.logout()).thenAnswer((_) async {});
      return jellyfin;
    }

    Instance pairedJellyfin() =>
        jellyfinInstance().copyWith(ownedApiKey: 'owned-key');

    test(
      'removes only the Arrmate connector pointing at this server, revokes '
      'the key and signs out',
      () async {
        // Given
        final radarrApi = MockRadarrApi();
        when(() => radarrApi.getNotifications()).thenAnswer(
          (_) async => [
            connector(id: 1),
            connector(id: 2, name: 'My Jellyfin'),
            connector(id: 3, host: 'other-jellyfin.local'),
          ],
        );
        when(
          () => radarrApi.deleteNotification(any()),
        ).thenAnswer((_) async {});
        final sonarrApi = MockSonarrApi();
        when(
          () => sonarrApi.getNotifications(),
        ).thenAnswer((_) async => [connector(id: 7)]);
        when(
          () => sonarrApi.deleteNotification(any()),
        ).thenAnswer((_) async {});
        final jellyfin = cleanJellyfin();

        // When
        final failures = await serviceWith(
          radarrApiFactory: (_) => radarrApi,
          sonarrApiFactory: (_) => sonarrApi,
          jellyfinServiceFactory: (_) => jellyfin,
          instancesSource: () => [
            radarrInstance(),
            sonarrInstance(),
            qbittorrentInstance(),
          ],
        ).disconnect(pairedJellyfin());

        // Then
        expect(failures, isEmpty);
        verify(() => radarrApi.deleteNotification(1)).called(1);
        verifyNever(() => radarrApi.deleteNotification(2));
        verifyNever(() => radarrApi.deleteNotification(3));
        verify(() => sonarrApi.deleteNotification(7)).called(1);
        verifyInOrder([
          () => jellyfin.revokeApiKey('owned-key'),
          () => jellyfin.logout(),
        ]);
      },
    );

    test('reports each failed step and still runs the others', () async {
      // Given
      final radarrApi = MockRadarrApi();
      when(
        () => radarrApi.getNotifications(),
      ).thenThrow(Exception('radarr down'));
      final jellyfin = MockJellyfinService();
      when(
        () => jellyfin.revokeApiKey(any()),
      ).thenThrow(Exception('not an administrator'));
      when(() => jellyfin.logout()).thenAnswer((_) async {});

      // When
      final failures = await serviceWith(
        radarrApiFactory: (_) => radarrApi,
        jellyfinServiceFactory: (_) => jellyfin,
        instancesSource: () => [radarrInstance()],
      ).disconnect(pairedJellyfin());

      // Then
      expect(failures, hasLength(2));
      expect(failures[0], contains('radarr-1'));
      expect(failures[1], contains('revoke'));
      verify(() => jellyfin.logout()).called(1);
    });

    test('revokes nothing without a key Arrmate created', () async {
      // Given — a reused "Arrmate" key may serve another device.
      final jellyfin = cleanJellyfin();

      // When
      final failures = await serviceWith(
        jellyfinServiceFactory: (_) => jellyfin,
        instancesSource: () => const [],
      ).disconnect(jellyfinInstance());

      // Then
      expect(failures, isEmpty);
      verifyNever(() => jellyfin.revokeApiKey(any()));
      verify(() => jellyfin.logout()).called(1);
    });
  });

  group('owned API key', () {
    Instance adminJellyfin() => Instance(
      id: 'jellyfin-1',
      type: InstanceType.jellyfin,
      label: 'Jellyfin',
      url: _jellyfinUrl,
      userSession: const InstanceUserSession(
        accessToken: 'token',
        deviceId: 'arrmate-device',
        isAdministrator: true,
      ),
    );

    Future<List<Instance>> pairWith(JellyfinApiKey key) async {
      final api = MockRadarrApi();
      stubCreate(api, schemas: [mediaBrowserSchema()]);
      final jellyfin = MockJellyfinService();
      when(() => jellyfin.ensureApiKey()).thenAnswer((_) async => key);
      final updated = <Instance>[];
      await serviceWith(
        radarrApiFactory: (_) => api,
        jellyfinServiceFactory: (_) => jellyfin,
        instancesSource: () => [radarrInstance(), adminJellyfin()],
        instanceUpdater: (instance) async => updated.add(instance),
      ).configureForAllArrInstances(jellyfinInstance: adminJellyfin());
      return updated;
    }

    test('records a key created by the pairing', () async {
      // When
      final updated = await pairWith(
        const JellyfinApiKey('minted-key', created: true),
      );

      // Then
      expect(updated.single.id, 'jellyfin-1');
      expect(updated.single.ownedApiKey, 'minted-key');
      expect(updated.single.userSession, adminJellyfin().userSession);
    });

    test('does not claim a reused key', () async {
      // When
      final updated = await pairWith(
        const JellyfinApiKey('shared-key', created: false),
      );

      // Then
      expect(updated, isEmpty);
    });
  });
}
