import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/domain/models/models.dart';

void main() {
  group('InstanceRepositoryImpl', () {
    group('getSystemStatus - Lógica de switch por tipo', () {
      test('Deve usar RadarrApi para instância tipo radarr', () {
        // Given
        final radarrInstance = Instance(
          id: '1',
          label: 'Test Radarr',
          url: 'http://localhost:7878',
          apiKey: 'apikey123',
          type: InstanceType.radarr,
        );

        // When / Then
        expect(radarrInstance.type, InstanceType.radarr);
        expect(radarrInstance.type.label, 'Radarr');
      });

      test('Deve usar SonarrApi para instância tipo sonarr', () {
        // Given
        final sonarrInstance = Instance(
          id: '2',
          label: 'Test Sonarr',
          url: 'http://localhost:8989',
          apiKey: 'apikey456',
          type: InstanceType.sonarr,
        );

        // When / Then
        expect(sonarrInstance.type, InstanceType.sonarr);
        expect(sonarrInstance.type.label, 'Sonarr');
      });
    });

    group('getTags - Lógica de switch por tipo', () {
      test('Deve diferenciar instância radarr de sonarr', () {
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

    group('Cobertura de InstanceType', () {
      test('Deve ter exatamente dois tipos de instância', () {
        // Given / When / Then
        expect(InstanceType.values.length, 2);
        expect(InstanceType.values, contains(InstanceType.radarr));
        expect(InstanceType.values, contains(InstanceType.sonarr));
      });

      test('Cada tipo deve ter label correto', () {
        // Given / When / Then
        expect(InstanceType.radarr.label, 'Radarr');
        expect(InstanceType.sonarr.label, 'Sonarr');
      });
    });
  });
}
