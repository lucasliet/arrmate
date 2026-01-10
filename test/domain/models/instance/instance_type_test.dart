import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/domain/models/models.dart';

void main() {
  group('InstanceType', () {
    test('Deve ter exatamente três tipos de instância', () {
      // Given / When / Then
      expect(InstanceType.values.length, 3);
      expect(InstanceType.values, contains(InstanceType.radarr));
      expect(InstanceType.values, contains(InstanceType.sonarr));
      expect(InstanceType.values, contains(InstanceType.qbittorrent));
    });

    test('Cada tipo deve ter label correto', () {
      // Given / When / Then
      expect(InstanceType.radarr.label, 'Radarr');
      expect(InstanceType.sonarr.label, 'Sonarr');
      expect(InstanceType.qbittorrent.label, 'qBittorrent');
    });

    test('Radarr e Sonarr devem ser tipos distintos', () {
      // Given
      final radarrInstance = Instance(
        id: '1',
        label: 'Test Radarr',
        url: 'http://localhost:7878',
        apiKey: 'apikey123',
        type: InstanceType.radarr,
      );

      final sonarrInstance = Instance(
        id: '2',
        label: 'Test Sonarr',
        url: 'http://localhost:8989',
        apiKey: 'apikey456',
        type: InstanceType.sonarr,
      );

      // When / Then
      expect(radarrInstance.type, isNot(equals(sonarrInstance.type)));
    });
  });
}
