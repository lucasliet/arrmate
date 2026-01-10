import 'package:arrmate/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatInstanceVersion', () {
    test('should return empty string when version is null', () {
      expect(formatInstanceVersion(null), '');
    });

    test('should add v prefix when version exists and starts with a digit', () {
      expect(formatInstanceVersion('5.0.0'), 'v5.0.0');
      expect(formatInstanceVersion('1.0'), 'v1.0');
    });

    test('should not add v prefix when version already starts with v', () {
      expect(formatInstanceVersion('v4.6.0'), 'v4.6.0');
      expect(formatInstanceVersion('v1.0.0-beta'), 'v1.0.0-beta');
    });

    test(
      'should add v prefix when version is Unknown or other non-digit string',
      () {
        expect(formatInstanceVersion('Unknown'), 'vUnknown');
        expect(formatInstanceVersion('beta-version'), 'vbeta-version');
      },
    );

    test('should handle edge cases', () {
      expect(formatInstanceVersion(''), '');
      expect(formatInstanceVersion(' '), '');
    });
  });
}
