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
  });
}
