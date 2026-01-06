import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InstanceStatus', () {
    test('Deve criar InstanceStatus a partir de JSON completo', () {
      final json = {
        'appName': 'Radarr',
        'instanceName': 'My Radarr',
        'version': '5.2.6.8376',
        'isDebug': false,
        'authentication': 'forms',
        'startTime': '2024-01-15T10:00:00Z',
        'urlBase': '/radarr',
      };

      final status = InstanceStatus.fromJson(json);

      expect(status.appName, 'Radarr');
      expect(status.instanceName, 'My Radarr');
      expect(status.version, '5.2.6.8376');
      expect(status.isDebug, false);
      expect(status.authentication, 'forms');
      expect(status.startTime, DateTime.parse('2024-01-15T10:00:00Z'));
      expect(status.urlBase, '/radarr');
    });

    test('Deve criar InstanceStatus com campos opcionais nulos', () {
      final json = {
        'appName': 'Sonarr',
        'instanceName': 'My Sonarr',
        'version': '4.0.0.1234',
      };

      final status = InstanceStatus.fromJson(json);

      expect(status.appName, 'Sonarr');
      expect(status.instanceName, 'My Sonarr');
      expect(status.version, '4.0.0.1234');
      expect(status.isDebug, null);
      expect(status.authentication, null);
      expect(status.startTime, null);
      expect(status.urlBase, null);
    });

    test('Deve comparar InstanceStatus corretamente com Equatable', () {
      final status1 = InstanceStatus(
        appName: 'Radarr',
        instanceName: 'My Radarr',
        version: '5.2.6.8376',
      );
      final status2 = InstanceStatus(
        appName: 'Radarr',
        instanceName: 'My Radarr',
        version: '5.2.6.8376',
      );
      final status3 = InstanceStatus(
        appName: 'Sonarr',
        instanceName: 'My Sonarr',
        version: '4.0.0.1234',
      );

      expect(status1, equals(status2));
      expect(status1, isNot(equals(status3)));
    });
  });
}
