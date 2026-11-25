import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthCheck provider failure sources', () {
    const cases = [
      ('IndexerStatusCheck', true, false),
      ('IndexerLongTermStatusCheck', true, false),
      ('IndexerRssCheck', false, false),
      ('IndexerSearchCheck', false, false),
      ('DownloadClientCheck', false, true),
      ('DownloadClientStatusCheck', false, true),
      ('AllowedHostsCheck', false, false),
    ];

    for (final (source, indexer, downloadClient) in cases) {
      test(
        'should flag $source as indexer=$indexer, downloadClient=$downloadClient',
        () {
          // Given
          final check = HealthCheck(
            source: source,
            type: 'warning',
            message: 'message',
            wikiUrl: '',
          );

          // When
          final flags = (
            check.reportsIndexerFailure,
            check.reportsDownloadClientFailure,
          );

          // Then
          expect(flags, (indexer, downloadClient));
        },
      );
    }
  });
}
