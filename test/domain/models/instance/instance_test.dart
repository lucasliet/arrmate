import 'dart:convert';

import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Instance com cache de tags', () {
    test('Deve criar Instance com tags', () {
      final instance = Instance(
        id: '1',
        label: 'My Radarr',
        url: 'http://localhost:7878',
        apiKey: 'apikey123',
        type: InstanceType.radarr,
        tags: [
          Tag(id: 1, label: 'Action'),
          Tag(id: 2, label: 'Drama'),
        ],
        version: '5.2.6.8376',
        name: 'My Radarr Instance',
      );

      expect(instance.tags.length, 2);
      expect(instance.tags[0].label, 'Action');
      expect(instance.tags[1].label, 'Drama');
      expect(instance.version, '5.2.6.8376');
      expect(instance.name, 'My Radarr Instance');
    });

    test('Deve criar Instance sem tags por padrão', () {
      final instance = Instance(
        id: '1',
        label: 'My Radarr',
        url: 'http://localhost:7878',
        apiKey: 'apikey123',
        type: InstanceType.radarr,
      );

      expect(instance.tags, isEmpty);
      expect(instance.version, null);
      expect(instance.name, null);
    });

    test('Deve serializar Instance com tags para JSON', () {
      final instance = Instance(
        id: '1',
        label: 'My Radarr',
        url: 'http://localhost:7878',
        apiKey: 'apikey123',
        type: InstanceType.radarr,
        tags: [Tag(id: 1, label: 'Action')],
        version: '5.2.6.8376',
        name: 'My Radarr Instance',
      );

      final json = instance.toJson();

      expect(json['tags'], isA<List>());
      expect((json['tags'] as List).length, 1);
      expect(json['version'], '5.2.6.8376');
      expect(json['name'], 'My Radarr Instance');
    });

    test('Deve desserializar Instance com tags a partir de JSON', () {
      final json = {
        'id': '1',
        'label': 'My Radarr',
        'url': 'http://localhost:7878',
        'apiKey': 'apikey123',
        'type': 'radarr',
        'tags': [
          {'id': 1, 'label': 'Action'},
          {'id': 2, 'label': 'Drama'},
        ],
        'version': '5.2.6.8376',
        'name': 'My Radarr Instance',
      };

      final instance = Instance.fromJson(json);

      expect(instance.tags.length, 2);
      expect(instance.tags[0].label, 'Action');
      expect(instance.tags[1].label, 'Drama');
      expect(instance.version, '5.2.6.8376');
      expect(instance.name, 'My Radarr Instance');
    });

    test('Deve usar copyWith para atualizar tags, version e name', () {
      final instance = Instance(
        id: '1',
        label: 'My Radarr',
        url: 'http://localhost:7878',
        apiKey: 'apikey123',
        type: InstanceType.radarr,
      );

      final updatedInstance = instance.copyWith(
        tags: [Tag(id: 1, label: 'Action')],
        version: '5.2.6.8376',
        name: 'Updated Name',
      );

      expect(updatedInstance.tags.length, 1);
      expect(updatedInstance.version, '5.2.6.8376');
      expect(updatedInstance.name, 'Updated Name');
      expect(updatedInstance.id, '1');
      expect(updatedInstance.label, 'My Radarr');
    });

    test('Deve preservar outros campos ao usar copyWith', () {
      final instance = Instance(
        id: '1',
        label: 'My Radarr',
        url: 'http://localhost:7878',
        apiKey: 'apikey123',
        type: InstanceType.radarr,
        mode: InstanceMode.slow,
        headers: [InstanceHeader(name: 'Custom', value: 'Header')],
      );

      final updatedInstance = instance.copyWith(
        tags: [Tag(id: 1, label: 'Action')],
      );

      expect(updatedInstance.mode, InstanceMode.slow);
      expect(updatedInstance.headers.length, 1);
      expect(updatedInstance.headers[0].name, 'Custom');
    });

    test(
      'should persist the alternative URL without persisting active URL',
      () {
        final instance = Instance(
          id: '1',
          label: 'My Radarr',
          url: 'http://192.168.1.10:7878',
          alternativeUrl: 'https://radarr.example.com',
          activeUrl: 'https://radarr.example.com',
          apiKey: 'apikey123',
          type: InstanceType.radarr,
        );

        final json = instance.toJson();
        final restored = Instance.fromJson(json);

        expect(json['alternativeUrl'], 'https://radarr.example.com');
        expect(json.containsKey('activeUrl'), isFalse);
        expect(restored.alternativeUrl, 'https://radarr.example.com');
        expect(restored.activeUrl, isNull);
        expect(restored.effectiveUrl, 'http://192.168.1.10:7878');
      },
    );

    test('should order unique connection URLs with the active URL first', () {
      final instance = Instance(
        id: '1',
        label: 'My Radarr',
        url: 'http://192.168.1.10:7878/',
        alternativeUrl: 'https://radarr.example.com/',
        activeUrl: 'https://radarr.example.com/',
        apiKey: 'apikey123',
        type: InstanceType.radarr,
      );

      expect(instance.connectionUrls, [
        'https://radarr.example.com',
        'http://192.168.1.10:7878',
      ]);
    });
  });

  group('Instance user session', () {
    const session = InstanceUserSession(
      accessToken: 'token-123',
      deviceId: 'arrmate-device-1',
      userId: 'user-9',
      userName: 'admin',
      isAdministrator: true,
    );

    test('round-trips the session through JSON', () {
      // Given
      final instance = Instance(
        id: 'jf-1',
        type: InstanceType.jellyfin,
        url: 'http://jellyfin.local:8096',
        userSession: session,
      );

      // When
      final restored = Instance.fromJson(
        jsonDecode(jsonEncode(instance.toJson())) as Map<String, dynamic>,
      );

      // Then
      expect(restored.userSession, session);
      expect(restored, instance);
    });

    test('omits the session from JSON when absent', () {
      // Given
      final instance = Instance(type: InstanceType.jellyfin, apiKey: 'key');

      // When
      final json = instance.toJson();

      // Then
      expect(json.containsKey('userSession'), isFalse);
      expect(Instance.fromJson(json).userSession, isNull);
    });

    test('copyWith keeps or clears the session', () {
      // Given
      final instance = Instance(
        type: InstanceType.jellyfin,
        userSession: session,
      );

      // When
      final kept = instance.copyWith(label: 'Renamed');
      final cleared = instance.copyWith(apiKey: 'key', clearUserSession: true);

      // Then
      expect(kept.userSession, session);
      expect(cleared.userSession, isNull);
      expect(cleared.apiKey, 'key');
    });
  });
}
