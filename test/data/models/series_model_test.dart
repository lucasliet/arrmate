import 'package:arrmate/domain/models/series/series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Series Model', () {
    test('should treat lookup id 0 as not in the library', () {
      // Given
      final lookup = {
        'id': 0,
        'tvdbId': 417742,
        'title': 'Shogun',
        'added': '0001-01-01T00:00:00Z',
      };
      final library = {
        'id': 1,
        'tvdbId': 371980,
        'title': 'Severance',
        'added': '2023-01-01T00:00:00Z',
      };

      // When
      final lookupSeries = Series.fromJson(lookup);
      final librarySeries = Series.fromJson(library);

      // Then
      expect(lookupSeries.exists, isFalse);
      expect(lookupSeries.id, 0);
      expect(librarySeries.exists, isTrue);
      expect(librarySeries.id, 1);
    });
  });
}
