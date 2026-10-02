import 'package:arrmate/domain/models/qbittorrent/add_torrent_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddTorrentRequest.toFormFields', () {
    test(
      'should send the paused flag under both qBittorrent 4 and 5 names',
      () {
        const request = AddTorrentRequest(urls: 'magnet:?xt=1', paused: true);

        final fields = request.toFormFields();

        expect(fields['paused'], 'true');
        expect(fields['stopped'], 'true');
      },
    );

    test('should start the torrent when paused is off', () {
      const request = AddTorrentRequest(urls: 'magnet:?xt=1');

      final fields = request.toFormFields();

      expect(fields['paused'], 'false');
      expect(fields['stopped'], 'false');
    });

    test('should omit optional fields that were not set', () {
      const request = AddTorrentRequest(urls: 'magnet:?xt=1');

      final fields = request.toFormFields();

      expect(fields.containsKey('savepath'), isFalse);
      expect(fields.containsKey('category'), isFalse);
      expect(fields.containsKey('tags'), isFalse);
    });
  });
}
