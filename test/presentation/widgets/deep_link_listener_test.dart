import 'package:flutter_test/flutter_test.dart';

import 'package:arrmate/presentation/widgets/deep_link_listener.dart';

void main() {
  group('deepLinkToLocation', () {
    test('should reconcile identifier-in-host form', () {
      // arrmate://movies/123 -> host=movies, path=/123
      final uri = Uri.parse('arrmate://movies/123');

      expect(deepLinkToLocation(uri), '/movies/123');
    });

    test('should handle authority-less form', () {
      final uri = Uri.parse('arrmate:///series/9');

      expect(deepLinkToLocation(uri), '/series/9');
    });

    test('should preserve query parameters', () {
      final uri = Uri.parse('arrmate:///search?q=inception&type=movie');

      expect(deepLinkToLocation(uri), '/search?q=inception&type=movie');
    });

    test('should support nested season paths', () {
      final uri = Uri.parse('arrmate:///series/9/season/3');

      expect(deepLinkToLocation(uri), '/series/9/season/3');
    });

    test('should support nested episode paths in authority-less form', () {
      final uri = Uri.parse('arrmate:///series/9/season/3/episode/45');

      expect(deepLinkToLocation(uri), '/series/9/season/3/episode/45');
    });

    test('should support nested episode paths in host form', () {
      final uri = Uri.parse('arrmate://series/9/season/3/episode/45');

      expect(deepLinkToLocation(uri), '/series/9/season/3/episode/45');
    });

    test('should return empty for a bare scheme', () {
      final uri = Uri.parse('arrmate://');

      expect(deepLinkToLocation(uri), '');
    });
  });
}
