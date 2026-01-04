import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/domain/models/models.dart';

void main() {
  group('LogEntry', () {
    test('Deve converter de JSON com sucesso', () {
      final json = {
        'time': '2024-01-04T12:00:00Z',
        'level': 'info',
        'logger': 'Radarr.Api',
        'message': 'API Request received',
        'exception': 'Stacktrace...',
        'exceptionType': 'ApiException',
      };

      final log = LogEntry.fromJson(json);

      expect(log.level, 'info');
      expect(log.logger, 'Radarr.Api');
      expect(log.message, 'API Request received');
      expect(log.exception, 'Stacktrace...');
      expect(log.time.isUtc, true);
    });
  });

  group('LogPage', () {
    test('Deve converter de JSON com sucesso', () {
      final json = {
        'page': 1,
        'pageSize': 1,
        'totalRecords': 100,
        'records': [
          {
            'time': '2024-01-04T12:00:00Z',
            'level': 'info',
            'logger': 'Radarr.Api',
            'message': 'Test message',
          }
        ],
      };

      final page = LogPage.fromJson(json);

      expect(page.page, 1);
      expect(page.totalRecords, 100);
      expect(page.records.length, 1);
      expect(page.records.first.level, 'info');
    });
  });

  group('HealthCheck', () {
    test('Deve converter de JSON com sucesso', () {
      final json = {
        'source': 'Indexers',
        'type': 'warning',
        'message': 'All indexers are showing signs of failure',
        'wikiUrl': 'https://wiki.servarr.com/radarr/system-health#indexers',
      };

      final health = HealthCheck.fromJson(json);

      expect(health.source, 'Indexers');
      expect(health.type, 'warning');
      expect(health.wikiUrl, 'https://wiki.servarr.com/radarr/system-health#indexers');
    });

    test('Deve lidar com wikiUrl nulo', () {
      final json = {
        'source': 'Indexers',
        'type': 'warning',
        'message': 'All indexers are showing signs of failure',
      };

      final health = HealthCheck.fromJson(json);

      expect(health.wikiUrl, '');
    });
  });
}
