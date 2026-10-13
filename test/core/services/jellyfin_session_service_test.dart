import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrmate/core/services/jellyfin_session_service.dart';
import 'package:arrmate/data/api/jellyfin_service.dart';
import 'package:arrmate/domain/models/models.dart';

class MockJellyfinService extends Mock implements JellyfinService {}

void main() {
  const session = InstanceUserSession(
    accessToken: 'token-123',
    deviceId: 'arrmate-device-1',
    userId: 'user-9',
    userName: 'admin',
    isAdministrator: true,
  );

  Instance jellyfin({
    String apiKey = '',
    List<InstanceHeader> headers = const [],
    InstanceUserSession? userSession,
  }) => Instance(
    id: 'jellyfin-1',
    type: InstanceType.jellyfin,
    label: 'Jellyfin',
    url: 'http://jellyfin.local:8096',
    apiKey: apiKey,
    headers: headers,
    userSession: userSession,
  );

  group('JellyfinSessionService', () {
    test('exchanges a password for a session and forgets it', () async {
      // Given
      final service = MockJellyfinService();
      when(() => service.hasLoginCredentials).thenReturn(true);
      when(() => service.signIn()).thenAnswer((_) async => session);
      final sessions = JellyfinSessionService(
        jellyfinServiceFactory: (_) => service,
      );
      final instance = jellyfin(
        headers: [
          InstanceHeader(
            name: 'Authorization',
            value: 'Basic YWRtaW46cGFzcw==',
          ),
          InstanceHeader(name: 'X-Proxy', value: 'keep-me'),
        ],
      );

      // When
      final exchanged = await sessions.exchangeCredentials(instance);

      // Then
      expect(exchanged.apiKey, isEmpty);
      expect(exchanged.userSession, session);
      expect(exchanged.headers.map((h) => h.name), ['X-Proxy']);
      expect(exchanged.toJson().toString(), isNot(contains('YWRtaW46cGFzcw')));
    });

    test('drops the session locally when an API key replaces it', () async {
      // Given
      final services = <Instance, MockJellyfinService>{};
      MockJellyfinService serviceFor(Instance instance) =>
          services.putIfAbsent(instance, () {
            final service = MockJellyfinService();
            when(() => service.hasLoginCredentials).thenReturn(false);
            when(() => service.logout()).thenAnswer((_) async {});
            return service;
          });
      final sessions = JellyfinSessionService(
        jellyfinServiceFactory: serviceFor,
      );

      // When
      final exchanged = await sessions.exchangeCredentials(
        jellyfin(apiKey: 'server-key', userSession: session),
      );
      await pumpEventQueue();

      // Then
      expect(exchanged.apiKey, 'server-key');
      expect(exchanged.userSession, isNull);
      for (final service in services.values) {
        verifyNever(() => service.logout());
      }
    });

    test('keeps a stored session when no new credentials are given', () async {
      // Given
      final service = MockJellyfinService();
      when(() => service.hasLoginCredentials).thenReturn(false);
      final sessions = JellyfinSessionService(
        jellyfinServiceFactory: (_) => service,
      );
      final instance = jellyfin(userSession: session);

      // When
      final exchanged = await sessions.exchangeCredentials(instance);

      // Then
      expect(exchanged, instance);
      verifyNever(() => service.signIn());
    });

    test('leaves other instance types untouched', () async {
      // Given
      final sessions = JellyfinSessionService(
        jellyfinServiceFactory: (_) => fail('must not build a client'),
      );
      final radarr = Instance(type: InstanceType.radarr, apiKey: 'a:b');

      // When
      final exchanged = await sessions.exchangeCredentials(radarr);

      // Then
      expect(exchanged, radarr);
      expect(sessions.needsCredentialExchange(radarr), isFalse);
    });
  });
}
