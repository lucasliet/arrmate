import 'package:arrmate/domain/models/shared/download_client_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DownloadClientInfo', () {
    test(
      'should extract the Radarr movie category from the settings fields',
      () {
        // Given
        final json = {
          'id': 1,
          'name': 'qBit',
          'implementation': 'QBittorrent',
          'enable': true,
          'protocol': 'torrent',
          'fields': [
            {'name': 'host', 'value': 'localhost'},
            {'name': 'movieCategory', 'value': 'radarr'},
            {'name': 'movieImportedCategory', 'value': 'radarr-imported'},
          ],
        };

        // When
        final client = DownloadClientInfo.fromJson(json);

        // Then
        expect(client.categories, ['radarr', 'radarr-imported']);
        expect(client.isQBittorrent, isTrue);
        expect(client.enable, isTrue);
      },
    );

    test('should extract the Sonarr tv category from the settings fields', () {
      // Given
      final json = {
        'id': 2,
        'name': 'qBit',
        'implementation': 'QBittorrent',
        'enable': true,
        'fields': [
          {'name': 'tvCategory', 'value': 'tv-sonarr'},
        ],
      };

      // When
      final client = DownloadClientInfo.fromJson(json);

      // Then
      expect(client.categories, ['tv-sonarr']);
    });

    test('should ignore empty, duplicated and non-category fields', () {
      // Given
      final json = {
        'id': 3,
        'name': 'qBit',
        'implementation': 'QBittorrent',
        'enable': false,
        'fields': [
          {'name': 'movieCategory', 'value': '  '},
          {'name': 'tvCategory', 'value': 'tv-sonarr'},
          {'name': 'tvImportedCategory', 'value': 'tv-sonarr'},
          {'name': 'urlBase', 'value': '/qbt'},
          {'name': 'port', 'value': 8080},
        ],
      };

      // When
      final client = DownloadClientInfo.fromJson(json);

      // Then
      expect(client.categories, ['tv-sonarr']);
      expect(client.enable, isFalse);
    });

    test('should tolerate a payload without settings fields', () {
      // Given / When
      final client = DownloadClientInfo.fromJson({
        'id': 4,
        'name': 'SAB',
        'implementation': 'Sabnzbd',
        'enable': true,
      });

      // Then
      expect(client.categories, isEmpty);
      expect(client.isQBittorrent, isFalse);
    });
  });
}
